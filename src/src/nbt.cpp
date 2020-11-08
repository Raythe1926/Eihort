/* Copyright (c) 2012, Jason Lloyd-Price
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met: 

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer. 
2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution. 

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. */


#include <zlib.h>
#include <cassert>
#include <cstdio>
#include <cstdlib>
#include <cstring>

#include "nbt.h"
#include "endian.h"

namespace eihort {
namespace nbt {


// =========================== NBT IO - Compression ==========================

class gzistream {
	// Helper input stream class which handles the compression

public:
	gzistream() = delete;
	gzistream( const gzistream& ) = delete;
	gzistream( gzistream&& ) = delete;
	// Load from file
	explicit gzistream( const char *fn );
	// Load from MCRegion
	gzistream( const char *fn, unsigned idx );
	~gzistream();

	// Get a char from the stream
	char get() { return read<char>(); }
	// Read an arbitrary structure from the stream
	template< typename T >
	T read() {
		T data;
		read( &data, sizeof(T) );
		return data;
	}
	// Read an integer
	template< typename T >
	T readi() { return bswap_from_big(read<T>()); }

	// Read data from the stream
	void read( void *dest, size_t sz );

	// Was the file found?
	bool fileFound() { return !fileNotFound; }

private:
	enum { BUFFER_SIZE = 1024 };
	// Buffer containing uncompressed data
	unsigned char *data;
	// Amount of bytes left in data
	unsigned bufferLeft;
	// Current cursor within data
	unsigned char *cursor;
	// Was the file found?
	bool fileNotFound;
	// The input gzFile
	gzFile in;
};

// -----------------------------------------------------------------
gzistream::gzistream( const char *fn )
	: bufferLeft(0)
{
	// "Normal" read from a file
	in = gzopen( const_cast<char*>(fn), "rb" );
	fileNotFound = (in == Z_NULL);
	data = fileNotFound ? NULL : (unsigned char*)malloc( BUFFER_SIZE );
}

// -----------------------------------------------------------------
gzistream::gzistream( const char *fn, unsigned idx ) {
	// Read data from within a MCRegion file
	in = Z_NULL;
	fileNotFound = false;
	data = NULL;

	uint32_t position, len;

	// Open the file
	FILE *f = fopen( fn, "rb" );
	if( !f ) {
		fileNotFound = true;
		return;
	}
	if( idx < 1024 ) {
		// idx is a chunk index
		// Look up the sector index here
		fseek( f, (long)(idx<<2), SEEK_SET );
		fread( &position, 4, 1, f );
		position = (bswap_from_big(position) >> 8) << 12;
	} else {
		// idx is directly a sector index
		position = idx;
	}
	if( position == 0 ) {
		fileNotFound = true;
		return;
	}

	// Seek to the start
	fseek( f, (long)position, SEEK_SET );
	fread( &len, 4, 1, f );
	len = bswap_from_big(len);

	// Get the storage version
	unsigned char version;
	fread( &version, 1, 1, f );

	// Read all data
	void *fileBuf = malloc( len );
	fread( fileBuf, len-1, 1, f );
	fclose( f );

	// Uncompress the data
	uLongf bytesAvailable = 512*1024; // 512K buffer
	data = (unsigned char*)malloc( bytesAvailable );
	uncompress( data, &bytesAvailable, (unsigned char*)fileBuf, len-1 );
	free( fileBuf );

	bufferLeft = bytesAvailable;
	cursor = &data[0];
}

// -----------------------------------------------------------------
gzistream::~gzistream() {
	if( in != Z_NULL )
		gzclose( in );
	free( data );
}

// -----------------------------------------------------------------
void gzistream::read( void *dest, size_t sz ) {
	while( sz > bufferLeft ) {
		assert( in );

		memcpy( dest, cursor, bufferLeft );
		sz -= bufferLeft;
		dest = (char*)dest + bufferLeft;
		bufferLeft = (unsigned)gzread( in, data, BUFFER_SIZE );
		cursor = &data[0];
	}

	memcpy( dest, cursor, sz );
	cursor += sz;
	bufferLeft -= (unsigned)sz;
}

// -=-=-=-=------------------------------------------------------=-=-=-=-
class gzostream {
	// Helper output class which handles compression

public:
	gzostream() = delete;
	gzostream( const gzostream& ) = delete;
	gzostream( gzostream&& ) = delete;
	explicit gzostream( const char *fn )
	{
		// Only plain files supported for output (no MCRegion)
		out = gzopen( const_cast<char*>(fn), "wb" );
	}
	~gzostream() {
		if( out )
			gzclose( out );
	}

	// Write a character
	void put(char ch) { write(ch); }
	// Write a structure
	template< typename T >
	void write( T data ) { write( &data, sizeof(T) ); }
	// Write a big endian integer
	template< typename T >
	void writei( T data ) { write(bswap_to_big(data)); }
	// Write arbitrary date
	void write( const void *src, size_t sz ) { gzwrite( out, src, (unsigned)sz ); }

private:
	// The compressed output file
	gzFile out;
};


// ================================== NBT IO =================================

class nbtistream : private gzistream {
	// Input stream exposing more NBT-friently functions

public:
	nbtistream() = delete;
	nbtistream( const nbtistream& ) = delete;
	nbtistream( nbtistream&& ) = delete;
	nbtistream( const char *fn, unsigned idx )
		: gzistream( fn, idx ) { }
	explicit nbtistream( const char *filename )
		: gzistream( filename ) { }
	~nbtistream() { }

	using gzistream::fileFound;

	// Read a named tag
	void readNamedTag( std::string &name, Tag &tag );

private:
	// Read the data associated with a tag
	void readTagPayload( Tag &tag );
	// Read a list
	List *readList();
	// Read a compound
	Compound *readCompound();
};

// -----------------------------------------------------------------
void nbtistream::readNamedTag( std::string &name, Tag &tag ) {
	tag.type = (TagType)get();
	assert( tag.type < TAG_Count );
	if( tag.type == TAG_End ) {
		name = "";
	} else {
		size_t len = readi<uint16_t>();
		name.resize( len );
		read( &name[0], len );
		readTagPayload( tag );
	}
}

// -----------------------------------------------------------------
void nbtistream::readTagPayload( Tag &tag ) {
	switch( tag.type ) {
	case TAG_Byte:   tag.data.b = get(); break;
	case TAG_Short:  tag.data.s = readi<int16_t>(); break;
	case TAG_Float:
	case TAG_Int:    tag.data.i = readi<int32_t>(); break;
	case TAG_Double:
	case TAG_Long:   tag.data.l = readi<int64_t>(); break;
	case TAG_Byte_Array:
		tag.len = readi<uint32_t>();
		tag.data.bytes = malloc( tag.len );
		read( tag.data.bytes, tag.len );
		break;
	case TAG_String:
		tag.len = readi<int16_t>();
		tag.data.str = (char*)malloc( tag.len );
		read( tag.data.str, tag.len );
		break;
	case TAG_List:
		tag.data.list = readList();
		break;
	case TAG_Compound:
		tag.data.comp = readCompound();
		break;
	case TAG_Int_Array:
		tag.len = readi<uint32_t>();
		tag.data.ia = new int[tag.len];
		for( unsigned i = 0; i < tag.len; i++ )
			tag.data.ia[i] = readi<int32_t>();
		break;
	case TAG_Long_Array:
		tag.len = readi<uint32_t>();
		tag.data.il = new int64_t[tag.len];
		for( unsigned i = 0; i < tag.len; i++ )
			tag.data.il[i] = readi<int64_t>();
		break;
	case TAG_End:
		// NOTE: TAG_End's can be read if they are in a list
		break;
	default:
		assert( false );
	}
}

// -----------------------------------------------------------------
List *nbtistream::readList() {
	Tag tag;
	tag.type = (TagType)get();
	assert( tag.type < TAG_Count );

	unsigned len = readi<uint32_t>();
	List *l = new List( tag.type );
	for( unsigned i = 0; i < len; i++ ) {
		readTagPayload( tag );
		l->push_back( tag );
	}
	return l;
}

// -----------------------------------------------------------------
Compound *nbtistream::readCompound() {
	Compound *comp = new Compound;
	std::string name;
	Tag tag;

	while( true ) {
		readNamedTag( name, tag );
		if( tag.type == TAG_End )
			break;
		(*comp)[name] = tag;
	}

	return comp;
}

// -=-=-=-=------------------------------------------------------=-=-=-=-
class nbtostream : public gzostream {
	// Output stream exposing more NBT-friently functions

public:
	explicit nbtostream( const char *fn )
		: gzostream(fn) { }
	~nbtostream() { }

	// Write a named tag
	void writeNamedTag( const std::string &name, const Tag &tag );

private:
	// Write the data associated with a tag
	void writeTagPayload( const Tag &tag );
	// Write a string
	void writeString( const std::string &str );
	// Write a list
	void writeList( const List *l );
	// Write a Compount
	void writeCompound( const Compound *comp );
};

// -----------------------------------------------------------------
void nbtostream::writeNamedTag( const std::string &name, const Tag &tag ) {
	write( (unsigned char)tag.type );
	if( tag.type != TAG_End ) {
		writeString( name );
		writeTagPayload( tag );
	}
}

// -----------------------------------------------------------------
void nbtostream::writeTagPayload( const Tag &tag ) {
	switch( tag.type ) {
	case TAG_Byte:   write( (uint8_t)tag.data.b ); break;
	case TAG_Short:  writei( (uint16_t)tag.data.s ); break;
	case TAG_Float:
	case TAG_Int:    writei( (uint32_t)tag.data.i ); break;
	case TAG_Double:
	case TAG_Long:   writei( (uint64_t)tag.data.l ); break;
	case TAG_Byte_Array:
		writei( tag.len );
		write( tag.data.bytes, tag.len );
		break;
	case TAG_String:
		writei( uint16_t(tag.len) );
		write( tag.data.str, tag.len );
		break;
	case TAG_List:
		writeList( tag.data.list );
		break;
	case TAG_Compound:
		writeCompound( tag.data.comp );
		break;
	case TAG_Int_Array:
		writei( tag.len );
		for( unsigned i = 0; i < tag.len; i++ )
			writei( tag.data.ia[i] );
		break;
	case TAG_Long_Array:
		writei( tag.len );
		for( unsigned i = 0; i < tag.len; i++ )
			writei( (uint64_t)tag.data.il[i] );
		break;
	case TAG_End:
		break;
	default:
		assert( false );
	}
}

// -----------------------------------------------------------------
void nbtostream::writeString( const std::string &str ) {
	writei( uint16_t(str.length()) );
	write( static_cast<const void*>(str.data()), str.length() );
}

// -----------------------------------------------------------------
void nbtostream::writeList( const List *l ) {
	write( uint8_t(l->getType()) );
	writei( uint32_t(l->size()) );

	for( List::const_iterator it = l->begin(); it != l->end(); ++it ) {
		assert( it->type == l->getType() );
		writeTagPayload( *it );
	}
}

// -----------------------------------------------------------------
void nbtostream::writeCompound( const Compound *comp ) {
	for( Compound::const_iterator it = comp->begin(); it != comp->end(); ++it )
		writeNamedTag( it->first, it->second );
	Tag endTag;
	endTag.type = TAG_End;
	writeNamedTag( "", endTag );
}

// ============================== NBT Management =============================

void Tag::destroyPayload() {
	switch( type ) {
	case TAG_End:
	case TAG_Byte:
	case TAG_Short:
	case TAG_Int:
	case TAG_Long:
	case TAG_Float:
	case TAG_Double: break;
	case TAG_Byte_Array: free( data.bytes ); break;
	case TAG_String:     delete[] data.str;  break;
	case TAG_List:       delete   data.list; break;
	case TAG_Compound:   delete   data.comp; break;
	case TAG_Int_Array:  delete[] data.ia;   break;
	case TAG_Long_Array: delete[] data.il;   break;
	default: assert( false );
	}
	type = TAG_Int;
}

// -----------------------------------------------------------------
Compound::~Compound() {
	for( iterator it = begin(); it != end(); ++it ) 
		it->second.destroyPayload();
}

// -----------------------------------------------------------------
void Compound::eraseTag( const std::string &tagName ) {
	iterator it = find( tagName );
	if( it != end() ) {
		it->second.destroyPayload();
		erase( it );
	}
}

// -----------------------------------------------------------------
void Compound::replaceTag( const std::string &tagName, const Tag &newTag ) {
	eraseTag( tagName );
	(*this)[tagName] = newTag;
}

// -----------------------------------------------------------------
void Compound::write( const char *filename, const std::string &outerName ) {
	nbtostream nbtOut( filename );
	Tag me;
	me.type = TAG_Compound;
	me.data.comp = this;
	nbtOut.writeNamedTag( outerName, me );
}

// -----------------------------------------------------------------
void Compound::printReadable( std::ostream &out, const char *pre ) const {
	if( size() == 0 ) {
		out << "{ }";
		return;
	}

	out << "{" << std::endl;
	for( const_iterator it = begin(); it != end(); ++it ) {
		out << pre << '\t';
		std::string name( it->first.begin(), it->first.end() );
		switch( it->second.type ) {
		case TAG_Byte:
			out << "Byte " << name << " = " << (unsigned)it->second.data.b << std::endl;
			break;
		case TAG_Short:
			out << "Short " << name << " = " << it->second.data.s << std::endl;
			break;
		case TAG_Int:
			out << "Int " << name << " = " << it->second.data.i << std::endl;
			break;
		case TAG_Long:
			out << "Long " << name << " = " << it->second.data.l << std::endl;
			break;
		case TAG_Float:
			out << "Float " << name << " = " << it->second.data.f << std::endl;
			break;
		case TAG_Double:
			out << "Double " << name << " = " << it->second.data.d << std::endl;
			break;
		case TAG_Byte_Array:
			out << "Data " << name << ", size = " << it->second.getLength() << std::endl;
			break;
		case TAG_String:
			out << "String " << name << " = " << it->second.data.str << std::endl;
			break;
		case TAG_List: {
			out << "List " << name << std::endl;
			if( it->second.data.list->getType() == TAG_Compound ) {
				char newPre[32];
				strcpy( newPre, pre );
				strcat( newPre, "\t\t" );
				for( const auto& it1 : *it->second.data.list ) {
					out << pre << "\t\t" << "Compound ";
					it1.data.comp->printReadable( out, newPre );
					out << std::endl;
				}
			}
			} break;
		case TAG_Compound: {
				char newPre[32];
				strcpy( newPre, pre );
				strcat( newPre, "\t" );
				out << "Compound " << name << " ";
				it->second.data.comp->printReadable( out, newPre );
				out << std::endl;
			} break;
		case TAG_Int_Array:
			out << "IntArray " << name << ", size = " << it->second.getLength() << std::endl;
			break;
		case TAG_Long_Array: 
			out << "LongArray " << name << ", size = " << it->second.getLength() << std::endl;
			break;
		default: assert( false );
		}
	}
	out << pre << "}";
}


// -----------------------------------------------------------------
List::~List() {
	for( iterator it = begin(); it != end(); ++it )
		it->destroyPayload();
}


// ============================ NBT IO - Entrypoints =========================

Compound *readNBT( const char *filename, std::string *outerName ) {
	nbtistream is( filename );
	if( is.fileFound() ) {
		Tag tag;
		std::string name;
		is.readNamedTag( name, tag );
		assert( tag.type == TAG_Compound );
		if( outerName )
			*outerName = name;
		return tag.data.comp;
	}
	return NULL;
}

// -----------------------------------------------------------------
Compound *readFromRegionFile( const char *filename, unsigned idx ) {
	nbtistream is( filename, idx );
	if( is.fileFound() ) {
		Tag tag;
		std::string name;
		is.readNamedTag( name, tag );
		assert( tag.type == TAG_Compound );
		return tag.data.comp;
	}
	return NULL;
}

// -----------------------------------------------------------------
Compound *readFromRegionFileSector( const char *filename, unsigned sector ) {
	return readFromRegionFile( filename, sector<<12 );
}

} // namespace nbt
} // namespace eihort

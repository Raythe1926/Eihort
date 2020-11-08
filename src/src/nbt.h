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

#ifndef NBT_H
#define NBT_H

#include <list>
#include <map>
#include <string>
#include <iostream>
#include "stdint.h"

namespace eihort {
namespace nbt {

// Tag types present in NBT files
enum TagType {
	TAG_End			= 0,
	TAG_Byte		= 1,
	TAG_Short		= 2,
	TAG_Int			= 3,
	TAG_Long		= 4,
	TAG_Float		= 5,
	TAG_Double		= 6,
	TAG_Byte_Array	= 7,
	TAG_String		= 8,
	TAG_List		= 9,
	TAG_Compound	= 10,
	TAG_Int_Array   = 11,
	TAG_Long_Array  = 12,
	TAG_Count
};

union TagData;
class Compound;
class List;
struct Tag;
struct Array;

union TagData {
	// Union of all the possible data types

	int8_t b;
	int16_t s;
	int32_t i;
	int64_t l;
	float f;
	double d;
	void *bytes;
	char *str; // Not \0-terminated
	List *list;
	Compound *comp;
	int32_t *ia;
	int64_t *il;
};

struct Tag {
	// Tagged union for NBT data with the associated type

	// The type of data to be stored here
	TagType type;
	// Length of the data (for byte and int arrays)
	uint32_t len;
	// The data type to be stored here
	TagData data;

	// Deletes any data associated with this Tag
	void destroyPayload();
	// Get the size of this data
	inline uint32_t getLength() const { return len; }
};

class Compound : public std::map< std::string, Tag > {
	// NBT Compound

public:
	Compound() { }
	~Compound();

	// Does this Compound have a tag with the given name?
	inline bool has( const std::string &what ) const { return find(what)!=end(); }
	// Removes a named tag from the Compound
	void eraseTag( const std::string &tagName );
	// Replaces the named tag with a new one
	void replaceTag( const std::string &tagName, const Tag &newTag );
	// Writes the Compound to a file
	void write( const char *filename, const std::string &outerName );
	// Stringifies this Compound in a nice way
	void printReadable( std::ostream &out, const char *pre = "" ) const;
};

class List : public std::list< Tag > {
	// NBT List

public:
	inline List( TagType type )
		: std::list<Tag>(), type(type) { }
	~List();

	// Get the type of the objects in the list
	inline TagType getType() const { return type; }

private:
	// The type of the objects in the list
	TagType type;
};

// Read an NBT file
Compound *readNBT( const char *filename, std::string *outerName = NULL );
// Read an NBT file from a region file
Compound *readFromRegionFile( const char *filename, unsigned idx );
// Read an NBT file from the given sector of the region file
Compound *readFromRegionFileSector( const char *filename, unsigned idx );
// Read an NBT file from a region file, by XY coordinates
inline Compound *readFromRegionFile( const char *filename, unsigned x, unsigned y ) {
	return readFromRegionFile( filename, x+(y<<5) );
}

} // namespace nbt
} // namespace eihort

#endif

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


#include <string>
#include <cassert>
#include <cstring>

#include "mcmap.h"

namespace eihort {

// -----------------------------------------------------------------
MCMap::MCMap( MCRegionMap *regions )
: lastChunk(NULL)
, loadedList(NULL)
, loadedListTail(NULL)
, nLoadedChunks(0)
, regions(regions)
{
}

// -----------------------------------------------------------------
MCMap::~MCMap() {
}

// -----------------------------------------------------------------
bool MCMap::getBlockID( int x, int y, int z, unsigned short &id ) {
	if( z < 0 )
		return false;

	// Get the chunk the block is in
	Chunk *chunk = getChunk( x, y );
	if( !chunk )
		return false;

	// Look up the block ID directly
	if( z >= chunk->minZ && z <= chunk->maxZ ) {
		id = chunk->id[(toLinearCoordInChunk(x,y) << chunk->zHtShift) + z - chunk->minZ];
	} else {
		id = 0;
	}
	return true;
}

// -----------------------------------------------------------------
bool MCMap::getBiomeCoords( int x, int y, unsigned short &c ) {
	// If biome coordinates are contained in the chunk, return them

	Chunk *chunk = getChunk( x, y );
	if( !chunk || !chunk->biomes )
		return false;

	c = chunk->biomes[toLinearCoordInChunk(x,y)];
	return true;
}

// -----------------------------------------------------------------
bool MCMap::getColumn( int x, int y, MCMap::Column &col ) {
	Chunk *chunk = getChunk( x, y );
	if( chunk ) {
		int pos = toLinearCoordInChunk(x,y) << chunk->zHtShift;
		col.id = chunk->id + pos;
		pos >>= 1;
		col.data = chunk->data + pos;
		col.blockLight = chunk->blockLight + pos;
		col.skyLight = chunk->skyLight + pos;
		col.minZ = chunk->minZ;
		col.maxZ = chunk->maxZ;
		return true;
	}
	return false;
}

// -----------------------------------------------------------------
static bool strlneq( const char *left, size_t left_size, const char *right )
{
	std::size_t right_size = std::strlen( right );
	return left_size == right_size && memcmp( left, right, left_size ) == 0;
}

// -----------------------------------------------------------------
void MCMap::getSignsInArea( int minx, int maxx, int miny, int maxy, MCMap::SignList &signs ) {
	// Sign text is stored in the TileEntities section of maps,
	// separate from the block ID data.
	// Here, we search for all sign text TileEntities which
	// are inside that region of the map

	int maxChunkX = shift_right( maxx, 4 );
	int maxChunkY = shift_right( maxy, 4 );

	for( int chX = shift_right( minx, 4 ); chX <= maxChunkX; chX++ ) {
		for( int chY = shift_right( miny, 4 ); chY <= maxChunkY; chY++ ) {
			// This chunk overlaps the target region
			// Check all TileEntities in the chunk
			Chunk *chunk = getChunk( chX<<4, chY<<4 );
			if( !chunk )
				continue;

			nbt::Compound *level = (*chunk->nbt)["Level"].data.comp;
			nbt::List *entList = (*level)["TileEntities"].data.list;
			for( auto it = entList->begin(); it != entList->end(); ++it ) {
				assert( it->type == nbt::TAG_Compound );
				nbt::Compound *te = it->data.comp;
				const nbt::Tag &id = (*te)["id"];
				if( strlneq( id.data.str, id.len, "Sign" ) ||
						// Not rendered: strlneq( id.data.str, id.len, "minecraft:standing_sign" ) ||
						strlneq( id.data.str, id.len, "minecraft:wall_sign" ) ||
						strlneq( id.data.str, id.len, "minecraft:sign" ) ) {
					// *te is a nbt::Compound is a Sign TileEntity inside
					// a chunk which overlaps the target region

					SignDesc sign;
					sign.x = (*te)["z"].data.i;
					sign.y = (*te)["x"].data.i;
					if( sign.x >= minx && sign.x <= maxx && sign.y >= miny && sign.y <= maxy ) {
						// The sign is inside the target region - output it
						sign.z = (*te)["y"].data.i;
						Column col;
						getColumn( sign.x, sign.y, col );
						unsigned id = col.getId( sign.z );
						unsigned data = col.getData( sign.z );
						sign.onWall = id == 68;
						sign.orientation = data;

						// Get text
						sign.text[0] = (*te)["Text1"].data.str;
						sign.textLen[0] = (*te)["Text1"].len;
						sign.text[1] = (*te)["Text2"].data.str;
						sign.textLen[1] = (*te)["Text2"].len;
						sign.text[2] = (*te)["Text3"].data.str;
						sign.textLen[2] = (*te)["Text3"].len;
						sign.text[3] = (*te)["Text4"].data.str;
						sign.textLen[3] = (*te)["Text4"].len;
						signs.push_back( sign );
					}
				}
			}
		}
	}
}

// -----------------------------------------------------------------
void MCMap::clearAllLoadedChunks() {
	while( loadedList )
		unloadOneChunk();
}

// -----------------------------------------------------------------
MCMap::Chunk *MCMap::getChunk_impl( ChunkCoords &coords ) {
	// Check if the chunk is already loaded
	ChunkMap::iterator it = loadedChunks.find( coords );
	lastChunkCoords = coords;

	if( it != loadedChunks.end() ) {
		// It is.. move it to the end of the LRU list
		if( it->second.nextLoadedChunk ) {
			it->second.nextLoadedChunk->toMeLoaded = it->second.toMeLoaded;
			*it->second.toMeLoaded = it->second.nextLoadedChunk;

			loadedListTail->nextLoadedChunk = &it->second;
			it->second.toMeLoaded = &loadedListTail->nextLoadedChunk;
		}
	} else {
		// Nope. Try to load the chunk
		Chunk chunk;
		chunk.coords = coords;
		chunk.nbt = regions->readChunk( coords.x, coords.y );
		if( !chunk.nbt )
			return lastChunk = NULL;

		// Unload chunks if we have lots loaded
		if( nLoadedChunks >= 200 )
			unloadOneChunk();

		// Pass off the main loading work to the subclass's loading function
		if( !loadChunk( chunk ) )
			return lastChunk = NULL;
		
		// Chunk successfully loaded
		nLoadedChunks++;
		loadedChunks[coords] = chunk;

		// Link it at the end of the LRU list
		it = loadedChunks.find( coords );
		if( loadedListTail ) {
			loadedListTail->nextLoadedChunk = &it->second;
			it->second.toMeLoaded = &loadedListTail->nextLoadedChunk;
		} else {
			loadedList = &it->second;
			it->second.toMeLoaded = &loadedList;
		}
	}

	// Done
	lastChunk = loadedListTail = &it->second;
	loadedListTail->nextLoadedChunk = NULL;

	return loadedListTail;
}

// -----------------------------------------------------------------
void MCMap::unloadOneChunk() {
	assert( loadedList );
	
	ChunkCoords coords = loadedList->coords;

	// Delete the NBT structure for the chunk to free
	delete loadedList->nbt;
	loadedList->nbt = NULL;

	// Pass off the rest of the unload to the subclass
	unloadChunk( *loadedList );

	// Unlink the chunk from the LRU list
	if( loadedList->nextLoadedChunk ) {
		loadedList->nextLoadedChunk->toMeLoaded = loadedList->toMeLoaded;
	} else {
		lastChunk = loadedListTail = NULL;
	}
	*loadedList->toMeLoaded = loadedList->nextLoadedChunk;

	// Cleanup bookkeeping
	loadedChunks.erase( loadedChunks.find( coords ) );
	nLoadedChunks--;
}

// -----------------------------------------------------------------
MCMap_MCRegion::MCMap_MCRegion( MCRegionMap *regions )
: MCMap( regions )
{
}

// -----------------------------------------------------------------
MCMap_MCRegion::~MCMap_MCRegion() {
}

// -----------------------------------------------------------------
void MCMap_MCRegion::getExtentsWithin( int&, int&, int&, int&, int &minz, int &maxz ) {
	minz = 0;
	maxz = 127;
}

// -----------------------------------------------------------------
bool MCMap_MCRegion::loadChunk( MCMap::Chunk &chunk ) {
	// Eihort's internal data structures mirror the MCRegion
	// format (originally by design).
	// All we need to do here is point the chunk pointers at the
	// appropriate NBT arrays.

	nbt::Compound *level = (*chunk.nbt)["Level"].data.comp;
	chunk.blockLight = (unsigned char*)(*level)["BlockLight"].data.bytes;
	chunk.skyLight = (unsigned char*)(*level)["SkyLight"].data.bytes;
	chunk.data = (unsigned char*)(*level)["Data"].data.bytes;

	chunk.minZ = 0;
	chunk.maxZ = 127;
	chunk.zHtShift = 7;
	chunk.biomes = NULL;

	// To accommodate Anvil, Eihort uses 2-byte block IDs, but
	// MCRegion only provides 1 byte.
	const unsigned char *idsrc = (unsigned char*)(*level)["Blocks"].data.bytes;
	chunk.id = new unsigned short[16*16*128];
	for( unsigned i = 0; i < 16*16*128; i++ )
		chunk.id[i] = idsrc[i];

	return true;
}

// -----------------------------------------------------------------
void MCMap_MCRegion::unloadChunk( Chunk &chunk ) {
	delete[] chunk.id;
	chunk.id = NULL;
	chunk.blockLight = NULL;
	chunk.skyLight = NULL;
	chunk.data = NULL;
}

// -----------------------------------------------------------------
MCMap_Anvil::MCMap_Anvil( MCRegionMap *regions )
: MCMap( regions )
, biomeIdToCoords( )
{
}

// -----------------------------------------------------------------
MCMap_Anvil::~MCMap_Anvil() {
}

// -----------------------------------------------------------------
void MCMap_Anvil::getExtentsWithin( int &minx, int &maxx, int &miny, int &maxy, int &minz, int &maxz ) {
	int minChunkX = shift_right(minx,4), maxChunkX = shift_right(maxx+15,4);
	int minChunkY = shift_right(miny,4), maxChunkY = shift_right(maxy+15,4);
	
	// Make a tight bound around the 16x16x16 sub-chunks contained
	// in this part of the world
	int cminx = INT_MAX, cmaxx = INT_MIN;
	int cminy = INT_MAX, cmaxy = INT_MIN;
	int cminz = INT_MAX, cmaxz = INT_MIN;
	for( int cx = minChunkX; cx <= maxChunkX; cx++ ) {
		for( int cy = minChunkY; cy <= maxChunkY; cy++ ) {
			ChunkCoords coords = { cy, cx };
			Chunk *chunk = getChunk_impl( coords );
			if( chunk ) {
				cminx = std::min( cminx, cx << 4 );
				cmaxx = std::max( cmaxx, (cx << 4) + 15 );
				cminy = std::min( cminy, cy << 4 );
				cmaxy = std::max( cmaxx, (cy << 4) + 15 );
				cminz = std::min( cminz, chunk->minZ );
				cmaxz = std::max( cmaxz, chunk->maxZ );
			}
		}
	}
	
	minx = std::max( minx, cminx );
	maxx = std::min( maxx, cmaxx );
	miny = std::max( miny, cminy );
	maxy = std::min( maxy, cmaxy );
	minz = std::max( minz, cminz );
	maxz = std::min( maxz, cmaxz );
}

// -----------------------------------------------------------------
void MCMap_Anvil::setBiomeCoordData( const BiomeCoordData& data ) {
	biomeIdToCoords = data;
}

// -----------------------------------------------------------------
bool MCMap_Anvil::loadChunk( MCMap::Chunk &chunk ) {
	// To support Anvil, we currently simply transform the Anvil structures into
	// the equivalent MCRegion structure

	nbt::Compound *level = (*chunk.nbt)["Level"].data.comp;
	nbt::List *sections = (*level)["Sections"].data.list;

	// Find the min and max Z of this chunk
	chunk.minZ = INT_MAX;
	chunk.maxZ = INT_MIN;
	for( nbt::List::const_iterator it = sections->begin(); it != sections->end(); ++it ) {
		assert( it->type == nbt::TAG_Compound );
		int zbase = (*it->data.comp)["Y"].data.b << 4;
		if( zbase < chunk.minZ )
			chunk.minZ = zbase;
		if( zbase + 15 > chunk.maxZ )
			chunk.maxZ = zbase + 15;
	}

	if( chunk.minZ == INT_MAX )
		return false;

	// Allocate memory for all the data
	unsigned zHeight = chunk.maxZ - chunk.minZ + 1;
	unsigned zSections = zHeight>>4;
	chunk.zHtShift = 4;
	while( zHeight > (1u << chunk.zHtShift) )
		chunk.zHtShift++;

	unsigned blocks = (16*16) << chunk.zHtShift;
	chunk.id = new unsigned short[blocks];
	chunk.blockLight = new unsigned char[blocks>>1];
	chunk.skyLight = new unsigned char[blocks>>1];
	chunk.data = new unsigned char[blocks>>1];
	memset( chunk.id, 0, blocks<<1 );
	memset( chunk.blockLight, 0, blocks>>1 );
	memset( chunk.skyLight, 0, blocks>>1 );
	memset( chunk.data, 0, blocks>>1 );
	bool *zSectionFilled = new bool[zSections];
	for( unsigned i = 0; i < zSections; i++ )
		zSectionFilled[i] = false;

	for( auto it = sections->begin(); it != sections->end(); ++it ) {
		// Copy each section into the large data arrays

		assert( it->type == nbt::TAG_Compound );
		nbt::Compound *section = it->data.comp;
		int zbase = (*section)["Y"].data.b;
		zbase = (zbase << 4) - chunk.minZ;
		zSectionFilled[zbase>>4] = true;

		unsigned char *idSrc = (unsigned char*)(*section)["Blocks"].data.bytes;
		unsigned char *blockLightSrc = (unsigned char*)(*section)["BlockLight"].data.bytes;
		unsigned char *skyLightSrc = (unsigned char*)(*section)["SkyLight"].data.bytes;
		unsigned char *dataSrc = (unsigned char*)(*section)["Data"].data.bytes;
		unsigned char *addSrc = NULL;
		if( section->find( "Add" ) != section->end() )
			addSrc = (unsigned char*)(*section)["Add"].data.bytes;

		for( int zo = 0; zo < 16; zo++ ) {
			for( int yo = 0; yo < 16; yo++ ) {
				for( int xo = 0; xo < 16; xo++ ) {
					unsigned destIdx = (((xo<<4)+yo) << chunk.zHtShift) + zbase + zo;
					unsigned srcIdx = (zo<<8)+(yo<<4)+xo;
					unsigned src4Shift = ((srcIdx&1u)<<2);
					unsigned dest4Shift = ((destIdx&1u)<<2);

					chunk.id[destIdx] = idSrc[srcIdx];
					if( addSrc )
						chunk.id[destIdx] += (unsigned short)((addSrc[srcIdx>>1] >> src4Shift) & 0xfu) << 8;

					chunk.blockLight[destIdx>>1] |= ((blockLightSrc[srcIdx>>1] >> src4Shift) & 0xfu) << dest4Shift;
					chunk.skyLight[destIdx>>1] |= ((skyLightSrc[srcIdx>>1] >> src4Shift) & 0xfu) << dest4Shift;
					chunk.data[destIdx>>1] |= ((dataSrc[srcIdx>>1] >> src4Shift) & 0xfu) << dest4Shift;
				}
			}
		}
	}

	if( level->find( "Biomes" ) != level->end() ) {
		// With Anvil, biomes are now stored directly in the world file

		unsigned char *biomeIds = (unsigned char*)(*level)["Biomes"].data.bytes;
		chunk.biomes = new unsigned short[16*16];
		for( unsigned i = 0; i < 16*16; i++ ) {
			if( biomeIds[i] < biomeIdToCoords.size() ) {
				chunk.biomes[(i>>4)+((i&0xf)<<4)] = biomeIdToCoords[biomeIds[i]];
			} else {
				chunk.biomes[i] = 0x7F7Fu;
			}
		}
	} else {
		chunk.biomes = NULL;
	}

	// Fill in sections for which we have no data with default data
	for( unsigned zs = 0; zs < zSections; zs++ ) {
		if( !zSectionFilled[zs] ) {
			unsigned zbase = zs << 4;
			for( unsigned x = 0; x < 16; x++ ) {
				for( unsigned y = 0; y < 16; y++ ) {
					unsigned xyc = toLinearCoordInChunk(x,y) << chunk.zHtShift;
					for( unsigned zo = 0; zo < 16; zo+=2 ) {
						// TODO: Copy the top block's luminance
						// for now, full sun in skipped blocks
						chunk.skyLight[(xyc+zbase+zo)>>1] = 0xffu;
					}
				}
			}
		}
	}

	delete[] zSectionFilled;

	return true;
}

// -----------------------------------------------------------------
void MCMap_Anvil::unloadChunk( Chunk &chunk ) {
	delete[] chunk.id;
	chunk.id = NULL;
	delete[] chunk.blockLight;
	chunk.blockLight = NULL;
	delete[] chunk.skyLight;
	chunk.skyLight = NULL;
	delete[] chunk.data;
	chunk.data = NULL;
	delete[] chunk.biomes;
	chunk.biomes = NULL;
}

} // namespace eihort

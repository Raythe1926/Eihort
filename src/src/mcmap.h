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

#ifndef MCMAP_H
#define MCMAP_H

#include <map>
#include <string>
#include <vector>

#include "nbt.h"
#include "jmath.h"
#include "mcregionmap.h"
#include "platform.h"

namespace eihort {

class MCMap {
	// This class abstracts the low-level chunk-based representation of
	// a Minecraft map, and presents a significantly easier-to-work-with
	// map which is seamless.
	// MCMap also serves as a base class to subclasses capable of loading
	// the world from different sources, e.g. Anvil and MCRegion.

public:
	virtual ~MCMap();

	struct Column {
		// The basic map access structure
		// Column represents a column of blocks in space
		// Blocks are indexed by their height in the world (in Eihort, this is the z axis)

		// Get the ID of a block
		inline unsigned getId( int z ) const { return z < minZ ? (z < 0 ? 7 : 0) : z > maxZ ? 0 : id[z-minZ]; }
		// Get the data field of a block
		inline unsigned getData( int z ) const { return get4BitsAtSafe( data, z, 0 ); }
		// Get the level of block lighting
		inline unsigned getBlockLight( int z ) const { return get4BitsAtSafe( blockLight, z, 0 ); }
		// Get the level of sky lighting
		inline unsigned getSkyLight( int z ) const { return get4BitsAtSafe( skyLight, z, 0xf ); }
		// Get the height of the column
		inline unsigned getHeight() const { return maxZ-minZ+1; }

		// Helper to get a 4-bit field
		static inline unsigned get4bitsAt( unsigned char *dat, unsigned zo )
			{ return (unsigned)((dat[zo>>1] >> ((zo&1)<<2)) & 0xf); }
		// Z-checked helper to get a 4-bit field
		inline unsigned get4BitsAtSafe( unsigned char *dat, int z, unsigned high ) const
			{ return z < minZ ? 0 : z > maxZ ? high : get4bitsAt(dat, z-minZ); }

		// Array of block IDs
		unsigned short *id;
		// Array of block data (stored two per byte)
		unsigned char *data;
		// Array of block light values (stored two per byte)
		unsigned char *blockLight;
		// Array of sky light values (stored two per byte)
		unsigned char *skyLight;
		// Z extents of this column
		int minZ, maxZ;
	};

	// Access the block ID at a point in the world
	bool getBlockID( int x, int y, int z, unsigned short &id );
	// Get the biome coordinates at a point in the world
	bool getBiomeCoords( int x, int y, unsigned short &c );
	// Access the data for an entire column of the world
	bool getColumn( int x, int y, Column &col );

	// Get the extents in the X/Y plane of the world
	void getXYExtents( int &minx, int &maxx, int &miny, int &maxy );
	// Get the underlying region map
	MCRegionMap *getRegions() { return regions; }

	// Get the extents of the world within a given block of space
	virtual void getExtentsWithin( int &minx, int &maxx, int &miny, int &maxy, int &minz, int &maxz ) = 0;
	
	struct SignDesc {
		// Sign description

		// Position of the sign
		int x, y, z;
		// Is the sign on a wall?
		bool onWall;
		// Orientation of the sign, for non-wall signs
		unsigned orientation;
		// Text on the sign
		const char *text[4];
		// Lengths of the text fields
		uint32_t textLen[4];
	};
	// A list of sign descriptions
	typedef std::list<SignDesc> SignList;
	// Retrieve all the signs within a given region of the map
	void getSignsInArea( int minx, int maxx, int miny, int maxy, SignList &signs );
	
	// Clear all the currently-loaded chunks
	void clearAllLoadedChunks();

protected:
	// Initialize the MCMap with the given chunk source
	explicit MCMap( MCRegionMap *regions );

	struct Chunk {
		// A loaded map chunk
		// Chunks are loaded in memory in the old (pre-Anvil) format

		// The NBT containing the chunk data
		nbt::Compound *nbt;
		// The chunk's block data array
		unsigned char *data;
		// The chunk's block ID array
		unsigned short *id;
		// The chunk's block lighting array
		unsigned char *blockLight;
		// The chunk's sky lighting array
		unsigned char *skyLight;
		// The chunk's biome coordinates, if available
		unsigned short *biomes;
		// The next loaded chunk in the LRU list of loaded chunks
		Chunk *nextLoadedChunk;
		// A pointer to the pointer pointing to this Chunk
		Chunk **toMeLoaded;
		// The coordinates of the chunk in the world
		ChunkCoords coords;
		// The minimum and maximum Z values in the chunk
		int minZ, maxZ;
		// (1<<zHtShift) is the pitch of the columns in all data arrays
		unsigned zHtShift;
	};

	// Converts an (x,y) position in a chunk to a single contiguous
	// index within the chunk
	static inline unsigned toLinearCoordInChunk( int x, int y ) {
		return (((unsigned)y&15)<<4) | ((unsigned)x&15);
	}

	// Get a chunk, loading it if necessary
	inline Chunk *getChunk( int x, int y ) {
		ChunkCoords coords;
		coords.x = shift_right( y, 4 );
		coords.y = shift_right( x, 4 );

		// Chunk requests are expected to be very coherent
		// Check the last chunk accessed is the one we want
		if( lastChunkCoords == coords )
			return lastChunk;

		// Fall back to the heavier chunk lookup function
		return getChunk_impl( coords );
	}
	// Looks up a chunk by coordinates
	// The chunk is loaded if necessary
	Chunk *getChunk_impl( ChunkCoords &coords );
	// Chunk loading function
	// Returns true on success
	virtual bool loadChunk( Chunk &chunk ) = 0;
	// Chunk unloading function
	virtual void unloadChunk( Chunk &chunk ) = 0;

	// Last chunk accessed
	ChunkCoords lastChunkCoords;
	Chunk *lastChunk;

	// Coordinate -> loaded Chunk map
	typedef std::map< ChunkCoords, Chunk > ChunkMap;
	// Current map of loaded chunks
	ChunkMap loadedChunks;

	// Unloads the least recently used chunk
	void unloadOneChunk();
	// Head of the LRU list of chunks
	Chunk *loadedList;
	// Tail of the LRU list of chunks
	Chunk *loadedListTail;
	// Number of currently loaded chunks
	unsigned nLoadedChunks;

	// Raw chunk data source
	MCRegionMap *regions;
};

class MCMap_MCRegion : public MCMap {
	// MCRegion-loading implementation of MCMap

public:
	// Create a MCRegion map reader from the given chunk source
	explicit MCMap_MCRegion( MCRegionMap *regions );
	virtual ~MCMap_MCRegion();

	virtual void getExtentsWithin( int &minx, int &maxx, int &miny, int &maxy, int &minz, int &maxz );

protected:
	virtual bool loadChunk( Chunk &chunk );
	virtual void unloadChunk( Chunk &chunk );
};

// Translation table for biome ID -> coordinates
typedef std::vector< unsigned short > BiomeCoordData;

class MCMap_Anvil : public MCMap {
	// Anvil-loading implementation of MCMap

public:
	// Create an Anvil map reader from the given chunk source
	explicit MCMap_Anvil( MCRegionMap *regions );
	virtual ~MCMap_Anvil();

	virtual void getExtentsWithin( int &minx, int &maxx, int &miny, int &maxy, int &minz, int &maxz );

	// Set up biome ID -> coordinate table
	void setBiomeCoordData( const BiomeCoordData& data );

protected:
	virtual bool loadChunk( Chunk &chunk );
	virtual void unloadChunk( Chunk &chunk );

	// Lookup table to translate biome IDs to coordinates
	BiomeCoordData biomeIdToCoords;
};

} // namespace eihort

#endif


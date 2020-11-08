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

#ifndef MCREGIONMAP_H
#define MCREGIONMAP_H

#include <string>
#include <SDL.h>

#include "luaobject.h"
#include "nbt.h"

struct lua_State;

namespace eihort {

class MCBiome;

struct ChunkCoords {
	// Chunk coordinates

	inline bool operator< ( const ChunkCoords &rhs ) const {
		return x < rhs.x || (x == rhs.x && y < rhs.y);
	}
	inline bool operator== ( const ChunkCoords &rhs ) const {
		return x == rhs.x && y == rhs.y;
	}

	// X and Y coordinates of the chunk
	int x, y;
};

typedef ChunkCoords RegionCoords;

class MCRegionMap : public LuaObject {
	// Provides raw chunk data to MCMap implementations

public:
	// Create a new MCRegionMap, with the given root path
	explicit MCRegionMap( const char *rootPath, bool anvil = true );
	~MCRegionMap();

	class ChangeListener {
		// Base class for chunk change listeners

	public:
		virtual ~ChangeListener();

		// The chunk with coordinates (x,y) changed!
		virtual void chunkChanged( int x, int y ) = 0;

	protected:
		ChangeListener();
	};

	// Get extents in chunk coordinates of an entire region
	static inline void regionCoordsToChunkExtents( int x, int y, int &minx, int &maxx, int &miny, int &maxy ) {
		const unsigned rgShift = 5; // 32 chunks/region
		minx = x << rgShift;
		maxx = minx + (1 << rgShift) - 1;
		miny = y << rgShift;
		maxy = miny + (1 << rgShift) - 1;
	}

	// Get the extents of a chunk in the world
	static inline void chunkCoordsToBlockExtents( int x, int y, int &minx, int &maxx, int &miny, int &maxy ) {
		const unsigned rgShift = 4; // 16 blocks/chunk
		minx = x << rgShift;
		maxx = minx + (1 << rgShift) - 1;
		miny = y << rgShift;
		maxy = miny + (1 << rgShift) - 1;
	}

	// Get the extents (in chunks) of the entire world
	void getWorldChunkExtents( int &minx, int &maxx, int &miny, int &maxy );
	// Get the extents (in blocks) of the entire world
	void getWorldBlockExtents( int &minx, int &maxx, int &miny, int &maxy );
	// Get the number of regions found
	inline unsigned getTotalRegionCount() const { return (unsigned)regions.size(); }

	// Read the NBT for a chunk
	// x and y are in chunk coords (that is, blockxy/16)
	// This function is thread-safe
	nbt::Compound *readChunk( int x, int y );

	// Change the root folder and re-search for regions
	void changeRoot( const char *newRoot, bool anvil = true );
	// Get the current root folder
	const std::string &getRoot() const { return root; }
	// Is this an Anvil MCRegionMap?
	bool isAnvil() const { return anvil; }

	// Poll for changes in the world
	void checkForRegionChanges();
	// Set the chunk change listener
	inline void setListener( ChangeListener *l ) { listener = l; }

	// Lua functions
	// Documented in the World Loading section of Eihort Lua API.txt

	static int lua_create( lua_State *L );
	static int lua_getRegionCount( lua_State *L );
	static int lua_getRootPath( lua_State *L );
	static int lua_changeRootPath( lua_State *L );
	static int lua_setMonitorState( lua_State *L );
	static int lua_createView( lua_State *L );
	static int lua_destroy( lua_State *L );
	static void setupLua( lua_State *L );

private:
	struct RegionDesc {
		// Region descriptor

		// File sectors at which the chunks are stored
		uint32_t *sectors;
		// The last update time of each chunk
		uint32_t *chunkTimes;
	};

	// Scan the directory structure to find region files
	void exploreDirectories();
	// Clear all cached data on the regions
	void flushRegionSectors();
	// Poll a specific region for changes
	void checkRegionForChanges( int x, int y, RegionDesc *region );
	// Get the last update time of a specific chunk
	bool getChunkInfo( int x, int y, unsigned &updTime );

	// Entry point for the change scanning thread
	static int updateScanner( void *rgMapCookie );
	// Get the extension of the region files
	const char *getRegionExt() const { return anvil ? "mca" : "mcr"; }

	// Root path to search for region files in
	std::string root;
	// Is this world in Anvil format?
	bool anvil;

	// World extents, in regions
	int minRgX, maxRgX, minRgY, maxRgY;
	// Region coordinate -> descriptor mapping
	typedef std::map< RegionCoords, RegionDesc > RegionMap;
	// Region coordinate -> descriptor mapping
	RegionMap regions;

	// The chunk change monitor thread
	SDL_Thread *changeThread;
	// Region descriptor mutex
	SDL_mutex *rgDescMutex;
	// The chunk change listener
	ChangeListener *listener;
	// Should we watch for chunk changes?
	bool watchUpdates;
};

} // namespace eihort

#endif // MCREGIONMAP_H

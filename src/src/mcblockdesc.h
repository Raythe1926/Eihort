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

#ifndef MCBLOCKDESC_H
#define MCBLOCKDESC_H

#include "luaobject.h"
#include "mcbiome.h"

// Lua metatable name
#define MCBLOCKDESC_META "MCBlockDesc"

#define SIGNTEXT_BLOCK_ID (1u<<12)
#define BLOCK_ID_COUNT ((1u<<12)+1)

namespace eihort {

namespace geom {
	class BlockGeometry;
}

class MCBlockDesc : public LuaObject {
	// MCBlockDesc is a container for all of the geometry generators used
	// to create the world.

public:
	MCBlockDesc();
	~MCBlockDesc();

	// Returns whether this block id should be highlighted
	inline unsigned shouldHighlight( unsigned id ) const { return blockFlags[id] & 0x80u; }
	// Get the solidity of a block from the given direction
	inline unsigned getSolidity( unsigned id, unsigned dir ) const { return blockFlags[id] & (1u<<dir); }
	// Get the geometry generator for a block id
	inline geom::BlockGeometry *getGeometry( unsigned id ) const { return geometry[id]; }
	// Is block lighting enabled globally?
	inline bool enableBlockLighting() const { return blockLighting; }

	// Override the "sky" brightness for all air blocks
	inline void setDefAirSkyLight( unsigned light, bool override = false ) { defAirSkyLight = light; overrideAirSkyLight = override; }
	// Is the sky brightness overrided?
	inline bool getDefAirSkyLightOverride() const { return overrideAirSkyLight; }
	// Get the overrided sky brightness
	inline unsigned getDefAirSkyLight() const { return defAirSkyLight; }
	
	// Locks the class from changes
	inline void lock() { lockCount++; }
	// Unlocks the class
	void unlock();
	// Are changes allowed?
	inline bool isLocked() { return lockCount > 0; }

	// Get the biome texture manager
	inline const MCBiome *getBiomes() const { return &biomes; }

	// Lua functions
	// Documented in the Block Description section of Eihort Lua API.txt

	static int lua_create( lua_State *L );
	static int lua_setGeometry( lua_State *L );
	static int lua_setSolidity( lua_State *L );
	static int lua_setHighlight( lua_State *L );
	static int lua_noBLockLighting( lua_State *L );
	static int lua_setDefAirSkylight( lua_State *L );
	static int lua_isLocked( lua_State *L );
	static int lua_setBiomeRoot( lua_State *L );
	static int lua_setBiomeChannel( lua_State *L );
	static int lua_setBiomeDefaultPos( lua_State *L );
	static int lua_destroy( lua_State *L );
	static void setupLua( lua_State *L );

private:
	// Solidity (lower 6 bits) and highlight (high bit) flags
	unsigned char blockFlags[BLOCK_ID_COUNT];
	// Geometry generators for each block ID
	geom::BlockGeometry *geometry[BLOCK_ID_COUNT];
	// The biome texture manager
	MCBiome biomes;
	// Global blocklighting flag
	bool blockLighting;

	// Overrided sky brightness
	unsigned defAirSkyLight;
	// Should the sky brightness be overrided?
	bool overrideAirSkyLight;

	// Number of locks preventing this object from being modified
	unsigned lockCount;
};

} // namespace eihort

#endif

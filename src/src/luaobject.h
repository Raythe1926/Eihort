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

#ifndef LUAOBJECT_H
#define LUAOBJECT_H

#include <lua.hpp>
#include <cassert>

class LuaObject {
	// This class is intended to be a base class for classes which can also
	// be Lua objects, mainly just for the utillity of the lua_push function.

public:
	LuaObject() : luaRegIdx(LUA_NOREF), luaL(NULL) { }
	~LuaObject() {
		if( luaL ) {
			// Unregister this object from Lua
			lua_push();
			*(void**)lua_touserdata( luaL, -1 ) = NULL;
			lua_pop( luaL, 1 );
			luaL_unref( luaL, LUA_REGISTRYINDEX, luaRegIdx );
		}
	}

	// Pushes this object on the Lua stack
	inline void lua_push() {
		lua_rawgeti( luaL, LUA_REGISTRYINDEX, luaRegIdx );
	}

protected:
	// Sets up the Lua counterpart to this object
	// Should be called upon initialization of the object
	inline void setupLuaObject( lua_State *L, const char *metaName ) {
		assert( !luaL );
		luaL = L;
		void **ppvObj = (void**)lua_newuserdata( L, sizeof(void*) );
		*ppvObj = this;
		luaL_newmetatable( L, metaName );
		lua_setmetatable( L, -2 );
		luaRegIdx = luaL_ref( L, LUA_REGISTRYINDEX );
	}

private:
	// Index of this object in the Lua Registry
	int luaRegIdx;
	// The Lua state in which this object resides
	lua_State *luaL;
};

// Get a Lua userdata object which has the given metatable
template< typename T >
static inline T *getLuaObjectArg( lua_State *L, int arg, const char *metaName ) {
	void **ppvObj = (void**)luaL_checkudata( L, arg, metaName );
	return static_cast<T*>((LuaObject*)*ppvObj);
}

#endif //LUAOBJECT_H

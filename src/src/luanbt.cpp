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


#include <lua.hpp>
#include <cassert>
#include <cstring>
#include <sstream>

#include "luanbt.h"
#include "nbt.h"

using namespace eihort;

// -----------------------------------------------------------------
static nbt::TagType stringToTagType( const char *name ) {
	switch( *name ) {
		case 'b':
			if( 0 == strcmp( name, "byte" ) )
				return nbt::TAG_Byte;
			if( 0 == strcmp( name, "bytearray" ) )
				return nbt::TAG_Byte_Array;
			break;
		case 'c':
			if( 0 == strcmp( name, "compound" ) )
				return nbt::TAG_Compound;
			break;
		case 'd':
			if( 0 == strcmp( name, "double" ) )
				return nbt::TAG_Double;
			break;
		case 'f':
			if( 0 == strcmp( name, "float" ) )
				return nbt::TAG_Float;
			break;
		case 'i':
			if( 0 == strcmp( name, "int" ) )
				return nbt::TAG_Int;
			break;
		case 'l':
			if( 0 == strcmp( name, "long" ) )
				return nbt::TAG_Long;
			if( 0 == strcmp( name, "list" ) )
				return nbt::TAG_List;
			break;
		case 's':
			if( 0 == strcmp( name, "string" ) )
				return nbt::TAG_String;
			if( 0 == strcmp( name, "short" ) )
				return nbt::TAG_Short;
			break;
	}
	return nbt::TAG_Count;
}

// -----------------------------------------------------------------
static const char *tagTypeToString( nbt::TagType type ) {
	switch( type ) {
	case nbt::TAG_Byte: return "byte";
	case nbt::TAG_Short: return "short";
	case nbt::TAG_Float: return "float";
	case nbt::TAG_Int: return "int";
	case nbt::TAG_Double: return "double";
	case nbt::TAG_Long: return "long";
	case nbt::TAG_Byte_Array: return "bytearray";
	case nbt::TAG_String: return "string";
	case nbt::TAG_List: return "list";
	case nbt::TAG_Compound: return "compound";
	default:
		return "unknown";
	}
}

// -----------------------------------------------------------------
static void luaGetTagData( lua_State *L, nbt::Tag &tag, int idx ) {
	switch( tag.type ) {
	case nbt::TAG_Byte:
		tag.data.b = (int8_t)luaL_checkint( L, idx );
		break;
	case nbt::TAG_Short:
		tag.data.s = (int16_t)luaL_checkint( L, idx );
		break;
	case nbt::TAG_Float:
		tag.data.f = (float)luaL_checknumber( L, idx );
		break;
	case nbt::TAG_Int:
		tag.data.i = (int32_t)luaL_checkint( L, idx );
		break;
	case nbt::TAG_Double:
		tag.data.d = (double)luaL_checknumber( L, idx );
		break;
	case nbt::TAG_Long:
		tag.data.l = (int64_t)luaL_checknumber( L, idx );
		break;
	case nbt::TAG_Byte_Array: {
		size_t len;
		const char *bytes = luaL_checklstring( L, idx, &len );
		tag.len = (uint32_t)len;
		tag.data.bytes = malloc( len );
		memcpy( tag.data.bytes, bytes, len );
		break; }
	case nbt::TAG_String: {
		size_t len;
		const char *s = luaL_checklstring( L, idx, &len );
		tag.len = (uint32_t)len;
		tag.data.str = (char*)malloc( len );
		memcpy( tag.data.str, s, len );
		break; }
	case nbt::TAG_List:
		tag.data.list = *(nbt::List**)luaL_checkudata( L, idx, LUANBTLIST_META );
		break;
	case nbt::TAG_Compound:
		tag.data.comp = *(nbt::Compound**)luaL_checkudata( L, idx, LUANBTCOMPOUND_META );
		break;
	default:
		assert(false);
	}
}

// -----------------------------------------------------------------
static void luaPushTagData( lua_State *L, const nbt::Tag &tag ) {
	switch( tag.type ) {
	case nbt::TAG_Byte: lua_pushnumber( L, tag.data.b ); return;
	case nbt::TAG_Short: lua_pushnumber( L, tag.data.s ); return;
	case nbt::TAG_Float: lua_pushnumber( L, tag.data.f ); return;
	case nbt::TAG_Int: lua_pushnumber( L, tag.data.i ); return;
	case nbt::TAG_Double: lua_pushnumber( L, tag.data.d ); return;
	case nbt::TAG_Long: lua_pushnumber( L, (lua_Number)tag.data.l ); return;
	case nbt::TAG_Byte_Array: lua_pushlstring( L, (char*)tag.data.bytes, tag.len ); return;
	case nbt::TAG_String: lua_pushlstring( L, tag.data.str, tag.len ); return;
	case nbt::TAG_List:
		*(nbt::List**)lua_newuserdata( L, sizeof(nbt::List*) ) = tag.data.list;
		luaL_newmetatable( L, LUANBTLIST_META );
		lua_setmetatable( L, -2 );
		return;
	case nbt::TAG_Compound:
		*(nbt::Compound**)lua_newuserdata( L, sizeof(nbt::Compound*) ) = tag.data.comp;
		luaL_newmetatable( L, LUANBTCOMPOUND_META );
		lua_setmetatable( L, -2 );
		return;
	default:
		lua_pushnil( L );
		return;
	}
}

// -----------------------------------------------------------------
static int luaNBTCompGet( lua_State *L ) {
	// value, tagtype = nbt:get( name )
	nbt::Compound *comp = *(nbt::Compound**)luaL_checkudata( L, 1, LUANBTCOMPOUND_META );
	size_t len;
	const char *name = luaL_checklstring( L, 2, &len );
	nbt::Compound::const_iterator it = comp->find( name );
	if( it != comp->end() ) {
		luaPushTagData( L, it->second );
		lua_pushstring( L, tagTypeToString( it->second.type ) );
		return 2;
	} else {
		return 0;
	}
}

// -----------------------------------------------------------------
static int luaNBTCompSet( lua_State *L ) {
	// nbt:set( name, value, type )
	nbt::Tag tag;
	nbt::Compound *comp = *(nbt::Compound**)luaL_checkudata( L, 1, LUANBTCOMPOUND_META );
	size_t namelen;
	const char *name = luaL_checklstring( L, 2, &namelen );
	tag.type = stringToTagType( luaL_checkstring( L, 4 ) );
	luaL_argcheck( L, tag.type != nbt::TAG_Count, 4, "Not a valid NBT type" );

	luaGetTagData( L, tag, 3 );

	comp->replaceTag( name, tag );
	return 0;
}

// -----------------------------------------------------------------
static int luaNBTCompNewCompound( lua_State *L ) {
	// nbt2 = nbt:newCompount( name )
	nbt::Compound *comp = *(nbt::Compound**)luaL_checkudata( L, 1, LUANBTCOMPOUND_META );
	size_t namelen;
	const char *name = luaL_checklstring( L, 2, &namelen );

	nbt::Compound *newComp = new nbt::Compound;
	nbt::Tag tag;
	tag.type = nbt::TAG_Compound;
	tag.data.comp = newComp;
	comp->replaceTag( name, tag );

	*(nbt::Compound**)lua_newuserdata( L, sizeof(nbt::Compound*) ) = newComp;
	luaL_newmetatable( L, LUANBTCOMPOUND_META );
	lua_setmetatable( L, -2 );
	return 1;
}

// -----------------------------------------------------------------
static int luaNBTCompNewList( lua_State *L ) {
	// list = nbt:newList( name, tagtype )
	nbt::Compound *comp = *(nbt::Compound**)luaL_checkudata( L, 1, LUANBTCOMPOUND_META );
	size_t namelen;
	const char *name = luaL_checklstring( L, 2, &namelen );
	nbt::TagType type = stringToTagType( luaL_checkstring( L, 3 ) );
	luaL_argcheck( L, type != nbt::TAG_Count, 3, "Not a valid NBT type" );
	luaL_argcheck( L, type != nbt::TAG_Byte_Array, 3, "Array of byte arrays is not allowed" );

	nbt::List *newList = new nbt::List( type );
	nbt::Tag tag;
	tag.type = nbt::TAG_List;
	tag.data.list = newList;
	comp->replaceTag( name, tag );

	*(nbt::List**)lua_newuserdata( L, sizeof(nbt::List*) ) = newList;
	luaL_newmetatable( L, LUANBTLIST_META );
	lua_setmetatable( L, -2 );
	return 1;
}

// -----------------------------------------------------------------
static int luaNBTIterateNext( lua_State *L ) {
	nbt::Compound *comp = *(nbt::Compound**)luaL_checkudata( L, 2, LUANBTCOMPOUND_META );

	// Get an iterator for the current position
	size_t len;
	nbt::Compound::const_iterator it;
	if( lua_isnil( L, 1 ) ) {
		it = comp->begin();
	} else {
		const char *name = luaL_checklstring( L, 2, &len );
		it = comp->find( name );
		if( it == comp->end() )
			return 0; // In case we're modifying the compound mid-iteration
		++it;
	}

	// At end?
	if( it == comp->end() )
		return 0;

	// Push the next named value
	lua_pushlstring( L, it->first.data(), int(it->first.length()) );
	luaPushTagData( L, it->second );
	lua_pushstring( L, tagTypeToString( it->second.type ) );
	return 3;
}

// -----------------------------------------------------------------
static int luaNBTIterate( lua_State *L ) {
	// (iterator) = nbt:iterate()
	lua_pushcfunction( L, &luaNBTIterateNext );
	lua_pushvalue( L, 1 );
	lua_pushnil( L );
	return 3;
}

// -----------------------------------------------------------------
static int luaNBTCompWrite( lua_State *L ) {
	// nbt:write( filename, rootname )
	nbt::Compound *comp = *(nbt::Compound**)luaL_checkudata( L, 1, LUANBTCOMPOUND_META );
	const char *path = luaL_checkstring( L, 2 );
	size_t onamelen;
	const char *oname = luaL_checklstring( L, 3, &onamelen );
	std::string outerName( oname, onamelen );
	comp->write( path, outerName );
	return 0;
}

// -----------------------------------------------------------------
static int luaNBTCompDestroy( lua_State *L ) {
	// nbt:destroy()
	nbt::Compound **pComp = (nbt::Compound**)luaL_checkudata( L, 1, LUANBTCOMPOUND_META );
	delete *pComp;
	*pComp = NULL;
	return 0;
}

// -----------------------------------------------------------------
static int luaNBTReadable( lua_State *L ) {
	// readable = nbt:getReadable()
	nbt::Compound **pComp = (nbt::Compound**)luaL_checkudata( L, 1, LUANBTCOMPOUND_META );
	std::stringstream ss;
	(*pComp)->printReadable( ss );
	lua_pushlstring( L, ss.str().c_str(), ss.str().length() );
	return 1;
}

// -----------------------------------------------------------------
static int luaNBTListGet( lua_State *L ) {
	nbt::List *l = *(nbt::List**)luaL_checkudata( L, 1, LUANBTLIST_META );
	if( lua_isnumber( L, 2 ) ) {
		unsigned i = (unsigned)lua_tonumber( L, 2 );
		if( i < 1 || i > l->size() )
			return 0;
		nbt::List::iterator it = l->begin();
		std::advance( it, i - 1 );
		luaPushTagData( L, *it );
		return 1;
	} else if( lua_isstring( L, 2 ) ) {
		if( 0 == strcmp( "type", lua_tostring( L, 2 ) ) ) {
			lua_pushstring( L, tagTypeToString( l->getType() ) );
			return 1;
		}
	}
	return 0;
}

// -----------------------------------------------------------------
static int luaNBTListSet( lua_State *L ) {
	nbt::List *l = *(nbt::List**)luaL_checkudata( L, 1, LUANBTLIST_META );
	if( lua_isnumber( L, 2 ) ) {
		size_t lsz = l->size();
		size_t idx = (size_t)lua_tonumber( L, 2 );
		if( lua_isnil( L, 3 ) ) {
			// list[i] = nil;
			// Delete element i
			if( idx < 1 || idx > lsz ) {
				lua_pushstring( L, "Index out of range" );
				lua_error( L );
			}
			auto it = l->begin();
			std::advance( it, idx - 1 );
			l->erase( it );
		} else {
			// list[i] = foo;
			if( idx < 1 || idx > lsz + 1 ) {
				lua_pushstring( L, "Index out of range" );
				lua_error( L );
			}
			nbt::Tag tag;
			tag.type = l->getType();
			luaGetTagData( L, tag, 3 );
			idx--;
			if( idx == lsz ) {
				// list[#list+1] = foo;
				l->push_back( tag );
			} else {
				// list[i] = foo;
				nbt::List::iterator it = l->begin();
				std::advance( it, idx );
				it->destroyPayload();
				*it = tag;
			}
		}
	} else {
		lua_pushstring( L, "Non-numeric index provided to NBT list" );
		lua_error( L );
	}
	return 0;
}

// -----------------------------------------------------------------
static int luaNBTListLen( lua_State *L ) {
	nbt::List *l = *(nbt::List**)luaL_checkudata( L, 1, LUANBTLIST_META );
	lua_pushnumber( L, (lua_Number)l->size() );
	return 1;
}

// -----------------------------------------------------------------
static int luaLoadNBT( lua_State *L ) {
	// nbt, rootname = eihort.loadNBT( filename )
	const char *path = luaL_checkstring( L, 1 );
	std::string outerName;
	nbt::Compound *comp = nbt::readNBT( path, &outerName );
	if( comp ) {
		lua_pushlstring( L, outerName.data(), outerName.length() );

		nbt::Compound **pComp = (nbt::Compound**)lua_newuserdata( L, sizeof(nbt::Compound*) );
		*pComp = comp;
		luaL_newmetatable( L, LUANBTCOMPOUND_META );
		lua_setmetatable( L, -2 );
		return 2;
	}
	return 0;
}

// -----------------------------------------------------------------
static int luaNewNBTCompound( lua_State *L ) {
	// nbt = eihort.newNBTCompound()
	*(nbt::Compound**)lua_newuserdata( L, sizeof(nbt::Compound*) ) = new nbt::Compound;
	luaL_newmetatable( L, LUANBTCOMPOUND_META );
	lua_setmetatable( L, -2 );
	return 1;
}

// -----------------------------------------------------------------
static int luaNewNBTList( lua_State *L ) {
	// list = eihort.newNBTList( tagtype )
	nbt::TagType type = stringToTagType( luaL_checkstring( L, 1 ) );
	luaL_argcheck( L, type != nbt::TAG_Count, 1, "Not a valid NBT type" );
	luaL_argcheck( L, type != nbt::TAG_Byte_Array, 1, "Array of byte arrays is not allowed" );
	*(nbt::List**)lua_newuserdata( L, sizeof(nbt::List*) ) = new nbt::List( type );
	luaL_newmetatable( L, LUANBTLIST_META );
	lua_setmetatable( L, -2 );
	return 1;
}

// -----------------------------------------------------------------
static const luaL_Reg LuaNBTCompound_functions[] = {
	{ "get", &luaNBTCompGet },
	{ "set", &luaNBTCompSet },
	{ "newCompound", &luaNBTCompNewCompound },
	{ "newList", &luaNBTCompNewList },
	{ "iterate", &luaNBTIterate },
	{ "write", &luaNBTCompWrite },
	{ "destroy", &luaNBTCompDestroy },
	{ "getReadable", &luaNBTReadable },
	{ NULL, NULL }
};

static const luaL_Reg LuaNBTList_functions[] = {
	{ "__index", &luaNBTListGet },
	{ "__newindex", &luaNBTListSet },
	{ "__len", &luaNBTListLen },
	{ NULL, NULL }
};

void LuaNBT_setupLua( lua_State *L ) {
	luaL_newmetatable( L, LUANBTCOMPOUND_META );
	lua_pushvalue( L, -1 );
	lua_setfield( L, -2, "__index" );
	luaL_setfuncs( L, &LuaNBTCompound_functions[0], 0 );
	lua_pop( L, 1 );
	luaL_newmetatable( L, LUANBTLIST_META );
	luaL_setfuncs( L, &LuaNBTList_functions[0], 0 );
	lua_pop( L, 1 );

	lua_pushcfunction( L, &luaLoadNBT );
	lua_setfield( L, -2, "loadNBT" );
	lua_pushcfunction( L, &luaNewNBTCompound );
	lua_setfield( L, -2, "newNBTCompound" );
	lua_pushcfunction( L, &luaNewNBTList );
	lua_setfield( L, -2, "newNBTList" );
}


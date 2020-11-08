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


#ifndef LIGHTMODEL_H
#define LIGHTMODEL_H

#include "luaobject.h"

/*
The LightModel class stores global lighting parameters and generates
lighting textures as expected by the shaders in EihortShader.
The lighting model is currently:

Light = D + (S - D) * I(s) + (B - D) * I(b) * clamp(1 - I(s) * Sp, 0, 1)

Where:
D = Dark color (i.e. unlit)
S = Sky lighting color
Sp = Sky "power"
B = Block lighting color (e.g. torches)
s = Sky lighting at a given point (0-15)
b = Block lighting at a given point (0-15)
I(x) = (x/15)^2

Sp determines how much block lighting will affect lighting when fully
lit by the sky. A value of 1 means no block lighting when fully lit by sky.
*/

// Lua metatable name
#define LIGHTMODEL_META "LightModel"

namespace eihort {

class LightModel : public LuaObject {
public:
	LightModel();
	virtual ~LightModel();

	// Set the lighting when no light is affecting an surface
	void setDarkColor( float *col );
	// Set the lighting when the sky lighting is fully affecting a surface
	void setSkyBrightColor( float *col, float power );
	// Set the lighting when block lighting (e.g. torches) is fully affecting a surface
	void setBlockBrightColor( float *col );

	// Upload the current lighting textures to GL
	void uploadGL();
	// Undo uploadGL()
	static void unloadGL();

	// Lua functions
	// Documented in the "World Rendering" section of Eihort Lua API.txt

	static int lua_setDark( lua_State *L );
	static int lua_setSky( lua_State *L );
	static int lua_setBlock( lua_State *L );

	// Set up the Lua metatable for this class
	static void setupLua( lua_State *L );
	// Initialize the Lua side of this object
	void initLua( lua_State *L );

private:
	// Recreate the lighting texture if dirty
	void regenTex();

	// Lighting colors
	float dark[4], skyBright[4], blockBright[4];
	// Difference between bright colours and dark
	float skyDelta[4], blockDelta[4];
	// Power of the sky; see setSkyBrightColor
	float skyPower;
	// Lighting interpolation curve
	float interp[16];

	// GL texture
	unsigned tex;
	// Set when the texture needs to be regenerated
	bool texDirty;
};

} // namespace eihort

#endif

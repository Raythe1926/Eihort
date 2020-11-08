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

#ifndef SKY_H
#define SKY_H

#include "jmath.h"
#include "glshader.h"
#include "luaobject.h"

namespace eihort {

class EihortShader;
class WorldQTree;

class Sky : public LuaObject {
	// Manages the light model and rendering of the sky

public:
	Sky();
	~Sky();

	// Set the current time
	// Time goes from -1 to 1, where 0 is noon and -1 and 1 are midnight
	// Returns the lighting level
	float setTime( float time );
	// Set the color of the horizon and of the top of the sky at noon
	void setColors( unsigned horiz, unsigned top );
	// Set the textures of the sun and the moon
	void setSunMoonTex( unsigned sun, unsigned moon );
	// Get the fog color that will best match the current horizon color
	unsigned getOptimalFogColor() { return fogColor; }
	// Draw the sky
	void renderSky( const jPlane *frustum, const jVec3 *nOffset );
	// Draw the sun and the moon
	void renderSunMoon( WorldQTree *qtree );

	// Lua functions
	// Documented in the Sky section of Eihort Lua API.txt

	static int lua_create( lua_State *L );
	static int lua_setTime( lua_State *L );
	static int lua_setColors( lua_State *L );
	static int lua_setSunMoon( lua_State *L );
	static int lua_getOptimalFogColor( lua_State *L );
	static int lua_render( lua_State *L );
	static int lua_destroy( lua_State *L );
	static void setupLua( lua_State *L );

private:
	// Vertex shader of the sky
	GLShaderObject skyVtxShader;
	// Fragment shader of the sky
	GLShaderObject skyFragShader;
	// The sky's compiled shader
	GLShader skyShader;

	// Angle at which the sun is currently (i.e. time)
	float sunAngle;
	// Size of the sun
	float sunSize;
	// Color at the top of the sky sphere
	unsigned topColor;
	// Horizon color
	unsigned horizColor;
	// Color of the fog
	unsigned fogColor;
	// ID of the offsetV vector of the shader
	unsigned offsetUniform;
	// The sky texture which is manipulated by this class
	unsigned skyTexId;
	// Textures of the sun and the moon
	unsigned sunTex, moonTex;
};

} // namespace eihort

#endif // SKY_H

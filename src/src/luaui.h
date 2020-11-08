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


#ifndef LUAUI_H
#define LUAUI_H

#include "uidrawcontext.h"

/*

The primitives exposed to Lua to draw the UI are simply a rectangle-drawing
object, which can also draw text inside the rectangle.
UI functionality is coded in ui.lua.

Exposed functions are documented in the UI Context and UI Rectangles sections
of Eihort Lua API.txt.
*/

struct lua_State;

// Lua metatable names
#define LUAUIRECT_META "UIRect"
#define LUAUIDRAWCONTEXT_META "UIDrawContext"

class LuaUIRect {
public:
	LuaUIRect();
	~LuaUIRect();

	// Draws the rectangle
	void draw( UIDrawContext *ctx );
	// Draws text inside the rectangle
	void drawTextIn( UIDrawContext *ctx, const char *text, float vScale, float hScale, UIDrawContext::TextAlignment align, float vBorder, float hBorder );

	// Set the size of the rectange
	void setRect( const UIRect *r );
	// Get the size of the rectangle
	const UIRect *getRect() const { return &rect; }

	// Set the background colours of the rectangle
	void setBackground( bool on, const unsigned *bkgCols );
	// Set the border colours of the rectangle
	void setBorder( bool on, const unsigned *borderCols );

	// Lua functions

	static int lua_draw( lua_State *L );
	static int lua_drawTextIn( lua_State *L );
	static int lua_fitToText( lua_State *L );
	static int lua_contains( lua_State *L );
	static int lua_getRect( lua_State *L );
	static int lua_setRect( lua_State *L );
	static int lua_setBorder( lua_State *L );
	static int lua_setBackground( lua_State *L );
	static int lua_destroy( lua_State *L );
	static int lua_create( lua_State *L );
	static void setupLua( lua_State *L );

protected:
	// Size of the rectangle
	UIRect rect;

	// Colors of the vertices when drawing the background
	unsigned bkgColors[4];
	// Colors of the vertices when drawing the border
	unsigned borderColors[4];
	// Should the background be drawn?
	bool drawBkg;
	// Should the border be drawn?
	bool drawBorder;
};


#endif

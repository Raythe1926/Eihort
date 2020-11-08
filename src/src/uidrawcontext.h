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

#ifndef UIDRAWCONTEXT_H
#define UIDRAWCONTEXT_H

#include "stdint.h"
#include <string>

struct lua_State;

struct UIRect {
	// A rectangle

	// Position and dimensions
	float x, y, w, h;

	inline UIRect()
		: x(0.0f), y(0.0f), w(0.0f), h(0.0f) { }
	inline UIRect( float x, float y, float w, float h )
		: x(x), y(y), w(w), h(h) { }
	inline UIRect( const UIRect &other )
		: x(other.x), y(other.y), w(other.w), h(other.h) { }

	// Is this point inside the rectangle?
	inline bool isInside( float px, float py ) const {
		return px >= x && px <= x+w && py >= y && py <= y+h;
	}

	// Override the rectangle parameters
	inline void set( float rx, float ry, float rw, float rh ) {
		x = rx; y = ry;
		w = rw; h = rh;
	}
};

// Color code
#define CC "\x10"

class UIDrawContext {
	// Draw context providing many UI drawing-related functions

public:
	// Create a new draw context
	// If initGL is false, no GL state will be modified
	// (e.g. if drawing text in the world)
	explicit UIDrawContext( bool initGL = true );
	~UIDrawContext();

	// Lua Initialization
	static void setupLua( lua_State *L );

	// Push the current transform
	void pushTransform();
	// Push the transform to the given rect
	void transformToRect( UIRect *r );
	// Push a rotation transform
	void rotate( float rad );
	// Revert to the transform at the last pushTransform
	void popTransform();

	// Move the draw cursor
	inline void moveTo( float x, float y ) { this->x = x; this->y = y; }
	
	// Set the current color
	void color( unsigned color );
	// Set the current color to a palette of 2 colours
	void color2( unsigned color1, unsigned color2 );
	// Set the current color to a palette of 4 colours
	void color4( const unsigned *colors );
	// Set the current color to white
	inline void white() { color( 0xffffffffu ); }

	// Draw a line
	void lineTo( float x, float y );
	// Draw a rectangle
	void lineRectTo( float x, float y );
	// Draw a filled rectangle
	void filledRectTo( float x, float y );
	// Draw a series of lines
	void lineStrip( unsigned n, const float *xy );

	// Text alignment constants
	enum TextAlignment {
		LEFT = 1,
		RIGHT = 2,
		CENTER = 3,
		TOP = 0,
		BOTTOM = 0x10,
		V_CENTER = 0x20
	};
	// Set "upright" (axis-aligned) font vectors
	void setFontVectorsAA( float dx, float dy );
	// Set freeform font vectors
	// X is the direction and width of the text
	// Y is the direction and height of the text
	void setFontVectors( float *X, float *Y );
	// Set the width of the area in which to confine text
	inline void setWidth( float w ) { textW = w; }
	// Set the height of the area in which to confine text
	inline void setHeight( float h ) { textH = h; }
	// Set color brightness
	inline void setFormatColorBrightness( float b ) { fmtColorBrightness = b; }

	struct TextLayout {
		// Text layout results

		// Number of lines
		unsigned lines;
		// Height of the text
		float totalHeight;
		// Width of this text
		float minWidth;
	};
	// Layout some text
	// NOTE: May trigger calls to the Lua texture loader
	void layoutText( const char *text, TextLayout *layout = NULL );
	// Draw the previously-layed out text with the given alignment
	void drawText( TextAlignment align = LEFT );

	// Cursor text
	void setAltText( const char *text );

private:
	// Lua functions - documented in the Eihort Core section
	// of Eihort Lua API.txt

	static int luaSetTextureLoader( lua_State *L );

	// The Lua texture loading function
	static int luaTextureLoader;
	// The Lua state in which to find the texture loading function
	static lua_State *luaL;

	struct FontPage {
		// A Unicode font page

		// Is the page loaded?
		bool loaded;
		// The GL texture for the font page
		unsigned tex;
		// Sizes of the glyphs in the page
		// Same format as Minecraft's glyph_sizes.bin
		unsigned char glyph_sizes[256];
	};
	// All Unicode font pages
	static FontPage fontPages[256];

	// Actual layout function
	void textify( const char *text );
	// Insert a linebreak in the current text layout
	void newLine( const char *txtStart, float lastW );
	// Decodes a UTF8 character
	static uint32_t decode_utf8( const char *&ch, const char *top = NULL );
	// Loads a font page
	static void loadFontPage( unsigned page );
	
	// Position of the cursor
	float x,y;
	// Current color palette
	unsigned colors[4];

	// Width and heigt of the text area
	float textW, textH;
	// Font size and direction
	float textDownV[2], textRightV[2], textVLen, textHLen;
	// Lines of text
	const char *textLines[64];
	// Widths of the lines of text
	float textLineWidths[64];
	// Width of the widest line
	float maxTextLineW;
	// Number of lines of text
	unsigned nTextLines;
	// Brigness of the color of formatted text 0= black, 1= full bright
	float fmtColorBrightness;
};

#endif

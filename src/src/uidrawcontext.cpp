/* Copyright (c) 2012, Jason Lloyd-Price and Antti Hakkinen
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
#include <GL/glew.h>
#include <cassert>
#include <cmath>
#include <cstdio>
#include <lua.hpp>
#include <SDL.h>

#include "uidrawcontext.h"
#include "luaimage.h"
#include "platform.h"

extern unsigned g_width, g_height;

int UIDrawContext::luaTextureLoader = 0;
lua_State *UIDrawContext::luaL;
UIDrawContext::FontPage UIDrawContext::fontPages[256];

const float SPACE_SIZE_RATIO = 0.3f;
const float TAB_SIZE_RATIO = 4*SPACE_SIZE_RATIO;

// -----------------------------------------------------------------
UIDrawContext::UIDrawContext( bool initGL )
: x(0.0f)
, y(0.0f)
, fmtColorBrightness(1.f)
{
	white();

	if( initGL ) {
		glDisable( GL_DEPTH_TEST );
		glEnable (GL_BLEND);
		glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
		glEnable( GL_ALPHA_TEST );
		glAlphaFunc( GL_GREATER, 0.01f );
		glDisable(GL_CULL_FACE);
		float white[] = { 1.0f, 1.0f, 1.0f, 1.0f };
		glMaterialfv( GL_FRONT, GL_AMBIENT_AND_DIFFUSE, &white[0] );
		glMatrixMode( GL_PROJECTION );
		glLoadIdentity();
		glMatrixMode( GL_MODELVIEW );
		glLoadIdentity();
		glScalef( 2.0f, -2.0f, 1.0f );
		glTranslatef( -0.5f, -0.5f, 0.0f );
	}
}

// -----------------------------------------------------------------
UIDrawContext::~UIDrawContext() {
}

// -----------------------------------------------------------------
void UIDrawContext::setupLua( lua_State *L ) {
	lua_pushcfunction( L, &luaSetTextureLoader );
	lua_setfield( L, -2, "setFontLoader" );

	for( auto it = std::begin(fontPages); it != std::end(fontPages); ++it ) {
		it->loaded = false;
	}
}

// -----------------------------------------------------------------
void UIDrawContext::pushTransform() {
	glPushMatrix();
}

// -----------------------------------------------------------------
void UIDrawContext::transformToRect( UIRect *r ) {
	glTranslatef( r->x, r->y, 0.0f );
	glScalef( r->w, r->h, 1.0f );
}

// -----------------------------------------------------------------
void UIDrawContext::rotate( float ) {
	assert( false );
}

// -----------------------------------------------------------------
void UIDrawContext::popTransform() {
	glPopMatrix();
}

// -----------------------------------------------------------------
void UIDrawContext::color( unsigned color ) {
	// All the same color
	colors[0] = color;
	colors[1] = color;
	colors[2] = color;
	colors[3] = color;
}

// -----------------------------------------------------------------
void UIDrawContext::color2( unsigned color1, unsigned color2 ) {
	// Alternate colors
	colors[0] = color1;
	colors[1] = color2;
	colors[2] = color1;
	colors[3] = color2;
}

// -----------------------------------------------------------------
void UIDrawContext::color4( const unsigned *colors ) {
	// 4 unique colors
	this->colors[0] = colors[0];
	this->colors[1] = colors[1];
	this->colors[2] = colors[2];
	this->colors[3] = colors[3];
}

// -----------------------------------------------------------------
inline void setGLColor( unsigned c ) {
	glColor4ub( (c>>16)&0xff, (c>>8)&0xff, c&0xff, (c>>24)&0xff );
}

// -----------------------------------------------------------------
inline void setGLColor( unsigned c, float brightness ) {
	unsigned r = (( (c>>16)&0xffu )) * brightness + .5f;
	unsigned g = (( (c>>8)&0xffu )) * brightness + .5f;
	unsigned b = (( c&0xffu )) * brightness + .5f;
	unsigned a = (( (c>>24)&0xffu )) * brightness + 0xffu * (1.f-brightness) + .5;
	glColor4ub( r, g, b, a );
}

// -----------------------------------------------------------------
inline void makeGLVertex( float x, float y, unsigned c ) {
	setGLColor( c );
	glVertex3f( x, y, 0.0f );
}

// -----------------------------------------------------------------
inline void makeGLVertex( float x, float y, float s, float t ) {
	glTexCoord2f( s, t );
	glVertex3f( x, y, 0.0f );
}

// -----------------------------------------------------------------
void UIDrawContext::lineTo( float dx, float dy ) {
	glBegin( GL_LINES );
	makeGLVertex( x, y, colors[0] );
	makeGLVertex( dx, dy, colors[1] );
	glEnd();
	x = dx; y = dy;
}

// -----------------------------------------------------------------
void UIDrawContext::lineRectTo( float dx, float dy ) {
	glBegin( GL_LINE_LOOP );
	makeGLVertex( x, y, colors[0] );
	makeGLVertex( dx, y, colors[1] );
	makeGLVertex( dx, dy, colors[2] );
	makeGLVertex( x, dy, colors[3] );
	glEnd();
	x = dx; y = dy;
}

// -----------------------------------------------------------------
void UIDrawContext::filledRectTo( float dx, float dy ) {
	glBegin( GL_QUADS );
	makeGLVertex( x, y, colors[0] );
	makeGLVertex( dx, y, colors[1] );
	makeGLVertex( dx, dy, colors[2] );
	makeGLVertex( x, dy, colors[3] );
	glEnd();
	x = dx; y = dy;
}

// -----------------------------------------------------------------
void UIDrawContext::lineStrip( unsigned n, const float *xy ) {
	setGLColor( colors[0] );
	glEnableClientState( GL_VERTEX_ARRAY );
	glVertexPointer( 2, GL_FLOAT, 0, xy );
	glDrawArrays( GL_LINE_STRIP, 0, (int)n );
	glDisableClientState( GL_VERTEX_ARRAY );
}

// -----------------------------------------------------------------
void UIDrawContext::setFontVectorsAA( float dx, float dy ) {
	textRightV[0] = dx;
	textRightV[1] = 0.0f;
	textHLen = dx;
	textDownV[0] = 0.0f;
	textDownV[1] = dy;
	textVLen = dy;
}

// -----------------------------------------------------------------
void UIDrawContext::setFontVectors( float *X, float *Y ) {
	textRightV[0] = X[0];
	textRightV[1] = X[1];
	textHLen = sqrtf( X[0]*X[0] + X[1]*X[1] );
	textDownV[0] = Y[0];
	textDownV[1] = Y[1];
	textVLen = sqrtf( Y[0]*Y[0] + Y[1]*Y[1] );
}

// -----------------------------------------------------------------
void UIDrawContext::layoutText( const char *text, UIDrawContext::TextLayout *layout ) {
	textify( text );
	if( layout ) {
		layout->lines = nTextLines;
		layout->totalHeight = textVLen * nTextLines;
		layout->minWidth = maxTextLineW;
	}
}

// Format flags
static const unsigned F_OBFUSCATE = 0x1, // Obfuscated
	F_BOLD = 0x2,    // Bold
	F_OSTRIKE = 0x4, // Striketrough
	F_USTRIKE = 0x8, // Underline
	F_ITALIC = 0x10;  // Italic

// -----------------------------------------------------------------
void UIDrawContext::drawText( UIDrawContext::TextAlignment align ) {
	glEnable( GL_TEXTURE_2D );
	glEnable (GL_BLEND);

	unsigned curPage = unsigned(-1);
	int curFlags = 0;
	setGLColor( colors[0] );

	float temp;
	float lettSepWidth = textHLen / 16.0f;

	// Adjust the starting position based on the vertical alignment
	switch( align & 0xf0 ) {
		case TOP: break;
		case V_CENTER:
			temp = (textH / textVLen - nTextLines) / 2.0f;
			x += textDownV[0] * temp;
			y += textDownV[1] * temp;
			break;
		case BOTTOM:
			temp = textH / textVLen - nTextLines;
			x += textDownV[0] * temp;
			y += textDownV[1] * temp;
			break;
	}

	for( unsigned i = 0; i < nTextLines; i++ ) {
		float xc = x, yc = y;

		// Adjust the line's starting position based on the horizontal alignment
		switch( align & 0xf ) {
			case LEFT: break;
			case CENTER:
				temp = (textW - textLineWidths[i]) / (2.0f * textHLen);
				xc += textRightV[0] * temp;
				yc += textRightV[1] * temp;
				break;
			case RIGHT:
				temp = (textW - textLineWidths[i]) / textHLen;
				xc += textRightV[0] * temp;
				yc += textRightV[1] * temp;
				break;
		}

		// Draw the characters one by one
		const char *t = textLines[i], *endT = textLines[i+1];
		bool lastCharSolid = false;
		while( t != endT ) {
			uint32_t wch = decode_utf8( t, endT );
			t++;
			if( wch <= ' ' ) {
				// Control character
				switch( wch ) {
					case '\0': assert(false); // FALLTHROUGH
					case '\n':
						// Reset color
						setGLColor( colors[0] );
						curFlags = 0;
						break;
					case ' ':
					case '\t':
						// Tab or space
						temp = wch==' ' ? SPACE_SIZE_RATIO : TAB_SIZE_RATIO;
						xc += textRightV[0] * temp;
						yc += textRightV[1] * temp;
						break;
					case '\x10':
						if( t[1] != '\0' && t[2] != '\0' && t[3] != '\0' ) {
							// Change the color
							glColor3f( (t[1] - '0') / 9.0f, (t[2] - '0') / 9.0f, (t[3] - '0') / 9.0f );
							t += 3;
							break;
						}
						// Fall-through if one of the next chars is \0 to prevent
						// buffer overrun
					default:
						// Unknown control code - replace with #
						wch = '#';
						goto draw_visible_char;
						break;
				}
				lastCharSolid = false;
			} else if( wch == 0xA7u ) {
				// Formatting character, get next
				if( *t == '\0' )
					continue;
				wch = decode_utf8( t );
				++t;
				switch( wch )
				{
					// http://minecraft.gamepedia.com/Formatting_codes
					case '0': setGLColor( 0xFF000000lu, fmtColorBrightness ); break;
					case '1': setGLColor( 0xFF0000AAlu, fmtColorBrightness ); break;
					case '2': setGLColor( 0xFF00AA00lu, fmtColorBrightness ); break;
					case '3': setGLColor( 0xFF00AAAAlu, fmtColorBrightness ); break;
					case '4': setGLColor( 0xFFAA0000lu, fmtColorBrightness ); break;
					case '5': setGLColor( 0xFFAA00AAlu, fmtColorBrightness ); break;
					case '6': setGLColor( 0xFFFFAA00lu, fmtColorBrightness ); break;
					case '7': setGLColor( 0xFFAAAAAAlu, fmtColorBrightness ); break;
					case '8': setGLColor( 0xFF555555lu, fmtColorBrightness ); break;
					case '9': setGLColor( 0xFF5555FFlu, fmtColorBrightness ); break;
					case 'a': setGLColor( 0xFF55FF55lu, fmtColorBrightness ); break;
					case 'b': setGLColor( 0xFF55FFFFlu, fmtColorBrightness ); break;
					case 'c': setGLColor( 0xFFFF5555lu, fmtColorBrightness ); break;
					case 'd': setGLColor( 0xFFFF55FFlu, fmtColorBrightness ); break;
					case 'e': setGLColor( 0xFFFFFF55lu, fmtColorBrightness ); break;
					case 'f': setGLColor( 0xFFFFFFFFlu, fmtColorBrightness ); break;
					case 'k': case 'l': case 'm': case 'n': case 'o':
						curFlags |= 1u << int(wch - 'k');
						break;
					case 'r':
						// Reset color
						setGLColor( colors[0] );
						curFlags = 0;
						break;
					default:
						break; // unsupported, skip
				}

			} else {

draw_visible_char:
				// Obfuscated
				if( ( curFlags & F_OBFUSCATE ) != 0 ) {
					uint32_t s = SDL_GetTicks() + wch;
					wch = 'A' + (s >> 1) % ('Z' - 'A' + 1) + (s & 1u) * ('a' - 'A');
				}

				// Visible character
				unsigned pageid = ((uint32_t)wch >> 8) & 0xffu;
				if( !fontPages[pageid].loaded )
					loadFontPage( pageid );
				const FontPage &page = fontPages[pageid];

				if( page.tex ) {
					if( curPage != pageid ) {
						// Swap pages
						if( curPage != unsigned(-1) )
							glEnd();

						glBindTexture( GL_TEXTURE_2D, page.tex );
						glBegin( GL_QUADS );

						curPage = pageid;
					}

					// Get the glyph size
					unsigned char gs = page.glyph_sizes[wch&0xffu];
					float v1 = ((wch & 0xf0u)+1) / 256.0f;
					float v2 = v1 + 14.5f / 256.0f;
					float u = (((wch & 0xfu) << 4) + ((gs&0xf0u) >> 4)) / 256.0f;
					float w = (gs&0xfu) - ((gs&0xf0u)>>4) + 1.f;

					// Extra spacing between visible characters
					if( lastCharSolid )
						xc += lettSepWidth;

					// Compute vertex positions
					float d_xc = textRightV[0] * (w/15.f);
					float d_yc = textRightV[1] * (w/15.f);
					float d_u = w / 256.0f;
					float vert[4][2] = {
						{ xc+textDownV[0], yc+textDownV[1] },
						{ xc             , yc              },
						{ xc+d_xc             , yc+d_yc              },
						{ xc+d_xc+textDownV[0], yc+d_yc+textDownV[1] },
					};

					// Italic
					if( ( curFlags & F_ITALIC ) != 0 )
					{
						float dx = textRightV[0] * (1.5f / 15.f),
							dy = textRightV[0] * (1.5f / 15.f);
						// Slant the quad
						vert[0][0] -= dx; vert[0][1] -= dy;
						vert[1][0] += dx; vert[1][1] += dy;
						vert[2][0] += dx; vert[2][1] += dy;
						vert[3][0] -= dx; vert[3][1] -= dy;
					}

					// Draw the actual vertices
					makeGLVertex( vert[0][0], vert[0][1], u, v2 );
					makeGLVertex( vert[1][0], vert[1][1], u, v1 );
					makeGLVertex( vert[2][0], vert[2][1], u + d_u, v1 );
					makeGLVertex( vert[3][0], vert[3][1], u + d_u, v2 );

					// Bold
					if( ( curFlags & F_BOLD ) != 0 )
					{
						// Draw another offset quad
						float dx = textRightV[0] / 15.f,
							dy = textRightV[1] / 15.f;
						makeGLVertex( vert[0][0] + dx, vert[0][1] + dy, u, v2 );
						makeGLVertex( vert[1][0] + dx, vert[1][1] + dy, u, v1 );
						makeGLVertex( vert[2][0] + dx, vert[2][1] + dy, u + d_u, v1 );
						makeGLVertex( vert[3][0] + dx, vert[3][1] + dy, u + d_u, v2 );

						// Bump width
						d_xc += dx;
						d_yc += dy;
					}

					// Overstrike
					if( ( curFlags & F_OSTRIKE ) != 0 )
					{
						// Draw an overstrike
						float ahx = textDownV[0] * (7.f / 15.f), // almost half height
							ahy = textDownV[1] * (7.f / 15.f);
						float sx = textRightV[0] * (.5f / 15.f), // shift -.5px left
							sy = textRightV[1] * (.5f / 15.f);
						makeGLVertex( vert[0][0] - ahx - sx, vert[0][1] - ahy - sy, 0.f, 0.f );
						makeGLVertex( vert[1][0] + ahx - sx, vert[1][1] + ahy - sy, 0.f, 0.f );
						makeGLVertex( vert[2][0] + ahx + sx, vert[2][1] + ahy + sy, 0.f, 0.f );
						makeGLVertex( vert[3][0] - ahx + sx, vert[3][1] - ahy + sy, 0.f, 0.f );
					}

					// Understrike
					if( ( curFlags & F_USTRIKE ) != 0 )
					{
						// Draw an overstrike
						float ox1 = textDownV[0] * (0.f / 15.f), // down 2 px
							ox2 = textDownV[0] * (14.f / 15.f), // down 1 px
							oy1 = textDownV[1] * (0.f / 15.f),
							oy2 = textDownV[1] * (14.f / 15.f);
						float sx = textRightV[0] * (.5f / 15.f), // shift -.5px left
							sy = textRightV[1] * (.5f / 15.f);
						makeGLVertex( vert[0][0] + ox1 - sx, vert[0][1] + oy1 - sy, 0.f, 0.f );
						makeGLVertex( vert[1][0] + ox2 - sx, vert[1][1] + oy2 - sy, 0.f, 0.f );
						makeGLVertex( vert[2][0] + ox2 + sx, vert[2][1] + oy2 + sy, 0.f, 0.f );
						makeGLVertex( vert[3][0] + ox1 + sx, vert[3][1] + oy1 + sy, 0.f, 0.f );
					}

					// Bump counters
					xc += d_xc;
					yc += d_yc;
					u += d_u;

					lastCharSolid = true;
				}
			}
		}

		// Down one line
		x += textDownV[0];
		y += textDownV[1];
	}

	if( curPage != unsigned(-1) )
		glEnd();

	glDisable( GL_TEXTURE_2D );
	glDisable (GL_BLEND);
}

// -----------------------------------------------------------------
void UIDrawContext::textify( const char *text ) {
	nTextLines = 0;
	textLines[0] = text;
	maxTextLineW = 0.0f;
	const char *t = text;

	float w = 0.0f;
	float wordWidth = 0.0f;
	float spaceWidth = 0.0f;
	float lettSepWidth = textHLen / 16.0f;
	const char *wordStart = t;
	bool lastCharSolid = false;
	int curFlags = 0;

	while( true ) {
		uint32_t wch = decode_utf8( t );
		if( wch <= ' ' ) {
			// Control character
			if( !(wch & 0x10) && wordWidth > 0.0f ) {
				// End the last word
				if( w > 0.0f && w + spaceWidth + wordWidth > textW ) {
					// Need to insert a linebreak
					newLine( wordStart, w );
					w = wordWidth;
				} else {
					w += wordWidth + spaceWidth;
				}
				wordWidth = 0.0f;
				spaceWidth = 0.0f;
				curFlags = 0;
			}
			switch( wch ) {
				case '\0': // End of string
					newLine( t, w + spaceWidth );
					return;
				case '\n': // Newline
					newLine( ++t, w + spaceWidth );
					spaceWidth = 0.0f;
					curFlags = 0;
					w = 0.0f;
					break;
				case ' ':
				case '\t':
					// Tab or space
					spaceWidth += textHLen * (*t==' ' ? SPACE_SIZE_RATIO : TAB_SIZE_RATIO);
					wordStart = ++t;
					break;
				default:
					// Unknown control code - replace with #
					wch = '#';
					goto solid_char;
					break;
			}
			lastCharSolid = false;
		} else if( wch == 0xA7u ) {
			// Formatting character, skip next
			if( *++t == '\0' )
				continue;
			wch = decode_utf8( t );
			++t;
			switch( wch )
			{
				case 'k': case 'l': case 'm': case 'n': case 'o':
					curFlags |= 1u << int(wch - 'k');
					break;
				default:
					break; // unsupported, or does not affect bounds
			}

		} else {
solid_char:
			// Solid character
			unsigned pageid = ((uint32_t)wch >> 8) & 0xffu;
			if( !fontPages[pageid].loaded )
				loadFontPage( pageid );
			const FontPage &page = fontPages[pageid];

			unsigned char gs = page.glyph_sizes[wch&0xff];
			float gw = ((gs&0xfu) - ((gs&0xf0u) >> 4) + 1) / 15.0f;
			if( lastCharSolid )
				wordWidth += lettSepWidth;
			wordWidth += gw * textHLen;
			if( ( curFlags & F_BOLD ) != 0 )
				wordWidth += textHLen / 15.f; // Bump 1px more for bold
			lastCharSolid = true;
			t++;
		}
	}
}

// -----------------------------------------------------------------
void UIDrawContext::newLine( const char *txtStart, float lastW ) {
	if( lastW > maxTextLineW )
		maxTextLineW = lastW;
	textLineWidths[nTextLines] = lastW;
	nTextLines++;
	textLines[nTextLines] = txtStart;
}

// -----------------------------------------------------------------
uint32_t UIDrawContext::decode_utf8( const char *&ch, const char *top ) {
	if( top != NULL && !( ch < top ) )
		return uint32_t( -1 );

	uint32_t ch1 = (uint32_t)*ch;

	if( (ch1 & 0x80u) == 0x00u ) {
		// Single-byte
		return ch1;
	} else if( (ch1 & 0xc0u) == 0x80u ) {
		// Continuation byte
		ch++;
		return decode_utf8( ch );
	} else {
		// Multi-byte code
		int conts = 1;
		for( uint32_t mask = 0x20u; ( ch1 & mask ) != 0; mask >>= 1 )
			++conts;
		if( top != NULL && !( ch+conts < top ) )
			return uint32_t( -1 );
		uint32_t r = ch1 & ( 0x3fu >> conts );
		for( int i = 0; i < conts; ++i ) {
			if( ( ch[i + 1] & 0xc0u ) != 0x80 )
				return uint32_t( -1 );
			r = (r << 6) | (ch[i + 1] & 0x3fu);
		}
		return r;
	}
}

// -----------------------------------------------------------------
void UIDrawContext::loadFontPage( unsigned page ) {
	fontPages[page].tex = 0;
	memset( fontPages[page].glyph_sizes, 0x0f, 256 );

	// Push the textture loading function in Lua
	lua_pushinteger( luaL, luaTextureLoader );
	lua_gettable( luaL, LUA_REGISTRYINDEX );
	lua_pushinteger( luaL, page );

	// Call the function
	if( 0 == lua_pcall( luaL, 1, 2, 0 ) ) {
		if( lua_isnumber( luaL, -2 ) && lua_isstring( luaL, -1 ) ) {
			size_t sz;
			const char *glyph_sizes = lua_tolstring( luaL, -1, &sz );
			if( sz == 256 ) {
				// Yay.. we have a loaded font page
				fontPages[page].tex = (unsigned)lua_tonumber( luaL, -2 );
				memcpy( fontPages[page].glyph_sizes, glyph_sizes, 256 );
			}
		}
		lua_pop( luaL, 2 );
	} else {
		lua_pop( luaL, 1 );
	}
	fontPages[page].loaded = true;
}

// -----------------------------------------------------------------
int UIDrawContext::luaSetTextureLoader( lua_State *L ) {
	// eihort.setFontLoader( loader )
	luaL_argcheck( L, lua_isfunction( L, 1 ), 1, "Expected function" );
	lua_pushvalue( L, 1 );
	luaTextureLoader = luaL_ref( L, LUA_REGISTRYINDEX );
	luaL = L;
	return 0;
}

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


#include <GL/glew.h>
#include <SDL.h>
#include <SDL_keyboard.h>
#include <SDL_mouse.h>
#include <SDL_image.h>
#include <stdlib.h>
#include <sstream>
#include <cstdlib>
#include <climits>
#include <clocale>
#include <cstring>
#include <ctime>

#include <lua.hpp>
#include <zlib.h>

#include "nbt.h"
#include "jmath.h"
#include "mcregionmap.h"
#include "worldmesh.h"
#include "worker.h"
#include "worldqtree.h"
#include "lightmodel.h"
#include "eihortshader.h"
#include "sky.h"
#include "mcbiome.h"
#include "platform.h"
#include "luaui.h"
#include "luafindfile.h"
#include "luanbt.h"
#include "luaimage.h"
#include "unzip.h"

#if defined(__APPLE__) && defined(__MACH__)
# include <CoreFoundation/CoreFoundation.h>
# include <OpenGL/OpenGL.h>
#endif

#if defined(__linux)
#	include <GL/glx.h>
#	include <X11/Xlib.h>
#endif

#if defined(_POSIX_VERSION)
#	include <sys/stat.h> // for mkdir()
#	include <errno.h>
#	include <unistd.h>
#endif

#ifdef _WIN32
// This makes nVidia Optimus detect Eihort as a program to run with the
// big beefy GPU rather than the crappy integrated thing.
extern "C" {
_declspec(dllexport) DWORD NvOptimusEnablement = 0x00000001;
}
#endif

// ---------------------------------------------------------------------------
//                           Global variables

// Version string, found in eihort.Version
#define VERSION "0.4.1"

// The Lua VM
lua_State *g_L;
// Window size
unsigned g_width, g_height;
// Eihort's window
SDL_Window *g_window;
// Our GL context
SDL_GLContext g_glContext;

// Does the screen need to be refreshed?
bool g_needRefresh = true;

// Workers used for offloading work to other threads
eihort::Worker *g_workers[MAX_WORKERS];
// Number of workers available
unsigned g_nWorkers;
// Eihort's shaders
eihort::EihortShader *g_shader;

// The path to the Eihort executable
char g_programRoot[MAX_PATH];


// --------------------------- Utility Functions ----------------------------
static const char *SDLKeyToString( SDL_Keycode key ) {
	// Convert a SDL_Keycode to a string
	switch( key ) {
		case SDLK_BACKSPACE: return "backspace";
		case SDLK_TAB: return "tab";
		case SDLK_CLEAR: return "clear";
		case SDLK_RETURN: return "return";
		case SDLK_PAUSE: return "pause";
		case SDLK_ESCAPE: return "escape";
		case SDLK_SPACE: return "space";
		case SDLK_EXCLAIM: return "!";
		case SDLK_QUOTEDBL: return "\"";
		case SDLK_HASH: return "#";
		case SDLK_DOLLAR: return "$";
		case SDLK_AMPERSAND: return "&";
		case SDLK_QUOTE: return "\'";
		case SDLK_LEFTPAREN: return "(";
		case SDLK_RIGHTPAREN: return ")";
		case SDLK_ASTERISK: return "*";
		case SDLK_PLUS: return "+";
		case SDLK_COMMA: return ",";
		case SDLK_MINUS: return "-";
		case SDLK_PERIOD: return ".";
		case SDLK_SLASH: return "/";
		case SDLK_0: return "0";
		case SDLK_1: return "1";
		case SDLK_2: return "2";
		case SDLK_3: return "3";
		case SDLK_4: return "4";
		case SDLK_5: return "5";
		case SDLK_6: return "6";
		case SDLK_7: return "7";
		case SDLK_8: return "8";
		case SDLK_9: return "9";
		case SDLK_COLON: return ":";
		case SDLK_SEMICOLON: return ";";
		case SDLK_LESS: return "<";
		case SDLK_EQUALS: return "=";
		case SDLK_GREATER: return ">";
		case SDLK_QUESTION: return "?";
		case SDLK_AT: return "@";
		case SDLK_LEFTBRACKET: return "[";
		case SDLK_BACKSLASH: return "\\";
		case SDLK_RIGHTBRACKET: return "]";
		case SDLK_CARET: return "^";
		case SDLK_UNDERSCORE: return "_";
		case SDLK_BACKQUOTE: return "`";
		case SDLK_a: return "a";
		case SDLK_b: return "b";
		case SDLK_c: return "c";
		case SDLK_d: return "d";
		case SDLK_e: return "e";
		case SDLK_f: return "f";
		case SDLK_g: return "g";
		case SDLK_h: return "h";
		case SDLK_i: return "i";
		case SDLK_j: return "j";
		case SDLK_k: return "k";
		case SDLK_l: return "l";
		case SDLK_m: return "m";
		case SDLK_n: return "n";
		case SDLK_o: return "o";
		case SDLK_p: return "p";
		case SDLK_q: return "q";
		case SDLK_r: return "r";
		case SDLK_s: return "s";
		case SDLK_t: return "t";
		case SDLK_u: return "u";
		case SDLK_v: return "v";
		case SDLK_w: return "w";
		case SDLK_x: return "x";
		case SDLK_y: return "y";
		case SDLK_z: return "z";
		case SDLK_DELETE: return "delete";
		case SDLK_KP_0: return "kp_0";
		case SDLK_KP_1: return "kp_1";
		case SDLK_KP_2: return "kp_2";
		case SDLK_KP_3: return "kp_3";
		case SDLK_KP_4: return "kp_4";
		case SDLK_KP_5: return "kp_5";
		case SDLK_KP_6: return "kp_6";
		case SDLK_KP_7: return "kp_7";
		case SDLK_KP_8: return "kp_8";
		case SDLK_KP_9: return "kp_9";
		case SDLK_KP_PERIOD: return "kp_period";
		case SDLK_KP_DIVIDE: return "kp_divide";
		case SDLK_KP_MULTIPLY: return "kp_multiply";
		case SDLK_KP_MINUS: return "kp_minus";
		case SDLK_KP_PLUS: return "kp_plus";
		case SDLK_KP_ENTER: return "kp_enter";
		case SDLK_KP_EQUALS: return "kp_equals";
		case SDLK_UP: return "up";
		case SDLK_DOWN: return "down";
		case SDLK_RIGHT: return "right";
		case SDLK_LEFT: return "left";
		case SDLK_INSERT: return "insert";
		case SDLK_HOME: return "home";
		case SDLK_END: return "end";
		case SDLK_PAGEUP: return "pageup";
		case SDLK_PAGEDOWN: return "pagedown";
		case SDLK_F1: return "f1";
		case SDLK_F2: return "f2";
		case SDLK_F3: return "f3";
		case SDLK_F4: return "f4";
		case SDLK_F5: return "f5";
		case SDLK_F6: return "f6";
		case SDLK_F7: return "f7";
		case SDLK_F8: return "f8";
		case SDLK_F9: return "f9";
		case SDLK_F10: return "f10";
		case SDLK_F11: return "f11";
		case SDLK_F12: return "f12";
		case SDLK_F13: return "f13";
		case SDLK_F14: return "f14";
		case SDLK_F15: return "f15";
		case SDLK_NUMLOCKCLEAR: return "numlockclear";
		case SDLK_CAPSLOCK: return "capslock";
		case SDLK_SCROLLLOCK: return "scrolllock";
		case SDLK_RSHIFT: return "rshift";
		case SDLK_LSHIFT: return "lshift";
		case SDLK_RCTRL: return "rctrl";
		case SDLK_LCTRL: return "lctrl";
		case SDLK_RALT: return "ralt";
		case SDLK_LALT: return "lalt";
		case SDLK_LGUI: return "lwin";
		case SDLK_RGUI: return "rwin";
		case SDLK_MODE: return "mode";
		case SDLK_HELP: return "help";
		case SDLK_SYSREQ: return "sysreq";
		case SDLK_MENU: return "menu";
		case SDLK_POWER: return "power";
		default:
			static char kee[16];
			snprintf (kee, 16, "unk%d", key);
			return kee;
	}
}

// ---------------------------------------------------------------------------
static const char *GLErrorToString( GLenum err ) {
	// Convert a GL error to a string
	switch( err ) {
	case GL_NO_ERROR: return "GL_NO_ERROR";
	case GL_INVALID_ENUM: return "GL_INVALID_ENUM";
	case GL_INVALID_VALUE: return "GL_INVALID_VALUE";
	case GL_INVALID_OPERATION: return "GL_INVALID_OPERATION";
	case GL_STACK_OVERFLOW: return "GL_INVALID_OPERATION";
	case GL_STACK_UNDERFLOW: return "GL_STACK_UNDERFLOW";
	case GL_OUT_OF_MEMORY: return "GL_OUT_OF_MEMORY";
	case GL_TABLE_TOO_LARGE: return "GL_TABLE_TOO_LARGE";
	default: return "Unknown GL error";
	}
}

// ---------------------------------------------------------------------------
#if defined(_MSC_VER) && (defined(_M_IX86_FP) && _M_IX86_FP != 0)
#include <intrin.h>
inline static
void
check_sse(void)
{
	int info[4];
	// NB. CPUID is available since Pentium. While it is possible to 
		// to also test this, we won't bother.
	__cpuid(info, 1);
#	if _M_IX86_FP == 1
	if ((info[3] & (1 << 25)) == 0)
		onError("No SSE", "Compiled with /arch:SSE, but no SSE\n");
#	elif _M_IX86_FP == 2
	//if ((info[3] & (1 << 26)) == 0)
		//onError("No SSE2", "Compiled with /arch:SSE2, but no SSE2\n");
#	endif
}
#else // _MSC_VER && _M_IX86_FP != 0
inline static
void
check_sse(void)
{}
#endif

// ------------------------ Error Handling Functions -------------------------
#ifdef _WINDOWS
static std::wstring utf8_to_wstring( std::string str ) {
	std::wstring out( str.size(), wchar_t('\0') );
	int out_size = MultiByteToWideChar( CP_UTF8, 0, str.data(), str.size(),
		const_cast<wchar_t *>(out.data()), out.size() );
	out.resize( std::size_t(out_size) );
	return out;
}
#endif

static bool errorDlg( const char *context, const char *error, bool yesno = false ) {
#ifdef _WINDOWS
	return IDYES == MessageBoxW( GetActiveWindow(), utf8_to_wstring(error).c_str(), utf8_to_wstring(context).c_str(), (yesno ? MB_YESNO : MB_OK) | MB_ICONERROR );
#elif defined(__APPLE__) && defined(__MACH__)
  CFStringRef alertHeader = CFStringCreateWithCString(NULL, context, CFStringGetSystemEncoding());
  CFStringRef alertMessage = CFStringCreateWithCString(NULL, error, CFStringGetSystemEncoding());
  CFOptionFlags result;
	if (!yesno)
		CFUserNotificationDisplayAlert(0, kCFUserNotificationStopAlertLevel, NULL, NULL, NULL, alertHeader, alertMessage, NULL, NULL, NULL, &result);
	else
		CFUserNotificationDisplayAlert(0, kCFUserNotificationStopAlertLevel, NULL, NULL, NULL, alertHeader, alertMessage, CFSTR("Yes"), CFSTR("No"), NULL, &result);
  CFRelease(alertHeader);
  CFRelease(alertMessage);
	return result == kCFUserNotificationDefaultResponse;
#elif defined(__linux)
	int button = 0;
	int result;
	SDL_ShowCursor( true );
	if ( yesno )
	{
		static const SDL_MessageBoxButtonData buttons[] = {
			{ SDL_MESSAGEBOX_BUTTON_RETURNKEY_DEFAULT, 1, "Yes" },
			{ SDL_MESSAGEBOX_BUTTON_ESCAPEKEY_DEFAULT, 0, "No" },
    };
		const SDL_MessageBoxData data = { SDL_MESSAGEBOX_ERROR, NULL, context, error, SDL_arraysize( buttons ), buttons, NULL };
		result = SDL_ShowMessageBox( &data, &button );
	}
	else
		result = SDL_ShowSimpleMessageBox( SDL_MESSAGEBOX_ERROR, context, error, NULL );
	if ( result != 0 )
		std::cerr << error << '\n';
	return bool( button );
#else
	std::cerr << error << '\n';
	return false;
#endif
}

// ---------------------------------------------------------------------------
void onError( const char *context, const char *error ) {
	// This function is called from various locations around Eihort
	errorDlg( context, error );
	exit (1);
}

// ---------------------------------------------------------------------------
static int luaErrorDlg( lua_State *L ) {
	// eihort.errorDialog( title, message )
	errorDlg( luaL_checkstring( L, 1 ), luaL_checkstring( L, 2 ), false );
	return 0;
}

// ---------------------------------------------------------------------------
static int luaErrorDlgYesNo( lua_State *L ) {
	// response = eihort.errorDialogYesNo( title, message )
	lua_pushboolean( L, errorDlg( luaL_checkstring( L, 1 ), luaL_checkstring( L, 2 ), true ) );
	return 1;
}

// ----------------------------- Events and Time -----------------------------
inline static
void
resizeContext()
{
	// TODO: Is this function still needed given that we're now using SDL2?

	// NB. SDL 1.2 is broken, hopefully the newer versions will be sane
		// calling SDL_SetVideoMode() (as suggested by the documentation)
		// is not the right thing, since it recreates (!) the GL context;
		// all we need to do is update its size

#if defined(__APPLE__) && defined(__MACH__)
		// CoreGL
	GLint size[2] = { (GLint)g_width, (GLint)g_height };
	CGLSetParameter(CGLGetCurrentContext(), kCGLCPSurfaceBackingSize, size);
#elif defined(__linux)
		// GLX
	XResizeWindow(glXGetCurrentDisplay(), glXGetCurrentDrawable(), g_width, g_height);
#endif
}

// ---------------------------------------------------------------------------
static int luaPollEvent( lua_State *L ) {
	// eventtype, ... = eihort.pollEvent()
	SDL_Event e;
	while( SDL_PollEvent( &e ) ) {
		switch( e.type ) {
		case SDL_WINDOWEVENT:
			switch( e.window.event ) {
			case SDL_WINDOWEVENT_EXPOSED:
				g_needRefresh = true;
				lua_pushstring( L, "expose" );
				return 1;
			case SDL_WINDOWEVENT_RESIZED:
				g_width = e.window.data1;
				g_height = e.window.data2;
				SDL_SetWindowSize( g_window, g_width, g_height );
				g_needRefresh = true;
				lua_pushstring( L, "resize" );
				lua_pushnumber( L, g_width );
				lua_pushnumber( L, g_height );
				return 3;
			case SDL_WINDOWEVENT_ENTER:
			case SDL_WINDOWEVENT_LEAVE:
				lua_pushstring( L, "active" );
				lua_pushstring( L, "mouse" );
				lua_pushboolean( L, e.window.type == SDL_WINDOWEVENT_ENTER );
				return 3;
			case SDL_WINDOWEVENT_FOCUS_GAINED:
			case SDL_WINDOWEVENT_FOCUS_LOST:
				lua_pushstring( L, "active" );
				lua_pushstring( L, "input" );
				lua_pushboolean( L, e.window.type == SDL_WINDOWEVENT_FOCUS_GAINED );
				return 3;
			case SDL_WINDOWEVENT_CLOSE:
				lua_pushstring( L, "quit" );
				return 1;
			}
			break;
		case SDL_KEYDOWN:
			if( !e.key.repeat ) {
				lua_pushstring( L, "keydown" );
				lua_pushstring( L, SDLKeyToString( e.key.keysym.sym ) );
				return 2;
			}
			break;
		case SDL_KEYUP:
			lua_pushstring( L, "keyup" );
			lua_pushstring( L, SDLKeyToString( e.key.keysym.sym ) );
			return 2;
		case SDL_MOUSEMOTION:
			lua_pushstring( L, "mousemove" );
			lua_pushnumber( L, e.motion.x );
			lua_pushnumber( L, e.motion.y );
			return 3;
		case SDL_MOUSEBUTTONUP:
		case SDL_MOUSEBUTTONDOWN:
			switch (e.button.button) {
				case 2: e.button.button = 3; break;
				case 3: e.button.button = 2; break;
			}
			lua_pushstring( L, e.type == SDL_MOUSEBUTTONUP ? "mouseup" : "mousedown" );
			lua_pushnumber( L, e.button.button );
			lua_pushnumber( L, e.button.x );
			lua_pushnumber( L, e.button.y );
			return 4;
		case SDL_QUIT:
			lua_pushstring( L, "quit" );
			return 1;
		}
	}

	return 0;
}

// ---------------------------------------------------------------------------
static int luaYield( lua_State* ) {
	// eihort.yield()
	SDL_Delay( 1 );
	return 0;
}

// ---------------------------------------------------------------------------
static int luaGetTime( lua_State *L ) {
	// time = eihort.getTime()
	lua_pushnumber( L, SDL_GetTicks() / 1000.0f );
	return 1;
}


// --------------------------------- Workers ---------------------------------
static int luaGetProcessorCount( lua_State *L ) {
	// n = eihort.getProcessorCount()

	// Get number of cores for workers
#ifdef _WINDOWS
#ifdef NDEBUG
	SYSTEM_INFO sysinfo;
    GetSystemInfo(&sysinfo);
    sysinfo.dwNumberOfProcessors;
	lua_pushnumber( L, sysinfo.dwNumberOfProcessors );
#else
	lua_pushnumber( L, 1 );
#endif
#else
# if defined(NDEBUG) && defined(_POSIX_VERSION) && defined(_SC_NPROCESSORS_ONLN)
    // This works on most unices; however, it's not POSIX
	lua_pushnumber( L, sysconf(_SC_NPROCESSORS_ONLN) );
# elif defined(NDEBUG) && defined(_POSIX_VERSION) && defined(_SC_NPROC_ONLN)
	lua_pushnumber( L, sysconf(_SC_NPROC_ONLN) );
#else
	lua_pushnumber( L, 1 );
#endif
#endif
	return 1;
}

// ---------------------------------------------------------------------------
static int luaInitWorkers( lua_State *L ) {
	// eihort.initWorkers( n )
	unsigned oldWorkerCount = g_nWorkers;
	int newWorkerCount = (int)luaL_checknumber( L, 1 );
	if( newWorkerCount < 0 || (unsigned)newWorkerCount < oldWorkerCount )
		return 0;
	newWorkerCount = std::min( newWorkerCount, MAX_WORKERS );
	for( unsigned i = oldWorkerCount; i < (unsigned)newWorkerCount; i++ )
		g_workers[i] = new eihort::Worker;
	g_nWorkers = newWorkerCount;
	return 0;
}


// --------------------------- Window and Video ------------------------------
static int luaInitializeVideo( lua_State *L ) {
	// success, message = initializeVideo( w, h, fullscreen, msaa )
	int width = (int)luaL_checknumber( L, 1 );
	luaL_argcheck( L, width > 20, 1, "Width too small" );
	int height = (int)luaL_checknumber( L, 2 );
	luaL_argcheck( L, height > 20, 2, "Height too small" );
	bool fullscreen = !!lua_toboolean( L, 3 );
	int msaa = (int)luaL_checknumber( L, 4 );
	luaL_argcheck( L, msaa >= 0, 4, "MSAA too small" );
	char filename[MAX_PATH];

	g_width = width;
	g_height = height;

	// Set up the GL capabilities we want
	SDL_GL_SetAttribute( SDL_GL_STENCIL_SIZE, 0 );
	SDL_GL_SetAttribute( SDL_GL_RED_SIZE, 8 );
	SDL_GL_SetAttribute( SDL_GL_GREEN_SIZE, 8 );
	SDL_GL_SetAttribute( SDL_GL_BLUE_SIZE, 8 );
	SDL_GL_SetAttribute( SDL_GL_DEPTH_SIZE, 24 );
	SDL_GL_SetAttribute( SDL_GL_ACCUM_RED_SIZE, 0 );
	SDL_GL_SetAttribute( SDL_GL_ACCUM_GREEN_SIZE, 0 );
	SDL_GL_SetAttribute( SDL_GL_ACCUM_BLUE_SIZE, 0 );
	SDL_GL_SetAttribute( SDL_GL_DOUBLEBUFFER, 1 );
#ifndef __linux
	if( msaa > 0 ) {
		// Linux builds will ship w/o anti-aliasing until we figure this out
		SDL_GL_SetAttribute( SDL_GL_MULTISAMPLESAMPLES, msaa );
	}
#endif
	
	// Create the window
	Uint32 flags = SDL_WINDOW_OPENGL | SDL_WINDOW_SHOWN | SDL_WINDOW_RESIZABLE;
	if( fullscreen )
		flags |= SDL_WINDOW_FULLSCREEN;
	g_window = SDL_CreateWindow( "Eihort v" VERSION,
		SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
		width, height, flags );
	
	if( !g_window ) {
		lua_pushboolean( L, false );
		lua_pushstring( L, SDL_GetError() );
		return 2;
	}
	
	// Set window icon
	snprintf( filename, MAX_PATH, "%s/%s/%s", g_programRoot, RESOURCE_SUFFIX, "res/eihort-logo.ico" );
	SDL_Surface *surface = IMG_Load( filename ); // Load icon from the file
	if (surface != NULL) {
		// Set icon & free the surface
		SDL_SetWindowIcon(g_window, surface);
		SDL_FreeSurface(surface);
	}

	// Initialize the GL context
	g_glContext = SDL_GL_CreateContext( g_window );
	if( !g_glContext ) {
		lua_pushboolean( L, false );
		lua_pushstring( L, SDL_GetError() );
		return 2;
	}

	// Initialize GLEW
	GLenum err = glewInit();
	if (GLEW_OK != err) {
		lua_pushboolean( L, false );
		lua_pushstring( L, (const char*)glewGetErrorString(err) );
		return 2;
	}

	// Did we get GL 2.0?
	if( !GLEW_VERSION_2_0 ) {
		lua_pushboolean( L, false );
		lua_pushstring( L,  "Eihort requires OpenGL version 2.0 or newer to function." );
		return 2;
	}

	// GL setup
	SDL_GL_SetSwapInterval( 1 );
	glClearColor( 0.0f, 0.0f, 0.0f, 1.0f );
	glClearDepth( 1.0 );

	// Load shaders
	g_shader = new eihort::EihortShader;

	lua_pushboolean( L, true );
	return 1;
}

// ---------------------------------------------------------------------------
static int luaGetWindowDims( lua_State *L ) {
	// w, h = eihort.getWindowDims()
	if( !g_window )
		return 0;
	int w, h;
	SDL_GL_GetDrawableSize( g_window, &w, &h );
	lua_pushnumber( L, w );
	lua_pushnumber( L, h );
	return 2;
}

// ---------------------------------------------------------------------------
static int luaSetWindowCaption( lua_State *L ) {
	// eihort.setWindowCaption( caption )
	SDL_SetWindowTitle( g_window, luaL_checklstring( L, 1, NULL ) );
	return 0;
}

// ---------------------------------------------------------------------------
static int luaGetVideoMem( lua_State *L ) {
	// mem = eihort.getVideoMem()
	if( GLEW_NVX_gpu_memory_info ) {
		GLint mem;
		glGetIntegerv( GL_GPU_MEMORY_INFO_DEDICATED_VIDMEM_NVX, &mem );
		lua_pushnumber( L, mem * 1024.0 );
		return 1;
	} else if( GLEW_ATI_meminfo ) {
		GLint mem[4];
		glGetIntegerv( GL_TEXTURE_FREE_MEMORY_ATI, mem );
		lua_pushnumber( L, mem[0] * 1024.0 );
		return 1;
	} else { 
#ifdef __APPLE__
		// NOTE: Some cards lack support of the above extensions with OS X drivers

		// TODO: I could find the current render, but it might not even be relevant
		// as we could be split on multiple cards
		CGLRendererInfoObj info;
		GLint numrends;
		if( CGLQueryRendererInfo( (GLuint)-1, &info, &numrends ) == 0 ) {
			// NOTE: The software renderer is always present and reports 0,
			// we assume Eihort is running on the highest-end card
			GLint maxmem = 0;
			for( GLint i = 0; i < numrends; ++i ) {
				GLint mem;
				if( CGLDescribeRenderer( info, i, kCGLRPVideoMemoryMegabytes, &mem ) != 0) {
					(void)CGLDestroyRendererInfo( info );
					return 0;
				}
				if( mem > maxmem )
					maxmem = mem;
			}

			if( maxmem > 0 ) {
				(void)CGLDestroyRendererInfo(info);
				lua_pushnumber( L, maxmem * (1024. * 1024.) );
				return 1;
			}
		}
#endif
	} 
	return 0;
}

// ---------------------------------------------------------------------------
static int luaShouldRedraw( lua_State *L ) {
	// redraw = eihort.shouldRedraw( [redraw] )
	bool newVal = !!lua_toboolean( L, 1 );
	lua_pushboolean( L, g_needRefresh );
	g_needRefresh = newVal;
	return 1;
}

// ---------------------------------------------------------------------------
static int luaBeginRender( lua_State *L ) {
	// eihort.beginRender( x, y, w, h )

	// Set up the viewport
	int vpX = (int)luaL_optnumber( L, 1, 0 );
	int vpY = (int)luaL_optnumber( L, 2, 0 );
	int vpW = (int)luaL_optnumber( L, 3, g_width );
	int vpH = (int)luaL_optnumber( L, 4, g_height );
	glViewport( vpX, vpY, vpW, vpH );

	// Set default state
	glEnable( GL_DEPTH_TEST );
	glDepthFunc( GL_LESS );

	glClear( GL_DEPTH_BUFFER_BIT );
	glUseProgram( 0 );

	glDisable( GL_BLEND );
	glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA );
	glEnable( GL_ALPHA_TEST );
	glAlphaFunc( GL_GREATER, 0.4f );
	glDisable( GL_LIGHTING );
	glEnable( GL_CULL_FACE );
	glColorMaterial( GL_FRONT_AND_BACK, GL_AMBIENT_AND_DIFFUSE );
	float white[] = { 1.0f, 1.0f, 1.0f, 1.0f };
	glMaterialfv( GL_FRONT, GL_AMBIENT_AND_DIFFUSE, &white[0] );
	
	return 0;
}

// ---------------------------------------------------------------------------
static int luaSetClearColor( lua_State *L ) {
	// eihort.setClearColor( r, g, b )
	glClearColor( (float)luaL_checknumber( L, 1 ), (float)luaL_checknumber( L, 2 ), (float)luaL_checknumber( L, 3 ), 1.0f );
	return 0;
}

// ---------------------------------------------------------------------------
static int luaClearScreen( lua_State* ) {
	// eihort.clearScreen()
	glClear( GL_COLOR_BUFFER_BIT );
	return 0;
}

// ---------------------------------------------------------------------------
static int luaEndRender( lua_State *L ) {
	// success, message = eihort.endRender()
	SDL_GL_SwapWindow( g_window );

	GLenum err = glGetError();
	if( err == GL_NO_ERROR ) {
		lua_pushboolean( L, true );
		return 1;
	}

	lua_pushboolean( L, false );
	lua_pushstring( L, GLErrorToString( err ) );
	return 2;
}

// ---------------------------- Mouse Control --------------------------------
static int luaShowCursor( lua_State *L ) {
	// eihort.showCursor( show )
	SDL_ShowCursor( lua_toboolean( L, 1 ) ? 1 : 0 );
	return 0;
}

// ---------------------------------------------------------------------------
static int luaGetMousePos( lua_State *L ) {
	// x, y = eihort.getMousePos()
	int x, y;
	SDL_GetMouseState( &x, &y );
	lua_pushnumber( L, x );
	lua_pushnumber( L, y );
	return 2;
}

// ---------------------------------------------------------------------------
static int luaWarpMouse( lua_State *L ) {
	// eihort.warpMouse( x, y )
	SDL_WarpMouseInWindow( g_window, (Uint16)luaL_checknumber( L, 1 ), (Uint16)luaL_checknumber( L, 2 ) );
	return 0;
}

// --------------------------- Utility Functions -----------------------------
static int luaAzimuthPitch( lua_State *L ) {
	// fx, fy, fz, ux, uy, uz, rx, ry, rz = eihort.fwdUpRightFromAzPitch( azimuth, pitch )
	float azimuth = (float)luaL_checknumber( L, 1 );
	float pitch = (float)luaL_checknumber( L, 2 );

	jMatrix tempAzimuth, tempPitch, final;

	jMatrixSetRotationAxis( &tempAzimuth, 0.0f, 0.0f, 1.0f, azimuth );
	jMatrixSetRotationAxis( &tempPitch, 1.0f, 0.0f, 0.0f, pitch );
	jMatrixMultiply( &final, &tempAzimuth, &tempPitch );

	// Eihort -> Minecraft coordinate conversion here
	lua_pushnumber( L, final.fwd.y );
	lua_pushnumber( L, final.fwd.z );
	lua_pushnumber( L, final.fwd.x );
	lua_pushnumber( L, final.up.y );
	lua_pushnumber( L, final.up.z );
	lua_pushnumber( L, final.up.x );
	lua_pushnumber( L, final.right.y );
	lua_pushnumber( L, final.right.z );
	lua_pushnumber( L, final.right.x );
	return 9;
}

// ---------------------------------------------------------------------------
static int luaIntAnd( lua_State *L ) {
	// c = eihort.intAnd( a, b )
	unsigned i1 = (unsigned)luaL_checknumber( L, 1 );
	unsigned i2 = (unsigned)luaL_checknumber( L, 2 );
	lua_pushnumber( L, i1 & i2 );
	return 1;
}

// ---------------------------------------------------------------------------
static int luaIntOr( lua_State *L ) {
	// c = eihort.intOr( a, b )
	unsigned i1 = (unsigned)luaL_checknumber( L, 1 );
	unsigned i2 = (unsigned)luaL_checknumber( L, 2 );
	lua_pushnumber( L, i1 | i2 );
	return 1;
}

// ---------------------------------------------------------------------------
static int luaGetSystemLanguage( lua_State *L ) {
	// lang = eihort.getSystemLanguage()
	// Locale should be in short form, e.g. "en_US" or "fr_CA"
#ifdef _WIN32
	wchar_t buf[LOCALE_NAME_MAX_LENGTH];
	if( GetUserDefaultLocaleName( &buf[0], LOCALE_NAME_MAX_LENGTH ) ) {
		char cbuf[LOCALE_NAME_MAX_LENGTH];
		for( unsigned i = 0; i < sizeof(cbuf); i++ )
			cbuf[i] = char(buf[i]);
		lua_pushstring( L, cbuf );
		return 1;
	}
#elif defined(_POSIX_VERSION)
	const char *msg_locale = std::setlocale( LC_MESSAGES, NULL );
	if( msg_locale != NULL ) {
		if( const char *stop = std::strchr( msg_locale, '.' ) )
			lua_pushlstring( L, msg_locale, stop - msg_locale );
		else
			lua_pushstring( L, msg_locale );
		return 1;
	}
#endif
	return 0;
}

// ---------------------------------------------------------------------------
static int luaCreateDirectory( lua_State *L ) {
	// success = eihort.createDirectory( path )
#ifdef _WINDOWS
	lua_pushboolean( L, CreateDirectoryA( luaL_checkstring( L, 1 ), NULL ) );
#elif defined(_POSIX_VERSION)
	lua_pushboolean( L, mkdir( luaL_checkstring( L, 1 ), S_IRWXU | S_IRWXG | S_IRWXO ) == 0 );
#else
#error implement me
#endif
	return 1;
}

// ----------------------------- Zip File Access -----------------------------
static int luaIndexZip( lua_State *L ) {
	// index = eihort.indexZip( zipfile )
	const char *path = luaL_checkstring( L, 1 );
	Unzip zipfile( path );
	if( !zipfile.good() )
		return 0;
	lua_newtable( L );
	for( auto it = zipfile.begin(); it != zipfile.end(); ++it ) {
		lua_pushstring( L, it->filename().c_str() );
		stringstream ss;
		if( it->is_stored() ) {
			ss << it->start() << ':' << it->uncompressed_size();
		} else {
			ss << it->start() << ':' << it->comp_size() << '>' << it->uncompressed_size();
		}
		lua_pushstring( L, ss.str().c_str() );
		lua_settable( L, -3 );
	}
	return 1;
}

// ---------------------------------------------------------------------------
static int luaReadFileFromZipDirect( lua_State *L ) {
	// data = eihort.readFileZipDirect( zipfile, start, uncsize )
	const char *zippath = luaL_checkstring( L, 1 );
	std::size_t start = (std::size_t)luaL_checkinteger( L, 2 );
	std::size_t comp_size = (std::size_t)luaL_checkinteger( L, 3 );

	// Open the file
	std::ifstream f( zippath, std::ios::in | std::ios::binary );
	if( !f.good() ) {
		lua_pushstring( L, "Failed to open zip file" );
		lua_error( L );
	}

	// Seek to the start
	if( !f.seekg( start, std::ios_base::beg ) ) {
		lua_pushstring( L, "Failed to seek" );
		lua_error( L );
	}

	void *data = NULL;
	std::size_t datasize;
	if( lua_isnumber( L, 4 ) ) {
		// Compressed file
		std::size_t uncomp_size = (std::size_t)luaL_checkinteger( L, 4 );

		// Read the compressed data
		void *inbuf = malloc( comp_size );
		if( !f.read((char*)inbuf, comp_size) ) {
			lua_pushstring( L, "Failed to read from file" );
			lua_error( L );
		}

		// Inflate it
		z_stream z;
		z.avail_in = (uInt)comp_size;
		z.next_in = reinterpret_cast<Bytef *>(inbuf);
		z.zalloc = NULL;
		z.zfree = NULL;
		if( inflateInit2(&z, -MAX_WBITS) != Z_OK ) {
			lua_pushstring( L, "Failed to initialize inflate stream" );
			lua_error( L );
		}
		data = malloc( uncomp_size );
		datasize = uncomp_size;
		z.avail_out = (uInt)uncomp_size;
		z.next_out = reinterpret_cast<Bytef *>(data);
		int err = inflate(&z, Z_FINISH);
		if( inflateEnd(&z) != Z_OK || err != Z_STREAM_END ) {
			free( data );
			free( inbuf );
			lua_pushstring( L, "Failed to inflate file" );
			lua_error( L );
		}
		free( inbuf );
	} else {
		// Uncompressed - simply read from the zipfile
		data = malloc( comp_size );
		datasize = comp_size;
		if( !f.read((char*)data, comp_size) ) {
			free( data );
			lua_pushstring( L, "Failed to read from file" );
			lua_error( L );
		}
	}

	// Push the file as a string
	lua_pushlstring( L, (char*)data, datasize );

	// Clean up
	free( data );
	return 1;
}

#ifdef _WINDOWS
#	include <errno.h>
#	include <io.h>
#	define access _access
#	define F_OK 00
#	define R_OK 04
#	define W_OK 02
#	define X_OK 00 // All files are executable on Windows
#endif

static int luaFileAccess( lua_State *L ) {
	// fileAccess( filename ) tests if the file exists
	// fileAccess( filename, "r" ) test if the file is readable
	// fileAccess( filename, "rw" ) test if the file can read and written
	const char *filename = luaL_checkstring( L, 1 );
	const char *modestring = luaL_optstring( L, 2, "" );
#if defined( _WINDOWS ) || defined( _POSIX_VERSION )
	int mask = 0;
	for ( const char *modechar = modestring; *modechar != '\0'; ++modechar )
		switch ( *modechar ) {
			case 'r': mask |= R_OK; break;
			case 'w': mask |= W_OK; break;
			case 'x': mask |= X_OK; break;
			default:
				lua_pushnil( L );
				return 1;
		}
	if ( mask == 0 )
		mask = F_OK;
	if ( access( filename, mask ) == 0 )
		lua_pushboolean( L, true );
	else if ( errno == EACCES )
		lua_pushboolean( L, false );
	else
		lua_pushnil( L );
#else
#error implement me
#endif
	return 1;
}

// ---------------------------------------------------------------------------
const luaL_Reg BaseEihort_functions[] = {
	// Error dialogs
	{ "errorDialog", &luaErrorDlg },
	{ "errorDialogYesNo", &luaErrorDlgYesNo },

	// Events and time
	{ "pollEvent", &luaPollEvent },
	{ "yield", &luaYield },
	{ "getTime", &luaGetTime },

	// Workers
	{ "getProcessorCount", &luaGetProcessorCount },
	{ "initWorkers", &luaInitWorkers },

	// Window and video controls
	{ "initializeVideo", &luaInitializeVideo },
	{ "getWindowDims", &luaGetWindowDims },
	{ "setWindowCaption", &luaSetWindowCaption },
	{ "getVideoMem", &luaGetVideoMem },
	{ "shouldRedraw", &luaShouldRedraw },
	{ "beginRender", &luaBeginRender },
	{ "setClearColor", &luaSetClearColor },
	{ "clearScreen", &luaClearScreen },
	{ "endRender", &luaEndRender },

	// Mouse control
	{ "showCursor", &luaShowCursor },
	{ "getMousePos", &luaGetMousePos },
	{ "warpMouse", &luaWarpMouse },

	// Utility functions
	{ "fwdUpRightFromAzPitch", &luaAzimuthPitch },
	{ "intAnd", &luaIntAnd },
	{ "intOr", &luaIntOr },
	{ "getSystemLanguage", &luaGetSystemLanguage },
	{ "createDirectory", luaCreateDirectory },
	{ "fileAccess", luaFileAccess },

	// Zip file access
	{ "indexZip", luaIndexZip },
	{ "readFileZipDirect", luaReadFileFromZipDirect },

	{ NULL, NULL }
};


// ======================= Main Initialization Functions =====================

void initLowLevel( const char *progname ) {
	// Initializes the low-level systems used by Eihort

#ifdef _WINDOWS
	(void)progname;

	// Check SSE
	check_sse();

	// Get program path
	GetModuleFileNameA(0, g_programRoot, sizeof(g_programRoot) - 1);
	char *pch = &g_programRoot[0], *lastSlash = NULL;
	while( *pch ) {
		switch( *pch ) {
		case '\\':
			*pch = '/';
		case '/':
			lastSlash = pch;
			break;
		}
		pch++;
	}
	*lastSlash = '\0';
#else
	strcpy( g_programRoot, progname );
	char *pch = &g_programRoot[0], *lastSlash = NULL;
	while( *pch ) {
		if( *pch == '/' )
			lastSlash = pch;
		pch++;
	}
	*lastSlash = '\0';
#endif

	// Create default worker
	g_nWorkers = 1;
	g_workers[0] = new eihort::Worker;

	// Initialize SDL
	if ( SDL_Init( SDL_INIT_VIDEO ) < 0 )
		onError( "SDL Initialization Error", SDL_GetError() );
}

// ---------------------------------------------------------------------------
static void initLua() {
	lua_State *L = g_L = luaL_newstate();
	luaL_openlibs( L );

	lua_newtable( L );

	// Detected paths
	char path[MAX_PATH], tmp_path[MAX_PATH];
	snprintf( path, MAX_PATH, "%s/%s/", g_programRoot, ROOT_SUFFIX );
	lua_pushstring( L, path );
	lua_setfield( L, -2, "ProgramPath" );
	snprintf( path, MAX_PATH, "%s/", minecraft_path( tmp_path ) );
	lua_pushstring( L, path );
	lua_setfield( L, -2, "MinecraftPath" );

	// Eihort version
	lua_pushstring( L, VERSION );
	lua_setfield( L, -2, "Version" );

	// Register Eihort functions found in main.cpp
	luaL_setfuncs( L, BaseEihort_functions, 0 );

	// Set up the metatables and global functions for all utilities exposed by Eihort
	eihort::MCRegionMap::setupLua( L );
	eihort::WorldQTree::setupLua( L );
	eihort::LightModel::setupLua( L );
	eihort::Sky::setupLua( L );
	eihort::geom::BlockGeometry::setupLua( L );
	eihort::MCBlockDesc::setupLua( L );
	FindFile_setupLua( L );
	LuaNBT_setupLua( L );
	LuaImage_setupLua( L );
	LuaUIRect::setupLua( L );
	UIDrawContext::setupLua( L );

	lua_setglobal( L, "eihort" );
}

// ---------------------------------------------------------------------------
static int runLuaMain( int argc, const char **argv ) {
	// Runs eihort.lua, with ... set to the cmdline args
	char filename[MAX_PATH];
	snprintf( filename, MAX_PATH, "%s/%s/%s", g_programRoot, ROOT_SUFFIX, "eihort.lua" );
	int ret = -1;
	if( 0 == luaL_loadfile( g_L, filename ) ) {
		for( int i = 1; i < argc; i++ )
			lua_pushstring( g_L, argv[i] );
		
		if( 0 != lua_pcall( g_L, argc - 1, 1, 0 ) ) {
			errorDlg( "Fatal Error", lua_tostring( g_L, -1 ) );
			lua_pop( g_L, 1 );
		} else {
			ret = (int)luaL_optnumber( g_L, -1, 0 );
			lua_pop( g_L, 1 );
		}
	} else {
		errorDlg( "Fatal Error", lua_tostring( g_L, -1 ) );
		lua_pop( g_L, 1 );
	}
	return ret;
}

// ================================= Main ====================================
int main( int argc, char **argv ) {
	std::setlocale(LC_ALL, "");

#ifdef __APPLE__
	// NOTE: macOS Sierra adds -psn_X_XXX when launched from Finder
	 // This strips it out, so it doesn't get parsed as a world name
	{
		int top = 1;
		for( int i = 1; i < argc; ++i )
			if( std::strncmp( argv[i], "-psn_", sizeof("-psn_")-1 ) != 0 )
				argv[top++] = argv[i];

		argc = top;
		argv[top] = NULL;
	}
#endif

	initLowLevel(*argv);
	initLua();

	return runLuaMain( argc, (const char**)argv );
}

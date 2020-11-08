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


#include "findfile.h"
#include "mcregionmap.h"
#include "mcbiome.h"
#include "worldqtree.h"
#include "platform.h"
#include "endian.h"

#define MCREGIONMAP_META "MCRegionMap"

#if defined(__APPLE__) && defined(__MACH__)
  // Needed for FSEvent api
# include <CoreServices/CoreServices.h>
#endif

#if defined(__linux) || defined(linux)
  // inotify(7)
# include <sys/inotify.h>
# include <unistd.h>
#endif

namespace eihort {

// -----------------------------------------------------------------
inline int toRegionCoord( int x ) {
	return shift_right( x, 5 );
}

// -----------------------------------------------------------------
MCRegionMap::MCRegionMap( const char *rootPath, bool anvil )
: root(""), anvil(anvil)
, minRgX(0), maxRgX(0), minRgY(0), maxRgY(0)
, watchUpdates(false)
{
	rgDescMutex = SDL_CreateMutex();

	changeRoot( rootPath, anvil );
	changeThread = SDL_CreateThread( updateScanner, "Eihort File Scanner", this );
}

// -----------------------------------------------------------------
MCRegionMap::~MCRegionMap() {
}

// -----------------------------------------------------------------
void MCRegionMap::changeRoot( const char *newRoot, bool anvil ) {
	root = newRoot;
	this->anvil = anvil;
	if( root[this->root.length()-1] == '/' || root[this->root.length()-1] == '\\' )
		this->root = this->root.substr( 0, this->root.length()-1 );
	
	flushRegionSectors();
	exploreDirectories();
}

// -----------------------------------------------------------------
void MCRegionMap::checkForRegionChanges() {
	exploreDirectories();
}

// -----------------------------------------------------------------
MCRegionMap::ChangeListener::ChangeListener() {
}

// -----------------------------------------------------------------
MCRegionMap::ChangeListener::~ChangeListener() {
}

// -----------------------------------------------------------------
void MCRegionMap::getWorldChunkExtents( int &minx, int &maxx, int &miny, int &maxy ) {
	const unsigned rgShift = 5; // 32 chunks/region
	miny = minRgX << rgShift;
	maxy = ((maxRgX+1) << rgShift) - 1;
	minx = minRgY << rgShift;
	maxx = ((maxRgY+1) << rgShift) - 1;
}

// -----------------------------------------------------------------
void MCRegionMap::getWorldBlockExtents( int &minx, int &maxx, int &miny, int &maxy ) {
	const unsigned rgShift = 5+4; // 32 chunks/region, 16 blocks/chunk
	miny = minRgX << rgShift;
	maxy = ((maxRgX+1) << rgShift) - 1;
	minx = minRgY << rgShift;
	maxx = ((maxRgY+1) << rgShift) - 1;
}

// -----------------------------------------------------------------
nbt::Compound *MCRegionMap::readChunk( int x, int y ) {
	unsigned t;
	if( getChunkInfo( x, y, t ) ) {
		char regionfn[MAX_PATH];
		snprintf( regionfn, MAX_PATH, "%s/region/r.%d.%d.%s", root.c_str(), toRegionCoord(x), toRegionCoord(y), getRegionExt() );
		return nbt::readFromRegionFile( regionfn, ((unsigned)x&31) + (((unsigned)y&31)<<5) );
	}
	return NULL;
}

// -----------------------------------------------------------------
void MCRegionMap::exploreDirectories() {
	char dirname[MAX_PATH];
	snprintf( dirname, MAX_PATH, "%s/region/*.%s", root.c_str(), getRegionExt() );

	FindFile find( dirname );

	const char *file = find.filename();
	if( file != NULL ) {
		do {
			// Is this a valid region filename?
			int regionX, regionY;
			if( file[0] != 'r' || file[1] != '.' )
				continue;
			char *s;
			regionX = strtol( &file[2], &s, 10 );
			if( s[0] != '.' )
				continue;
			s++;
			regionY = strtol( s, &s, 10 );
			if( abs( regionX ) > 0x0001ffff || abs( regionY ) > 0x0001ffff )
				continue;
			if( *s != '.' || 0 != strcmp( s+1, getRegionExt() ) )
				continue;

			// It's valid
			ChunkCoords rgCoords ={ regionX, regionY };

			RegionMap::iterator it = regions.find( rgCoords );
			if( it != regions.end() ) {
				// We've seen this region before. Maybe we're
				// reloading regions after level.dat update
				if( it->second.chunkTimes ) {
					// The region is already loaded - check it for changes
					checkRegionForChanges( regionX, regionY, &it->second );
				}
			} else {
				// New undiscovered region
				RegionDesc rg;
				rg.chunkTimes = NULL;
				rg.sectors = NULL;
				regions[rgCoords] = rg;

				if( rgCoords.x < minRgX )
					minRgX = rgCoords.x;
				if( rgCoords.x > maxRgX )
					maxRgX = rgCoords.x;
				if( rgCoords.y < minRgY )
					minRgY = rgCoords.y;
				if( rgCoords.y > maxRgY )
					maxRgY = rgCoords.y;
			}
		} while( (file = find.next()) != NULL );
	}
}

// -----------------------------------------------------------------
void MCRegionMap::flushRegionSectors() {
	SDL_mutexP( rgDescMutex );
	for( RegionMap::iterator it = regions.begin(); it != regions.end(); ++it ) {
		delete[] it->second.chunkTimes;
		it->second.chunkTimes = NULL;
		delete[] it->second.sectors;
		it->second.sectors = NULL;
	}
	regions.clear();
	SDL_mutexV( rgDescMutex );
}

// -----------------------------------------------------------------
void MCRegionMap::checkRegionForChanges( int x, int y, RegionDesc *region ) {
	ChunkCoords c = { x, y };

	char regionfn[MAX_PATH];
	snprintf( regionfn, MAX_PATH, "%s/region/r.%d.%d.%s", root.c_str(), c.x, c.y, getRegionExt() );
	FILE *f = fopen( regionfn, "rb" );

	if( !f ) {
		// File existed a nanosecond ago.. what just happened?
		delete[] region->chunkTimes;
		region->chunkTimes = NULL;
		delete[] region->sectors;
		region->sectors = NULL;
		return;
	}

	// Read the sector offsets
	fseek( f, 0, SEEK_SET );
	fread( region->sectors, 4, 1024, f );

	// Check for changed chunks
	for( unsigned i = 0; i < 1024; i++ ) {
		unsigned newTime;
		fread( &newTime, 4, 1, f );
		newTime = bswap_from_big( newTime );
		region->sectors[i] = bswap_from_big( region->sectors[i] );
		if( region->chunkTimes[i] < newTime ) {
			// A chunk changed!
			region->chunkTimes[i] = newTime;
			if( listener ) {
				int x = (c.x<<5)+(int)(i&31);
				int y = (c.y*32)+(int)(i>>5);
				listener->chunkChanged( y, x );
			}
		}
	}

	fclose( f );
}

// -----------------------------------------------------------------
bool MCRegionMap::getChunkInfo( int x, int y, unsigned &updTime ) {
	SDL_mutexP( rgDescMutex );

	// Find the region
	ChunkCoords c = { toRegionCoord(x), toRegionCoord(y) };
	RegionMap::iterator it = regions.find( c );
	if( it == regions.end() ) {
		SDL_mutexV( rgDescMutex );
		return false;
	}

	if( !it->second.chunkTimes ) {
		// Load the region file containing this chunk
		char regionfn[MAX_PATH];
		snprintf( regionfn, MAX_PATH, "%s/region/r.%d.%d.%s", root.c_str(), c.x, c.y, getRegionExt() );
		FILE *f = fopen( regionfn, "rb" );

		if( !f ) {
			SDL_mutexV( rgDescMutex );
			return false;
		}

		it->second.chunkTimes = new uint32_t[1024];
		it->second.sectors = new uint32_t[1024];
		fseek( f, 0, SEEK_SET );
		fread( it->second.sectors, 4, 1024, f );
		fread( it->second.chunkTimes, 4, 1024, f );
		fclose( f );

		for( unsigned i = 0; i < 1024; i++ ) {
			it->second.chunkTimes[i] = bswap_from_big( it->second.chunkTimes[i] );
			it->second.sectors[i] = bswap_from_big( it->second.sectors[i] );
		}
	}
	SDL_mutexV( rgDescMutex );

	// Get the update time
	unsigned i = ((unsigned)x&31) + (((unsigned)y&31)<<5);
	updTime = it->second.chunkTimes[i];

	//return updTime != 0; // Apparently the timestamps are unreliable? This punches holes in the world.
	return it->second.sectors[i] != 0;
}

// -----------------------------------------------------------------
int MCRegionMap::updateScanner( void *rgMapCookie ) {
	MCRegionMap *rgMap = static_cast<MCRegionMap*>( rgMapCookie );

#ifdef _WINDOWS
	unsigned lastFullScan = SDL_GetTicks();

	// PS-WIN32: Directory change signals
	char notifyInfo[16*1024];
	snprintf( notifyInfo, 16*1024, "%s/", rgMap->root.c_str() );
	HANDLE dirHandle = CreateFileA( notifyInfo, FILE_LIST_DIRECTORY, 7, NULL, OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS, NULL );

	while( true ) {
		DWORD len = 0;

		if( ReadDirectoryChangesW( dirHandle, &notifyInfo[0], sizeof(notifyInfo), TRUE,
			FILE_NOTIFY_CHANGE_LAST_WRITE | FILE_NOTIFY_CHANGE_FILE_NAME,
			&len, NULL, NULL ) ) {

			if( rgMap->watchUpdates ) {
				unsigned now = SDL_GetTicks();
				if( now - lastFullScan < 1000 ) {
					SDL_Delay( 1000 ); // At least 1s between updates
					lastFullScan = now;
				}

				SDL_mutexP( rgMap->rgDescMutex );
				rgMap->exploreDirectories();
				SDL_mutexV( rgMap->rgDescMutex );
			}
		}
	}

#elif defined(__APPLE__) && defined(__MACH__)
  // Mac OS X FSEvent API
    // I'd prefer kqueue(2), but it does not allow detection of file changes
    // w/o registering the files. Ask Jason what's the actual use scenario.

  struct Callback {
    static void callback(ConstFSEventStreamRef, void *cookie, size_t, void *, const FSEventStreamEventFlags *, const FSEventStreamEventId *)
    {
			MCRegionMap *rgMap = static_cast<MCRegionMap*>( cookie );
      if (rgMap->watchUpdates)
      {
        SDL_mutexP( rgMap->rgDescMutex );
        rgMap->exploreDirectories();
        SDL_mutexV( rgMap->rgDescMutex );
      }
    }
  };

  CFStringRef path = CFStringCreateWithCString(NULL, rgMap->root.c_str(), CFStringGetSystemEncoding());
  CFArrayRef paths = CFArrayCreate(NULL, (const void **)&path, 1, NULL);
  FSEventStreamContext callback_data = { 0, (void *)rgMap, NULL, NULL, NULL };
  FSEventStreamRef stream = FSEventStreamCreate(NULL,
    &Callback::callback,
    &callback_data,
    paths,
    kFSEventStreamEventIdSinceNow,
    CFAbsoluteTime(1.0),
    kFSEventStreamCreateFlagNone);
  FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
  FSEventStreamStart(stream);
  CFRunLoopRun();
  FSEventStreamStop(stream);
  FSEventStreamRelease(stream);
  CFRelease(path);
  CFRelease(paths);

#else
# if defined(__linux) || defined(linux)
  // Linux inotify(7)

  char buf[BUFSIZ];
  int fd = inotify_init();
  if (inotify_add_watch(fd, rgMap->root.c_str(), IN_CREATE | IN_DELETE | IN_MODIFY) != -1 &&
      inotify_add_watch(fd, (rgMap->root + "/region/").c_str(), IN_CREATE | IN_DELETE | IN_MODIFY) != -1)
    while (0 < read(fd, buf, BUFSIZ))
# else
  // Far from optimal..
  for (;;)

# endif
    if (rgMap->watchUpdates)
    {
      SDL_mutexP( rgMap->rgDescMutex );
      rgMap->exploreDirectories();
      SDL_mutexV( rgMap->rgDescMutex );
      SDL_Delay(1000);
    }
#endif

	return 0;
}

// -----------------------------------------------------------------
int MCRegionMap::lua_create( lua_State *L ) {
	// regions = eihort.loadWorld( rootpath, anvil )
	const char *root = luaL_checklstring( L, 1, NULL );
	luaL_argcheck( L, lua_isboolean( L, 2 ) || lua_isnoneornil( L, 2 ), 2, "Expected Anvil flag" );
	MCRegionMap *regions = new MCRegionMap( root, !!lua_toboolean( L, 2 ) );
	regions->setupLuaObject( L, MCREGIONMAP_META );
	regions->lua_push();
	return 1;
}

// -----------------------------------------------------------------
int MCRegionMap::lua_getRegionCount( lua_State *L ) {
	// n = regions:getRegionCount()
	lua_pushnumber( L, getLuaObjectArg<MCRegionMap>( L, 1, MCREGIONMAP_META )->getTotalRegionCount() );
	return 1;
}

// -----------------------------------------------------------------
int MCRegionMap::lua_getRootPath( lua_State *L ) {
	// rootpath = regions:getRootPath()
	char path[MAX_PATH];
	strcpy( path, getLuaObjectArg<MCRegionMap>( L, 1, MCREGIONMAP_META )->getRoot().c_str() );
	strcat( path, "/" );
	lua_pushstring( L, &path[0] );
	return 1;
}

// -----------------------------------------------------------------
int MCRegionMap::lua_changeRootPath( lua_State *L ) {
	// regions:changeRootPath( rootpath )
	MCRegionMap *regions = getLuaObjectArg<MCRegionMap>( L, 1, MCREGIONMAP_META );
	regions->changeRoot( luaL_checklstring( L, 2, NULL ), regions->anvil );
	return 0;
}

// -----------------------------------------------------------------
int MCRegionMap::lua_setMonitorState( lua_State *L ) {
	// regions:setMonitorState( on )
	luaL_argcheck( L, lua_isboolean( L, 2 ), 2, "Expected monitor state" );
	getLuaObjectArg<MCRegionMap>( L, 1, MCREGIONMAP_META )->watchUpdates = !!lua_toboolean( L, 2 );
	return 0;
}

// -----------------------------------------------------------------
static void parseBiomeCoordData( BiomeCoordData& biomeIdToCoords, lua_State *L, int index )
{
	// Loop through the table
	for( lua_pushnil( L ); lua_next( L, index ) != 0; lua_pop( L, 1 ) ) {
		// Get key & value
		lua_Integer id = luaL_checkinteger( L, -2 );
		lua_Integer coord = luaL_checkinteger( L, -1 );

		// Check data 
		luaL_argcheck( L, 0 <= id && id < 16*16 && 0 <= coord && coord <= 0xffff,
			index, "Biome ID must be in [0, 256) and coordinate in [0, 65536)." );

		// Add data
		if( unsigned(id) >= biomeIdToCoords.size() )
			biomeIdToCoords.resize( id + 1, 0xAD32u );
		biomeIdToCoords[id] = (unsigned short)coord;
	}
}

// -----------------------------------------------------------------
int MCRegionMap::lua_createView( lua_State *L ) {
	// view = regions:createView( blocks )
	MCRegionMap *regions = getLuaObjectArg<MCRegionMap>( L, 1, MCREGIONMAP_META );
	MCBlockDesc *blocks = getLuaObjectArg<MCBlockDesc>( L, 2, MCBLOCKDESC_META );
	unsigned leafShift = (unsigned)luaL_optnumber( L, 3, 7.0 );
	luaL_argcheck( L, leafShift >= 2 && leafShift <= 12, 2, "The QTree leaf size must be at least 2 and no more than 12." );
	BiomeCoordData biomeIdToCoords;
	if( lua_type( L, 4 ) == LUA_TTABLE )
		parseBiomeCoordData( biomeIdToCoords, L, 4 );
	WorldQTree::createNew( L, regions, blocks, leafShift, biomeIdToCoords );
	return 1;
}

// -----------------------------------------------------------------
int MCRegionMap::lua_destroy( lua_State *L ) {
	// regions:destroy()
	delete getLuaObjectArg<MCRegionMap>( L, 1, MCREGIONMAP_META );
	return 0;
}

// -----------------------------------------------------------------
static const luaL_Reg MCRegionMap_functions[] = {
	{ "getRegionCount", &MCRegionMap::lua_getRegionCount },
	{ "getRootPath", &MCRegionMap::lua_getRootPath },
	{ "changeRootPath", &MCRegionMap::lua_changeRootPath },
	{ "setMonitorState", &MCRegionMap::lua_setMonitorState },
	{ "createView", &MCRegionMap::lua_createView },
	{ "destroy", &MCRegionMap::lua_destroy },
	{ NULL, NULL }
};

void MCRegionMap::setupLua( lua_State *L ) {
	luaL_newmetatable( L, MCREGIONMAP_META );
	lua_pushvalue( L, -1 );
	lua_setfield( L, -2, "__index" );
	luaL_setfuncs( L, &MCRegionMap_functions[0], 0 );
	lua_pop( L, 1 );

	lua_pushcfunction( L, &MCRegionMap::lua_create );
	lua_setfield( L, -2, "loadWorld" );
}

} // namespace eihort


-- This is the main module of Eihort
-- It contains an event processing system for window, input and other events,
-- the main initialization code (including the loading of the configuration
-- file), and the main loop.


require "mcversions"
require "devtools"

------------------------------------------------------------------------------
-- Event dispatch system

EventDownAction = { };
EventUpAction = { };
EventState = { };

local function eventDown( evt )
	EventState[evt] = false;
	local action = EventDownAction[evt];
	if action then
		action();
	end
end
local function eventUp( evt )
	EventState[evt] = nil;
	local action = EventUpAction[evt];
	if action then
		action();
	end
end
Event = {
	-- The names of these events are (mostly) hard-coded in eihort.exe

	-- Filled in later:
	-- redraw(): Called to draw the screen again
	-- mousemove( x, y ): The mouse just moved
	-- idle(): Called when there's nothing else to do.
	--         Return true to save CPU

	active = function( type, state )
		if type == 'mouse' then
			if state then
				eventDown( 'mfocus' );
			else
				eventUp( 'mfocus' );
			end
		end
	end;
	resize = function( w, h )
		ScreenWidth = w;
		ScreenHeight = h;
		ScreenAspect = w / h;
		eventDown( 'resize' );
	end;
	keydown = eventDown;
	keyup = eventUp;
	mousedown = function( button, x, y )
		Event.mousemove( x, y );
		eventDown( 'mouse' .. button );
	end;
	mouseup = function( button, x, y )
		Event.mousemove( x, y );
		eventUp( 'mouse' .. button );
	end;
	quit = function()
		-- User closed the window
		QuitFlag = 0;
	end;
	error = function( msg )
		local ignore = eihort.errorDialogYesNo( LANG"ERR_Error", debug.traceback( msg, 3 ) .. "\n\n" .. LANG"ERR_Attempt_Ignore" );
		if not ignore then
			QuitFlag = 1;
		end
	end;
};

local function main()
	-- Helper to process a single event
	local function processEvent( evtStr, ... )
		if not evtStr then
			return false;
		end

		local handler = Event[evtStr];
		if handler then
			handler( ... );
		end

		return true;
	end

	-- The main loop
	assert( Event.redraw );
	assert( Event.idle );

	while not QuitFlag do
		if not processEvent( eihort.pollEvent() ) then
			local idle = Event.idle();
			if eihort.shouldRedraw( Config.disable_cpu_saver ) then
				Event.redraw();
			end
			if idle then
				eihort.yield(); -- Don't kill the CPU
			end
		end
	end
	return QuitFlag;
end

------------------------------------------------------------------------------
-- Program state table

ProgramState = {
	defaultVRAM = 512;
};

------------------------------------------------------------------------------
-- Config helpers

local function autodetectMCJar( minecraft_path )
	-- Try to figure out where the Minecraft jar file is
	local bestVersion, bestVersionVal;
	
	foundVersions = { };  -- Create an empty table for debug prints
	
	-- Find all files in MC location and check for the latest one
	ff = eihort.findFile( minecraft_path .. "versions/*" );
	if ff then
		repeat
			local fn, isdir = ff:filename();
			if isdir and string.sub( fn, 1, 1 ) ~= "." then
				local snapshot = fn;
				if MinecraftVersions[fn] then
					snapshot = MinecraftVersions[fn];
				end
				if snapshot then
					local year, week, subweek = string.match( snapshot, "^(%d+)w(%d+)(%w?)$" );
					if year then
						local val = tonumber(year) * 100 + tonumber(week) + (subweek == "" and 0 or string.byte(subweek) / 256);
						if not bestVersion or val > bestVersionVal then
							bestVersion = fn;
							bestVersionVal = val;
						end
						
						-- Insert velues into debug table
						table.insert( foundVersions, { fn, val } );
						foundVersions["bestVersion"] = bestVersion;
						foundVersions["bestVersionVal"] = bestVersionVal;
					end
				end
			end
		until not ff:next();
		ff:close();
	end
	
	if bestVersion then
		ProgramState.usedMCVersion = bestVersion;
		return minecraft_path .. "versions/" .. bestVersion .. "/" .. bestVersion .. ".jar";
	end
end

local function listFiles( path )
	-- Helper function exposed to the config which just lists
	-- files in a directory
	
	local t = { };
	local ff = eihort.findFile( path );
	if ff then
		local root = string.match( path, "^(.-)[^/\\]*$" );
		if root ~= "" then
			root = root .. "/";
		end
		repeat
			local filename, isdir = ff:filename();
			if not isdir then
				table.insert( t, root .. filename );
			end
		until not ff:next();
	end
	return t;
end

local outputPath;
do
	local paths = { eihort.ProgramPath };
	local xdgDesktop = os.getenv( 'XDG_DESKTOP_DIR' );
	if xdgDesktop then
		table.insert( paths, xdgDesktop .. "/" );
	end
	local home = os.getenv( 'HOME' );
	if not home and os.getenv( 'USERPROFILE' ) then
		home = os.getenv( 'USERPROFILE' );
	end
	if home then
		table.insert( paths, home .. "/Desktop/" );
		table.insert( paths, home .. "/" );
	end
	for _, path in ipairs( paths ) do
		if eihort.fileAccess( path, "rw" ) then
			outputPath = path;
			break;
		end
	end
	if not outputPath then
		eihort.errorDialog( "Eihort Error", "Cannot locate a writable path for output files." );
	end
end

------------------------------------------------------------------------------
-- Read in the config

function tableMerge( t1, t2 )
	--deep-merges two tables.
	--if e.g. ~/.config/eihort.config has only some key bindings redefined,
	--the global eihort.config's "keys" table should still contain the others.
	for k, v in pairs( t2 ) do
		if type( v ) == "table" and type( t1[k] ) == "table" then
			tableMerge( t1[k], v )
		else
			t1[k] = v
		end
	end
end

Config = {
	getenv = os.getenv;
	minecraft_path = eihort.MinecraftPath;
	eihort_path = eihort.ProgramPath;
	output_path = outputPath;
	autodetectMCJar = autodetectMCJar;
	listFiles = listFiles;
};

do
	local configChunk = assert( loadfile( eihort.ProgramPath .. "eihort.config", nil, Config ) );
	local success = xpcall( configChunk, function( msg )
		eihort.errorDialog( LANG"ERR_Config", msg )
	end );
	if not success then
		return 1;
	end
	
	local function tryLoadConfig( path, filename )
		if not path or not filename then
			return;
		end
		local configFile = path .. filename;
		local f = io.open( configFile );
		if not f then
			return;
		end
		f:close();
		local userConfigMeta = { __index = Config; };
		local userConfig = {};
		setmetatable( userConfig, userConfigMeta );
		local userChunk = assert( loadfile( configFile, nil, userConfig ) );
		--if we have a readable user config, load and merge it.
		if userChunk then
			success = xpcall( userChunk, function( msg )
				eihort.errorDialog( LANG( "ERR_Error_In", configFile ), msg )
			end );
			if success then
				--overwrite parts of the global config with the user config
				tableMerge( Config, userConfig );
			end
		end
	end

	--get XDG config directory or its default.
	local xdgConfig = os.getenv( "XDG_CONFIG_HOME" );
	if xdgConfig then
		tryLoadConfig( xdgConfig, "/eihort.config" );
	else
		tryLoadConfig( os.getenv( "HOME" ), "/.config/eihort.config" );
	end
	-- Win7 user config in %USERPROFILE% and %APPDATA%
	tryLoadConfig( os.getenv( "USERPROFILE" ), "/eihort.config" );
	tryLoadConfig( os.getenv( "APPDATA" ), "/eihort.config" );

	local workerCount = Config.worker_threads or 0;
	if workerCount == 0 then
		workerCount = eihort.getProcessorCount();
	end
	eihort.initWorkers( workerCount );
end

------------------------------------------------------------------------------
-- Initialize low-level systems

require "lang"
InitLocalization( Config.language );

-- Load remaining lua scripts after localization has been started so LANG is available
require "assets"
require "mapview"
require "worldmenu"

if Config.asset_search_paths then
	initializeAssetIndex( Config.asset_search_paths );
end

------------------------------------------------------------------------------
-- Use dev tools (needs to be extended)

if Config.deveoper_tools and Config.print_found_versions then
	PrintVersionsList();
end

------------------------------------------------------------------------------
-- World loading function

function loadWorld( path )
	local levelDatPath = path .. "/level.dat";
	local f = io.open( levelDatPath, "rb" );
	if f then
		f:close();
		local oName, dat = eihort.loadNBT( levelDatPath );
		if dat then
			local levelData = dat:get("Data");
			if levelData then
				local version = levelData:get("version");
				local name = levelData:get("LevelName");
				return eihort.loadWorld( path, version == 0x4abd ), name;
			end
			dat:destroy();
		end
	end
end

------------------------------------------------------------------------------
-- Process the command line

local argv = { ... };
local argSettings = { };

local startWorld, startWorldName;

-- Add value to settings table
local function addArgToList ( setting, value )
	if tonumber( value ) then
		argSettings[setting] = tonumber( value );
		ProgramState.useCmdArgs = true;
	end
end

if #argv > 0 then
	-- Check for setting and fill setting table
	for key, val in ipairs ( argv ) do		
		if val == "-w" or val == "-world" then -- set world path
			if argv[key + 1] then
				argSettings.worldPath = argv[key + 1];
				ProgramState.useCmdArgs = true;
			end
		elseif val == "-x" or val == "-eyeX" then -- set eyeX
			addArgToList( "eyeX", argv[key + 1] );
		elseif val == "-y" or val == "-eyeY" then -- set eyeY
			addArgToList( "eyeY", argv[key + 1] );
		elseif val == "-z" or val == "-eyeZ" then -- set eyeZ
			addArgToList( "eyeZ", argv[key + 1] );
		elseif val == "-d" or val == "-dim"  or val == "-dimension" then -- set target dimension
			if tonumber( argv[key + 1] ) then
				if tonumber( argv[key + 1] ) >= -1 and tonumber( argv[key + 1] ) <= 1 then 
					addArgToList( "dim", tonumber( argv[key + 1] ) );
				end
			elseif argv[key + 1] == "overworld" or argv[key + 1] == "o" then
				addArgToList( "dim", 0 );
			elseif argv[key + 1] == "nether" or argv[key + 1] == "n" then
				addArgToList( "dim", -1 );
			elseif argv[key + 1] == "end"  or argv[key + 1] == "e" then
				addArgToList( "dim", 1 );
			end
		elseif val == "-t" or val == "-time" then -- set time
			addArgToList( "worldTime", argv[key + 1] );
		elseif val == "-p" or val == "-pitch" then
			addArgToList( "pitch", argv[key + 1] );
		elseif val == "-a" or val == "-azi" or val == "-azimuth" then -- set azimuth
			addArgToList( "azimuth", argv[key + 1] );
		elseif val == "-v" or val == "-vd" or val == "-viewDistance" then -- set pitch
			if tonumber( argv[key + 1] ) and tonumber( argv[key + 1] ) > 0 then
				addArgToList( "viewDistance", argv[key + 1] );
			end
		elseif val == "-vram" then -- set VRAM (to set the error message if eihort can't find the VRAM)
			if tonumber( argv[key + 1] ) then
				Config.max_gpu_mem = argv[key + 1];
			end
		else
			if key == 1 then -- set world path if somebody is not using -w /world/to/path
				argSettings.worldPath = val;
			end
		end
	end
	
	startWorld, startWorldName = loadWorld( argSettings.worldPath );
	if not startWorld or startWorld:getRegionCount() == 0 then
		eihort.errorDialog( LANG"ERR_Error", LANG( "ERR_No_Regions", argSettings.worldPath ) );
		return 1;
	end
end

------------------------------------------------------------------------------
-- Initialize video

ScreenWidth = Config.screenwidth or 800;
ScreenHeight = Config.screenheight or 600;
ScreenAspect = ScreenWidth / ScreenHeight;
assert( eihort.initializeVideo( ScreenWidth, ScreenHeight, Config.fullscreen, Config.multisample or 0 ) );

if startWorld then
	-- World loaded - enter the main map view
	beginMapView( startWorld, startWorldName, argSettings );
else
	-- Show the world selection menu first
	beginWorldMenu();
end

------------------------------------------------------------------------------
-- Error trap

while true do
	local success, ret = xpcall( main, function( ... ) return Event.error( ... ); end );
	if success then
		-- The return value of this function is the return value of eihort.exe
		return ret;
	end
end


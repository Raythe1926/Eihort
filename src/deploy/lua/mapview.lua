
-- Somewhat bloated module which handles Eihort when it is rendering a world


require "ui"
require "blockids"
require "biomes"
require "spline"
require "assets"
require "lang"

------------------------------------------------------------------------------
-- Constants

-- Colors applied to block faces at different times of day
local sunLightColor = { 0.99, 0.99, 0.99 };
local endLightColor = { 61/255, 76/255, 68/255 };
local moonLightColor = { 59/255, 53/255, 78/255 };
local dawnDuskGlowColor = { 0.5*0x9b/255, 0.5*0x40/255, 0.5*0x16/255 };
local blockLightColor = { 1.7, 1.39, 1 };

-- Block highlights
local blockHighlights = {
	--{ "name", id1, id2, ... }
	{ LANG"HL_Clay", 82 };
	{ LANG"HL_Coal_Ore", 16 };
	{ LANG"HL_Bone_Block", 216 };
	{ LANG"HL_Iron_Ore", 15 };
	{ LANG"HL_Moss_Stone", 48 };
	{ LANG"HL_Gold_Ore", 14 };
	{ LANG"HL_Chests", 54, 95 };
	{ LANG"HL_Lapis_Lazuli_Ore", 21 };
	{ LANG"HL_Rails", 66, 27, 28, 157 };
	{ LANG"HL_Redstone_Ore", 73, 74 };
	{ LANG"HL_Redstone_Wire", 55 };
	{ LANG"HL_Diamond_Ore", 56 };
	{ LANG"HL_Spawner", 52 };
	{ LANG"HL_Emerald_Ore", 129 };
	{ LANG"HL_Portal", 90, 119 };
	{ LANG"HL_Lava", 11 };
};

------------------------------------------------------------------------------
-- Helper functions

-- Tranform time: minecraft <-> eihort
local function TransformTimeZone ( target, startTime )
	if target == "eihort" then
		startTime = (startTime-6000)/12000;
		if startTime > 1 then
			startTime = startTime - 2;
		end
		
		return startTime;
	end
end

-- Transform view direction: minecraft <-> eihort
local function TransformViewDirection ( angleType, target, startAngle )
	-- angleType is either "pitch" or "azimuth"
	-- target is either "eihort" or "minecraft"
	
	local returnAngle;
	
	if angleType == "pitch" then
		if target == "eihort" then
			returnAngle = -math.rad( startAngle )
		elseif target == "minecraft" then
			returnAngle = -math.deg( startAngle );
		end
	elseif angleType == "azimuth" then
		if target == "eihort" then
			returnAngle = math.rad( math.fmod( -startAngle + 90, 360 ) - 180 );
		elseif target == "minecraft" then
			returnAngle = math.fmod( -math.deg( startAngle ) + 90, 360 ) - 180;
			if returnAngle < -180 then
				returnAngle = 360 + returnAngle;
			end
		end
	end
	
	return returnAngle;
end

-- Take a screenshot
local function takeScreenshotNow( worldName )
	
	-- Find savepath for screenshots
	local name = Config.screenshot_path;
	local fnroot, dPos, cChar, osDate;
	
	if name then
		cChar = string.len ( name );
		while cChar > 0 do
			if string.sub( name, cChar, cChar ) ~= "\\" and string.sub( name, cChar, cChar ) ~= "/" then
				cChar = cChar - 1;
			else
				dPos = cChar + 1;
				break;
			end
		end

		-- strip worldName of color codes & special characters
		worldName = string.gsub( worldName, '\xc2\xa7.', '' );
		worldName = string.gsub( worldName, '[^ -\x7e]', '_' );

		name = string.gsub( name, "%%(.)", {O=worldName} );
		osDate = os.date ( string.sub( name, dPos, string.len ( name ) ) );
	
		fnroot = string.sub( name, 1, cChar) .. osDate;
		local path = string.match( fnroot, "^(.*[/\\])[^/\\]*$" );
		if path then
			eihort.createDirectory( path );
		end
	else
		fnroot = os.date( eihort.output_path .. "eihort-%Y.%m.%d-%H.%M.%S" );
	end

	-- Try to open the file to see if it's already there
	local fn = fnroot .. ".png";
	local f = io.open( fn );
	local i = 0;
	while f do
		f:close();
		fn = fnroot .. "-" .. i .. ".png"; -- Add numbers to the end until the filename is unique
		i = i + 1;
		f = io.open( fn );
	end
	
	-- Grab the screen and dump it out to the file
	local screen = eihort.screengrab();
	local success, msg = screen:writePNG( fn );
	if not success then
		eihort.errorDialog( LANG"ERR_Screenshot_Failed", msg );
	end
end

-- Tries to figure out how much VRAM is available and sets the view allowance
local function setGpuAllowance( view )
	local allowance = Config.max_gpu_mem or 0;
	if allowance == 0 then
		allowance = eihort.getVideoMem();
		if not allowance or allowance == 0 then
			eihort.errorDialog( LANG"ERR_VRAM_Warn_Title", string.gsub( LANG"ERR_VRAM_Warn", "%$%$", ProgramState.defaultVRAM ) );
			ProgramState.noDetectedVram = true;
			allowance = ProgramState.defaultVRAM*1024*1024;
		end
		allowance = allowance * 0.9;
	else
		allowance = allowance * 1024 * 1024;
	end
		
	view:setGpuAllowance( allowance );
	
end

-- Modifies the spawn position in the world's level.dat
local function moveSpawnHere( worldPath, dim, x, y, z )	
	-- Only world in the overworld
	if dim ~= 0 then
		eihort.errorDialog( LANG"EO_Move_Spawn", LANG"ERR_Overworld_Only" );
		return;
	end

	-- Load level.dat
	local levelDatPath = worldPath .. "level.dat";
	local rootName, levelDat = eihort.loadNBT( levelDatPath );
	if not levelDat then
		eihort.errorDialog( LANG"EO_Move_Spawn", LANG( "ERR_Failed_Open", "level.dat" ) );
		return;
	end

	local levelData = levelDat:get("Data");
	if not levelData then
		eihort.errorDialog( LANG"EO_Move_Spawn", LANG"ERR_Corrupted_World" );
		return;
	end

	-- Set the spawn position
	levelData:set( "SpawnX", x, "int" );
	levelData:set( "SpawnY", y, "int" );
	levelData:set( "SpawnZ", z, "int" );

	-- Save level.dat
	levelDat:write( levelDatPath, rootName );
	levelDat:destroy();
end

-- Modifies the player's position in the world's level.dat
local function movePlayerHere( worldPath, dim, x, y, z, az, pit )
	
	-- Load the level.dat
	local levelDatPath = worldPath .. "level.dat";
	local rootName, levelDat = eihort.loadNBT( levelDatPath );
	if not levelDat then
		eihort.errorDialog( LANG"EO_Move_Player", LANG( "ERR_Failed_Open", "level.dat" ) );
		return;
	end

	local levelData = levelDat:get("Data");
	if not levelData then
		eihort.errorDialog( LANG"EO_Move_Player", LANG"ERR_Corrupted_World" );
		return;
	end
	local player = levelData:get("Player");
	if not player then
		player = levelData:newCompound( "Player" );
	end

	-- Modify the position
	local pos = player:newList( "Pos", "double" );
	pos[1] = x;
	pos[2] = y-1.62;
	pos[3] = z;
	
	az = TransformViewDirection( "azimuth", "minecraft", az );
	pit = TransformViewDirection( "pitch", "minecraft", pit );
	
	local rot = player:newList( "Rotation", "float" );
	rot[1] = az;
	rot[2] = pit;
	
	player:set( "Dimension", dim, "int" );

	-- Write it back
	levelDat:write( levelDatPath, rootName );
	levelDat:destroy();
end

-- Determine the player's position from the level.dat
local function getPlayerPosition( worldPath )	
	local levelDatPath = worldPath .. "level.dat";
	local rootName, levelDat = eihort.loadNBT( levelDatPath );
	if levelDat then
		local levelData = levelDat:get("Data");
		if levelData then
			local player = levelData:get("Player");
			if player then
				local pos = player:get("Pos") or {};
				local rot = player:get("Rotation") or {};
				local dim = player:get("Dimension");
				local x, y, z, az, pitch = pos[1] or 0, pos[2] or 128, pos[3] or 0, rot[1] or 0, rot[2] or 0;
				levelDat:destroy();
				return x, y+1.62, z, TransformViewDirection( "azimuth", "eihort", az ), TransformViewDirection( "pitch", "eihort", pitch ), dim or 0;
			end
		end
	end
	levelDat:destroy();
	return 0, 128, 0, 0, 0, 0;
end

-- Determine the world spawn position from the level.dat
local function GetWorldSpawnPosition( worldPath )	
	local levelDatPath = worldPath .. "level.dat";
	local rootName, levelDat = eihort.loadNBT( levelDatPath );
	
	if levelDat then
		local levelData = levelDat:get("Data");
		if levelData then
			local spawnX = levelData:get("SpawnX") or   0;
			local spawnY = levelData:get("SpawnY") or 128;
			local spawnZ = levelData:get("SpawnZ") or   0;
			levelDat:destroy();
			return spawnX, spawnY, spawnZ;
		end
	end
	levelDat:destroy();
	return 0, 128, 0; -- No Data information found
end

-- Get time from MC world
local function GetWorldTime( worldPath )
	local mcTime, worldTime;
	
	if Config.use_world_time then
		local levelDatPath = worldPath .. "level.dat";
		local rootName, levelDat = eihort.loadNBT( levelDatPath );
		
		if levelDat then
			local levelData = levelDat:get("Data");
			mcTime = levelData:get("DayTime");
			worldTime = TransformTimeZone ( "eihort", mcTime );
			levelDat:destroy();
		end
	else
		worldTime = Config.start_time or 0;
	end
	
	return worldTime;
end

-- Add shortcut button tooltips
local function ShortcutButtonTooltip( shortcutName, buttonTable )
	local output = LANG"EO_Shortcut" .. ": ";
	local usedButtons = { };
	
	for buttonNr, button in ipairs( buttonTable ) do
		for key, action in pairs( Config.keys ) do
			if action == button then
				if not usedButtons[button] then
					output = output .. string.upper( key );
					usedButtons[button] = true;
				else
					output = output .. " / " .. string.upper( key );
				end	
			end
		end
		if buttonTable[buttonNr+1] then
			output = output .. " + ";
		end
	end
	
	return output;	
end

------------------------------------------------------------------------------
-- Lighting

local function updateLightModels_netherend( worldView, sky, worldTime, dark )
	-- Lighting models for the nether and the end
	local sr, sg, sb = unpack( endLightColor );
	sky:setTime( 0 );

	local function setLightModel( dir, pct )
		local model = worldView:getLightModel(dir);
		model:setSky( pct*sr, pct*sg, pct*sb, 0 );
		model:setDark( dark, dark, dark );
		model:setBlock( unpack( blockLightColor ) );
	end

	-- Z- (west), Z+ (east)
	setLightModel( 2, 0.8 );
	setLightModel( 3, 0.8 );
	-- X- (north), X+ (south)
	setLightModel( 0, 0.8^2 );
	setLightModel( 1, 0.8^2 );
	-- Y- (down)
	setLightModel( 4, 0.8^3 );
	-- Y+ (up)
	setLightModel( 5, 1 );
end

local function updateLightModels_overworld( worldView, sky, worldTime, dark )
	-- Lighting models for the overworld
	
	local mr, mg, mb = unpack( moonLightColor );
	local sr, sg, sb = unpack( sunLightColor );
	local gr, gg, gb = unpack( dawnDuskGlowColor );
	sky:setTime( worldTime );

	local function getStr( angle )
		-- Returns the "strength" of light coming from the given angle
		-- on normal faces, west-facing faces, and east-facing faces
		angle = math.fmod( angle + math.pi, math.pi*2 ) - math.pi;
		local str = math.min( 1, math.max( 0, math.cos( angle ) * 0.8 + 0.2 ) ) ^ 0.8;
		local mask = str ^ 0.8;
		local wStr = math.min( 1, math.max( 0, math.cos( (angle - math.pi/2)*0.9 ) * 0.4 + 0.6 ) ) * mask;
		local eStr = math.min( 1, math.max( 0, math.cos( (angle + math.pi/2)*0.9 ) * 0.4 + 0.6 ) ) * mask;
		return str, wStr, eStr;
	end

	-- Get the strength of the light coming from the sun/moon
	local sunAngle = math.pi * worldTime;
	local sunStr, wSunStr, eSunStr = getStr( sunAngle );
	local moonStr, wMoonStr, eMoonStr = getStr( sunAngle + math.pi );
	
	-- Glow factors for dawn/dusk
	local wGlow = math.max( 0, math.sin( sunAngle ) ^ 3 - 0.05 );
	local eGlow = math.max( 0, -math.sin( sunAngle ) ^ 3 - 0.05 );
	local oGlow = (wGlow+eGlow)*0.8;

	local function setLightModel( dir, sun, moon, glow )
		local model = worldView:getLightModel(dir);
		model:setSky( sun*sr + moon*mr + glow*gr, sun*sg + moon*mg + glow*gg, sun*sb + moon*mb + glow*gb, sunStr*1.2 );
		model:setDark( dark, dark, dark );
		model:setBlock( unpack( blockLightColor ) );
	end
	-- Z- (west), Z+ (east)
	setLightModel( 2, wSunStr, wMoonStr, wGlow );
	setLightModel( 3, eSunStr, eMoonStr, eGlow );
	-- X- (north), X+ (south)
	setLightModel( 0, sunStr*0.8^2, moonStr*0.8^2, 0 );
	setLightModel( 1, sunStr*0.8^2, moonStr*0.8^2, 0 );
	-- Y- (down)
	setLightModel( 4, sunStr*0.8^3, moonStr*0.8^3, 0 );
	-- Y+ (up)
	setLightModel( 5, sunStr, moonStr, 0 );
end

local function createOverworldSky()
	-- Loads the sky for the overworld
	
	local sky = eihort.newSky();
	local sun = loadTexture( "assets/minecraft/textures/environment/sun.png", 1, 1 ):uploadToGL( 'mag_nearest', 'min_nearest', 'mip_none' );
	local moonImage = loadTexture( "assets/minecraft/textures/environment/moon_phases.png", 1, 1 );
	local moon = moonImage:sub( 0, 0, moonImage.width/4, moonImage.height/2 ):uploadToGL( 'mag_nearest', 'min_nearest', 'mip_none' );
	sky:setSunMoon( sun, moon );

	local function setMoonPhase( phase )
		phase = math.floor( math.fmod( phase, 8 ) );
		phaseImg = moonImage:sub( (phase - math.floor(phase/4)*4) * moonImage.width/4, math.floor(phase/4)*moonImage.height/2, moonImage.width/4, moonImage.height/2 );
		phaseImg:uploadToGL( moon, 'mag_nearest', 'min_nearest', 'mip_none' );
		phaseImg:destroy();
	end
	return sky, setMoonPhase;
end

local function createNetherEndSky()
	-- Loads a blank sky for the Nether/End
	
	local sky = eihort.newSky();
	sky:setColors( 0, 0, 0, 0, 0, 0 );
	return sky;
end

------------------------------------------------------------------------------
-- Main Map View

function beginMapView( world, worldName, argsTable )
	-- Create the main worldView object which will be doing the rendering
	local worldPath = world:getRootPath();
	local blocks = loadBlockDesc();
	loadBiomeTextures( blocks, world:getRootPath() );
	local worldView = world:createView( blocks, Config.qtree_leaf_size or 7, getBiomeCoordData() );
	setGpuAllowance( worldView );
	
	-- Load the skies
	local owSky, setMoonPhase = createOverworldSky();
	local neSky = createNetherEndSky();
	local drawSky, updateLightModels, sky;
	local moonPhase = 0;

	-- Mouse controls
	local mouseX, mouseY = eihort.getMousePos();
	local ignoreNextMM = false;
	local mouseLook = false;
	local controlsOn = 0;
	eihort.showCursor( true );

	-- World view parameters
	local worldTime = GetWorldTime( worldPath );
	local viewDistance = Config.start_view_distance or 500;
	local light0, lightStr = 0.05, LANG"INFO_LS_Overworld";
	local takeScreenshot = false;
	local speedModifier = 1;
	local inDim = -666;
	local monitorEnabled = false;

	-- Camera position and parameters
	local pitch, azimuth;
	local eyeX, eyeY, eyeZ, fwdX, fwdY, fwdZ, upX, upY, upZ, rightX, rightY, rightZ;
	local fov = (Config.fov or 75) * math.pi / 180;
	local nearPlane = 0.1;

	-- UI
	local showUI, uiRoot = true, ui.newRoot();
	local infoDisplay = ui.newLabel( "", 0.03, 0.02, 0, 0, 1, 1 );

	-- Flag to force a redraw on the next frame
	local redrawNextFrame = true;

	-- Spline
	local splinet, splinedt = 0, 0;
	local lastSplineAz = 0;
	local splines = {
		x = NewSpline();
		y = NewSpline();
		z = NewSpline();
		azimuth = NewSpline();
		pitch = NewSpline();
	};
	
	-- Helper to execute functions when nothing is loading
	local execNoLoad = { };
	local function execWhenNothingIsLoading( what, a, b, c, d )
		table.insert( execNoLoad, function() what( a, b, c, d ); end );
		worldView:pauseLoading( true );
	end

	-- Helper to update the camera based on the azimuth and pitch
	local function refreshPosition()
		fwdX, fwdY, fwdZ, upX, upY, upZ, rightX, rightY, rightZ = eihort.fwdUpRightFromAzPitch( azimuth, pitch );
		worldView:setPosition( eyeX, eyeY, eyeZ, fwdX, fwdY, fwdZ, upX, upY, upZ );
		redrawNextFrame = true;
	end
	
	-- Sets the camera parameters
	local function resetCameraParams()
		worldView:setCameraParams( fov, ScreenWidth / ScreenHeight, nearPlane, viewDistance * 1.05 );
	end

	-- Update camera properties from the spline
	local function resolveSplinePos()
		if splines.x.n == 0 then
			return;
		end
		eyeX, eyeY, eyeZ = splines.x:evaluate( splinet ), splines.y:evaluate( splinet ), splines.z:evaluate( splinet );
		azimuth = math.fmod( splines.azimuth:evaluate( splinet ) + math.pi, math.pi*2 ) - math.pi;
		pitch = splines.pitch:evaluate( splinet );
	end
	
	-- Calculate Chunk position in region file
	local function PosInChunkLocal()
		local coords = { eyeX, eyeZ };
		
		for nr, _ in ipairs(coords) do
			if coords[nr] > 0 then
				while ( coords[nr] - 512 ) > 0 do
					coords[nr] = coords[nr] - 512;
				end
			else
				while coords[nr] < 0 do
					coords[nr] = coords[nr] + 512;
				end
			end
			coords[nr] = math.floor( coords[nr] / 16 );
		end
		
		return " || " .. tostring( coords[1] ) .. "/" .. tostring( coords[2] ) .. " (" .. string.lower( LANG"INFO_Region_File" ) .. ")";
	end
	
	-- Calculate pitch data (info screen)
	function CalcPitchData ( pit )
		local output;
		
		output = TransformViewDirection( "pitch", "minecraft", pit );
		
		if output > 0 then
			if output >= 10 then
				return " " .. string.format( "%.1f", output );
			else
				return "  " .. string.format( "%.1f", output );
			end
		else
			if output >= -10 then
				return " " .. string.format( "%.1f", output );
			else
				return string.format( "%.1f", output );
			end
		end
	end
	
	-- Calculate azimuth data (info screen)
	function CalcAzimuthData ( az )
		local output, cardialDirection, temp, stringlen;
		
		-- Calculate azimuth
		output = math.fmod( -math.deg( az ) + 90, 360) -180;
		cardialDirection = -output;
		
		if output < -180  then
			output = output + 360;
		end
		
		-- Calculate cardinal direction
		if cardialDirection < 0 then
			cardialDirection = cardialDirection + 360;
		end
		
		if cardialDirection >= 337.5 or cardialDirection < 22.5 then
			cardialDirection = LANG"INFO_South";
		elseif cardialDirection >= 22.5 and cardialDirection < 67.5 then
			cardialDirection = LANG"INFO_SouthEast";
		elseif cardialDirection >= 67.5 and cardialDirection < 112.5 then
			cardialDirection = LANG"INFO_East";
		elseif cardialDirection >= 112.5 and cardialDirection < 157.5 then
			cardialDirection = LANG"INFO_NorthEast";
		elseif cardialDirection >= 157.5 and cardialDirection < 202.5 then
			cardialDirection = LANG"INFO_North";
		elseif cardialDirection >= 202.5 and cardialDirection < 247.5 then
			cardialDirection = LANG"INFO_NorthWest";
		elseif cardialDirection >= 247.5 and cardialDirection < 292.5 then
			cardialDirection = LANG"INFO_West";
		elseif cardialDirection >= 292.5 and cardialDirection < 337.5 then
			cardialDirection = LANG"INFO_SouthWest";
		else
			cardialDirection = LANG"INFO_Unknown_Direction";
		end
		
		temp = "";
		stringlen = string.len( string.format( "%.1f", output ) );
		for i = stringlen, 5 do
			temp = temp .. " "
		end
		
		cardialDirection = temp .. " (" .. cardialDirection .. ")";
		
		return string.format( "%.1f", output ) .. cardialDirection;
	end
	
	-- Info display
	local infoformat = string.format( "%s: (%%.0f %%.0f %%.0f)\n%%s%%s%%s%%s%%s%s\n\n%s: %%s\n%s: %%.0f:%%02.0f\n%s: %%.0f%%s",
		LANG"INFO_Coords", LANG"INFO_Config", LANG"INFO_Light_Strength",
		LANG"INFO_Time", LANG"INFO_View_Distance" );
	local function refreshInfoDisplay()
		local triCount, vtxMem, idxMem, texMem = worldView:getLastFrameStats();
		infoDisplay.text = string.format( infoformat,
			eyeX, eyeY, eyeZ,
			(Config.show_region_file and (LANG"INFO_Region_File" .. ": r." .. math.floor(eyeX/(32*16)) .. "." .. math.floor(eyeZ/(32*16)) .. "\n")) or "",
			(Config.show_global_chunk and (LANG"INFO_In_Chunk" .. ": " .. math.floor(eyeX/16) .. "/" .. math.floor(eyeY/16) .. "/" .. math.floor(eyeZ/16) .. " (" .. string.lower(LANG"INFO_In_Chunk_Global") .. ")" .. (Config.show_region_chunk and PosInChunkLocal() or "") .. "\n")) or "",
			(Config.show_view_angles and (LANG"INFO_Pitch" .. ": " .. CalcPitchData(pitch) .. " || " .. LANG"INFO_Azimuth" .. ": " .. CalcAzimuthData(azimuth) .. "\n")) or "",
			(Config.show_triangles and (LANG"INFO_Triangles" .. ": " .. triCount .. "\n")) or "",
			(Config.show_vram_use and string.format( "%s: %.0f %s (%.0f %s)\n", 
				LANG"INFO_Mem",
			    (vtxMem + idxMem + texMem) / (1024*1024), LANG"INFO_MB",
			    worldView:getGpuAllowanceLeft() / (1024*1024), LANG"INFO_Mem_Free" )) or "",
			lightStr,
			math.floor( worldTime * 12 + 12 ), math.floor( math.fmod( worldTime * 12 + 12, 1 ) * 60 ),
			viewDistance,
			(monitorEnabled and "\n" .. LANG"INFO_Monitor") or "" );
	end
	
	-- Move the player to another dimension
	local function moveToDim( dim )
		-- Nether/Overworld/End switching
		if inDim ~= dim then
			if dim == -1 then
				-- To nether
				eyeX = eyeX / 8;
				eyeZ = eyeZ / 8;
			elseif inDim == -1 then
				-- From nether
				eyeX = eyeX * 8;
				eyeZ = eyeZ * 8;
			end
			refreshPosition();
			if dim == 0 then
				-- Change the lighting to the overworld lighting
				world:changeRootPath( worldPath );
				light0 = 0.8^15;
				lightStr = LANG"INFO_LS_Overworld";
				updateLightModels = updateLightModels_overworld;
				sky = owSky;
				blocks:setDefAirSkylight( 15 );
			else
				-- Change the lighting to the Nether/End lighting
				world:changeRootPath( worldPath .. "DIM" .. dim .. "/" );
				light0 = 0.9^15;
				lightStr = LANG"INFO_LS_Nether_End";
				updateLightModels = updateLightModels_netherend;
				sky = neSky;
				if dim == 1 then
					blocks:setDefAirSkylight( 15, true );
				else
					blocks:setDefAirSkylight( 0 );
				end
			end
			updateLightModels( worldView, sky, worldTime, light0 );

			worldView:reloadAll();
			inDim = dim;
		end
	end
	
	-- Move the camera back to the player's position
	local function resetPositionToPlayer()
		local x, y, z, yaw, pit, dim = getPlayerPosition( worldPath );
		local movePlayer = true;
		
		-- Toggle button functionality
		if not Config.buttonUseIsToggled then -- Key is NOT pressed
			azimuth, pitch = yaw, pit;
			eyeX, eyeY, eyeZ = x, y, z;
			moveToDim( dim );
			eyeX, eyeY, eyeZ = x, y, z;
			refreshPosition();
		else -- Key is pressed
			if Config.confirmToggledButtonUse and Config.confirmToggledButtonUseForMovedPlayer then
				movePlayer = eihort.errorDialogYesNo( LANG"EO_Move_Player", LANG"EO_Move_Player_Question" );
			end
			if movePlayer then
				movePlayerHere( worldPath, inDim, eyeX, eyeY, eyeZ, azimuth, pitch );
			end
		end
	end
	
	-- Move the camera back to the world spawn position
	local function ResetPositionToSpawn()
		local x, y, z = GetWorldSpawnPosition( worldPath );
		local moveSpawn = true;
		
		-- Toggle button functionality
		if not Config.buttonUseIsToggled then -- Key is NOT pressed
			moveToDim( 0 );
			azimuth, pitch = math.pi/2, 0;
			eyeX, eyeY, eyeZ = x, y, z;
			
			refreshPosition();
		else -- Key is pressed
			if Config.confirmToggledButtonUse and Config.confirmToggledButtonUseForMovedSpawn then
				moveSpawn = eihort.errorDialogYesNo( LANG"EO_Move_Spawn", LANG"EO_Move_Spawn_Question" );
			end
			if moveSpawn then
				moveSpawnHere( worldPath, inDim, eyeX, eyeY, eyeZ );
			end
		end
	end
	
	-- Move the camera back to the position in the config
	local function resetPosition()
		eyeX, eyeY, eyeZ = Config.origin_x or 0, Config.origin_y or 0, Config.origin_z or 0;
		azimuth = Config.origin_azimuth or 0;
		pitch = Config.origin_pitch or 0;
		refreshPosition();
	end
	
	-- Use cmd args instead of level.dat data
	local function OverwriteWithCmdArgs ( )
		if ProgramState.useCmdArgs then
			-- in pairs with key = value does not work - see also http://lua-users.org/lists/lua-l/2013-03/msg00899.html
			if argsTable then
				if argsTable.eyeX then
					eyeX = argsTable.eyeX;
				end
				if argsTable.eyeY then
					eyeY = argsTable.eyeY;
				end
				if argsTable.eyeZ then
					eyeZ = argsTable.eyeZ;
				end
				if argsTable.pitch then
					pitch = TransformViewDirection( "pitch", "eihort", argsTable.pitch );
				end
				if argsTable.azimuth then
					azimuth = TransformViewDirection( "azimuth", "eihort", argsTable.azimuth );
				end
				if argsTable.dim then
					moveToDim( argsTable.dim );
				end
				if argsTable.worldTime then
					worldTime = TransformTimeZone ( "eihort", argsTable.worldTime );
				end
				if argsTable.viewDistance then
					viewDistance = argsTable.viewDistance;
				end
				
				refreshPosition();	
			end
		end
	end

	-- Set up initial parameters
	resetPositionToPlayer();
	OverwriteWithCmdArgs();
	refreshInfoDisplay();
	resetCameraParams();
	worldView:setViewDistance( viewDistance );
	updateLightModels( worldView, sky, worldTime, light0 );
	
	-- Clear current event handlers
	EventDownAction = { };
	EventUpAction = { };

	-------------------------------------------------------------------
	-- Available impulse actions

	local impulseActions = {
		-- Reload the entire world
		reloadworld = function()
			worldView:reloadAll();
		end;
		
		-- Turn the file change monitor on/off
		togglemonitor = function()
			monitorEnabled = not monitorEnabled;
			world:setMonitorState( monitorEnabled );
			redrawNextFrame = true;
		end;
		
		-- Change the lighting mode
		changelightmode = function()
			if light0 < 0.1 then
				light0 = 0.9^15;
				lightStr = LANG"INFO_LS_Nether_End";
			elseif light0 < 0.95 then
				light0 = 1.0;
				lightStr = LANG"INFO_LS_Fullbright";
			else
				light0 = 0.8^15;
				lightStr = LANG"INFO_LS_Overworld";
			end
			updateLightModels( worldView, sky, worldTime, light0 );
			redrawNextFrame = true;
		end;
		
		-- Change the phase of the moon
		changemoonphase = function()
			moonPhase = moonPhase + 1;
			setMoonPhase( moonPhase );
			redrawNextFrame = true;
		end;
		
		-- Reset the camera position
		resetposition = resetPosition;
		
		-- Move the camera to the player position
		playerposition = resetPositionToPlayer;
		
		-- Move the camera to the world position
		spawnposition = ResetPositionToSpawn;
		
		-- Show/hide the UI
		toggleui = function()
			showUI = not showUI;
			if showUI then
				uiRoot:mouseEnter( mouseX / ScreenWidth, mouseY / ScreenHeight );
			else
				uiRoot:mouseLeave();
			end
		end;
		
		-- Take a screenshot
		screenshot = function()
			takeScreenshot = true;
			redrawNextFrame = true;
		end;
		
		-- Toggle screen info visibility
		screeninfo = function()
			local keys = { "show_triangles", "show_vram_use", "show_region_file", "show_region_chunk", "show_global_chunk", "show_view_angles" };
			
			-- Save orig configs to table
			if not Config.origConfig then
				Config.origConfig = { };
				
				for key, value in ipairs( keys ) do
					Config["origConfig"][value] = Config[value];
				end
			end
			
			if not Config.showF3Info then
				Config.showF3Info = false;
			end
			
			if Config.showF3Info == true then
				for key, value in ipairs( keys ) do
					Config[value] = Config["origConfig"][value];
				end
				Config.showF3Info = false;
			elseif Config.showF3Info == false then
				for key, value in ipairs( keys ) do
					Config[value] = true;
				end
				Config.showF3Info = true;
			end
		end;
		
		-- Allow the mouse to move freely
		freemouse = function()
			if mouseLook then
				mouseLook = false;
				eihort.showCursor( true );
				if showUI then
					uiRoot:mouseEnter( mouseX / ScreenWidth, mouseY / ScreenHeight );
				end
			end
		end;
		
		-- Speed up all operations
		speedup = { function() speedModifier = Config.speedup_modifier or 8; end;
		            function() speedModifier = 1; end };
		
		-- Slow down all operations
		slowdown = { function() speedModifier = Config.slowdown_modifier or 1/8; end;
		             function() speedModifier = 1; end };
		
		-- Toggle button effects
		togglebuttonuse = { function() Config.buttonUseIsToggled = true; end;
							function() Config.buttonUseIsToggled = false; end };
		
		-- Add a control point to the spline
	    splineadd = function()
			splines.x:addPt( eyeX );
			splines.y:addPt( eyeY );
			splines.z:addPt( eyeZ );
			local tau = 2 * math.pi;
			local taubase = tau * math.floor( lastSplineAz / tau );
			local az = taubase + azimuth;
			if math.abs( az - lastSplineAz ) > math.pi then
				if az < lastSplineAz then
					az = az + tau;
				else
					az = az - tau;
				end
			end
			lastSplineAz = az;
			splines.azimuth:addPt( az );
			splines.pitch:addPt( pitch );
		end;
		-- Move to the spline's start
		splinestart = function()
			splinet = 0;
			resolveSplinePos();
			refreshPosition();
		end;
		-- Move to the spline's end
		splineend = function()
			splinet = splines.x.n-1;
			resolveSplinePos();
			refreshPosition();
		end;
		-- Erase the entire spline
		splineerase = function()
			splinet = 0;
			for k, _ in pairs( splines ) do
				splines[k] = NewSpline();
			end
		end;
		-- Pop the last point off the spline
		splinepop = function()
			for _, v in pairs( splines ) do
				v:pop();
			end
			splinet = splines.x.n-1;
		end;
		
		-- Developer keys
		restarteihort = function()
			if Config.deveoper_tools and Config.enable_developer_keys and speedModifier ~= 1 then -- Requires pressed left or right Ctrl to work
				RestartEihort( worldPath, eyeX, eyeY, eyeZ, TransformViewDirection( "pitch", "minecraft", pitch ), TransformViewDirection ( "azimuth", "minecraft", azimuth ), inDim );
			end
		end;
	};

	-------------------------------------------------------------------
	-- Key binding setup
	
	local controls = {
		moveforward = 0;
		moveback = 0;
		moveright = 0;
		moveleft = 0;
		moveup = 0;
		movedown = 0;
		['viewdist-'] = 0;
		['viewdist+'] = 0;
		['time-'] = 0;
		['time+'] = 0;
		['splinet+'] = 0;
		['splinet-'] = 0;
	};
	for k, v in pairs( Config.keys ) do
		local imp = impulseActions[v];
		k = string.lower( k );
		if imp then
			if type(imp) == "table" then
				EventDownAction[k] = imp[1];
				EventUpAction[k] = imp[2];
			else
				EventDownAction[k] = imp;
				EventUpAction[k] = nil;
			end
		elseif controls[v] then
			EventDownAction[k] = function()
				controlsOn = controlsOn + 1;
				controls[v] = controls[v] + 1;
			end;
			EventUpAction[k] = function()
				controlsOn = controlsOn - 1;
				controls[v] = controls[v] - 1;
			end;
		else
			error( LANG( "ERR_Unknown_Binding", v ) );
		end
	end

	-------------------------------------------------------------------
	-- Mouse stuff
	
	Event.mousemove = function( x, y )
		if ignoreNextMM then
			ignoreNextMM = false;
			return;
		end

		if mouseLook then
			-- Change the pitch/azimuth in response to mouse movement
			local dx = x - mouseX;
			local dy = y - mouseY;

			azimuth = azimuth - dx * ((Config.mouse_sensitivity_scale / 100) * Config.mouse_sensitivity_x or 0.008);
			pitch = pitch - dy * ((Config.mouse_sensitivity_scale / 100) * Config.mouse_sensitivity_y or 0.01);
			if azimuth > math.pi then
				azimuth = azimuth - 2 * math.pi;
			elseif azimuth < -math.pi then
				azimuth = azimuth + 2 * math.pi;
			end
			if pitch > math.pi / 2 then
				pitch = math.pi / 2;
			elseif pitch < -math.pi / 2 then
				pitch = -math.pi / 2;
			end

			refreshPosition();
			ignoreNextMM = true;
			eihort.warpMouse( mouseX, mouseY );
			return;
		end

		mouseX = x;
		mouseY = y;

		-- Update the UI
		if showUI then
			uiRoot:mouseMove( x / ScreenWidth, y / ScreenHeight );
		end
	end;
	EventDownAction.mouse1 = function()
		if not mouseLook then
			if not showUI or uiRoot:mouseDown( mouseX / ScreenWidth, mouseY / ScreenHeight ) == uiRoot then
				-- Clicked in the window, not on a UI element
				mouseLook = true;
				ignoreNextMM = true;
				mouseX, mouseY = math.floor( ScreenWidth / 2 ), math.floor( ScreenHeight / 2 );
				eihort.warpMouse( mouseX, mouseY );
				eihort.showCursor( false );
				if showUI then
					uiRoot:mouseLeave();
				end
			end
		end
	end;
	EventUpAction.mouse1 = function()
		if not mouseLook and showUI then
			uiRoot:mouseUp( mouseX / ScreenWidth, mouseY / ScreenHeight );
		end
	end;

	-------------------------------------------------------------------
	-- Main UI
	do
		-- "Extra Options" panel properties
		local panelW = 0.28;
		local panelR = 0.98;
		local panelX = panelR - panelW;
		local panelY = 0.1;
		local extraOptionsPanel = uiRoot:addComposite( 1, 0, 1, 1 );
		local devButtonsPanel = uiRoot:addComposite( 0, 0, 1, 1 );
		local fontHt = 0.03;
		local buttonHt = 0.035;
		local buttonSpace = buttonHt + 0.01;
		local y = panelY;

		-- Show Extra Options toggle
		uiRoot:addToggle(
			function() extraOptionsPanel.invisible = false; end, 
			function() extraOptionsPanel.invisible = true; end,
			LANG"EO_Button", fontHt*1.2, 0, panelX-0.1, 0.02, panelW+0.1, 0.05 );
		extraOptionsPanel.invisible = true;

		-- Select other world button
		local selectWorldButton = extraOptionsPanel:addButton(
			function() execWhenNothingIsLoading( function()
				worldView:destroy();
				world:destroy();
				blocks:destroy();
				beginWorldMenu( true );
			end ); end,
			LANG"EO_Select_World", fontHt, 0, panelX, y, panelW, buttonHt );
		y = y + buttonSpace;

		-- Move spawn button
		local moveSpawnButton = extraOptionsPanel:addButton(
			function() moveSpawnHere( worldPath, inDim, eyeX, eyeY, eyeZ ); end,
			LANG"EO_Move_Spawn", fontHt, 0, panelX, y, panelW, buttonHt );
		y = y + buttonSpace;
		if Config.showShortcutButtonTooltip and Config.showShortcutButtonTooltipForEOMenu then
			moveSpawnButton.tooltip = ShortcutButtonTooltip( "moveSpawnButton", { "togglebuttonuse", "spawnposition" } );
		end

		-- Move player button
		local movePlayerButton = extraOptionsPanel:addButton(
			function() movePlayerHere( worldPath, inDim, eyeX, eyeY, eyeZ, azimuth, pitch ); end,
			LANG"EO_Move_Player", fontHt, 0, panelX, y, panelW, buttonHt );
		y = y + buttonSpace;
		if Config.showShortcutButtonTooltip and Config.showShortcutButtonTooltipForEOMenu then
			movePlayerButton.tooltip = ShortcutButtonTooltip( "movePlayerButton", { "togglebuttonuse", "playerposition" } );
		end

		-- Dimension selection buttons
		local dimButtonW = (panelW - 2*(buttonSpace - buttonHt)) / 3;
		extraOptionsPanel:addButton(
			function() execWhenNothingIsLoading( moveToDim, -1 ); end,
			LANG"EO_Nether", fontHt, 0, panelX, y, dimButtonW, buttonHt );
		extraOptionsPanel:addButton(
			function() execWhenNothingIsLoading( moveToDim, 0 ); end,
			LANG"EO_Overworld", fontHt, 0, panelX+dimButtonW+buttonSpace-buttonHt, y, dimButtonW, buttonHt );
		extraOptionsPanel:addButton(
			function() execWhenNothingIsLoading( moveToDim, 1 ); end,
			LANG"EO_End", fontHt, 0, panelX+2*(dimButtonW+buttonSpace-buttonHt), y, dimButtonW, buttonHt );
		y = y + buttonSpace;

		-- No block lighting
		local function setNoBlockLighting( on )
			blocks:noBlockLighting( on );
			worldView:reloadAll();
		end
		local noBlockLighting = extraOptionsPanel:addToggle(
			function() execWhenNothingIsLoading( setNoBlockLighting, true ); end,
			function() execWhenNothingIsLoading( setNoBlockLighting, false ); end,
			LANG"EO_Block_Lighting", fontHt, 0, panelX, y, panelW, buttonHt );
		noBlockLighting.alt = LANG"EO_Block_Lighting_Alt";
		y = y + buttonSpace;

		-- Highlight buttons
		local hiliteW = (panelW + buttonHt - buttonSpace) / 2;
		local hiliteX2 = panelX + hiliteW + buttonSpace - buttonHt;
		local function addBlockHighlight( i, name, ... )
			local ids = { ... };
			local function changeHighlight( on )
				for _, id in ipairs( ids ) do
					blocks:setHighlight( id, on );
				end
				worldView:reloadAll();
			end
			local x = panelX;
			if math.fmod( i, 2 ) == 1 then
				x = hiliteX2;
			end

			extraOptionsPanel:addToggle(
				function() execWhenNothingIsLoading( changeHighlight, true ); end,
				function() execWhenNothingIsLoading( changeHighlight, false ); end,
				name, fontHt, 0, x, y, hiliteW, buttonHt );

			if math.fmod( i, 2 ) == 0 then
				y = y + buttonSpace;
			end
		end
		for i, v in ipairs( blockHighlights ) do
			addBlockHighlight( i, unpack( v ) );
		end
		if math.fmod( #blockHighlights, 2 ) == 1 then
			y = y + buttonSpace;
		end

		extraOptionsPanel.rect:setRect( panelX-0.01, panelY-0.01, panelW+0.02, y+buttonHt-buttonSpace-panelY+0.02 );
		
		-- Developer buttons
		if Config.deveoper_tools and Config.show_developer_buttons then
			local devButtonsLabel = devButtonsPanel:addLabel( LANG"DEV_Developer_Buttons", 0.035, 0, 0.028, 0.845, 0.15, 0.03 );
				devButtonsLabel.align = eihort.TextAlignLeft + eihort.TextAlignTop;
			local restartEihortButton = devButtonsPanel:addButton(
				function () RestartEihort( worldPath, eyeX, eyeY, eyeZ, TransformViewDirection( "pitch", "minecraft", pitch ), TransformViewDirection ( "azimuth", "minecraft", azimuth ), inDim ); end,
				LANG"DEV_Restart_Eihort", 0.03, 0, 0.028, 0.89, 0.15, 0.08 );
			if Config.showShortcutButtonTooltip and Config.showShortcutButtonTooltipForDevButtons then
				restartEihortButton.tooltip = ShortcutButtonTooltip( "restartEihortButton", { "slowdown", "restarteihort" } );
			end
		end

		-- Shrink panels to fit
		devButtonsPanel:shrinkToFit()
	end

	-------------------------------------------------------------------
	-- Screen stuff
	
	EventDownAction.mfocus = nil;
	EventUpAction.mfocus = function()
		if mouseLook then
			mouseLook = false;
			eihort.showCursor( true );
			if showUI then
				uiRoot:mouseEnter( mouseX / ScreenWidth, mouseY / ScreenHeight );
			end
		end
	end;
	Event.redraw = function()
		eihort.beginRender();

		sky:render( worldView, 0, (eyeY - 16) / viewDistance, 0 );
		if eyeY > 16 then
			worldView:setFog( viewDistance * 0.7, viewDistance, sky:getHorizFogColor() );
		else
			worldView:setFog( viewDistance * 0.7, viewDistance, 0, 0, 0 );
		end
		worldView:render( true );
		
		if not Config.takeScreenshotAsIs and not Config.buttonUseIsToggled then
			if takeScreenshot then
				takeScreenshot = false;
				takeScreenshotNow( worldName );
			end
		end

		if showUI then
			local ctx = eihort.newUIContext();
			uiRoot:render( ctx );
			refreshInfoDisplay();
			infoDisplay:render( ctx );
			ctx:destroy();
		end
		
		if Config.takeScreenshotAsIs or Config.buttonUseIsToggled then
			if takeScreenshot then
				takeScreenshot = false;
				takeScreenshotNow( worldName );
			end
		end

		local good, err = eihort.endRender();
		assert( good or Config.ignore_gl_errors, err );
	end;
	
	EventDownAction.resize = function()
		resetCameraParams();
		uiRoot:changedAspect();
		infoDisplay:changedAspect();
	end;

	-------------------------------------------------------------------
	-- Movement controls
	
	local function moveEye( dx, dy, dz, scale )
		eyeX = eyeX + dx * scale;
		eyeY = eyeY + dy * scale;
		eyeZ = eyeZ + dz * scale;
	end;
	local function frameMove( dt )
		local ret = false;
		if execNoLoad[1] and not worldView:isLoading() then
			worldView:pauseLoading( false );
			local e = execNoLoad;
			execNoLoad = { };
			for _, v in ipairs( e ) do
				v();
			end
		end
		if controlsOn > 0 or math.abs( splinedt ) > 0.01 then
			local speed = dt * speedModifier;
			local mvSpeed = (Config.movement_speed or 50) * speed;
			if controls.moveforward > 0 then
				moveEye( fwdX, fwdY, fwdZ, mvSpeed );
			end
			if controls.moveback > 0 then
				moveEye( fwdX, fwdY, fwdZ, -mvSpeed );
			end
			if controls.moveright > 0 then
				moveEye( rightX, rightY, rightZ, mvSpeed );
			end
			if controls.moveleft > 0 then
				moveEye( rightX, rightY, rightZ, -mvSpeed );
			end
			if controls.moveup > 0 then
				moveEye( upX, upY, upZ, mvSpeed );
			end
			if controls.movedown > 0 then
				moveEye( upX, upY, upZ, -mvSpeed );
			end
			if controls['viewdist+'] > 0 or controls['viewdist-'] > 0 then
				local vdSpeed = speed * (Config.view_distance_speed or 50);
				if controls['viewdist+'] > 0 then
					viewDistance = viewDistance + vdSpeed;
					if viewDistance > 10000 then
						viewDistance = 10000;
					end
				end
				if controls['viewdist-'] > 0 then
					viewDistance = viewDistance - vdSpeed;
					if viewDistance < 50 then
						viewDistance = 50;
					end
				end
				resetCameraParams();
				worldView:setViewDistance( viewDistance );
			end
			if controls['time+'] > 0 or controls['time-'] > 0 then
				local tSpeed = speed * (Config.time_speed or 6) / 12;
				if controls['time+'] > 0 then
					worldTime = worldTime + tSpeed;
					if worldTime > 1 then
						worldTime = worldTime - 2;
					end
				end
				if controls['time-'] > 0 then
					worldTime = worldTime - tSpeed;
					if worldTime < -1 then
						worldTime = worldTime + 2;
					end
				end
				updateLightModels( worldView, sky, worldTime, light0 );
			end
			if controls['splinet+'] > 0 or controls['splinet-'] > 0 or math.abs( splinedt ) > 0.01 then
				local tSpeed = speedModifier * (Config.spline_speed or 0.5);
				local targdt = 0;
				if controls['splinet+'] > 0 then
					targdt = targdt + tSpeed;
				end
				if controls['splinet-'] > 0 then
					targdt = targdt - tSpeed;
				end
				splinedt = targdt + (splinedt - targdt) * (0.001^dt);
				splinet = splinet + splinedt * dt;
				if splinet < 0 then
					splinet = 0;
				elseif splinet > splines.x.n - 1 then
					splinet = splines.x.n - 1;
				end
				resolveSplinePos();
			end
			refreshPosition();
			ret = true;
		end
		if redrawNextFrame then
			redrawNextFrame = false;
			eihort.shouldRedraw( true );
		end
		return ret;
	end;

	-------------------------------------------------------------------
	-- Idle controller
	
	local minFrameTime = 1 / (Config.fps_limit or 60);
	local lastFrameTime = eihort.getTime();

	Event.idle = function()
		local t = eihort.getTime();
		local dt = t - lastFrameTime;
		if dt > minFrameTime then
			if dt > 0.1 then
				dt = 0.1;
				lastFrameTime = t;
			else
				lastFrameTime = lastFrameTime + dt;
			end
			return not frameMove( dt );
		end
		return true;
	end;
end


-- The world selection menu


require "ui"
require "mapview"
require "lang"

------------------------------------------------------------------------------
local function scanForWorlds( rootPath, cb )
	-- Scans for valid worlds in the given folder
	
	local ff = eihort.findFile( rootPath .. "/*" );
	if ff then
		repeat
			local fn, isdir = ff:filename();
			if isdir then
				local levelDatPath = rootPath .. fn .. "/level.dat";
				local f = io.open( levelDatPath, "rb" );
				if f then
					f:close();
					local oName, dat = eihort.loadNBT( levelDatPath );
					if dat then
						local levelData = dat:get("Data");
						if levelData then
							local levelName = levelData:get("LevelName");
							if levelName then
								cb( levelName, rootPath .. fn .. "/", levelData );
							end
						end
						dat:destroy();
					end
				end
			end
		until not ff:next()
		ff:close();
	end
end

------------------------------------------------------------------------------
function beginWorldMenu( force )
	-- Constructs and displays the world menu
	
	-- Clear the current event handlers
	EventDownAction = { };
	EventUpAction = { };

	-- Make a new top level UI container
	local uiRoot = ui.newRoot();
 
	-- Display warning if not MC file could be found
	if not ProgramState.usedMCVersion then
		eihort.errorDialog( LANG"ERR_Error", LANG"ERR_No_MC_jar");
	end
	
	-- "Eihort version" text for fullscreen
	if Config.fullscreen then
		local EihortVersionLabel = uiRoot:addLabel( LANG"WS_Eihort_Version" .. ": " .. eihort.Version, 0.03, 0, 0.02, 0.02, 0.3, 0.97 );
		EihortVersionLabel.align = eihort.TextAlignLeft + eihort.TextAlignTop;
	end
	
	-- "Select a world" text
	local selectLabel = uiRoot:addLabel( LANG"WS_Select", 0.045, 0, 0.3, 0.05, 0.4, 0.05 );
	selectLabel.align = eihort.TextAlignCenter + eihort.TextAlignVCenter;

	--[[ TODO: Add used MC version somwhere. Add full texture search path list on options page
	-- Texture search location box
	local assetPathsLabel = uiRoot:addLabel( LANG"WS_Tex_Search_Locs" .. ":" .. string.gsub ( ActiveAssetPaths, "\\" , "/" ), 0.03, 0, 0.02, 0, 0.3, 0.97 );
	assetPathsLabel.align = eihort.TextAlignLeft + eihort.TextAlignBottom;
	]]
	
	-- Generate potentially multiple pages of world select buttons
	local maxButtons = math.floor( (1 - 0.3) / 0.05 );
	local listRoot = uiRoot:addComposite( 0, 0.17, 1, 0.05*maxButtons );
	local listPages = { listRoot };
	local curPage = 1;
	local n = 0;
	local pageRect = { listPages[1].rect:getRect() };
	local lastSelectWorld, buttonTheme;

	-- Gets the name of the version the world was last played with
	local function ShowPlayedVersion ( path )
		local levelDatPath = path .. "level.dat";
		local rootName, levelDat = eihort.loadNBT( levelDatPath );
		local output = "";
		if Config.show_last_played_version then
			if levelDat then
				local levelData = levelDat:get("Data");
				if levelData then
					local playedVersion = levelData:get("Version");
					if playedVersion then
						local playedVersionName = playedVersion:get("Name");
						local playedVersionSnapshot = playedVersion:get("Snapshot");
						output = "\n" .. LANG"WS_Version_Last_Played" .. ": ";
						if playedVersionSnapshot == 1 then
							output = output .. LANG"WS_Is_Snapshot" .. " ";
						end
						output = output .. playedVersionName;
					end
				end
			end
		end
		return (output);
	end
	
	-- Adds a new world to the list of worlds
	local function addWorldToList( name, path, levelData )
		
		-- Determine the version of the world
		local version = levelData:get("version");
		local versionStr, isAnvil = nil, true;
		if version then
			if version == 0x4abd then
				versionStr = "";
 			elseif version == 0x4abc then
				versionStr = "\n" .. LANG"WS_Map_Version" .. ": " .. LANG"WS_MCRegion_Version";
				isAnvil = false;
			end
		end
		versionStr = versionStr or ("\n" .. LANG"WS_Map_Version" .. ": " .. LANG"WS_Unknown_Version_Anvil");
		
		-- Add a new page if necessary
		if n == maxButtons then
			listRoot = uiRoot:addComposite( unpack( pageRect ) );
			table.insert( listPages, listRoot );
			listRoot.invisible = true;
			n = 0;
		end
		
		-- Make the world select button
		local function selectWorld()
			beginMapView( eihort.loadWorld( path, isAnvil ), name );
		end
		lastSelectWorld = selectWorld;
		local button = listRoot:addButton( selectWorld, name, 0.035, 0, 0.3, pageRect[2]+0.05*n, 0.4, 0.04 );
		button:setTheme( buttonTheme );
		button.tooltip = string.gsub ( path, "\\" , "/" ) .. versionStr .. ShowPlayedVersion(path);
		n = n + 1;
	end
	
	-- Scan all world paths for worlds
	for _, path in ipairs( Config.world_paths or { "." } ) do
		
		-- Checks inputs for RGB or HEX colours
		local function ProcessColours ( R, G, B, path)
			-- Disassemble HEX colours
			local function ParseHexColour ( hexColour )
					local returnR, returnG, returnB;
					
					if ( string.sub( R, 1, 1 ) == "#" and string.len( R ) == 7 ) then
						returnR = ( tonumber( string.sub( R, 2, 3 ), 16) / 255 );
						returnG = ( tonumber( string.sub( R, 4, 5 ), 16) / 255 );
						returnB = ( tonumber( string.sub( R, 6, 7 ), 16) / 255 );
						
						return returnR, returnG, returnB;
					else
						eihort.errorDialog( LANG"ERR_Error", LANG( "ERR_Unprocessable_world_colour", string.gsub( path, "\\", "/" ) ) );
						return 0, 0, 0;
					end
			end
			
			if ( G and B ) and ( tonumber(R) and tonumber(G) and tonumber(B) ) then
				return R, G, B;
			else
				return ParseHexColour ( R );
			end
		end
		
		local worldR, worldG, worldB;
		
		worldR, worldG, worldB = ProcessColours ( path[2], path[3], path[4], path[1]);
		
		local function colors( sc1, add1, sc2, add2 )
			return { true, worldR*sc1+add1, worldG*sc1+add1, worldB*sc1+add1, worldR*sc2+add2, worldG*sc2+add2, worldB*sc2+add2 };
		end
		local OFF = { false };
		buttonTheme = {
			bkg =       colors( 1, 0, 0.8, 0 );
			bkg_mo =    colors( 0.7, 0.2, 0.5, 0.4 );
			bkg_md =    colors( -1, 1, -0.8, 1 );
			border =    OFF;
			border_mo = OFF;
			border_md = OFF;
		};
		scanForWorlds( path[1], addWorldToList );
	end

	if #listPages > 1 then
		-- Multiple pages - add Next/Prev buttons
		uiRoot:addButton( function()
			listPages[curPage].invisible = true;
			curPage = curPage - 1;
			if curPage < 1 then
				curPage = #listPages;
			end
			listPages[curPage].invisible = false;
		end, LANG"WS_Prev_Page", 0.03, 0, 0.35, pageRect[2]-0.05, 0.3, 0.035 );
		uiRoot:addButton( function()
			listPages[curPage].invisible = true;
			curPage = curPage + 1;
			if curPage > #listPages then
				curPage = 1;
			end
			listPages[curPage].invisible = false;
		end, LANG"WS_Next_Page", 0.03, 0, 0.35, pageRect[2]+pageRect[4]+0.04-0.035, 0.3, 0.035 );
	elseif n <= 1 then
		if n == 1 then
			-- Only one world.. let's just load it directly
			if not force then
				lastSelectWorld();
				return;
			end
		else
			error( LANG"ERR_No_Worlds" );
		end
	end
	
	-- Quit button
	local quitButton = uiRoot:addButton( function()
			Event.quit();
		-- layout: font-size, border, distance from left, distance from top, box-width, box-height
		end, LANG"WS_Quit_Button_Text", 0.04, 0, 0.855, 0.9, 0.13, 0.08 );

	-- Background color
	eihort.setClearColor( 0, 0, 0 );

	-------------------------------------------------------------------
	-- Mouse stuff
	local mouseX, mouseY = eihort.getMousePos();
	uiRoot:mouseEnter( mouseX / ScreenWidth, mouseY / ScreenWidth );
	eihort.showCursor( true );
	Event.mousemove = function( x, y )
		mouseX = x;
		mouseY = y;

		-- Update the UI
		uiRoot:mouseMove( x / ScreenWidth, y / ScreenHeight );
	end;
	EventDownAction.mouse1 = function()
		uiRoot:mouseDown( mouseX / ScreenWidth, mouseY / ScreenHeight );
	end;
	EventUpAction.mouse1 = function()
		uiRoot:mouseUp( mouseX / ScreenWidth, mouseY / ScreenHeight );
	end;

	-------------------------------------------------------------------
	-- Screen stuff
	Event.redraw = function()
		eihort.beginRender();
		eihort.clearScreen();

		local uiCtx = eihort.newUIContext();
		uiRoot:render( uiCtx );
		uiCtx:destroy();

		local good, err = eihort.endRender();
		assert( good or Config.ignore_gl_errors, err );
	end;
	EventDownAction.resize = function()
		uiRoot:changedAspect();
	end;

	-------------------------------------------------------------------
	-- Idle controller
	Event.idle = function()
		return true;
	end;
end

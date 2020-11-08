
-- Development tools for eihort

------------------------------------------------------------------------------
-- Print all found MC versions to a file
function PrintVersionsList( )
	local file;
	local handoverTable = { };
	
	local function DoRightSpacing ( version )
		local maxLength = 12;
		local output = "";
		
		for i = string.len(version), maxLength do
			output = output .. " ";
		end
		
		return output .. version;
	end
	local function CalculateSnapshotValue( snapshot )
		local year, week, subweek, returnValue;
		
		year, week, subweek = string.match( snapshot, "^(%d+)w(%d+)(%w?)$" );
		returnValue = tonumber(year) * 100 + tonumber(week) + (subweek == "" and 0 or string.byte(subweek) / 256);
		
		return returnValue;
	end
	local function SortSnapshotValueTable ( sortTable )
		local returnTable = { };
		
		local function FillGarbagecollector ( tabe )
			local garbagecollector = "";
			
			for k, v in ipairs ( tabe ) do
				garbagecollector = garbagecollector .. "[" .. k .. "] = { " .. v[1] .. ", " .. v[2] .. " };\n";
			end
			
			return garbagecollector;
		end
		
		for nr, tab in ipairs( sortTable ) do
			if returnTable[1] then
				for nr2, tab2 in ipairs( returnTable ) do
					if tab[2] > tab2[2] then
						table.insert( returnTable, nr2, tab );
						break;
					elseif not returnTable[nr2+1] then
						table.insert( returnTable, #returnTable+1, tab );
						break;
					end
				end
			else
				table.insert( returnTable, 1, tab );
			end
		end
		
		return returnTable;
	end
	local function LimitDecimalAmmount ( input, amount )
		return string.format( "%." .. amount .. "f", input )
	end
	
	-- Fill and sort handoverTable with versions from table MinecraftVersions
	for key, val in pairs( MinecraftVersions ) do
		handoverTable[#handoverTable + 1] = { key, CalculateSnapshotValue( val ), val };
	end
	handoverTable = SortSnapshotValueTable( handoverTable );
	
	
	eihort.createDirectory( Config.deveoper_tools_path );
	file = io.open ( Config.deveoper_tools_path .. "mc versions.txt", "w" );
	
	if file then
		file:write("DETECTED MINECRAFT VERSIONS:\n\nSearched in: " .. string.gsub ( Config.minecraft_path, "\\" , "/" ) .. "versions/*\n\n");
		
		file:write("All detected versions:\n");
		if ProgramState.usedMCVersion then
			for nr, versionTable in ipairs( SortSnapshotValueTable( foundVersions ) ) do
				if string.sub( versionTable[1], 1, 1 ) ~= "." then
					file:write( versionTable[1] );
					if foundVersions[nr + 1] then
						file:write(", ");
					end
				end
			end
			
			file:write("\n\n");
			
			file:write("Version list with calculation values:\n");
			for _, tab in ipairs ( SortSnapshotValueTable( foundVersions ) ) do
				if string.sub( tab[1], 1, 1 ) ~= "." then
					file:write(" " .. DoRightSpacing( tab[1] ) .. " = " .. tostring( LimitDecimalAmmount ( tab[2], 3 ) ) .. "\n" );
				end
			end
			file:write("\n");
			
			file:write("The best found version is " .. tostring(foundVersions["bestVersion"]) .. " with a value of " .. tostring( LimitDecimalAmmount ( foundVersions["bestVersionVal"], 3 ) ) .. "." );
		else
			file:write("eihort was not able to find any version of Minecraft.");
		end
		file:write("\n\n");
		
		file:write("All known version equivalents with calculation values:\n");
		for i=#handoverTable, 1, -1 do
			file:write(" " .. DoRightSpacing( handoverTable[i][1] ) .. " = " .. handoverTable[i][3] .. " (" .. LimitDecimalAmmount ( handoverTable[i][2], 3 ) .. ")" .. "\n" );
		end
		file:write("\n");
		
		file:close();
	end
end

------------------------------------------------------------------------------
-- Print the whole list of loaded assests to a file
function PrintAssetIndex( assetIndex )
	local f;
	
	eihort.createDirectory( Config.deveoper_tools_path );
	
	-- Print assets list to a *.txt file
	f = io.open( Config.deveoper_tools_path .. "assets.txt", "w" );
	if f then
		for k, v in pairs( assetIndex ) do
			f:write( k .. " -> " .. v .. "\n" );
		end
		f:close();
	end
end

------------------------------------------------------------------------------
-- Print the whole list of loaded assests to a file
function PrintCacheHits( hitList )
	local file;
	local cacheQueries, cacheHits = 0, 0;
	
	-- Calculate cache queries and hits
	local function CalculteTotalNumbers ()
		for key, count in pairs( hitList ) do
			cacheQueries = cacheQueries + count
			cacheHits = cacheHits + (count - 1)
		end
	end
	-- Sort cache list most to least hits
	local function SortHitList ()
		local sortedTable = { };
		local checkTable = { };
		
		for path, hits in pairs( hitList ) do			
			if sortedTable[1] then
				for nr, hitTable in ipairs( sortedTable ) do
					if not checkTable[path] then
						if hitList[path] > sortedTable[nr][1] or hitList[path] == sortedTable[nr][1] then
							table.insert ( sortedTable, nr, { hits, path } )
							checkTable[path] = true;
						elseif not sortedTable[nr+1] then
							table.insert ( sortedTable, { hits, path } )
							checkTable[path] = true;
						end
					end
				end
			else
				table.insert ( sortedTable, { hits, path } )
				checkTable[path] = true;
			end
		end
		
		return sortedTable;
	end
	-- Check for the largest hits for one file
	local function FindMostHits( hitList )
		local returnValue = 0;
		
		for nr, hitTable in ipairs( hitList ) do
			if hitList[nr][1] > returnValue then
				returnValue = hitList[nr][1];
			end
		end
		
		return returnValue;
	end
	-- Calculate spaces for the output file
	local function AddSpacer( word, maxLength )
		local output = "";
		
		maxLength = string.len( tostring( maxLength ) );
		
		for	i = string.len( tostring( word ) ), maxLength + 1 do
			output = output .. " ";
		end
		
		return output;
	end
	
	eihort.createDirectory( Config.deveoper_tools_path );
	file = io.open ( Config.deveoper_tools_path .. "cache hits.txt", "w" );
	
	if file then
		file:write("DETECTED CACHE HITS:\n\n");
		
		CalculteTotalNumbers ();
		
		file:write("    Total Quries: " .. cacheQueries .. "\n");
		file:write("      Total Hits: " .. cacheHits .. "\n");
		file:write("  Hits / Queries: " .. string.format( "%.2f", cacheHits/cacheQueries ) .. "\n");
		
		if Config.print_cache_hits_detail then
			local sortedHitList = { };
			local highestNumber, hitsString, counterString;
			
			file:write("\n -- INFORMATION -- \n");
			file:write(" full_tex: texture is located in assets/minecraft/textures/blocks/* and is loaded via blockids.lua\n");
			file:write("  cut_tex: texture is not located in assets/minecraft/textures/blocks/* and is loaded via blocktextures.lua\n");
			
			hitsString = "HITS";	
			sortedHitList = SortHitList();
			highestNumber = FindMostHits( sortedHitList );
			if string.len( hitsString ) > highestNumber then
				highestNumber = string.len( hitsString );
			end
			
			file:write("\n");
			file:write( "     " .. AddSpacer( #sortedHitList, #sortedHitList ) .. "  " .. AddSpacer( hitsString, highestNumber ) .. hitsString .. "  |  TEXTURE\n");
			file:write("-------------------------------------------------------------------------------\n");
			
			for nr, infoTable in ipairs( sortedHitList ) do
				file:write(" " .. AddSpacer( nr * 100, #sortedHitList ) .. "[" .. nr .. "] = " .. AddSpacer( infoTable[1], highestNumber ) .. infoTable[1] .. "  |  " .. infoTable[2] .. "\n");
			end
		end
		file:close();
	end
end

------------------------------------------------------------------------------
-- Developer Buttons

-- Restart eihort button
function RestartEihort( worldPath, eyeX, eyeY, eyeZ, pitch, azimuth, dimemsion )
local executeLine, eihortExtension;

local function VramHandover( )
	local returnValue = "";
	
	if ProgramState.noDetectedVram then
		returnValue = " -vram " .. ProgramState.defaultVRAM;
	end
	
	return returnValue;
end

executeLine = "START \"eihort\" /D";
eihortExtension = "exe"; -- needs to be improved for Linux and Mac

executeLine = executeLine .. " \"" .. Config.eihort_path .. "\" eihort." .. eihortExtension; -- set path
executeLine = executeLine .. " -world \"" .. worldPath .. "\" " .. " -eyeX " .. eyeX .. " -eyeY " .. eyeY .. " -eyeZ " .. eyeZ .. " -pitch " .. pitch .. " -azimuth " .. azimuth .. " -dimemsion " .. dimemsion .. VramHandover(); -- add arguments

os.execute( executeLine ); -- Load new eihort window
QuitFlag = 1; -- Close current eihort window
end


-- This module contains functions which help manage and load assets which
-- may be strewn across multiple zip files and in multiple directories


-- List of zip files in which to search for assets
local assetArchives = { };
-- Global asset path -> asset location table
-- Entries are either paths to files, or paths of the form \d*:\d*(>\d*)?,
-- giving the archive to look up the asset in, the offset into that
-- archive, and the decompressed size of the asset
local assetIndex = { };
-- \n-separated list of paths in which assets are searched for
-- For display purposes
ActiveAssetPaths = "";

------------------------------------------------------------------------------
local function loadAsset( path, loader, loaderZipDirect )
	-- Helper function to resolve the location of an asset
	-- Passes the work to the given loader function
	
	local assetpath = assetIndex[path];
	if not assetpath then
		return;
	end
	local archive, start, comp, ucomp = string.match( assetpath, "^([^?]+)%?(%d+):(%d+)>?(%d*)$" );
	if archive then
		-- Asset is stored in a zip
		local zip = assetArchives[tonumber(archive)];
		return loaderZipDirect( zip, tonumber(start), tonumber(comp), tonumber(ucomp) );
	else
		-- Load the file directly
		return loader( assetpath );
	end
end

------------------------------------------------------------------------------
local function indexDirectory( root, assetPath, ff )
	-- Recursively adds all files in a directory to the global asset index
	
	repeat
		local fn, isdir = ff:filename();
		local fullfn = root .. fn;
		local fullasset = assetPath .. fn;
		if isdir then
			if fn ~= "." and fn ~= ".." then
				local ff2 = eihort.findFile( fullfn .. "/*" );
				if ff2 then
					indexDirectory( fullfn .. "/", fullasset .. "/", ff2 );
					ff2:close();
				end
			end
		else
			assetIndex[fullasset] = fullfn;
		end
	until not ff:next();
end

------------------------------------------------------------------------------
local function indexAssets( searchPaths )
	-- Takes a list of search paths and adds all assets contained therein
	-- to the global asset index
	-- Earlier search paths override later search paths
	
	for i = #searchPaths, 1, -1 do
		path = searchPaths[i];

		if type(path) == "table" then
			-- This is another list of asset paths - probably from listFiles
			indexAssets( path );
		else
			-- Maybe this is an archive?
			local archiveIndex = eihort.indexZip( path );
			if archiveIndex then
				-- Yup.. add all files in the archive to the index
				local aid = #assetArchives + 1;
				assetArchives[aid] = path;
				for filename, directAccess in pairs( archiveIndex ) do
					assetIndex[filename] = aid .. "?" .. directAccess;
				end
				ActiveAssetPaths = "\n" .. path .. ActiveAssetPaths;
			else
				-- Nope.. maybe it's a folder?
				local ff = eihort.findFile( path .. "/*" );
				if ff then
					-- Yup.. add all files to the asset index
					indexDirectory( path .. "/", "", ff );
					ff:close();
					ActiveAssetPaths = "\n" .. path .. ActiveAssetPaths;
				else
					-- It's neither.. silently ignore it so we can put
					-- filenames with ??? in the default config
				end
			end
		end
	end
end

------------------------------------------------------------------------------
function initializeAssetIndex( searchpaths )
	-- Load all files in the search paths into one giant table
	indexAssets( searchpaths );

	-- Print assets list to a *.txt file (in devtools.lua)
	if Config.deveoper_tools and Config.print_loaded_assets then
		PrintAssetIndex( assetIndex );
	end
end

------------------------------------------------------------------------------
function errorNecessaryAsset( path )
	-- Nice error message for when an asset is inaccessible
	error( LANG("ERR_No_Asset", path) );
end

------------------------------------------------------------------------------
function loadTexture( path, failw, failh )
	-- Helper for a texture loading function
	-- Fails with an error for the user if the texture is not found and
	-- failw and failh are not given
	
	local asset = loadAsset( path, eihort.loadImage, eihort.loadImageZipDirect );
	if not asset and failw then
		if Config.silent_fail_texture_load then
			-- Return a white image for unknown but necessary textures
			return eihort.newImage( failw, failh, 1, 1, 1, 1 );
		else
			errorNecessaryAsset( path );
		end
	end
	return asset;
end

------------------------------------------------------------------------------
local function fileReader( path )
	-- Helper function for the font loader, which will
	-- load and return the file given
	
	local f = io.open( path, "rb" );
	local data = f:read("*a");
	f:close();
	return data;
end

------------------------------------------------------------------------------
local glyphSizes;
eihort.setFontLoader( function( pageid )
	-- Font page loader
	if not glyphSizes then
		-- Load glyph_sizes.bin
		local binpath = "assets/minecraft/font/glyph_sizes.bin";
		glyphSizes = loadAsset( binpath, fileReader, eihort.readFileZipDirect );
		if not glyphSizes then
			errorNecessaryAsset( binpath );
		end
	end
	local texpath = string.format( "assets/minecraft/textures/font/unicode_page_%02x.png", pageid );
	local tex = loadTexture( texpath );
	if tex then
		local gltex = tex:uploadToGL( 'clamp', 'mag_nearest', 'min_nearest', 'mip_none' );
		return gltex, string.sub( glyphSizes, 256*pageid + 1, 256*pageid + 256 );
	end
end );


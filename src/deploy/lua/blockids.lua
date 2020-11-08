
-- Block ID -> Geometry description for Eihort 0.3.0+

-- The first part of this file contains helper functions used to construct
-- the various block geometry objects.
-- The actual Block ID -> Geometry list starts partway down.

require "assets"
require "lang"
require "blocktextures"

function loadBlockDesc()
	local blocks = eihort.newBlockDesc();

	-- Basic texture loading
	local textureCache = { };
	local transformedMinecraftTexture = { };
	local defAniso = 'aniso_' .. tostring( Config.anisotropy or 0 );
	local cacheHits = { }; -- Debug table for cahehits
	local blocksTexturePath = "assets/minecraft/textures/blocks/";
	local blocksTextureExtension = ".png";
	
	function texUpload( img, ... )
		return img:uploadToGL( 'repeat', 'mag_nearest', 'min_linear', 'mip_linear', 'mipgen_alphawt_box', defAniso, ... );
	end
	
	-- Fill debug table for cahehits
	local function AddToCacheHitsList( imgName )
		if Config.deveoper_tools and Config.print_cache_hits then
			-- Remove the path from the texture name
			local function StripPathFromTexture( fullTexName )
				local pathStart, pathEnd, returnValue;
				
				pathStart, pathEnd = string.find( fullTexName, "assets/minecraft/textures/blocks/" );
				
				if pathStart and pathEnd then
					returnValue = "full_tex " .. string.sub( fullTexName, 1, pathStart-1 ) .. string.sub( fullTexName, pathEnd+1, string.len( fullTexName ) );
				else
					returnValue = " cut_tex " .. fullTexName;
				end
				
				return returnValue;
			end
			
			if cacheHits[StripPathFromTexture( imgName )] then
				cacheHits[StripPathFromTexture( imgName )] = cacheHits[StripPathFromTexture( imgName )] + 1
			else
				cacheHits[StripPathFromTexture( imgName )] = 1
			end
		end
	end
	
	-- Upload textures VRAM
	function TEX( filename, ... )
		function quote( s ) 
			return string.format( '\'%s\'', string.gsub( s, '[\\\']', '\\%1' ))
		end
		local cachekey = quote( filename )
		for _, arg in ipairs({ ... }) do
			cachekey = string.format( '%s,%s', cachekey, quote( arg ) )
		end
		local cached = textureCache[cachekey];
		
		AddToCacheHitsList( cachekey )
		
		if cached then
			return cached;
		end
		local teximg = loadTexture( filename, 1, 1 );
		local tex = texUpload( teximg, ... );
		textureCache[cachekey] = tex;
		teximg:destroy();
		return tex;
	end

	-- Some special cases where the alpha channels must be modified
	local function Tex_AlphaFromGray( t1, t2, ... )
		t1:grayToAlpha( t2 );
		local tex = texUpload( t1, 'mipgen_box', ... );
		t1:destroy();
		t2:destroy();
		return tex;
	end
	local function BTEX_AlphaFromGray( basetex, graytex, ... )
		return Tex_AlphaFromGray( loadTexture( blocksTexturePath .. basetex .. blocksTextureExtension, 1, 1 ), loadTexture( blocksTexturePath .. graytex .. blocksTextureExtension, 1, 1 ), ... );
	end
	local function BTEX_InAlpha( alphatex, ... )
		local img = loadTexture( blocksTexturePath .. alphatex .. blocksTextureExtension, 1, 1 );
		return Tex_AlphaFromGray( eihort.newImage( img.width, img.height, 0, 0, 0, 0 ), img, ... );
	end
	local function BTEX_NoAlpha( blocktex, ... )
		local img = loadTexture( blocksTexturePath .. blocktex .. blocksTextureExtension, 1, 1 );
		return Tex_AlphaFromGray( img, eihort.newImage( img.width, img.height, 0, 0, 0, 0 ), ... );
	end

	-- Load additional textures
	transformedMinecraftTexture = LoadAdditionalTextures();
	
	-- Upload all textures to OpenGL
	local function TTEX ( blocktex, ... )
		local function returnQuote ( input )
			local output;
			
			output = string.gsub( input, "\\", "/" );
			output = "'" .. output .. "'";
			
			return output;
		end
		local function addQuotedArgs ( argTable )
			local output = "";
			
			for _, arg in ipairs ( argTable ) do
				output = output .. "," .. returnQuote ( arg );
			end
			
			return output;
		end
		
		local texUploadValue, texName;
		
		texName = returnQuote ( blocktex ) .. addQuotedArgs( { ... } );
		
		AddToCacheHitsList( texName );
		
		if textureCache[texName] then
			return textureCache[texName];
		else
			texUploadValue = texUpload( transformedMinecraftTexture[blocktex], ... );
			textureCache[texName] = texUploadValue;
			
			return texUploadValue;
		end
	end
	
	-- Special cases for water, lava and portals
	local function BTEX_Nonsquare( nosquaretex, columns, ... )
		local columsIsNumber, workColumns, teximg, teximg_sub, tex;
		local commandTable = { ... };
		
		if type( columns ) == "number" then
			columsIsNumber = true;
			workColumns = columns or 1;
		else
			columsIsNumber = false;
			workColumns = 1;
			if type( columns ) == "string" then
				table.insert( commandTable, 1, columns );
			end
		end
		
		teximg = loadTexture( nosquaretex, workColumns, 1 );
		teximg_sub = teximg:sub( 0, 0, teximg.width / workColumns, teximg.width / workColumns );
		
		if columsIsNumber then
			tex = texUpload( teximg_sub, ... );
		else
			tex = texUpload( teximg_sub, unpack( commandTable ) );
		end
		
		teximg:destroy();
		teximg_sub:destroy();
		
		return tex;
	end
	
	-- Texture loading for square, non-square and additional images
	function BTEX( blocktex, ... )
		local imgPath, imgTexture;
		
		imgPath = blocksTexturePath .. blocktex .. blocksTextureExtension;
		imgTexture = loadTexture( imgPath, 1, 1 );
		
		if transformedMinecraftTexture[blocktex] then
			imgTexture:destroy();
			return TTEX( blocktex, ... );
		else
			if imgTexture.height == imgTexture.width then
				imgTexture:destroy();
				return TEX( imgPath, ... );
			else
				imgTexture:destroy();
				return BTEX_Nonsquare( imgPath, ... )
			end
		end
	end

	-- Block geometry adapters
	local function DataAdapter( mask, ... ) -- "mask" is the bitmask for the data value.
		local geoms = { ... };
		local geomList = { };
		local solidity = 0x3f;
		for i, v in ipairs( geoms ) do
			if type( v ) == "number" then
				geomList[i] = geomList[v+1];
			else
				geomList[i] = v[1];
				solidity = eihort.intAnd( solidity, v[2] );
			end
		end
		return { eihort.geom.dataAdapter( mask, unpack( geomList ) ), solidity };
	end
	local function RotatingAdapter( normalGeom, faceGeom )
		return { eihort.geom.rotatingAdapter( normalGeom[1], faceGeom[1] ),
			     eihort.intAnd( normalGeom[2], eihort.intOr( 0x60, faceGeom[2] ) ) };
	end
	local function FaceBitAdapter( faceGeom )
		return { eihort.geom.faceBitAdapter( faceGeom[1] ), 0x00 };
	end
	local function FacingAdapter( normalGeom, faceGeom )
		if not normalGeom then
			normalGeom = { false, 0x00 };
		end
		return { eihort.geom.facingAdapter( normalGeom[1], faceGeom[1] ),
			     eihort.intAnd( normalGeom[2], eihort.intOr( 0x60, faceGeom[2] ) ) };
	end
	local function TopDifferentAdapter( normalGeom, diffGeom, topId, topGeom )
		return { eihort.geom.topDifferentAdapter( normalGeom[1], diffGeom[1], topId, topGeom and topGeom[1] ),
		         eihort.intAnd( normalGeom[2], diffGeom[2] ) };
	end
	local function SetTexScale( geom, s, t )
		geom[1]:setTexScale( s, t );
		return geom;
	end
	local function DelayRender( geom, delta )
		geom[1]:renderGroupAdd( delta or 1 );
		return geom;
	end

	-- Block Geometry creators
	-- In all the following, ... represents a list of textures with different
	-- meaning depending on how many textures are given:
	--     One texture: All sides of the block are covered with the same texture
	--     Two textures: The four sides take the first texture, the top and
	--                   bottom take the second
	--     Three textures: Sides, bottom, top
	--     Four textures: First two textures are the sides, which go on alternate
	--                    faces, last two textures are bottom and top
	--     Six textures: All 6 sides in the order X- X+ Z- Z+ Y- Y+ (sides: west, east, north, south, bottom, top)
	
	local function OpaqueBlock( ... )
		return { eihort.geom.opaqueBlock( ... ), 0x3f };
	end
	local function HollowOpaqueBlock( ... )
		return { eihort.geom.opaqueBlock( ... ), 0x00 };
	end
	local function BrightOpaqueBlock( ... )
		return { eihort.geom.brightOpaqueBlock( ... ), 0x3f };
	end
	local function TransparentBlock( order, ... )
		return { eihort.geom.transparentBlock( order, ... ), 0x00 };
	end
	local function Slab( topOffset, bottomOffset, ... )
		local solidity = 0;
		if topOffset == 0 then
			solidity = solidity + 0x10;
		end
		if bottomOffset == 0 then
			solidity = solidity + 0x20;
		end
		return { eihort.geom.squashedBlock( topOffset, bottomOffset, ... ), solidity };
	end
	local function CompactedBlock( offsetXn, offsetXp, offsetZn, offsetZp, offsetYn, offsetYp, ... )
		return { eihort.geom.compactedBlock( offsetXn, offsetXp, offsetZn, offsetZp, offsetYn, offsetYp, ... ), 0x00 };
	end
	local function MultiCompactedBlock( offsets, ... )
		-- Will compact in sequence north, south, west, east, bottom, top
		return { eihort.geom.multiCompactedBlock( offsets, ... ) , 0x00 };
	end
	local function MultiCompactedConnectedBlock( x, y, z, ... )
		-- Will compact in sequence north, south, west, east, bottom, top
		-- Connections: table 1 = north-south, table 2 = west-east, table 3 = top-bottom
		return { eihort.geom.multiCompactedConnectedBlock( x, y, z, ... ) , 0x00 };
	end
	local function BiomeOpaqueBlock( biomeChannel, ... )
		return { eihort.geom.biomeOpaqueBlock( biomeChannel, ... ), 0x3f };
	end
	local function BiomeHollowOpaqueBlock( biomeChannel, ... )
		return { eihort.geom.biomeOpaqueBlock( biomeChannel, ... ), 0x00 };
	end
	local function BiomeAlphaOpaqueBlock( biomeChannel, ... )
		return { eihort.geom.biomeAlphaOpaqueBlock( biomeChannel, ... ), 0x3f };
	end
	local function Portal( tex )
		return { eihort.geom.portal( tex ), 0x00 };
	end
	local function HashShapedBlock( offset, ... )
		return { eihort.geom.hashShapedBlock( offset, ... ), 0x00 };
	end
	local function BiomeHashShapedBlock( biomeChannel, offset, ... )
		return { eihort.geom.biomeHashShapedBlock( biomeChannel, offset, ... ), 0x00 };
	end
	local function Rail( straight, turn )
		return { eihort.geom.rail( straight, turn ), 0x00 };
	end
	local function Door( bottom, top )
		return DataAdapter( 0x8,
			{ eihort.geom.door( bottom ), 0x00 },
			{ eihort.geom.door( top ), 0x00 } );
	end
	local function Stairs( ... )
		return { eihort.geom.stairs( ... ), 0x00 };
	end
	local function Torch( tex )
		return { eihort.geom.torch( tex ), 0x00 };
	end
	local function XShapedBlock( tex )
		return { eihort.geom.xShapedBlock( tex ), 0x00 };
	end
	local function BiomeXShapedBlock( biomeChannel, tex )
		return { eihort.geom.biomeXShapedBlock( biomeChannel, tex ), 0x00 };
	end
	local function Fence( tex )
		return MultiCompactedConnectedBlock(
		          {  10,  10,  -7,  -7, -11,  -2,
				     10,  10,  -7,  -7,  -5,  -8 },
				  {  -7,  -7,  10,  10, -11,  -2,
				     -7,  -7,  10,  10,  -5,  -8 },
				  {  -6,  -6,  -6,  -6,  -0,  -0 },
				  tex );
	end
	local function FenceGate( tex )
		return DataAdapter( 0x4, -- Fence Gate
		          DataAdapter( 0x3, -- fence fate CLOSED
		            MultiCompactedBlock( -- facing south
		              { -7,  -7,  0,  -14,  -5,   0, -- end bars
		                -7,  -7,  -14,  0,  -5,   0, 
		                -7,  -7,  -2,  -2, -12,  -1, -- gate parts
		                -7,  -7,  -6,  -6,  -9,  -4,
		                -7,  -7,  -2,  -2,  -6,  -7 },
		              tex ),
		            MultiCompactedBlock( -- facing west
		              {-14,   0,  -7,  -7,  -5,   0, -- end bars
		                 0, -14,  -7,  -7,  -5,   0, 
		                -2,  -2,  -7,  -7, -12,  -1, -- gate parts
		                -6,  -6,  -7,  -7,  -9,  -4,
		                -2,  -2,  -7,  -7,  -6,  -7 },
		              tex ),
		            MultiCompactedBlock( -- facing north
		              { -7,  -7,   0, -14,  -5,   0, -- end bars
		                -7,  -7, -14,   0,  -5,   0, 
		                -7,  -7,  -2,  -2,  -12, -1, -- gate parts
		                -7,  -7,  -6,  -6,  -9,  -4,
		                -7,  -7,  -2,  -2,  -6,  -7 },
		              tex ),
		            MultiCompactedBlock( -- facing east
		              {-14,   0,  -7,  -7,  -5,   0, -- end bars
		                 0, -14,  -7,  -7,  -5,   0, 
		                -2,  -2,  -7,  -7, -12,  -1, -- gate parts
		                -6,  -6,  -7,  -7,  -9,  -4,
		                -2,  -2,  -7,  -7,  -6,  -7 },
		              tex ) ),
		          DataAdapter( 0x3, -- fence gate OPEN
		            MultiCompactedBlock( -- facing south
		              { -7,  -7,   0,  -14,  -5,  0, -- end bars
		                -7,  -7, -14,   0,  -5,   0, 
		                -9,  -1,   0, -14, -12,  -1, -- gate right
		               -13,  -1,   0, -14,  -9,  -4,
		                -9,  -1,   0, -14,  -6,  -7,
		                -9,  -1, -14,   0, -12,  -1, -- gate left
		               -13,  -1, -14,   0,  -9,  -4,
		                -9,  -1, -14,   0,  -6,  -7 },
		              tex ),
		            MultiCompactedBlock( -- facing west
		              {-14,   0,  -7,  -7,  -5,   0, -- end bars
		                 0, -14,  -7,  -7,  -5,   0, 
		               -14,   0,  -1,  -9, -12,  -1, -- gate left
		               -14,   0,  -1, -13,  -9,  -4,
		               -14,   0,  -1,  -9,  -6,  -7,
		                 0, -14,  -1,  -9, -12,  -1, -- gate right
		                 0, -14,  -1, -13,  -9,  -4,
		                 0, -14,  -1,  -9,  -6,  -7 },
		              tex ),
		            MultiCompactedBlock( -- facing north
		              { -7,  -7,   0, -14,  -5,   0, -- end bars
		                -7,  -7, -14,   0,  -5,   0, 
		                -1,  -9,   0, -14, -12,  -1, -- gate left
		                -1, -13,   0, -14,  -9,  -4,
		                -1,  -9,   0, -14,  -6,  -7,
		                -1,  -9, -14,   0, -12,  -1, -- gate right
		                -1, -13, -14,   0,  -9,  -4,
		                -1,  -9, -14,   0,  -6,  -7 },
		              tex ),
		            MultiCompactedBlock( -- facing east
		              {-14,   0,  -7,  -7,  -5,   0, -- end bars
		                 0, -14,  -7,  -7,  -5,   0, 
		               -14,   0,  -9,  -1, -12,  -1, -- gate right
		               -14,   0, -13,  -1,  -9,  -4,
		               -14,   0,  -9,  -1,  -6,  -7,
		                 0, -14,  -9,  -1, -12,  -1, -- gate left
		                 0, -14, -13,  -1,  -9,  -4,
		                 0, -14,  -9,  -1,  -6,  -7 },
		              tex ) ) );
	end
	local function ChorusFlowerImmature( )
		return MultiCompactedBlock(
		          { -2,  -2,  -2,  -2,  -2,  -2, -- mid part
		             0, -14,  -2,  -2,  -2,  -2, -- north part
		           -14,   0,  -2,  -2,  -2,  -2, -- south part
		            -2,  -2,   0, -14,  -2,  -2, -- west part
		            -2,  -2, -14,   0,  -2,  -2, -- east part
		            -2,  -2,  -2,  -2,   0, -14, -- bottom part
		            -2,  -2,  -2,  -2, -14,   0}, -- top part
		          BTEX("chorus_flower") );
	end
	local function repImage( img, m, n )
	local w, h = img.width, img.height;
	local resImg = eihort.newImage( m*w, n*h, 0, 0, 0, 0 );
	for i = 1, m do
		for j = 1, n do
			resImg:put( img, (i-1)*w, (j-1)*h );
		end
	end
	return resImg;
	end
	local function rotImage( img, m, n )
		local w, h = img.width, img.height
		local resImg = eihort.newImage( w, h, 0, 0, 0, 0 );
		for i = 0, 1 do
			for j = 0, 1 do
				resImg:put( img, (i-1)*w + m, (j-1)*h + n );
			end
		end
		return resImg;
	end
	local function SignTextures( mask )
		-- start with north facing
		 -- repeat front/back to 24x24 with vertical reps
		 -- repeat left/right to 16x24 and bot/top to 24x16 (Minecraft has 2px deep signs, Eihort 3)
		 -- shift front/back/left/right as the sign is offset from block top
		local w = rotImage( repImage( transformedMinecraftTexture.sign_right  , 8, 2 ), 0, 6 );
		local e = rotImage( repImage( transformedMinecraftTexture.sign_left , 8, 2 ), 0, 6 );
		local n = rotImage( repImage( transformedMinecraftTexture.sign_front , 1, 2 ), 0, 6 );
		local s = rotImage( repImage( transformedMinecraftTexture.sign_back  , 1, 2 ), 0, 6 );
		local b =           repImage( transformedMinecraftTexture.sign_bottom, 1, 8 );
		local t =           repImage( transformedMinecraftTexture.sign_top   , 1, 8 );
		-- 1 = rotate 90 degrees CCW about bot-top
		if eihort.intAnd( mask, 1 ) > 0 then
			w, e, n, s = n, s, e, w
			b, t = b:rotate('rotate_270'), t:rotate()
		end
		-- 2 = rotate 180 degrees about bot-top
		if eihort.intAnd( mask, 2 ) > 0 then
			w, e, n, s = e, w, s, n
			b, t = b:rotate('rotate_180'), t:rotate('rotate_180')
		end
		return { texUpload(w), texUpload(e), texUpload(n), texUpload(s), texUpload(b), texUpload(t) };
	end

	-------------------------------------------------------------------
	-- The actual block geometry list
	FurnaceBody = OpaqueBlock( BTEX("furnace_side"), BTEX("furnace_top") );
	MinecraftBlocks = {
		-- [<block id>] = <geometry>;
		[1]   = DataAdapter( 0x7, -- Stone Type
		          OpaqueBlock( BTEX("stone") ), -- stone
				  OpaqueBlock( BTEX("stone_granite") ), -- granite
				  OpaqueBlock( BTEX("stone_granite_smooth") ), -- polished granite
				  OpaqueBlock( BTEX("stone_diorite") ), -- diorite
				  OpaqueBlock( BTEX("stone_diorite_smooth") ), -- polished diorite
				  OpaqueBlock( BTEX("stone_andesite") ), -- andasite
				  OpaqueBlock( BTEX("stone_andesite_smooth") ), -- polished andasite
				  0 );
		[2]   = TopDifferentAdapter( -- Grass
		          BiomeAlphaOpaqueBlock( 0, BTEX_AlphaFromGray( "grass_side", "grass_side_overlay" ), BTEX_NoAlpha("dirt"), BTEX_InAlpha("grass_top") ), -- regular grass
		          OpaqueBlock( BTEX("grass_side_snowed"), BTEX("dirt") ), 78 ); -- snowy grass
		[3]   = DataAdapter( 0x3, -- Dirt
		          OpaqueBlock( BTEX("dirt") ), -- dirt
		          OpaqueBlock( BTEX("coarse_dirt") ), -- coarse
		          TopDifferentAdapter( -- Pozdol
					OpaqueBlock( BTEX("dirt_podzol_side"), BTEX("dirt"), BTEX("dirt_podzol_top") ), -- regular pozdol
					OpaqueBlock( BTEX("grass_side_snowed"), BTEX("dirt"), BTEX("dirt_podzol_top") ), 78 ), 0 ); -- snowy pozdol
		[4]   = OpaqueBlock( BTEX("cobblestone") ); -- Cobblestone
		[5]   = DataAdapter( 0x7, -- Wooden Plank
		          OpaqueBlock( BTEX("planks_oak") ), -- oak
		          OpaqueBlock( BTEX("planks_spruce") ), -- spruce
		          OpaqueBlock( BTEX("planks_birch") ), -- birch
		          OpaqueBlock( BTEX("planks_jungle") ), -- jungle
				  OpaqueBlock( BTEX("planks_acacia") ), -- acacia
				  OpaqueBlock( BTEX("planks_big_oak") ), -- dark oak
				  0, 0 );
		[6]   = DataAdapter( 0x7, -- Sapling
		          XShapedBlock( BTEX("sapling_oak") ), -- oak
		          XShapedBlock( BTEX("sapling_spruce") ), -- spruce
		          XShapedBlock( BTEX("sapling_birch") ), -- birch
		          XShapedBlock( BTEX("sapling_jungle") ), -- jungle
				  XShapedBlock( BTEX("sapling_acacia") ), -- acacia
				  XShapedBlock( BTEX("sapling_roofed_oak") ), -- dark oak
				  0, 0 );
		[7]   = OpaqueBlock( BTEX("bedrock") ); -- Bedrock
		[8]   = TransparentBlock( 1, BTEX( "water_flow" ), BTEX( "water_still" ) ); -- Water
		[9]   = TransparentBlock( 2, BTEX( "water_still" ) ); -- Stationary Water
		[10]  = BrightOpaqueBlock( BTEX( "lava_flow", 2 ), BTEX( "lava_still" ) ); -- Lava
		[11]  = BrightOpaqueBlock( BTEX( "lava_still" ) ); -- Stationary Lava
		[12]  = DataAdapter( 0x1, -- Sand
					OpaqueBlock( BTEX("sand") ), -- regular
					OpaqueBlock( BTEX("red_sand") ) ); -- red
		[13]  = OpaqueBlock( BTEX("gravel") ); -- Gravel
		[14]  = OpaqueBlock( BTEX("gold_ore") ); -- Gold Ore
		[15]  = OpaqueBlock( BTEX("iron_ore") ); -- Iron Ore
		[16]  = OpaqueBlock( BTEX("coal_ore") ); -- Coal Ore
		[17]  = DataAdapter( 0x3, -- Wood Log
		          DataAdapter( 0xc, -- oak log
					OpaqueBlock( BTEX("log_oak"), BTEX("log_oak_top") ), -- top-bottom
					OpaqueBlock( BTEX("log_oak_top"), BTEX("log_oak_top", 'rotate_180'), BTEX("log_oak", 'rotate_90'), BTEX("log_oak", 'rotate_270'), BTEX("log_oak", 'rotate_270'), BTEX("log_oak", 'rotate_270') ), -- west-east
					OpaqueBlock( BTEX("log_oak", 'rotate_90'), BTEX("log_oak", 'rotate_270'), BTEX("log_oak_top", 'rotate_180'), BTEX("log_oak_top"), BTEX("log_oak", 'rotate_180'), BTEX("log_oak") ), -- north-south
					0 ),
		          DataAdapter( 0xc, -- spruce log
					OpaqueBlock( BTEX("log_spruce"), BTEX("log_spruce_top") ), -- top-bottom
					OpaqueBlock( BTEX("log_spruce_top"), BTEX("log_spruce_top", 'rotate_180'), BTEX("log_spruce", 'rotate_90'), BTEX("log_spruce", 'rotate_270'), BTEX("log_spruce", 'rotate_270'), BTEX("log_spruce", 'rotate_270') ), -- west-east
					OpaqueBlock( BTEX("log_spruce", 'rotate_90'), BTEX("log_spruce", 'rotate_270'), BTEX("log_spruce_top", 'rotate_180'), BTEX("log_spruce_top"), BTEX("log_spruce", 'rotate_180'), BTEX("log_spruce") ), -- north-south
					0 ),
		          DataAdapter( 0xc, -- birch log
					OpaqueBlock( BTEX("log_birch"), BTEX("log_birch_top") ), -- top-bottom
					OpaqueBlock( BTEX("log_birch_top"), BTEX("log_birch_top", 'rotate_180'), BTEX("log_birch", 'rotate_90'), BTEX("log_birch", 'rotate_270'), BTEX("log_birch", 'rotate_270'), BTEX("log_birch", 'rotate_270') ), -- west-east
					OpaqueBlock( BTEX("log_birch", 'rotate_90'), BTEX("log_birch", 'rotate_270'), BTEX("log_birch_top", 'rotate_180'), BTEX("log_birch_top"), BTEX("log_birch", 'rotate_180'), BTEX("log_birch") ), -- north-south
					0 ),
		          DataAdapter( 0xc, -- jungle log
					OpaqueBlock( BTEX("log_jungle"), BTEX("log_jungle_top") ), -- top-bottom
					OpaqueBlock( BTEX("log_jungle_top"), BTEX("log_jungle_top", 'rotate_180'), BTEX("log_jungle", 'rotate_90'), BTEX("log_jungle", 'rotate_270'), BTEX("log_jungle", 'rotate_270'), BTEX("log_jungle", 'rotate_270') ), -- west-east
					OpaqueBlock( BTEX("log_jungle", 'rotate_90'), BTEX("log_jungle", 'rotate_270'), BTEX("log_jungle_top", 'rotate_180'), BTEX("log_jungle_top"), BTEX("log_jungle", 'rotate_180'), BTEX("log_jungle") ), -- north-south
					0 ) );
		[18]  = DataAdapter( 0x3, -- Leaves
		          BiomeHollowOpaqueBlock( 1, BTEX("leaves_oak") ), -- oak
		          BiomeHollowOpaqueBlock( 2, BTEX("leaves_spruce") ), -- spruce
		          BiomeHollowOpaqueBlock( 1, BTEX("leaves_birch") ), -- birch
		          BiomeHollowOpaqueBlock( 1, BTEX("leaves_jungle") ) ); -- jungle
		[19]  = DataAdapter( 0x1, -- Sponge
		          OpaqueBlock( BTEX("sponge") ), -- dry
		          OpaqueBlock( BTEX("sponge_wet") ) ); -- wet
		[20]  = HollowOpaqueBlock( BTEX("glass") ); -- Glass
		[21]  = OpaqueBlock( BTEX("lapis_ore") ); -- Lapis Lazuli Ore
		[22]  = OpaqueBlock( BTEX("lapis_block") ); -- Lapis Lazuli Block
		[23]  = DataAdapter( 0x6, -- Dispenser
					DataAdapter( 0x1,
						OpaqueBlock( BTEX("furnace_top", 'rotate_180'), BTEX("dispenser_front_vertical"), BTEX("furnace_top") ), -- facing down
						OpaqueBlock( BTEX("furnace_top"), BTEX("furnace_top"), BTEX("dispenser_front_vertical") ) ), -- facing up
					DataAdapter( 0x1,
						OpaqueBlock( BTEX("furnace_side"), BTEX("furnace_side"), BTEX("dispenser_front_horizontal"), BTEX("furnace_side"), BTEX("furnace_top"), BTEX("furnace_top") ), -- facing north
						OpaqueBlock( BTEX("furnace_side"), BTEX("furnace_side"), BTEX("furnace_side"), BTEX("dispenser_front_horizontal"), BTEX("furnace_top", 'rotate_180'), BTEX("furnace_top", 'rotate_180') ) ), -- facing south
					DataAdapter( 0x1,
						OpaqueBlock( BTEX("dispenser_front_horizontal"), BTEX("furnace_side"), BTEX("furnace_side"), BTEX("furnace_side"), BTEX("furnace_top", 'rotate_270'), BTEX("furnace_top", 'rotate_90') ), -- facing west
						OpaqueBlock( BTEX("furnace_side"), BTEX("dispenser_front_horizontal"), BTEX("furnace_side"), BTEX("furnace_side"), BTEX("furnace_top", 'rotate_90'), BTEX("furnace_top", 'rotate_270') ) ), -- facing east
					0, 0 );
		[24]  = DataAdapter( 0x3, -- Sandstone
		          OpaqueBlock( BTEX("sandstone_normal"), BTEX("sandstone_bottom"), BTEX("sandstone_top") ), -- regular
		          OpaqueBlock( BTEX("sandstone_carved"), BTEX("sandstone_top"), BTEX("sandstone_top") ), -- chiseled
		          OpaqueBlock( BTEX("sandstone_smooth"), BTEX("sandstone_top"), BTEX("sandstone_top") ), -- smooth
		          0 );
		[25]  = OpaqueBlock( BTEX("noteblock") ); -- Note Block
		[26] = DataAdapter( 0x3, -- Bed
		          DataAdapter( 0x8, -- facing south
					MultiCompactedBlock( -- bottom
					  {  0,   0,   0,   0,  -3,  -7, -- mid part
					     0,   0,   0, -16,   0,  -7, -- west rest
					     0, -16,   0,   0,   0,  -7, -- north rest
					     0,   0, -16,   0,   0,  -7 }, -- east rest
					  BTEX("bed_feet_side"), BTEX("bed_feet_side", 'flip_x'), BTEX("bed_feet_end"), TransparentTexture(), BTEX("planks_oak"), BTEX("bed_feet_top", 'rotate_270', 'flip_x') ),
					MultiCompactedBlock( -- top
					  {  0,   0,   0,   0,  -3,  -7, -- mid part
					     0,   0, -16,   0,   0,  -7, -- east rest
					   -16,   0,   0,   0,   0,  -7, -- south rest
					     0,   0,   0, -16,   0,  -7 }, -- west rest
					  BTEX("bed_head_side"), BTEX("bed_head_side", 'flip_x'), TransparentTexture(), BTEX("bed_head_end"), BTEX("planks_oak"), BTEX("bed_head_top", 'rotate_270', 'flip_x') ) ),
		          DataAdapter( 0x8, -- facing west
					MultiCompactedBlock( -- bottom
					  {  0,   0,   0,   0,  -3,  -7, -- mid part
					     0, -16,   0,   0,   0,  -7, -- north rest
					     0,   0, -16,   0,   0,  -7, -- east rest
					   -16,   0,   0,   0,   0,  -7 }, -- south rest
					  TransparentTexture(), BTEX("bed_feet_end"), BTEX("bed_feet_side"), BTEX("bed_feet_side", 'flip_x'), BTEX("planks_oak", 'rotate_90'), BTEX("bed_feet_top", 'flip_x') ),
					MultiCompactedBlock( -- top
					  {  0,   0,   0,   0,  -3,  -7, -- mid part
					   -16,   0,   0,   0,   0,  -7, -- south rest
					     0,   0,   0, -16,   0,  -7, -- west rest
					     0, -16,   0,   0,   0,  -7 }, -- north rest
					  BTEX("bed_head_end"), TransparentTexture(), BTEX("bed_head_side"), BTEX("bed_head_side", 'flip_x'), BTEX("planks_oak", 'rotate_90'), BTEX("bed_head_top", 'flip_x') ) ),
		          DataAdapter( 0x8, -- facing north
					MultiCompactedBlock( -- bottom
					  {  0,   0,   0,   0,  -3,  -7, -- mid part
					     0,   0, -16,   0,   0,  -7, -- east rest
					   -16,   0,   0,   0,   0,  -7, -- south rest
					     0,   0,   0, -16,   0,  -7 }, -- west rest
					  BTEX("bed_feet_side", 'flip_x'), BTEX("bed_feet_side"), TransparentTexture(), BTEX("bed_feet_end"), BTEX("planks_oak", 'rotate_180'), BTEX("bed_feet_top", 'rotate_90', 'flip_x') ),
					MultiCompactedBlock( -- top
					  {  0,   0,   0,   0,  -3,  -7, -- mid part
					     0,   0,   0, -16,   0,  -7, -- west rest
					     0, -16,   0,   0,   0,  -7, -- north rest
					     0,   0, -16,   0,   0,  -7 }, -- east rest
					  BTEX("bed_head_side", 'flip_x'), BTEX("bed_head_side"), BTEX("bed_head_end"), TransparentTexture(), BTEX("planks_oak", 'rotate_180'), BTEX("bed_head_top", 'rotate_90', 'flip_x') ) ),
		          DataAdapter( 0x8, -- facing east
					MultiCompactedBlock( -- bottom
					  {  0,   0,   0,   0,  -3,  -7, -- mid part
					   -16,   0,   0,   0,   0,  -7, -- south rest
					     0,   0,   0, -16,   0,  -7, -- west rest
					     0, -16,   0,   0,   0,  -7 }, -- north rest
					  BTEX("bed_feet_end"), TransparentTexture(), BTEX("bed_feet_side", 'flip_x'), BTEX("bed_feet_side"), BTEX("planks_oak", 'rotate_270'), BTEX("bed_feet_top", 'flip_y') ),
					MultiCompactedBlock( -- top
					  {  0,   0,   0,   0,  -3,  -7, -- mid part
					     0, -16,   0,   0,   0,  -7, -- north rest
					     0,   0, -16,   0,   0,  -7, -- east rest
					   -16,   0,   0,   0,   0,  -7 }, -- south rest
					  TransparentTexture(), BTEX("bed_head_end"), BTEX("bed_head_side", 'flip_x'), BTEX("bed_head_side"), BTEX("planks_oak", 'rotate_270'), BTEX("bed_head_top", 'flip_y') ) ) );
		[27]  = DataAdapter( 0x8, -- Powered Rails
		          Rail( BTEX("rail_golden") ), -- not powered
		          Rail( BTEX("rail_golden_powered") ) ); -- powered
		[28]  = DataAdapter( 0x8, -- Detector Rails
		          Rail( BTEX("rail_detector") ), -- not powered
		          Rail( BTEX("rail_detector_powered") ) ); -- powered
		[29]  = DataAdapter( 0x8, -- Sticky Piston
		          DataAdapter( 0x7, -- unpowered
					OpaqueBlock( BTEX("piston_side", 'rotate_180'), BTEX("piston_side", 'rotate_180'), BTEX("piston_side", 'rotate_180'), BTEX("piston_side", 'rotate_180'), BTEX("piston_top_sticky", 'rotate_180'), BTEX("piston_bottom") ), -- facing down
					OpaqueBlock( BTEX("piston_side"), BTEX("piston_side"), BTEX("piston_side"), BTEX("piston_side"), BTEX("piston_bottom"), BTEX("piston_top_sticky", 'rotate_180') ), -- facing up
					OpaqueBlock( BTEX("piston_side", 'rotate_90'), BTEX("piston_side", 'rotate_270'), BTEX("piston_top_sticky"), BTEX("piston_bottom"), BTEX("piston_side", 'rotate_180'), BTEX("piston_side") ), -- facing north
					OpaqueBlock( BTEX("piston_side", 'rotate_270'), BTEX("piston_side", 'rotate_90'), BTEX("piston_bottom"), BTEX("piston_top_sticky"), BTEX("piston_side"), BTEX("piston_side", 'rotate_180') ), -- facing south
					OpaqueBlock( BTEX("piston_top_sticky"), BTEX("piston_bottom"), BTEX("piston_side", 'rotate_270'), BTEX("piston_side", 'rotate_90'), BTEX("piston_side", 'rotate_90'), BTEX("piston_side", 'rotate_90') ), -- facing west
					OpaqueBlock( BTEX("piston_bottom"), BTEX("piston_top_sticky"), BTEX("piston_side", 'rotate_90'), BTEX("piston_side", 'rotate_270'), BTEX("piston_side", 'rotate_270'), BTEX("piston_side", 'rotate_270') ), -- facing east
					0, 0 ),
				  DataAdapter( 0x7, -- powered
					MultiCompactedBlock( -- facing down
		              {   0,   0,   0,   0,  -4,   0, -- base
		                 -6,  -6,  -6,  -6,   0, -12 }, -- pole
		              BTEX("modified_piston_side", 'rotate_180'), BTEX("piston_inner", 'rotate_180'), BTEX("piston_bottom") ),
					MultiCompactedBlock( -- facing up
		              {   0,   0,   0,   0,   0,  -4, -- base
		                 -6,  -6,  -6,  -6, -12,   0 }, -- pole
		              BTEX("modified_piston_side"), BTEX("piston_bottom"), BTEX("piston_inner", 'rotate_180') ),
					MultiCompactedBlock( -- facing north
		              {  -4,   0,   0,   0,   0,   0, -- base
		                  0, -12,  -6,  -6,  -6,  -6 }, -- pole
		              BTEX("modified_piston_side", 'rotate_90'), BTEX("modified_piston_side", 'rotate_270'), BTEX("piston_inner"), BTEX("piston_bottom"), BTEX("modified_piston_side", 'rotate_180'), BTEX("modified_piston_side") ),
					MultiCompactedBlock( -- facing south
		              {   0,  -4,   0,   0,   0,   0, -- base
		                -12,   0,  -6,  -6,  -6,  -6 }, -- pole
		              BTEX("modified_piston_side", 'rotate_270'), BTEX("modified_piston_side", 'rotate_90'), BTEX("piston_bottom"), BTEX("piston_inner"), BTEX("modified_piston_side"), BTEX("modified_piston_side", 'rotate_180') ),
					MultiCompactedBlock( -- facing west
		              {   0,   0,  -4,   0,   0,   0, -- base
		                 -6,  -6,   0, -12,  -6,  -6 }, -- pole
		              BTEX("piston_inner"), BTEX("piston_bottom"), BTEX("modified_piston_side", 'rotate_270'), BTEX("modified_piston_side", 'rotate_90'), BTEX("modified_piston_side", 'rotate_90'), BTEX("modified_piston_side", 'rotate_90') ),
					MultiCompactedBlock( -- facing east
		              {   0,   0,   0,  -4,   0,   0, -- base
		                 -6,  -6, -12,   0,  -6,  -6 }, -- pole
		              BTEX("piston_bottom"), BTEX("piston_inner"), BTEX("modified_piston_side", 'rotate_90'), BTEX("modified_piston_side", 'rotate_270'), BTEX("modified_piston_side", 'rotate_270'), BTEX("modified_piston_side", 'rotate_270') ),
					0, 0 ) );
		[30]  = XShapedBlock( BTEX("web") ); -- Web
		[31]  = DataAdapter( 0x3, -- Tall Grass
		          XShapedBlock( BTEX("deadbush") ), -- dead bush like
		          BiomeXShapedBlock( 0, BTEX("tallgrass") ), -- tall grass
		          BiomeXShapedBlock( 0, BTEX("fern") ), 0 ); -- fern
		[32]  = XShapedBlock( BTEX("deadbush") ), -- Dead Bush
		[33]  = DataAdapter( 0x8, -- Regular Piston
		          DataAdapter( 0x7, -- unpowered
					OpaqueBlock( BTEX("piston_side", 'rotate_180'), BTEX("piston_side", 'rotate_180'), BTEX("piston_side", 'rotate_180'), BTEX("piston_side", 'rotate_180'), BTEX("piston_top_normal", 'rotate_180'), BTEX("piston_bottom") ), -- facing down
					OpaqueBlock( BTEX("piston_side"), BTEX("piston_side"), BTEX("piston_side"), BTEX("piston_side"), BTEX("piston_bottom"), BTEX("piston_top_normal", 'rotate_180') ), -- facing up
					OpaqueBlock( BTEX("piston_side", 'rotate_90'), BTEX("piston_side", 'rotate_270'), BTEX("piston_top_normal"), BTEX("piston_bottom"), BTEX("piston_side", 'rotate_180'), BTEX("piston_side") ), -- facing north
					OpaqueBlock( BTEX("piston_side", 'rotate_270'), BTEX("piston_side", 'rotate_90'), BTEX("piston_bottom"), BTEX("piston_top_normal"), BTEX("piston_side"), BTEX("piston_side", 'rotate_180') ), -- facing south
					OpaqueBlock( BTEX("piston_top_normal"), BTEX("piston_bottom"), BTEX("piston_side", 'rotate_270'), BTEX("piston_side", 'rotate_90'), BTEX("piston_side", 'rotate_90'), BTEX("piston_side", 'rotate_90') ), -- facing west
					OpaqueBlock( BTEX("piston_bottom"), BTEX("piston_top_normal"), BTEX("piston_side", 'rotate_90'), BTEX("piston_side", 'rotate_270'), BTEX("piston_side", 'rotate_270'), BTEX("piston_side", 'rotate_270') ), -- facing east
					0, 0 ),
				  DataAdapter( 0x7, -- powered
					MultiCompactedBlock( -- facing down
		              {   0,   0,   0,   0,  -4,   0, -- base
		                 -6,  -6,  -6,  -6,   0, -12 }, -- pole
		              BTEX("modified_piston_side", 'rotate_180'), BTEX("piston_inner", 'rotate_180'), BTEX("piston_bottom") ),
					MultiCompactedBlock( -- facing up
		              {   0,   0,   0,   0,   0,  -4, -- base
		                 -6,  -6,  -6,  -6, -12,   0 }, -- pole
		              BTEX("modified_piston_side"), BTEX("piston_bottom"), BTEX("piston_inner", 'rotate_180') ),
					MultiCompactedBlock( -- facing north
		              {  -4,   0,   0,   0,   0,   0, -- base
		                  0, -12,  -6,  -6,  -6,  -6 }, -- pole
		              BTEX("modified_piston_side", 'rotate_90'), BTEX("modified_piston_side", 'rotate_270'), BTEX("piston_inner"), BTEX("piston_bottom"), BTEX("modified_piston_side", 'rotate_180'), BTEX("modified_piston_side") ),
					MultiCompactedBlock( -- facing south
		              {   0,  -4,   0,   0,   0,   0, -- base
		                -12,   0,  -6,  -6,  -6,  -6 }, -- pole
		              BTEX("modified_piston_side", 'rotate_270'), BTEX("modified_piston_side", 'rotate_90'), BTEX("piston_bottom"), BTEX("piston_inner"), BTEX("modified_piston_side"), BTEX("modified_piston_side", 'rotate_180') ),
					MultiCompactedBlock( -- facing west
		              {   0,   0,  -4,   0,   0,   0, -- base
		                 -6,  -6,   0, -12,  -6,  -6 }, -- pole
		              BTEX("piston_inner"), BTEX("piston_bottom"), BTEX("modified_piston_side", 'rotate_270'), BTEX("modified_piston_side", 'rotate_90'), BTEX("modified_piston_side", 'rotate_90'), BTEX("modified_piston_side", 'rotate_90') ),
					MultiCompactedBlock( -- facing east
		              {   0,   0,   0,  -4,   0,   0, -- base
		                 -6,  -6, -12,   0,  -6,  -6 }, -- pole
		              BTEX("piston_bottom"), BTEX("piston_inner"), BTEX("modified_piston_side", 'rotate_90'), BTEX("modified_piston_side", 'rotate_270'), BTEX("modified_piston_side", 'rotate_270'), BTEX("modified_piston_side", 'rotate_270') ),
				  0, 0 ) );
		[34]  = DataAdapter( 0x8, -- Piston Extension
		          DataAdapter( 0x7, -- regular piston
					 MultiCompactedBlock( -- facing down
		              {   0,   0,   0,   0,   0, -12, -- plate
		                 -6,  -6,  -6,  -6,  -4,   0 }, -- pole
		              BTEX("modified_piston_arm_side", 'rotate_180'), BTEX("piston_top_normal", 'rotate_180'), BTEX("piston_top_normal") ),
					 MultiCompactedBlock( -- facing up
		              {   0,   0,   0,   0, -12,   0, -- plate
		                 -6,  -6,  -6,  -6,   0,  -4 }, -- pole
		              BTEX("modified_piston_arm_side"), BTEX("piston_top_normal"), BTEX("piston_top_normal", 'rotate_180') ),
					 MultiCompactedBlock( -- facing north
		              {   0, -12,   0,   0,   0,   0, -- plate
		                 -4,   0,  -6,  -6,  -6,  -6 }, -- pole
		              BTEX("modified_piston_arm_side", 'rotate_90'), BTEX("modified_piston_arm_side", 'rotate_270'), BTEX("piston_top_normal"), BTEX("piston_top_normal"), BTEX("modified_piston_arm_side", 'rotate_180'), BTEX("modified_piston_arm_side") ),
					 MultiCompactedBlock( -- facing south
		              { -12,   0,   0,   0,   0,   0, -- plate
		                  0,  -4,  -6,  -6,  -6,  -6 }, -- pole
		              BTEX("modified_piston_arm_side", 'rotate_270'), BTEX("modified_piston_arm_side", 'rotate_90'), BTEX("piston_top_normal"), BTEX("piston_top_normal"), BTEX("modified_piston_arm_side"), BTEX("modified_piston_arm_side", 'rotate_180') ),
					 MultiCompactedBlock( -- facing west
		              {   0,   0,   0, -12,   0,   0, -- plate
		                 -6,  -6,  -4,   0,  -6,  -6 }, -- pole
		              BTEX("piston_top_normal"), BTEX("piston_top_normal"), BTEX("modified_piston_arm_side", 'rotate_270'), BTEX("modified_piston_arm_side", 'rotate_90'), BTEX("modified_piston_arm_side", 'rotate_90'), BTEX("modified_piston_arm_side", 'rotate_90') ),
					 MultiCompactedBlock( -- facing east
		              {   0,   0, -12,   0,   0,   0, -- plate
		                 -6,  -6,   0,  -4,  -6,  -6 }, -- pole
		              BTEX("piston_top_normal"), BTEX("piston_top_normal"), BTEX("modified_piston_arm_side", 'rotate_90'), BTEX("modified_piston_arm_side", 'rotate_270'), BTEX("modified_piston_arm_side", 'rotate_270'), BTEX("modified_piston_arm_side", 'rotate_270') ),
					0, 0 ),
				  DataAdapter( 0x7, -- sticky piston
					 MultiCompactedBlock( -- facing down
		              {   0,   0,   0,   0,   0, -12, -- plate
		                 -6,  -6,  -6,  -6,  -4,   0 }, -- pole
		              BTEX("modified_piston_arm_side", 'rotate_180'), BTEX("piston_top_sticky", 'rotate_180'), BTEX("piston_top_normal") ),
					 MultiCompactedBlock( -- facing up
		              {   0,   0,   0,   0, -12,   0, -- plate
		                 -6,  -6,  -6,  -6,   0,  -4 }, -- pole
		              BTEX("modified_piston_arm_side"), BTEX("piston_top_normal"), BTEX("piston_top_sticky", 'rotate_180') ),
					 MultiCompactedBlock( -- facing north
		              {   0, -12,   0,   0,   0,   0, -- plate
		                 -4,   0,  -6,  -6,  -6,  -6 }, -- pole
		              BTEX("modified_piston_arm_side", 'rotate_90'), BTEX("modified_piston_arm_side", 'rotate_270'), BTEX("piston_top_sticky"), BTEX("piston_top_normal"), BTEX("modified_piston_arm_side", 'rotate_180'), BTEX("modified_piston_arm_side") ),
					 MultiCompactedBlock( -- facing south
		              { -12,   0,   0,   0,   0,   0, -- plate
		                  0,  -4,  -6,  -6,  -6,  -6 }, -- pole
		              BTEX("modified_piston_arm_side", 'rotate_270'), BTEX("modified_piston_arm_side", 'rotate_90'), BTEX("piston_top_normal"), BTEX("piston_top_sticky"), BTEX("modified_piston_arm_side"), BTEX("modified_piston_arm_side", 'rotate_180') ),
					 MultiCompactedBlock( -- facing west
		              {   0,   0,   0, -12,   0,   0, -- plate
		                 -6,  -6,  -4,   0,  -6,  -6 }, -- pole
		              BTEX("piston_top_sticky"), BTEX("piston_top_normal"), BTEX("modified_piston_arm_side", 'rotate_270'), BTEX("modified_piston_arm_side", 'rotate_90'), BTEX("modified_piston_arm_side", 'rotate_90'), BTEX("modified_piston_arm_side", 'rotate_90') ),
					 MultiCompactedBlock( -- facing east
		              {   0,   0, -12,   0,   0,   0, -- plate
		                 -6,  -6,   0,  -4,  -6,  -6 }, -- pole
		              BTEX("piston_top_normal"), BTEX("piston_top_sticky"), BTEX("modified_piston_arm_side", 'rotate_90'), BTEX("modified_piston_arm_side", 'rotate_270'), BTEX("modified_piston_arm_side", 'rotate_270'), BTEX("modified_piston_arm_side", 'rotate_270') ),
					0, 0 ) );
		[35]  = DataAdapter( 0xf, -- Wool
		          OpaqueBlock( BTEX("wool_colored_white") ), -- white
		          OpaqueBlock( BTEX("wool_colored_orange") ), -- orange
		          OpaqueBlock( BTEX("wool_colored_magenta") ), -- magenta
		          OpaqueBlock( BTEX("wool_colored_light_blue") ), -- light blue
		          OpaqueBlock( BTEX("wool_colored_yellow") ), -- yellow
		          OpaqueBlock( BTEX("wool_colored_lime") ), -- lime
		          OpaqueBlock( BTEX("wool_colored_pink") ), -- pink
		          OpaqueBlock( BTEX("wool_colored_gray") ), -- grey
		          OpaqueBlock( BTEX("wool_colored_silver") ), -- light grey	
		          OpaqueBlock( BTEX("wool_colored_cyan") ), -- cyan
		          OpaqueBlock( BTEX("wool_colored_purple") ), -- purple
		          OpaqueBlock( BTEX("wool_colored_blue") ), -- blue
		          OpaqueBlock( BTEX("wool_colored_brown") ), -- brown
		          OpaqueBlock( BTEX("wool_colored_green") ), -- green
		          OpaqueBlock( BTEX("wool_colored_red") ), -- red
		          OpaqueBlock( BTEX("wool_colored_black") ) ); -- black
		[37]  = XShapedBlock( BTEX("flower_dandelion") ); -- Dandelion
		[38]  = DataAdapter( 0xf, -- Flowers
		          XShapedBlock( BTEX("flower_rose") ), -- poppy
				  XShapedBlock( BTEX("flower_blue_orchid") ), -- blue orchid
				  XShapedBlock( BTEX("flower_allium") ), -- allium
				  XShapedBlock( BTEX("flower_houstonia") ), -- azure bluet
				  XShapedBlock( BTEX("flower_tulip_red") ), -- red tulip
				  XShapedBlock( BTEX("flower_tulip_orange") ), -- orange tulip
				  XShapedBlock( BTEX("flower_tulip_white") ), -- white tulip
				  XShapedBlock( BTEX("flower_tulip_pink") ), -- pink tulip
				  XShapedBlock( BTEX("flower_oxeye_daisy") ), -- oxeye daisy
				  0, 0, 0, 0, 0, 0, 0 );
		[39]  = XShapedBlock( BTEX("mushroom_brown") ); -- Brown Mushroom
		[40]  = XShapedBlock( BTEX("mushroom_red") ); -- Red Mushroom
		[41]  = OpaqueBlock( BTEX("gold_block") ); -- Gold block
		[42]  = OpaqueBlock( BTEX("iron_block") ); -- Iron block
		[43]  = DataAdapter( 0x7, -- Double Slab
		          DataAdapter(0x8, -- Stone
					OpaqueBlock( BTEX("stone_slab_side"), BTEX("stone_slab_top") ), -- stone double slab
					OpaqueBlock( BTEX("stone_slab_top") ) ), -- smooth stone slab
		          DataAdapter(0x8, -- Sandstone
					OpaqueBlock( BTEX("sandstone_normal"), BTEX("sandstone_bottom"), BTEX("sandstone_top") ), -- sandstone double slab
					OpaqueBlock( BTEX("sandstone_top") ) ), -- smooth sandstone slab
		          OpaqueBlock( BTEX("planks_oak") ), -- wooden planks
		          OpaqueBlock( BTEX("cobblestone") ), -- cobblestone
		          OpaqueBlock( BTEX("brick") ), -- brick
		          OpaqueBlock( BTEX("stonebrick") ), -- stone brick
				  OpaqueBlock( BTEX("nether_brick") ), -- nether brick
				  OpaqueBlock( BTEX("quartz_block_side"), BTEX("quartz_block_bottom"), BTEX("quartz_block_top") ), -- nether Quartz
		          0, 0 );
		[44]  = DataAdapter( 0x8, -- Slabs
		          DataAdapter( 0x7, -- Regular Slabs
		            Slab( -8, 0, BTEX("stone_slab_side"), BTEX("stone_slab_top") ), -- stone slab
		            Slab( -8, 0, BTEX("sandstone_normal"), BTEX("sandstone_bottom"), BTEX("sandstone_top") ), -- sandstone slab
		            Slab( -8, 0, BTEX("planks_oak") ), -- wooden plank slab
		            Slab( -8, 0, BTEX("cobblestone") ), -- cobblestone slab
		            Slab( -8, 0, BTEX("brick") ), -- brick slab
		            Slab( -8, 0, BTEX("stonebrick") ), -- stone brick
					Slab( -8, 0, BTEX("nether_brick") ), -- nether brick
					Slab( -8, 0, BTEX("quartz_block_side"), BTEX("quartz_block_bottom"), BTEX("quartz_block_top") ), -- quartz slab
		            0, 0 ),
		          DataAdapter( 0x7, -- Upside-down slabs
		            Slab( 0, -8, BTEX("stone_slab_side"), BTEX("stone_slab_top") ), -- stone slab
		            Slab( 0, -8, BTEX("sandstone_normal"), BTEX("sandstone_bottom"), BTEX("sandstone_top") ), -- sandstone slab
		            Slab( 0, -8, BTEX("planks_oak") ), -- wooden plank slab
		            Slab( 0, -8, BTEX("cobblestone") ), -- cobblestone slab
		            Slab( 0, -8, BTEX("brick") ), -- brick slab
		            Slab( 0, -8, BTEX("stonebrick") ), -- stone brick
					Slab( 0, -8, BTEX("nether_brick") ), -- nether brick
					Slab( 0, -8, BTEX("quartz_block_side"), BTEX("quartz_block_bottom"), BTEX("quartz_block_top") ), -- quartz slab
		            0, 0 ) );
		[45]  = OpaqueBlock( BTEX("brick") ); -- Brick
		[46]  = OpaqueBlock( BTEX("tnt_side"), BTEX("tnt_bottom"), BTEX("tnt_top") ); -- TNT
		[47]  = OpaqueBlock( BTEX("bookshelf"), BTEX("planks_oak") ); -- Bookshelf
		[48]  = OpaqueBlock( BTEX("cobblestone_mossy") ); -- Mossy Cobblestone
		[49]  = OpaqueBlock( BTEX("obsidian") ); -- Obsidian
		[50]  = Torch( BTEX("torch_on","clamp") ); -- Torch
		-- [51] -- Fire
		[52]  = HollowOpaqueBlock( BTEX("mob_spawner") ); -- Monster spawner
		[53]  = Stairs( BTEX("planks_oak") ); -- Oak Wood Stairs
		[54]  = DataAdapter( 0x3, -- Chest
				   MultiCompactedBlock( -- facing west
					{ -1,  -1, -1,  -1,  0, -2, -- box
					  -7,  -7,  0, -15, -7, -5 }, -- buckle
		            BTEX ("chest_normal_front"), BTEX ("chest_normal_back"), BTEX ("chest_normal_left"), BTEX ("chest_normal_right"), BTEX ("chest_normal_bottom", 'rotate_270'), BTEX ("chest_normal_top", 'rotate_270') ),
		          MultiCompactedBlock( -- facing east
					{ -1,  -1,  -1, -1,  0, -2, -- box
					  -7,  -7, -15,  0, -7, -5 }, -- buckle
		            BTEX("chest_normal_back"), BTEX ("chest_normal_front"), BTEX ("chest_normal_right"), BTEX ("chest_normal_left"), BTEX ("chest_normal_bottom", 'rotate_90'), BTEX ("chest_normal_top", 'rotate_90') ),
		          MultiCompactedBlock( -- facing north
					{ -1,  -1, -1, -1,  0, -2, -- box
					   0, -15, -7, -7, -7, -5 }, -- buckle
		            BTEX("chest_normal_right"), BTEX ("chest_normal_left"), BTEX ("chest_normal_front"), BTEX ("chest_normal_back"), BTEX ("chest_normal_bottom"), BTEX ("chest_normal_top", 'rotate_180') ),
		          MultiCompactedBlock( -- facing south
					{  -1, -1, -1, -1,  0, -2, -- box
					  -15,  0, -7, -7, -7, -5 }, -- buckle
		            BTEX("chest_normal_left"), BTEX ("chest_normal_right"), BTEX ("chest_normal_back"), BTEX ("chest_normal_front"), BTEX ("chest_normal_bottom", 'rotate_180'), BTEX ("chest_normal_top") ) );
		-- [55] -- Redstone Wire
		[56]  = OpaqueBlock( BTEX("diamond_ore") ); -- Diamond Ore
		[57]  = OpaqueBlock( BTEX("diamond_block") ); -- Diamond Block
		[58]  = OpaqueBlock( BTEX("crafting_table_front"), BTEX("crafting_table_side"), BTEX("planks_oak"), BTEX("crafting_table_top") ); -- Crafting Table
		[59]  = DataAdapter( 0x7, -- Wheat Crops
		          HashShapedBlock( -4, BTEX("wheat_stage_0"), 0 ), -- growthstate 0
		          HashShapedBlock( -4, BTEX("wheat_stage_1"), 0 ), -- growthstate 1
		          HashShapedBlock( -4, BTEX("wheat_stage_2"), 0 ), -- growthstate 2
		          HashShapedBlock( -4, BTEX("wheat_stage_3"), 0 ), -- growthstate 3
		          HashShapedBlock( -4, BTEX("wheat_stage_4"), 0 ), -- growthstate 4
		          HashShapedBlock( -4, BTEX("wheat_stage_5"), 0 ), -- growthstate 5
		          HashShapedBlock( -4, BTEX("wheat_stage_6"), 0 ), -- growthstate 6
		          HashShapedBlock( -4, BTEX("wheat_stage_7"), 0 ) ); -- growthstate 7 
		[60]  = DataAdapter( 0x7, -- Farmland
		          CompactedBlock( 0, 0, 0, 0, 0, -1, BTEX("dirt"), BTEX("dirt"), BTEX("farmland_dry") ), -- not hydrated, moisture level 0
		          CompactedBlock( 0, 0, 0, 0, 0, -1, BTEX("dirt"), BTEX("dirt"), BTEX("farmland_dry") ), -- not hydrated, moisture level 1
		          CompactedBlock( 0, 0, 0, 0, 0, -1, BTEX("dirt"), BTEX("dirt"), BTEX("farmland_dry") ), -- not hydrated, moisture level 2
		          CompactedBlock( 0, 0, 0, 0, 0, -1, BTEX("dirt"), BTEX("dirt"), BTEX("farmland_dry") ), -- not hydrated, moisture level 3
		          CompactedBlock( 0, 0, 0, 0, 0, -1, BTEX("dirt"), BTEX("dirt"), BTEX("farmland_dry") ), -- not hydrated, moisture level 4
		          CompactedBlock( 0, 0, 0, 0, 0, -1, BTEX("dirt"), BTEX("dirt"), BTEX("farmland_dry") ), -- not hydrated, moisture level 5
		          CompactedBlock( 0, 0, 0, 0, 0, -1, BTEX("dirt"), BTEX("dirt"), BTEX("farmland_dry") ), -- not hydrated, moisture level 6
		          CompactedBlock( 0, 0, 0, 0, 0, -1, BTEX("dirt"), BTEX("dirt"), BTEX("farmland_wet") ) ); -- hydrated, moisture level 7
		[61]  = DataAdapter( 0x3, -- Furnace
		          OpaqueBlock( BTEX("furnace_front_off"), BTEX("furnace_side"), BTEX("furnace_side"), BTEX("furnace_side"), BTEX("furnace_top", 'rotate_270'), BTEX("furnace_top", 'rotate_90') ), -- facing west
		          OpaqueBlock( BTEX("furnace_side"), BTEX("furnace_front_off"), BTEX("furnace_side"), BTEX("furnace_side"), BTEX("furnace_top", 'rotate_90'), BTEX("furnace_top", 'rotate_270') ), -- facing east
		          OpaqueBlock( BTEX("furnace_side"), BTEX("furnace_side"), BTEX("furnace_front_off"), BTEX("furnace_side"), BTEX("furnace_top"), BTEX("furnace_top") ), -- facing north
		          OpaqueBlock( BTEX("furnace_side"), BTEX("furnace_side"), BTEX("furnace_side"), BTEX("furnace_front_off"), BTEX("furnace_top", 'rotate_180'), BTEX("furnace_top", 'rotate_180') ) ); -- facing south
		[62]  = DataAdapter( 0x3, -- Burning Furnace
		          OpaqueBlock( BTEX("furnace_front_on"), BTEX("furnace_side"), BTEX("furnace_side"), BTEX("furnace_side"), BTEX("furnace_top", 'rotate_270'), BTEX("furnace_top", 'rotate_90') ), -- facing west
		          OpaqueBlock( BTEX("furnace_side"), BTEX("furnace_front_on"), BTEX("furnace_side"), BTEX("furnace_side"), BTEX("furnace_top", 'rotate_90'), BTEX("furnace_top", 'rotate_270') ), -- facing east
		          OpaqueBlock( BTEX("furnace_side"), BTEX("furnace_side"), BTEX("furnace_front_on"), BTEX("furnace_side"), BTEX("furnace_top"), BTEX("furnace_top") ), -- facing north
		          OpaqueBlock( BTEX("furnace_side"), BTEX("furnace_side"), BTEX("furnace_side"), BTEX("furnace_front_on"), BTEX("furnace_top", 'rotate_180'), BTEX("furnace_top", 'rotate_180') ) ); -- facing south
		-- [63] -- Sign Post
		[64]  = Door( BTEX("door_wood_lower"), BTEX("door_wood_upper") ); -- Oak Wood Door
		[65]  = FacingAdapter( false, HashShapedBlock( -15, BTEX("ladder") ) ); -- Ladder
		[66]  = Rail( BTEX("rail_normal"), BTEX("rail_normal_turned") ); -- Rails
		[67]  = Stairs( BTEX("cobblestone") ); -- Cobblestone Stairs
		[68]  = DataAdapter( 0x7, -- Wall Sign
		          CompactedBlock( 0, 0, -14, 0, -4, -4, unpack( SignTextures( 0 ) ) ), -- north
		          0, 0,
		          CompactedBlock( 0, 0, 0, -14, -4, -4, unpack( SignTextures( 2 ) ) ), -- south
		          CompactedBlock( -14, 0, 0, 0, -4, -4, unpack( SignTextures( 1 ) ) ), -- west
		          CompactedBlock( 0, -14, 0, 0, -4, -4, unpack( SignTextures( 3 ) ) ), -- east
		          0, 0 );
		-- [69] -- Lever
		[70]  = CompactedBlock( -1, -1, -1, -1, 0, -15, BTEX("stone") ); -- Stone Pressure Plate
		[71]  = Door( BTEX("door_iron_lower"), BTEX("door_iron_upper") ); -- Iron Door
		[72]  = CompactedBlock( -1, -1, -1, -1, 0, -15, BTEX("planks_oak") ); -- Wooden Pressure plate
		[73]  = OpaqueBlock( BTEX("redstone_ore") ); -- Redstone Ore
		[74]  = OpaqueBlock( BTEX("redstone_ore") ); -- Glowing Redstone Ore
		[75]  = Torch( BTEX("redstone_torch_off", "clamp") ); -- Redstone Torch (off)
		[76]  = Torch( BTEX("redstone_torch_on", "clamp") ); -- Redstone Torch (on)
		[77]  = DataAdapter( 0x7 + 0x8, -- Stone Button
		          CompactedBlock( -5, -5, -6, -6, -14, 0, BTEX("stone") ), -- off, bottom
				  CompactedBlock( 0, -14, -5, -5, -6, -6, BTEX("stone") ), -- off, east
		          CompactedBlock( -14, 0, -5, -5, -6, -6, BTEX("stone") ), -- off, west
				  CompactedBlock( -5, -5, 0, -14, -6, -6, BTEX("stone") ), -- off, south
				  CompactedBlock( -5, -5, -14, 0, -6, -6, BTEX("stone") ), -- off, north
				  CompactedBlock( -5, -5, -6, -6, 0, -14, BTEX("stone") ), -- off, top
				  0, 0,
		          CompactedBlock( -5, -5, -6, -6, -15, 0, BTEX("stone") ), -- on, bottom
				  CompactedBlock( 0, -15, -5, -5, -6, -6, BTEX("stone") ), -- on, east
		          CompactedBlock( -15, 0, -5, -5, -6, -6, BTEX("stone") ), -- on, west
				  CompactedBlock( -5, -5, 0, -15, -6, -6, BTEX("stone") ), -- on, south
		          CompactedBlock( -5, -5, -15, 0, -6, -6, BTEX("stone") ), -- on, north
		          CompactedBlock( -5, -5, -6, -6, 0, -15, BTEX("stone") ), -- on, top
				  0, 0 );
		[78]  = DataAdapter( 0x7, -- Snow
		          Slab( -14, 0, BTEX("snow") ), -- 1 layer
		          Slab( -12, 0, BTEX("snow") ), -- 2 layer
		          Slab( -10, 0, BTEX("snow") ), -- 3 layer
		          Slab( -8, 0, BTEX("snow") ), -- 4 layer
		          Slab( -6, 0, BTEX("snow") ), -- 5 layer
		          Slab( -4, 0, BTEX("snow") ), -- 6 layer
		          Slab( -2, 0, BTEX("snow") ), -- 7 layer
		          OpaqueBlock( BTEX("snow") ) ); -- 8 layer/block
		[79]  = DelayRender( TransparentBlock( 0, BTEX("ice") ), 5 ); -- Ice
		[80]  = OpaqueBlock( BTEX("snow") ); -- Snow Block
		[81]  = HashShapedBlock( -1, BTEX("cactus_side"), BTEX("cactus_bottom"), BTEX("cactus_top") ); -- Cactus
		[82]  = OpaqueBlock( BTEX("clay") ); -- Clay
		[83]  = XShapedBlock( BTEX("reeds") ); -- Sugar Cane
		[84]  = OpaqueBlock( BTEX("noteblock"), BTEX("noteblock"), BTEX("jukebox_top") ); -- Jukebox
		[85]  = Fence( BTEX("planks_oak") ); -- Oak Wood Fence
		[86]  = DataAdapter( 0x3, -- Pumpkin
		          OpaqueBlock( BTEX("pumpkin_side"), BTEX("pumpkin_side"), BTEX("pumpkin_side"), BTEX("pumpkin_face_off"), BTEX("pumpkin_top", 'rotate_180'), BTEX("pumpkin_top", 'rotate_180') ), -- facing south
		          OpaqueBlock( BTEX("pumpkin_face_off"), BTEX("pumpkin_side"), BTEX("pumpkin_side"), BTEX("pumpkin_side"), BTEX("pumpkin_top", 'rotate_270'), BTEX("pumpkin_top", 'rotate_90') ), -- facing west
		          OpaqueBlock( BTEX("pumpkin_side"), BTEX("pumpkin_side"), BTEX("pumpkin_face_off"), BTEX("pumpkin_side"), BTEX("pumpkin_top"), BTEX("pumpkin_top") ), -- facing north
		          OpaqueBlock( BTEX("pumpkin_side"), BTEX("pumpkin_face_off"), BTEX("pumpkin_side"), BTEX("pumpkin_side"), BTEX("pumpkin_top", 'rotate_90'), BTEX("pumpkin_top", 'rotate_270') ) ); -- facing 
		[87]  = OpaqueBlock( BTEX("netherrack") ); -- Netherrack
		[88]  = OpaqueBlock( BTEX("soul_sand") ); -- Soul Sand
		[89]  = OpaqueBlock( BTEX("glowstone") ); -- Glowstone Block
		[90]  = DelayRender( Portal( BTEX("portal") ), 10 ); -- Portal
		[91]  = DataAdapter( 0x3, -- Jack-o-lantern
		          OpaqueBlock( BTEX("pumpkin_side"), BTEX("pumpkin_side"), BTEX("pumpkin_side"), BTEX("pumpkin_face_on"), BTEX("pumpkin_top", 'rotate_180'), BTEX("pumpkin_top", 'rotate_180') ), -- facing south
		          OpaqueBlock( BTEX("pumpkin_face_on"), BTEX("pumpkin_side"), BTEX("pumpkin_side"), BTEX("pumpkin_side"), BTEX("pumpkin_top", 'rotate_270'), BTEX("pumpkin_top", 'rotate_90') ), -- facing west
		          OpaqueBlock( BTEX("pumpkin_side"), BTEX("pumpkin_side"), BTEX("pumpkin_face_on"), BTEX("pumpkin_side"), BTEX("pumpkin_top"), BTEX("pumpkin_top") ), -- facing north
		          OpaqueBlock( BTEX("pumpkin_side"), BTEX("pumpkin_face_on"), BTEX("pumpkin_side"), BTEX("pumpkin_side"), BTEX("pumpkin_top", 'rotate_90'), BTEX("pumpkin_top", 'rotate_270') ) ); -- facing east
		[92]  = DataAdapter( 0x7, -- Cake
		          CompactedBlock( -1, -1, -1, -1, 0, -8, BTEX("cake_side"), BTEX("cake_bottom"), BTEX("cake_top") ), -- full cake
		          CompactedBlock( -3, -1, -1, -1, 0, -8, BTEX("cake_inner"), BTEX("cake_side"), BTEX("cake_side"), BTEX("cake_side"), BTEX("cake_bottom"), BTEX("cake_top") ), -- eaten 1
		          CompactedBlock( -5, -1, -1, -1, 0, -8, BTEX("cake_inner"), BTEX("cake_side"), BTEX("cake_side"), BTEX("cake_side"), BTEX("cake_bottom"), BTEX("cake_top") ), -- eaten 2
		          CompactedBlock( -7, -1, -1, -1, 0, -8, BTEX("cake_inner"), BTEX("cake_side"), BTEX("cake_side"), BTEX("cake_side"), BTEX("cake_bottom"), BTEX("cake_top") ), -- eaten 3
		          CompactedBlock( -9, -1, -1, -1, 0, -8, BTEX("cake_inner"), BTEX("cake_side"), BTEX("cake_side"), BTEX("cake_side"), BTEX("cake_bottom"), BTEX("cake_top") ), -- eaten 4
		          CompactedBlock( -11, -1, -1, -1, 0, -8, BTEX("cake_inner"), BTEX("cake_side"), BTEX("cake_side"), BTEX("cake_side"), BTEX("cake_bottom"), BTEX("cake_top") ), 0, 0 ); -- eaten 5
		-- [93] -- Redstone repeater (off)
		-- [94] -- Redstone repeater (on)
		[95]  = DataAdapter( 0xf, -- Stained Glass
				  DelayRender( TransparentBlock( 0, BTEX("glass_white") ), 15 ), -- white
				  DelayRender( TransparentBlock( 0, BTEX("glass_orange") ), 15 ), -- orange
				  DelayRender( TransparentBlock( 0, BTEX("glass_magenta") ), 15 ), -- magenta
				  DelayRender( TransparentBlock( 0, BTEX("glass_light_blue") ), 15 ), -- light blue
				  DelayRender( TransparentBlock( 0, BTEX("glass_yellow") ), 15 ), -- yellow
				  DelayRender( TransparentBlock( 0, BTEX("glass_lime") ), 15 ), -- lime
				  DelayRender( TransparentBlock( 0, BTEX("glass_pink") ), 15 ), -- pink
				  DelayRender( TransparentBlock( 0, BTEX("glass_gray") ), 15 ), -- grey
				  DelayRender( TransparentBlock( 0, BTEX("glass_silver") ), 15 ), -- light grey
				  DelayRender( TransparentBlock( 0, BTEX("glass_cyan") ), 15 ), -- cyan
				  DelayRender( TransparentBlock( 0, BTEX("glass_purple") ), 15 ), -- purple
				  DelayRender( TransparentBlock( 0, BTEX("glass_blue") ), 15 ), -- blue				  
				  DelayRender( TransparentBlock( 0, BTEX("glass_brown") ), 15 ), -- brown
				  DelayRender( TransparentBlock( 0, BTEX("glass_green") ), 15 ), -- green
				  DelayRender( TransparentBlock( 0, BTEX("glass_red") ), 15 ), -- red
				  DelayRender( TransparentBlock( 0, BTEX("glass_black") ), 15 ) ); -- black
		[96]  = DataAdapter( 0x8, -- Wooden Trapdoor
		          DataAdapter( 0x4,
		            Slab( -13, 0, BTEX("trapdoor") ), -- bottom
		            DataAdapter( 0x3,
		              CompactedBlock( 0, 0, -13, 0, 0, 0, BTEX("trapdoor") ), -- north
		              CompactedBlock( 0, 0, 0, -13, 0, 0, BTEX("trapdoor") ), -- south
		              CompactedBlock( -13, 0, 0, 0, 0, 0, BTEX("trapdoor") ), -- west
		              CompactedBlock( 0, -13, 0, 0, 0, 0, BTEX("trapdoor") ) ) ), -- east
		          DataAdapter( 0x4,
		            Slab( 0, -13, BTEX("trapdoor") ), -- top
		            DataAdapter( 0x3,
		              CompactedBlock( 0, 0, -13, 0, 0, 0, BTEX("trapdoor") ), -- north
		              CompactedBlock( 0, 0, 0, -13, 0, 0, BTEX("trapdoor") ), -- south
		              CompactedBlock( -13, 0, 0, 0, 0, 0, BTEX("trapdoor") ), -- west
		              CompactedBlock( 0, -13, 0, 0, 0, 0, BTEX("trapdoor") ) ) ) ); -- east
		[97]  = DataAdapter( 0x7, -- Hidden Silverfish
		          OpaqueBlock( BTEX("stone") ), -- stone
		          OpaqueBlock( BTEX("cobblestone") ), -- cobblestone
		          OpaqueBlock( BTEX("stonebrick") ), -- stonebrick
		          OpaqueBlock( BTEX("stonebrick_mossy") ), -- mossy stonebrick
		          OpaqueBlock( BTEX("stonebrick_cracked") ), -- cracked stonebrick
		          OpaqueBlock( BTEX("stonebrick_carved") ),  -- chiseld stonebrick
				  0, 0 );
		[98]  = DataAdapter( 0x3, -- Stone Brick
		          OpaqueBlock( BTEX("stonebrick") ), -- regular
		          OpaqueBlock( BTEX("stonebrick_mossy") ), -- mossy
		          OpaqueBlock( BTEX("stonebrick_cracked") ), -- cracked
		          OpaqueBlock( BTEX("stonebrick_carved") ) ); -- chisled
		[99] = DataAdapter( 0xf, -- Brown Mushroom
		          OpaqueBlock( BTEX("mushroom_block_skin_brown") ), -- pores
		          OpaqueBlock( BTEX("mushroom_block_skin_brown"), BTEX("mushroom_block_inside"), BTEX("mushroom_block_skin_brown"), BTEX("mushroom_block_inside"), BTEX("mushroom_block_inside"), BTEX("mushroom_block_skin_brown") ), -- west + north
		          OpaqueBlock( BTEX("mushroom_block_inside"), BTEX("mushroom_block_inside"), BTEX("mushroom_block_skin_brown"), BTEX("mushroom_block_inside"), BTEX("mushroom_block_inside"), BTEX("mushroom_block_skin_brown") ), -- north
		          OpaqueBlock( BTEX("mushroom_block_inside"), BTEX("mushroom_block_skin_brown"), BTEX("mushroom_block_skin_brown"), BTEX("mushroom_block_inside"), BTEX("mushroom_block_inside"), BTEX("mushroom_block_skin_brown") ), -- east + north
		          OpaqueBlock( BTEX("mushroom_block_skin_brown"), BTEX("mushroom_block_inside"), BTEX("mushroom_block_inside"), BTEX("mushroom_block_inside"), BTEX("mushroom_block_inside"), BTEX("mushroom_block_skin_brown") ), -- west
		          OpaqueBlock( BTEX("mushroom_block_inside"), BTEX("mushroom_block_inside"), BTEX("mushroom_block_skin_brown") ), -- top
		          OpaqueBlock( BTEX("mushroom_block_inside"), BTEX("mushroom_block_skin_brown"), BTEX("mushroom_block_inside"), BTEX("mushroom_block_inside"), BTEX("mushroom_block_inside"), BTEX("mushroom_block_skin_brown") ), -- east
		          OpaqueBlock( BTEX("mushroom_block_skin_brown"), BTEX("mushroom_block_inside"), BTEX("mushroom_block_inside"), BTEX("mushroom_block_skin_brown"), BTEX("mushroom_block_inside"), BTEX("mushroom_block_skin_brown") ), -- west + south
		          OpaqueBlock( BTEX("mushroom_block_inside"), BTEX("mushroom_block_inside"), BTEX("mushroom_block_inside"), BTEX("mushroom_block_skin_brown"), BTEX("mushroom_block_inside"), BTEX("mushroom_block_skin_brown") ), -- south
		          OpaqueBlock( BTEX("mushroom_block_inside"), BTEX("mushroom_block_skin_brown"), BTEX("mushroom_block_inside"), BTEX("mushroom_block_skin_brown"), BTEX("mushroom_block_inside"), BTEX("mushroom_block_skin_brown") ), -- east + south
		          OpaqueBlock( BTEX("mushroom_block_skin_stem"), BTEX("mushroom_block_inside") ), -- stem
		          0, 0, 0, 0, 0 );
		[100] = DataAdapter( 0xf, -- Red Mushroom
		          OpaqueBlock( BTEX("mushroom_block_skin_red") ), -- pores
		          OpaqueBlock( BTEX("mushroom_block_skin_red"), BTEX("mushroom_block_inside"), BTEX("mushroom_block_skin_red"), BTEX("mushroom_block_inside"), BTEX("mushroom_block_inside"), BTEX("mushroom_block_skin_red") ), -- west + north
		          OpaqueBlock( BTEX("mushroom_block_inside"), BTEX("mushroom_block_inside"), BTEX("mushroom_block_skin_red"), BTEX("mushroom_block_inside"), BTEX("mushroom_block_inside"), BTEX("mushroom_block_skin_red") ), -- north
		          OpaqueBlock( BTEX("mushroom_block_inside"), BTEX("mushroom_block_skin_red"), BTEX("mushroom_block_skin_red"), BTEX("mushroom_block_inside"), BTEX("mushroom_block_inside"), BTEX("mushroom_block_skin_red") ), -- east + north
		          OpaqueBlock( BTEX("mushroom_block_skin_red"), BTEX("mushroom_block_inside"), BTEX("mushroom_block_inside"), BTEX("mushroom_block_inside"), BTEX("mushroom_block_inside"), BTEX("mushroom_block_skin_red") ), -- west
		          OpaqueBlock( BTEX("mushroom_block_inside"), BTEX("mushroom_block_inside"), BTEX("mushroom_block_skin_red") ), -- top
		          OpaqueBlock( BTEX("mushroom_block_inside"), BTEX("mushroom_block_skin_red"), BTEX("mushroom_block_inside"), BTEX("mushroom_block_inside"), BTEX("mushroom_block_inside"), BTEX("mushroom_block_skin_red") ), -- east
		          OpaqueBlock( BTEX("mushroom_block_skin_red"), BTEX("mushroom_block_inside"), BTEX("mushroom_block_inside"), BTEX("mushroom_block_skin_red"), BTEX("mushroom_block_inside"), BTEX("mushroom_block_skin_red") ), -- west + south
		          OpaqueBlock( BTEX("mushroom_block_inside"), BTEX("mushroom_block_inside"), BTEX("mushroom_block_inside"), BTEX("mushroom_block_skin_red"), BTEX("mushroom_block_inside"), BTEX("mushroom_block_skin_red") ), -- south
		          OpaqueBlock( BTEX("mushroom_block_inside"), BTEX("mushroom_block_skin_red"), BTEX("mushroom_block_inside"), BTEX("mushroom_block_skin_red"), BTEX("mushroom_block_inside"), BTEX("mushroom_block_skin_red") ), -- east + south
		          OpaqueBlock( BTEX("mushroom_block_skin_stem"), BTEX("mushroom_block_inside") ), -- stem
		          0, 0, 0, 0, 0 );
		-- [101] -- Iron Bars TODO
		[102] = HollowOpaqueBlock( BTEX("glass") ); -- Glass Panes (for now, a solid glass block - TODO)
		[103] = OpaqueBlock( BTEX("melon_side"), BTEX("melon_top") ); -- Melon
		-- [104] -- Pumpkin Stem
		-- [105] -- Melon Stem
		[106] = FaceBitAdapter( BiomeHashShapedBlock( 1, {-15}, BTEX("vine"), BTEX("vine"), 0 ) ); -- Vines
		[107] = FenceGate( BTEX("planks_oak") ); -- Oak Fence Gate
		[108] = Stairs( BTEX("brick") ); -- Brick Stairs
		[109] = Stairs( BTEX("stonebrick") ); -- Stone Brick Stairs
		[110] = TopDifferentAdapter( -- Mycelium
					OpaqueBlock( BTEX("mycelium_side"), BTEX("dirt"), BTEX("mycelium_top") ), -- regular mycelium
					OpaqueBlock( BTEX("grass_side_snowed"), BTEX("dirt"), BTEX("mycelium_top") ), 78 ); -- snowy mycelium
		[111] = BiomeHashShapedBlock( 0, {-15}, 0, 0, BTEX("waterlily") ); -- Lily pad
		[112] = OpaqueBlock( BTEX("nether_brick") ); -- Nether Brick
		[113] = Fence( BTEX("nether_brick") ); -- Nether Brick Fence
		[114] = Stairs( BTEX("nether_brick") ); -- Nether Brick Stairs
		[115] = DataAdapter( 0x3, -- Nether Wart
		          HashShapedBlock( -4, BTEX("nether_wart_stage_0"), 0 ), -- growthstate 0
		          HashShapedBlock( -4, BTEX("nether_wart_stage_1"), 0 ), 1, -- growthstate 1
		          HashShapedBlock( -4, BTEX("nether_wart_stage_2"), 0 ) ); -- growthstate 2
		[116] = Slab( -4, 0, BTEX("enchanting_table_side"), BTEX("enchanting_table_bottom"), BTEX("enchanting_table_top") ); -- Enchantment Table
		-- [117] -- Brewing Stand
		[118] = MultiCompactedBlock( -- Cauldron, TODO: needs 0x3 DataAdapter for water levels
					{   0, -14,   0,   0,  -3,   0, -- north, wall
					    0, -14,   0, -12,   0, -13, -- north, stand west
					    0, -14, -12,   0,   0, -13, -- north, stand east
					    0,   0, -14,   0,  -3,   0, -- east, wall
					    0, -12, -14,   0,   0, -13, -- east, stand north
					  -12,   0, -14,   0,   0, -13, -- east, stand south
					  -14,   0,   0,   0,  -3,   0, -- south, wall
					  -14,   0,   0, -12,   0, -13, -- south, stand west
					  -14,   0, -12,   0,   0, -13, -- south, stand east
						0,   0,   0, -14,  -3,   0, -- west, wall
					    0, -12,   0, -14,   0, -13, -- west, stand north
					  -12,   0,   0, -14,   0, -13, -- west, stand south
					    0,   0,   0,   0,  -3, -12 }, -- floor
		            BTEX("cauldron_side"), BTEX("cauldron_side"), BTEX("cauldron_side"), BTEX("cauldron_side"), BTEX("cauldron_bottom_combined"), BTEX("cauldron_top_combined") );
		[119] = CompactedBlock( 0, 0, 0, 0, -12, -4, SingleColorTexture ( 0, 0, 0, 1 ) ); -- End Portal
		[120] = DataAdapter( 0x4+0x3, -- End Portal Frame
		          CompactedBlock( 0, 0, 0, 0, 0, -3, BTEX("endframe_side"), BTEX("end_stone"), BTEX("endframe_top") ), -- without eye, south
		          CompactedBlock( 0, 0, 0, 0, 0, -3, BTEX("endframe_side"), BTEX("end_stone", 'rotate_90'), BTEX("endframe_top", 'rotate_270') ), -- without eye, west
		          CompactedBlock( 0, 0, 0, 0, 0, -3, BTEX("endframe_side"), BTEX("end_stone", 'rotate_180'), BTEX("endframe_top", 'rotate_180') ), -- without eye, north
		          CompactedBlock( 0, 0, 0, 0, 0, -3, BTEX("endframe_side"), BTEX("end_stone", 'rotate_270'), BTEX("endframe_top", 'rotate_90') ), -- without eye, east
		          MultiCompactedBlock( -- with eye, south
					{  0,  0,  0,  0,   0, -3, -- frame
					  -4, -4, -4, -4, -13,  0 }, -- eye
		            BTEX("endframe_side_eye"), BTEX("end_stone"), BTEX("endframe_top_eye") ),
		          MultiCompactedBlock( -- with eye, west
					{  0,  0,  0,  0,   0, -3, -- frame
					  -4, -4, -4, -4, -13,  0 }, -- eye
		            BTEX("endframe_side_eye"), BTEX("end_stone", 'rotate_90'), BTEX("endframe_top_eye", 'rotate_270') ),
		          MultiCompactedBlock( -- with eye, north
					{  0,  0,  0,  0,   0, -3, -- frame
					  -4, -4, -4, -4, -13,  0 }, -- eye
		            BTEX("endframe_side_eye"), BTEX("end_stone", 'rotate_180'), BTEX("endframe_top_eye", 'rotate_180') ),
		          MultiCompactedBlock( -- with eye, east
					{  0,  0,  0,  0,   0, -3, -- frame
					  -4, -4, -4, -4, -13,  0 }, -- eye
		            BTEX("endframe_side_eye"), BTEX("end_stone", 'rotate_270'), BTEX("endframe_top_eye", 'rotate_90') ) );
		[121] = OpaqueBlock( BTEX("end_stone") ); -- End Stone
		[122] = MultiCompactedBlock( -- Dragon Egg
		          { -6, -6, -6, -6, -15,   0,
		            -5, -5, -5, -5, -14,  -1,
		            -4, -4, -4, -4, -13,  -2,
		            -3, -3, -3, -3, -11,  -3,
		            -2, -2, -2, -2,  -8,  -5,
		            -1, -1, -1, -1,  -3,  -8,
		            -3, -3, -3, -3,  -1, -13,
		            -6, -6, -6, -6,   0, -15}, -- egg
		          BTEX("dragon_egg") );
		[123] = OpaqueBlock( BTEX("redstone_lamp_off") ); -- Redstone Lamp (off)
		[124] = OpaqueBlock( BTEX("redstone_lamp_on") ); -- Redstone Lamp (on)
		[125] = DataAdapter( 0x7, -- Wooden Double-Slab
		          OpaqueBlock( BTEX("planks_oak") ), -- oak
		          OpaqueBlock( BTEX("planks_spruce") ), -- spruce
		          OpaqueBlock( BTEX("planks_birch") ), -- birch
		          OpaqueBlock( BTEX("planks_jungle") ), -- jungle
		          OpaqueBlock( BTEX("planks_acacia") ), -- acacia
		          OpaqueBlock( BTEX("planks_big_oak") ), -- dark oak
				  0, 0 );
		[126] = DataAdapter( 0x7+0x8, -- Wooden Slab
		          Slab( -8, 0, BTEX("planks_oak") ), -- bottom, oak
		          Slab( -8, 0, BTEX("planks_spruce") ), -- bottom, spruce
		          Slab( -8, 0, BTEX("planks_birch") ), -- bottom, birch
		          Slab( -8, 0, BTEX("planks_jungle") ), -- bottom, jungle
		          Slab( -8, 0, BTEX("planks_acacia") ), -- bottom, acacia
		          Slab( -8, 0, BTEX("planks_big_oak") ), -- bottom, dark oak
				  0, 0,
		          Slab( 0, -8, BTEX("planks_oak") ), -- top, oak
		          Slab( 0, -8, BTEX("planks_spruce") ), -- top, spruce
		          Slab( 0, -8, BTEX("planks_birch") ), -- top, birch
		          Slab( 0, -8, BTEX("planks_jungle") ), -- top, jungle
		          Slab( 0, -8, BTEX("planks_acacia") ), -- top, acacia
		          Slab( 0, -8, BTEX("planks_big_oak") ), -- top, dark oak
				  0, 0 );
		[127] = DataAdapter( 0xc+0x3,  -- Cocoa Plant
		          MultiCompactedBlock( -- age 0, facing north
		           { -11, -1, -6, -6,  -7, -4, -- pod
		             -12,  0, -8, -8, -12,  0 }, -- stem
		           BTEX("cocoa_age_0_side_right"), BTEX("cocoa_age_0_side_left"), BTEX("cocoa_age_0_side_middle"), BTEX("cocoa_age_0_side_middle"), BTEX("cocoa_age_0_bottom"), BTEX("cocoa_age_0_top") ),
		          MultiCompactedBlock( -- age 0, facing east
		           {  -6, -6, -1, -11,  -7, -4, -- pod
		              -8, -8,  0, -12, -12,  0 }, -- stem
		           BTEX("cocoa_age_0_side_middle"), BTEX("cocoa_age_0_side_middle"), BTEX("cocoa_age_0_side_right"), BTEX("cocoa_age_0_side_left"), BTEX("cocoa_age_0_bottom", 'rotate_90'), BTEX("cocoa_age_0_top", 'rotate_270') ),
		          MultiCompactedBlock( -- age 0, facing south
		           { -1, -11, -6, -6,  -7, -4, -- pod
		              0, -12, -8, -8, -12,  0 }, -- stem
		            BTEX("cocoa_age_0_side_left"), BTEX("cocoa_age_0_side_right"), BTEX("cocoa_age_0_side_middle"), BTEX("cocoa_age_0_side_middle"), BTEX("cocoa_age_0_bottom", 'rotate_180'), BTEX("cocoa_age_0_top", 'rotate_180') ),
		          MultiCompactedBlock( -- age 0, facing west
		           { -6, -6, -11, -1,  -7, -4, -- pod
		             -8, -8, -12,  0, -12,  0 }, -- stem
		           BTEX("cocoa_age_0_side_middle"), BTEX("cocoa_age_0_side_middle"), BTEX("cocoa_age_0_side_left"), BTEX("cocoa_age_0_side_right"), BTEX("cocoa_age_0_bottom", 'rotate_270'), BTEX("cocoa_age_0_top", 'rotate_90') ),
		          MultiCompactedBlock( -- age 1, facing north
		           {  -9, -1, -5, -5,  -5, -4, -- pod
		             -12,  0, -8, -8, -12,  0 }, -- stem
		           BTEX("cocoa_age_1_side_right"), BTEX("cocoa_age_1_side_left"), BTEX("cocoa_age_1_side_middle"), BTEX("cocoa_age_1_side_middle"), BTEX("cocoa_age_1_bottom"), BTEX("cocoa_age_1_top") ),
		          MultiCompactedBlock( -- age 1, facing east
		           {  -5, -5, -1,  -9,  -5, -4, -- pod
		              -8, -8,  0, -12, -12,  0 }, -- stem
		           BTEX("cocoa_age_1_side_middle"), BTEX("cocoa_age_1_side_middle"), BTEX("cocoa_age_1_side_right"), BTEX("cocoa_age_1_side_left"), BTEX("cocoa_age_1_bottom", 'rotate_90'), BTEX("cocoa_age_1_top", 'rotate_270') ),
		          MultiCompactedBlock( -- age 1, facing south
		           { -1,  -9, -5, -5,  -5, -4, -- pod
		              0, -12, -8, -8, -12,  0 }, -- stem
		           BTEX("cocoa_age_1_side_left"), BTEX("cocoa_age_1_side_right"), BTEX("cocoa_age_1_side_middle"), BTEX("cocoa_age_1_side_middle"), BTEX("cocoa_age_1_bottom", 'rotate_180'), BTEX("cocoa_age_1_top", 'rotate_180') ),
		          MultiCompactedBlock( -- age 1, facing west
		           {  -5, -5,  -9, -1,  -5, -4, -- pod
		              -8, -8, -12,  0, -12,  0 }, -- stem
		           BTEX("cocoa_age_1_side_middle"), BTEX("cocoa_age_1_side_middle"), BTEX("cocoa_age_1_side_left"), BTEX("cocoa_age_1_side_right"), BTEX("cocoa_age_1_bottom", 'rotate_270'), BTEX("cocoa_age_1_top", 'rotate_90') ),
		          MultiCompactedBlock( -- age 2, facing north
		           {  -7, -1, -4, -4,  -3, -4, -- pod
		             -12,  0, -8, -8, -12,  0 }, -- stem
		           BTEX("cocoa_age_2_side_right"), BTEX("cocoa_age_2_side_left"), BTEX("cocoa_age_2_side_middle"), BTEX("cocoa_age_2_side_middle"), BTEX("cocoa_age_2_bottom"), BTEX("cocoa_age_2_top") ),
		          MultiCompactedBlock( -- age 2, facing east
		           { -4, -4, -1,  -7,  -3, -4, -- pod
		             -8, -8,  0, -12, -12,  0 }, -- stem
		           BTEX("cocoa_age_2_side_middle"), BTEX("cocoa_age_2_side_middle"), BTEX("cocoa_age_2_side_right"), BTEX("cocoa_age_2_side_left"), BTEX("cocoa_age_2_bottom", 'rotate_90'), BTEX("cocoa_age_2_top", 'rotate_270') ),
		          MultiCompactedBlock( -- age 2, facing south
		           { -1,  -7, -4, -4,  -3, -4, -- pod
		              0, -12, -8, -8, -12,  0 }, -- stem
		           BTEX("cocoa_age_2_side_left"), BTEX("cocoa_age_2_side_right"), BTEX("cocoa_age_2_side_middle"), BTEX("cocoa_age_2_side_middle"), BTEX("cocoa_age_2_bottom", 'rotate_180'), BTEX("cocoa_age_2_top", 'rotate_180') ),
		          MultiCompactedBlock( -- age 2, facing west
		           { -4, -4,  -7, -1,  -3, -4, -- pod
		             -8, -8, -12,  0, -12,  0 }, -- stem
		           BTEX("cocoa_age_2_side_middle"), BTEX("cocoa_age_2_side_middle"), BTEX("cocoa_age_2_side_left"), BTEX("cocoa_age_2_side_right"), BTEX("cocoa_age_2_bottom", 'rotate_270'), BTEX("cocoa_age_2_top", 'rotate_90') ),
				  0, 0, 0, 0 );
		[128] = DataAdapter( 0x4, -- Sandstone Stairs
		          Stairs( BTEX("sandstone_normal"), BTEX("sandstone_bottom"), BTEX("sandstone_top") ), -- regular
				  Stairs( BTEX("sandstone_normal"), BTEX("sandstone_top"), BTEX("sandstone_bottom") ) ); -- upside-down
		[129] = OpaqueBlock( BTEX("emerald_ore") ); -- Emerald Ore
		[130] = DataAdapter( 0x3, -- Ender Chest
				   MultiCompactedBlock( -- facing west
					{ -1,  -1, -1,  -1,  0, -2, -- box
					  -7,  -7,  0, -15, -7, -5 }, -- buckle
		            BTEX ("chest_ender_front"), BTEX ("chest_ender_back"), BTEX ("chest_ender_left"), BTEX ("chest_ender_right"), BTEX ("chest_ender_bottom", 'rotate_270'), BTEX ("chest_ender_top", 'rotate_270') ),
		          MultiCompactedBlock( -- facing east
					{ -1,  -1,  -1, -1,  0, -2, -- box
					  -7,  -7, -15,  0, -7, -5 }, -- buckle
		            BTEX("chest_ender_back"), BTEX ("chest_ender_front"), BTEX ("chest_ender_right"), BTEX ("chest_ender_left"), BTEX ("chest_ender_bottom", 'rotate_90'), BTEX ("chest_ender_top", 'rotate_90') ),
		          MultiCompactedBlock( -- facing north
					{ -1,  -1, -1, -1,  0, -2, -- box
					   0, -15, -7, -7, -7, -5 }, -- buckle
		            BTEX("chest_ender_right"), BTEX ("chest_ender_left"), BTEX ("chest_ender_front"), BTEX ("chest_ender_back"), BTEX ("chest_ender_bottom"), BTEX ("chest_ender_top", 'rotate_180') ),
		          MultiCompactedBlock( -- facing south
					{  -1, -1, -1, -1,  0, -2, -- box
					  -15,  0, -7, -7, -7, -5 }, -- buckle
		            BTEX("chest_ender_left"), BTEX ("chest_ender_right"), BTEX ("chest_ender_back"), BTEX ("chest_ender_front"), BTEX ("chest_ender_bottom", 'rotate_180'), BTEX ("chest_ender_top") ) );
		-- [131] -- Tripwire Hook
		-- [132] -- Tripwire
		[133] = OpaqueBlock( BTEX("emerald_block") ); -- Block of Emerald
		[134] = Stairs( BTEX("planks_spruce") ); -- Spruce Wood Stairs
		[135] = Stairs( BTEX("planks_birch") ); -- Birch Wood Stairs
		[136] = Stairs( BTEX("planks_jungle") ); -- Jungle Wood Stairs
		[137] = DataAdapter( 0x8, -- Command Block (Impulse Mode)
					DataAdapter( 0x7, -- unconditional
					  OpaqueBlock( BTEX("command_block_side", 'rotate_180'), BTEX("command_block_front", 'rotate_180'), BTEX("command_block_back") ), -- down
					  OpaqueBlock( BTEX("command_block_side"), BTEX("command_block_back"), BTEX("command_block_front", 'rotate_180') ), -- up
					  OpaqueBlock( BTEX("command_block_side", 'rotate_90'), BTEX("command_block_side", 'rotate_270'), BTEX("command_block_front"), BTEX("command_block_back"), BTEX("command_block_side", 'rotate_180'), BTEX("command_block_side") ), -- north
					  OpaqueBlock( BTEX("command_block_side", 'rotate_270'), BTEX("command_block_side", 'rotate_90'), BTEX("command_block_back"), BTEX("command_block_front"), BTEX("command_block_side"), BTEX("command_block_side", 'rotate_180') ), -- south
					  OpaqueBlock( BTEX("command_block_front"), BTEX("command_block_back"), BTEX("command_block_side", 'rotate_270'), BTEX("command_block_side", 'rotate_90'), BTEX("command_block_side", 'rotate_90'), BTEX("command_block_side", 'rotate_90') ), -- west
					  OpaqueBlock( BTEX("command_block_back"), BTEX("command_block_front"), BTEX("command_block_side", 'rotate_90'), BTEX("command_block_side", 'rotate_270'), BTEX("command_block_side", 'rotate_270'), BTEX("command_block_side", 'rotate_270') ), -- east
					  0, 0 ),
					DataAdapter( 0x7, -- conditional
					  OpaqueBlock( BTEX("command_block_conditional", 'rotate_180'), BTEX("command_block_front", 'rotate_180'), BTEX("command_block_back") ), -- down
					  OpaqueBlock( BTEX("command_block_conditional"), BTEX("command_block_back"), BTEX("command_block_front", 'rotate_180') ), -- up
					  OpaqueBlock( BTEX("command_block_conditional", 'rotate_90'), BTEX("command_block_conditional", 'rotate_270'), BTEX("command_block_front"), BTEX("command_block_back"), BTEX("command_block_conditional", 'rotate_180'), BTEX("command_block_conditional") ), -- north
					  OpaqueBlock( BTEX("command_block_conditional", 'rotate_270'), BTEX("command_block_conditional", 'rotate_90'), BTEX("command_block_back"), BTEX("command_block_front"), BTEX("command_block_conditional"), BTEX("command_block_conditional", 'rotate_180') ), -- south
					  OpaqueBlock( BTEX("command_block_front"), BTEX("command_block_back"), BTEX("command_block_conditional", 'rotate_270'), BTEX("command_block_conditional", 'rotate_90'), BTEX("command_block_conditional", 'rotate_90'), BTEX("command_block_conditional", 'rotate_90') ), -- west
					  OpaqueBlock( BTEX("command_block_back"), BTEX("command_block_front"), BTEX("command_block_conditional", 'rotate_90'), BTEX("command_block_conditional", 'rotate_270'), BTEX("command_block_conditional", 'rotate_270'), BTEX("command_block_conditional", 'rotate_270') ), -- east
					  0, 0 ) );
		-- [138] -- Beacon Block
		[139] = DataAdapter( 0x1, -- Cobblestone Wall
					MultiCompactedConnectedBlock( -- regular
					 { -5, -5, -5, -5,  0, -2 },
					 { -5, -5, -5, -5,  0, -2 },
					 { -5, -5, -5, -5,  0, -2 },
					 BTEX("cobblestone") ),
					MultiCompactedConnectedBlock( -- mossy
					 { -5, -5, -5, -5,  0, -2 },
					 { -5, -5, -5, -5,  0, -2 },
					 { -5, -5, -5, -5,  0, -2 },
					 BTEX("cobblestone_mossy") ) );
		[140] = MultiCompactedBlock( -- Flower Pot
		          { -5, -10, -5, -5, 0, -10, -- wall, north
		            -5, -5, -10, -5, 0,  -10, -- wall, west
		            -10, -5, -5, -5, 0,  -10, -- wall, south
		            -5, -5, -5, -10, 0,  -10, -- wall, east
		            -6, -6, -6, -6,  -0,  -12 }, -- inlay
		          BTEX("flower_pot_side"), BTEX("flower_pot_bottom"), BTEX("flower_pot_top") );
		[141] = DataAdapter( 0x7, -- Carrots
		          HashShapedBlock( -4, BTEX("carrots_stage_0"), 0 ), HashShapedBlock( -4, BTEX("carrots_stage_0"), 0 ), -- growthstate 0
		          HashShapedBlock( -4, BTEX("carrots_stage_1"), 0 ), HashShapedBlock( -4, BTEX("carrots_stage_1"), 0 ), -- growthstate 1
		          HashShapedBlock( -4, BTEX("carrots_stage_2"), 0 ), HashShapedBlock( -4, BTEX("carrots_stage_2"), 0 ), HashShapedBlock( -4, BTEX("carrots_stage_2"), 0 ), -- growthstate 2
		          HashShapedBlock( -4, BTEX("carrots_stage_3"), 0 ) ); -- growthstate 3
		[142] = DataAdapter( 0x7, -- Potatoes
		          HashShapedBlock( -4, BTEX("potatoes_stage_0"), 0 ), HashShapedBlock( -4, BTEX("potatoes_stage_0"), 0 ), -- growthstate 0
		          HashShapedBlock( -4, BTEX("potatoes_stage_1"), 0 ), HashShapedBlock( -4, BTEX("potatoes_stage_1"), 0 ), -- growthstate 1
		          HashShapedBlock( -4, BTEX("potatoes_stage_2"), 0 ), HashShapedBlock( -4, BTEX("potatoes_stage_2"), 0 ), HashShapedBlock( -4, BTEX("potatoes_stage_2"), 0 ), -- growthstate 2
		          HashShapedBlock( -4, BTEX("potatoes_stage_3"), 0 ) ); -- growthstate 3
		[143] = DataAdapter( 0x7+0x8, -- Wooden Button
		          CompactedBlock( -5, -5, -6, -6, -14, 0, BTEX("planks_oak") ), -- off, bottom
				  CompactedBlock( 0, -14, -5, -5, -6, -6, BTEX("planks_oak") ), -- off, east
		          CompactedBlock( -14, 0, -5, -5, -6, -6, BTEX("planks_oak") ), -- off, west
				  CompactedBlock( -5, -5, 0, -14, -6, -6, BTEX("planks_oak") ), -- off, south
				  CompactedBlock( -5, -5, -14, 0, -6, -6, BTEX("planks_oak") ), -- off, north
				  CompactedBlock( -5, -5, -6, -6, 0, -14, BTEX("planks_oak") ), -- off, top
				  0, 0,
		          CompactedBlock( -5, -5, -6, -6, -15, 0, BTEX("planks_oak") ), -- on, bottom
				  CompactedBlock( 0, -15, -5, -5, -6, -6, BTEX("planks_oak") ), -- on, east
		          CompactedBlock( -15, 0, -5, -5, -6, -6, BTEX("planks_oak") ), -- on, west
				  CompactedBlock( -5, -5, 0, -15, -6, -6, BTEX("planks_oak") ), -- on, south
		          CompactedBlock( -5, -5, -15, 0, -6, -6, BTEX("planks_oak") ), -- on, north
		          CompactedBlock( -5, -5, -6, -6, 0, -15, BTEX("planks_oak") ), -- on, top
				  0, 0 );
		-- [144] -- Head Block
		[145] = DataAdapter( 0xc+0x3, -- Anvil TODO: Support, Brink and Base sections need different top texture ( anvil_base not anvil_top_merge_damaged_X ) => MultiBlockInBlock
		          MultiCompactedBlock(  -- regular anvil, facing south
		           {   0,   0,  -3,  -3, -10,   0, -- head
		              -4,  -4,  -6,  -6,  -5,  -6, -- support
		              -3,  -3,  -4,  -4,  -4, -11, -- brink
		              -2,  -2,  -2,  -2,   0, -12 }, -- base
		           BTEX("anvil_side_wide"), BTEX("anvil_side_wide", 'flip_x'), BTEX("anvil_side_narrow"), BTEX("anvil_side_narrow"), BTEX("anvil_base", 'rotate_180'), BTEX("anvil_top_merge_damaged_0", 'rotate_180') ),
		          MultiCompactedBlock(  -- regular anvil, facing west
		           {  -3,  -3,   0,   0, -10,   0, -- head
		              -6,  -6,  -4,  -4,  -5,  -6, -- support
		              -4,  -4,  -3,  -3,  -4, -11, -- brink
		              -2,  -2,  -2,  -2,   0, -12 }, -- base
		           BTEX("anvil_side_narrow"), BTEX("anvil_side_narrow"), BTEX("anvil_side_wide"), BTEX("anvil_side_wide", 'flip_x'), BTEX("anvil_base", 'rotate_270'), BTEX("anvil_top_merge_damaged_0", 'rotate_90') ),
		          MultiCompactedBlock(  -- regular anvil, facing north
		           {   0,   0,  -3,  -3, -10,   0, -- head
		              -4,  -4,  -6,  -6,  -5,  -6, -- support
		              -3,  -3,  -4,  -4,  -4, -11, -- brink
		              -2,  -2,  -2,  -2,   0, -12 }, -- base
		           BTEX("anvil_side_wide", 'flip_x'), BTEX("anvil_side_wide"), BTEX("anvil_side_narrow"), BTEX("anvil_side_narrow"), BTEX("anvil_base"), BTEX("anvil_top_merge_damaged_0") ),
		          MultiCompactedBlock(  -- regular anvil, facing east
		           {  -3,  -3,   0,   0, -10,   0, -- head
		              -6,  -6,  -4,  -4,  -5,  -6, -- support
		              -4,  -4,  -3,  -3,  -4, -11, -- brink
		              -2,  -2,  -2,  -2,   0, -12 }, -- base
		           BTEX("anvil_side_narrow"), BTEX("anvil_side_narrow"), BTEX("anvil_side_wide", 'flip_x'), BTEX("anvil_side_wide"), BTEX("anvil_base", 'rotate_90'), BTEX("anvil_top_merge_damaged_0", 'rotate_270') ),
		          MultiCompactedBlock(  -- slightly damaged anvil, facing south
		           {   0,   0,  -3,  -3, -10,   0, -- head
		              -4,  -4,  -6,  -6,  -5,  -6, -- support
		              -3,  -3,  -4,  -4,  -4, -11, -- brink
		              -2,  -2,  -2,  -2,   0, -12 }, -- base
		           BTEX("anvil_side_wide"), BTEX("anvil_side_wide", 'flip_x'), BTEX("anvil_side_narrow"), BTEX("anvil_side_narrow"), BTEX("anvil_base", 'rotate_180'), BTEX("anvil_top_merge_damaged_1", 'rotate_180') ),
		          MultiCompactedBlock(  -- slightly damaged anvil, facing west
		           {  -3,  -3,   0,   0, -10,   0, -- head
		              -6,  -6,  -4,  -4,  -5,  -6, -- support
		              -4,  -4,  -3,  -3,  -4, -11, -- brink
		              -2,  -2,  -2,  -2,   0, -12 }, -- base
		           BTEX("anvil_side_narrow"), BTEX("anvil_side_narrow"), BTEX("anvil_side_wide"), BTEX("anvil_side_wide", 'flip_x'), BTEX("anvil_base", 'rotate_270'), BTEX("anvil_top_merge_damaged_1", 'rotate_90') ),
		          MultiCompactedBlock(  -- slightly damaged anvil, facing north
		           {   0,   0,  -3,  -3, -10,   0, -- head
		              -4,  -4,  -6,  -6,  -5,  -6, -- support
		              -3,  -3,  -4,  -4,  -4, -11, -- brink
		              -2,  -2,  -2,  -2,   0, -12 }, -- base
		           BTEX("anvil_side_wide", 'flip_x'), BTEX("anvil_side_wide"), BTEX("anvil_side_narrow"), BTEX("anvil_side_narrow"), BTEX("anvil_base"), BTEX("anvil_top_merge_damaged_1") ),
		          MultiCompactedBlock(  -- slightly damaged anvil, facing east
		           {  -3,  -3,   0,   0, -10,   0, -- head
		              -6,  -6,  -4,  -4,  -5,  -6, -- support
		              -4,  -4,  -3,  -3,  -4, -11, -- brink
		              -2,  -2,  -2,  -2,   0, -12 }, -- base
		           BTEX("anvil_side_narrow"), BTEX("anvil_side_narrow"), BTEX("anvil_side_wide", 'flip_x'), BTEX("anvil_side_wide"), BTEX("anvil_base", 'rotate_90'), BTEX("anvil_top_merge_damaged_1", 'rotate_270') ),
		          MultiCompactedBlock(  -- very damaged anvil, facing south
		           {   0,   0,  -3,  -3, -10,   0, -- head
		              -4,  -4,  -6,  -6,  -5,  -6, -- support
		              -3,  -3,  -4,  -4,  -4, -11, -- brink
		              -2,  -2,  -2,  -2,   0, -12 }, -- base
		           BTEX("anvil_side_wide"), BTEX("anvil_side_wide", 'flip_x'), BTEX("anvil_side_narrow"), BTEX("anvil_side_narrow"), BTEX("anvil_base", 'rotate_180'), BTEX("anvil_top_merge_damaged_2", 'rotate_180') ),
		          MultiCompactedBlock(  -- very damaged anvil, facing west
		           {  -3,  -3,   0,   0, -10,   0, -- head
		              -6,  -6,  -4,  -4,  -5,  -6, -- support
		              -4,  -4,  -3,  -3,  -4, -11, -- brink
		              -2,  -2,  -2,  -2,   0, -12 }, -- base
		           BTEX("anvil_side_narrow"), BTEX("anvil_side_narrow"), BTEX("anvil_side_wide"), BTEX("anvil_side_wide", 'flip_x'), BTEX("anvil_base", 'rotate_270'), BTEX("anvil_top_merge_damaged_2", 'rotate_90') ),
		          MultiCompactedBlock(  -- very damaged anvil, facing north
		           {   0,   0,  -3,  -3, -10,   0, -- head
		              -4,  -4,  -6,  -6,  -5,  -6, -- support
		              -3,  -3,  -4,  -4,  -4, -11, -- brink
		              -2,  -2,  -2,  -2,   0, -12 }, -- base
		           BTEX("anvil_side_wide", 'flip_x'), BTEX("anvil_side_wide"), BTEX("anvil_side_narrow"), BTEX("anvil_side_narrow"), BTEX("anvil_base"), BTEX("anvil_top_merge_damaged_2") ),
		          MultiCompactedBlock(  -- very damaged anvil, facing east
		           {  -3,  -3,   0,   0, -10,   0, -- head
		              -6,  -6,  -4,  -4,  -5,  -6, -- support
		              -4,  -4,  -3,  -3,  -4, -11, -- brink
		              -2,  -2,  -2,  -2,   0, -12 }, -- base
		           BTEX("anvil_side_narrow"), BTEX("anvil_side_narrow"), BTEX("anvil_side_wide", 'flip_x'), BTEX("anvil_side_wide"), BTEX("anvil_base", 'rotate_90'), BTEX("anvil_top_merge_damaged_2", 'rotate_270') ),
				  0, 0, 0, 0 );
		[146] = DataAdapter( 0x3, -- Trapped Chest
				   MultiCompactedBlock( -- facing west
					{ -1,  -1, -1,  -1,  0, -2, -- box
					  -7,  -7,  0, -15, -7, -5 }, -- buckle
		            BTEX ("chest_trapped_front"), BTEX ("chest_trapped_back"), BTEX ("chest_trapped_left"), BTEX ("chest_trapped_right"), BTEX ("chest_trapped_bottom", 'rotate_270'), BTEX ("chest_trapped_top", 'rotate_270') ),
		          MultiCompactedBlock( -- facing east
					{ -1,  -1,  -1, -1,  0, -2, -- box
					  -7,  -7, -15,  0, -7, -5 }, -- buckle
		            BTEX("chest_trapped_back"), BTEX ("chest_trapped_front"), BTEX ("chest_trapped_right"), BTEX ("chest_trapped_left"), BTEX ("chest_trapped_bottom", 'rotate_90'), BTEX ("chest_trapped_top", 'rotate_90') ),
		          MultiCompactedBlock( -- facing north
					{ -1,  -1, -1, -1,  0, -2, -- box
					   0, -15, -7, -7, -7, -5 }, -- buckle
		            BTEX("chest_trapped_right"), BTEX ("chest_trapped_left"), BTEX ("chest_trapped_front"), BTEX ("chest_trapped_back"), BTEX ("chest_trapped_bottom"), BTEX ("chest_trapped_top", 'rotate_180') ),
		          MultiCompactedBlock( -- facing south
					{  -1, -1, -1, -1,  0, -2, -- box
					  -15,  0, -7, -7, -7, -5 }, -- buckle
		            BTEX("chest_trapped_left"), BTEX ("chest_trapped_right"), BTEX ("chest_trapped_back"), BTEX ("chest_trapped_front"), BTEX ("chest_trapped_bottom", 'rotate_180'), BTEX ("chest_trapped_top") ) );
		[147] = CompactedBlock( -1, -1, -1, -1, 0, -15, BTEX("gold_block") ); -- Weighted Pressure Plate (Light)
		[148] = CompactedBlock( -1, -1, -1, -1, 0, -15, BTEX("iron_block") ); -- Weighted Pressure Plate (Heavy)
		-- [149] -- Redstone Comparator (inactive)
		-- [150] -- ??? -> Redstone Comparator (active)
		[151] = CompactedBlock( 0, 0, 0, 0, 0, -10, BTEX("daylight_detector_side"), BTEX("daylight_detector_side"), BTEX("daylight_detector_top") ); -- Daylight Sensor
		[152] = OpaqueBlock( BTEX("redstone_block") ); -- Block of Redstone
		[153] = OpaqueBlock( BTEX("quartz_ore") ); -- Nether Quartz (Ore)
		[154] = DataAdapter( 0x7, -- Hopper TODO: Facing section need different texture ( hopper_outside not hopper_top_merge ) => MultiBlockInBlock
		          MultiCompactedBlock( -- down
		           {   0, -14,   0,   0, -10,   0, -- wall, north
		               0,   0, -14,   0, -10,   0, -- wall, east
		             -14,   0,   0,   0, -10,   0, -- wall, south
		               0,   0,   0, -14, -10,   0, -- wall, west
		               0,   0,   0,   0, -10,  -5, -- wall, bottom
		              -4,  -4,  -4,  -4,  -4,  -6, -- mid section
		              -6,  -6,  -6,  -6,   0, -12 }, -- facing section
		           BTEX("hopper_outside"), BTEX("hopper_outside"), BTEX("hopper_top_merge") ),
		          0,
		          MultiCompactedBlock( -- north
		           {   0, -14,   0,   0, -10,   0, -- wall, north
		               0,   0, -14,   0, -10,   0, -- wall, east
		             -14,   0,   0,   0, -10,   0, -- wall, south
		               0,   0,   0, -14, -10,   0, -- wall, west
		               0,   0,   0,   0, -10,  -5, -- wall, bottom
		              -4,  -4,  -4,  -4,  -4,  -6, -- mid section
		               0, -12,  -6,  -6,  -4,  -8 }, -- facing section
		           BTEX("hopper_outside"), BTEX("hopper_outside"), BTEX("hopper_top_merge") ),
		          MultiCompactedBlock( -- south
		           {   0, -14,   0,   0, -10,   0, -- wall, north
		               0,   0, -14,   0, -10,   0, -- wall, east
		             -14,   0,   0,   0, -10,   0, -- wall, south
		               0,   0,   0, -14, -10,   0, -- wall, west
		               0,   0,   0,   0, -10,  -5, -- wall, bottom
		              -4,  -4,  -4,  -4,  -4,  -6, -- mid section
		             -12,   0,  -6,  -6,  -4,  -8 }, -- facing section
		           BTEX("hopper_outside"), BTEX("hopper_outside", 'rotate_180'), BTEX("hopper_top_merge", 'rotate_180') ),
		          MultiCompactedBlock( -- west
		           {   0, -14,   0,   0, -10,   0, -- wall, north
		               0,   0, -14,   0, -10,   0, -- wall, east
		             -14,   0,   0,   0, -10,   0, -- wall, south
		               0,   0,   0, -14, -10,   0, -- wall, west
		               0,   0,   0,   0, -10,  -5, -- wall, bottom
		              -4,  -4,  -4,  -4,  -4,  -6, -- mid section
		              -6,  -6,   0, -12,  -4,  -8 }, -- facing section
		           BTEX("hopper_outside"), BTEX("hopper_outside", 'rotate_270'), BTEX("hopper_top_merge", 'rotate_90') ),
		          MultiCompactedBlock( -- west
		           {   0, -14,   0,   0, -10,   0, -- wall, north
		               0,   0, -14,   0, -10,   0, -- wall, east
		             -14,   0,   0,   0, -10,   0, -- wall, south
		               0,   0,   0, -14, -10,   0, -- wall, west
		               0,   0,   0,   0, -10,  -5, -- wall, bottom
		              -4,  -4,  -4,  -4,  -4,  -6, -- mid section
		              -6,  -6, -12,   0,  -4,  -8 }, -- facing section
		           BTEX("hopper_outside"), BTEX("hopper_outside", 'rotate_90'), BTEX("hopper_top_merge", 'rotate_270') ),
				  0, 0 );
		[155] = DataAdapter( 0x4, -- Block of Quartz
					DataAdapter( 0x3,
						OpaqueBlock( BTEX("quartz_block_side"), BTEX("quartz_block_bottom"), BTEX("quartz_block_top") ), -- regular
						OpaqueBlock( BTEX("quartz_block_chiseled"), BTEX("quartz_block_chiseled_top") ), -- chiseld
						OpaqueBlock( BTEX("quartz_block_lines"), BTEX("quartz_block_lines_top") ), -- lines, top-bottom
						OpaqueBlock( BTEX("quartz_block_lines_top"), BTEX("quartz_block_lines_top", 'rotate_180'), BTEX("quartz_block_lines", 'rotate_90'), BTEX("quartz_block_lines", 'rotate_270'), BTEX("quartz_block_lines", 'rotate_270'), BTEX("quartz_block_lines", 'rotate_270') ) ), -- lines, west-east		
					OpaqueBlock( BTEX("quartz_block_lines", 'rotate_90'), BTEX("quartz_block_lines", 'rotate_270'), BTEX("quartz_block_lines_top", 'rotate_180'), BTEX("quartz_block_lines_top"), BTEX("quartz_block_lines", 'rotate_180'), BTEX("quartz_block_lines") ) ); -- lines, north-south
		[156] = DataAdapter( 0x4, -- Quartz Stairs
		          Stairs( BTEX("quartz_block_side"), BTEX("quartz_block_bottom"), BTEX("quartz_block_top") ), -- regular
				  Stairs( BTEX("quartz_block_side"), BTEX("quartz_block_top"), BTEX("quartz_block_bottom") ) ); -- upside-down
		[157] = DataAdapter( 0x8, -- Activator Rail
		          Rail( BTEX("rail_activator") ), -- not powered
		          Rail( BTEX("rail_activator_powered") ) ); -- powered
		[158] = DataAdapter( 0x6, -- Dropper
					DataAdapter( 0x1,
						OpaqueBlock( BTEX("furnace_top"), BTEX("dropper_front_vertical"), BTEX("furnace_top") ), -- facing down
						OpaqueBlock( BTEX("furnace_top"), BTEX("furnace_top"), BTEX("dropper_front_vertical") ) ), -- facing up
					DataAdapter( 0x1,
						OpaqueBlock( BTEX("furnace_side"), BTEX("furnace_side"), BTEX("dropper_front_horizontal"), BTEX("furnace_side"), BTEX("furnace_top"), BTEX("furnace_top") ), -- facing north
						OpaqueBlock( BTEX("furnace_side"), BTEX("furnace_side"), BTEX("furnace_side"), BTEX("dropper_front_horizontal"), BTEX("furnace_top"), BTEX("furnace_top") ) ), -- facing south
					DataAdapter( 0x1,
						OpaqueBlock( BTEX("dropper_front_horizontal"), BTEX("furnace_side"), BTEX("furnace_side"), BTEX("furnace_side"), BTEX("furnace_top"), BTEX("furnace_top") ), -- facing west
						OpaqueBlock( BTEX("furnace_side"), BTEX("dropper_front_horizontal"), BTEX("furnace_side"), BTEX("furnace_side"), BTEX("furnace_top"), BTEX("furnace_top") ) ), -- facing east
					0, 0 );
		[159] = DataAdapter( 0xf, -- Stained Hardened Clay
		          OpaqueBlock( BTEX("hardened_clay_stained_white") ), -- white
		          OpaqueBlock( BTEX("hardened_clay_stained_orange") ), -- orange
		          OpaqueBlock( BTEX("hardened_clay_stained_magenta") ), -- magenta
		          OpaqueBlock( BTEX("hardened_clay_stained_light_blue") ), -- light blue
		          OpaqueBlock( BTEX("hardened_clay_stained_yellow") ), -- yellow
		          OpaqueBlock( BTEX("hardened_clay_stained_lime") ), -- lime
		          OpaqueBlock( BTEX("hardened_clay_stained_pink") ), -- pink
		          OpaqueBlock( BTEX("hardened_clay_stained_gray") ), -- grey
		          OpaqueBlock( BTEX("hardened_clay_stained_silver") ), -- light grey	
		          OpaqueBlock( BTEX("hardened_clay_stained_cyan") ), -- cyan
		          OpaqueBlock( BTEX("hardened_clay_stained_purple") ), -- purple
		          OpaqueBlock( BTEX("hardened_clay_stained_blue") ), -- blue
		          OpaqueBlock( BTEX("hardened_clay_stained_brown") ), -- brown
		          OpaqueBlock( BTEX("hardened_clay_stained_green") ), -- green
		          OpaqueBlock( BTEX("hardened_clay_stained_red") ), -- red
		          OpaqueBlock( BTEX("hardened_clay_stained_black") ) ); -- black
		[160]  = DataAdapter( 0xf, -- Stained Glass Panes
				  DelayRender( TransparentBlock( 0, BTEX("glass_white") ), 15 ), -- white
				  DelayRender( TransparentBlock( 0, BTEX("glass_orange") ), 15 ), -- orange
				  DelayRender( TransparentBlock( 0, BTEX("glass_magenta") ), 15 ), -- magenta
				  DelayRender( TransparentBlock( 0, BTEX("glass_light_blue") ), 15 ), -- light blue
				  DelayRender( TransparentBlock( 0, BTEX("glass_yellow") ), 15 ), -- yellow
				  DelayRender( TransparentBlock( 0, BTEX("glass_lime") ), 15 ), -- lime
				  DelayRender( TransparentBlock( 0, BTEX("glass_pink") ), 15 ), -- pink
				  DelayRender( TransparentBlock( 0, BTEX("glass_gray") ), 15 ), -- grey
				  DelayRender( TransparentBlock( 0, BTEX("glass_silver") ), 15 ), -- light grey
				  DelayRender( TransparentBlock( 0, BTEX("glass_cyan") ), 15 ), -- cyan
				  DelayRender( TransparentBlock( 0, BTEX("glass_purple") ), 15 ), -- purple
				  DelayRender( TransparentBlock( 0, BTEX("glass_blue") ), 15 ), -- blue				  
				  DelayRender( TransparentBlock( 0, BTEX("glass_brown") ), 15 ), -- brown
				  DelayRender( TransparentBlock( 0, BTEX("glass_green") ), 15 ), -- green
				  DelayRender( TransparentBlock( 0, BTEX("glass_red") ), 15 ), -- red
				  DelayRender( TransparentBlock( 0, BTEX("glass_black") ), 15 ) ); -- black
		[161] = DataAdapter( 0x1,-- Leaves (Acacia/Dark Oak)
		          BiomeHollowOpaqueBlock( 1, BTEX("leaves_acacia") ), -- acacia
		          BiomeHollowOpaqueBlock( 1, BTEX("leaves_big_oak") ) ); -- dark oak
		[162] = DataAdapter( 0x1, -- Wood Log (Acacia/Dark Oak)
		          DataAdapter( 0xc, -- acacia log
					OpaqueBlock( BTEX("log_acacia"), BTEX("log_acacia_top") ), -- top-bottom
					OpaqueBlock( BTEX("log_acacia_top"), BTEX("log_acacia_top", 'rotate_180'), BTEX("log_acacia", 'rotate_90'), BTEX("log_acacia", 'rotate_270'), BTEX("log_acacia", 'rotate_270'), BTEX("log_acacia", 'rotate_270') ), -- west-east
					OpaqueBlock( BTEX("log_acacia", 'rotate_90'), BTEX("log_acacia", 'rotate_270'), BTEX("log_acacia_top", 'rotate_180'), BTEX("log_acacia_top"), BTEX("log_acacia", 'rotate_180'), BTEX("log_acacia") ), -- north-south
					0 ),
		          DataAdapter( 0xc, -- dark oak log
					OpaqueBlock( BTEX("log_big_oak"), BTEX("log_big_oak_top") ), -- top-bottom
					OpaqueBlock( BTEX("log_big_oak_top"), BTEX("log_big_oak_top", 'rotate_180'), BTEX("log_big_oak", 'rotate_90'), BTEX("log_big_oak", 'rotate_270'), BTEX("log_big_oak", 'rotate_270'), BTEX("log_big_oak", 'rotate_270') ), -- west-east
					OpaqueBlock( BTEX("log_big_oak", 'rotate_90'), BTEX("log_big_oak", 'rotate_270'), BTEX("log_big_oak_top", 'rotate_180'), BTEX("log_big_oak_top"), BTEX("log_big_oak", 'rotate_180'), BTEX("log_big_oak") ), -- north-south
					0 ) );
		[163] = Stairs( BTEX("planks_acacia") ); -- Acacia Wood Stairs
		[164] = Stairs( BTEX("planks_big_oak") ); -- Dark Oak Wood Stairs
		[165] = DelayRender( TransparentBlock( 0, BTEX("slime") ), 15 ); -- Slime Block
		-- [166] -- Barrier (not visible like air)
		[167] = DataAdapter( 0x8, -- Iron Trapdoor
		          DataAdapter( 0x4,
		            Slab( -13, 0, BTEX("iron_trapdoor") ), -- bottom
		            DataAdapter( 0x3,
		              CompactedBlock( 0, 0, -13, 0, 0, 0, BTEX("iron_trapdoor") ), -- north
		              CompactedBlock( 0, 0, 0, -13, 0, 0, BTEX("iron_trapdoor") ), -- south
		              CompactedBlock( -13, 0, 0, 0, 0, 0, BTEX("iron_trapdoor") ), -- west
		              CompactedBlock( 0, -13, 0, 0, 0, 0, BTEX("iron_trapdoor") ) ) ), -- east
		          DataAdapter( 0x4,
		            Slab( 0, -13, BTEX("iron_trapdoor") ), -- top
		            DataAdapter( 0x3,
		              CompactedBlock( 0, 0, -13, 0, 0, 0, BTEX("iron_trapdoor") ), -- north
		              CompactedBlock( 0, 0, 0, -13, 0, 0, BTEX("iron_trapdoor") ), -- south
		              CompactedBlock( -13, 0, 0, 0, 0, 0, BTEX("iron_trapdoor") ), -- west
		              CompactedBlock( 0, -13, 0, 0, 0, 0, BTEX("iron_trapdoor") ) ) ) ); -- east
		[168] = DataAdapter( 0x3, -- Prismarine
		              OpaqueBlock( BTEX("prismarine_rough") ), -- regular
		              OpaqueBlock( BTEX("prismarine_bricks") ), -- bricks
		              OpaqueBlock( BTEX("prismarine_dark") ), -- dark
					  0 );
		[169] = OpaqueBlock( BTEX("sea_lantern") ); -- Sea Lantern
		[170] = DataAdapter( 0xc, -- Hay Bale
				  OpaqueBlock( BTEX("hay_block_side"), BTEX("hay_block_top") ), -- top-bottom
				  OpaqueBlock( BTEX("hay_block_top"), BTEX("hay_block_top", 'rotate_180'), BTEX("hay_block_side", 'rotate_90'), BTEX("hay_block_side", 'rotate_270'), BTEX("hay_block_side", 'rotate_270'), BTEX("hay_block_side", 'rotate_270') ), -- west-east
				  OpaqueBlock( BTEX("hay_block_side", 'rotate_90'), BTEX("hay_block_side", 'rotate_270'), BTEX("hay_block_top", 'rotate_180'), BTEX("hay_block_top"), BTEX("hay_block_side", 'rotate_180'), BTEX("hay_block_side") ), -- north-south
				  0 );
		[171] = DataAdapter( 0xf, -- Carpet
		          CompactedBlock( 0, 0, 0, 0, 0, -15, BTEX("wool_colored_white") ), -- white
		          CompactedBlock( 0, 0, 0, 0, 0, -15, BTEX("wool_colored_orange") ), -- orange
		          CompactedBlock( 0, 0, 0, 0, 0, -15, BTEX("wool_colored_magenta") ), -- magenta
		          CompactedBlock( 0, 0, 0, 0, 0, -15, BTEX("wool_colored_light_blue") ), -- light blue
		          CompactedBlock( 0, 0, 0, 0, 0, -15, BTEX("wool_colored_yellow") ), -- yellow
		          CompactedBlock( 0, 0, 0, 0, 0, -15, BTEX("wool_colored_lime") ), -- lime
		          CompactedBlock( 0, 0, 0, 0, 0, -15, BTEX("wool_colored_pink") ), -- pink
		          CompactedBlock( 0, 0, 0, 0, 0, -15, BTEX("wool_colored_gray") ), -- grey
		          CompactedBlock( 0, 0, 0, 0, 0, -15, BTEX("wool_colored_silver") ), -- light grey	
		          CompactedBlock( 0, 0, 0, 0, 0, -15, BTEX("wool_colored_cyan") ), -- cyan
		          CompactedBlock( 0, 0, 0, 0, 0, -15, BTEX("wool_colored_purple") ), -- purple
		          CompactedBlock( 0, 0, 0, 0, 0, -15, BTEX("wool_colored_blue") ), -- blue
		          CompactedBlock( 0, 0, 0, 0, 0, -15, BTEX("wool_colored_brown") ), -- brown
		          CompactedBlock( 0, 0, 0, 0, 0, -15, BTEX("wool_colored_green") ), -- green
		          CompactedBlock( 0, 0, 0, 0, 0, -15, BTEX("wool_colored_red") ), -- red
		          CompactedBlock( 0, 0, 0, 0, 0, -15, BTEX("wool_colored_black") ) ); -- black
		[172] = OpaqueBlock( BTEX("hardened_clay") ); -- Hardened Clay
		[173] = OpaqueBlock( BTEX("coal_block") ); -- Block of Coal
		[174] = OpaqueBlock( BTEX("ice_packed") ); -- Packed Ice
		-- [175] -- Double Plants
		-- [176] -- Standing Banner
		-- [177] -- Wall Banner
		[178] = CompactedBlock( 0, 0, 0, 0, 0, -10, BTEX("daylight_detector_side"), BTEX("daylight_detector_side"), BTEX("daylight_detector_inverted_top") ); -- Inverted Daylight Sensor
		[179] = DataAdapter( 0x3, -- Red Sandstone
		          OpaqueBlock( BTEX("red_sandstone_normal"), BTEX("red_sandstone_bottom"), BTEX("red_sandstone_top") ), -- regular
		          OpaqueBlock( BTEX("red_sandstone_carved"), BTEX("red_sandstone_top"), BTEX("red_sandstone_top") ), -- chiseled
		          OpaqueBlock( BTEX("red_sandstone_smooth"), BTEX("red_sandstone_top"), BTEX("red_sandstone_top") ), -- smooth
		          0 );
		[180] = DataAdapter( 0x4, -- Red Sandstone Stairs
		          Stairs( BTEX("red_sandstone_normal"), BTEX("red_sandstone_bottom"), BTEX("red_sandstone_top") ), -- regular
				  Stairs( BTEX("red_sandstone_normal"), BTEX("red_sandstone_top"), BTEX("red_sandstone_bottom") ) ); -- upside-down
		[181] = DataAdapter( 0x8, -- Red Sandstone Double-Slab
		          OpaqueBlock( BTEX("red_sandstone_normal"), BTEX("red_sandstone_bottom"), BTEX("red_sandstone_top") ), -- regular
				  OpaqueBlock( BTEX("red_sandstone_top") ) ); -- smooth
		[182] = DataAdapter( 0x8, -- Red Sandstone Slab
		          Slab( -8, 0, BTEX("red_sandstone_normal"), BTEX("red_sandstone_bottom"), BTEX("red_sandstone_top") ), -- regular slab
				  Slab( 0, -8, BTEX("red_sandstone_normal"), BTEX("red_sandstone_bottom"), BTEX("red_sandstone_top") ) ); -- upside-down slab
		[183] = FenceGate( BTEX("planks_spruce") ); -- Spruce Fence Gate
		[184] = FenceGate( BTEX("planks_birch") ); -- Birch Fence Gate
		[185] = FenceGate( BTEX("planks_jungle") ); -- Jungle Fence Gate
		[186] = FenceGate( BTEX("planks_big_oak") ); -- Dark Oak Fence Gate
		[187] = FenceGate( BTEX("planks_acacia") ); -- Acacia Fence Gate
		[188] = Fence( BTEX("planks_spruce") ); -- Spruce Wood Fence
		[189] = Fence( BTEX("planks_birch") ); -- Birch Wood Fence
		[190] = Fence( BTEX("planks_jungle") ); -- Jungle Wood Fence
		[191] = Fence( BTEX("planks_big_oak") ); -- Dark Oak Wood Fence
		[192] = Fence( BTEX("planks_acacia") ); -- Acacia Wood Fence
		[193] = Door( BTEX("door_spruce_lower"), BTEX("door_spruce_upper") ); -- Spruce Wood Door
		[194] = Door( BTEX("door_birch_lower"), BTEX("door_birch_upper") ); -- Birch Wood Door
		[195] = Door( BTEX("door_jungle_lower"), BTEX("door_jungle_upper") ); -- Jungle Wood Door
		[196] = Door( BTEX("door_acacia_lower"), BTEX("door_acacia_upper") ); -- Acacia Wood Door
		[197] = Door( BTEX("door_dark_oak_lower"), BTEX("door_dark_oak_upper") ); -- Dark Oak Wood Door
		[198] = DataAdapter( 0x7, -- End Rod
				  MultiCompactedBlock( -- facing down
					{  -6,  -6,  -6,  -6, -15,   0, -- base
					   -7,  -7,  -7,  -7,   0,  -1 }, -- stand
		            BTEX("end_rod_side", 'rotate_180'), BTEX("end_rod_top"), BTEX("end_rod_bottom", 'rotate_180') ),
				  MultiCompactedBlock( -- facing up
					{  -6,  -6,  -6,  -6,   0, -15, -- base
					   -7,  -7,  -7,  -7,  -1,   0 }, -- stand
		            BTEX("end_rod_side"), BTEX("end_rod_bottom", 'rotate_180'), BTEX("end_rod_top") ),
				  MultiCompactedBlock( -- facing north
					{ -15,   0,  -6,  -6,  -6,  -6, -- base
					    0,  -1,  -7,  -7,  -7,  -7 }, -- stand
		            BTEX("end_rod_side", 'rotate_90'), BTEX("end_rod_side", 'rotate_270'), BTEX("end_rod_top", 'rotate_180'), BTEX("end_rod_bottom", 'rotate_180'), BTEX("end_rod_side", 'rotate_180'), BTEX("end_rod_side") ),
				  MultiCompactedBlock( -- facing south
					{   0, -15,  -6,  -6,  -6,  -6, -- base
					   -1,   0,  -7,  -7,  -7,  -7 }, -- stand
		            BTEX("end_rod_side", 'rotate_270'), BTEX("end_rod_side", 'rotate_90'), BTEX("end_rod_bottom", 'rotate_180'), BTEX("end_rod_top", 'rotate_180'), BTEX("end_rod_side"), BTEX("end_rod_side", 'rotate_180') ),
				  MultiCompactedBlock( -- facing west
					{  -6,  -6, -15,   0,  -6,  -6, -- base
					   -7,  -7,   0,  -1,  -7,  -7 }, -- stand
		            BTEX("end_rod_top", 'rotate_180'), BTEX("end_rod_bottom", 'rotate_180'), BTEX("end_rod_side", 'rotate_270'), BTEX("end_rod_side", 'rotate_90'), BTEX("end_rod_side", 'rotate_90'), BTEX("end_rod_side", 'rotate_90') ),
				  MultiCompactedBlock( -- facing east
					{  -6,  -6,   0, -15,  -6,  -6, -- base
					   -7,  -7,  -1,   0,  -7,  -7 }, -- stand
		            BTEX("end_rod_bottom", 'rotate_180'), BTEX("end_rod_top", 'rotate_180'), BTEX("end_rod_side", 'rotate_90'), BTEX("end_rod_side", 'rotate_270'), BTEX("end_rod_side", 'rotate_270'), BTEX("end_rod_side", 'rotate_270') ),
				  0, 0 );
		[199] = MultiCompactedConnectedBlock( -- Chorus Plant
		          {  -3,  -3,  -4,  -4,  -4,  -4}, -- nort-south part
				  {  -4,  -4,  -3,  -3,  -4,  -4}, -- west-east part
				  {  -4,  -4,  -4,  -4,  -4,   0 }, -- top-bottom part
				  BTEX("chorus_plant") );
		[200] = DataAdapter( 0x7, -- Chorus Flower
				  ChorusFlowerImmature(), -- growthstate 0
				  ChorusFlowerImmature(), -- growthstate 1
				  ChorusFlowerImmature(), -- growthstate 2
				  ChorusFlowerImmature(), -- growthstate 3
				  ChorusFlowerImmature(), -- growthstate 4
				  MultiCompactedBlock( -- growthstate 5
		          { -2,  -2,  -2,  -2,  -2,  -2, -- mid part
		             0, -14,  -2,  -2,  -2,  -2, -- north part
		           -14,   0,  -2,  -2,  -2,  -2, -- south part
		            -2,  -2,   0, -14,  -2,  -2, -- west part
		            -2,  -2, -14,   0,  -2,  -2, -- east part
		            -2,  -2,  -2,  -2,   0, -14, -- bottom part
		            -2,  -2,  -2,  -2, -14,   0}, -- top part
		          BTEX("chorus_flower_dead") ),
				  0, 0 );
		[201] = OpaqueBlock( BTEX("purpur_block") ); -- Purpur Block
		[202] = OpaqueBlock( BTEX("purpur_pillar"), BTEX("purpur_pillar_top") ); -- Purpur Pillar
		[203] = Stairs( BTEX("purpur_block") ); -- Purpur Stairs
		[204] = OpaqueBlock( BTEX("purpur_block") ); -- Purpur Double-Slab
		[205] = DataAdapter( 0x8, -- Purpur Slab
		          Slab( -8, 0, BTEX("purpur_block") ), -- bottom
		          Slab( 0, -8, BTEX("purpur_block") ) ); -- top
		[206] = OpaqueBlock( BTEX("end_bricks") ); -- End Stone Bricks
		[207] = DataAdapter( 0x3, -- Beetroot Seeds
		          HashShapedBlock( -4, BTEX("beetroots_stage_0"), 0 ), -- growthstate 0
		          HashShapedBlock( -4, BTEX("beetroots_stage_1"), 0 ), -- growthstate 1
		          HashShapedBlock( -4, BTEX("beetroots_stage_2"), 0 ), -- growthstate 2
		          HashShapedBlock( -4, BTEX("beetroots_stage_3"), 0 ) ); -- growthstate 3
		[208] = CompactedBlock( 0, 0, 0, 0, 0, -1, BTEX("grass_path_side"), BTEX("dirt"), BTEX("grass_path_top") ); -- Grass Path
		[209] = OpaqueBlock( SingleColorTexture ( 0, 0, 0, 1 ) ); -- End Gateway
		[210] = DataAdapter( 0x8, -- Command Block (Repeating Mode)
					DataAdapter( 0x7, -- unconditional
					  OpaqueBlock( BTEX("repeating_command_block_side", 'rotate_180'), BTEX("repeating_command_block_front", 'rotate_180'), BTEX("repeating_command_block_back") ), -- down
					  OpaqueBlock( BTEX("repeating_command_block_side"), BTEX("repeating_command_block_back"), BTEX("repeating_command_block_front", 'rotate_180') ), -- up
					  OpaqueBlock( BTEX("repeating_command_block_side", 'rotate_90'), BTEX("repeating_command_block_side", 'rotate_270'), BTEX("repeating_command_block_front"), BTEX("repeating_command_block_back"), BTEX("repeating_command_block_side", 'rotate_180'), BTEX("repeating_command_block_side") ), -- north
					  OpaqueBlock( BTEX("repeating_command_block_side", 'rotate_270'), BTEX("repeating_command_block_side", 'rotate_90'), BTEX("repeating_command_block_back"), BTEX("repeating_command_block_front"), BTEX("repeating_command_block_side"), BTEX("repeating_command_block_side", 'rotate_180') ), -- south
					  OpaqueBlock( BTEX("repeating_command_block_front"), BTEX("repeating_command_block_back"), BTEX("repeating_command_block_side", 'rotate_270'), BTEX("repeating_command_block_side", 'rotate_90'), BTEX("repeating_command_block_side", 'rotate_90'), BTEX("repeating_command_block_side", 'rotate_90') ), -- west
					  OpaqueBlock( BTEX("repeating_command_block_back"), BTEX("repeating_command_block_front"), BTEX("repeating_command_block_side", 'rotate_90'), BTEX("repeating_command_block_side", 'rotate_270'), BTEX("repeating_command_block_side", 'rotate_270'), BTEX("repeating_command_block_side", 'rotate_270') ), -- east
					  0, 0 ),
					DataAdapter( 0x7, -- conditional
					  OpaqueBlock( BTEX("repeating_command_block_conditional", 'rotate_180'), BTEX("repeating_command_block_front", 'rotate_180'), BTEX("repeating_command_block_back") ), -- down
					  OpaqueBlock( BTEX("repeating_command_block_conditional"), BTEX("repeating_command_block_back"), BTEX("repeating_command_block_front", 'rotate_180') ), -- up
					  OpaqueBlock( BTEX("repeating_command_block_conditional", 'rotate_90'), BTEX("repeating_command_block_conditional", 'rotate_270'), BTEX("repeating_command_block_front"), BTEX("repeating_command_block_back"), BTEX("repeating_command_block_conditional", 'rotate_180'), BTEX("repeating_command_block_conditional") ), -- north
					  OpaqueBlock( BTEX("repeating_command_block_conditional", 'rotate_270'), BTEX("repeating_command_block_conditional", 'rotate_90'), BTEX("repeating_command_block_back"), BTEX("repeating_command_block_front"), BTEX("repeating_command_block_conditional"), BTEX("repeating_command_block_conditional", 'rotate_180') ), -- south
					  OpaqueBlock( BTEX("repeating_command_block_front"), BTEX("repeating_command_block_back"), BTEX("repeating_command_block_conditional", 'rotate_270'), BTEX("repeating_command_block_conditional", 'rotate_90'), BTEX("repeating_command_block_conditional", 'rotate_90'), BTEX("repeating_command_block_conditional", 'rotate_90') ), -- west
					  OpaqueBlock( BTEX("repeating_command_block_back"), BTEX("repeating_command_block_front"), BTEX("repeating_command_block_conditional", 'rotate_90'), BTEX("repeating_command_block_conditional", 'rotate_270'), BTEX("repeating_command_block_conditional", 'rotate_270'), BTEX("repeating_command_block_conditional", 'rotate_270') ), -- east
					  0, 0 ) );
		[211] = DataAdapter( 0x8, -- Command Block (Chain Mode)
					DataAdapter( 0x7, -- unconditional
					  OpaqueBlock( BTEX("chain_command_block_side", 'rotate_180'), BTEX("chain_command_block_front", 'rotate_180'), BTEX("chain_command_block_back") ), -- down
					  OpaqueBlock( BTEX("chain_command_block_side"), BTEX("chain_command_block_back"), BTEX("chain_command_block_front", 'rotate_180') ), -- up
					  OpaqueBlock( BTEX("chain_command_block_side", 'rotate_90'), BTEX("chain_command_block_side", 'rotate_270'), BTEX("chain_command_block_front"), BTEX("chain_command_block_back"), BTEX("chain_command_block_side", 'rotate_180'), BTEX("chain_command_block_side") ), -- north
					  OpaqueBlock( BTEX("chain_command_block_side", 'rotate_270'), BTEX("chain_command_block_side", 'rotate_90'), BTEX("chain_command_block_back"), BTEX("chain_command_block_front"), BTEX("chain_command_block_side"), BTEX("chain_command_block_side", 'rotate_180') ), -- south
					  OpaqueBlock( BTEX("chain_command_block_front"), BTEX("chain_command_block_back"), BTEX("chain_command_block_side", 'rotate_270'), BTEX("chain_command_block_side", 'rotate_90'), BTEX("chain_command_block_side", 'rotate_90'), BTEX("chain_command_block_side", 'rotate_90') ), -- west
					  OpaqueBlock( BTEX("chain_command_block_back"), BTEX("chain_command_block_front"), BTEX("chain_command_block_side", 'rotate_90'), BTEX("chain_command_block_side", 'rotate_270'), BTEX("chain_command_block_side", 'rotate_270'), BTEX("chain_command_block_side", 'rotate_270') ), -- east
					  0, 0 ),
					DataAdapter( 0x7, -- conditional
					  OpaqueBlock( BTEX("chain_command_block_conditional", 'rotate_180'), BTEX("chain_command_block_front", 'rotate_180'), BTEX("chain_command_block_back") ), -- down
					  OpaqueBlock( BTEX("chain_command_block_conditional"), BTEX("chain_command_block_back"), BTEX("chain_command_block_front", 'rotate_180') ), -- up
					  OpaqueBlock( BTEX("chain_command_block_conditional", 'rotate_90'), BTEX("chain_command_block_conditional", 'rotate_270'), BTEX("chain_command_block_front"), BTEX("chain_command_block_back"), BTEX("chain_command_block_conditional", 'rotate_180'), BTEX("chain_command_block_conditional") ), -- north
					  OpaqueBlock( BTEX("chain_command_block_conditional", 'rotate_270'), BTEX("chain_command_block_conditional", 'rotate_90'), BTEX("chain_command_block_back"), BTEX("chain_command_block_front"), BTEX("chain_command_block_conditional"), BTEX("chain_command_block_conditional", 'rotate_180') ), -- south
					  OpaqueBlock( BTEX("chain_command_block_front"), BTEX("chain_command_block_back"), BTEX("chain_command_block_conditional", 'rotate_270'), BTEX("chain_command_block_conditional", 'rotate_90'), BTEX("chain_command_block_conditional", 'rotate_90'), BTEX("chain_command_block_conditional", 'rotate_90') ), -- west
					  OpaqueBlock( BTEX("chain_command_block_back"), BTEX("chain_command_block_front"), BTEX("chain_command_block_conditional", 'rotate_90'), BTEX("chain_command_block_conditional", 'rotate_270'), BTEX("chain_command_block_conditional", 'rotate_270'), BTEX("chain_command_block_conditional", 'rotate_270') ), -- east
					  0, 0 ) );
		[212] = DataAdapter( 0x3, -- Frosted Ice
		          DelayRender( TransparentBlock( 0, BTEX("frosted_ice_0") ), 5 ), -- age 0
		          DelayRender( TransparentBlock( 0, BTEX("frosted_ice_1") ), 5 ), -- age 1
		          DelayRender( TransparentBlock( 0, BTEX("frosted_ice_2") ), 5 ), -- age 2
		          DelayRender( TransparentBlock( 0, BTEX("frosted_ice_3") ), 5 ) ); -- age 3
		[213] = OpaqueBlock( BTEX( "magma") ); -- Magma Block
		[214] = OpaqueBlock( BTEX("nether_wart_block") ); -- Nether Wart Block
		[215] = OpaqueBlock( BTEX("red_nether_brick") ); -- Red Nether Brick
		[216] = DataAdapter( 0xc, -- Bone Block
				  OpaqueBlock( BTEX("bone_block_side"), BTEX("bone_block_top") ), -- top-bottom
				  OpaqueBlock( BTEX("bone_block_top"), BTEX("bone_block_top", 'rotate_180'), BTEX("bone_block_side", 'rotate_90'), BTEX("bone_block_side", 'rotate_270'), BTEX("bone_block_side", 'rotate_270'), BTEX("bone_block_side", 'rotate_270') ), -- west-east
				  OpaqueBlock( BTEX("bone_block_side", 'rotate_90'), BTEX("bone_block_side", 'rotate_270'), BTEX("bone_block_top", 'rotate_180'), BTEX("bone_block_top"), BTEX("bone_block_side", 'rotate_180'), BTEX("bone_block_side") ), -- north-south
				  0 );
		-- [217] -- Structure Void
		[218] = DataAdapter( 0x8, -- Observer
		          DataAdapter( 0x7, -- unpowered
					  OpaqueBlock( BTEX("observer_side", 'rotate_90'), BTEX("observer_side", 'rotate_270'), BTEX("observer_top", 'flip_x'), BTEX("observer_top"), BTEX("observer_front", 'rotate_180'), BTEX("observer_back") ), -- facing down
					  OpaqueBlock( BTEX("observer_side", 'rotate_270'), BTEX("observer_side", 'rotate_270'), BTEX("observer_top", 'rotate_180'), BTEX("observer_top", 'flip_y'), BTEX("observer_back"), BTEX("observer_front", 'rotate_180') ), -- facing up
					  OpaqueBlock( BTEX("observer_side"), BTEX("observer_side"), BTEX("observer_front"), BTEX("observer_back"), BTEX("observer_top"), BTEX("observer_top", 'flip_y') ), -- facing north
					  OpaqueBlock( BTEX("observer_side"), BTEX("observer_side"), BTEX("observer_back"), BTEX("observer_front"), BTEX("observer_top", 'rotate_180'), BTEX("observer_top", 'flip_x') ), -- facing south
					  OpaqueBlock( BTEX("observer_front"), BTEX("observer_back"), BTEX("observer_side"), BTEX("observer_side"), BTEX("observer_top", 'rotate_270'), BTEX("observer_top", 'rotate_90', 'flip_x') ), -- facing west
					  OpaqueBlock( BTEX("observer_back"), BTEX("observer_front"), BTEX("observer_side"), BTEX("observer_side"), BTEX("observer_top", 'rotate_90'), BTEX("observer_top", 'rotate_90', 'flip_y') ), -- facing east
					  0, 0 ),
		          DataAdapter( 0x7, -- powered
					  OpaqueBlock( BTEX("observer_side", 'rotate_90'), BTEX("observer_side", 'rotate_270'), BTEX("observer_top", 'flip_x'), BTEX("observer_top"), BTEX("observer_front", 'rotate_180'), BTEX("observer_back_lit") ), -- facing down
					  OpaqueBlock( BTEX("observer_side", 'rotate_270'), BTEX("observer_side", 'rotate_270'), BTEX("observer_top", 'rotate_180'), BTEX("observer_top", 'flip_y'), BTEX("observer_back_lit"), BTEX("observer_front", 'rotate_180') ), -- facing up
					  OpaqueBlock( BTEX("observer_side"), BTEX("observer_side"), BTEX("observer_front"), BTEX("observer_back_lit"), BTEX("observer_top"), BTEX("observer_top", 'flip_y') ), -- facing north
					  OpaqueBlock( BTEX("observer_side"), BTEX("observer_side"), BTEX("observer_back_lit"), BTEX("observer_front"), BTEX("observer_top", 'rotate_180'), BTEX("observer_top", 'flip_x') ), -- facing south
					  OpaqueBlock( BTEX("observer_front"), BTEX("observer_back_lit"), BTEX("observer_side"), BTEX("observer_side"), BTEX("observer_top", 'rotate_270'), BTEX("observer_top", 'rotate_90', 'flip_x') ), -- facing west
					  OpaqueBlock( BTEX("observer_back_lit"), BTEX("observer_front"), BTEX("observer_side"), BTEX("observer_side"), BTEX("observer_top", 'rotate_90'), BTEX("observer_top", 'rotate_90', 'flip_y') ), -- facing east
					  0, 0 ) );
		[219] = DataAdapter( 0x7, -- White Shulker Box
		          OpaqueBlock( BTEX("shulker_white_side_left", 'rotate_180'), BTEX("shulker_white_side_right", 'rotate_180'), BTEX("shulker_white_side_front", 'rotate_180'), BTEX("shulker_white_side_back", 'rotate_180'), BTEX("shulker_white_top"), BTEX("shulker_white_bottom", 'flip_y') ), -- facing down
		          OpaqueBlock( BTEX("shulker_white_side_left"), BTEX("shulker_white_side_right"), BTEX("shulker_white_side_back"), BTEX("shulker_white_side_front"), BTEX("shulker_white_bottom", 'flip_y'), BTEX("shulker_white_top") ), -- facing up
		          OpaqueBlock( BTEX("shulker_white_side_right", 'rotate_90'), BTEX("shulker_white_side_left", 'rotate_270'), BTEX("shulker_white_top"), BTEX("shulker_white_bottom", 'flip_x'), BTEX("shulker_white_side_front", 'rotate_180'), BTEX("shulker_white_side_back") ), -- facing north
		          OpaqueBlock( BTEX("shulker_white_side_left", 'rotate_270'), BTEX("shulker_white_side_right", 'rotate_90'), BTEX("shulker_white_bottom", 'flip_x'), BTEX("shulker_white_top"), BTEX("shulker_white_side_front"), BTEX("shulker_white_side_back", 'rotate_180') ), -- facing south
		          OpaqueBlock( BTEX("shulker_white_top"), BTEX("shulker_white_bottom", 'flip_x'), BTEX("shulker_white_side_left", 'rotate_270'), BTEX("shulker_white_side_right", 'rotate_90'), BTEX("shulker_white_side_front", 'rotate_90'), BTEX("shulker_white_side_back", 'rotate_90') ), -- facing west
		          OpaqueBlock( BTEX("shulker_white_bottom", 'flip_x'), BTEX("shulker_white_top"), BTEX("shulker_white_side_right", 'rotate_90'), BTEX("shulker_white_side_left", 'rotate_270'), BTEX("shulker_white_side_front", 'rotate_270'), BTEX("shulker_white_side_back", 'rotate_270') ), -- facing east
				  0, 0 );
		[220] = DataAdapter( 0x7, -- Orange Shulker Box
		          OpaqueBlock( BTEX("shulker_orange_side_left", 'rotate_180'), BTEX("shulker_orange_side_right", 'rotate_180'), BTEX("shulker_orange_side_front", 'rotate_180'), BTEX("shulker_orange_side_back", 'rotate_180'), BTEX("shulker_orange_top"), BTEX("shulker_orange_bottom", 'flip_y') ), -- facing down
		          OpaqueBlock( BTEX("shulker_orange_side_left"), BTEX("shulker_orange_side_right"), BTEX("shulker_orange_side_back"), BTEX("shulker_orange_side_front"), BTEX("shulker_orange_bottom", 'flip_y'), BTEX("shulker_orange_top") ), -- facing up
		          OpaqueBlock( BTEX("shulker_orange_side_right", 'rotate_90'), BTEX("shulker_orange_side_left", 'rotate_270'), BTEX("shulker_orange_top"), BTEX("shulker_orange_bottom", 'flip_x'), BTEX("shulker_orange_side_front", 'rotate_180'), BTEX("shulker_orange_side_back") ), -- facing north
		          OpaqueBlock( BTEX("shulker_orange_side_left", 'rotate_270'), BTEX("shulker_orange_side_right", 'rotate_90'), BTEX("shulker_orange_bottom", 'flip_x'), BTEX("shulker_orange_top"), BTEX("shulker_orange_side_front"), BTEX("shulker_orange_side_back", 'rotate_180') ), -- facing south
		          OpaqueBlock( BTEX("shulker_orange_top"), BTEX("shulker_orange_bottom", 'flip_x'), BTEX("shulker_orange_side_left", 'rotate_270'), BTEX("shulker_orange_side_right", 'rotate_90'), BTEX("shulker_orange_side_front", 'rotate_90'), BTEX("shulker_orange_side_back", 'rotate_90') ), -- facing west
		          OpaqueBlock( BTEX("shulker_orange_bottom", 'flip_x'), BTEX("shulker_orange_top"), BTEX("shulker_orange_side_right", 'rotate_90'), BTEX("shulker_orange_side_left", 'rotate_270'), BTEX("shulker_orange_side_front", 'rotate_270'), BTEX("shulker_orange_side_back", 'rotate_270') ), -- facing east
				  0, 0 );
		[221] = DataAdapter( 0x7, -- Magenta Shulker Box
		          OpaqueBlock( BTEX("shulker_magenta_side_left", 'rotate_180'), BTEX("shulker_magenta_side_right", 'rotate_180'), BTEX("shulker_magenta_side_front", 'rotate_180'), BTEX("shulker_magenta_side_back", 'rotate_180'), BTEX("shulker_magenta_top"), BTEX("shulker_magenta_bottom", 'flip_y') ), -- facing down
		          OpaqueBlock( BTEX("shulker_magenta_side_left"), BTEX("shulker_magenta_side_right"), BTEX("shulker_magenta_side_back"), BTEX("shulker_magenta_side_front"), BTEX("shulker_magenta_bottom", 'flip_y'), BTEX("shulker_magenta_top") ), -- facing up
		          OpaqueBlock( BTEX("shulker_magenta_side_right", 'rotate_90'), BTEX("shulker_magenta_side_left", 'rotate_270'), BTEX("shulker_magenta_top"), BTEX("shulker_magenta_bottom", 'flip_x'), BTEX("shulker_magenta_side_front", 'rotate_180'), BTEX("shulker_magenta_side_back") ), -- facing north
		          OpaqueBlock( BTEX("shulker_magenta_side_left", 'rotate_270'), BTEX("shulker_magenta_side_right", 'rotate_90'), BTEX("shulker_magenta_bottom", 'flip_x'), BTEX("shulker_magenta_top"), BTEX("shulker_magenta_side_front"), BTEX("shulker_magenta_side_back", 'rotate_180') ), -- facing south
		          OpaqueBlock( BTEX("shulker_magenta_top"), BTEX("shulker_magenta_bottom", 'flip_x'), BTEX("shulker_magenta_side_left", 'rotate_270'), BTEX("shulker_magenta_side_right", 'rotate_90'), BTEX("shulker_magenta_side_front", 'rotate_90'), BTEX("shulker_magenta_side_back", 'rotate_90') ), -- facing west
		          OpaqueBlock( BTEX("shulker_magenta_bottom", 'flip_x'), BTEX("shulker_magenta_top"), BTEX("shulker_magenta_side_right", 'rotate_90'), BTEX("shulker_magenta_side_left", 'rotate_270'), BTEX("shulker_magenta_side_front", 'rotate_270'), BTEX("shulker_magenta_side_back", 'rotate_270') ), -- facing east
				  0, 0 );
		[222] = DataAdapter( 0x7, -- Light Blue Shulker Box
		          OpaqueBlock( BTEX("shulker_light_blue_side_left", 'rotate_180'), BTEX("shulker_light_blue_side_right", 'rotate_180'), BTEX("shulker_light_blue_side_front", 'rotate_180'), BTEX("shulker_light_blue_side_back", 'rotate_180'), BTEX("shulker_light_blue_top"), BTEX("shulker_light_blue_bottom", 'flip_y') ), -- facing down
		          OpaqueBlock( BTEX("shulker_light_blue_side_left"), BTEX("shulker_light_blue_side_right"), BTEX("shulker_light_blue_side_back"), BTEX("shulker_light_blue_side_front"), BTEX("shulker_light_blue_bottom", 'flip_y'), BTEX("shulker_light_blue_top") ), -- facing up
		          OpaqueBlock( BTEX("shulker_light_blue_side_right", 'rotate_90'), BTEX("shulker_light_blue_side_left", 'rotate_270'), BTEX("shulker_light_blue_top"), BTEX("shulker_light_blue_bottom", 'flip_x'), BTEX("shulker_light_blue_side_front", 'rotate_180'), BTEX("shulker_light_blue_side_back") ), -- facing north
		          OpaqueBlock( BTEX("shulker_light_blue_side_left", 'rotate_270'), BTEX("shulker_light_blue_side_right", 'rotate_90'), BTEX("shulker_light_blue_bottom", 'flip_x'), BTEX("shulker_light_blue_top"), BTEX("shulker_light_blue_side_front"), BTEX("shulker_light_blue_side_back", 'rotate_180') ), -- facing south
		          OpaqueBlock( BTEX("shulker_light_blue_top"), BTEX("shulker_light_blue_bottom", 'flip_x'), BTEX("shulker_light_blue_side_left", 'rotate_270'), BTEX("shulker_light_blue_side_right", 'rotate_90'), BTEX("shulker_light_blue_side_front", 'rotate_90'), BTEX("shulker_light_blue_side_back", 'rotate_90') ), -- facing west
		          OpaqueBlock( BTEX("shulker_light_blue_bottom", 'flip_x'), BTEX("shulker_light_blue_top"), BTEX("shulker_light_blue_side_right", 'rotate_90'), BTEX("shulker_light_blue_side_left", 'rotate_270'), BTEX("shulker_light_blue_side_front", 'rotate_270'), BTEX("shulker_light_blue_side_back", 'rotate_270') ), -- facing east
				  0, 0 );
		[223] = DataAdapter( 0x7, -- Yellow Shulker Box
		          OpaqueBlock( BTEX("shulker_yellow_side_left", 'rotate_180'), BTEX("shulker_yellow_side_right", 'rotate_180'), BTEX("shulker_yellow_side_front", 'rotate_180'), BTEX("shulker_yellow_side_back", 'rotate_180'), BTEX("shulker_yellow_top"), BTEX("shulker_yellow_bottom", 'flip_y') ), -- facing down
		          OpaqueBlock( BTEX("shulker_yellow_side_left"), BTEX("shulker_yellow_side_right"), BTEX("shulker_yellow_side_back"), BTEX("shulker_yellow_side_front"), BTEX("shulker_yellow_bottom", 'flip_y'), BTEX("shulker_yellow_top") ), -- facing up
		          OpaqueBlock( BTEX("shulker_yellow_side_right", 'rotate_90'), BTEX("shulker_yellow_side_left", 'rotate_270'), BTEX("shulker_yellow_top"), BTEX("shulker_yellow_bottom", 'flip_x'), BTEX("shulker_yellow_side_front", 'rotate_180'), BTEX("shulker_yellow_side_back") ), -- facing north
		          OpaqueBlock( BTEX("shulker_yellow_side_left", 'rotate_270'), BTEX("shulker_yellow_side_right", 'rotate_90'), BTEX("shulker_yellow_bottom", 'flip_x'), BTEX("shulker_yellow_top"), BTEX("shulker_yellow_side_front"), BTEX("shulker_yellow_side_back", 'rotate_180') ), -- facing south
		          OpaqueBlock( BTEX("shulker_yellow_top"), BTEX("shulker_yellow_bottom", 'flip_x'), BTEX("shulker_yellow_side_left", 'rotate_270'), BTEX("shulker_yellow_side_right", 'rotate_90'), BTEX("shulker_yellow_side_front", 'rotate_90'), BTEX("shulker_yellow_side_back", 'rotate_90') ), -- facing west
		          OpaqueBlock( BTEX("shulker_yellow_bottom", 'flip_x'), BTEX("shulker_yellow_top"), BTEX("shulker_yellow_side_right", 'rotate_90'), BTEX("shulker_yellow_side_left", 'rotate_270'), BTEX("shulker_yellow_side_front", 'rotate_270'), BTEX("shulker_yellow_side_back", 'rotate_270') ), -- facing east
				  0, 0 );
		[224] = DataAdapter( 0x7, -- Lime Shulker Box
		          OpaqueBlock( BTEX("shulker_lime_side_left", 'rotate_180'), BTEX("shulker_lime_side_right", 'rotate_180'), BTEX("shulker_lime_side_front", 'rotate_180'), BTEX("shulker_lime_side_back", 'rotate_180'), BTEX("shulker_lime_top"), BTEX("shulker_lime_bottom", 'flip_y') ), -- facing down
		          OpaqueBlock( BTEX("shulker_lime_side_left"), BTEX("shulker_lime_side_right"), BTEX("shulker_lime_side_back"), BTEX("shulker_lime_side_front"), BTEX("shulker_lime_bottom", 'flip_y'), BTEX("shulker_lime_top") ), -- facing up
		          OpaqueBlock( BTEX("shulker_lime_side_right", 'rotate_90'), BTEX("shulker_lime_side_left", 'rotate_270'), BTEX("shulker_lime_top"), BTEX("shulker_lime_bottom", 'flip_x'), BTEX("shulker_lime_side_front", 'rotate_180'), BTEX("shulker_lime_side_back") ), -- facing north
		          OpaqueBlock( BTEX("shulker_lime_side_left", 'rotate_270'), BTEX("shulker_lime_side_right", 'rotate_90'), BTEX("shulker_lime_bottom", 'flip_x'), BTEX("shulker_lime_top"), BTEX("shulker_lime_side_front"), BTEX("shulker_lime_side_back", 'rotate_180') ), -- facing south
		          OpaqueBlock( BTEX("shulker_lime_top"), BTEX("shulker_lime_bottom", 'flip_x'), BTEX("shulker_lime_side_left", 'rotate_270'), BTEX("shulker_lime_side_right", 'rotate_90'), BTEX("shulker_lime_side_front", 'rotate_90'), BTEX("shulker_lime_side_back", 'rotate_90') ), -- facing west
		          OpaqueBlock( BTEX("shulker_lime_bottom", 'flip_x'), BTEX("shulker_lime_top"), BTEX("shulker_lime_side_right", 'rotate_90'), BTEX("shulker_lime_side_left", 'rotate_270'), BTEX("shulker_lime_side_front", 'rotate_270'), BTEX("shulker_lime_side_back", 'rotate_270') ), -- facing east
				  0, 0 );
		[225] = DataAdapter( 0x7, -- Pink Shulker Box
		          OpaqueBlock( BTEX("shulker_pink_side_left", 'rotate_180'), BTEX("shulker_pink_side_right", 'rotate_180'), BTEX("shulker_pink_side_front", 'rotate_180'), BTEX("shulker_pink_side_back", 'rotate_180'), BTEX("shulker_pink_top"), BTEX("shulker_pink_bottom", 'flip_y') ), -- facing down
		          OpaqueBlock( BTEX("shulker_pink_side_left"), BTEX("shulker_pink_side_right"), BTEX("shulker_pink_side_back"), BTEX("shulker_pink_side_front"), BTEX("shulker_pink_bottom", 'flip_y'), BTEX("shulker_pink_top") ), -- facing up
		          OpaqueBlock( BTEX("shulker_pink_side_right", 'rotate_90'), BTEX("shulker_pink_side_left", 'rotate_270'), BTEX("shulker_pink_top"), BTEX("shulker_pink_bottom", 'flip_x'), BTEX("shulker_pink_side_front", 'rotate_180'), BTEX("shulker_pink_side_back") ), -- facing north
		          OpaqueBlock( BTEX("shulker_pink_side_left", 'rotate_270'), BTEX("shulker_pink_side_right", 'rotate_90'), BTEX("shulker_pink_bottom", 'flip_x'), BTEX("shulker_pink_top"), BTEX("shulker_pink_side_front"), BTEX("shulker_pink_side_back", 'rotate_180') ), -- facing south
		          OpaqueBlock( BTEX("shulker_pink_top"), BTEX("shulker_pink_bottom", 'flip_x'), BTEX("shulker_pink_side_left", 'rotate_270'), BTEX("shulker_pink_side_right", 'rotate_90'), BTEX("shulker_pink_side_front", 'rotate_90'), BTEX("shulker_pink_side_back", 'rotate_90') ), -- facing west
		          OpaqueBlock( BTEX("shulker_pink_bottom", 'flip_x'), BTEX("shulker_pink_top"), BTEX("shulker_pink_side_right", 'rotate_90'), BTEX("shulker_pink_side_left", 'rotate_270'), BTEX("shulker_pink_side_front", 'rotate_270'), BTEX("shulker_pink_side_back", 'rotate_270') ), -- facing east
				  0, 0 );
		[226] = DataAdapter( 0x7, -- Gray Shulker Box
		          OpaqueBlock( BTEX("shulker_gray_side_left", 'rotate_180'), BTEX("shulker_gray_side_right", 'rotate_180'), BTEX("shulker_gray_side_front", 'rotate_180'), BTEX("shulker_gray_side_back", 'rotate_180'), BTEX("shulker_gray_top"), BTEX("shulker_gray_bottom", 'flip_y') ), -- facing down
		          OpaqueBlock( BTEX("shulker_gray_side_left"), BTEX("shulker_gray_side_right"), BTEX("shulker_gray_side_back"), BTEX("shulker_gray_side_front"), BTEX("shulker_gray_bottom", 'flip_y'), BTEX("shulker_gray_top") ), -- facing up
		          OpaqueBlock( BTEX("shulker_gray_side_right", 'rotate_90'), BTEX("shulker_gray_side_left", 'rotate_270'), BTEX("shulker_gray_top"), BTEX("shulker_gray_bottom", 'flip_x'), BTEX("shulker_gray_side_front", 'rotate_180'), BTEX("shulker_gray_side_back") ), -- facing north
		          OpaqueBlock( BTEX("shulker_gray_side_left", 'rotate_270'), BTEX("shulker_gray_side_right", 'rotate_90'), BTEX("shulker_gray_bottom", 'flip_x'), BTEX("shulker_gray_top"), BTEX("shulker_gray_side_front"), BTEX("shulker_gray_side_back", 'rotate_180') ), -- facing south
		          OpaqueBlock( BTEX("shulker_gray_top"), BTEX("shulker_gray_bottom", 'flip_x'), BTEX("shulker_gray_side_left", 'rotate_270'), BTEX("shulker_gray_side_right", 'rotate_90'), BTEX("shulker_gray_side_front", 'rotate_90'), BTEX("shulker_gray_side_back", 'rotate_90') ), -- facing west
		          OpaqueBlock( BTEX("shulker_gray_bottom", 'flip_x'), BTEX("shulker_gray_top"), BTEX("shulker_gray_side_right", 'rotate_90'), BTEX("shulker_gray_side_left", 'rotate_270'), BTEX("shulker_gray_side_front", 'rotate_270'), BTEX("shulker_gray_side_back", 'rotate_270') ), -- facing east
				  0, 0 );
		[227] = DataAdapter( 0x7, -- Light Gray Shulker Box
		          OpaqueBlock( BTEX("shulker_silver_side_left", 'rotate_180'), BTEX("shulker_silver_side_right", 'rotate_180'), BTEX("shulker_silver_side_front", 'rotate_180'), BTEX("shulker_silver_side_back", 'rotate_180'), BTEX("shulker_silver_top"), BTEX("shulker_silver_bottom", 'flip_y') ), -- facing down
		          OpaqueBlock( BTEX("shulker_silver_side_left"), BTEX("shulker_silver_side_right"), BTEX("shulker_silver_side_back"), BTEX("shulker_silver_side_front"), BTEX("shulker_silver_bottom", 'flip_y'), BTEX("shulker_silver_top") ), -- facing up
		          OpaqueBlock( BTEX("shulker_silver_side_right", 'rotate_90'), BTEX("shulker_silver_side_left", 'rotate_270'), BTEX("shulker_silver_top"), BTEX("shulker_silver_bottom", 'flip_x'), BTEX("shulker_silver_side_front", 'rotate_180'), BTEX("shulker_silver_side_back") ), -- facing north
		          OpaqueBlock( BTEX("shulker_silver_side_left", 'rotate_270'), BTEX("shulker_silver_side_right", 'rotate_90'), BTEX("shulker_silver_bottom", 'flip_x'), BTEX("shulker_silver_top"), BTEX("shulker_silver_side_front"), BTEX("shulker_silver_side_back", 'rotate_180') ), -- facing south
		          OpaqueBlock( BTEX("shulker_silver_top"), BTEX("shulker_silver_bottom", 'flip_x'), BTEX("shulker_silver_side_left", 'rotate_270'), BTEX("shulker_silver_side_right", 'rotate_90'), BTEX("shulker_silver_side_front", 'rotate_90'), BTEX("shulker_silver_side_back", 'rotate_90') ), -- facing west
		          OpaqueBlock( BTEX("shulker_silver_bottom", 'flip_x'), BTEX("shulker_silver_top"), BTEX("shulker_silver_side_right", 'rotate_90'), BTEX("shulker_silver_side_left", 'rotate_270'), BTEX("shulker_silver_side_front", 'rotate_270'), BTEX("shulker_silver_side_back", 'rotate_270') ), -- facing east
				  0, 0 );
		[228] = DataAdapter( 0x7, -- Cyan Shulker Box
		          OpaqueBlock( BTEX("shulker_cyan_side_left", 'rotate_180'), BTEX("shulker_cyan_side_right", 'rotate_180'), BTEX("shulker_cyan_side_front", 'rotate_180'), BTEX("shulker_cyan_side_back", 'rotate_180'), BTEX("shulker_cyan_top"), BTEX("shulker_cyan_bottom", 'flip_y') ), -- facing down
		          OpaqueBlock( BTEX("shulker_cyan_side_left"), BTEX("shulker_cyan_side_right"), BTEX("shulker_cyan_side_back"), BTEX("shulker_cyan_side_front"), BTEX("shulker_cyan_bottom", 'flip_y'), BTEX("shulker_cyan_top") ), -- facing up
		          OpaqueBlock( BTEX("shulker_cyan_side_right", 'rotate_90'), BTEX("shulker_cyan_side_left", 'rotate_270'), BTEX("shulker_cyan_top"), BTEX("shulker_cyan_bottom", 'flip_x'), BTEX("shulker_cyan_side_front", 'rotate_180'), BTEX("shulker_cyan_side_back") ), -- facing north
		          OpaqueBlock( BTEX("shulker_cyan_side_left", 'rotate_270'), BTEX("shulker_cyan_side_right", 'rotate_90'), BTEX("shulker_cyan_bottom", 'flip_x'), BTEX("shulker_cyan_top"), BTEX("shulker_cyan_side_front"), BTEX("shulker_cyan_side_back", 'rotate_180') ), -- facing south
		          OpaqueBlock( BTEX("shulker_cyan_top"), BTEX("shulker_cyan_bottom", 'flip_x'), BTEX("shulker_cyan_side_left", 'rotate_270'), BTEX("shulker_cyan_side_right", 'rotate_90'), BTEX("shulker_cyan_side_front", 'rotate_90'), BTEX("shulker_cyan_side_back", 'rotate_90') ), -- facing west
		          OpaqueBlock( BTEX("shulker_cyan_bottom", 'flip_x'), BTEX("shulker_cyan_top"), BTEX("shulker_cyan_side_right", 'rotate_90'), BTEX("shulker_cyan_side_left", 'rotate_270'), BTEX("shulker_cyan_side_front", 'rotate_270'), BTEX("shulker_cyan_side_back", 'rotate_270') ), -- facing east
				  0, 0 );
		[229] = DataAdapter( 0x7, -- Purple Shulker Box
		          OpaqueBlock( BTEX("shulker_purple_side_left", 'rotate_180'), BTEX("shulker_purple_side_right", 'rotate_180'), BTEX("shulker_purple_side_front", 'rotate_180'), BTEX("shulker_purple_side_back", 'rotate_180'), BTEX("shulker_purple_top"), BTEX("shulker_purple_bottom", 'flip_y') ), -- facing down
		          OpaqueBlock( BTEX("shulker_purple_side_left"), BTEX("shulker_purple_side_right"), BTEX("shulker_purple_side_back"), BTEX("shulker_purple_side_front"), BTEX("shulker_purple_bottom", 'flip_y'), BTEX("shulker_purple_top") ), -- facing up
		          OpaqueBlock( BTEX("shulker_purple_side_right", 'rotate_90'), BTEX("shulker_purple_side_left", 'rotate_270'), BTEX("shulker_purple_top"), BTEX("shulker_purple_bottom", 'flip_x'), BTEX("shulker_purple_side_front", 'rotate_180'), BTEX("shulker_purple_side_back") ), -- facing north
		          OpaqueBlock( BTEX("shulker_purple_side_left", 'rotate_270'), BTEX("shulker_purple_side_right", 'rotate_90'), BTEX("shulker_purple_bottom", 'flip_x'), BTEX("shulker_purple_top"), BTEX("shulker_purple_side_front"), BTEX("shulker_purple_side_back", 'rotate_180') ), -- facing south
		          OpaqueBlock( BTEX("shulker_purple_top"), BTEX("shulker_purple_bottom", 'flip_x'), BTEX("shulker_purple_side_left", 'rotate_270'), BTEX("shulker_purple_side_right", 'rotate_90'), BTEX("shulker_purple_side_front", 'rotate_90'), BTEX("shulker_purple_side_back", 'rotate_90') ), -- facing west
		          OpaqueBlock( BTEX("shulker_purple_bottom", 'flip_x'), BTEX("shulker_purple_top"), BTEX("shulker_purple_side_right", 'rotate_90'), BTEX("shulker_purple_side_left", 'rotate_270'), BTEX("shulker_purple_side_front", 'rotate_270'), BTEX("shulker_purple_side_back", 'rotate_270') ), -- facing east
				  0, 0 );
		[230] = DataAdapter( 0x7, -- Blue Shulker Box
		          OpaqueBlock( BTEX("shulker_blue_side_left", 'rotate_180'), BTEX("shulker_blue_side_right", 'rotate_180'), BTEX("shulker_blue_side_front", 'rotate_180'), BTEX("shulker_blue_side_back", 'rotate_180'), BTEX("shulker_blue_top"), BTEX("shulker_blue_bottom", 'flip_y') ), -- facing down
		          OpaqueBlock( BTEX("shulker_blue_side_left"), BTEX("shulker_blue_side_right"), BTEX("shulker_blue_side_back"), BTEX("shulker_blue_side_front"), BTEX("shulker_blue_bottom", 'flip_y'), BTEX("shulker_blue_top") ), -- facing up
		          OpaqueBlock( BTEX("shulker_blue_side_right", 'rotate_90'), BTEX("shulker_blue_side_left", 'rotate_270'), BTEX("shulker_blue_top"), BTEX("shulker_blue_bottom", 'flip_x'), BTEX("shulker_blue_side_front", 'rotate_180'), BTEX("shulker_blue_side_back") ), -- facing north
		          OpaqueBlock( BTEX("shulker_blue_side_left", 'rotate_270'), BTEX("shulker_blue_side_right", 'rotate_90'), BTEX("shulker_blue_bottom", 'flip_x'), BTEX("shulker_blue_top"), BTEX("shulker_blue_side_front"), BTEX("shulker_blue_side_back", 'rotate_180') ), -- facing south
		          OpaqueBlock( BTEX("shulker_blue_top"), BTEX("shulker_blue_bottom", 'flip_x'), BTEX("shulker_blue_side_left", 'rotate_270'), BTEX("shulker_blue_side_right", 'rotate_90'), BTEX("shulker_blue_side_front", 'rotate_90'), BTEX("shulker_blue_side_back", 'rotate_90') ), -- facing west
		          OpaqueBlock( BTEX("shulker_blue_bottom", 'flip_x'), BTEX("shulker_blue_top"), BTEX("shulker_blue_side_right", 'rotate_90'), BTEX("shulker_blue_side_left", 'rotate_270'), BTEX("shulker_blue_side_front", 'rotate_270'), BTEX("shulker_blue_side_back", 'rotate_270') ), -- facing east
				  0, 0 );
		[231] = DataAdapter( 0x7, -- Brown Shulker Box
		          OpaqueBlock( BTEX("shulker_brown_side_left", 'rotate_180'), BTEX("shulker_brown_side_right", 'rotate_180'), BTEX("shulker_brown_side_front", 'rotate_180'), BTEX("shulker_brown_side_back", 'rotate_180'), BTEX("shulker_brown_top"), BTEX("shulker_brown_bottom", 'flip_y') ), -- facing down
		          OpaqueBlock( BTEX("shulker_brown_side_left"), BTEX("shulker_brown_side_right"), BTEX("shulker_brown_side_back"), BTEX("shulker_brown_side_front"), BTEX("shulker_brown_bottom", 'flip_y'), BTEX("shulker_brown_top") ), -- facing up
		          OpaqueBlock( BTEX("shulker_brown_side_right", 'rotate_90'), BTEX("shulker_brown_side_left", 'rotate_270'), BTEX("shulker_brown_top"), BTEX("shulker_brown_bottom", 'flip_x'), BTEX("shulker_brown_side_front", 'rotate_180'), BTEX("shulker_brown_side_back") ), -- facing north
		          OpaqueBlock( BTEX("shulker_brown_side_left", 'rotate_270'), BTEX("shulker_brown_side_right", 'rotate_90'), BTEX("shulker_brown_bottom", 'flip_x'), BTEX("shulker_brown_top"), BTEX("shulker_brown_side_front"), BTEX("shulker_brown_side_back", 'rotate_180') ), -- facing south
		          OpaqueBlock( BTEX("shulker_brown_top"), BTEX("shulker_brown_bottom", 'flip_x'), BTEX("shulker_brown_side_left", 'rotate_270'), BTEX("shulker_brown_side_right", 'rotate_90'), BTEX("shulker_brown_side_front", 'rotate_90'), BTEX("shulker_brown_side_back", 'rotate_90') ), -- facing west
		          OpaqueBlock( BTEX("shulker_brown_bottom", 'flip_x'), BTEX("shulker_brown_top"), BTEX("shulker_brown_side_right", 'rotate_90'), BTEX("shulker_brown_side_left", 'rotate_270'), BTEX("shulker_brown_side_front", 'rotate_270'), BTEX("shulker_brown_side_back", 'rotate_270') ), -- facing east
				  0, 0 );
		[232] = DataAdapter( 0x7, -- Green Shulker Box
		          OpaqueBlock( BTEX("shulker_green_side_left", 'rotate_180'), BTEX("shulker_green_side_right", 'rotate_180'), BTEX("shulker_green_side_front", 'rotate_180'), BTEX("shulker_green_side_back", 'rotate_180'), BTEX("shulker_green_top"), BTEX("shulker_green_bottom", 'flip_y') ), -- facing down
		          OpaqueBlock( BTEX("shulker_green_side_left"), BTEX("shulker_green_side_right"), BTEX("shulker_green_side_back"), BTEX("shulker_green_side_front"), BTEX("shulker_green_bottom", 'flip_y'), BTEX("shulker_green_top") ), -- facing up
		          OpaqueBlock( BTEX("shulker_green_side_right", 'rotate_90'), BTEX("shulker_green_side_left", 'rotate_270'), BTEX("shulker_green_top"), BTEX("shulker_green_bottom", 'flip_x'), BTEX("shulker_green_side_front", 'rotate_180'), BTEX("shulker_green_side_back") ), -- facing north
		          OpaqueBlock( BTEX("shulker_green_side_left", 'rotate_270'), BTEX("shulker_green_side_right", 'rotate_90'), BTEX("shulker_green_bottom", 'flip_x'), BTEX("shulker_green_top"), BTEX("shulker_green_side_front"), BTEX("shulker_green_side_back", 'rotate_180') ), -- facing south
		          OpaqueBlock( BTEX("shulker_green_top"), BTEX("shulker_green_bottom", 'flip_x'), BTEX("shulker_green_side_left", 'rotate_270'), BTEX("shulker_green_side_right", 'rotate_90'), BTEX("shulker_green_side_front", 'rotate_90'), BTEX("shulker_green_side_back", 'rotate_90') ), -- facing west
		          OpaqueBlock( BTEX("shulker_green_bottom", 'flip_x'), BTEX("shulker_green_top"), BTEX("shulker_green_side_right", 'rotate_90'), BTEX("shulker_green_side_left", 'rotate_270'), BTEX("shulker_green_side_front", 'rotate_270'), BTEX("shulker_green_side_back", 'rotate_270') ), -- facing east
				  0, 0 );
		[233] = DataAdapter( 0x7, -- Red Shulker Box
		          OpaqueBlock( BTEX("shulker_red_side_left", 'rotate_180'), BTEX("shulker_red_side_right", 'rotate_180'), BTEX("shulker_red_side_front", 'rotate_180'), BTEX("shulker_red_side_back", 'rotate_180'), BTEX("shulker_red_top"), BTEX("shulker_red_bottom", 'flip_y') ), -- facing down
		          OpaqueBlock( BTEX("shulker_red_side_left"), BTEX("shulker_red_side_right"), BTEX("shulker_red_side_back"), BTEX("shulker_red_side_front"), BTEX("shulker_red_bottom", 'flip_y'), BTEX("shulker_red_top") ), -- facing up
		          OpaqueBlock( BTEX("shulker_red_side_right", 'rotate_90'), BTEX("shulker_red_side_left", 'rotate_270'), BTEX("shulker_red_top"), BTEX("shulker_red_bottom", 'flip_x'), BTEX("shulker_red_side_front", 'rotate_180'), BTEX("shulker_red_side_back") ), -- facing north
		          OpaqueBlock( BTEX("shulker_red_side_left", 'rotate_270'), BTEX("shulker_red_side_right", 'rotate_90'), BTEX("shulker_red_bottom", 'flip_x'), BTEX("shulker_red_top"), BTEX("shulker_red_side_front"), BTEX("shulker_red_side_back", 'rotate_180') ), -- facing south
		          OpaqueBlock( BTEX("shulker_red_top"), BTEX("shulker_red_bottom", 'flip_x'), BTEX("shulker_red_side_left", 'rotate_270'), BTEX("shulker_red_side_right", 'rotate_90'), BTEX("shulker_red_side_front", 'rotate_90'), BTEX("shulker_red_side_back", 'rotate_90') ), -- facing west
		          OpaqueBlock( BTEX("shulker_red_bottom", 'flip_x'), BTEX("shulker_red_top"), BTEX("shulker_red_side_right", 'rotate_90'), BTEX("shulker_red_side_left", 'rotate_270'), BTEX("shulker_red_side_front", 'rotate_270'), BTEX("shulker_red_side_back", 'rotate_270') ), -- facing east
				  0, 0 );
		[234] = DataAdapter( 0x7, -- Black Shulker Box
		          OpaqueBlock( BTEX("shulker_black_side_left", 'rotate_180'), BTEX("shulker_black_side_right", 'rotate_180'), BTEX("shulker_black_side_front", 'rotate_180'), BTEX("shulker_black_side_back", 'rotate_180'), BTEX("shulker_black_top"), BTEX("shulker_black_bottom", 'flip_y') ), -- facing down
		          OpaqueBlock( BTEX("shulker_black_side_left"), BTEX("shulker_black_side_right"), BTEX("shulker_black_side_back"), BTEX("shulker_black_side_front"), BTEX("shulker_black_bottom", 'flip_y'), BTEX("shulker_black_top") ), -- facing up
		          OpaqueBlock( BTEX("shulker_black_side_right", 'rotate_90'), BTEX("shulker_black_side_left", 'rotate_270'), BTEX("shulker_black_top"), BTEX("shulker_black_bottom", 'flip_x'), BTEX("shulker_black_side_front", 'rotate_180'), BTEX("shulker_black_side_back") ), -- facing north
		          OpaqueBlock( BTEX("shulker_black_side_left", 'rotate_270'), BTEX("shulker_black_side_right", 'rotate_90'), BTEX("shulker_black_bottom", 'flip_x'), BTEX("shulker_black_top"), BTEX("shulker_black_side_front"), BTEX("shulker_black_side_back", 'rotate_180') ), -- facing south
		          OpaqueBlock( BTEX("shulker_black_top"), BTEX("shulker_black_bottom", 'flip_x'), BTEX("shulker_black_side_left", 'rotate_270'), BTEX("shulker_black_side_right", 'rotate_90'), BTEX("shulker_black_side_front", 'rotate_90'), BTEX("shulker_black_side_back", 'rotate_90') ), -- facing west
		          OpaqueBlock( BTEX("shulker_black_bottom", 'flip_x'), BTEX("shulker_black_top"), BTEX("shulker_black_side_right", 'rotate_90'), BTEX("shulker_black_side_left", 'rotate_270'), BTEX("shulker_black_side_front", 'rotate_270'), BTEX("shulker_black_side_back", 'rotate_270') ), -- facing east
				  0, 0 );
		[235] = DataAdapter( 0x3, -- White Glazed Terracotta
		          OpaqueBlock( BTEX("glazed_terracotta_white"), BTEX("glazed_terracotta_white", 'rotate_180'), BTEX("glazed_terracotta_white", 'rotate_270'), BTEX("glazed_terracotta_white", 'rotate_90'), BTEX("glazed_terracotta_white"), BTEX("glazed_terracotta_white") ), -- south
		          OpaqueBlock( BTEX("glazed_terracotta_white", 'rotate_90'), BTEX("glazed_terracotta_white", 'rotate_270'), BTEX("glazed_terracotta_white"), BTEX("glazed_terracotta_white", 'rotate_180'), BTEX("glazed_terracotta_white", 'rotate_90'), BTEX("glazed_terracotta_white", 'rotate_270') ), -- west
		          OpaqueBlock( BTEX("glazed_terracotta_white", 'rotate_180'), BTEX("glazed_terracotta_white"), BTEX("glazed_terracotta_white", 'rotate_90'), BTEX("glazed_terracotta_white", 'rotate_270'), BTEX("glazed_terracotta_white", 'rotate_180'), BTEX("glazed_terracotta_white", 'rotate_180') ), -- north
		          OpaqueBlock( BTEX("glazed_terracotta_white", 'rotate_270'), BTEX("glazed_terracotta_white", 'rotate_90'), BTEX("glazed_terracotta_white", 'rotate_180'), BTEX("glazed_terracotta_white"), BTEX("glazed_terracotta_white", 'rotate_270'), BTEX("glazed_terracotta_white", 'rotate_90') ) ); -- east
		[236] = DataAdapter( 0x3, -- Orange Glazed Terracotta
		          OpaqueBlock( BTEX("glazed_terracotta_orange"), BTEX("glazed_terracotta_orange", 'rotate_180'), BTEX("glazed_terracotta_orange", 'rotate_270'), BTEX("glazed_terracotta_orange", 'rotate_90'), BTEX("glazed_terracotta_orange"), BTEX("glazed_terracotta_orange") ), -- south
		          OpaqueBlock( BTEX("glazed_terracotta_orange", 'rotate_90'), BTEX("glazed_terracotta_orange", 'rotate_270'), BTEX("glazed_terracotta_orange"), BTEX("glazed_terracotta_orange", 'rotate_180'), BTEX("glazed_terracotta_orange", 'rotate_90'), BTEX("glazed_terracotta_orange", 'rotate_270') ), -- west
		          OpaqueBlock( BTEX("glazed_terracotta_orange", 'rotate_180'), BTEX("glazed_terracotta_orange"), BTEX("glazed_terracotta_orange", 'rotate_90'), BTEX("glazed_terracotta_orange", 'rotate_270'), BTEX("glazed_terracotta_orange", 'rotate_180'), BTEX("glazed_terracotta_orange", 'rotate_180') ), -- north
		          OpaqueBlock( BTEX("glazed_terracotta_orange", 'rotate_270'), BTEX("glazed_terracotta_orange", 'rotate_90'), BTEX("glazed_terracotta_orange", 'rotate_180'), BTEX("glazed_terracotta_orange"), BTEX("glazed_terracotta_orange", 'rotate_270'), BTEX("glazed_terracotta_orange", 'rotate_90') ) ); -- east
		[237] = DataAdapter( 0x3, -- Magenta Glazed Terracotta
		          OpaqueBlock( BTEX("glazed_terracotta_magenta"), BTEX("glazed_terracotta_magenta", 'rotate_180'), BTEX("glazed_terracotta_magenta", 'rotate_270'), BTEX("glazed_terracotta_magenta", 'rotate_90'), BTEX("glazed_terracotta_magenta"), BTEX("glazed_terracotta_magenta") ), -- south
		          OpaqueBlock( BTEX("glazed_terracotta_magenta", 'rotate_90'), BTEX("glazed_terracotta_magenta", 'rotate_270'), BTEX("glazed_terracotta_magenta"), BTEX("glazed_terracotta_magenta", 'rotate_180'), BTEX("glazed_terracotta_magenta", 'rotate_90'), BTEX("glazed_terracotta_magenta", 'rotate_270') ), -- west
		          OpaqueBlock( BTEX("glazed_terracotta_magenta", 'rotate_180'), BTEX("glazed_terracotta_magenta"), BTEX("glazed_terracotta_magenta", 'rotate_90'), BTEX("glazed_terracotta_magenta", 'rotate_270'), BTEX("glazed_terracotta_magenta", 'rotate_180'), BTEX("glazed_terracotta_magenta", 'rotate_180') ), -- north
		          OpaqueBlock( BTEX("glazed_terracotta_magenta", 'rotate_270'), BTEX("glazed_terracotta_magenta", 'rotate_90'), BTEX("glazed_terracotta_magenta", 'rotate_180'), BTEX("glazed_terracotta_magenta"), BTEX("glazed_terracotta_magenta", 'rotate_270'), BTEX("glazed_terracotta_magenta", 'rotate_90') ) ); -- east
		[238] = DataAdapter( 0x3, -- Light Blue Glazed Terracotta
		          OpaqueBlock( BTEX("glazed_terracotta_light_blue"), BTEX("glazed_terracotta_light_blue", 'rotate_180'), BTEX("glazed_terracotta_light_blue", 'rotate_270'), BTEX("glazed_terracotta_light_blue", 'rotate_90'), BTEX("glazed_terracotta_light_blue"), BTEX("glazed_terracotta_light_blue") ), -- south
		          OpaqueBlock( BTEX("glazed_terracotta_light_blue", 'rotate_90'), BTEX("glazed_terracotta_light_blue", 'rotate_270'), BTEX("glazed_terracotta_light_blue"), BTEX("glazed_terracotta_light_blue", 'rotate_180'), BTEX("glazed_terracotta_light_blue", 'rotate_90'), BTEX("glazed_terracotta_light_blue", 'rotate_270') ), -- west
		          OpaqueBlock( BTEX("glazed_terracotta_light_blue", 'rotate_180'), BTEX("glazed_terracotta_light_blue"), BTEX("glazed_terracotta_light_blue", 'rotate_90'), BTEX("glazed_terracotta_light_blue", 'rotate_270'), BTEX("glazed_terracotta_light_blue", 'rotate_180'), BTEX("glazed_terracotta_light_blue", 'rotate_180') ), -- north
		          OpaqueBlock( BTEX("glazed_terracotta_light_blue", 'rotate_270'), BTEX("glazed_terracotta_light_blue", 'rotate_90'), BTEX("glazed_terracotta_light_blue", 'rotate_180'), BTEX("glazed_terracotta_light_blue"), BTEX("glazed_terracotta_light_blue", 'rotate_270'), BTEX("glazed_terracotta_light_blue", 'rotate_90') ) ); -- east
		[239] = DataAdapter( 0x3, -- Yellow Glazed Terracotta
		          OpaqueBlock( BTEX("glazed_terracotta_yellow"), BTEX("glazed_terracotta_yellow", 'rotate_180'), BTEX("glazed_terracotta_yellow", 'rotate_270'), BTEX("glazed_terracotta_yellow", 'rotate_90'), BTEX("glazed_terracotta_yellow"), BTEX("glazed_terracotta_yellow") ), -- south
		          OpaqueBlock( BTEX("glazed_terracotta_yellow", 'rotate_90'), BTEX("glazed_terracotta_yellow", 'rotate_270'), BTEX("glazed_terracotta_yellow"), BTEX("glazed_terracotta_yellow", 'rotate_180'), BTEX("glazed_terracotta_yellow", 'rotate_90'), BTEX("glazed_terracotta_yellow", 'rotate_270') ), -- west
		          OpaqueBlock( BTEX("glazed_terracotta_yellow", 'rotate_180'), BTEX("glazed_terracotta_yellow"), BTEX("glazed_terracotta_yellow", 'rotate_90'), BTEX("glazed_terracotta_yellow", 'rotate_270'), BTEX("glazed_terracotta_yellow", 'rotate_180'), BTEX("glazed_terracotta_yellow", 'rotate_180') ), -- north
		          OpaqueBlock( BTEX("glazed_terracotta_yellow", 'rotate_270'), BTEX("glazed_terracotta_yellow", 'rotate_90'), BTEX("glazed_terracotta_yellow", 'rotate_180'), BTEX("glazed_terracotta_yellow"), BTEX("glazed_terracotta_yellow", 'rotate_270'), BTEX("glazed_terracotta_yellow", 'rotate_90') ) ); -- east
		[240] = DataAdapter( 0x3, -- Lime Glazed Terracotta
		          OpaqueBlock( BTEX("glazed_terracotta_lime"), BTEX("glazed_terracotta_lime", 'rotate_180'), BTEX("glazed_terracotta_lime", 'rotate_270'), BTEX("glazed_terracotta_lime", 'rotate_90'), BTEX("glazed_terracotta_lime"), BTEX("glazed_terracotta_lime") ), -- south
		          OpaqueBlock( BTEX("glazed_terracotta_lime", 'rotate_90'), BTEX("glazed_terracotta_lime", 'rotate_270'), BTEX("glazed_terracotta_lime"), BTEX("glazed_terracotta_lime", 'rotate_180'), BTEX("glazed_terracotta_lime", 'rotate_90'), BTEX("glazed_terracotta_lime", 'rotate_270') ), -- west
		          OpaqueBlock( BTEX("glazed_terracotta_lime", 'rotate_180'), BTEX("glazed_terracotta_lime"), BTEX("glazed_terracotta_lime", 'rotate_90'), BTEX("glazed_terracotta_lime", 'rotate_270'), BTEX("glazed_terracotta_lime", 'rotate_180'), BTEX("glazed_terracotta_lime", 'rotate_180') ), -- north
		          OpaqueBlock( BTEX("glazed_terracotta_lime", 'rotate_270'), BTEX("glazed_terracotta_lime", 'rotate_90'), BTEX("glazed_terracotta_lime", 'rotate_180'), BTEX("glazed_terracotta_lime"), BTEX("glazed_terracotta_lime", 'rotate_270'), BTEX("glazed_terracotta_lime", 'rotate_90') ) ); -- east
		[241] = DataAdapter( 0x3, -- Pink Glazed Terracotta
		          OpaqueBlock( BTEX("glazed_terracotta_pink"), BTEX("glazed_terracotta_pink", 'rotate_180'), BTEX("glazed_terracotta_pink", 'rotate_270'), BTEX("glazed_terracotta_pink", 'rotate_90'), BTEX("glazed_terracotta_pink"), BTEX("glazed_terracotta_pink") ), -- south
		          OpaqueBlock( BTEX("glazed_terracotta_pink", 'rotate_90'), BTEX("glazed_terracotta_pink", 'rotate_270'), BTEX("glazed_terracotta_pink"), BTEX("glazed_terracotta_pink", 'rotate_180'), BTEX("glazed_terracotta_pink", 'rotate_90'), BTEX("glazed_terracotta_pink", 'rotate_270') ), -- west
		          OpaqueBlock( BTEX("glazed_terracotta_pink", 'rotate_180'), BTEX("glazed_terracotta_pink"), BTEX("glazed_terracotta_pink", 'rotate_90'), BTEX("glazed_terracotta_pink", 'rotate_270'), BTEX("glazed_terracotta_pink", 'rotate_180'), BTEX("glazed_terracotta_pink", 'rotate_180') ), -- north
		          OpaqueBlock( BTEX("glazed_terracotta_pink", 'rotate_270'), BTEX("glazed_terracotta_pink", 'rotate_90'), BTEX("glazed_terracotta_pink", 'rotate_180'), BTEX("glazed_terracotta_pink"), BTEX("glazed_terracotta_pink", 'rotate_270'), BTEX("glazed_terracotta_pink", 'rotate_90') ) ); -- east
		[242] = DataAdapter( 0x3, -- Grey Glazed Terracotta
		          OpaqueBlock( BTEX("glazed_terracotta_gray"), BTEX("glazed_terracotta_gray", 'rotate_180'), BTEX("glazed_terracotta_gray", 'rotate_270'), BTEX("glazed_terracotta_gray", 'rotate_90'), BTEX("glazed_terracotta_gray"), BTEX("glazed_terracotta_gray") ), -- south
		          OpaqueBlock( BTEX("glazed_terracotta_gray", 'rotate_90'), BTEX("glazed_terracotta_gray", 'rotate_270'), BTEX("glazed_terracotta_gray"), BTEX("glazed_terracotta_gray", 'rotate_180'), BTEX("glazed_terracotta_gray", 'rotate_90'), BTEX("glazed_terracotta_gray", 'rotate_270') ), -- west
		          OpaqueBlock( BTEX("glazed_terracotta_gray", 'rotate_180'), BTEX("glazed_terracotta_gray"), BTEX("glazed_terracotta_gray", 'rotate_90'), BTEX("glazed_terracotta_gray", 'rotate_270'), BTEX("glazed_terracotta_gray", 'rotate_180'), BTEX("glazed_terracotta_gray", 'rotate_180') ), -- north
		          OpaqueBlock( BTEX("glazed_terracotta_gray", 'rotate_270'), BTEX("glazed_terracotta_gray", 'rotate_90'), BTEX("glazed_terracotta_gray", 'rotate_180'), BTEX("glazed_terracotta_gray"), BTEX("glazed_terracotta_gray", 'rotate_270'), BTEX("glazed_terracotta_gray", 'rotate_90') ) ); -- east
		[243] = DataAdapter( 0x3, -- Light Grey Glazed Terracotta
		          OpaqueBlock( BTEX("glazed_terracotta_silver"), BTEX("glazed_terracotta_silver", 'rotate_180'), BTEX("glazed_terracotta_silver", 'rotate_270'), BTEX("glazed_terracotta_silver", 'rotate_90'), BTEX("glazed_terracotta_silver"), BTEX("glazed_terracotta_silver") ), -- south
		          OpaqueBlock( BTEX("glazed_terracotta_silver", 'rotate_90'), BTEX("glazed_terracotta_silver", 'rotate_270'), BTEX("glazed_terracotta_silver"), BTEX("glazed_terracotta_silver", 'rotate_180'), BTEX("glazed_terracotta_silver", 'rotate_90'), BTEX("glazed_terracotta_silver", 'rotate_270') ), -- west
		          OpaqueBlock( BTEX("glazed_terracotta_silver", 'rotate_180'), BTEX("glazed_terracotta_silver"), BTEX("glazed_terracotta_silver", 'rotate_90'), BTEX("glazed_terracotta_silver", 'rotate_270'), BTEX("glazed_terracotta_silver", 'rotate_180'), BTEX("glazed_terracotta_silver", 'rotate_180') ), -- north
		          OpaqueBlock( BTEX("glazed_terracotta_silver", 'rotate_270'), BTEX("glazed_terracotta_silver", 'rotate_90'), BTEX("glazed_terracotta_silver", 'rotate_180'), BTEX("glazed_terracotta_silver"), BTEX("glazed_terracotta_silver", 'rotate_270'), BTEX("glazed_terracotta_silver", 'rotate_90') ) ); -- east
		[244] = DataAdapter( 0x3, -- Cyan Glazed Terracotta
		          OpaqueBlock( BTEX("glazed_terracotta_cyan"), BTEX("glazed_terracotta_cyan", 'rotate_180'), BTEX("glazed_terracotta_cyan", 'rotate_270'), BTEX("glazed_terracotta_cyan", 'rotate_90'), BTEX("glazed_terracotta_cyan"), BTEX("glazed_terracotta_cyan") ), -- south
		          OpaqueBlock( BTEX("glazed_terracotta_cyan", 'rotate_90'), BTEX("glazed_terracotta_cyan", 'rotate_270'), BTEX("glazed_terracotta_cyan"), BTEX("glazed_terracotta_cyan", 'rotate_180'), BTEX("glazed_terracotta_cyan", 'rotate_90'), BTEX("glazed_terracotta_cyan", 'rotate_270') ), -- west
		          OpaqueBlock( BTEX("glazed_terracotta_cyan", 'rotate_180'), BTEX("glazed_terracotta_cyan"), BTEX("glazed_terracotta_cyan", 'rotate_90'), BTEX("glazed_terracotta_cyan", 'rotate_270'), BTEX("glazed_terracotta_cyan", 'rotate_180'), BTEX("glazed_terracotta_cyan", 'rotate_180') ), -- north
		          OpaqueBlock( BTEX("glazed_terracotta_cyan", 'rotate_270'), BTEX("glazed_terracotta_cyan", 'rotate_90'), BTEX("glazed_terracotta_cyan", 'rotate_180'), BTEX("glazed_terracotta_cyan"), BTEX("glazed_terracotta_cyan", 'rotate_270'), BTEX("glazed_terracotta_cyan", 'rotate_90') ) ); -- east
		[245] = DataAdapter( 0x3, -- Purple Glazed Terracotta
		          OpaqueBlock( BTEX("glazed_terracotta_purple"), BTEX("glazed_terracotta_purple", 'rotate_180'), BTEX("glazed_terracotta_purple", 'rotate_270'), BTEX("glazed_terracotta_purple", 'rotate_90'), BTEX("glazed_terracotta_purple"), BTEX("glazed_terracotta_purple") ), -- south
		          OpaqueBlock( BTEX("glazed_terracotta_purple", 'rotate_90'), BTEX("glazed_terracotta_purple", 'rotate_270'), BTEX("glazed_terracotta_purple"), BTEX("glazed_terracotta_purple", 'rotate_180'), BTEX("glazed_terracotta_purple", 'rotate_90'), BTEX("glazed_terracotta_purple", 'rotate_270') ), -- west
		          OpaqueBlock( BTEX("glazed_terracotta_purple", 'rotate_180'), BTEX("glazed_terracotta_purple"), BTEX("glazed_terracotta_purple", 'rotate_90'), BTEX("glazed_terracotta_purple", 'rotate_270'), BTEX("glazed_terracotta_purple", 'rotate_180'), BTEX("glazed_terracotta_purple", 'rotate_180') ), -- north
		          OpaqueBlock( BTEX("glazed_terracotta_purple", 'rotate_270'), BTEX("glazed_terracotta_purple", 'rotate_90'), BTEX("glazed_terracotta_purple", 'rotate_180'), BTEX("glazed_terracotta_purple"), BTEX("glazed_terracotta_purple", 'rotate_270'), BTEX("glazed_terracotta_purple", 'rotate_90') ) ); -- east
		[246] = DataAdapter( 0x3, -- Blue Glazed Terracotta
		          OpaqueBlock( BTEX("glazed_terracotta_blue"), BTEX("glazed_terracotta_blue", 'rotate_180'), BTEX("glazed_terracotta_blue", 'rotate_270'), BTEX("glazed_terracotta_blue", 'rotate_90'), BTEX("glazed_terracotta_blue"), BTEX("glazed_terracotta_blue") ), -- south
		          OpaqueBlock( BTEX("glazed_terracotta_blue", 'rotate_90'), BTEX("glazed_terracotta_blue", 'rotate_270'), BTEX("glazed_terracotta_blue"), BTEX("glazed_terracotta_blue", 'rotate_180'), BTEX("glazed_terracotta_blue", 'rotate_90'), BTEX("glazed_terracotta_blue", 'rotate_270') ), -- west
		          OpaqueBlock( BTEX("glazed_terracotta_blue", 'rotate_180'), BTEX("glazed_terracotta_blue"), BTEX("glazed_terracotta_blue", 'rotate_90'), BTEX("glazed_terracotta_blue", 'rotate_270'), BTEX("glazed_terracotta_blue", 'rotate_180'), BTEX("glazed_terracotta_blue", 'rotate_180') ), -- north
		          OpaqueBlock( BTEX("glazed_terracotta_blue", 'rotate_270'), BTEX("glazed_terracotta_blue", 'rotate_90'), BTEX("glazed_terracotta_blue", 'rotate_180'), BTEX("glazed_terracotta_blue"), BTEX("glazed_terracotta_blue", 'rotate_270'), BTEX("glazed_terracotta_blue", 'rotate_90') ) ); -- east
		[247] = DataAdapter( 0x3, -- Brown Glazed Terracotta
		          OpaqueBlock( BTEX("glazed_terracotta_brown"), BTEX("glazed_terracotta_brown", 'rotate_180'), BTEX("glazed_terracotta_brown", 'rotate_270'), BTEX("glazed_terracotta_brown", 'rotate_90'), BTEX("glazed_terracotta_brown"), BTEX("glazed_terracotta_brown") ), -- south
		          OpaqueBlock( BTEX("glazed_terracotta_brown", 'rotate_90'), BTEX("glazed_terracotta_brown", 'rotate_270'), BTEX("glazed_terracotta_brown"), BTEX("glazed_terracotta_brown", 'rotate_180'), BTEX("glazed_terracotta_brown", 'rotate_90'), BTEX("glazed_terracotta_brown", 'rotate_270') ), -- west
		          OpaqueBlock( BTEX("glazed_terracotta_brown", 'rotate_180'), BTEX("glazed_terracotta_brown"), BTEX("glazed_terracotta_brown", 'rotate_90'), BTEX("glazed_terracotta_brown", 'rotate_270'), BTEX("glazed_terracotta_brown", 'rotate_180'), BTEX("glazed_terracotta_brown", 'rotate_180') ), -- north
		          OpaqueBlock( BTEX("glazed_terracotta_brown", 'rotate_270'), BTEX("glazed_terracotta_brown", 'rotate_90'), BTEX("glazed_terracotta_brown", 'rotate_180'), BTEX("glazed_terracotta_brown"), BTEX("glazed_terracotta_brown", 'rotate_270'), BTEX("glazed_terracotta_brown", 'rotate_90') ) ); -- east
		[248] = DataAdapter( 0x3, -- Green Glazed Terracotta
		          OpaqueBlock( BTEX("glazed_terracotta_green"), BTEX("glazed_terracotta_green", 'rotate_180'), BTEX("glazed_terracotta_green", 'rotate_270'), BTEX("glazed_terracotta_green", 'rotate_90'), BTEX("glazed_terracotta_green"), BTEX("glazed_terracotta_green") ), -- south
		          OpaqueBlock( BTEX("glazed_terracotta_green", 'rotate_90'), BTEX("glazed_terracotta_green", 'rotate_270'), BTEX("glazed_terracotta_green"), BTEX("glazed_terracotta_green", 'rotate_180'), BTEX("glazed_terracotta_green", 'rotate_90'), BTEX("glazed_terracotta_green", 'rotate_270') ), -- west
		          OpaqueBlock( BTEX("glazed_terracotta_green", 'rotate_180'), BTEX("glazed_terracotta_green"), BTEX("glazed_terracotta_green", 'rotate_90'), BTEX("glazed_terracotta_green", 'rotate_270'), BTEX("glazed_terracotta_green", 'rotate_180'), BTEX("glazed_terracotta_green", 'rotate_180') ), -- north
		          OpaqueBlock( BTEX("glazed_terracotta_green", 'rotate_270'), BTEX("glazed_terracotta_green", 'rotate_90'), BTEX("glazed_terracotta_green", 'rotate_180'), BTEX("glazed_terracotta_green"), BTEX("glazed_terracotta_green", 'rotate_270'), BTEX("glazed_terracotta_green", 'rotate_90') ) ); -- east
		[249] = DataAdapter( 0x3, -- Red Glazed Terracotta
		          OpaqueBlock( BTEX("glazed_terracotta_red"), BTEX("glazed_terracotta_red", 'rotate_180'), BTEX("glazed_terracotta_red", 'rotate_270'), BTEX("glazed_terracotta_red", 'rotate_90'), BTEX("glazed_terracotta_red"), BTEX("glazed_terracotta_red") ), -- south
		          OpaqueBlock( BTEX("glazed_terracotta_red", 'rotate_90'), BTEX("glazed_terracotta_red", 'rotate_270'), BTEX("glazed_terracotta_red"), BTEX("glazed_terracotta_red", 'rotate_180'), BTEX("glazed_terracotta_red", 'rotate_90'), BTEX("glazed_terracotta_red", 'rotate_270') ), -- west
		          OpaqueBlock( BTEX("glazed_terracotta_red", 'rotate_180'), BTEX("glazed_terracotta_red"), BTEX("glazed_terracotta_red", 'rotate_90'), BTEX("glazed_terracotta_red", 'rotate_270'), BTEX("glazed_terracotta_red", 'rotate_180'), BTEX("glazed_terracotta_red", 'rotate_180') ), -- north
		          OpaqueBlock( BTEX("glazed_terracotta_red", 'rotate_270'), BTEX("glazed_terracotta_red", 'rotate_90'), BTEX("glazed_terracotta_red", 'rotate_180'), BTEX("glazed_terracotta_red"), BTEX("glazed_terracotta_red", 'rotate_270'), BTEX("glazed_terracotta_red", 'rotate_90') ) ); -- east
		[250] = DataAdapter( 0x3, -- Black Glazed Terracotta
		          OpaqueBlock( BTEX("glazed_terracotta_black"), BTEX("glazed_terracotta_black", 'rotate_180'), BTEX("glazed_terracotta_black", 'rotate_270'), BTEX("glazed_terracotta_black", 'rotate_90'), BTEX("glazed_terracotta_black"), BTEX("glazed_terracotta_black") ), -- south
		          OpaqueBlock( BTEX("glazed_terracotta_black", 'rotate_90'), BTEX("glazed_terracotta_black", 'rotate_270'), BTEX("glazed_terracotta_black"), BTEX("glazed_terracotta_black", 'rotate_180'), BTEX("glazed_terracotta_black", 'rotate_90'), BTEX("glazed_terracotta_black", 'rotate_270') ), -- west
		          OpaqueBlock( BTEX("glazed_terracotta_black", 'rotate_180'), BTEX("glazed_terracotta_black"), BTEX("glazed_terracotta_black", 'rotate_90'), BTEX("glazed_terracotta_black", 'rotate_270'), BTEX("glazed_terracotta_black", 'rotate_180'), BTEX("glazed_terracotta_black", 'rotate_180') ), -- north
		          OpaqueBlock( BTEX("glazed_terracotta_black", 'rotate_270'), BTEX("glazed_terracotta_black", 'rotate_90'), BTEX("glazed_terracotta_black", 'rotate_180'), BTEX("glazed_terracotta_black"), BTEX("glazed_terracotta_black", 'rotate_270'), BTEX("glazed_terracotta_black", 'rotate_90') ) ); -- east
		[251] = DataAdapter( 0xf, -- Concrete
		          OpaqueBlock( BTEX("concrete_white") ), -- white
		          OpaqueBlock( BTEX("concrete_orange") ), -- orange
		          OpaqueBlock( BTEX("concrete_magenta") ), -- magenta
		          OpaqueBlock( BTEX("concrete_light_blue") ), -- light blue
		          OpaqueBlock( BTEX("concrete_yellow") ), -- yellow
		          OpaqueBlock( BTEX("concrete_lime") ), -- lime
		          OpaqueBlock( BTEX("concrete_pink") ), -- pink
		          OpaqueBlock( BTEX("concrete_gray") ), -- grey
		          OpaqueBlock( BTEX("concrete_silver") ), -- light grey	
		          OpaqueBlock( BTEX("concrete_cyan") ), -- cyan
		          OpaqueBlock( BTEX("concrete_purple") ), -- purple
		          OpaqueBlock( BTEX("concrete_blue") ), -- blue
		          OpaqueBlock( BTEX("concrete_brown") ), -- brown
		          OpaqueBlock( BTEX("concrete_green") ), -- green
		          OpaqueBlock( BTEX("concrete_red") ), -- red
		          OpaqueBlock( BTEX("concrete_black") ) ); -- black
		[252] = DataAdapter( 0xf, -- Concrete Powder
		          OpaqueBlock( BTEX("concrete_powder_white") ), -- white
		          OpaqueBlock( BTEX("concrete_powder_orange") ), -- orange
		          OpaqueBlock( BTEX("concrete_powder_magenta") ), -- magenta
		          OpaqueBlock( BTEX("concrete_powder_light_blue") ), -- light blue
		          OpaqueBlock( BTEX("concrete_powder_yellow") ), -- yellow
		          OpaqueBlock( BTEX("concrete_powder_lime") ), -- lime
		          OpaqueBlock( BTEX("concrete_powder_pink") ), -- pink
		          OpaqueBlock( BTEX("concrete_powder_gray") ), -- grey
		          OpaqueBlock( BTEX("concrete_powder_silver") ), -- light grey	
		          OpaqueBlock( BTEX("concrete_powder_cyan") ), -- cyan
		          OpaqueBlock( BTEX("concrete_powder_purple") ), -- purple
		          OpaqueBlock( BTEX("concrete_powder_blue") ), -- blue
		          OpaqueBlock( BTEX("concrete_powder_brown") ), -- brown
		          OpaqueBlock( BTEX("concrete_powder_green") ), -- green
		          OpaqueBlock( BTEX("concrete_powder_red") ), -- red
		          OpaqueBlock( BTEX("concrete_powder_black") ) ); -- black
		[255] = DataAdapter( 0x3, -- Structure Block
		          OpaqueBlock( BTEX("structure_block_save") ), -- save
		          OpaqueBlock( BTEX("structure_block_load") ), -- load
		          OpaqueBlock( BTEX("structure_block_corner") ), -- corner
		          OpaqueBlock( BTEX("structure_block_data") ) ); -- data
	};
	
	for id, blk in pairs( MinecraftBlocks ) do
		blocks:setGeometry( id, blk[1] );
		blocks:setSolidity( id, blk[2] );
	end
	
	-- Write cache hits to a debug file
	if Config.deveoper_tools and Config.print_cache_hits then
		PrintCacheHits( cacheHits );
	end
	
	-- Clear table transformedMinecraftTexture
	for texname, _ in pairs( transformedMinecraftTexture ) do
		transformedMinecraftTexture[texname]:destroy();
	end
	transformedMinecraftTexture = { };

	return blocks;
end

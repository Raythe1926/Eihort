
-- Block Textures -> Texture transformations for Eihort 0.4.1+

-- The first part of this file contains helper functions used to transform textures.
-- The actual block texture transformation starts partway down.

-- Storage tables for textures
local originalMinecraftTexture = { };
local transformedMinecraftTexture = { };

-- Transparent texture generator
function TransparentTexture ( )
	local tempTex = eihort.newImage( 1, 1, 1, 1, 1, 0 );
	local tex = tempTex:uploadToGL( 'repeat', 'mag_nearest', 'min_nearest', 'mip_none' );
	tempTex:destroy();
	return tex;
end

-- Single color texture generator
function SingleColorTexture ( r, g, b, a )
	local tempTex = eihort.newImage( 1, 1, r, g, b, a );
	local tex = tempTex:uploadToGL( 'repeat', 'mag_nearest', 'min_nearest', 'mip_none' );
	tempTex:destroy();
	return tex;
end

-- Load a texture from a file
local function LoadTextureFromFile ( texturePath, filename, width, height )
	-- usage: LoadTextureFromFile ( path to file, filename, file width, file height )
	local file = loadTexture( texturePath .. filename, width, height );
	
	return file;
end

-- Collect and return texture information
local function GetTextureInformation ( fromTexture, partsInFile )
	local imgInfo = { };
	
	imgInfo.textureWidth = fromTexture.width/partsInFile[1];
	imgInfo.textureHeight = fromTexture.height/partsInFile[2];
	imgInfo.multiplierX = imgInfo.textureWidth/16;
	imgInfo.multiplierY = imgInfo.textureHeight/16;
	
	return imgInfo;
end

-- Enlarge an image by replicating it's pixels
local function EnlargeImagePixel( sourceTexture, horizontalScale, verticalScale )
	--[[ 
	USAGE: TransformSingleTextureToFile (
		(1)   sourceTexture = texture that will be enlarged
		(2) horizontalScale = texture pixel will be replicated on the x-axis
		(3)   verticalScale = texture pixel will be replicated on the y-axis
	]]
	
	local imgInfo = { };
	local returnTexture, tempTexture, workingTexture;
	
	imgInfo = GetTextureInformation( sourceTexture, { 1, 1 } );
	tempTexture = eihort.newImage( imgInfo.textureWidth*horizontalScale, imgInfo.textureHeight, 0, 0, 0, 0 );
	returnTexture = eihort.newImage( imgInfo.textureWidth*horizontalScale, imgInfo.textureHeight*verticalScale, 0, 0, 0, 0 );
	
	-- Multiply pixel
	for y = 1, imgInfo.textureHeight do
		-- Copy x-Axis
		for x = 1, imgInfo.textureWidth do
			workingTexture = sourceTexture:sub( x-1, y-1, 1, 1 );
			
			for i = 1, horizontalScale do
				tempTexture:put( workingTexture, (x-1)*horizontalScale+(i-1), y-1 );
			end
		end
		
		-- Copy y-Axis
		workingTexture = tempTexture:sub( 0, y-1, tempTexture.width, 1 );
		for i = 1, verticalScale do
			returnTexture:put( workingTexture, 0, (y-1)*verticalScale+(i-1) );
		end
	end
	
	tempTexture:destroy();
	workingTexture:destroy();
	
	return returnTexture;
end

-- Transforms and modify multiple parts of a texture to one file
local function TransformMultipleModifiedTextureToFile ( commandTable )
	--[[ 
	USAGE: TransformMultipleModifiedTextureToFile ( {
		[1] = table: first part of the texture {
			(1) sourceTexture = texture name inside table originalMinecraftTexture
			(2)   partsInFile = table: texture quantity in file {x, y}
			(3)      copyFrom = table: copy texture from {x, y}
			(4)   textureSize = table: the texture size {x, y}
			(5)       pasteTo = table: paste texture to {x, y} }
			(6)    actionList = table: list of all applied actions on the texture
		[2] = table: second part of the texture {
			(1) sourceTexture = texture name inside table originalMinecraftTexture
			... }
		... );
	]]
	
	local tempTextures = { };
	local imgInfo = { };
	local returnTexture;
	
	imgInfo = GetTextureInformation( commandTable[1][1], commandTable[1][2] );
	returnTexture = eihort.newImage( imgInfo.textureWidth, imgInfo.textureHeight, 0, 0, 0, 0 );
	
	for nr, processImage in ipairs( commandTable ) do
		local sourceTexture, partsInFile, copyFrom, textureSize;
		
		sourceTexture = commandTable[nr][1];
		partsInFile = commandTable[nr][2];
		copyFrom = commandTable[nr][3];
		textureSize = commandTable[nr][4];
		
		tempTextures[nr] = sourceTexture:sub( imgInfo.multiplierX*copyFrom[1], imgInfo.multiplierY*copyFrom[2], imgInfo.multiplierX*textureSize[1], imgInfo.multiplierY*textureSize[2] );
	end
	
	for nr, processImage in ipairs( tempTextures ) do
		local pasteTo, actionList;
		pasteTo = commandTable[nr][5];
		actionList = commandTable[nr][6];
		
		if actionList[1] then
			tempTextures[nr] = tempTextures[nr]:rotate( unpack ( actionList ) );
		end
		
		returnTexture:put( tempTextures[nr], imgInfo.multiplierX*pasteTo[1], imgInfo.multiplierY*pasteTo[2] );
		tempTextures[nr]:destroy();
	end
	
	return returnTexture;
end

-- Transforms multiple parts of a texture to one file
local function TransformMultipleTextureToFile ( commandTable )
	--[[ 
	USAGE: TransformMultipleTextureToFile ( {
		[1] = table: first part of the texture {
			(1) sourceTexture = texture name inside table originalMinecraftTexture
			(2)   partsInFile = table: texture quantity in file {x, y}
			(3)      copyFrom = table: copy texture from {x, y}
			(4)   textureSize = table: the texture size {x, y}
			(5)       pasteTo = table: paste texture to {x, y} }
		[2] = table: second part of the texture {
			(1) sourceTexture = texture name inside table originalMinecraftTexture
			... }
		... );
	]]
	
	for nr, _ in ipairs ( commandTable ) do
		commandTable[nr][6] = { };
	end
	
	local returnTexture = TransformMultipleModifiedTextureToFile( commandTable );
	
	return returnTexture;
end

-- Transforms a (part of a) texture to a file
local function TransformSingleTextureToFile ( sourceTexture, partsInFile, copyFrom, textureSize, pasteTo )
	--[[ 
	USAGE: TransformSingleTextureToFile (
		(1) sourceTexture = texture inside table originalMinecraftTexture
		(2)   partsInFile = table: texture quantity in file {x, y}
		(3)      copyFrom = table: copy texture from {x, y}
		(4)   textureSize = table: the texture size {x, y}
		(5)       pasteTo = table: paste texture to {x, y} );
	]]
	
	local commandTable = { 
		[1] = { sourceTexture, partsInFile, copyFrom, textureSize, pasteTo, { } }
	};
	
	local returnTexture = TransformMultipleModifiedTextureToFile( commandTable );
	
	return returnTexture;
end

-- Overlay an image with another
local function OverlayTextures ( frameSize, canvasTexture, paintTexture )
	-- The paint texture will overlay the canvas texture
	-- USAGE: OverlayTextures ( { image size x, image size y }, { canvas texture, paste to X, paste to Y }, { paint texture, paste to X, paste to Y } );
	
	local returnTexture;
	
	returnTexture = eihort.newImage( frameSize[1], frameSize[2], 0, 0, 0, 0 );
	
	returnTexture:put( canvasTexture[1], canvasTexture[2], canvasTexture[3] );
	returnTexture:put( paintTexture[1], paintTexture[2], paintTexture[3] );
	
	return returnTexture;	
end

-- Upscale a texture
local function UpscaleImageTexture ( sourceTexture, partsInFile, copyFrom, textureSize, pasteTo, newTextureSize )
	--[[ 
	USAGE: TransformMultipleModifiedTextureToFile (
		(1)  sourceTexture = texture name inside table originalMinecraftTexture
		(2)    partsInFile = table: texture quantity in file {x, y}
		(3)       copyFrom = table: copy texture from {x, y}
		(4)    textureSize = table: the texture size {x, y}
		(5)        pasteTo = table: paste texture to {x, y}
		(6) newTextureSize = table: the upscaled texture size {x, y}
	]]
	
	local imgInfo = { };
	local scaleInfo = { };
	local returnTexture, enlargedTexture;
	
	imgInfo = GetTextureInformation( sourceTexture, partsInFile );
	
	-- Calcuate scale settings
	scaleInfo.scaleRatioX = (imgInfo.multiplierX * newTextureSize[1]) / (imgInfo.textureWidth - (imgInfo.multiplierX * newTextureSize[1]));
	scaleInfo.scaleRatioY = (imgInfo.multiplierY * newTextureSize[2]) / (imgInfo.textureHeight - (imgInfo.multiplierY * newTextureSize[2]));
	scaleInfo.newFreeSpaceX = newTextureSize[1] * scaleInfo.scaleRatioX * imgInfo.multiplierX * textureSize[1];
	scaleInfo.newFreeSpaceY = newTextureSize[2] * scaleInfo.scaleRatioY * imgInfo.multiplierY * textureSize[2];
	scaleInfo.newTextureWidth = scaleInfo.newFreeSpaceX + imgInfo.multiplierX * newTextureSize[1] * textureSize[1];
	scaleInfo.newTextureHeight = scaleInfo.newFreeSpaceY + imgInfo.multiplierY * newTextureSize[2] * textureSize[2];
	scaleInfo.enlargeRatioX = scaleInfo.newTextureWidth / imgInfo.textureWidth;
	scaleInfo.enlargeRatioY = scaleInfo.newTextureHeight / imgInfo.textureHeight;
	
	enlargedTexture = sourceTexture:sub( imgInfo.multiplierX*copyFrom[1], imgInfo.multiplierY*copyFrom[2], imgInfo.multiplierX*textureSize[1], imgInfo.multiplierY*textureSize[2] );
	enlargedTexture = EnlargeImagePixel( enlargedTexture, newTextureSize[1], newTextureSize[2] );
	
	returnTexture = eihort.newImage( scaleInfo.newTextureWidth, scaleInfo.newTextureHeight, 0, 0, 0, 0 );
	returnTexture:put( enlargedTexture, imgInfo.multiplierX*scaleInfo.enlargeRatioX*pasteTo[1], imgInfo.multiplierY*scaleInfo.enlargeRatioY*pasteTo[2] );
	
	enlargedTexture:destroy();
	
	return returnTexture;
end

-- Load all additional textures
function LoadAdditionalTextures ()
	-- ID 29, Sticky Piston - ID 33, Piston - ID 34, Piston Head
		originalMinecraftTexture.piston_side = LoadTextureFromFile( "assets/minecraft/textures/blocks/", "piston_side.png", 16, 16 ); -- load texture
		
		-- Save Textures
		transformedMinecraftTexture.modified_piston_side = TransformMultipleModifiedTextureToFile ( { -- base
			[1] = { originalMinecraftTexture.piston_side, {1, 1}, {0, 4}, {16, 12}, {0, 4}, { } },
			[2] = { originalMinecraftTexture.piston_side, {1, 1}, {0, 0}, {4, 4}, {6, 0}, {'rotate_90'} } } );
		transformedMinecraftTexture.modified_piston_arm_side = TransformMultipleModifiedTextureToFile ( { -- arm
			[1] = { originalMinecraftTexture.piston_side, {1, 1}, {0, 0}, {16, 4}, {0, 0}, { } },
			[2] = { originalMinecraftTexture.piston_side, {1, 1}, {4, 0}, {12, 4}, {6, 4}, {'rotate_90'} } } );
			
	-- ID 54, Chest
		originalMinecraftTexture.chest_normal = LoadTextureFromFile( "assets/minecraft/textures/entity/chest/", "normal.png", 64, 64 ); -- load texture
		
		-- Save Textures
		transformedMinecraftTexture.chest_normal_left = TransformMultipleTextureToFile ( { -- left
			[1] = { originalMinecraftTexture.chest_normal, {4, 4}, {0, 14}, {14, 4}, {1, 2} },
			[2] = { originalMinecraftTexture.chest_normal, {4, 4}, {0, 33}, {14, 10}, {1, 6} },
			[3] = { originalMinecraftTexture.chest_normal, {4, 4}, {0, 1}, {1, 4}, {15, 5} } } );
		transformedMinecraftTexture.chest_normal_right = TransformMultipleTextureToFile ( { -- right
			[1] = { originalMinecraftTexture.chest_normal, {4, 4}, {28, 14}, {14, 4}, {1, 2} },
			[2] = { originalMinecraftTexture.chest_normal, {4, 4}, {28, 33}, {14, 10}, {1, 6} },
			[3] = { originalMinecraftTexture.chest_normal, {4, 4}, {3, 1}, {1, 4}, {0, 5} } } );
		transformedMinecraftTexture.chest_normal_back = TransformMultipleTextureToFile ( { -- back
			[1] = { originalMinecraftTexture.chest_normal, {4, 4}, {42, 14}, {14, 4}, {1, 2} },
			[2] = { originalMinecraftTexture.chest_normal, {4, 4}, {42, 33}, {14, 10}, {1, 6} } } );
		transformedMinecraftTexture.chest_normal_front = TransformMultipleTextureToFile ( { -- front
			[1] = { originalMinecraftTexture.chest_normal, {4, 4}, {0, 14}, {14, 4}, {1, 2} },
			[2] = { originalMinecraftTexture.chest_normal, {4, 4}, {14, 33}, {14, 10}, {1, 6} },
			[3] = { originalMinecraftTexture.chest_normal, {4, 4}, {1, 1}, {2, 4}, {7, 5} } } );
		transformedMinecraftTexture.chest_normal_bottom = TransformMultipleTextureToFile ( { -- bottom
			[1] = { originalMinecraftTexture.chest_normal, {4, 4}, {28, 19}, {14, 14}, {1, 1} },
			[2] = { originalMinecraftTexture.chest_normal, {4, 4}, {3, 0}, {2, 1}, {7, 15} } } );
		transformedMinecraftTexture.chest_normal_top = TransformMultipleTextureToFile ( { -- top
			[1] = { originalMinecraftTexture.chest_normal, {4, 4}, {14, 0}, {14, 14}, {1, 1} },
			[2] = { originalMinecraftTexture.chest_normal, {4, 4}, {1, 0}, {2, 1}, {7, 15} } } );
			
	-- ID 68, Sign
		originalMinecraftTexture.sign = LoadTextureFromFile( "assets/minecraft/textures/entity/", "sign.png", 64, 32 ); -- load texture
		
		-- Save Textures
		-- keep the original sizes: left/right is 2x12, front/back is 24x12, back/top is 24x2
		transformedMinecraftTexture.sign_left = TransformSingleTextureToFile ( originalMinecraftTexture.sign, {64/2, 32/12}, {16/2*0, 16/12*2}, {16/2*2, 16/12*12}, {0, 0} ); -- left
		transformedMinecraftTexture.sign_right = TransformSingleTextureToFile ( originalMinecraftTexture.sign, {64/2, 32/12}, {16/2*26, 16/12*2}, {16/2*2, 16/12*12}, {0, 0} ); -- right
		transformedMinecraftTexture.sign_front = TransformSingleTextureToFile ( originalMinecraftTexture.sign, {64/24, 32/12}, {16/24*2, 16/12*2}, {16/24*24, 16/12*12}, {0, 0} ); -- front
		transformedMinecraftTexture.sign_back = TransformSingleTextureToFile ( originalMinecraftTexture.sign, {64/24, 32/12}, {16/24*28, 16/12*2}, {16/24*24, 16/12*12}, {0, 0} ); -- back
		transformedMinecraftTexture.sign_bottom = TransformMultipleModifiedTextureToFile ( { -- bottom
			[1] = { originalMinecraftTexture.sign, {64/24, 32/2}, {16/24*26, 16/2*0}, {16/24*24, 16/2*2}, {0, 0}, {'flip_x'} } } );
		transformedMinecraftTexture.sign_top = TransformMultipleModifiedTextureToFile ( { -- top
			[1] = { originalMinecraftTexture.sign, {64/24, 32/2}, {16/24*2, 16/2*0}, {16/24*24, 16/2*2}, {0, 0}, { 'rotate_180'} } } );
	
	-- ID 119, Cauldron
		originalMinecraftTexture.cauldron_top = LoadTextureFromFile( "assets/minecraft/textures/blocks/", "cauldron_top.png", 16, 16 ); -- load textures
		originalMinecraftTexture.cauldron_inner = LoadTextureFromFile( "assets/minecraft/textures/blocks/", "cauldron_inner.png", 16, 16 );
		originalMinecraftTexture.cauldron_bottom = LoadTextureFromFile( "assets/minecraft/textures/blocks/", "cauldron_bottom.png", 16, 16 );	
		
		-- Save Textures
		transformedMinecraftTexture.cauldron_top_combined = TransformMultipleTextureToFile ( { -- top
			[1] = { originalMinecraftTexture.cauldron_inner, {1, 1}, {0, 0}, {16, 16}, {0, 0} }, -- floor
			[2] = { originalMinecraftTexture.cauldron_top, {1, 1}, {0, 0}, {16, 2}, {0, 0} }, -- wall, top
			[3] = { originalMinecraftTexture.cauldron_top, {1, 1}, {14, 0}, {2, 16}, {14, 0} }, -- wall, right
			[4] = { originalMinecraftTexture.cauldron_top, {1, 1}, {0, 14}, {16, 2}, {0, 14} }, -- wall, bottom
			[5] = { originalMinecraftTexture.cauldron_top, {1, 1}, {0, 0}, {2, 16}, {0, 0} } } ); -- wall, left
		transformedMinecraftTexture.cauldron_bottom_combined = TransformMultipleTextureToFile ( { -- bottom
			[1] = { originalMinecraftTexture.cauldron_inner, {1, 1}, {0, 0}, {16, 16}, {0, 0} }, -- floor
			[2] = { originalMinecraftTexture.cauldron_bottom, {1, 1}, {0, 0}, {4, 2}, {0, 0} }, -- stand, top-left
			[3] = { originalMinecraftTexture.cauldron_bottom, {1, 1}, {12, 0}, {4, 2}, {12, 0} }, -- stand, top-right
			[4] = { originalMinecraftTexture.cauldron_bottom, {1, 1}, {14, 0}, {2, 4}, {14, 0} }, -- stand, right-top
			[5] = { originalMinecraftTexture.cauldron_bottom, {1, 1}, {14, 12}, {2, 4}, {14, 12} }, -- stand, right-bottom
			[6] = { originalMinecraftTexture.cauldron_bottom, {1, 1}, {0, 14}, {4, 2}, {0, 14} }, -- stand, bottom-left
			[7] = { originalMinecraftTexture.cauldron_bottom, {1, 1}, {12, 14}, {4, 2}, {12, 14} }, -- stand, bottom-right
			[8] = { originalMinecraftTexture.cauldron_bottom, {1, 1}, {0, 0}, {2, 4}, {0, 0} }, -- stand, left-top
			[9] = { originalMinecraftTexture.cauldron_bottom, {1, 1}, {0, 12}, {2, 4}, {0, 12} } } ); -- stand, left-bottom
	
	-- ID 120, End Portal Frame
		originalMinecraftTexture.endframe_side = LoadTextureFromFile( "assets/minecraft/textures/blocks/", "endframe_side.png", 16, 16 ); -- load textures
		originalMinecraftTexture.endframe_top = LoadTextureFromFile( "assets/minecraft/textures/blocks/", "endframe_top.png", 16, 16 );
		originalMinecraftTexture.endframe_eye = LoadTextureFromFile( "assets/minecraft/textures/blocks/", "endframe_eye.png", 16, 16 );
		
		-- Save Textures
		transformedMinecraftTexture.endframe_side_eye = TransformMultipleTextureToFile ( { -- side
			[1] = { originalMinecraftTexture.endframe_side, {1, 1}, {0, 3}, {16, 13}, {0, 3} },
			[2] = { originalMinecraftTexture.endframe_eye, {1, 1}, {4, 0}, {8, 3}, {4, 0} } } );
		transformedMinecraftTexture.endframe_top_eye = TransformMultipleTextureToFile ( { -- top
			[1] = { originalMinecraftTexture.endframe_top, {1, 1}, {0, 0}, {16, 16}, {0, 0} },
			[2] = { originalMinecraftTexture.endframe_eye, {1, 1}, {4, 4}, {8, 8}, {4, 4} } } );
			
	-- ID 127, Cocoa Plant
		originalMinecraftTexture.cocoa_stage_0 = LoadTextureFromFile( "assets/minecraft/textures/blocks/", "cocoa_stage_0.png", 16, 16 ); -- load textures
		originalMinecraftTexture.cocoa_stage_1 = LoadTextureFromFile( "assets/minecraft/textures/blocks/", "cocoa_stage_1.png", 16, 16 );
		originalMinecraftTexture.cocoa_stage_2 = LoadTextureFromFile( "assets/minecraft/textures/blocks/", "cocoa_stage_2.png", 16, 16 );
		
		-- Save Textures
		transformedMinecraftTexture.cocoa_age_0_top = TransformSingleTextureToFile ( originalMinecraftTexture.cocoa_stage_0, {1, 1}, {0, 0}, {4, 4}, {6, 11} ); -- age 0, top
		transformedMinecraftTexture.cocoa_age_0_bottom = TransformSingleTextureToFile ( originalMinecraftTexture.cocoa_stage_0, {1, 1}, {0, 0}, {4, 4}, {6, 1} ); -- age 0, bottom
		transformedMinecraftTexture.cocoa_age_0_side_left = TransformMultipleModifiedTextureToFile ( { -- age 0, side left
			[1] = { originalMinecraftTexture.cocoa_stage_0, {1, 1}, {11, 0}, {5, 4}, {0, 0}, {'flip_x'} },
			[2] = { originalMinecraftTexture.cocoa_stage_0, {1, 1}, {11, 4}, {5, 5}, {1, 4}, { } } } );
		transformedMinecraftTexture.cocoa_age_0_side_right = TransformSingleTextureToFile ( originalMinecraftTexture.cocoa_stage_0, {1, 1}, {11, 0}, {5, 9}, {11, 0} ); -- age 0, side right
		transformedMinecraftTexture.cocoa_age_0_side_middle = TransformSingleTextureToFile ( originalMinecraftTexture.cocoa_stage_0, {1, 1}, {11, 4}, {4, 5}, {6, 4} ); -- age 0, side middle
		transformedMinecraftTexture.cocoa_age_1_top = TransformSingleTextureToFile ( originalMinecraftTexture.cocoa_stage_1, {1, 1}, {0, 0}, {6, 6}, {5, 9} ); -- age 1, top
		transformedMinecraftTexture.cocoa_age_1_bottom = TransformSingleTextureToFile ( originalMinecraftTexture.cocoa_stage_1, {1, 1}, {0, 0}, {6, 6}, {5, 1} ); -- age 1, bottom
		transformedMinecraftTexture.cocoa_age_1_side_left = TransformMultipleModifiedTextureToFile ( { -- age 1, side left
			[1] = { originalMinecraftTexture.cocoa_stage_1, {1, 1}, {11, 0}, {5, 4}, {0, 0}, {'flip_x'} },
			[2] = { originalMinecraftTexture.cocoa_stage_1, {1, 1}, {9, 4}, {7, 7}, {1, 4}, { } } } );
		transformedMinecraftTexture.cocoa_age_1_side_right = TransformSingleTextureToFile ( originalMinecraftTexture.cocoa_stage_1, {1, 1}, {9, 0}, {7, 11}, {9, 0} ); -- age 1, side right
		transformedMinecraftTexture.cocoa_age_1_side_middle = TransformSingleTextureToFile ( originalMinecraftTexture.cocoa_stage_1, {1, 1}, {9, 4}, {6, 7}, {5, 4} ); -- age 1, side middle
		transformedMinecraftTexture.cocoa_age_2_top = UpscaleImageTexture ( originalMinecraftTexture.cocoa_stage_2, {1, 1}, {0, 0}, {7, 7}, {4, 7}, {8, 8} ); -- age 2, top
		transformedMinecraftTexture.cocoa_age_2_bottom = UpscaleImageTexture ( originalMinecraftTexture.cocoa_stage_2, {1, 1}, {0, 0}, {7, 7}, {4, 1}, {8, 8} ); -- age 2, bottom
		transformedMinecraftTexture.cocoa_age_2_side_left = TransformMultipleModifiedTextureToFile ( { -- age 2, side left
			[1] = { originalMinecraftTexture.cocoa_stage_2, {1, 1}, {11, 0}, {5, 4}, {0, 0}, {'flip_x'} },
			[2] = { originalMinecraftTexture.cocoa_stage_2, {1, 1}, {7, 4}, {9, 9}, {1, 4}, { } } } );
		transformedMinecraftTexture.cocoa_age_2_side_right = TransformSingleTextureToFile ( originalMinecraftTexture.cocoa_stage_2, {1, 1}, {7, 0}, {9, 13}, {7, 0} ); -- age 2, side right
		transformedMinecraftTexture.cocoa_age_2_side_middle = TransformSingleTextureToFile ( originalMinecraftTexture.cocoa_stage_2, {1, 1}, {7, 4}, {8, 9}, {4, 4} ); -- age 2, side middle
	
	-- ID 130, Ender Chest
		originalMinecraftTexture.chest_ender = LoadTextureFromFile( "assets/minecraft/textures/entity/chest/", "ender.png", 64, 64 ); -- load texture
		
		-- Save Textures
		transformedMinecraftTexture.chest_ender_left = TransformMultipleTextureToFile ( { -- left
			[1] = { originalMinecraftTexture.chest_ender, {4, 4}, {0, 14}, {14, 4}, {1, 2} },
			[2] = { originalMinecraftTexture.chest_ender, {4, 4}, {0, 33}, {14, 10}, {1, 6} },
			[3] = { originalMinecraftTexture.chest_ender, {4, 4}, {0, 1}, {1, 4}, {15, 5} } } );
		transformedMinecraftTexture.chest_ender_right = TransformMultipleTextureToFile ( { -- right
			[1] = { originalMinecraftTexture.chest_ender, {4, 4}, {28, 14}, {14, 4}, {1, 2} },
			[2] = { originalMinecraftTexture.chest_ender, {4, 4}, {28, 33}, {14, 10}, {1, 6} },
			[3] = { originalMinecraftTexture.chest_ender, {4, 4}, {3, 1}, {1, 4}, {0, 5} } } );
		transformedMinecraftTexture.chest_ender_back = TransformMultipleTextureToFile ( { -- back
			[1] = { originalMinecraftTexture.chest_ender, {4, 4}, {42, 14}, {14, 4}, {1, 2} },
			[2] = { originalMinecraftTexture.chest_ender, {4, 4}, {42, 33}, {14, 10}, {1, 6} } } );
		transformedMinecraftTexture.chest_ender_front = TransformMultipleTextureToFile ( { -- front
			[1] = { originalMinecraftTexture.chest_ender, {4, 4}, {0, 14}, {14, 4}, {1, 2} },
			[2] = { originalMinecraftTexture.chest_ender, {4, 4}, {14, 33}, {14, 10}, {1, 6} },
			[3] = { originalMinecraftTexture.chest_ender, {4, 4}, {1, 1}, {2, 4}, {7, 5} } } );
		transformedMinecraftTexture.chest_ender_bottom = TransformMultipleTextureToFile ( { -- bottom
			[1] = { originalMinecraftTexture.chest_ender, {4, 4}, {28, 19}, {14, 14}, {1, 1} },
			[2] = { originalMinecraftTexture.chest_ender, {4, 4}, {3, 0}, {2, 1}, {7, 15} } } );
		transformedMinecraftTexture.chest_ender_top = TransformMultipleTextureToFile ( { -- top
			[1] = { originalMinecraftTexture.chest_ender, {4, 4}, {14, 0}, {14, 14}, {1, 1} },
			[2] = { originalMinecraftTexture.chest_ender, {4, 4}, {1, 0}, {2, 1}, {7, 15} } } );
	
	-- ID 140, Flower Pot
		originalMinecraftTexture.flower_pot = LoadTextureFromFile( "assets/minecraft/textures/blocks/", "flower_pot.png", 16, 16 ); -- load textures
		originalMinecraftTexture.dirt = LoadTextureFromFile( "assets/minecraft/textures/blocks/", "dirt.png", 16, 16 );
		
		-- Save Textures
		transformedMinecraftTexture.flower_pot_side = TransformSingleTextureToFile ( originalMinecraftTexture.flower_pot, {1, 1}, {5, 10}, {6, 6}, {5, 10} ); -- side
		transformedMinecraftTexture.flower_pot_top = TransformMultipleTextureToFile ( { -- top
			[1] = { originalMinecraftTexture.flower_pot, {1, 1}, {5, 5}, {6, 6}, {5, 5} },
			[2] = { originalMinecraftTexture.dirt, {1, 1}, {6, 6}, {4, 4}, {6, 6} } } );
		transformedMinecraftTexture.flower_pot_bottom = TransformSingleTextureToFile ( originalMinecraftTexture.flower_pot, {1, 1}, {5, 5}, {6, 6}, {5, 5} ); -- bottom
	
	-- ID 145, Anvil
		originalMinecraftTexture.anvil_base = LoadTextureFromFile( "assets/minecraft/textures/blocks/", "anvil_base.png", 16, 16 ); -- load textures
		originalMinecraftTexture.anvil_top_damaged_0 = LoadTextureFromFile( "assets/minecraft/textures/blocks/", "anvil_top_damaged_0.png", 16, 16 );
		originalMinecraftTexture.anvil_top_damaged_1 = LoadTextureFromFile( "assets/minecraft/textures/blocks/", "anvil_top_damaged_1.png", 16, 16 );
		originalMinecraftTexture.anvil_top_damaged_2 = LoadTextureFromFile( "assets/minecraft/textures/blocks/", "anvil_top_damaged_2.png", 16, 16 );
		
		-- Save Textures
		transformedMinecraftTexture.anvil_side_wide = TransformMultipleModifiedTextureToFile ( { -- side wide
			[1] = { originalMinecraftTexture.anvil_base, {1, 1}, {10, 0}, {6, 16}, {0, 0}, { 'rotate_270' } },
			[2] = { originalMinecraftTexture.anvil_base, {1, 1}, {5, 4}, {5, 8}, {4, 6}, { 'rotate_270' } },
			[3] = { originalMinecraftTexture.anvil_base, {1, 1}, {4, 3}, {1, 10}, {3, 11}, { 'rotate_270' } },
			[4] = { originalMinecraftTexture.anvil_base, {1, 1}, {0, 2}, {4, 12}, {2, 12}, { 'rotate_270' } } } );
		transformedMinecraftTexture.anvil_side_narrow = TransformMultipleTextureToFile ( { -- side narrow
			[1] = { originalMinecraftTexture.anvil_base, {1, 1}, {3, 0}, {10, 6}, {3, 0} },
			[2] = { originalMinecraftTexture.anvil_base, {1, 1}, {6, 6}, {4, 5}, {6, 6} },
			[3] = { originalMinecraftTexture.anvil_base, {1, 1}, {4, 11}, {8, 1}, {4, 11} },
			[4] = { originalMinecraftTexture.anvil_base, {1, 1}, {2, 12}, {12, 4}, {2, 12} } } );
		transformedMinecraftTexture.anvil_top_merge_damaged_0 = TransformMultipleTextureToFile ( { -- regular anvil, top
			[1] = { originalMinecraftTexture.anvil_base, {1, 1}, {0, 0}, {16, 16}, {0, 0} },
			[2] = { originalMinecraftTexture.anvil_top_damaged_0, {1, 1}, {3, 0}, {10, 16}, {3, 0} } } );
		transformedMinecraftTexture.anvil_top_merge_damaged_1 = TransformMultipleTextureToFile ( { -- slightly damaged anvil, top
			[1] = { originalMinecraftTexture.anvil_base, {1, 1}, {0, 0}, {16, 16}, {0, 0} },
			[2] = { originalMinecraftTexture.anvil_top_damaged_1, {1, 1}, {3, 0}, {10, 16}, {3, 0} } } );
		transformedMinecraftTexture.anvil_top_merge_damaged_2 = TransformMultipleTextureToFile ( { -- very damaged anvil, top
			[1] = { originalMinecraftTexture.anvil_base, {1, 1}, {0, 0}, {16, 16}, {0, 0} },
			[2] = { originalMinecraftTexture.anvil_top_damaged_2, {1, 1}, {3, 0}, {10, 16}, {3, 0} } } );
	
	-- ID 146, Trapped Chest
		originalMinecraftTexture.chest_trapped = LoadTextureFromFile( "assets/minecraft/textures/entity/chest/", "trapped.png", 64, 64 ); -- load texture
		
		-- Save Textures
		transformedMinecraftTexture.chest_trapped_left = TransformMultipleTextureToFile ( { -- left
			[1] = { originalMinecraftTexture.chest_trapped, {4, 4}, {0, 14}, {14, 4}, {1, 2} },
			[2] = { originalMinecraftTexture.chest_trapped, {4, 4}, {0, 33}, {14, 10}, {1, 6} },
			[3] = { originalMinecraftTexture.chest_trapped, {4, 4}, {0, 1}, {1, 4}, {15, 5} } } );
		transformedMinecraftTexture.chest_trapped_right = TransformMultipleTextureToFile ( { -- right
			[1] = { originalMinecraftTexture.chest_trapped, {4, 4}, {28, 14}, {14, 4}, {1, 2} },
			[2] = { originalMinecraftTexture.chest_trapped, {4, 4}, {28, 33}, {14, 10}, {1, 6} },
			[3] = { originalMinecraftTexture.chest_trapped, {4, 4}, {3, 1}, {1, 4}, {0, 5} } } );
		transformedMinecraftTexture.chest_trapped_back = TransformMultipleTextureToFile ( { -- back
			[1] = { originalMinecraftTexture.chest_trapped, {4, 4}, {42, 14}, {14, 4}, {1, 2} },
			[2] = { originalMinecraftTexture.chest_trapped, {4, 4}, {42, 33}, {14, 10}, {1, 6} } } );
		transformedMinecraftTexture.chest_trapped_front = TransformMultipleTextureToFile ( { -- front
			[1] = { originalMinecraftTexture.chest_trapped, {4, 4}, {0, 14}, {14, 4}, {1, 2} },
			[2] = { originalMinecraftTexture.chest_trapped, {4, 4}, {14, 33}, {14, 10}, {1, 6} },
			[3] = { originalMinecraftTexture.chest_trapped, {4, 4}, {1, 1}, {2, 4}, {7, 5} } } );
		transformedMinecraftTexture.chest_trapped_bottom = TransformMultipleTextureToFile ( { -- bottom
			[1] = { originalMinecraftTexture.chest_trapped, {4, 4}, {28, 19}, {14, 14}, {1, 1} },
			[2] = { originalMinecraftTexture.chest_trapped, {4, 4}, {3, 0}, {2, 1}, {7, 15} } } );
		transformedMinecraftTexture.chest_trapped_top = TransformMultipleTextureToFile ( { -- top
			[1] = { originalMinecraftTexture.chest_trapped, {4, 4}, {14, 0}, {14, 14}, {1, 1} },
			[2] = { originalMinecraftTexture.chest_trapped, {4, 4}, {1, 0}, {2, 1}, {7, 15} } } );
	
	-- ID 154, Hopper
		originalMinecraftTexture.hopper_inside = LoadTextureFromFile( "assets/minecraft/textures/blocks/", "hopper_inside.png", 16, 16 ); -- load textures
		originalMinecraftTexture.hopper_top = LoadTextureFromFile( "assets/minecraft/textures/blocks/", "hopper_top.png", 16, 16 );
		
		-- Save Textures
		transformedMinecraftTexture.hopper_top_merge = TransformMultipleTextureToFile ( { -- top
			[1] = { originalMinecraftTexture.hopper_top, {1, 1}, {0, 0}, {16, 16}, {0, 0} },
			[2] = { originalMinecraftTexture.hopper_inside, {1, 1}, {2, 2}, {12, 12}, {2, 2} } } );
	
	-- ID 198, End Rod
		originalMinecraftTexture.end_rod = LoadTextureFromFile( "assets/minecraft/textures/blocks/", "end_rod.png", 16, 16 ); -- load texture
		
		-- Save Textures
		transformedMinecraftTexture.end_rod_top = TransformMultipleTextureToFile ( { -- top
			[1] = { originalMinecraftTexture.end_rod, {1, 1}, {2, 2}, {4, 4}, {6, 6} },
			[2] = { originalMinecraftTexture.end_rod, {1, 1}, {2, 0}, {2, 2}, {7, 7} } } );
		transformedMinecraftTexture.end_rod_side = TransformMultipleTextureToFile ( { -- side
			[1] = { originalMinecraftTexture.end_rod, {1, 1}, {0, 0}, {2, 15}, {7, 0} },
			[2] = { originalMinecraftTexture.end_rod, {1, 1}, {2, 6}, {4, 1}, {6, 15} } } );
		transformedMinecraftTexture.end_rod_bottom = TransformSingleTextureToFile ( originalMinecraftTexture.end_rod, {1, 1}, {2, 2}, {4, 4}, {6, 6} ); -- bottom
	
	-- ID 219, White Shulker Box
		originalMinecraftTexture.shulker_white = LoadTextureFromFile( "assets/minecraft/textures/entity/shulker/", "shulker_white.png", 64, 64 ); -- load texture
		
		-- Save Textures
		transformedMinecraftTexture.shulker_white_top = TransformSingleTextureToFile ( originalMinecraftTexture.shulker_white, {4, 4}, {16, 0}, {16, 16}, {0, 0} ); -- top
		transformedMinecraftTexture.shulker_white_side_left = TransformMultipleTextureToFile ( { -- left
			[1] = { originalMinecraftTexture.shulker_white, {4, 4}, {0, 16}, {16, 12}, {0, 0} },
			[2] = { originalMinecraftTexture.shulker_white, {4, 4}, {4, 44}, {8, 4}, {4, 8} },
			[3] = { originalMinecraftTexture.shulker_white, {4, 4}, {0, 48}, {16, 4}, {0, 12} } } );
		transformedMinecraftTexture.shulker_white_side_front = TransformMultipleTextureToFile ( { -- front
			[1] = { originalMinecraftTexture.shulker_white, {4, 4}, {16, 16}, {16, 12}, {0, 0} },
			[2] = { originalMinecraftTexture.shulker_white, {4, 4}, {20, 44}, {8, 4}, {4, 8} },
			[3] = { originalMinecraftTexture.shulker_white, {4, 4}, {16, 48}, {16, 4}, {0, 12} } } );
		transformedMinecraftTexture.shulker_white_side_right = TransformMultipleTextureToFile ( { -- right
			[1] = { originalMinecraftTexture.shulker_white, {4, 4}, {32, 16}, {16, 12}, {0, 0} },
			[2] = { originalMinecraftTexture.shulker_white, {4, 4}, {36, 44}, {8, 4}, {4, 8} },
			[3] = { originalMinecraftTexture.shulker_white, {4, 4}, {32, 48}, {16, 4}, {0, 12} } } );
		transformedMinecraftTexture.shulker_white_side_back = TransformMultipleTextureToFile ( { -- back
			[1] = { originalMinecraftTexture.shulker_white, {4, 4}, {48, 16}, {16, 12}, {0, 0} },
			[2] = { originalMinecraftTexture.shulker_white, {4, 4}, {52, 44}, {8, 4}, {4, 8} },
			[3] = { originalMinecraftTexture.shulker_white, {4, 4}, {48, 48}, {16, 4}, {0, 12} } } );
		transformedMinecraftTexture.shulker_white_bottom = TransformSingleTextureToFile ( originalMinecraftTexture.shulker_white, {4, 4}, {32, 28}, {16, 16}, {0, 0} ); -- bottom
	
	-- ID 220, Orange Shulker Box
		originalMinecraftTexture.shulker_orange = LoadTextureFromFile( "assets/minecraft/textures/entity/shulker/", "shulker_orange.png", 64, 64 ); -- load texture
		
		-- Save Textures
		transformedMinecraftTexture.shulker_orange_top = TransformSingleTextureToFile ( originalMinecraftTexture.shulker_orange, {4, 4}, {16, 0}, {16, 16}, {0, 0} ); -- top
		transformedMinecraftTexture.shulker_orange_side_left = TransformMultipleTextureToFile ( { -- left
			[1] = { originalMinecraftTexture.shulker_orange, {4, 4}, {0, 16}, {16, 12}, {0, 0} },
			[2] = { originalMinecraftTexture.shulker_orange, {4, 4}, {4, 44}, {8, 4}, {4, 8} },
			[3] = { originalMinecraftTexture.shulker_orange, {4, 4}, {0, 48}, {16, 4}, {0, 12} } } );
		transformedMinecraftTexture.shulker_orange_side_front = TransformMultipleTextureToFile ( { -- front
			[1] = { originalMinecraftTexture.shulker_orange, {4, 4}, {16, 16}, {16, 12}, {0, 0} },
			[2] = { originalMinecraftTexture.shulker_orange, {4, 4}, {20, 44}, {8, 4}, {4, 8} },
			[3] = { originalMinecraftTexture.shulker_orange, {4, 4}, {16, 48}, {16, 4}, {0, 12} } } );
		transformedMinecraftTexture.shulker_orange_side_right = TransformMultipleTextureToFile ( { -- right
			[1] = { originalMinecraftTexture.shulker_orange, {4, 4}, {32, 16}, {16, 12}, {0, 0} },
			[2] = { originalMinecraftTexture.shulker_orange, {4, 4}, {36, 44}, {8, 4}, {4, 8} },
			[3] = { originalMinecraftTexture.shulker_orange, {4, 4}, {32, 48}, {16, 4}, {0, 12} } } );
		transformedMinecraftTexture.shulker_orange_side_back = TransformMultipleTextureToFile ( { -- back
			[1] = { originalMinecraftTexture.shulker_orange, {4, 4}, {48, 16}, {16, 12}, {0, 0} },
			[2] = { originalMinecraftTexture.shulker_orange, {4, 4}, {52, 44}, {8, 4}, {4, 8} },
			[3] = { originalMinecraftTexture.shulker_orange, {4, 4}, {48, 48}, {16, 4}, {0, 12} } } );
		transformedMinecraftTexture.shulker_orange_bottom = TransformSingleTextureToFile ( originalMinecraftTexture.shulker_orange, {4, 4}, {32, 28}, {16, 16}, {0, 0} ); -- bottom
	
	-- ID 221, Magenta Shulker Box
		originalMinecraftTexture.shulker_magenta = LoadTextureFromFile( "assets/minecraft/textures/entity/shulker/", "shulker_magenta.png", 64, 64 ); -- load texture
		
		-- Save Textures
		transformedMinecraftTexture.shulker_magenta_top = TransformSingleTextureToFile ( originalMinecraftTexture.shulker_magenta, {4, 4}, {16, 0}, {16, 16}, {0, 0} ); -- top
		transformedMinecraftTexture.shulker_magenta_side_left = TransformMultipleTextureToFile ( { -- left
			[1] = { originalMinecraftTexture.shulker_magenta, {4, 4}, {0, 16}, {16, 12}, {0, 0} },
			[2] = { originalMinecraftTexture.shulker_magenta, {4, 4}, {4, 44}, {8, 4}, {4, 8} },
			[3] = { originalMinecraftTexture.shulker_magenta, {4, 4}, {0, 48}, {16, 4}, {0, 12} } } );
		transformedMinecraftTexture.shulker_magenta_side_front = TransformMultipleTextureToFile ( { -- front
			[1] = { originalMinecraftTexture.shulker_magenta, {4, 4}, {16, 16}, {16, 12}, {0, 0} },
			[2] = { originalMinecraftTexture.shulker_magenta, {4, 4}, {20, 44}, {8, 4}, {4, 8} },
			[3] = { originalMinecraftTexture.shulker_magenta, {4, 4}, {16, 48}, {16, 4}, {0, 12} } } );
		transformedMinecraftTexture.shulker_magenta_side_right = TransformMultipleTextureToFile ( { -- right
			[1] = { originalMinecraftTexture.shulker_magenta, {4, 4}, {32, 16}, {16, 12}, {0, 0} },
			[2] = { originalMinecraftTexture.shulker_magenta, {4, 4}, {36, 44}, {8, 4}, {4, 8} },
			[3] = { originalMinecraftTexture.shulker_magenta, {4, 4}, {32, 48}, {16, 4}, {0, 12} } } );
		transformedMinecraftTexture.shulker_magenta_side_back = TransformMultipleTextureToFile ( { -- back
			[1] = { originalMinecraftTexture.shulker_magenta, {4, 4}, {48, 16}, {16, 12}, {0, 0} },
			[2] = { originalMinecraftTexture.shulker_magenta, {4, 4}, {52, 44}, {8, 4}, {4, 8} },
			[3] = { originalMinecraftTexture.shulker_magenta, {4, 4}, {48, 48}, {16, 4}, {0, 12} } } );
		transformedMinecraftTexture.shulker_magenta_bottom = TransformSingleTextureToFile ( originalMinecraftTexture.shulker_magenta, {4, 4}, {32, 28}, {16, 16}, {0, 0} ); -- bottom
	
	-- ID 222, Light Blue Shulker Box
		originalMinecraftTexture.shulker_light_blue = LoadTextureFromFile( "assets/minecraft/textures/entity/shulker/", "shulker_light_blue.png", 64, 64 ); -- load texture
		
		-- Save Textures
		transformedMinecraftTexture.shulker_light_blue_top = TransformSingleTextureToFile ( originalMinecraftTexture.shulker_light_blue, {4, 4}, {16, 0}, {16, 16}, {0, 0} ); -- top
		transformedMinecraftTexture.shulker_light_blue_side_left = TransformMultipleTextureToFile ( { -- left
			[1] = { originalMinecraftTexture.shulker_light_blue, {4, 4}, {0, 16}, {16, 12}, {0, 0} },
			[2] = { originalMinecraftTexture.shulker_light_blue, {4, 4}, {4, 44}, {8, 4}, {4, 8} },
			[3] = { originalMinecraftTexture.shulker_light_blue, {4, 4}, {0, 48}, {16, 4}, {0, 12} } } );
		transformedMinecraftTexture.shulker_light_blue_side_front = TransformMultipleTextureToFile ( { -- front
			[1] = { originalMinecraftTexture.shulker_light_blue, {4, 4}, {16, 16}, {16, 12}, {0, 0} },
			[2] = { originalMinecraftTexture.shulker_light_blue, {4, 4}, {20, 44}, {8, 4}, {4, 8} },
			[3] = { originalMinecraftTexture.shulker_light_blue, {4, 4}, {16, 48}, {16, 4}, {0, 12} } } );
		transformedMinecraftTexture.shulker_light_blue_side_right = TransformMultipleTextureToFile ( { -- right
			[1] = { originalMinecraftTexture.shulker_light_blue, {4, 4}, {32, 16}, {16, 12}, {0, 0} },
			[2] = { originalMinecraftTexture.shulker_light_blue, {4, 4}, {36, 44}, {8, 4}, {4, 8} },
			[3] = { originalMinecraftTexture.shulker_light_blue, {4, 4}, {32, 48}, {16, 4}, {0, 12} } } );
		transformedMinecraftTexture.shulker_light_blue_side_back = TransformMultipleTextureToFile ( { -- back
			[1] = { originalMinecraftTexture.shulker_light_blue, {4, 4}, {48, 16}, {16, 12}, {0, 0} },
			[2] = { originalMinecraftTexture.shulker_light_blue, {4, 4}, {52, 44}, {8, 4}, {4, 8} },
			[3] = { originalMinecraftTexture.shulker_light_blue, {4, 4}, {48, 48}, {16, 4}, {0, 12} } } );
		transformedMinecraftTexture.shulker_light_blue_bottom = TransformSingleTextureToFile ( originalMinecraftTexture.shulker_light_blue, {4, 4}, {32, 28}, {16, 16}, {0, 0} ); -- bottom
	
	-- ID 223, Yellow Shulker Box
		originalMinecraftTexture.shulker_yellow = LoadTextureFromFile( "assets/minecraft/textures/entity/shulker/", "shulker_yellow.png", 64, 64 ); -- load texture
		
		-- Save Textures
		transformedMinecraftTexture.shulker_yellow_top = TransformSingleTextureToFile ( originalMinecraftTexture.shulker_yellow, {4, 4}, {16, 0}, {16, 16}, {0, 0} ); -- top
		transformedMinecraftTexture.shulker_yellow_side_left = TransformMultipleTextureToFile ( { -- left
			[1] = { originalMinecraftTexture.shulker_yellow, {4, 4}, {0, 16}, {16, 12}, {0, 0} },
			[2] = { originalMinecraftTexture.shulker_yellow, {4, 4}, {4, 44}, {8, 4}, {4, 8} },
			[3] = { originalMinecraftTexture.shulker_yellow, {4, 4}, {0, 48}, {16, 4}, {0, 12} } } );
		transformedMinecraftTexture.shulker_yellow_side_front = TransformMultipleTextureToFile ( { -- front
			[1] = { originalMinecraftTexture.shulker_yellow, {4, 4}, {16, 16}, {16, 12}, {0, 0} },
			[2] = { originalMinecraftTexture.shulker_yellow, {4, 4}, {20, 44}, {8, 4}, {4, 8} },
			[3] = { originalMinecraftTexture.shulker_yellow, {4, 4}, {16, 48}, {16, 4}, {0, 12} } } );
		transformedMinecraftTexture.shulker_yellow_side_right = TransformMultipleTextureToFile ( { -- right
			[1] = { originalMinecraftTexture.shulker_yellow, {4, 4}, {32, 16}, {16, 12}, {0, 0} },
			[2] = { originalMinecraftTexture.shulker_yellow, {4, 4}, {36, 44}, {8, 4}, {4, 8} },
			[3] = { originalMinecraftTexture.shulker_yellow, {4, 4}, {32, 48}, {16, 4}, {0, 12} } } );
		transformedMinecraftTexture.shulker_yellow_side_back = TransformMultipleTextureToFile ( { -- back
			[1] = { originalMinecraftTexture.shulker_yellow, {4, 4}, {48, 16}, {16, 12}, {0, 0} },
			[2] = { originalMinecraftTexture.shulker_yellow, {4, 4}, {52, 44}, {8, 4}, {4, 8} },
			[3] = { originalMinecraftTexture.shulker_yellow, {4, 4}, {48, 48}, {16, 4}, {0, 12} } } );
		transformedMinecraftTexture.shulker_yellow_bottom = TransformSingleTextureToFile ( originalMinecraftTexture.shulker_yellow, {4, 4}, {32, 28}, {16, 16}, {0, 0} ); -- bottom
	
	-- ID 224, Lime Shulker Box
		originalMinecraftTexture.shulker_lime = LoadTextureFromFile( "assets/minecraft/textures/entity/shulker/", "shulker_lime.png", 64, 64 ); -- load texture
		
		-- Save Textures
		transformedMinecraftTexture.shulker_lime_top = TransformSingleTextureToFile ( originalMinecraftTexture.shulker_lime, {4, 4}, {16, 0}, {16, 16}, {0, 0} ); -- top
		transformedMinecraftTexture.shulker_lime_side_left = TransformMultipleTextureToFile ( { -- left
			[1] = { originalMinecraftTexture.shulker_lime, {4, 4}, {0, 16}, {16, 12}, {0, 0} },
			[2] = { originalMinecraftTexture.shulker_lime, {4, 4}, {4, 44}, {8, 4}, {4, 8} },
			[3] = { originalMinecraftTexture.shulker_lime, {4, 4}, {0, 48}, {16, 4}, {0, 12} } } );
		transformedMinecraftTexture.shulker_lime_side_front = TransformMultipleTextureToFile ( { -- front
			[1] = { originalMinecraftTexture.shulker_lime, {4, 4}, {16, 16}, {16, 12}, {0, 0} },
			[2] = { originalMinecraftTexture.shulker_lime, {4, 4}, {20, 44}, {8, 4}, {4, 8} },
			[3] = { originalMinecraftTexture.shulker_lime, {4, 4}, {16, 48}, {16, 4}, {0, 12} } } );
		transformedMinecraftTexture.shulker_lime_side_right = TransformMultipleTextureToFile ( { -- right
			[1] = { originalMinecraftTexture.shulker_lime, {4, 4}, {32, 16}, {16, 12}, {0, 0} },
			[2] = { originalMinecraftTexture.shulker_lime, {4, 4}, {36, 44}, {8, 4}, {4, 8} },
			[3] = { originalMinecraftTexture.shulker_lime, {4, 4}, {32, 48}, {16, 4}, {0, 12} } } );
		transformedMinecraftTexture.shulker_lime_side_back = TransformMultipleTextureToFile ( { -- back
			[1] = { originalMinecraftTexture.shulker_lime, {4, 4}, {48, 16}, {16, 12}, {0, 0} },
			[2] = { originalMinecraftTexture.shulker_lime, {4, 4}, {52, 44}, {8, 4}, {4, 8} },
			[3] = { originalMinecraftTexture.shulker_lime, {4, 4}, {48, 48}, {16, 4}, {0, 12} } } );
		transformedMinecraftTexture.shulker_lime_bottom = TransformSingleTextureToFile ( originalMinecraftTexture.shulker_lime, {4, 4}, {32, 28}, {16, 16}, {0, 0} ); -- bottom
	
	-- ID 225, Pink Shulker Box
		originalMinecraftTexture.shulker_pink = LoadTextureFromFile( "assets/minecraft/textures/entity/shulker/", "shulker_pink.png", 64, 64 ); -- load texture
		
		-- Save Textures
		transformedMinecraftTexture.shulker_pink_top = TransformSingleTextureToFile ( originalMinecraftTexture.shulker_pink, {4, 4}, {16, 0}, {16, 16}, {0, 0} ); -- top
		transformedMinecraftTexture.shulker_pink_side_left = TransformMultipleTextureToFile ( { -- left
			[1] = { originalMinecraftTexture.shulker_pink, {4, 4}, {0, 16}, {16, 12}, {0, 0} },
			[2] = { originalMinecraftTexture.shulker_pink, {4, 4}, {4, 44}, {8, 4}, {4, 8} },
			[3] = { originalMinecraftTexture.shulker_pink, {4, 4}, {0, 48}, {16, 4}, {0, 12} } } );
		transformedMinecraftTexture.shulker_pink_side_front = TransformMultipleTextureToFile ( { -- front
			[1] = { originalMinecraftTexture.shulker_pink, {4, 4}, {16, 16}, {16, 12}, {0, 0} },
			[2] = { originalMinecraftTexture.shulker_pink, {4, 4}, {20, 44}, {8, 4}, {4, 8} },
			[3] = { originalMinecraftTexture.shulker_pink, {4, 4}, {16, 48}, {16, 4}, {0, 12} } } );
		transformedMinecraftTexture.shulker_pink_side_right = TransformMultipleTextureToFile ( { -- right
			[1] = { originalMinecraftTexture.shulker_pink, {4, 4}, {32, 16}, {16, 12}, {0, 0} },
			[2] = { originalMinecraftTexture.shulker_pink, {4, 4}, {36, 44}, {8, 4}, {4, 8} },
			[3] = { originalMinecraftTexture.shulker_pink, {4, 4}, {32, 48}, {16, 4}, {0, 12} } } );
		transformedMinecraftTexture.shulker_pink_side_back = TransformMultipleTextureToFile ( { -- back
			[1] = { originalMinecraftTexture.shulker_pink, {4, 4}, {48, 16}, {16, 12}, {0, 0} },
			[2] = { originalMinecraftTexture.shulker_pink, {4, 4}, {52, 44}, {8, 4}, {4, 8} },
			[3] = { originalMinecraftTexture.shulker_pink, {4, 4}, {48, 48}, {16, 4}, {0, 12} } } );
		transformedMinecraftTexture.shulker_pink_bottom = TransformSingleTextureToFile ( originalMinecraftTexture.shulker_pink, {4, 4}, {32, 28}, {16, 16}, {0, 0} ); -- bottom
	
	-- ID 226, Gray Shulker Box
		originalMinecraftTexture.shulker_gray = LoadTextureFromFile( "assets/minecraft/textures/entity/shulker/", "shulker_gray.png", 64, 64 ); -- load texture
		
		-- Save Textures
		transformedMinecraftTexture.shulker_gray_top = TransformSingleTextureToFile ( originalMinecraftTexture.shulker_gray, {4, 4}, {16, 0}, {16, 16}, {0, 0} ); -- top
		transformedMinecraftTexture.shulker_gray_side_left = TransformMultipleTextureToFile ( { -- left
			[1] = { originalMinecraftTexture.shulker_gray, {4, 4}, {0, 16}, {16, 12}, {0, 0} },
			[2] = { originalMinecraftTexture.shulker_gray, {4, 4}, {4, 44}, {8, 4}, {4, 8} },
			[3] = { originalMinecraftTexture.shulker_gray, {4, 4}, {0, 48}, {16, 4}, {0, 12} } } );
		transformedMinecraftTexture.shulker_gray_side_front = TransformMultipleTextureToFile ( { -- front
			[1] = { originalMinecraftTexture.shulker_gray, {4, 4}, {16, 16}, {16, 12}, {0, 0} },
			[2] = { originalMinecraftTexture.shulker_gray, {4, 4}, {20, 44}, {8, 4}, {4, 8} },
			[3] = { originalMinecraftTexture.shulker_gray, {4, 4}, {16, 48}, {16, 4}, {0, 12} } } );
		transformedMinecraftTexture.shulker_gray_side_right = TransformMultipleTextureToFile ( { -- right
			[1] = { originalMinecraftTexture.shulker_gray, {4, 4}, {32, 16}, {16, 12}, {0, 0} },
			[2] = { originalMinecraftTexture.shulker_gray, {4, 4}, {36, 44}, {8, 4}, {4, 8} },
			[3] = { originalMinecraftTexture.shulker_gray, {4, 4}, {32, 48}, {16, 4}, {0, 12} } } );
		transformedMinecraftTexture.shulker_gray_side_back = TransformMultipleTextureToFile ( { -- back
			[1] = { originalMinecraftTexture.shulker_gray, {4, 4}, {48, 16}, {16, 12}, {0, 0} },
			[2] = { originalMinecraftTexture.shulker_gray, {4, 4}, {52, 44}, {8, 4}, {4, 8} },
			[3] = { originalMinecraftTexture.shulker_gray, {4, 4}, {48, 48}, {16, 4}, {0, 12} } } );
		transformedMinecraftTexture.shulker_gray_bottom = TransformSingleTextureToFile ( originalMinecraftTexture.shulker_gray, {4, 4}, {32, 28}, {16, 16}, {0, 0} ); -- bottom
	
	-- ID 227, Light Gray Shulker Box
		originalMinecraftTexture.shulker_light_gray = LoadTextureFromFile( "assets/minecraft/textures/entity/shulker/", "shulker_light_gray.png", 64, 64 ); -- load texture
		
		-- Save Textures
		transformedMinecraftTexture.shulker_light_gray_top = TransformSingleTextureToFile ( originalMinecraftTexture.shulker_light_gray, {4, 4}, {16, 0}, {16, 16}, {0, 0} ); -- top
		transformedMinecraftTexture.shulker_light_gray_side_left = TransformMultipleTextureToFile ( { -- left
			[1] = { originalMinecraftTexture.shulker_light_gray, {4, 4}, {0, 16}, {16, 12}, {0, 0} },
			[2] = { originalMinecraftTexture.shulker_light_gray, {4, 4}, {4, 44}, {8, 4}, {4, 8} },
			[3] = { originalMinecraftTexture.shulker_light_gray, {4, 4}, {0, 48}, {16, 4}, {0, 12} } } );
		transformedMinecraftTexture.shulker_light_gray_side_front = TransformMultipleTextureToFile ( { -- front
			[1] = { originalMinecraftTexture.shulker_light_gray, {4, 4}, {16, 16}, {16, 12}, {0, 0} },
			[2] = { originalMinecraftTexture.shulker_light_gray, {4, 4}, {20, 44}, {8, 4}, {4, 8} },
			[3] = { originalMinecraftTexture.shulker_light_gray, {4, 4}, {16, 48}, {16, 4}, {0, 12} } } );
		transformedMinecraftTexture.shulker_light_gray_side_right = TransformMultipleTextureToFile ( { -- right
			[1] = { originalMinecraftTexture.shulker_light_gray, {4, 4}, {32, 16}, {16, 12}, {0, 0} },
			[2] = { originalMinecraftTexture.shulker_light_gray, {4, 4}, {36, 44}, {8, 4}, {4, 8} },
			[3] = { originalMinecraftTexture.shulker_light_gray, {4, 4}, {32, 48}, {16, 4}, {0, 12} } } );
		transformedMinecraftTexture.shulker_light_gray_side_back = TransformMultipleTextureToFile ( { -- back
			[1] = { originalMinecraftTexture.shulker_light_gray, {4, 4}, {48, 16}, {16, 12}, {0, 0} },
			[2] = { originalMinecraftTexture.shulker_light_gray, {4, 4}, {52, 44}, {8, 4}, {4, 8} },
			[3] = { originalMinecraftTexture.shulker_light_gray, {4, 4}, {48, 48}, {16, 4}, {0, 12} } } );
		transformedMinecraftTexture.shulker_light_gray_bottom = TransformSingleTextureToFile ( originalMinecraftTexture.shulker_light_gray, {4, 4}, {32, 28}, {16, 16}, {0, 0} ); -- bottom
	
	-- ID 228, Cyan Shulker Box
		originalMinecraftTexture.shulker_cyan = LoadTextureFromFile( "assets/minecraft/textures/entity/shulker/", "shulker_cyan.png", 64, 64 ); -- load texture
		
		-- Save Textures
		transformedMinecraftTexture.shulker_cyan_top = TransformSingleTextureToFile ( originalMinecraftTexture.shulker_cyan, {4, 4}, {16, 0}, {16, 16}, {0, 0} ); -- top
		transformedMinecraftTexture.shulker_cyan_side_left = TransformMultipleTextureToFile ( { -- left
			[1] = { originalMinecraftTexture.shulker_cyan, {4, 4}, {0, 16}, {16, 12}, {0, 0} },
			[2] = { originalMinecraftTexture.shulker_cyan, {4, 4}, {4, 44}, {8, 4}, {4, 8} },
			[3] = { originalMinecraftTexture.shulker_cyan, {4, 4}, {0, 48}, {16, 4}, {0, 12} } } );
		transformedMinecraftTexture.shulker_cyan_side_front = TransformMultipleTextureToFile ( { -- front
			[1] = { originalMinecraftTexture.shulker_cyan, {4, 4}, {16, 16}, {16, 12}, {0, 0} },
			[2] = { originalMinecraftTexture.shulker_cyan, {4, 4}, {20, 44}, {8, 4}, {4, 8} },
			[3] = { originalMinecraftTexture.shulker_cyan, {4, 4}, {16, 48}, {16, 4}, {0, 12} } } );
		transformedMinecraftTexture.shulker_cyan_side_right = TransformMultipleTextureToFile ( { -- right
			[1] = { originalMinecraftTexture.shulker_cyan, {4, 4}, {32, 16}, {16, 12}, {0, 0} },
			[2] = { originalMinecraftTexture.shulker_cyan, {4, 4}, {36, 44}, {8, 4}, {4, 8} },
			[3] = { originalMinecraftTexture.shulker_cyan, {4, 4}, {32, 48}, {16, 4}, {0, 12} } } );
		transformedMinecraftTexture.shulker_cyan_side_back = TransformMultipleTextureToFile ( { -- back
			[1] = { originalMinecraftTexture.shulker_cyan, {4, 4}, {48, 16}, {16, 12}, {0, 0} },
			[2] = { originalMinecraftTexture.shulker_cyan, {4, 4}, {52, 44}, {8, 4}, {4, 8} },
			[3] = { originalMinecraftTexture.shulker_cyan, {4, 4}, {48, 48}, {16, 4}, {0, 12} } } );
		transformedMinecraftTexture.shulker_cyan_bottom = TransformSingleTextureToFile ( originalMinecraftTexture.shulker_cyan, {4, 4}, {32, 28}, {16, 16}, {0, 0} ); -- bottom
	
	-- ID 229, Purple Shulker Box
		originalMinecraftTexture.shulker_purple = LoadTextureFromFile( "assets/minecraft/textures/entity/shulker/", "shulker_purple.png", 64, 64 ); -- load texture
		
		-- Save Textures
		transformedMinecraftTexture.shulker_purple_top = TransformSingleTextureToFile ( originalMinecraftTexture.shulker_purple, {4, 4}, {16, 0}, {16, 16}, {0, 0} ); -- top
		transformedMinecraftTexture.shulker_purple_side_left = TransformMultipleTextureToFile ( { -- left
			[1] = { originalMinecraftTexture.shulker_purple, {4, 4}, {0, 16}, {16, 12}, {0, 0} },
			[2] = { originalMinecraftTexture.shulker_purple, {4, 4}, {4, 44}, {8, 4}, {4, 8} },
			[3] = { originalMinecraftTexture.shulker_purple, {4, 4}, {0, 48}, {16, 4}, {0, 12} } } );
		transformedMinecraftTexture.shulker_purple_side_front = TransformMultipleTextureToFile ( { -- front
			[1] = { originalMinecraftTexture.shulker_purple, {4, 4}, {16, 16}, {16, 12}, {0, 0} },
			[2] = { originalMinecraftTexture.shulker_purple, {4, 4}, {20, 44}, {8, 4}, {4, 8} },
			[3] = { originalMinecraftTexture.shulker_purple, {4, 4}, {16, 48}, {16, 4}, {0, 12} } } );
		transformedMinecraftTexture.shulker_purple_side_right = TransformMultipleTextureToFile ( { -- right
			[1] = { originalMinecraftTexture.shulker_purple, {4, 4}, {32, 16}, {16, 12}, {0, 0} },
			[2] = { originalMinecraftTexture.shulker_purple, {4, 4}, {36, 44}, {8, 4}, {4, 8} },
			[3] = { originalMinecraftTexture.shulker_purple, {4, 4}, {32, 48}, {16, 4}, {0, 12} } } );
		transformedMinecraftTexture.shulker_purple_side_back = TransformMultipleTextureToFile ( { -- back
			[1] = { originalMinecraftTexture.shulker_purple, {4, 4}, {48, 16}, {16, 12}, {0, 0} },
			[2] = { originalMinecraftTexture.shulker_purple, {4, 4}, {52, 44}, {8, 4}, {4, 8} },
			[3] = { originalMinecraftTexture.shulker_purple, {4, 4}, {48, 48}, {16, 4}, {0, 12} } } );
		transformedMinecraftTexture.shulker_purple_bottom = TransformSingleTextureToFile ( originalMinecraftTexture.shulker_purple, {4, 4}, {32, 28}, {16, 16}, {0, 0} ); -- bottom
	
	-- ID 230, Blue Shulker Box
		originalMinecraftTexture.shulker_blue = LoadTextureFromFile( "assets/minecraft/textures/entity/shulker/", "shulker_blue.png", 64, 64 ); -- load texture
		
		-- Save Textures
		transformedMinecraftTexture.shulker_blue_top = TransformSingleTextureToFile ( originalMinecraftTexture.shulker_blue, {4, 4}, {16, 0}, {16, 16}, {0, 0} ); -- top
		transformedMinecraftTexture.shulker_blue_side_left = TransformMultipleTextureToFile ( { -- left
			[1] = { originalMinecraftTexture.shulker_blue, {4, 4}, {0, 16}, {16, 12}, {0, 0} },
			[2] = { originalMinecraftTexture.shulker_blue, {4, 4}, {4, 44}, {8, 4}, {4, 8} },
			[3] = { originalMinecraftTexture.shulker_blue, {4, 4}, {0, 48}, {16, 4}, {0, 12} } } );
		transformedMinecraftTexture.shulker_blue_side_front = TransformMultipleTextureToFile ( { -- front
			[1] = { originalMinecraftTexture.shulker_blue, {4, 4}, {16, 16}, {16, 12}, {0, 0} },
			[2] = { originalMinecraftTexture.shulker_blue, {4, 4}, {20, 44}, {8, 4}, {4, 8} },
			[3] = { originalMinecraftTexture.shulker_blue, {4, 4}, {16, 48}, {16, 4}, {0, 12} } } );
		transformedMinecraftTexture.shulker_blue_side_right = TransformMultipleTextureToFile ( { -- right
			[1] = { originalMinecraftTexture.shulker_blue, {4, 4}, {32, 16}, {16, 12}, {0, 0} },
			[2] = { originalMinecraftTexture.shulker_blue, {4, 4}, {36, 44}, {8, 4}, {4, 8} },
			[3] = { originalMinecraftTexture.shulker_blue, {4, 4}, {32, 48}, {16, 4}, {0, 12} } } );
		transformedMinecraftTexture.shulker_blue_side_back = TransformMultipleTextureToFile ( { -- back
			[1] = { originalMinecraftTexture.shulker_blue, {4, 4}, {48, 16}, {16, 12}, {0, 0} },
			[2] = { originalMinecraftTexture.shulker_blue, {4, 4}, {52, 44}, {8, 4}, {4, 8} },
			[3] = { originalMinecraftTexture.shulker_blue, {4, 4}, {48, 48}, {16, 4}, {0, 12} } } );
		transformedMinecraftTexture.shulker_blue_bottom = TransformSingleTextureToFile ( originalMinecraftTexture.shulker_blue, {4, 4}, {32, 28}, {16, 16}, {0, 0} ); -- bottom
	
	-- ID 231, Brown Shulker Box
		originalMinecraftTexture.shulker_brown = LoadTextureFromFile( "assets/minecraft/textures/entity/shulker/", "shulker_brown.png", 64, 64 ); -- load texture
		
		-- Save Textures
		transformedMinecraftTexture.shulker_brown_top = TransformSingleTextureToFile ( originalMinecraftTexture.shulker_brown, {4, 4}, {16, 0}, {16, 16}, {0, 0} ); -- top
		transformedMinecraftTexture.shulker_brown_side_left = TransformMultipleTextureToFile ( { -- left
			[1] = { originalMinecraftTexture.shulker_brown, {4, 4}, {0, 16}, {16, 12}, {0, 0} },
			[2] = { originalMinecraftTexture.shulker_brown, {4, 4}, {4, 44}, {8, 4}, {4, 8} },
			[3] = { originalMinecraftTexture.shulker_brown, {4, 4}, {0, 48}, {16, 4}, {0, 12} } } );
		transformedMinecraftTexture.shulker_brown_side_front = TransformMultipleTextureToFile ( { -- front
			[1] = { originalMinecraftTexture.shulker_brown, {4, 4}, {16, 16}, {16, 12}, {0, 0} },
			[2] = { originalMinecraftTexture.shulker_brown, {4, 4}, {20, 44}, {8, 4}, {4, 8} },
			[3] = { originalMinecraftTexture.shulker_brown, {4, 4}, {16, 48}, {16, 4}, {0, 12} } } );
		transformedMinecraftTexture.shulker_brown_side_right = TransformMultipleTextureToFile ( { -- right
			[1] = { originalMinecraftTexture.shulker_brown, {4, 4}, {32, 16}, {16, 12}, {0, 0} },
			[2] = { originalMinecraftTexture.shulker_brown, {4, 4}, {36, 44}, {8, 4}, {4, 8} },
			[3] = { originalMinecraftTexture.shulker_brown, {4, 4}, {32, 48}, {16, 4}, {0, 12} } } );
		transformedMinecraftTexture.shulker_brown_side_back = TransformMultipleTextureToFile ( { -- back
			[1] = { originalMinecraftTexture.shulker_brown, {4, 4}, {48, 16}, {16, 12}, {0, 0} },
			[2] = { originalMinecraftTexture.shulker_brown, {4, 4}, {52, 44}, {8, 4}, {4, 8} },
			[3] = { originalMinecraftTexture.shulker_brown, {4, 4}, {48, 48}, {16, 4}, {0, 12} } } );
		transformedMinecraftTexture.shulker_brown_bottom = TransformSingleTextureToFile ( originalMinecraftTexture.shulker_brown, {4, 4}, {32, 28}, {16, 16}, {0, 0} ); -- bottom
	
	-- ID 232, Green Shulker Box
		originalMinecraftTexture.shulker_green = LoadTextureFromFile( "assets/minecraft/textures/entity/shulker/", "shulker_green.png", 64, 64 ); -- load texture
		
		-- Save Textures
		transformedMinecraftTexture.shulker_green_top = TransformSingleTextureToFile ( originalMinecraftTexture.shulker_green, {4, 4}, {16, 0}, {16, 16}, {0, 0} ); -- top
		transformedMinecraftTexture.shulker_green_side_left = TransformMultipleTextureToFile ( { -- left
			[1] = { originalMinecraftTexture.shulker_green, {4, 4}, {0, 16}, {16, 12}, {0, 0} },
			[2] = { originalMinecraftTexture.shulker_green, {4, 4}, {4, 44}, {8, 4}, {4, 8} },
			[3] = { originalMinecraftTexture.shulker_green, {4, 4}, {0, 48}, {16, 4}, {0, 12} } } );
		transformedMinecraftTexture.shulker_green_side_front = TransformMultipleTextureToFile ( { -- front
			[1] = { originalMinecraftTexture.shulker_green, {4, 4}, {16, 16}, {16, 12}, {0, 0} },
			[2] = { originalMinecraftTexture.shulker_green, {4, 4}, {20, 44}, {8, 4}, {4, 8} },
			[3] = { originalMinecraftTexture.shulker_green, {4, 4}, {16, 48}, {16, 4}, {0, 12} } } );
		transformedMinecraftTexture.shulker_green_side_right = TransformMultipleTextureToFile ( { -- right
			[1] = { originalMinecraftTexture.shulker_green, {4, 4}, {32, 16}, {16, 12}, {0, 0} },
			[2] = { originalMinecraftTexture.shulker_green, {4, 4}, {36, 44}, {8, 4}, {4, 8} },
			[3] = { originalMinecraftTexture.shulker_green, {4, 4}, {32, 48}, {16, 4}, {0, 12} } } );
		transformedMinecraftTexture.shulker_green_side_back = TransformMultipleTextureToFile ( { -- back
			[1] = { originalMinecraftTexture.shulker_green, {4, 4}, {48, 16}, {16, 12}, {0, 0} },
			[2] = { originalMinecraftTexture.shulker_green, {4, 4}, {52, 44}, {8, 4}, {4, 8} },
			[3] = { originalMinecraftTexture.shulker_green, {4, 4}, {48, 48}, {16, 4}, {0, 12} } } );
		transformedMinecraftTexture.shulker_green_bottom = TransformSingleTextureToFile ( originalMinecraftTexture.shulker_green, {4, 4}, {32, 28}, {16, 16}, {0, 0} ); -- bottom
	
	-- ID 233, Red Shulker Box
		originalMinecraftTexture.shulker_red = LoadTextureFromFile( "assets/minecraft/textures/entity/shulker/", "shulker_red.png", 64, 64 ); -- load texture
		
		-- Save Textures
		transformedMinecraftTexture.shulker_red_top = TransformSingleTextureToFile ( originalMinecraftTexture.shulker_red, {4, 4}, {16, 0}, {16, 16}, {0, 0} ); -- top
		transformedMinecraftTexture.shulker_red_side_left = TransformMultipleTextureToFile ( { -- left
			[1] = { originalMinecraftTexture.shulker_red, {4, 4}, {0, 16}, {16, 12}, {0, 0} },
			[2] = { originalMinecraftTexture.shulker_red, {4, 4}, {4, 44}, {8, 4}, {4, 8} },
			[3] = { originalMinecraftTexture.shulker_red, {4, 4}, {0, 48}, {16, 4}, {0, 12} } } );
		transformedMinecraftTexture.shulker_red_side_front = TransformMultipleTextureToFile ( { -- front
			[1] = { originalMinecraftTexture.shulker_red, {4, 4}, {16, 16}, {16, 12}, {0, 0} },
			[2] = { originalMinecraftTexture.shulker_red, {4, 4}, {20, 44}, {8, 4}, {4, 8} },
			[3] = { originalMinecraftTexture.shulker_red, {4, 4}, {16, 48}, {16, 4}, {0, 12} } } );
		transformedMinecraftTexture.shulker_red_side_right = TransformMultipleTextureToFile ( { -- right
			[1] = { originalMinecraftTexture.shulker_red, {4, 4}, {32, 16}, {16, 12}, {0, 0} },
			[2] = { originalMinecraftTexture.shulker_red, {4, 4}, {36, 44}, {8, 4}, {4, 8} },
			[3] = { originalMinecraftTexture.shulker_red, {4, 4}, {32, 48}, {16, 4}, {0, 12} } } );
		transformedMinecraftTexture.shulker_red_side_back = TransformMultipleTextureToFile ( { -- back
			[1] = { originalMinecraftTexture.shulker_red, {4, 4}, {48, 16}, {16, 12}, {0, 0} },
			[2] = { originalMinecraftTexture.shulker_red, {4, 4}, {52, 44}, {8, 4}, {4, 8} },
			[3] = { originalMinecraftTexture.shulker_red, {4, 4}, {48, 48}, {16, 4}, {0, 12} } } );
		transformedMinecraftTexture.shulker_red_bottom = TransformSingleTextureToFile ( originalMinecraftTexture.shulker_red, {4, 4}, {32, 28}, {16, 16}, {0, 0} ); -- bottom
	
	-- ID 234, Black Shulker Box
		originalMinecraftTexture.shulker_black = LoadTextureFromFile( "assets/minecraft/textures/entity/shulker/", "shulker_black.png", 64, 64 ); -- load texture
		
		-- Save Textures
		transformedMinecraftTexture.shulker_black_top = TransformSingleTextureToFile ( originalMinecraftTexture.shulker_black, {4, 4}, {16, 0}, {16, 16}, {0, 0} ); -- top
		transformedMinecraftTexture.shulker_black_side_left = TransformMultipleTextureToFile ( { -- left
			[1] = { originalMinecraftTexture.shulker_black, {4, 4}, {0, 16}, {16, 12}, {0, 0} },
			[2] = { originalMinecraftTexture.shulker_black, {4, 4}, {4, 44}, {8, 4}, {4, 8} },
			[3] = { originalMinecraftTexture.shulker_black, {4, 4}, {0, 48}, {16, 4}, {0, 12} } } );
		transformedMinecraftTexture.shulker_black_side_front = TransformMultipleTextureToFile ( { -- front
			[1] = { originalMinecraftTexture.shulker_black, {4, 4}, {16, 16}, {16, 12}, {0, 0} },
			[2] = { originalMinecraftTexture.shulker_black, {4, 4}, {20, 44}, {8, 4}, {4, 8} },
			[3] = { originalMinecraftTexture.shulker_black, {4, 4}, {16, 48}, {16, 4}, {0, 12} } } );
		transformedMinecraftTexture.shulker_black_side_right = TransformMultipleTextureToFile ( { -- right
			[1] = { originalMinecraftTexture.shulker_black, {4, 4}, {32, 16}, {16, 12}, {0, 0} },
			[2] = { originalMinecraftTexture.shulker_black, {4, 4}, {36, 44}, {8, 4}, {4, 8} },
			[3] = { originalMinecraftTexture.shulker_black, {4, 4}, {32, 48}, {16, 4}, {0, 12} } } );
		transformedMinecraftTexture.shulker_black_side_back = TransformMultipleTextureToFile ( { -- back
			[1] = { originalMinecraftTexture.shulker_black, {4, 4}, {48, 16}, {16, 12}, {0, 0} },
			[2] = { originalMinecraftTexture.shulker_black, {4, 4}, {52, 44}, {8, 4}, {4, 8} },
			[3] = { originalMinecraftTexture.shulker_black, {4, 4}, {48, 48}, {16, 4}, {0, 12} } } );
		transformedMinecraftTexture.shulker_black_bottom = TransformSingleTextureToFile ( originalMinecraftTexture.shulker_black, {4, 4}, {32, 28}, {16, 16}, {0, 0} ); -- bottom
	
	-- TODO: NEW TYPE, Regular Shulker Box
		originalMinecraftTexture.shulker_regular = LoadTextureFromFile( "assets/minecraft/textures/entity/shulker/", "shulker.png", 64, 64 ); -- load texture
		
		-- Save Textures
		transformedMinecraftTexture.shulker_regular_top = TransformSingleTextureToFile ( originalMinecraftTexture.shulker_regular, {4, 4}, {16, 0}, {16, 16}, {0, 0} ); -- top
		transformedMinecraftTexture.shulker_regular_side_left = TransformMultipleTextureToFile ( { -- left
			[1] = { originalMinecraftTexture.shulker_regular, {4, 4}, {0, 16}, {16, 12}, {0, 0} },
			[2] = { originalMinecraftTexture.shulker_regular, {4, 4}, {4, 44}, {8, 4}, {4, 8} },
			[3] = { originalMinecraftTexture.shulker_regular, {4, 4}, {0, 48}, {16, 4}, {0, 12} } } );
		transformedMinecraftTexture.shulker_regular_side_front = TransformMultipleTextureToFile ( { -- front
			[1] = { originalMinecraftTexture.shulker_regular, {4, 4}, {16, 16}, {16, 12}, {0, 0} },
			[2] = { originalMinecraftTexture.shulker_regular, {4, 4}, {20, 44}, {8, 4}, {4, 8} },
			[3] = { originalMinecraftTexture.shulker_regular, {4, 4}, {16, 48}, {16, 4}, {0, 12} } } );
		transformedMinecraftTexture.shulker_regular_side_right = TransformMultipleTextureToFile ( { -- right
			[1] = { originalMinecraftTexture.shulker_regular, {4, 4}, {32, 16}, {16, 12}, {0, 0} },
			[2] = { originalMinecraftTexture.shulker_regular, {4, 4}, {36, 44}, {8, 4}, {4, 8} },
			[3] = { originalMinecraftTexture.shulker_regular, {4, 4}, {32, 48}, {16, 4}, {0, 12} } } );
		transformedMinecraftTexture.shulker_regular_side_back = TransformMultipleTextureToFile ( { -- back
			[1] = { originalMinecraftTexture.shulker_regular, {4, 4}, {48, 16}, {16, 12}, {0, 0} },
			[2] = { originalMinecraftTexture.shulker_regular, {4, 4}, {52, 44}, {8, 4}, {4, 8} },
			[3] = { originalMinecraftTexture.shulker_regular, {4, 4}, {48, 48}, {16, 4}, {0, 12} } } );
		transformedMinecraftTexture.shulker_regular_bottom = TransformSingleTextureToFile ( originalMinecraftTexture.shulker_regular, {4, 4}, {32, 28}, {16, 16}, {0, 0} ); -- bottom
	
	-- Clear table originalMinecraftTexture
	for name, _ in pairs( originalMinecraftTexture ) do
		originalMinecraftTexture[name]:destroy();
	end
	
	return transformedMinecraftTexture;
end

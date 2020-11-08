
-- This module provides only a single function responsible for loading
-- the biome channels and setting up Eihort for biome rendering


require "assets"

function loadBiomeTextures( blocks, worldRoot )
	-- Find the biome textures
	local grassBiomeImage = loadTexture( "assets/minecraft/textures/colormap/grass.png", 256, 256 );
	local foliageBiomeImage	= loadTexture( "assets/minecraft/textures/colormap/foliage.png", 256, 256 );

	if not grassBiomeImage and not foliageBiomeImage then
		blocks:setBiomeRoot( "" );
	end

	-- Set up the biome channels
	blocks:setBiomeRoot( worldRoot .. "biomes/" );
	blocks:setBiomeDefaultPos( 56/255, 142/255 );
	if grassBiomeImage then
		blocks:setBiomeChannel( 0, false, grassBiomeImage );
	else
		blocks:setBiomeChannel( 0, 0x38/255, 0xa7/255, 0x88/255 );
	end
	if foliageBiomeImage then
		blocks:setBiomeChannel( 1, false, foliageBiomeImage );
		blocks:setBiomeChannel( 2, true, foliageBiomeImage );
	else
		blocks:setBiomeChannel( 1, 0x37/255, 0x9e/255, 0x7f/255 );
		blocks:setBiomeChannel( 2, 0x4c/255, 0x81/255, 0x67/255 );
	end
end

function getBiomeCoordData()
	-- translates the 8-bit biome IDs to coordinates in the 16x16
	 -- biome color table
	return {
		-- info: 0x7F7Fu mid-green, 0xBF7Fu light-blue, 1fff mc-savanna
		[  0] = 0xBF7F; -- Ocean
		[  1] = 0xAD32; -- Plains
		[  2] = 0xff00; -- Desert
		[  3] = 0xEFCB; -- Extreme Hills
		[  4] = 0x704C; -- Forest
		[  5] = 0xEFCB; -- Taiga
		[  6] = 0x1AAF; -- Swampland
		[  7] = 0xBF7F; -- River
		[  8] = 0xff00; -- Hell
		[  9] = 0xBF7F; -- The End
		[ 10] = 0xFFFF; -- Frozen Ocean
		[ 11] = 0xFFFF; -- Frozen River
		[ 12] = 0xFFFF; -- Ice Plains
		[ 13] = 0xFFFF; -- Ice Mountains
		[ 14] = 0x1919; -- Mushroom Island
		[ 15] = 0x1919; -- Mushroom Island Shore
		[ 16] = 0xAD32; -- Beach
		[ 17] = 0xff00; -- Desert Hills
		[ 18] = 0x704C; -- Forest Hills
		[ 19] = 0xEFCB; -- Taiga Hills
		[ 20] = 0xEFCB; -- Extreme Hills Edge
		[ 21] = 0x1900; -- Jungle
		[ 22] = 0x1900; -- Jungle Hills
		[ 23] = 0x1900; -- Jungle Edge
		[ 24] = 0xBF7F; -- Deep Ocean
		[ 25] = 0xAAAA; -- Stone Beach
		[ 26] = 0xEFCB; -- Cold Beach
		[ 27] = 0xBF7F; -- Birch Forest
		[ 28] = 0xBF7F; -- Birch Forest Hills
		[ 29] = 0x1AAF; -- Roofed Forest
		[ 30] = 0xEFCB; -- Cold Taiga
		[ 31] = 0xEFCB; -- Cold Taiga Hills
		[ 32] = 0xEFCB; -- Mega Taiga
		[ 33] = 0xEFCB; -- Mega Taiga Hills
		[ 34] = 0xEFCB; -- Extreme Hills+
		[ 35] = 0xff00; -- Savanna
		[ 36] = 0xff00; -- Savanna Plateau
		[ 37] = 0xff00; -- Mesa
		[ 38] = 0xff00; -- Mesa Plateau F
		[ 39] = 0xff00; -- Mesa Plateau
		[ 40] = 0xAD32; -- NA
		[ 41] = 0xAD32; -- NA
		[ 42] = 0xAD32; -- NA
		[ 43] = 0xAD32; -- NA
		[ 44] = 0xAD32; -- NA
		[ 45] = 0xAD32; -- NA
		[ 46] = 0xAD32; -- NA
		[ 47] = 0xAD32; -- NA
		[ 48] = 0xAD32; -- NA
		[ 49] = 0xAD32; -- NA
		[ 50] = 0xAD32; -- NA
		[ 51] = 0xAD32; -- NA
		[ 52] = 0xAD32; -- NA
		[ 53] = 0xAD32; -- NA
		[ 54] = 0xAD32; -- NA
		[ 55] = 0xAD32; -- NA
		[ 56] = 0xAD32; -- NA
		[ 57] = 0xAD32; -- NA
		[ 58] = 0xAD32; -- NA
		[ 59] = 0xAD32; -- NA
		[ 60] = 0xAD32; -- NA
		[ 61] = 0xAD32; -- NA
		[ 62] = 0xAD32; -- NA
		[ 63] = 0xAD32; -- NA
		[ 64] = 0xAD32; -- NA
		[ 65] = 0xAD32; -- NA
		[ 66] = 0xAD32; -- NA
		[ 67] = 0xAD32; -- NA
		[ 68] = 0xAD32; -- NA
		[ 69] = 0xAD32; -- NA
		[ 70] = 0xAD32; -- NA
		[ 71] = 0xAD32; -- NA
		[ 72] = 0xAD32; -- NA
		[ 73] = 0xAD32; -- NA
		[ 74] = 0xAD32; -- NA
		[ 75] = 0xAD32; -- NA
		[ 76] = 0xAD32; -- NA
		[ 77] = 0xAD32; -- NA
		[ 78] = 0xAD32; -- NA
		[ 79] = 0xAD32; -- NA
		[ 80] = 0xAD32; -- NA
		[ 81] = 0xAD32; -- NA
		[ 82] = 0xAD32; -- NA
		[ 83] = 0xAD32; -- NA
		[ 84] = 0xAD32; -- NA
		[ 85] = 0xAD32; -- NA
		[ 86] = 0xAD32; -- NA
		[ 87] = 0xAD32; -- NA
		[ 88] = 0xAD32; -- NA
		[ 89] = 0xAD32; -- NA
		[ 90] = 0xAD32; -- NA
		[ 91] = 0xAD32; -- NA
		[ 92] = 0xAD32; -- NA
		[ 93] = 0xAD32; -- NA
		[ 94] = 0xAD32; -- NA
		[ 95] = 0xAD32; -- NA
		[ 96] = 0xAD32; -- NA
		[ 97] = 0xAD32; -- NA
		[ 98] = 0xAD32; -- NA
		[ 99] = 0xAD32; -- NA
		[100] = 0xAD32; -- NA
		[101] = 0xAD32; -- NA
		[102] = 0xAD32; -- NA
		[103] = 0xAD32; -- NA
		[104] = 0xAD32; -- NA
		[105] = 0xAD32; -- NA
		[106] = 0xAD32; -- NA
		[107] = 0xAD32; -- NA
		[108] = 0xAD32; -- NA
		[109] = 0xAD32; -- NA
		[110] = 0xAD32; -- NA
		[111] = 0xAD32; -- NA
		[112] = 0xAD32; -- NA
		[113] = 0xAD32; -- NA
		[114] = 0xAD32; -- NA
		[115] = 0xAD32; -- NA
		[116] = 0xAD32; -- NA
		[117] = 0xAD32; -- NA
		[118] = 0xAD32; -- NA
		[119] = 0xAD32; -- NA
		[120] = 0xAD32; -- NA
		[121] = 0xAD32; -- NA
		[122] = 0xAD32; -- NA
		[123] = 0xAD32; -- NA
		[124] = 0xAD32; -- NA
		[125] = 0xAD32; -- NA
		[126] = 0xAD32; -- NA
		[127] = 0xAD32; -- The Void
		[128] = 0xAD32; -- Plains M
		[129] = 0xAD32; -- Sunflower Plains
		[130] = 0xff00; -- Desert M
		[131] = 0xEFCB; -- Extreme Hills M
		[132] = 0x704C; -- Flower Forest
		[133] = 0xEFCB; -- Taiga M
		[134] = 0x1AAF; -- Swampland M
		[135] = 0xAD32; -- NA
		[136] = 0xAD32; -- NA
		[137] = 0xAD32; -- NA
		[138] = 0xAD32; -- NA
		[139] = 0xAD32; -- NA
		[140] = 0xFFFF; -- Ice Plains Spikes
		[141] = 0xAD32; -- NA
		[142] = 0xAD32; -- NA
		[143] = 0xAD32; -- NA
		[144] = 0xAD32; -- NA
		[145] = 0xAD32; -- NA
		[146] = 0xAD32; -- NA
		[147] = 0xAD32; -- NA
		[148] = 0xAD32; -- NA
		[149] = 0x1900; -- Jungle M
		[150] = 0xAD32; -- NA
		[151] = 0x1900; -- Jungle Edge M
		[152] = 0xAD32; -- NA
		[153] = 0xAD32; -- NA
		[154] = 0xAD32; -- NA
		[155] = 0x704C; -- Birch Forest M
		[156] = 0x704C; -- Birch Forest Hills M
		[157] = 0x1AAF; -- Roofed Forest M
		[158] = 0xEFCB; -- Cold Taiga M
		[159] = 0xAD32; -- NA
		[160] = 0xEFCB; -- Mega Spruce Taiga
		[161] = 0xEFCB; -- Redwood Taiga Hills M
		[162] = 0xEFCB; -- Extreme Hills+ M
		[163] = 0xff00; -- Savanna M
		[164] = 0xff00; -- Savanna Plateau M
		[165] = 0xff00; -- Mesa (Bryce)
		[166] = 0xff00; -- Mesa Plateau F M
		[167] = 0xff00; -- Mesa Plateau M
	};
end

-- TODO: generate the above table indices from these data

BiomeColours = {
	-- { ID, temperature, rain, "biome" }
	{   0,  0.5, 0.5, "Ocean" };
	{   1,  0.8, 0.4, "Plains" };
	{   2,  2.0, 0.0, "Desert" };
	{   3,  0.2, 0.3, "Extreme Hills " };
	{   4,  0.7, 0.8, "Forest" };
	{   5, 0.25, 0.8, "Taiga" };
	{   6,  0.8, 0.9, "Swampland" };
	{   7,  0.5, 0.5, "River" };
	{   8,  666, 0.0, "Hell" }; -- recheck temperature
	{   9,  0.5, 0.5, "The End " };
	{  10,  0.0, 0.5, "FrozenOcean" };
	{  11,  0.0, 0.5, "FrozenRiver" };
	{  12,  0.0, 0.5, "Ice Plains" };
	{  13,  0.0, 0.5, "Ice Mountains" };
	{  14,  0.9, 1.0, "MushroomIsland" };
	{  15,  0.9, 1.0, "MushroomIslandShore" };
	{  16,  0.8, 0.4, "Beach" };
	{  17,  2.0, 0.0, "DesertHills" };
	{  18,  0.7, 0.8, "ForestHills" };
	{  19, 0.25, 0.7, "TaigaHills" };
	{  20,  0.2, 0.3, "Extreme Hills Edge" };
	{  21, 0.95, 0.9, "Jungle" };
	{  22, 0.95, 0.9, "JungleHills" };
	{  23, 0.95, 0.8, "JungleEdge" };
	{  24,  0.5, 0.5, "Deep Ocean" };
	{  25,  0.2, 0.3, "Stone Beach" };
	{  26, 0.05, 0.3, "Cold Beach" };
	{  27,  0.6, 0.6, "Birch Forest" };
	{  28,  0.6, 0.6, "Birch Forest Hills" };
	{  29,  0.7, 0.8, "Roofed Forest" };
	{  30, -0.5, 0.4, "Cold Taiga" };
	{  31, -0.5, 0.4, "Cold Taiga Hills" };
	{  32,  0.3, 0.8, "Mega Taiga" };
	{  33,  0.3, 0.8, "Mega Taiga Hills" };
	{  34,  0.2, 0.3, "Extreme Hills+" };
	{  35,  1.2, 0.0, "Savanna" };
	{  36,  1.2, 0.0, "Savanna Plateau" };
	{  37,  2.0, 0.0, "Mesa" };
	{  38,  2.0, 0.0, "Mesa Plateau F" };
	{  39,  2.0, 0.0, "Mesa Plateau" };
	{ 127,  0.8, 0.4, "The Void" }; -- recheck temperature
	{ 128,  0.8, 0.4, "Plains M" };
	{ 129,  0.8, 0.4, "Sunflower Plains" };
	{ 130,  2.0, 0.0, "Desert M" };
	{ 131,  0.2, 0.3, "Extreme Hills M" };
	{ 132,  0.7, 0.8, "Flower Forest" };
	{ 133, 0.25, 0.8, "Taiga M" };
	{ 134,  0.8, 0.9, "Swampland M" };
	{ 140,  0.0, 0.5, "Ice Plains Spikes" };
	{ 149, 0.95, 0.9, "Jungle M" };
	{ 151, 0.95, 0.8, "JungleEdge M" };
	{ 155,  0.6, 0.6, "Birch Forest M" };
	{ 156,  0.6, 0.6, "Birch Forest Hills M" };
	{ 157,  0.7, 0.8, "Roofed Forest M" };
	{ 158, -0.5, 0.4, "Cold Taiga M" };
	{ 160, 0.25, 0.8, "Mega Spruce Taiga" };
	{ 161, 0.25, 0.8, "Redwood Taiga Hills M" }; -- recheck temperature
	{ 162,  0.2, 0.3, "Extreme Hills+ M" };
	{ 163,  1.2, 0.0, "Savanna M" };
	{ 164,  1.2, 0.0, "Savanna Plateau M" };
	{ 165,  2.0, 0.0, "Mesa (Bryce)" };
	{ 166,  2.0, 0.0, "Mesa Plateau F M" };
	{ 167,  2.0, 0.0, "Mesa Plateau M" };
}



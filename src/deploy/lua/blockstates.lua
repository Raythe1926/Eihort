
-- Block names and states -> Geometry description for Eihort 0.4.2+

MinecraftBlocks = {
	-- ["<block name>"] = <geometry>;

	-- >> A << --
	["minecraft:acacia_bark"] = OpaqueBlock( BTEX("acacia_log") ); -- Acacia Bark
	["minecraft:acacia_leaves"] = BiomeHollowOpaqueBlock( 1, BTEX("acacia_leaves") ); -- Acacia Leaves
	["minecraft:acacia_log"] = StateAdapter( "axis", -- Acacia Log
		["x"] = OpaqueBlock( BTEX("acacia_log_top"), BTEX("acacia_log_top", 'rotate_180'), BTEX("acacia_log", 'rotate_90'), BTEX("acacia_log", 'rotate_270'), BTEX("acacia_log", 'rotate_270'), BTEX("acacia_log", 'rotate_270') ), -- west-east
		["y"] = OpaqueBlock( BTEX("acacia_log"), BTEX("acacia_log_top") ), -- top-bottom
		["z"] = OpaqueBlock( BTEX("acacia_log", 'rotate_90'), BTEX("acacia_log", 'rotate_270'), BTEX("acacia_log_top", 'rotate_180'), BTEX("acacia_log_top"), BTEX("acacia_log", 'rotate_180'), BTEX("acacia_log") ) ); -- north-south
	["minecraft:acacia_planks"] = OpaqueBlock( BTEX("acacia_planks") ); -- Acacia Planks
	["minecraft:acacia_pressure_plate"] = CompactedBlock( -1, -1, -1, -1, 0, -15, BTEX("acacia_planks") ); -- Acacia Pressure Plate
	["minecraft:acacia_sapling"] = OpaqueBlock( BTEX("acacia_sapling") ); -- Acacia Sapling
	["minecraft:acacia_slab"] =  StateAdapter( "type", -- Acacia Slab
		["bottom"] = Slab( -8, 0, BTEX("acacia_planks") ), -- bottom slab
		["top"] = Slab( 0, -8, BTEX("acacia_planks") ), -- top slab
		["double"] = OpaqueBlock( BTEX("acacia_planks") ) ); -- double slab
	-- ["minecraft:air"] (not visible)
	["minecraft:allium"] = XShapedBlock( BTEX("allium") ); -- Allium
	["minecraft:andesite"] = OpaqueBlock( BTEX("andesite") ); -- Andasite
	["minecraft:azure_bluet"] = XShapedBlock( BTEX("azure_bluet") ); -- Azure Bluet

	-- >> B << --
	["minecraft:bedrock"] = OpaqueBlock( BTEX("bedrock") ); -- Bedrock
	["minecraft:beetroots"] = StateAdapter( "age", -- Beetroots
		[0] = HashShapedBlock( -4, BTEX("beetroots_stage0"), 0 ), -- growthstate 0
		[1] = HashShapedBlock( -4, BTEX("beetroots_stage1"), 0 ), -- growthstate 1
		[2] = HashShapedBlock( -4, BTEX("beetroots_stage2"), 0 ), -- growthstate 2
		[3] = HashShapedBlock( -4, BTEX("beetroots_stage3"), 0 ) ); -- growthstate 3
	["minecraft:birch_bark"] = OpaqueBlock( BTEX("birch_log") ); -- Birch Bark
	["minecraft:birch_leaves"] = BiomeHollowOpaqueBlock( 1, BTEX("birch_leaves") ); -- Birch Leaves
	["minecraft:birch_log"] = StateAdapter( "axis", -- Birch Log
		["x"] = OpaqueBlock( BTEX("birch_log_top"), BTEX("birch_log_top", 'rotate_180'), BTEX("birch_log", 'rotate_90'), BTEX("birch_log", 'rotate_270'), BTEX("birch_log", 'rotate_270'), BTEX("birch_log", 'rotate_270') ), -- west-east
		["y"] = OpaqueBlock( BTEX("birch_log"), BTEX("birch_log_top") ), -- top-bottom
		["z"] = OpaqueBlock( BTEX("birch_log", 'rotate_90'), BTEX("birch_log", 'rotate_270'), BTEX("birch_log_top", 'rotate_180'), BTEX("birch_log_top"), BTEX("birch_log", 'rotate_180'), BTEX("birch_log") ) ); -- north-south
	["minecraft:birch_planks"] = OpaqueBlock( BTEX("birch_planks") ); -- Birch Planks
	["minecraft:birch_pressure_plate"] = CompactedBlock( -1, -1, -1, -1, 0, -15, BTEX("birch_planks") ); -- Birch Pressure Plate
	["minecraft:birch_sapling"] = OpaqueBlock( BTEX("birch_sapling") ); -- Birch Sapling
	["minecraft:birch_slab"] =  StateAdapter( "type", -- Birch Slab
		["bottom"] = Slab( -8, 0, BTEX("birch_planks") ), -- bottom slab
		["top"] = Slab( 0, -8, BTEX("birch_planks") ), -- top slab
		["double"] = OpaqueBlock( BTEX("birch_planks") ) ); -- double slab
	["minecraft:black_carpet"] = CompactedBlock( 0, 0, 0, 0, 0, -15, BTEX("black_wool") ); -- Black Carpet
	["minecraft:black_concrete"] = OpaqueBlock( BTEX("black_concrete") ) ); -- Black Concrete
	["minecraft:black_concrete_powder"] = OpaqueBlock( BTEX("black_concrete_powder") ); -- Black Concrete Powder
	["minecraft:black_glazed_terracotta"] = StateAdapter( "facing", -- Black Glazed Terracotta
		["north"] = OpaqueBlock( BTEX("black_glazed_terracotta", 'rotate_180'), BTEX("black_glazed_terracotta"), BTEX("black_glazed_terracotta", 'rotate_90'), BTEX("black_glazed_terracotta", 'rotate_270'), BTEX("black_glazed_terracotta", 'rotate_180'), BTEX("black_glazed_terracotta", 'rotate_180') ), -- facing north
		["east"]  = OpaqueBlock( BTEX("black_glazed_terracotta", 'rotate_270'), BTEX("black_glazed_terracotta", 'rotate_90'), BTEX("black_glazed_terracotta", 'rotate_180'), BTEX("black_glazed_terracotta"), BTEX("black_glazed_terracotta", 'rotate_270'), BTEX("black_glazed_terracotta", 'rotate_90') ), -- facing east
		["south"] = OpaqueBlock( BTEX("black_glazed_terracotta"), BTEX("black_glazed_terracotta", 'rotate_180'), BTEX("black_glazed_terracotta", 'rotate_270'), BTEX("black_glazed_terracotta", 'rotate_90'), BTEX("black_glazed_terracotta"), BTEX("black_glazed_terracotta") ), -- facing south
		["west"]  = OpaqueBlock( BTEX("black_glazed_terracotta", 'rotate_90'), BTEX("black_glazed_terracotta", 'rotate_270'), BTEX("black_glazed_terracotta"), BTEX("black_glazed_terracotta", 'rotate_180'), BTEX("black_glazed_terracotta", 'rotate_90'), BTEX("black_glazed_terracotta", 'rotate_270') ) ); -- facing west
	["minecraft:black_shulker_box"] = StateAdapter( "facing", -- Black Shulker Box
		["north"] = OpaqueBlock( BTEX("shulker_black_side_right", 'rotate_90'), BTEX("shulker_black_side_left", 'rotate_270'), BTEX("shulker_black_top"), BTEX("shulker_black_bottom", 'flip_x'), BTEX("shulker_black_side_front", 'rotate_180'), BTEX("shulker_black_side_back") ), -- facing north
		["east"]  = OpaqueBlock( BTEX("shulker_black_bottom", 'flip_x'), BTEX("shulker_black_top"), BTEX("shulker_black_side_right", 'rotate_90'), BTEX("shulker_black_side_left", 'rotate_270'), BTEX("shulker_black_side_front", 'rotate_270'), BTEX("shulker_black_side_back", 'rotate_270') ), -- facing east
		["south"] = OpaqueBlock( BTEX("shulker_black_side_left", 'rotate_270'), BTEX("shulker_black_side_right", 'rotate_90'), BTEX("shulker_black_bottom", 'flip_x'), BTEX("shulker_black_top"), BTEX("shulker_black_side_front"), BTEX("shulker_black_side_back", 'rotate_180') ), -- facing south
		["west"]  = OpaqueBlock( BTEX("shulker_black_top"), BTEX("shulker_black_bottom", 'flip_x'), BTEX("shulker_black_side_left", 'rotate_270'), BTEX("shulker_black_side_right", 'rotate_90'), BTEX("shulker_black_side_front", 'rotate_90'), BTEX("shulker_black_side_back", 'rotate_90') ), -- facing west
		["up"]    = OpaqueBlock( BTEX("shulker_black_side_left"), BTEX("shulker_black_side_right"), BTEX("shulker_black_side_back"), BTEX("shulker_black_side_front"), BTEX("shulker_black_bottom", 'flip_y'), BTEX("shulker_black_top") ), -- facing up
		["down"]  = OpaqueBlock( BTEX("shulker_black_side_left", 'rotate_180'), BTEX("shulker_black_side_right", 'rotate_180'), BTEX("shulker_black_side_front", 'rotate_180'), BTEX("shulker_black_side_back", 'rotate_180'), BTEX("shulker_black_top"), BTEX("shulker_black_bottom", 'flip_y') ) ); -- facing down
	["minecraft:black_wool"] = OpaqueBlock( BTEX("black_wool") ) ); -- Black Wool
	["minecraft:blue_carpet"] = CompactedBlock( 0, 0, 0, 0, 0, -15, BTEX("blue_wool") ); -- Blue Carpet
	["minecraft:blue_concrete"] = OpaqueBlock( BTEX("blue_concrete") ); -- Blue Concrete
	["minecraft:blue_concrete_powder"] = OpaqueBlock( BTEX("blue_concrete_powder") ); -- Blue Concrete Powder
	["minecraft:blue_glazed_terracotta"] = StateAdapter( "facing", -- Blue Glazed Terracotta
		["north"] = OpaqueBlock( BTEX("blue_glazed_terracotta", 'rotate_180'), BTEX("blue_glazed_terracotta"), BTEX("blue_glazed_terracotta", 'rotate_90'), BTEX("blue_glazed_terracotta", 'rotate_270'), BTEX("blue_glazed_terracotta", 'rotate_180'), BTEX("blue_glazed_terracotta", 'rotate_180') ), -- facing north
		["east"]  = OpaqueBlock( BTEX("blue_glazed_terracotta", 'rotate_270'), BTEX("blue_glazed_terracotta", 'rotate_90'), BTEX("blue_glazed_terracotta", 'rotate_180'), BTEX("blue_glazed_terracotta"), BTEX("blue_glazed_terracotta", 'rotate_270'), BTEX("blue_glazed_terracotta", 'rotate_90') ), -- facing east
		["south"] = OpaqueBlock( BTEX("blue_glazed_terracotta"), BTEX("blue_glazed_terracotta", 'rotate_180'), BTEX("blue_glazed_terracotta", 'rotate_270'), BTEX("blue_glazed_terracotta", 'rotate_90'), BTEX("blue_glazed_terracotta"), BTEX("blue_glazed_terracotta") ), -- facing south
		["west"]  = OpaqueBlock( BTEX("blue_glazed_terracotta", 'rotate_90'), BTEX("blue_glazed_terracotta", 'rotate_270'), BTEX("blue_glazed_terracotta"), BTEX("blue_glazed_terracotta", 'rotate_180'), BTEX("blue_glazed_terracotta", 'rotate_90'), BTEX("blue_glazed_terracotta", 'rotate_270') ) ); -- facing west
	["minecraft:blue_ice"] = OpaqueBlock( BTEX("blue_ice") ); -- Blue Ice
	["minecraft:blue_orchid"] = XShapedBlock( BTEX("blue_orchid") ); -- Blue Orchid
	["minecraft:blue_shulker_box"] = StateAdapter( "facing", -- Blue Shulker Box
		["north"] = OpaqueBlock( BTEX("shulker_blue_side_right", 'rotate_90'), BTEX("shulker_blue_side_left", 'rotate_270'), BTEX("shulker_blue_top"), BTEX("shulker_blue_bottom", 'flip_x'), BTEX("shulker_blue_side_front", 'rotate_180'), BTEX("shulker_blue_side_back") ), -- facing north
		["east"]  = OpaqueBlock( BTEX("shulker_blue_bottom", 'flip_x'), BTEX("shulker_blue_top"), BTEX("shulker_blue_side_right", 'rotate_90'), BTEX("shulker_blue_side_left", 'rotate_270'), BTEX("shulker_blue_side_front", 'rotate_270'), BTEX("shulker_blue_side_back", 'rotate_270') ), -- facing east
		["south"] = OpaqueBlock( BTEX("shulker_blue_side_left", 'rotate_270'), BTEX("shulker_blue_side_right", 'rotate_90'), BTEX("shulker_blue_bottom", 'flip_x'), BTEX("shulker_blue_top"), BTEX("shulker_blue_side_front"), BTEX("shulker_blue_side_back", 'rotate_180') ), -- facing south
		["west"]  = OpaqueBlock( BTEX("shulker_blue_top"), BTEX("shulker_blue_bottom", 'flip_x'), BTEX("shulker_blue_side_left", 'rotate_270'), BTEX("shulker_blue_side_right", 'rotate_90'), BTEX("shulker_blue_side_front", 'rotate_90'), BTEX("shulker_blue_side_back", 'rotate_90') ), -- facing west
		["up"]    = OpaqueBlock( BTEX("shulker_blue_side_left"), BTEX("shulker_blue_side_right"), BTEX("shulker_blue_side_back"), BTEX("shulker_blue_side_front"), BTEX("shulker_blue_bottom", 'flip_y'), BTEX("shulker_blue_top") ), -- facing up
		["down"]  = OpaqueBlock( BTEX("shulker_blue_side_left", 'rotate_180'), BTEX("shulker_blue_side_right", 'rotate_180'), BTEX("shulker_blue_side_front", 'rotate_180'), BTEX("shulker_blue_side_back", 'rotate_180'), BTEX("shulker_blue_top"), BTEX("shulker_blue_bottom", 'flip_y') ) ); -- facing down
	["minecraft:blue_wool"] = OpaqueBlock( BTEX("blue_wool") ); -- Blue Wool
	["minecraft:bookshelf"] = OpaqueBlock( BTEX("bookshelf"), BTEX("oak_planks") ); -- Bookshelf
	["minecraft:bone_block"] = StateAdapter( "axis", -- Bone Block
		["x"] = OpaqueBlock( BTEX("bone_block_top"), BTEX("bone_block_top", 'rotate_180'), BTEX("bone_block_side", 'rotate_90'), BTEX("bone_block_side", 'rotate_270'), BTEX("bone_block_side", 'rotate_270'), BTEX("bone_block_side", 'rotate_270') ), -- west-east
		["y"] = OpaqueBlock( BTEX("bone_block_side"), BTEX("bone_block_top") ), -- top-bottom
		["z"] = OpaqueBlock( BTEX("bone_block_side", 'rotate_90'), BTEX("bone_block_side", 'rotate_270'), BTEX("bone_block_top", 'rotate_180'), BTEX("bone_block_top"), BTEX("bone_block_side", 'rotate_180'), BTEX("bone_block_side") ) ); -- north-south
	["minecraft:brain_coral_block"] = OpaqueBlock( BTEX("brain_coral_block") ); -- Brain/Pink Coral Block
	["minecraft:brain_coral"] = XShapedBlock( BTEX("brain_coral") ); -- Brain/Pink Coral Plant
	["minecraft:dead_brain_coral_block"] = OpaqueBlock( BTEX("dead_brain_coral_block") ); -- Brain/Pink Dead Coral Block
	["minecraft:brick"] = OpaqueBlock( BTEX("brick") ); -- Brick
	["minecraft:brick_slab"] =  StateAdapter( "type", -- Brick Slab
		["bottom"] = Slab( -8, 0, BTEX("brick") ), -- bottom slab
		["top"] = Slab( 0, -8, BTEX("brick") ), -- top slab
		["double"] = OpaqueBlock( BTEX("brick") ) ); -- double slab
	["minecraft:brown_carpet"] = CompactedBlock( 0, 0, 0, 0, 0, -15, BTEX("brown_wool") ); -- Brown Carpet
	["minecraft:brown_concrete"] = OpaqueBlock( BTEX("brown_concrete") ); -- Brown Concrete
	["minecraft:brown_concrete_powder"] = OpaqueBlock( BTEX("brown_concrete_powder") ); -- Brown Concrete Powder
	["minecraft:brown_glazed_terracotta"] = StateAdapter( "facing", -- Brown Glazed Terracotta
		["north"] = OpaqueBlock( BTEX("brown_glazed_terracotta", 'rotate_180'), BTEX("brown_glazed_terracotta"), BTEX("brown_glazed_terracotta", 'rotate_90'), BTEX("brown_glazed_terracotta", 'rotate_270'), BTEX("brown_glazed_terracotta", 'rotate_180'), BTEX("brown_glazed_terracotta", 'rotate_180') ), -- facing north
		["east"]  = OpaqueBlock( BTEX("brown_glazed_terracotta", 'rotate_270'), BTEX("brown_glazed_terracotta", 'rotate_90'), BTEX("brown_glazed_terracotta", 'rotate_180'), BTEX("brown_glazed_terracotta"), BTEX("brown_glazed_terracotta", 'rotate_270'), BTEX("brown_glazed_terracotta", 'rotate_90') ), -- facing east
		["south"] = OpaqueBlock( BTEX("brown_glazed_terracotta"), BTEX("brown_glazed_terracotta", 'rotate_180'), BTEX("brown_glazed_terracotta", 'rotate_270'), BTEX("brown_glazed_terracotta", 'rotate_90'), BTEX("brown_glazed_terracotta"), BTEX("brown_glazed_terracotta") ), -- facing south
		["west"]  = OpaqueBlock( BTEX("brown_glazed_terracotta", 'rotate_90'), BTEX("brown_glazed_terracotta", 'rotate_270'), BTEX("brown_glazed_terracotta"), BTEX("brown_glazed_terracotta", 'rotate_180'), BTEX("brown_glazed_terracotta", 'rotate_90'), BTEX("brown_glazed_terracotta", 'rotate_270') ) ); -- facing west
	["minecraft:brown_mushroom"] = XShapedBlock( BTEX("brown_mushroom") ); -- Brown Mushroom
	["minecraft:brown_shulker_box"] = StateAdapter( "facing", -- Brown Shulker Box
		["north"] = OpaqueBlock( BTEX("shulker_brown_side_right", 'rotate_90'), BTEX("shulker_brown_side_left", 'rotate_270'), BTEX("shulker_brown_top"), BTEX("shulker_brown_bottom", 'flip_x'), BTEX("shulker_brown_side_front", 'rotate_180'), BTEX("shulker_brown_side_back") ), -- facing north
		["east"]  = OpaqueBlock( BTEX("shulker_brown_bottom", 'flip_x'), BTEX("shulker_brown_top"), BTEX("shulker_brown_side_right", 'rotate_90'), BTEX("shulker_brown_side_left", 'rotate_270'), BTEX("shulker_brown_side_front", 'rotate_270'), BTEX("shulker_brown_side_back", 'rotate_270') ), -- facing east
		["south"] = OpaqueBlock( BTEX("shulker_brown_side_left", 'rotate_270'), BTEX("shulker_brown_side_right", 'rotate_90'), BTEX("shulker_brown_bottom", 'flip_x'), BTEX("shulker_brown_top"), BTEX("shulker_brown_side_front"), BTEX("shulker_brown_side_back", 'rotate_180') ), -- facing south
		["west"]  = OpaqueBlock( BTEX("shulker_brown_top"), BTEX("shulker_brown_bottom", 'flip_x'), BTEX("shulker_brown_side_left", 'rotate_270'), BTEX("shulker_brown_side_right", 'rotate_90'), BTEX("shulker_brown_side_front", 'rotate_90'), BTEX("shulker_brown_side_back", 'rotate_90') ), -- facing west
		["up"]    = OpaqueBlock( BTEX("shulker_brown_side_left"), BTEX("shulker_brown_side_right"), BTEX("shulker_brown_side_back"), BTEX("shulker_brown_side_front"), BTEX("shulker_brown_bottom", 'flip_y'), BTEX("shulker_brown_top") ), -- facing up
		["down"]  = OpaqueBlock( BTEX("shulker_brown_side_left", 'rotate_180'), BTEX("shulker_brown_side_right", 'rotate_180'), BTEX("shulker_brown_side_front", 'rotate_180'), BTEX("shulker_brown_side_back", 'rotate_180'), BTEX("shulker_brown_top"), BTEX("shulker_brown_bottom", 'flip_y') ) ); -- facing down
	["minecraft:brown_wool"] = OpaqueBlock( BTEX("brown_wool") ); -- Brown Wool
	["minecraft:bubble_coral_block"] = OpaqueBlock( BTEX("bubble_coral_block") ); -- Bubble/Purple Coral Block
	["minecraft:bubble_coral"] = XShapedBlock( BTEX("bubble_coral") ); -- Bubble/Purple Coral Plant
	["minecraft:dead_bubble_coral_block"] = OpaqueBlock( BTEX("dead_bubble_coral_block") ); -- Bubble/Purple Dead Coral Block


	-- >> C << --
	["minecraft:cake"] = StateAdapter( "bites", -- Cake
		[0] = CompactedBlock( -1, -1, -1, -1, 0, -8, BTEX("cake_side"), BTEX("cake_bottom"), BTEX("cake_top") ), -- bites 0, full cake
		[1] = CompactedBlock( -3, -1, -1, -1, 0, -8, BTEX("cake_inner"), BTEX("cake_side"), BTEX("cake_side"), BTEX("cake_side"), BTEX("cake_bottom"), BTEX("cake_top") ), -- bites 1
		[2] = CompactedBlock( -5, -1, -1, -1, 0, -8, BTEX("cake_inner"), BTEX("cake_side"), BTEX("cake_side"), BTEX("cake_side"), BTEX("cake_bottom"), BTEX("cake_top") ), -- bites 2
		[3] = CompactedBlock( -7, -1, -1, -1, 0, -8, BTEX("cake_inner"), BTEX("cake_side"), BTEX("cake_side"), BTEX("cake_side"), BTEX("cake_bottom"), BTEX("cake_top") ), -- bites 3
		[4] = CompactedBlock( -9, -1, -1, -1, 0, -8, BTEX("cake_inner"), BTEX("cake_side"), BTEX("cake_side"), BTEX("cake_side"), BTEX("cake_bottom"), BTEX("cake_top") ), -- bites 4
		[5] = CompactedBlock( -11, -1, -1, -1, 0, -8, BTEX("cake_inner"), BTEX("cake_side"), BTEX("cake_side"), BTEX("cake_side"), BTEX("cake_bottom"), BTEX("cake_top") ), -- bites 5
		[6] = CompactedBlock( -13, -1, -1, -1, 0, -8, BTEX("cake_inner"), BTEX("cake_side"), BTEX("cake_side"), BTEX("cake_side"), BTEX("cake_bottom"), BTEX("cake_top") ), 0 ); -- bites 6
	["minecraft:carrots"] = StateAdapter( "age", -- Carrots
		[0] = HashShapedBlock( -4, BTEX("carrots_stage0"), 0 ), -- growthstate 0
		[1] = HashShapedBlock( -4, BTEX("carrots_stage0"), 0 ), -- growthstate 1
		[2] = HashShapedBlock( -4, BTEX("carrots_stage1"), 0 ), -- growthstate 2
		[3] = HashShapedBlock( -4, BTEX("carrots_stage1"), 0 ), -- growthstate 3
		[4] = HashShapedBlock( -4, BTEX("carrots_stage2"), 0 ), -- growthstate 4
		[5] = HashShapedBlock( -4, BTEX("carrots_stage2"), 0 ), -- growthstate 5
		[6] = HashShapedBlock( -4, BTEX("carrots_stage2"), 0 ), -- growthstate 6
		[7] = HashShapedBlock( -4, BTEX("carrots_stage3"), 0 ) ); -- growthstate 7
	["minecraft:carved_pumpkin"] = StateAdapter( "facing", -- Carved Pumpkin
			["north"] = OpaqueBlock( BTEX("pumpkin_side"), BTEX("pumpkin_side"), BTEX("pumpkin_face"), BTEX("pumpkin_side"), BTEX("pumpkin_top"), BTEX("pumpkin_top") ), -- facing north
			["east"]  = OpaqueBlock( BTEX("pumpkin_side"), BTEX("pumpkin_face"), BTEX("pumpkin_side"), BTEX("pumpkin_side"), BTEX("pumpkin_top", 'rotate_90'), BTEX("pumpkin_top", 'rotate_270') ), -- facing east
			["south"] = OpaqueBlock( BTEX("pumpkin_side"), BTEX("pumpkin_side"), BTEX("pumpkin_side"), BTEX("pumpkin_face"), BTEX("pumpkin_top", 'rotate_180'), BTEX("pumpkin_top", 'rotate_180') ), -- facing south
			["west"]  = OpaqueBlock( BTEX("pumpkin_face"), BTEX("pumpkin_side"), BTEX("pumpkin_side"), BTEX("pumpkin_side"), BTEX("pumpkin_top", 'rotate_270'), BTEX("pumpkin_top", 'rotate_90') ) ); -- facing west
	-- ["minecraft:cave_air"] (not visible)
	["minecraft:chain_command_block"] = StateAdapter( "conditional", -- Chain Command Block
		["false"] = StateAdapter( "facing", -- unconditional
			["north"] = OpaqueBlock( BTEX("chain_command_block_side", 'rotate_90'), BTEX("chain_command_block_side", 'rotate_270'), BTEX("chain_command_block_front"), BTEX("chain_command_block_back"), BTEX("chain_command_block_side", 'rotate_180'), BTEX("chain_command_block_side") ), -- facing north
			["east"]  = OpaqueBlock( BTEX("chain_command_block_back"), BTEX("chain_command_block_front"), BTEX("chain_command_block_side", 'rotate_90'), BTEX("chain_command_block_side", 'rotate_270'), BTEX("chain_command_block_side", 'rotate_270'), BTEX("chain_command_block_side", 'rotate_270') ), -- facing east
			["south"] = OpaqueBlock( BTEX("chain_command_block_side", 'rotate_270'), BTEX("chain_command_block_side", 'rotate_90'), BTEX("chain_command_block_back"), BTEX("chain_command_block_front"), BTEX("chain_command_block_side"), BTEX("chain_command_block_side", 'rotate_180') ), -- facing south
			["west"]  = OpaqueBlock( BTEX("chain_command_block_front"), BTEX("chain_command_block_back"), BTEX("chain_command_block_side", 'rotate_270'), BTEX("chain_command_block_side", 'rotate_90'), BTEX("chain_command_block_side", 'rotate_90'), BTEX("chain_command_block_side", 'rotate_90') ), -- facing west
			["up"]    = OpaqueBlock( BTEX("chain_command_block_side"), BTEX("chain_command_block_back"), BTEX("chain_command_block_front", 'rotate_180') ), -- facing up
			["down"]  = OpaqueBlock( BTEX("chain_command_block_side", 'rotate_180'), BTEX("chain_command_block_front", 'rotate_180'), BTEX("chain_command_block_back") ) ), -- facing down
		["true"] = StateAdapter( "facing", -- conditional
			["north"] = OpaqueBlock( BTEX("chain_command_block_conditional", 'rotate_90'), BTEX("chain_command_block_conditional", 'rotate_270'), BTEX("chain_command_block_front"), BTEX("chain_command_block_back"), BTEX("chain_command_block_conditional", 'rotate_180'), BTEX("chain_command_block_conditional") ), -- facing north
			["east"]  = OpaqueBlock( BTEX("chain_command_block_back"), BTEX("chain_command_block_frnt"), BTEX("chain_command_block_conditional", 'rotate_90'), BTEX("chain_command_block_conditional", 'rotate_270'), BTEX("chain_command_block_conditional", 'rotate_270'), BTEX("chain_command_block_conditional", 'rotate_270') ), -- facing east
			["south"] = OpaqueBlock( BTEX("chain_command_block_conditional", 'rotate_270'), BTEX("chain_command_block_conditional", 'rotate_90'), BTEX("chain_command_block_back"), BTEX("chain_command_block_front"), BTEX("chain_command_block_conditional"), BTEX("chain_command_block_conditional", 'rotate_180') ), -- facing south
			["west"]  = OpaqueBlock( BTEX("chain_command_block_front"), BTEX("chain_command_block_back"), BTEX("chain_command_block_conditional", 'rotate_270'), BTEX("chain_command_block_conditional", 'rotate_90'), BTEX("chain_command_block_conditional", 'rotate_90'), BTEX("chain_command_block_conditional", 'rotate_90') ), -- facing west
			["up"]    = OpaqueBlock( BTEX("chain_command_block_conditional"), BTEX("chain_command_block_back"), BTEX("chain_command_block_front", 'rotate_180') ), -- facing up
			["down"]  = OpaqueBlock( BTEX("chain_command_block_conditional", 'rotate_180'), BTEX("chain_command_block_front", 'rotate_180'), BTEX("chain_command_block_back") ) ) ); -- facing down
	["minecraft:chiseled_red_sandstone"] = OpaqueBlock( BTEX("chiseled_red_sandstone"), BTEX("red_sandstone_top"), BTEX("red_sandstone_top") ); -- Chiseled Red Sandstone
	["minecraft:chiseled_sandstone"] = OpaqueBlock( BTEX("chiseled_sandstone"), BTEX("sandstone_top"), BTEX("sandstone_top") ); -- Chiseled Sandstone
	["minecraft:chiseled_stone_bricks"] = OpaqueBlock( BTEX("chiseled_stone_bricks") ); -- Chisled Stone Brick
	["minecraft:chiseled_quartz_block"] = OpaqueBlock( BTEX("quartz_block_chiseled"), BTEX("quartz_block_chiseled_top") ); -- Chiseled Quartz Block
	["minecraft:clay"] = OpaqueBlock( BTEX("clay") ); -- Clay
	["minecraft:coal_block"] = OpaqueBlock( BTEX("coal_block") ); -- Coal Block
	["minecraft:coal_ore"] = OpaqueBlock( BTEX("coal_ore") ); -- Coal Ore
	["minecraft:coarse_dirt"] = OpaqueBlock( BTEX("coarse_dirt") ); -- Coarse Dirt
	["minecraft:cobblestone"] = OpaqueBlock( BTEX("cobblestone") ); -- Cobblestone
	["minecraft:cobblestone_slab"] =  StateAdapter( "type", -- Cobblestone Slab
		["bottom"] = Slab( -8, 0, BTEX("cobblestone") ), -- bottom slab
		["top"] = Slab( 0, -8, BTEX("cobblestone") ), -- top slab
		["double"] = OpaqueBlock( BTEX("cobblestone") ) ); -- double slab
	["minecraft:cobweb"] = XShapedBlock( BTEX("cobweb") ); -- Cobweb
	["minecraft:command_block"] = StateAdapter( "conditional", -- Command Block
		["false"] = StateAdapter( "facing", -- unconditional
			["north"] = OpaqueBlock( BTEX("command_block_side", 'rotate_90'), BTEX("command_block_side", 'rotate_270'), BTEX("command_block_front"), BTEX("command_block_back"), BTEX("command_block_side", 'rotate_180'), BTEX("command_block_side") ), -- facing north
			["east"]  = OpaqueBlock( BTEX("command_block_back"), BTEX("command_block_front"), BTEX("command_block_side", 'rotate_90'), BTEX("command_block_side", 'rotate_270'), BTEX("command_block_side", 'rotate_270'), BTEX("command_block_side", 'rotate_270') ), -- facing east
			["south"] = OpaqueBlock( BTEX("command_block_side", 'rotate_270'), BTEX("command_block_side", 'rotate_90'), BTEX("command_block_back"), BTEX("command_block_front"), BTEX("command_block_side"), BTEX("command_block_side", 'rotate_180') ), -- facing south
			["west"]  = OpaqueBlock( BTEX("command_block_front"), BTEX("command_block_back"), BTEX("command_block_side", 'rotate_270'), BTEX("command_block_side", 'rotate_90'), BTEX("command_block_side", 'rotate_90'), BTEX("command_block_side", 'rotate_90') ), -- facing west
			["up"]    = OpaqueBlock( BTEX("command_block_side"), BTEX("command_block_back"), BTEX("command_block_front", 'rotate_180') ), -- facing up
			["down"]  = OpaqueBlock( BTEX("command_block_side", 'rotate_180'), BTEX("command_block_front", 'rotate_180'), BTEX("command_block_back") ) ), -- facing down
		["true"] = StateAdapter( "facing", -- conditional
			["north"] = OpaqueBlock( BTEX("command_block_conditional", 'rotate_90'), BTEX("command_block_conditional", 'rotate_270'), BTEX("command_block_front"), BTEX("command_block_back"), BTEX("command_block_conditional", 'rotate_180'), BTEX("command_block_conditional") ), -- facing north
			["east"]  = OpaqueBlock( BTEX("command_block_back"), BTEX("command_block_front"), BTEX("command_block_conditional", 'rotate_90'), BTEX("command_block_conditional", 'rotate_270'), BTEX("command_block_conditional", 'rotate_270'), BTEX("command_block_conditional", 'rotate_270') ), -- facing east
			["south"] = OpaqueBlock( BTEX("command_block_conditional", 'rotate_270'), BTEX("command_block_conditional", 'rotate_90'), BTEX("command_block_back"), BTEX("command_block_front"), BTEX("command_block_conditional"), BTEX("command_block_conditional", 'rotate_180') ), -- facing south
			["west"]  = OpaqueBlock( BTEX("command_block_front"), BTEX("command_block_back"), BTEX("command_block_conditional", 'rotate_270'), BTEX("command_block_conditional", 'rotate_90'), BTEX("command_block_conditional", 'rotate_90'), BTEX("command_block_conditional", 'rotate_90') ), -- facing west
			["up"]    = OpaqueBlock( BTEX("command_block_conditional"), BTEX("command_block_back"), BTEX("command_block_front", 'rotate_180') ), -- facing up
			["down"]  = OpaqueBlock( BTEX("command_block_conditional", 'rotate_180'), BTEX("command_block_front", 'rotate_180'), BTEX("command_block_back") ) ) ); -- facing down
	["minecraft:cracked_stone_bricks"] = OpaqueBlock( BTEX("cracked_stone_bricks") ); -- Cracked Stone Brick
	["minecraft:crafting_table"] = OpaqueBlock( BTEX("crafting_table_front"), BTEX("crafting_table_side"), BTEX("oak_planks"), BTEX("crafting_table_top") ); -- Crafting Table
	["minecraft:cut_red_sandstone"] = OpaqueBlock( BTEX("cut_red_sandstone"), BTEX("red_sandstone_top"), BTEX("red_sandstone_top") ); -- Cut Red Sandstone
	["minecraft:cut_sandstone"] = OpaqueBlock( BTEX("cut_sandstone"), BTEX("sandstone_top"), BTEX("sandstone_top") ); -- Cut Sandstone
	["minecraft:cyan_carpet"] = CompactedBlock( 0, 0, 0, 0, 0, -15, BTEX("cyan_wool") ); -- Cyan Carpet
	["minecraft:cyan_concrete"] = OpaqueBlock( BTEX("cyan_concrete") ); -- Cyan Concrete
	["minecraft:cyan_concrete_powder"] = OpaqueBlock( BTEX("cyan_concrete_powder") ); -- Cyan Concrete Powder
	["minecraft:cyan_glazed_terracotta"] = StateAdapter( "facing", -- Cyan Glazed Terracotta
		["north"] = OpaqueBlock( BTEX("cyan_glazed_terracotta", 'rotate_180'), BTEX("cyan_glazed_terracotta"), BTEX("cyan_glazed_terracotta", 'rotate_90'), BTEX("cyan_glazed_terracotta", 'rotate_270'), BTEX("cyan_glazed_terracotta", 'rotate_180'), BTEX("cyan_glazed_terracotta", 'rotate_180') ), -- facing north
		["east"]  = OpaqueBlock( BTEX("cyan_glazed_terracotta", 'rotate_270'), BTEX("cyan_glazed_terracotta", 'rotate_90'), BTEX("cyan_glazed_terracotta", 'rotate_180'), BTEX("cyan_glazed_terracotta"), BTEX("cyan_glazed_terracotta", 'rotate_270'), BTEX("cyan_glazed_terracotta", 'rotate_90') ), -- facing east
		["south"] = OpaqueBlock( BTEX("cyan_glazed_terracotta"), BTEX("cyan_glazed_terracotta", 'rotate_180'), BTEX("cyan_glazed_terracotta", 'rotate_270'), BTEX("cyan_glazed_terracotta", 'rotate_90'), BTEX("cyan_glazed_terracotta"), BTEX("cyan_glazed_terracotta") ), -- facing south
		["west"]  = OpaqueBlock( BTEX("cyan_glazed_terracotta", 'rotate_90'), BTEX("cyan_glazed_terracotta", 'rotate_270'), BTEX("cyan_glazed_terracotta"), BTEX("cyan_glazed_terracotta", 'rotate_180'), BTEX("cyan_glazed_terracotta", 'rotate_90'), BTEX("cyan_glazed_terracotta", 'rotate_270') ) ); -- facing west
	["minecraft:cyan_shulker_box"] = StateAdapter( "facing", -- Cyan Shulker Box
		["north"] = OpaqueBlock( BTEX("shulker_cyan_side_right", 'rotate_90'), BTEX("shulker_cyan_side_left", 'rotate_270'), BTEX("shulker_cyan_top"), BTEX("shulker_cyan_bottom", 'flip_x'), BTEX("shulker_cyan_side_front", 'rotate_180'), BTEX("shulker_cyan_side_back") ), -- facing north
		["east"]  = OpaqueBlock( BTEX("shulker_cyan_bottom", 'flip_x'), BTEX("shulker_cyan_top"), BTEX("shulker_cyan_side_right", 'rotate_90'), BTEX("shulker_cyan_side_left", 'rotate_270'), BTEX("shulker_cyan_side_front", 'rotate_270'), BTEX("shulker_cyan_side_back", 'rotate_270') ), -- facing east
		["south"] = OpaqueBlock( BTEX("shulker_cyan_side_left", 'rotate_270'), BTEX("shulker_cyan_side_right", 'rotate_90'), BTEX("shulker_cyan_bottom", 'flip_x'), BTEX("shulker_cyan_top"), BTEX("shulker_cyan_side_front"), BTEX("shulker_cyan_side_back", 'rotate_180') ), -- facing south
		["west"]  = OpaqueBlock( BTEX("shulker_cyan_top"), BTEX("shulker_cyan_bottom", 'flip_x'), BTEX("shulker_cyan_side_left", 'rotate_270'), BTEX("shulker_cyan_side_right", 'rotate_90'), BTEX("shulker_cyan_side_front", 'rotate_90'), BTEX("shulker_cyan_side_back", 'rotate_90') ), -- facing west
		["up"]    = OpaqueBlock( BTEX("shulker_cyan_side_left"), BTEX("shulker_cyan_side_right"), BTEX("shulker_cyan_side_back"), BTEX("shulker_cyan_side_front"), BTEX("shulker_cyan_bottom", 'flip_y'), BTEX("shulker_cyan_top") ), -- facing up
		["down"]  = OpaqueBlock( BTEX("shulker_cyan_side_left", 'rotate_180'), BTEX("shulker_cyan_side_right", 'rotate_180'), BTEX("shulker_cyan_side_front", 'rotate_180'), BTEX("shulker_cyan_side_back", 'rotate_180'), BTEX("shulker_cyan_top"), BTEX("shulker_cyan_bottom", 'flip_y') ) ); -- facing down
	["minecraft:cyan_wool"] = OpaqueBlock( BTEX("cyan_wool") ); -- Cyan Wool

	-- >> D << --
	["minecraft:dandelion"] = XShapedBlock( BTEX("dandelion") ); -- Dandelion
	["minecraft:dark_oak_bark"] = OpaqueBlock( BTEX("dark_oak_log") ); -- Dark Oak Bark
	["minecraft:dark_oak_leaves"] = BiomeHollowOpaqueBlock( 1, BTEX("dark_oak_leaves") ); -- Dark Oak Leaves
	["minecraft:dark_oak_log"] = StateAdapter( "axis", -- Dark Oak Log
		["x"] = OpaqueBlock( BTEX("dark_oak_log_top"), BTEX("dark_oak_log_top", 'rotate_180'), BTEX("dark_oak_log", 'rotate_90'), BTEX("dark_oak_log", 'rotate_270'), BTEX("dark_oak_log", 'rotate_270'), BTEX("dark_oak_log", 'rotate_270') ), -- west-east
		["y"] = OpaqueBlock( BTEX("dark_oak_log"), BTEX("dark_oak_log_top") ), -- top-bottom
		["z"] = OpaqueBlock( BTEX("dark_oak_log", 'rotate_90'), BTEX("dark_oak_log", 'rotate_270'), BTEX("dark_oak_log_top", 'rotate_180'), BTEX("dark_oak_log_top"), BTEX("dark_oak_log", 'rotate_180'), BTEX("dark_oak_log") ) ); -- north-south
	["minecraft:dark_oak_planks"] = OpaqueBlock( BTEX("dark_oak_planks") ); -- Dark Oak Planks
	["minecraft:dark_oak_pressure_plate"] = CompactedBlock( -1, -1, -1, -1, 0, -15, BTEX("dark_oak_planks") ); -- Dark Oak Pressure Plate
	["minecraft:dark_oak_sapling"] = OpaqueBlock( BTEX("dark_oak_sapling") ); -- Dark Oak Sapling
	["minecraft:dark_oak_slab"] =  StateAdapter( "type", -- Dark Oak Slab
		["bottom"] = Slab( -8, 0, BTEX("dark_oak_planks") ), -- bottom slab
		["top"] = Slab( 0, -8, BTEX("dark_oak_planks") ), -- top slab
		["double"] = OpaqueBlock( BTEX("dark_oak_planks") ) ); -- double slab
	["minecraft:dark_prismarine"] = OpaqueBlock( BTEX("dark_prismarine") ), -- Dark Prismarine
	["minecraft:dark_prismarine_slab"] =  StateAdapter( "type", -- Dark Prismarine Slab
		["bottom"] = Slab( -8, 0, BTEX("dark_prismarine") ), -- bottom slab
		["top"] = Slab( 0, -8, BTEX("dark_prismarine") ), -- top slab
		["double"] = OpaqueBlock( BTEX("dark_prismarine") ) ); -- double slab
	["minecraft:daylight_detector"] = StateAdapter( "snowy", -- Daylight Detector
		["false"] = CompactedBlock( 0, 0, 0, 0, 0, -10, BTEX("daylight_detector_side"), BTEX("daylight_detector_side"), BTEX("daylight_detector_top") ), -- regular daylight detector
		["true"]  = CompactedBlock( 0, 0, 0, 0, 0, -10, BTEX("daylight_detector_side"), BTEX("daylight_detector_side"), BTEX("daylight_detector_inverted_top") ) ); -- inverted daylight detector
	["minecraft:dead_bush"] = XShapedBlock( BTEX("dead_bush") ); -- Dead Bush
	["minecraft:diamond_block"] = OpaqueBlock( BTEX("diamond_block") ); -- Diamond Block
	["minecraft:diamond_ore"] = OpaqueBlock( BTEX("diamond_ore") ); -- Diamond Ore
	["minecraft:diorite"] = OpaqueBlock( BTEX("diorite") ); -- Diorite	
	["minecraft:dirt"] = OpaqueBlock( BTEX("dirt") ); -- Dirt
	["minecraft:dispenser"] = StateAdapter( "facing", -- Dispenser
		["north"] = OpaqueBlock( BTEX("furnace_side"), BTEX("furnace_side"), BTEX("dispenser_front"), BTEX("furnace_side"), BTEX("furnace_top"), BTEX("furnace_top") ), -- facing north
		["east"]  = OpaqueBlock( BTEX("furnace_side"), BTEX("dispenser_front"), BTEX("furnace_side"), BTEX("furnace_side"), BTEX("furnace_top", 'rotate_90'), BTEX("furnace_top", 'rotate_270') ), -- facing east
		["south"] = OpaqueBlock( BTEX("furnace_side"), BTEX("furnace_side"), BTEX("furnace_side"), BTEX("dispenser_front"), BTEX("furnace_top", 'rotate_180'), BTEX("furnace_top", 'rotate_180') ), -- facing south
		["west"]  = OpaqueBlock( BTEX("dispenser_front"), BTEX("furnace_side"), BTEX("furnace_side"), BTEX("furnace_side"), BTEX("furnace_top", 'rotate_270'), BTEX("furnace_top", 'rotate_90') ), -- facing west
		["up"]    = OpaqueBlock( BTEX("furnace_top"), BTEX("furnace_top"), BTEX("dispenser_front_vertical") ), -- facing up
		["down"]  = OpaqueBlock( BTEX("furnace_top", 'rotate_180'), BTEX("dispenser_front_vertical"), BTEX("furnace_top") ) ); -- facing down
	["minecraft:dragon_egg"] = MultiCompactedBlock( -- Dragon Egg
		{ -6, -6, -6, -6, -15,   0,
		  -5, -5, -5, -5, -14,  -1,
		  -4, -4, -4, -4, -13,  -2,
		  -3, -3, -3, -3, -11,  -3,
		  -2, -2, -2, -2,  -8,  -5,
		  -1, -1, -1, -1,  -3,  -8,
		  -3, -3, -3, -3,  -1, -13,
		  -6, -6, -6, -6,   0, -15}, -- egg
		BTEX("dragon_egg") );
	["minecraft:dropper"] = StateAdapter( "facing", -- Dropper
		["north"] = OpaqueBlock( BTEX("furnace_side"), BTEX("furnace_side"), BTEX("dropper_front"), BTEX("furnace_side"), BTEX("furnace_top"), BTEX("furnace_top") ), -- facing north
		["east"]  = OpaqueBlock( BTEX("furnace_side"), BTEX("dropper_front"), BTEX("furnace_side"), BTEX("furnace_side"), BTEX("furnace_top"), BTEX("furnace_top") ), -- facing east
		["south"] = OpaqueBlock( BTEX("furnace_side"), BTEX("furnace_side"), BTEX("furnace_side"), BTEX("dropper_front"), BTEX("furnace_top"), BTEX("furnace_top") ), -- facing south
		["west"]  = OpaqueBlock( BTEX("dropper_front"), BTEX("furnace_side"), BTEX("furnace_side"), BTEX("furnace_side"), BTEX("furnace_top"), BTEX("furnace_top") ), -- facing west
		["up"]    = OpaqueBlock( BTEX("furnace_top"), BTEX("furnace_top"), BTEX("dropper_front_vertical") ), -- facing up
		["down"]  = OpaqueBlock( BTEX("furnace_top"), BTEX("dropper_front_vertical"), BTEX("furnace_top") ) ); -- facing down

	-- >> E << --
	["minecraft:emerald_block"] = OpaqueBlock( BTEX("emerald_block") ); -- Emerald Block
	["minecraft:emerald_ore"] = OpaqueBlock( BTEX("emerald_ore") ); -- Emerald Ore
	["minecraft:end_portal_frame"] = StateAdapter( "eye", -- End Portal Frame
		["false"] = StateAdapter( "facing", -- without eye
			["north"] = CompactedBlock( 0, 0, 0, 0, 0, -3, BTEX("end_portal_frame_side"), BTEX("end_stone", 'rotate_180'), BTEX("end_portal_frame_top", 'rotate_180') ), -- facing north
			["east"]  = CompactedBlock( 0, 0, 0, 0, 0, -3, BTEX("end_portal_frame_side"), BTEX("end_stone", 'rotate_270'), BTEX("end_portal_frame_top", 'rotate_90') ), -- facing east
			["south"] = CompactedBlock( 0, 0, 0, 0, 0, -3, BTEX("end_portal_frame_side"), BTEX("end_stone"), BTEX("end_portal_frame_top") ), -- facing south
			["west"]  = CompactedBlock( 0, 0, 0, 0, 0, -3, BTEX("end_portal_frame_side"), BTEX("end_stone", 'rotate_90'), BTEX("end_portal_frame_top", 'rotate_270') ) ), -- facing west
		["true"] = StateAdapter( "facing", -- with eye
			["north"] = MultiCompactedBlock( -- facing north
				{  0,  0,  0,  0,   0, -3, -- frame
				  -4, -4, -4, -4, -13,  0 }, -- eye
				BTEX("endframe_side_eye"), BTEX("end_stone", 'rotate_180'), BTEX("endframe_top_eye", 'rotate_180') ), -- facing north
			["east"]  = MultiCompactedBlock( -- with eye, east
				{  0,  0,  0,  0,   0, -3, -- frame
				  -4, -4, -4, -4, -13,  0 }, -- eye
				BTEX("endframe_side_eye"), BTEX("end_stone", 'rotate_270'), BTEX("endframe_top_eye", 'rotate_90') ), -- facing east
			["south"] = MultiCompactedBlock( -- facing south
				{  0,  0,  0,  0,   0, -3, -- frame
				  -4, -4, -4, -4, -13,  0 }, -- eye
				BTEX("endframe_side_eye"), BTEX("end_stone"), BTEX("endframe_top_eye") ),
			["west"]  = MultiCompactedBlock( -- facing west
				{  0,  0,  0,  0,   0, -3, -- frame
				  -4, -4, -4, -4, -13,  0 }, -- eye
				BTEX("endframe_side_eye"), BTEX("end_stone", 'rotate_90'), BTEX("endframe_top_eye", 'rotate_270') ) ) );
	["minecraft:end_rod"] = StateAdapter( "facing", -- End Rod
		["north"] = MultiCompactedBlock( -- facing north
			{ -15,   0,  -6,  -6,  -6,  -6, -- base
				0,  -1,  -7,  -7,  -7,  -7 }, -- stand
			BTEX("end_rod_side", 'rotate_90'), BTEX("end_rod_side", 'rotate_270'), BTEX("end_rod_top", 'rotate_180'), BTEX("end_rod_bottom", 'rotate_180'), BTEX("end_rod_side", 'rotate_180'), BTEX("end_rod_side") ),
		["east"]  = MultiCompactedBlock( -- facing east
			{  -6,  -6,   0, -15,  -6,  -6, -- base
			   -7,  -7,  -1,   0,  -7,  -7 }, -- stand
			BTEX("end_rod_bottom", 'rotate_180'), BTEX("end_rod_top", 'rotate_180'), BTEX("end_rod_side", 'rotate_90'), BTEX("end_rod_side", 'rotate_270'), BTEX("end_rod_side", 'rotate_270'), BTEX("end_rod_side", 'rotate_270') ),
		["south"] = MultiCompactedBlock( -- facing south
			{   0, -15,  -6,  -6,  -6,  -6, -- base
			   -1,   0,  -7,  -7,  -7,  -7 }, -- stand
			BTEX("end_rod_side", 'rotate_270'), BTEX("end_rod_side", 'rotate_90'), BTEX("end_rod_bottom", 'rotate_180'), BTEX("end_rod_top", 'rotate_180'), BTEX("end_rod_side"), BTEX("end_rod_side", 'rotate_180') ),
		["west"]  = MultiCompactedBlock( -- facing west
			{  -6,  -6, -15,   0,  -6,  -6, -- base
			   -7,  -7,   0,  -1,  -7,  -7 }, -- stand
			BTEX("end_rod_top", 'rotate_180'), BTEX("end_rod_bottom", 'rotate_180'), BTEX("end_rod_side", 'rotate_270'), BTEX("end_rod_side", 'rotate_90'), BTEX("end_rod_side", 'rotate_90'), BTEX("end_rod_side", 'rotate_90') ),
		["up"]    = MultiCompactedBlock( -- facing up
			{  -6,  -6,  -6,  -6,   0, -15, -- base
			   -7,  -7,  -7,  -7,  -1,   0 }, -- stand
			BTEX("end_rod_side"), BTEX("end_rod_bottom", 'rotate_180'), BTEX("end_rod_top") ),
		["down"]  = MultiCompactedBlock( -- facing down
			{  -6,  -6,  -6,  -6, -15,   0, -- base
			   -7,  -7,  -7,  -7,   0,  -1 }, -- stand
			BTEX("end_rod_side", 'rotate_180'), BTEX("end_rod_top"), BTEX("end_rod_bottom", 'rotate_180') ) );
	["minecraft:end_stone"] = OpaqueBlock( BTEX("end_stone") ); -- End Stone
	["minecraft:end_stone_bricks"] = OpaqueBlock( BTEX("end_stone_bricks") ); -- End Stone Bricks

	-- >> F << --
	["minecraft:farmland"] = StateAdapter( "moisture", -- Farmland
		[0] = CompactedBlock( 0, 0, 0, 0, 0, -1, BTEX("dirt"), BTEX("dirt"), BTEX("farmland") ), -- not hydrated, moisture level 0
		[1] = CompactedBlock( 0, 0, 0, 0, 0, -1, BTEX("dirt"), BTEX("dirt"), BTEX("farmland") ), -- not hydrated, moisture level 1
		[2] = CompactedBlock( 0, 0, 0, 0, 0, -1, BTEX("dirt"), BTEX("dirt"), BTEX("farmland") ), -- not hydrated, moisture level 2
		[3] = CompactedBlock( 0, 0, 0, 0, 0, -1, BTEX("dirt"), BTEX("dirt"), BTEX("farmland") ), -- not hydrated, moisture level 3
		[4] = CompactedBlock( 0, 0, 0, 0, 0, -1, BTEX("dirt"), BTEX("dirt"), BTEX("farmland") ), -- not hydrated, moisture level 4
		[5] = CompactedBlock( 0, 0, 0, 0, 0, -1, BTEX("dirt"), BTEX("dirt"), BTEX("farmland") ), -- not hydrated, moisture level 5
		[6] = CompactedBlock( 0, 0, 0, 0, 0, -1, BTEX("dirt"), BTEX("dirt"), BTEX("farmland") ), -- not hydrated, moisture level 6
		[7] = CompactedBlock( 0, 0, 0, 0, 0, -1, BTEX("dirt"), BTEX("dirt"), BTEX("farmland_wet") ) ); -- hydrated, moisture level 7
	["minecraft:fern"] = BiomeXShapedBlock( 0, BTEX("fern") ), 0 ); -- Fern
	["minecraft:fire_coral_block"] = OpaqueBlock( BTEX("fire_coral_block") ); -- Fire/Red Coral Block
	["minecraft:fire_coral"] = XShapedBlock( BTEX("fire_coral") ); -- Fire/Red Coral Plant
	["minecraft:dead_fire_coral_block"] = OpaqueBlock( BTEX("dead_fire_coral_block") ); -- Fire/Red Dead Coral Block
	["minecraft:flowing_lava"] = BrightOpaqueBlock( BTEX( "lava_flow", 2 ), BTEX( "lava_still" ) ); -- Flowing Lava
	["minecraft:flowing_water"] = TransparentBlock( 2, BTEX( "water_still" ) ); -- Flowing Water
	["minecraft:frosted_ice"] = StateAdapter( "age", -- Frosted Ice
		[0] = DelayRender( TransparentBlock( 0, BTEX("frosted_ice_0") ), 5 ), -- age 0
		[1] = DelayRender( TransparentBlock( 0, BTEX("frosted_ice_1") ), 5 ), -- age 1
		[2] = DelayRender( TransparentBlock( 0, BTEX("frosted_ice_2") ), 5 ), -- age 2
		[3] = DelayRender( TransparentBlock( 0, BTEX("frosted_ice_3") ), 5 ) ); -- age 3
	["minecraft:furnace"] = StateAdapter( "lit", -- Furnace
		["false"] = StateAdapter( "facing", -- unlit furnace
			["north"] = OpaqueBlock( BTEX("furnace_side"), BTEX("furnace_side"), BTEX("furnace_front"), BTEX("furnace_side"), BTEX("furnace_top"), BTEX("furnace_top") ), -- facing north
			["east"]  = OpaqueBlock( BTEX("furnace_side"), BTEX("furnace_front"), BTEX("furnace_side"), BTEX("furnace_side"), BTEX("furnace_top", 'rotate_90'), BTEX("furnace_top", 'rotate_270') ), -- facing east
			["south"] = OpaqueBlock( BTEX("furnace_side"), BTEX("furnace_side"), BTEX("furnace_side"), BTEX("furnace_front"), BTEX("furnace_top", 'rotate_180'), BTEX("furnace_top", 'rotate_180') ), -- facing south
			["west"]  = OpaqueBlock( BTEX("furnace_front"), BTEX("furnace_side"), BTEX("furnace_side"), BTEX("furnace_side"), BTEX("furnace_top", 'rotate_270'), BTEX("furnace_top", 'rotate_90') ) ), -- facing west
		["true"] = StateAdapter( "facing", -- lit furnace
			["north"] = OpaqueBlock( BTEX("furnace_side"), BTEX("furnace_side"), BTEX("furnace_front_on"), BTEX("furnace_side"), BTEX("furnace_top"), BTEX("furnace_top") ), -- facing north
			["east"]  = OpaqueBlock( BTEX("furnace_side"), BTEX("furnace_front_on"), BTEX("furnace_side"), BTEX("furnace_side"), BTEX("furnace_top", 'rotate_90'), BTEX("furnace_top", 'rotate_270') ), -- facing east
			["south"] = OpaqueBlock( BTEX("furnace_side"), BTEX("furnace_side"), BTEX("furnace_side"), BTEX("furnace_front_on"), BTEX("furnace_top", 'rotate_180'), BTEX("furnace_top", 'rotate_180') ), -- facing south
			["west"]  = OpaqueBlock( BTEX("furnace_front_on"), BTEX("furnace_side"), BTEX("furnace_side"), BTEX("furnace_side"), BTEX("furnace_top", 'rotate_270'), BTEX("furnace_top", 'rotate_90') ) ) ); -- facing west

	-- >> G << --
	["minecraft:glass"] = HollowOpaqueBlock( BTEX("glass") ); -- Glass
	["minecraft:glowstone"] = OpaqueBlock( BTEX("glowstone") ); -- Glowstone Block
	["minecraft:gold_block"] = OpaqueBlock( BTEX("gold_block") ); -- Gold Block
	["minecraft:gold_ore"] = OpaqueBlock( BTEX("gold_ore") ); -- Gold Ore
	["minecraft:granite"] = OpaqueBlock( BTEX("stone_granite") ); -- Granite
	["minecraft:grass"] = BiomeXShapedBlock( 0, BTEX("grass") ); -- Grass
	["minecraft:grass_path"] = CompactedBlock( 0, 0, 0, 0, 0, -1, BTEX("grass_path_side"), BTEX("dirt"), BTEX("grass_path_top") ); -- Grass Path
	["minecraft:grass_block"] = StateAdapter( "snowy", -- Grass
		["false"] = BiomeAlphaOpaqueBlock( 0, BTEX_AlphaFromGray( "grass_block_side", "grass_block_side_overlay" ), BTEX_NoAlpha("dirt"), BTEX_InAlpha("grass_block_top") ), -- regular grass
		["true"]  = OpaqueBlock( BTEX("grass_block_snow"), BTEX("dirt"), BTEX("grass_block_top") ) ); -- snowy grass
	["minecraft:gravel"] = OpaqueBlock( BTEX("gravel") ); -- Gravel
	["minecraft:gray_carpet"] = CompactedBlock( 0, 0, 0, 0, 0, -15, BTEX("gray_wool") ); -- Grey Carpet
	["minecraft:gray_concrete"] = OpaqueBlock( BTEX("grey_concrete") ); -- Grey Concrete
	["minecraft:gray_concrete_powder"] = OpaqueBlock( BTEX("grey_concrete_powder") ); -- Grey Concrete Powder
	["minecraft:gray_glazed_terracotta"] = StateAdapter( "facing", -- Grey Glazed Terracotta
		["north"] = OpaqueBlock( BTEX("gray_glazed_terracotta", 'rotate_180'), BTEX("gray_glazed_terracotta"), BTEX("gray_glazed_terracotta", 'rotate_90'), BTEX("gray_glazed_terracotta", 'rotate_270'), BTEX("gray_glazed_terracotta", 'rotate_180'), BTEX("gray_glazed_terracotta", 'rotate_180') ), -- facing north
		["east"]  = OpaqueBlock( BTEX("gray_glazed_terracotta", 'rotate_270'), BTEX("gray_glazed_terracotta", 'rotate_90'), BTEX("gray_glazed_terracotta", 'rotate_180'), BTEX("gray_glazed_terracotta"), BTEX("gray_glazed_terracotta", 'rotate_270'), BTEX("gray_glazed_terracotta", 'rotate_90') ), -- facing east
		["south"] = OpaqueBlock( BTEX("gray_glazed_terracotta"), BTEX("gray_glazed_terracotta", 'rotate_180'), BTEX("gray_glazed_terracotta", 'rotate_270'), BTEX("gray_glazed_terracotta", 'rotate_90'), BTEX("gray_glazed_terracotta"), BTEX("gray_glazed_terracotta") ), -- facing south
		["west"]  = OpaqueBlock( BTEX("gray_glazed_terracotta", 'rotate_90'), BTEX("gray_glazed_terracotta", 'rotate_270'), BTEX("gray_glazed_terracotta"), BTEX("gray_glazed_terracotta", 'rotate_180'), BTEX("gray_glazed_terracotta", 'rotate_90'), BTEX("gray_glazed_terracotta", 'rotate_270') ) ); -- facing west
	["minecraft:gray_shulker_box"] = StateAdapter( "facing", -- Gray Shulker Box
		["north"] = OpaqueBlock( BTEX("shulker_gray_side_right", 'rotate_90'), BTEX("shulker_gray_side_left", 'rotate_270'), BTEX("shulker_gray_top"), BTEX("shulker_gray_bottom", 'flip_x'), BTEX("shulker_gray_side_front", 'rotate_180'), BTEX("shulker_gray_side_back") ), -- facing north
		["east"]  = OpaqueBlock( BTEX("shulker_gray_bottom", 'flip_x'), BTEX("shulker_gray_top"), BTEX("shulker_gray_side_right", 'rotate_90'), BTEX("shulker_gray_side_left", 'rotate_270'), BTEX("shulker_gray_side_front", 'rotate_270'), BTEX("shulker_gray_side_back", 'rotate_270') ), -- facing east
		["south"] = OpaqueBlock( BTEX("shulker_gray_side_left", 'rotate_270'), BTEX("shulker_gray_side_right", 'rotate_90'), BTEX("shulker_gray_bottom", 'flip_x'), BTEX("shulker_gray_top"), BTEX("shulker_gray_side_front"), BTEX("shulker_gray_side_back", 'rotate_180') ), -- facing south
		["west"]  = OpaqueBlock( BTEX("shulker_gray_top"), BTEX("shulker_gray_bottom", 'flip_x'), BTEX("shulker_gray_side_left", 'rotate_270'), BTEX("shulker_gray_side_right", 'rotate_90'), BTEX("shulker_gray_side_front", 'rotate_90'), BTEX("shulker_gray_side_back", 'rotate_90') ), -- facing west
		["up"]    = OpaqueBlock( BTEX("shulker_gray_side_left"), BTEX("shulker_gray_side_right"), BTEX("shulker_gray_side_back"), BTEX("shulker_gray_side_front"), BTEX("shulker_gray_bottom", 'flip_y'), BTEX("shulker_gray_top") ), -- facing up
		["down"]  = OpaqueBlock( BTEX("shulker_gray_side_left", 'rotate_180'), BTEX("shulker_gray_side_right", 'rotate_180'), BTEX("shulker_gray_side_front", 'rotate_180'), BTEX("shulker_gray_side_back", 'rotate_180'), BTEX("shulker_gray_top"), BTEX("shulker_gray_bottom", 'flip_y') ) ); -- facing down
	["minecraft:gray_wool"] = OpaqueBlock( BTEX("grey_wool") ); -- Grey Wool
	["minecraft:green_carpet"] = CompactedBlock( 0, 0, 0, 0, 0, -15, BTEX("green_wool") ); -- Green Carpet
	["minecraft:green_concrete"] = OpaqueBlock( BTEX("green_concrete") ); -- Green Concrete
	["minecraft:green_concrete_powder"] = OpaqueBlock( BTEX("green_concrete_powder") ); -- Green Concrete Powder
	["minecraft:green_glazed_terracotta"] = StateAdapter( "facing", -- Green Glazed Terracotta
		["north"] = OpaqueBlock( BTEX("green_glazed_terracotta", 'rotate_180'), BTEX("green_glazed_terracotta"), BTEX("green_glazed_terracotta", 'rotate_90'), BTEX("green_glazed_terracotta", 'rotate_270'), BTEX("green_glazed_terracotta", 'rotate_180'), BTEX("green_glazed_terracotta", 'rotate_180') ), -- facing north
		["east"]  = OpaqueBlock( BTEX("green_glazed_terracotta", 'rotate_270'), BTEX("green_glazed_terracotta", 'rotate_90'), BTEX("green_glazed_terracotta", 'rotate_180'), BTEX("green_glazed_terracotta"), BTEX("green_glazed_terracotta", 'rotate_270'), BTEX("green_glazed_terracotta", 'rotate_90') ), -- facing east
		["south"] = OpaqueBlock( BTEX("green_glazed_terracotta"), BTEX("green_glazed_terracotta", 'rotate_180'), BTEX("green_glazed_terracotta", 'rotate_270'), BTEX("green_glazed_terracotta", 'rotate_90'), BTEX("green_glazed_terracotta"), BTEX("green_glazed_terracotta") ), -- facing south
		["west"]  = OpaqueBlock( BTEX("green_glazed_terracotta", 'rotate_90'), BTEX("green_glazed_terracotta", 'rotate_270'), BTEX("green_glazed_terracotta"), BTEX("green_glazed_terracotta", 'rotate_180'), BTEX("green_glazed_terracotta", 'rotate_90'), BTEX("green_glazed_terracotta", 'rotate_270') ) ); -- facing west
	["minecraft:green_shulker_box"] = StateAdapter( "facing", -- Green Shulker Box
		["north"] = OpaqueBlock( BTEX("shulker_green_side_right", 'rotate_90'), BTEX("shulker_green_side_left", 'rotate_270'), BTEX("shulker_green_top"), BTEX("shulker_green_bottom", 'flip_x'), BTEX("shulker_green_side_front", 'rotate_180'), BTEX("shulker_green_side_back") ), -- facing north
		["east"]  = OpaqueBlock( BTEX("shulker_green_bottom", 'flip_x'), BTEX("shulker_green_top"), BTEX("shulker_green_side_right", 'rotate_90'), BTEX("shulker_green_side_left", 'rotate_270'), BTEX("shulker_green_side_front", 'rotate_270'), BTEX("shulker_green_side_back", 'rotate_270') ), -- facing east
		["south"] = OpaqueBlock( BTEX("shulker_green_side_left", 'rotate_270'), BTEX("shulker_green_side_right", 'rotate_90'), BTEX("shulker_green_bottom", 'flip_x'), BTEX("shulker_green_top"), BTEX("shulker_green_side_front"), BTEX("shulker_green_side_back", 'rotate_180') ), -- facing south
		["west"]  = OpaqueBlock( BTEX("shulker_green_top"), BTEX("shulker_green_bottom", 'flip_x'), BTEX("shulker_green_side_left", 'rotate_270'), BTEX("shulker_green_side_right", 'rotate_90'), BTEX("shulker_green_side_front", 'rotate_90'), BTEX("shulker_green_side_back", 'rotate_90') ), -- facing west
		["up"]    = OpaqueBlock( BTEX("shulker_green_side_left"), BTEX("shulker_green_side_right"), BTEX("shulker_green_side_back"), BTEX("shulker_green_side_front"), BTEX("shulker_green_bottom", 'flip_y'), BTEX("shulker_green_top") ), -- facing up
		["down"]  = OpaqueBlock( BTEX("shulker_green_side_left", 'rotate_180'), BTEX("shulker_green_side_right", 'rotate_180'), BTEX("shulker_green_side_front", 'rotate_180'), BTEX("shulker_green_side_back", 'rotate_180'), BTEX("shulker_green_top"), BTEX("shulker_green_bottom", 'flip_y') ) ); -- facing down
	["minecraft:green_wool"] = OpaqueBlock( BTEX("green_wool") ); -- Green Wool

	-- >> H << --
	["minecraft:heavy_weighted_pressure_plate"] = CompactedBlock( -1, -1, -1, -1, 0, -15, BTEX("iron_block") ); -- Heavy Weighted Pressure Plate
	["minecraft:hay_bale"] = StateAdapter( "axis", -- Hay Bale
		["x"] = OpaqueBlock( BTEX("hay_block_top"), BTEX("hay_block_top", 'rotate_180'), BTEX("hay_block_side", 'rotate_90'), BTEX("hay_block_side", 'rotate_270'), BTEX("hay_block_side", 'rotate_270'), BTEX("hay_block_side", 'rotate_270') ), -- west-east
		["y"] = OpaqueBlock( BTEX("hay_block_side"), BTEX("hay_block_top") ), -- top-bottom
		["z"] = OpaqueBlock( BTEX("hay_block_side", 'rotate_90'), BTEX("hay_block_side", 'rotate_270'), BTEX("hay_block_top", 'rotate_180'), BTEX("hay_block_top"), BTEX("hay_block_side", 'rotate_180'), BTEX("hay_block_side") ) ); -- north-south
	["minecraft:horn_coral_block"] = OpaqueBlock( BTEX("horn_coral_block") ); -- Horn/Yellow Coral Block
	["minecraft:horn_coral"] = XShapedBlock( BTEX("horn_coral") ); -- Horn/Yellow Coral Plant
	["minecraft:dead_horn_coral_block"] = OpaqueBlock( BTEX("dead_horn_coral_block") ); -- Horn/Yellow Dead Coral Block

	-- >> I << --
	["minecraft:infested_chiseled_stone_bricks"] = OpaqueBlock( BTEX("chiseled_stone_bricks") ), -- Infested Chiseled Stone Bricks
	["minecraft:infested_cobblestone"] = OpaqueBlock( BTEX("cobblestone") ), -- Infested Cobblestone
	["minecraft:infested_cracked_stone_bricks"] = OpaqueBlock( BTEX("cracked_stone_bricks") ), -- Infested Cracked Stone Bricks
	["minecraft:infested_mossy_stone_bricks"] = OpaqueBlock( BTEX("mossy_stone_bricks") ), -- Infested Mossy Stone Bricks
	["minecraft:infested_stone"] = OpaqueBlock( BTEX("stone") ), -- Infested Stone Bricks
	["minecraft:infested_stone_bricks"] = OpaqueBlock( BTEX("stone_bricks") ), -- Infested Stone
	["minecraft:iron_block"] = OpaqueBlock( BTEX("iron_block") ); -- Iron Block
	["minecraft:iron_ore"] = OpaqueBlock( BTEX("iron_ore") ); -- Iron Ore

	-- >> J << --
	["minecraft:jack_o_lantern"] = StateAdapter( "facing", -- Jack-O-Lantern
			["north"] = OpaqueBlock( BTEX("pumpkin_side"), BTEX("pumpkin_side"), BTEX("pumpkin_face_on"), BTEX("pumpkin_side"), BTEX("pumpkin_top"), BTEX("pumpkin_top") ), -- facing north
			["east"]  = OpaqueBlock( BTEX("pumpkin_side"), BTEX("pumpkin_face_on"), BTEX("pumpkin_side"), BTEX("pumpkin_side"), BTEX("pumpkin_top", 'rotate_90'), BTEX("pumpkin_top", 'rotate_270') ), -- facing east
			["south"] = OpaqueBlock( BTEX("pumpkin_side"), BTEX("pumpkin_side"), BTEX("pumpkin_side"), BTEX("pumpkin_face_on"), BTEX("pumpkin_top", 'rotate_180'), BTEX("pumpkin_top", 'rotate_180') ), -- facing south
			["west"]  = OpaqueBlock( BTEX("pumpkin_face_on"), BTEX("pumpkin_side"), BTEX("pumpkin_side"), BTEX("pumpkin_side"), BTEX("pumpkin_top", 'rotate_270'), BTEX("pumpkin_top", 'rotate_90') ) ); -- facing west
	["minecraft:jukebox"] = OpaqueBlock( BTEX("jukebox_side"), BTEX("jukebox_side"), BTEX("jukebox_top") ); -- Jukebox
	["minecraft:jungle_bark"] = OpaqueBlock( BTEX("jungle_log") ); -- Jungle Bark
	["minecraft:jungle_leaves"] = BiomeHollowOpaqueBlock( 1, BTEX("jungle_leaves") ); -- Jungle Leaves
	["minecraft:jungle_log"] = StateAdapter( "axis", -- Jungle Log
		["x"] = OpaqueBlock( BTEX("jungle_log_top"), BTEX("jungle_log_top", 'rotate_180'), BTEX("jungle_log", 'rotate_90'), BTEX("jungle_log", 'rotate_270'), BTEX("jungle_log", 'rotate_270'), BTEX("jungle_log", 'rotate_270') ), -- west-east
		["y"] = OpaqueBlock( BTEX("jungle_log"), BTEX("jungle_log_top") ), -- top-bottom
		["z"] = OpaqueBlock( BTEX("jungle_log", 'rotate_90'), BTEX("jungle_log", 'rotate_270'), BTEX("jungle_log_top", 'rotate_180'), BTEX("jungle_log_top"), BTEX("jungle_log", 'rotate_180'), BTEX("jungle_log") ) ); -- north-south
	["minecraft:jungle_planks"] = OpaqueBlock( BTEX("jungle_planks") ); -- Jungle Planks
	["minecraft:jungle_pressure_plate"] = CompactedBlock( -1, -1, -1, -1, 0, -15, BTEX("jungle_planks") ); -- Jungle Pressure Plate
	["minecraft:jungle_sapling"] = OpaqueBlock( BTEX("jungle_sapling") ); -- Jungle Sapling
	["minecraft:jungle_slab"] =  StateAdapter( "type", -- Jungle Slab
		["bottom"] = Slab( -8, 0, BTEX("jungle_planks") ), -- bottom slab
		["top"] = Slab( 0, -8, BTEX("jungle_planks") ), -- top slab
		["double"] = OpaqueBlock( BTEX("jungle_planks") ) ); -- double slab

	-- >> K << --
	["minecraft:kelp"] = XShapedBlock( BTEX("kelp_plant") ); -- Kelp
	["minecraft:kelp_top"] = XShapedBlock( BTEX("kelp_top") ); -- Kelp Top

	-- >> L << --
	["minecraft:lapis_block"] = OpaqueBlock( BTEX("lapis_block") ); -- Lapis Lazuli Block
	["minecraft:lapis_ore"] = OpaqueBlock( BTEX("lapis_ore") ); -- Lapis Lazuli Ore
	["minecraft:large_fern"] = StateAdapter( "half", -- Large Fern
		["upper"] = XShapedBlock( BTEX("large_fern_top") ), -- upper half
		["lower"] = XShapedBlock( BTEX("large_fern_bottom") ); -- lower half
	["minecraft:lava"] = BrightOpaqueBlock( BTEX( "lava_still" ) ); -- Still Lava
	["minecraft:light_blue_carpet"] = CompactedBlock( 0, 0, 0, 0, 0, -15, BTEX("light_blue_wool") ); -- Light Blue Carpet
	["minecraft:light_blue_concrete"] = OpaqueBlock( BTEX("light_blue_concrete") ); -- Light Blue Concrete
	["minecraft:light_blue_concrete_powder"] = OpaqueBlock( BTEX("light_blue_concrete_powder") ); -- Light Blue Concrete Powder
	["minecraft:light_blue_glazed_terracotta"] = StateAdapter( "facing", -- Light Blue Glazed Terracotta
		["north"] = OpaqueBlock( BTEX("light_blue_glazed_terracotta", 'rotate_180'), BTEX("light_blue_glazed_terracotta"), BTEX("light_blue_glazed_terracotta", 'rotate_90'), BTEX("light_blue_glazed_terracotta", 'rotate_270'), BTEX("light_blue_glazed_terracotta", 'rotate_180'), BTEX("light_blue_glazed_terracotta", 'rotate_180') ), -- facing north
		["east"]  = OpaqueBlock( BTEX("light_blue_glazed_terracotta", 'rotate_270'), BTEX("light_blue_glazed_terracotta", 'rotate_90'), BTEX("light_blue_glazed_terracotta", 'rotate_180'), BTEX("light_blue_glazed_terracotta"), BTEX("light_blue_glazed_terracotta", 'rotate_270'), BTEX("light_blue_glazed_terracotta", 'rotate_90') ), -- facing east
		["south"] = OpaqueBlock( BTEX("light_blue_glazed_terracotta"), BTEX("light_blue_glazed_terracotta", 'rotate_180'), BTEX("light_blue_glazed_terracotta", 'rotate_270'), BTEX("light_blue_glazed_terracotta", 'rotate_90'), BTEX("light_blue_glazed_terracotta"), BTEX("light_blue_glazed_terracotta") ), -- facing south
		["west"]  = OpaqueBlock( BTEX("light_blue_glazed_terracotta", 'rotate_90'), BTEX("light_blue_glazed_terracotta", 'rotate_270'), BTEX("light_blue_glazed_terracotta"), BTEX("light_blue_glazed_terracotta", 'rotate_180'), BTEX("light_blue_glazed_terracotta", 'rotate_90'), BTEX("light_blue_glazed_terracotta", 'rotate_270') ) ); -- facing west
	["minecraft:light_blue_shulker_box"] = StateAdapter( "facing", -- Light Blue Shulker Box
		["north"] = OpaqueBlock( BTEX("shulker_light_blue_side_right", 'rotate_90'), BTEX("shulker_light_blue_side_left", 'rotate_270'), BTEX("shulker_light_blue_top"), BTEX("shulker_light_blue_bottom", 'flip_x'), BTEX("shulker_light_blue_side_front", 'rotate_180'), BTEX("shulker_light_blue_side_back") ), -- facing north
		["east"]  = OpaqueBlock( BTEX("shulker_light_blue_bottom", 'flip_x'), BTEX("shulker_light_blue_top"), BTEX("shulker_light_blue_side_right", 'rotate_90'), BTEX("shulker_light_blue_side_left", 'rotate_270'), BTEX("shulker_light_blue_side_front", 'rotate_270'), BTEX("shulker_light_blue_side_back", 'rotate_270') ), -- facing east
		["south"] = OpaqueBlock( BTEX("shulker_light_blue_side_left", 'rotate_270'), BTEX("shulker_light_blue_side_right", 'rotate_90'), BTEX("shulker_light_blue_bottom", 'flip_x'), BTEX("shulker_light_blue_top"), BTEX("shulker_light_blue_side_front"), BTEX("shulker_light_blue_side_back", 'rotate_180') ), -- facing south
		["west"]  = OpaqueBlock( BTEX("shulker_light_blue_top"), BTEX("shulker_light_blue_bottom", 'flip_x'), BTEX("shulker_light_blue_side_left", 'rotate_270'), BTEX("shulker_light_blue_side_right", 'rotate_90'), BTEX("shulker_light_blue_side_front", 'rotate_90'), BTEX("shulker_light_blue_side_back", 'rotate_90') ), -- facing west
		["up"]    = OpaqueBlock( BTEX("shulker_light_blue_side_left"), BTEX("shulker_light_blue_side_right"), BTEX("shulker_light_blue_side_back"), BTEX("shulker_light_blue_side_front"), BTEX("shulker_light_blue_bottom", 'flip_y'), BTEX("shulker_light_blue_top") ), -- facing up
		["down"]  = OpaqueBlock( BTEX("shulker_light_blue_side_left", 'rotate_180'), BTEX("shulker_light_blue_side_right", 'rotate_180'), BTEX("shulker_light_blue_side_front", 'rotate_180'), BTEX("shulker_light_blue_side_back", 'rotate_180'), BTEX("shulker_light_blue_top"), BTEX("shulker_light_blue_bottom", 'flip_y') ) ); -- facing down
	["minecraft:light_blue_wool"] = OpaqueBlock( BTEX("light_blue_wool") ); -- Light Blue Wool
	["minecraft:light_gray_carpet"] = CompactedBlock( 0, 0, 0, 0, 0, -15, BTEX("light_gray_wool") ); -- Light Grey Carpet	
	["minecraft:light_gray_concrete"] = OpaqueBlock( BTEX("light_grey_concrete") ); -- Light Grey Concrete
	["minecraft:light_gray_concrete_powder"] = OpaqueBlock( BTEX("light_grey_concrete_powder") ); -- Light Grey	Concrete Powder
	["minecraft:light_gray_glazed_terracotta"] = StateAdapter( "facing", -- Light Grey Glazed Terracotta
		["north"] = OpaqueBlock( BTEX("light_gray_glazed_terracotta", 'rotate_180'), BTEX("light_gray_glazed_terracotta"), BTEX("light_gray_glazed_terracotta", 'rotate_90'), BTEX("light_gray_glazed_terracotta", 'rotate_270'), BTEX("light_gray_glazed_terracotta", 'rotate_180'), BTEX("light_gray_glazed_terracotta", 'rotate_180') ), -- facing north
		["east"]  = OpaqueBlock( BTEX("light_gray_glazed_terracotta", 'rotate_270'), BTEX("light_gray_glazed_terracotta", 'rotate_90'), BTEX("light_gray_glazed_terracotta", 'rotate_180'), BTEX("light_gray_glazed_terracotta"), BTEX("light_gray_glazed_terracotta", 'rotate_270'), BTEX("light_gray_glazed_terracotta", 'rotate_90') ), -- facing east
		["south"] = OpaqueBlock( BTEX("light_gray_glazed_terracotta"), BTEX("light_gray_glazed_terracotta", 'rotate_180'), BTEX("light_gray_glazed_terracotta", 'rotate_270'), BTEX("light_gray_glazed_terracotta", 'rotate_90'), BTEX("light_gray_glazed_terracotta"), BTEX("light_gray_glazed_terracotta") ), -- facing south
		["west"]  = OpaqueBlock( BTEX("light_gray_glazed_terracotta", 'rotate_90'), BTEX("light_gray_glazed_terracotta", 'rotate_270'), BTEX("light_gray_glazed_terracotta"), BTEX("light_gray_glazed_terracotta", 'rotate_180'), BTEX("light_gray_glazed_terracotta", 'rotate_90'), BTEX("light_gray_glazed_terracotta", 'rotate_270') ) ); -- facing west
	["minecraft:light_gray_shulker_box"] = StateAdapter( "facing", -- Light Gray Shulker Box
		["north"] = OpaqueBlock( BTEX("shulker_light_gray_side_right", 'rotate_90'), BTEX("shulker_light_gray_side_left", 'rotate_270'), BTEX("shulker_light_gray_top"), BTEX("shulker_light_gray_bottom", 'flip_x'), BTEX("shulker_light_gray_side_front", 'rotate_180'), BTEX("shulker_light_gray_side_back") ), -- facing north
		["east"]  = OpaqueBlock( BTEX("shulker_light_gray_bottom", 'flip_x'), BTEX("shulker_light_gray_top"), BTEX("shulker_light_gray_side_right", 'rotate_90'), BTEX("shulker_light_gray_side_left", 'rotate_270'), BTEX("shulker_light_gray_side_front", 'rotate_270'), BTEX("shulker_light_gray_side_back", 'rotate_270') ), -- facing east
		["south"] = OpaqueBlock( BTEX("shulker_light_gray_side_left", 'rotate_270'), BTEX("shulker_light_gray_side_right", 'rotate_90'), BTEX("shulker_light_gray_bottom", 'flip_x'), BTEX("shulker_light_gray_top"), BTEX("shulker_light_gray_side_front"), BTEX("shulker_light_gray_side_back", 'rotate_180') ), -- facing south
		["west"]  = OpaqueBlock( BTEX("shulker_light_gray_top"), BTEX("shulker_light_gray_bottom", 'flip_x'), BTEX("shulker_light_gray_side_left", 'rotate_270'), BTEX("shulker_light_gray_side_right", 'rotate_90'), BTEX("shulker_light_gray_side_front", 'rotate_90'), BTEX("shulker_light_gray_side_back", 'rotate_90') ), -- facing west
		["up"]    = OpaqueBlock( BTEX("shulker_light_gray_side_left"), BTEX("shulker_light_gray_side_right"), BTEX("shulker_light_gray_side_back"), BTEX("shulker_light_gray_side_front"), BTEX("shulker_light_gray_bottom", 'flip_y'), BTEX("shulker_light_gray_top") ), -- facing up
		["down"]  = OpaqueBlock( BTEX("shulker_light_gray_side_left", 'rotate_180'), BTEX("shulker_light_gray_side_right", 'rotate_180'), BTEX("shulker_light_gray_side_front", 'rotate_180'), BTEX("shulker_light_gray_side_back", 'rotate_180'), BTEX("shulker_light_gray_top"), BTEX("shulker_light_gray_bottom", 'flip_y') ) ); -- facing down
	["minecraft:light_gray_wool"] = OpaqueBlock( BTEX("light_gray_wool") ); -- Light Grey Wool
	["minecraft:light_weighted_pressure_plate"] = CompactedBlock( -1, -1, -1, -1, 0, -15, BTEX("gold_block") ); -- Light Weighted Pressure Plate
	["minecraft:lilac"] = StateAdapter( "half", -- Lilac
		["upper"] = XShapedBlock( BTEX("lilac_top") ), -- upper half
		["lower"] = XShapedBlock( BTEX("lilac_bottom") ); -- lower half
	["minecraft:lime_carpet"] = CompactedBlock( 0, 0, 0, 0, 0, -15, BTEX("lime_wool") ); -- Lime Carpet
	["minecraft:lime_concrete"] = OpaqueBlock( BTEX("lime_concrete") ); -- Lime Concrete
	["minecraft:lime_concrete_powder"] = OpaqueBlock( BTEX("lime_concrete_powder") ); -- Lime Concrete Powder
	["minecraft:lime_glazed_terracotta"] = StateAdapter( "facing", -- Lime Glazed Terracotta
		["north"] = OpaqueBlock( BTEX("lime_glazed_terracotta", 'rotate_180'), BTEX("lime_glazed_terracotta"), BTEX("lime_glazed_terracotta", 'rotate_90'), BTEX("lime_glazed_terracotta", 'rotate_270'), BTEX("lime_glazed_terracotta", 'rotate_180'), BTEX("lime_glazed_terracotta", 'rotate_180') ), -- facing north
		["east"]  = OpaqueBlock( BTEX("lime_glazed_terracotta", 'rotate_270'), BTEX("lime_glazed_terracotta", 'rotate_90'), BTEX("lime_glazed_terracotta", 'rotate_180'), BTEX("lime_glazed_terracotta"), BTEX("lime_glazed_terracotta", 'rotate_270'), BTEX("lime_glazed_terracotta", 'rotate_90') ), -- facing east
		["south"] = OpaqueBlock( BTEX("lime_glazed_terracotta"), BTEX("lime_glazed_terracotta", 'rotate_180'), BTEX("lime_glazed_terracotta", 'rotate_270'), BTEX("lime_glazed_terracotta", 'rotate_90'), BTEX("lime_glazed_terracotta"), BTEX("lime_glazed_terracotta") ), -- facing south
		["west"]  = OpaqueBlock( BTEX("lime_glazed_terracotta", 'rotate_90'), BTEX("lime_glazed_terracotta", 'rotate_270'), BTEX("lime_glazed_terracotta"), BTEX("lime_glazed_terracotta", 'rotate_180'), BTEX("lime_glazed_terracotta", 'rotate_90'), BTEX("lime_glazed_terracotta", 'rotate_270') ) ); -- facing west
	["minecraft:lime_shulker_box"] = StateAdapter( "facing", -- Lime Shulker Box
		["north"] = OpaqueBlock( BTEX("shulker_lime_side_right", 'rotate_90'), BTEX("shulker_lime_side_left", 'rotate_270'), BTEX("shulker_lime_top"), BTEX("shulker_lime_bottom", 'flip_x'), BTEX("shulker_lime_side_front", 'rotate_180'), BTEX("shulker_lime_side_back") ), -- facing north
		["east"]  = OpaqueBlock( BTEX("shulker_lime_bottom", 'flip_x'), BTEX("shulker_lime_top"), BTEX("shulker_lime_side_right", 'rotate_90'), BTEX("shulker_lime_side_left", 'rotate_270'), BTEX("shulker_lime_side_front", 'rotate_270'), BTEX("shulker_lime_side_back", 'rotate_270') ), -- facing east
		["south"] = OpaqueBlock( BTEX("shulker_lime_side_left", 'rotate_270'), BTEX("shulker_lime_side_right", 'rotate_90'), BTEX("shulker_lime_bottom", 'flip_x'), BTEX("shulker_lime_top"), BTEX("shulker_lime_side_front"), BTEX("shulker_lime_side_back", 'rotate_180') ), -- facing south
		["west"]  = OpaqueBlock( BTEX("shulker_lime_top"), BTEX("shulker_lime_bottom", 'flip_x'), BTEX("shulker_lime_side_left", 'rotate_270'), BTEX("shulker_lime_side_right", 'rotate_90'), BTEX("shulker_lime_side_front", 'rotate_90'), BTEX("shulker_lime_side_back", 'rotate_90') ), -- facing west
		["up"]    = OpaqueBlock( BTEX("shulker_lime_side_left"), BTEX("shulker_lime_side_right"), BTEX("shulker_lime_side_back"), BTEX("shulker_lime_side_front"), BTEX("shulker_lime_bottom", 'flip_y'), BTEX("shulker_lime_top") ), -- facing up
		["down"]  = OpaqueBlock( BTEX("shulker_lime_side_left", 'rotate_180'), BTEX("shulker_lime_side_right", 'rotate_180'), BTEX("shulker_lime_side_front", 'rotate_180'), BTEX("shulker_lime_side_back", 'rotate_180'), BTEX("shulker_lime_top"), BTEX("shulker_lime_bottom", 'flip_y') ) ); -- facing down
	["minecraft:lime_wool"] = OpaqueBlock( BTEX("lime_wool") ); -- Lime Wool

	-- >> M << --
	["minecraft:magenta_carpet"] = CompactedBlock( 0, 0, 0, 0, 0, -15, BTEX("magenta_wool") ); -- Magenta Carpet
	["minecraft:magenta_concrete"] = OpaqueBlock( BTEX("magenta_concrete") ); -- Magenta Concrete
	["minecraft:magenta_concrete_powder"] = OpaqueBlock( BTEX("magenta_concrete_powder") ); -- Magenta Concrete Powder
	["minecraft:magenta_glazed_terracotta"] = StateAdapter( "facing", -- Magenta Glazed Terracotta
		["north"] = OpaqueBlock( BTEX("magenta_glazed_terracotta", 'rotate_180'), BTEX("magenta_glazed_terracotta"), BTEX("magenta_glazed_terracotta", 'rotate_90'), BTEX("magenta_glazed_terracotta", 'rotate_270'), BTEX("magenta_glazed_terracotta", 'rotate_180'), BTEX("magenta_glazed_terracotta", 'rotate_180') ), -- facing north
		["east"]  = OpaqueBlock( BTEX("magenta_glazed_terracotta", 'rotate_270'), BTEX("magenta_glazed_terracotta", 'rotate_90'), BTEX("magenta_glazed_terracotta", 'rotate_180'), BTEX("magenta_glazed_terracotta"), BTEX("magenta_glazed_terracotta", 'rotate_270'), BTEX("magenta_glazed_terracotta", 'rotate_90') ), -- facing east
		["south"] = OpaqueBlock( BTEX("magenta_glazed_terracotta"), BTEX("magenta_glazed_terracotta", 'rotate_180'), BTEX("magenta_glazed_terracotta", 'rotate_270'), BTEX("magenta_glazed_terracotta", 'rotate_90'), BTEX("magenta_glazed_terracotta"), BTEX("magenta_glazed_terracotta") ), -- facing south
		["west"]  = OpaqueBlock( BTEX("magenta_glazed_terracotta", 'rotate_90'), BTEX("magenta_glazed_terracotta", 'rotate_270'), BTEX("magenta_glazed_terracotta"), BTEX("magenta_glazed_terracotta", 'rotate_180'), BTEX("magenta_glazed_terracotta", 'rotate_90'), BTEX("magenta_glazed_terracotta", 'rotate_270') ) ); -- facing west
	["minecraft:magenta_shulker_box"] = StateAdapter( "facing", -- Magenta Shulker Box
		["north"] = OpaqueBlock( BTEX("shulker_magenta_side_right", 'rotate_90'), BTEX("shulker_magenta_side_left", 'rotate_270'), BTEX("shulker_magenta_top"), BTEX("shulker_magenta_bottom", 'flip_x'), BTEX("shulker_magenta_side_front", 'rotate_180'), BTEX("shulker_magenta_side_back") ), -- facing north
		["east"]  = OpaqueBlock( BTEX("shulker_magenta_bottom", 'flip_x'), BTEX("shulker_magenta_top"), BTEX("shulker_magenta_side_right", 'rotate_90'), BTEX("shulker_magenta_side_left", 'rotate_270'), BTEX("shulker_magenta_side_front", 'rotate_270'), BTEX("shulker_magenta_side_back", 'rotate_270') ), -- facing east
		["south"] = OpaqueBlock( BTEX("shulker_magenta_side_left", 'rotate_270'), BTEX("shulker_magenta_side_right", 'rotate_90'), BTEX("shulker_magenta_bottom", 'flip_x'), BTEX("shulker_magenta_top"), BTEX("shulker_magenta_side_front"), BTEX("shulker_magenta_side_back", 'rotate_180') ), -- facing south
		["west"]  = OpaqueBlock( BTEX("shulker_magenta_top"), BTEX("shulker_magenta_bottom", 'flip_x'), BTEX("shulker_magenta_side_left", 'rotate_270'), BTEX("shulker_magenta_side_right", 'rotate_90'), BTEX("shulker_magenta_side_front", 'rotate_90'), BTEX("shulker_magenta_side_back", 'rotate_90') ), -- facing west
		["up"]    = OpaqueBlock( BTEX("shulker_magenta_side_left"), BTEX("shulker_magenta_side_right"), BTEX("shulker_magenta_side_back"), BTEX("shulker_magenta_side_front"), BTEX("shulker_magenta_bottom", 'flip_y'), BTEX("shulker_magenta_top") ), -- facing up
		["down"]  = OpaqueBlock( BTEX("shulker_magenta_side_left", 'rotate_180'), BTEX("shulker_magenta_side_right", 'rotate_180'), BTEX("shulker_magenta_side_front", 'rotate_180'), BTEX("shulker_magenta_side_back", 'rotate_180'), BTEX("shulker_magenta_top"), BTEX("shulker_magenta_bottom", 'flip_y') ) ); -- facing down
	["minecraft:magenta_wool"] = OpaqueBlock( BTEX("magenta_wool") ); -- Magenta Wool
	["minecraft:magma_block"] = OpaqueBlock( BTEX( "magma") ); -- Magma Block
	["minecraft:melon_block"] = OpaqueBlock( BTEX("melon_side"), BTEX("melon_top") ); -- Melon
	["minecraft:mob_spawner"] = HollowOpaqueBlock( BTEX("mob_spawner") ); -- Mob Spawner
	["minecraft:mossy_cobblestone"] = OpaqueBlock( BTEX("mossy_cobblestone") ); -- Mossy Cobblestone
	["minecraft:mossy_stone_bricks"] = OpaqueBlock( BTEX("mossy_stone_bricks") ); -- Mossy Stone Brick
	["minecraft:mycelium"] = StateAdapter( "snowy", -- Mycelium
		["false"] = OpaqueBlock( BTEX("mycelium_side"), BTEX("dirt"), BTEX("mycelium_top") ), -- regular mycelium
		["true"]  = OpaqueBlock( BTEX("grass_side_snowed"), BTEX("dirt"), BTEX("mycelium_top") ) ); -- snowy mycelium

	-- >> N << --
	["minecraft:nether_bricks"] = OpaqueBlock( BTEX("nether_brick") ); -- Nether Brick
	["minecraft:nether_brick_slab"] =  StateAdapter( "type", -- Nether Brick Slab
		["bottom"] = Slab( -8, 0, BTEX("nether_brick") ), -- bottom slab
		["top"] = Slab( 0, -8, BTEX("nether_brick") ), -- top slab
		["double"] = OpaqueBlock( BTEX("nether_brick") ) ); -- double slab
	["minecraft:nether_quartz_ore"] = OpaqueBlock( BTEX("quartz_ore") ); -- Nether Quartz Ore
	["minecraft:nether_wart"] = StateAdapter( "age", -- Nether Wart
		[0] = HashShapedBlock( -4, BTEX("nether_wart_stage0"), 0 ), -- growthstate 0
		[1] = HashShapedBlock( -4, BTEX("nether_wart_stage1"), 0 ), -- growthstate 1
		[2] = HashShapedBlock( -4, BTEX("nether_wart_stage2"), 0 ) ); -- growthstate 2
	["minecraft:nether_wart_block"] = OpaqueBlock( BTEX("nether_wart_block") ); -- Nether Wart Block
	["minecraft:netherrack"] = OpaqueBlock( BTEX("netherrack") ); -- Netherrack
	["minecraft:note_block"] = OpaqueBlock( BTEX("note_block") ); -- Note Block

	-- >> O << --
	["minecraft:oak_bark"] = OpaqueBlock( BTEX("oak_log") ); -- Oak Bark
	["minecraft:oak_leaves"] = BiomeHollowOpaqueBlock( 1, BTEX("oak_leaves") ); -- Oak Leaves
	["minecraft:oak_log"] = StateAdapter( "axis", -- Oak Log
		["x"] = OpaqueBlock( BTEX("oak_log_top"), BTEX("oak_log_top", 'rotate_180'), BTEX("oak_log", 'rotate_90'), BTEX("oak_log", 'rotate_270'), BTEX("oak_log", 'rotate_270'), BTEX("oak_log", 'rotate_270') ), -- west-east
		["y"] = OpaqueBlock( BTEX("oak_log"), BTEX("oak_log_top") ), -- top-bottom
		["z"] = OpaqueBlock( BTEX("oak_log", 'rotate_90'), BTEX("oak_log", 'rotate_270'), BTEX("oak_log_top", 'rotate_180'), BTEX("oak_log_top"), BTEX("oak_log", 'rotate_180'), BTEX("oak_log") ) ); -- north-south
	["minecraft:oak_planks"] = OpaqueBlock( BTEX("oak_planks") ); -- Oak Planks
	["minecraft:oak_pressure_plate"] = CompactedBlock( -1, -1, -1, -1, 0, -15, BTEX("oak_planks") ); -- Oak Pressure Plate
	["minecraft:oak_sapling"] = OpaqueBlock( BTEX("oak_sapling") ); -- Oak Sapling
	["minecraft:oak_slab"] =  StateAdapter( "type", -- Oak Slab
		["bottom"] = Slab( -8, 0, BTEX("oak_planks") ), -- bottom slab
		["top"] = Slab( 0, -8, BTEX("oak_planks") ), -- top slab
		["double"] = OpaqueBlock( BTEX("oak_planks") ) ); -- double slab
	["minecraft:observer"] = StateAdapter( "powered", -- Observer
		["false"] = StateAdapter( "facing", -- unpowered
			["north"] = OpaqueBlock( BTEX("observer_side"), BTEX("observer_side"), BTEX("observer_front"), BTEX("observer_back"), BTEX("observer_top"), BTEX("observer_top", 'flip_y') ), -- facing north
			["east"]  = OpaqueBlock( BTEX("observer_back"), BTEX("observer_front"), BTEX("observer_side"), BTEX("observer_side"), BTEX("observer_top", 'rotate_90'), BTEX("observer_top", 'rotate_90', 'flip_y') ), -- facing east
			["south"] = OpaqueBlock( BTEX("observer_side"), BTEX("observer_side"), BTEX("observer_back"), BTEX("observer_front"), BTEX("observer_top", 'rotate_180'), BTEX("observer_top", 'flip_x') ), -- facing south
			["west"]  = OpaqueBlock( BTEX("observer_front"), BTEX("observer_back"), BTEX("observer_side"), BTEX("observer_side"), BTEX("observer_top", 'rotate_270'), BTEX("observer_top", 'rotate_90', 'flip_x') ), -- facing west
			["up"]    = OpaqueBlock( BTEX("observer_side", 'rotate_270'), BTEX("observer_side", 'rotate_270'), BTEX("observer_top", 'rotate_180'), BTEX("observer_top", 'flip_y'), BTEX("observer_back"), BTEX("observer_front", 'rotate_180') ), -- facing up
			["down"]  = OpaqueBlock( BTEX("observer_side", 'rotate_90'), BTEX("observer_side", 'rotate_270'), BTEX("observer_top", 'flip_x'), BTEX("observer_top"), BTEX("observer_front", 'rotate_180'), BTEX("observer_back") ) ), -- facing down
		["true"] = StateAdapter( "facing", -- powered
			["north"] = OpaqueBlock( BTEX("observer_side"), BTEX("observer_side"), BTEX("observer_front"), BTEX("observer_back_on"), BTEX("observer_top"), BTEX("observer_top", 'flip_y') ), -- facing north
			["east"]  = OpaqueBlock( BTEX("observer_back_on"), BTEX("observer_front"), BTEX("observer_side"), BTEX("observer_side"), BTEX("observer_top", 'rotate_90'), BTEX("observer_top", 'rotate_90', 'flip_y') ), -- facing east
			["south"] = OpaqueBlock( BTEX("observer_side"), BTEX("observer_side"), BTEX("observer_back_on"), BTEX("observer_front"), BTEX("observer_top", 'rotate_180'), BTEX("observer_top", 'flip_x') ), -- facing south
			["west"]  = OpaqueBlock( BTEX("observer_front"), BTEX("observer_back_on"), BTEX("observer_side"), BTEX("observer_side"), BTEX("observer_top", 'rotate_270'), BTEX("observer_top", 'rotate_90', 'flip_x') ), -- facing west
			["up"]    = OpaqueBlock( BTEX("observer_side", 'rotate_270'), BTEX("observer_side", 'rotate_270'), BTEX("observer_top", 'rotate_180'), BTEX("observer_top", 'flip_y'), BTEX("observer_back_on"), BTEX("observer_front", 'rotate_180') ), -- facing up
			["down"]  = OpaqueBlock( BTEX("observer_side", 'rotate_90'), BTEX("observer_side", 'rotate_270'), BTEX("observer_top", 'flip_x'), BTEX("observer_top"), BTEX("observer_front", 'rotate_180'), BTEX("observer_back_on") ) ) ); -- facing down
	["minecraft:obsidian"] = OpaqueBlock( BTEX("obsidian") ); -- Obsidian
	["minecraft:orange_carpet"] = CompactedBlock( 0, 0, 0, 0, 0, -15, BTEX("orange_wool") ); -- Orange Carpet
	["minecraft:orange_concrete"] = OpaqueBlock( BTEX("orange_concrete") ); -- Orange Concrete
	["minecraft:orange_concrete_powder"] = OpaqueBlock( BTEX("orange_concrete_powder") ); -- Orange Concrete Powder
	["minecraft:orange_glazed_terracotta"] = StateAdapter( "facing", -- Orange Glazed Terracotta
		["north"] = OpaqueBlock( BTEX("orange_glazed_terracotta", 'rotate_180'), BTEX("orange_glazed_terracotta"), BTEX("orange_glazed_terracotta", 'rotate_90'), BTEX("orange_glazed_terracotta", 'rotate_270'), BTEX("orange_glazed_terracotta", 'rotate_180'), BTEX("orange_glazed_terracotta", 'rotate_180') ), -- facing north
		["east"]  = OpaqueBlock( BTEX("orange_glazed_terracotta", 'rotate_270'), BTEX("orange_glazed_terracotta", 'rotate_90'), BTEX("orange_glazed_terracotta", 'rotate_180'), BTEX("orange_glazed_terracotta"), BTEX("orange_glazed_terracotta", 'rotate_270'), BTEX("orange_glazed_terracotta", 'rotate_90') ), -- facing east
		["south"] = OpaqueBlock( BTEX("orange_glazed_terracotta"), BTEX("orange_glazed_terracotta", 'rotate_180'), BTEX("orange_glazed_terracotta", 'rotate_270'), BTEX("orange_glazed_terracotta", 'rotate_90'), BTEX("orange_glazed_terracotta"), BTEX("orange_glazed_terracotta") ), -- facing south
		["west"]  = OpaqueBlock( BTEX("orange_glazed_terracotta", 'rotate_90'), BTEX("orange_glazed_terracotta", 'rotate_270'), BTEX("orange_glazed_terracotta"), BTEX("orange_glazed_terracotta", 'rotate_180'), BTEX("orange_glazed_terracotta", 'rotate_90'), BTEX("orange_glazed_terracotta", 'rotate_270') ) ); -- facing west
	["minecraft:orange_shulker_box"] = StateAdapter( "facing", -- Orange Shulker Box
		["north"] = OpaqueBlock( BTEX("shulker_orange_side_right", 'rotate_90'), BTEX("shulker_orange_side_left", 'rotate_270'), BTEX("shulker_orange_top"), BTEX("shulker_orange_bottom", 'flip_x'), BTEX("shulker_orange_side_front", 'rotate_180'), BTEX("shulker_orange_side_back") ), -- facing north
		["east"]  = OpaqueBlock( BTEX("shulker_orange_bottom", 'flip_x'), BTEX("shulker_orange_top"), BTEX("shulker_orange_side_right", 'rotate_90'), BTEX("shulker_orange_side_left", 'rotate_270'), BTEX("shulker_orange_side_front", 'rotate_270'), BTEX("shulker_orange_side_back", 'rotate_270') ), -- facing east
		["south"] = OpaqueBlock( BTEX("shulker_orange_side_left", 'rotate_270'), BTEX("shulker_orange_side_right", 'rotate_90'), BTEX("shulker_orange_bottom", 'flip_x'), BTEX("shulker_orange_top"), BTEX("shulker_orange_side_front"), BTEX("shulker_orange_side_back", 'rotate_180') ), -- facing south
		["west"]  = OpaqueBlock( BTEX("shulker_orange_top"), BTEX("shulker_orange_bottom", 'flip_x'), BTEX("shulker_orange_side_left", 'rotate_270'), BTEX("shulker_orange_side_right", 'rotate_90'), BTEX("shulker_orange_side_front", 'rotate_90'), BTEX("shulker_orange_side_back", 'rotate_90') ), -- facing west
		["up"]    = OpaqueBlock( BTEX("shulker_orange_side_left"), BTEX("shulker_orange_side_right"), BTEX("shulker_orange_side_back"), BTEX("shulker_orange_side_front"), BTEX("shulker_orange_bottom", 'flip_y'), BTEX("shulker_orange_top") ), -- facing up
		["down"]  = OpaqueBlock( BTEX("shulker_orange_side_left", 'rotate_180'), BTEX("shulker_orange_side_right", 'rotate_180'), BTEX("shulker_orange_side_front", 'rotate_180'), BTEX("shulker_orange_side_back", 'rotate_180'), BTEX("shulker_orange_top"), BTEX("shulker_orange_bottom", 'flip_y') ) ); -- facing down
	["minecraft:orange_tulip"] = XShapedBlock( BTEX("orange_tulip") ); -- Orange Tulip
	["minecraft:orange_wool"] = OpaqueBlock( BTEX("orange_wool") ); -- Orange Wool
	["minecraft:oxeye_daisy"] = XShapedBlock( BTEX("oxeye_daisy") ); -- Oxeye Daisy

	-- >> P << --
	["minecraft:packed_ice"] = OpaqueBlock( BTEX("packed_ice") ); -- Packed Ice
	["minecraft:peony"] = StateAdapter( "half", -- Peony
		["upper"] = XShapedBlock( BTEX("peony_top") ), -- upper half
		["lower"] = XShapedBlock( BTEX("peony_bottom") ); -- lower half
	["minecraft:petrified_oak_slab"] =  StateAdapter( "type", -- Petrified Oak Slab
		["bottom"] = Slab( -8, 0, BTEX("oak_planks") ), -- bottom slab
		["top"] = Slab( 0, -8, BTEX("oak_planks") ), -- top slab
		["double"] = OpaqueBlock( BTEX("oak_planks") ) ); -- double slab};
	["minecraft:pink_carpet"] = CompactedBlock( 0, 0, 0, 0, 0, -15, BTEX("pink_wool") ); -- Pink Carpet
	["minecraft:pink_concrete"] = OpaqueBlock( BTEX("pink_concrete") ); -- Pink Concrete
	["minecraft:pink_concrete_powder"] = OpaqueBlock( BTEX("pink_concrete_powder") ); -- Pink Concrete Powder
	["minecraft:pink_glazed_terracotta"] = StateAdapter( "facing", -- Pink Glazed Terracotta
		["north"] = OpaqueBlock( BTEX("pink_glazed_terracotta", 'rotate_180'), BTEX("pink_glazed_terracotta"), BTEX("pink_glazed_terracotta", 'rotate_90'), BTEX("pink_glazed_terracotta", 'rotate_270'), BTEX("pink_glazed_terracotta", 'rotate_180'), BTEX("pink_glazed_terracotta", 'rotate_180') ), -- facing north
		["east"]  = OpaqueBlock( BTEX("pink_glazed_terracotta", 'rotate_270'), BTEX("pink_glazed_terracotta", 'rotate_90'), BTEX("pink_glazed_terracotta", 'rotate_180'), BTEX("pink_glazed_terracotta"), BTEX("pink_glazed_terracotta", 'rotate_270'), BTEX("pink_glazed_terracotta", 'rotate_90') ), -- facing east
		["south"] = OpaqueBlock( BTEX("pink_glazed_terracotta"), BTEX("pink_glazed_terracotta", 'rotate_180'), BTEX("pink_glazed_terracotta", 'rotate_270'), BTEX("pink_glazed_terracotta", 'rotate_90'), BTEX("pink_glazed_terracotta"), BTEX("pink_glazed_terracotta") ), -- facing south
		["west"]  = OpaqueBlock( BTEX("pink_glazed_terracotta", 'rotate_90'), BTEX("pink_glazed_terracotta", 'rotate_270'), BTEX("pink_glazed_terracotta"), BTEX("pink_glazed_terracotta", 'rotate_180'), BTEX("pink_glazed_terracotta", 'rotate_90'), BTEX("pink_glazed_terracotta", 'rotate_270') ) ); -- facing west
	["minecraft:pink_shulker_box"] = StateAdapter( "facing", -- Pink Shulker Box
		["north"] = OpaqueBlock( BTEX("shulker_pink_side_right", 'rotate_90'), BTEX("shulker_pink_side_left", 'rotate_270'), BTEX("shulker_pink_top"), BTEX("shulker_pink_bottom", 'flip_x'), BTEX("shulker_pink_side_front", 'rotate_180'), BTEX("shulker_pink_side_back") ), -- facing north
		["east"]  = OpaqueBlock( BTEX("shulker_pink_bottom", 'flip_x'), BTEX("shulker_pink_top"), BTEX("shulker_pink_side_right", 'rotate_90'), BTEX("shulker_pink_side_left", 'rotate_270'), BTEX("shulker_pink_side_front", 'rotate_270'), BTEX("shulker_pink_side_back", 'rotate_270') ), -- facing east
		["south"] = OpaqueBlock( BTEX("shulker_pink_side_left", 'rotate_270'), BTEX("shulker_pink_side_right", 'rotate_90'), BTEX("shulker_pink_bottom", 'flip_x'), BTEX("shulker_pink_top"), BTEX("shulker_pink_side_front"), BTEX("shulker_pink_side_back", 'rotate_180') ), -- facing south
		["west"]  = OpaqueBlock( BTEX("shulker_pink_top"), BTEX("shulker_pink_bottom", 'flip_x'), BTEX("shulker_pink_side_left", 'rotate_270'), BTEX("shulker_pink_side_right", 'rotate_90'), BTEX("shulker_pink_side_front", 'rotate_90'), BTEX("shulker_pink_side_back", 'rotate_90') ), -- facing west
		["up"]    = OpaqueBlock( BTEX("shulker_pink_side_left"), BTEX("shulker_pink_side_right"), BTEX("shulker_pink_side_back"), BTEX("shulker_pink_side_front"), BTEX("shulker_pink_bottom", 'flip_y'), BTEX("shulker_pink_top") ), -- facing up
		["down"]  = OpaqueBlock( BTEX("shulker_pink_side_left", 'rotate_180'), BTEX("shulker_pink_side_right", 'rotate_180'), BTEX("shulker_pink_side_front", 'rotate_180'), BTEX("shulker_pink_side_back", 'rotate_180'), BTEX("shulker_pink_top"), BTEX("shulker_pink_bottom", 'flip_y') ) ); -- facing down
	["minecraft:pink_tulip"] = XShapedBlock( BTEX("pink_tulip") ); -- Pink Tulip
	["minecraft:pink_wool"] = OpaqueBlock( BTEX("pink_wool") ); -- Pink Wool
	["minecraft:podzol"] = StateAdapter( "snowy", -- Podzol
		["false"] = OpaqueBlock( BTEX("podzol_side"), BTEX("dirt"), BTEX("podzol_top") ), -- regular pozdol
		["true"]  = OpaqueBlock( BTEX("grass_block_snow"), BTEX("dirt"), BTEX("grass_block_top") ) ); -- snowy pozdol
	["minecraft:polished_andesite"] = OpaqueBlock( BTEX("polished_andesite") ); -- Polished Andasite
	["minecraft:polished_diorite"] = OpaqueBlock( BTEX("polished_diorite") ); --  Polished Diorite
	["minecraft:polished_granite"] = OpaqueBlock( BTEX("polished_granite") ); -- Polished Granite
	["minecraft:poppy"] = XShapedBlock( BTEX("poppy") ); -- Poppy
	["minecraft:potatoes"] = StateAdapter( "age", -- Potatoes
		[0] = HashShapedBlock( -4, BTEX("potatoes_stage0"), 0 ), -- growthstate 0
		[1] = HashShapedBlock( -4, BTEX("potatoes_stage0"), 0 ), -- growthstate 1
		[2] = HashShapedBlock( -4, BTEX("potatoes_stage1"), 0 ), -- growthstate 2
		[3] = HashShapedBlock( -4, BTEX("potatoes_stage1"), 0 ), -- growthstate 3
		[4] = HashShapedBlock( -4, BTEX("potatoes_stage2"), 0 ), -- growthstate 4
		[5] = HashShapedBlock( -4, BTEX("potatoes_stage2"), 0 ), -- growthstate 5
		[6] = HashShapedBlock( -4, BTEX("potatoes_stage2"), 0 ), -- growthstate 6
		[7] = HashShapedBlock( -4, BTEX("potatoes_stage3"), 0 ) ); -- growthstate 7
	["minecraft:prismarine"] = OpaqueBlock( BTEX("prismarine") ), -- Prismarine
	["minecraft:prismarine_slab"] =  StateAdapter( "type", -- Prismarine Slab
		["bottom"] = Slab( -8, 0, BTEX("prismarine") ), -- bottom slab
		["top"] = Slab( 0, -8, BTEX("prismarine") ), -- top slab
		["double"] = OpaqueBlock( BTEX("prismarine") ) ); -- double slab
	["minecraft:prismarine_bricks"] = OpaqueBlock( BTEX("prismarine_bricks") ), -- Prismarine Brick
	["minecraft:prismarine_bricks_slab"] =  StateAdapter( "type", -- Prismarine Brick Slab
		["bottom"] = Slab( -8, 0, BTEX("prismarine_bricks") ), -- bottom slab
		["top"] = Slab( 0, -8, BTEX("prismarine_bricks") ), -- top slab
		["double"] = OpaqueBlock( BTEX("prismarine_bricks") ) ); -- double slab
	["minecraft:pumpkin"] = OpaqueBlock( BTEX("pumpkin_side"), BTEX("pumpkin_top") ); -- Pumpkin
	["minecraft:purple_carpet"] = CompactedBlock( 0, 0, 0, 0, 0, -15, BTEX("purple_wool") ); -- Purple Carpet
	["minecraft:purple_concrete"] = OpaqueBlock( BTEX("purple_concrete") ); -- Purple Concrete
	["minecraft:purple_concrete_powder"] = OpaqueBlock( BTEX("purple_concrete_powder") ); -- Purple Concrete Powder
	["minecraft:purple_glazed_terracotta"] = StateAdapter( "facing", -- Purple Glazed Terracotta
		["north"] = OpaqueBlock( BTEX("purple_glazed_terracotta", 'rotate_180'), BTEX("purple_glazed_terracotta"), BTEX("purple_glazed_terracotta", 'rotate_90'), BTEX("purple_glazed_terracotta", 'rotate_270'), BTEX("purple_glazed_terracotta", 'rotate_180'), BTEX("purple_glazed_terracotta", 'rotate_180') ), -- facing north
		["east"]  = OpaqueBlock( BTEX("purple_glazed_terracotta", 'rotate_270'), BTEX("purple_glazed_terracotta", 'rotate_90'), BTEX("purple_glazed_terracotta", 'rotate_180'), BTEX("purple_glazed_terracotta"), BTEX("purple_glazed_terracotta", 'rotate_270'), BTEX("purple_glazed_terracotta", 'rotate_90') ), -- facing east
		["south"] = OpaqueBlock( BTEX("purple_glazed_terracotta"), BTEX("purple_glazed_terracotta", 'rotate_180'), BTEX("purple_glazed_terracotta", 'rotate_270'), BTEX("purple_glazed_terracotta", 'rotate_90'), BTEX("purple_glazed_terracotta"), BTEX("purple_glazed_terracotta") ), -- facing south
		["west"]  = OpaqueBlock( BTEX("purple_glazed_terracotta", 'rotate_90'), BTEX("purple_glazed_terracotta", 'rotate_270'), BTEX("purple_glazed_terracotta"), BTEX("purple_glazed_terracotta", 'rotate_180'), BTEX("purple_glazed_terracotta", 'rotate_90'), BTEX("purple_glazed_terracotta", 'rotate_270') ) ); -- facing west
	["minecraft:purple_shulker_box"] = StateAdapter( "facing", -- Purple Shulker Box
		["north"] = OpaqueBlock( BTEX("shulker_purple_side_right", 'rotate_90'), BTEX("shulker_purple_side_left", 'rotate_270'), BTEX("shulker_purple_top"), BTEX("shulker_purple_bottom", 'flip_x'), BTEX("shulker_purple_side_front", 'rotate_180'), BTEX("shulker_purple_side_back") ), -- facing north
		["east"]  = OpaqueBlock( BTEX("shulker_purple_bottom", 'flip_x'), BTEX("shulker_purple_top"), BTEX("shulker_purple_side_right", 'rotate_90'), BTEX("shulker_purple_side_left", 'rotate_270'), BTEX("shulker_purple_side_front", 'rotate_270'), BTEX("shulker_purple_side_back", 'rotate_270') ), -- facing east
		["south"] = OpaqueBlock( BTEX("shulker_purple_side_left", 'rotate_270'), BTEX("shulker_purple_side_right", 'rotate_90'), BTEX("shulker_purple_bottom", 'flip_x'), BTEX("shulker_purple_top"), BTEX("shulker_purple_side_front"), BTEX("shulker_purple_side_back", 'rotate_180') ), -- facing south
		["west"]  = OpaqueBlock( BTEX("shulker_purple_top"), BTEX("shulker_purple_bottom", 'flip_x'), BTEX("shulker_purple_side_left", 'rotate_270'), BTEX("shulker_purple_side_right", 'rotate_90'), BTEX("shulker_purple_side_front", 'rotate_90'), BTEX("shulker_purple_side_back", 'rotate_90') ), -- facing west
		["up"]    = OpaqueBlock( BTEX("shulker_purple_side_left"), BTEX("shulker_purple_side_right"), BTEX("shulker_purple_side_back"), BTEX("shulker_purple_side_front"), BTEX("shulker_purple_bottom", 'flip_y'), BTEX("shulker_purple_top") ), -- facing up
		["down"]  = OpaqueBlock( BTEX("shulker_purple_side_left", 'rotate_180'), BTEX("shulker_purple_side_right", 'rotate_180'), BTEX("shulker_purple_side_front", 'rotate_180'), BTEX("shulker_purple_side_back", 'rotate_180'), BTEX("shulker_purple_top"), BTEX("shulker_purple_bottom", 'flip_y') ) ); -- facing down
	["minecraft:purple_wool"] = OpaqueBlock( BTEX("purple_wool") ); -- Purple Wool
	["minecraft:purpur_block"] = OpaqueBlock( BTEX("purpur_block") ); -- Purpur Block
	["minecraft:purpur_slab"] =  StateAdapter( "type", -- Purpur Slab
		["bottom"] = Slab( -8, 0, BTEX("purpur_block") ), -- bottom slab
		["top"] = Slab( 0, -8, BTEX("purpur_block") ), -- top slab
		["double"] = OpaqueBlock( BTEX("purpur_block") ) ); -- double slab

	-- >> Q << --
	["minecraft:quartz_block"] = OpaqueBlock( BTEX("quartz_block_side"), BTEX("quartz_block_bottom"), BTEX("quartz_block_top") ); -- Quartz Block
	["minecraft:quartz_pillar"] = StateAdapter( "axis", -- Quartz Pillar Block
		["x"] = OpaqueBlock( BTEX("quartz_pillar_top"), BTEX("quartz_pillar_top", 'rotate_180'), BTEX("quartz_pillar", 'rotate_90'), BTEX("quartz_pillar", 'rotate_270'), BTEX("quartz_pillar", 'rotate_270'), BTEX("quartz_pillar", 'rotate_270') ), -- west-east
		["y"] = OpaqueBlock( BTEX("quartz_pillar"), BTEX("quartz_pillar_top") ), -- top-bottom
		["z"] = OpaqueBlock( BTEX("quartz_pillar", 'rotate_90'), BTEX("quartz_pillar", 'rotate_270'), BTEX("quartz_pillar_top", 'rotate_180'), BTEX("quartz_pillar_top"), BTEX("quartz_pillar", 'rotate_180'), BTEX("quartz_pillar") ) ); -- north-south
	["minecraft:quartz_slab"] =  StateAdapter( "type", -- Quartz Slab
		["bottom"] = Slab( -8, 0, BTEX("quartz_block_side"), BTEX("quartz_block_bottom"), BTEX("quartz_block_top") ), -- bottom slab
		["top"] = Slab( 0, -8, BTEX("quartz_block_side"), BTEX("quartz_block_bottom"), BTEX("quartz_block_top") ), -- top slab
		["double"] = OpaqueBlock( BTEX("quartz_block_side"), BTEX("quartz_block_bottom"), BTEX("quartz_block_top") ) ); -- double slab

	-- >> R << --
	["minecraft:red_carpet"] = CompactedBlock( 0, 0, 0, 0, 0, -15, BTEX("red_wool") ); -- Red Carpet
	["minecraft:red_concrete"] = OpaqueBlock( BTEX("red_concrete") ); -- Red Concrete
	["minecraft:red_concrete_powder"] = OpaqueBlock( BTEX("red_concrete_powder") ); -- Red Concrete Powder
	["minecraft:red_glazed_terracotta"] = StateAdapter( "facing", -- Red Glazed Terracotta
		["north"] = OpaqueBlock( BTEX("red_glazed_terracotta", 'rotate_180'), BTEX("red_glazed_terracotta"), BTEX("red_glazed_terracotta", 'rotate_90'), BTEX("red_glazed_terracotta", 'rotate_270'), BTEX("red_glazed_terracotta", 'rotate_180'), BTEX("red_glazed_terracotta", 'rotate_180') ), -- facing north
		["east"]  = OpaqueBlock( BTEX("red_glazed_terracotta", 'rotate_270'), BTEX("red_glazed_terracotta", 'rotate_90'), BTEX("red_glazed_terracotta", 'rotate_180'), BTEX("red_glazed_terracotta"), BTEX("red_glazed_terracotta", 'rotate_270'), BTEX("red_glazed_terracotta", 'rotate_90') ), -- facing east
		["south"] = OpaqueBlock( BTEX("red_glazed_terracotta"), BTEX("red_glazed_terracotta", 'rotate_180'), BTEX("red_glazed_terracotta", 'rotate_270'), BTEX("red_glazed_terracotta", 'rotate_90'), BTEX("red_glazed_terracotta"), BTEX("red_glazed_terracotta") ), -- facing south
		["west"]  = OpaqueBlock( BTEX("red_glazed_terracotta", 'rotate_90'), BTEX("red_glazed_terracotta", 'rotate_270'), BTEX("red_glazed_terracotta"), BTEX("red_glazed_terracotta", 'rotate_180'), BTEX("red_glazed_terracotta", 'rotate_90'), BTEX("red_glazed_terracotta", 'rotate_270') ) ); -- facing west
	["minecraft:red_nether_bricks"] = OpaqueBlock( BTEX("red_nether_brick") ); -- Red Nether Brick
	["minecraft:red_sand"] = OpaqueBlock( BTEX("red_sand") ); -- Red Sand
	["minecraft:red_sandstone"] = OpaqueBlock( BTEX("red_sandstone"), BTEX("red_sandstone_bottom"), BTEX("red_sandstone_top") ); -- Red Sandstone
	["minecraft:red_sandstone_slab"] =  StateAdapter( "type", -- Red Sandstone Slab
		["bottom"] = Slab( -8, 0, BTEX("red_sandstone"), BTEX("red_sandstone_bottom"), BTEX("red_sandstone_top") ), -- bottom slab
		["top"] = Slab( 0, -8, BTEX("red_sandstone"), BTEX("red_sandstone_bottom"), BTEX("red_sandstone_top") ), -- top slab
		["double"] = OpaqueBlock( BTEX("red_sandstone"), BTEX("red_sandstone_bottom"), BTEX("red_sandstone_top") ) ); -- double slab
	["minecraft:red_shulker_box"] = StateAdapter( "facing", -- Red Shulker Box
		["north"] = OpaqueBlock( BTEX("shulker_red_side_right", 'rotate_90'), BTEX("shulker_red_side_left", 'rotate_270'), BTEX("shulker_red_top"), BTEX("shulker_red_bottom", 'flip_x'), BTEX("shulker_red_side_front", 'rotate_180'), BTEX("shulker_red_side_back") ), -- facing north
		["east"]  = OpaqueBlock( BTEX("shulker_red_bottom", 'flip_x'), BTEX("shulker_red_top"), BTEX("shulker_red_side_right", 'rotate_90'), BTEX("shulker_red_side_left", 'rotate_270'), BTEX("shulker_red_side_front", 'rotate_270'), BTEX("shulker_red_side_back", 'rotate_270') ), -- facing east
		["south"] = OpaqueBlock( BTEX("shulker_red_side_left", 'rotate_270'), BTEX("shulker_red_side_right", 'rotate_90'), BTEX("shulker_red_bottom", 'flip_x'), BTEX("shulker_red_top"), BTEX("shulker_red_side_front"), BTEX("shulker_red_side_back", 'rotate_180') ), -- facing south
		["west"]  = OpaqueBlock( BTEX("shulker_red_top"), BTEX("shulker_red_bottom", 'flip_x'), BTEX("shulker_red_side_left", 'rotate_270'), BTEX("shulker_red_side_right", 'rotate_90'), BTEX("shulker_red_side_front", 'rotate_90'), BTEX("shulker_red_side_back", 'rotate_90') ), -- facing west
		["up"]    = OpaqueBlock( BTEX("shulker_red_side_left"), BTEX("shulker_red_side_right"), BTEX("shulker_red_side_back"), BTEX("shulker_red_side_front"), BTEX("shulker_red_bottom", 'flip_y'), BTEX("shulker_red_top") ), -- facing up
		["down"]  = OpaqueBlock( BTEX("shulker_red_side_left", 'rotate_180'), BTEX("shulker_red_side_right", 'rotate_180'), BTEX("shulker_red_side_front", 'rotate_180'), BTEX("shulker_red_side_back", 'rotate_180'), BTEX("shulker_red_top"), BTEX("shulker_red_bottom", 'flip_y') ) ); -- facing down
	["minecraft:redstone_block"] = OpaqueBlock( BTEX("redstone_block") ); -- Redstone Block
	["minecraft:redstone_lamp"] = StateAdapter( "lit", -- Redstone Lamp
		["false"] = OpaqueBlock( BTEX("redstone_lamp_off") ), -- unlit redstone lamp
		["true"] = OpaqueBlock( BTEX("redstone_lamp_on") ) ); -- lit redstone lamp
	["minecraft:redstone_ore"] = StateAdapter( "lit", -- Redstone Ore
		["false"] = OpaqueBlock( BTEX("redstone_ore") ), -- unlit redstone ore
		["true"] = OpaqueBlock( BTEX("redstone_ore") ) ); -- unlit redstone ore
	["minecraft:red_mushroom"] = XShapedBlock( BTEX("red_mushroom") ); -- Red Mushroom
	["minecraft:red_tulip"] = XShapedBlock( BTEX("red_tulip") ); -- Red Tulip
	["minecraft:red_wool"] = OpaqueBlock( BTEX("red_wool") ); -- Red Wool
	["minecraft:repeating_command_block"] = StateAdapter( "conditional", -- Repeating Command Block
		["false"] = StateAdapter( "facing", -- unconditional
			["north"] = OpaqueBlock( BTEX("repeating_command_block_side", 'rotate_90'), BTEX("repeating_command_block_side", 'rotate_270'), BTEX("repeating_command_block_front"), BTEX("repeating_command_block_back"), BTEX("repeating_command_block_side", 'rotate_180'), BTEX("repeating_command_block_side") ), -- facing north
			["east"]  = OpaqueBlock( BTEX("repeating_command_block_back"), BTEX("repeating_command_block_front"), BTEX("repeating_command_block_side", 'rotate_90'), BTEX("repeating_command_block_side", 'rotate_270'), BTEX("repeating_command_block_side", 'rotate_270'), BTEX("repeating_command_block_side", 'rotate_270') ), -- facing east
			["south"] = OpaqueBlock( BTEX("repeating_command_block_side", 'rotate_270'), BTEX("repeating_command_block_side", 'rotate_90'), BTEX("repeating_command_block_back"), BTEX("repeating_command_block_front"), BTEX("repeating_command_block_side"), BTEX("repeating_command_block_side", 'rotate_180') ), -- facing south
			["west"]  = OpaqueBlock( BTEX("repeating_command_block_front"), BTEX("repeating_command_block_back"), BTEX("repeating_command_block_side", 'rotate_270'), BTEX("repeating_command_block_side", 'rotate_90'), BTEX("repeating_command_block_side", 'rotate_90'), BTEX("repeating_command_block_side", 'rotate_90') ), -- facing west
			["up"]    = OpaqueBlock( BTEX("repeating_command_block_side"), BTEX("repeating_command_block_back"), BTEX("repeating_command_block_front", 'rotate_180') ), -- facing up
			["down"]  = OpaqueBlock( BTEX("repeating_command_block_side", 'rotate_180'), BTEX("repeating_command_block_front", 'rotate_180'), BTEX("repeating_command_block_back") ) ), -- facing down
		["true"] = StateAdapter( "facing", -- conditional
			["north"] = OpaqueBlock( BTEX("repeating_command_block_conditional", 'rotate_90'), BTEX("repeating_command_block_conditional", 'rotate_270'), BTEX("repeating_command_block_front"), BTEX("repeating_command_block_back"), BTEX("repeating_command_block_conditional", 'rotate_180'), BTEX("repeating_command_block_conditional") ), -- facing north
			["east"]  = OpaqueBlock( BTEX("repeating_command_block_back"), BTEX("repeating_command_block_front"), BTEX("repeating_command_block_conditional", 'rotate_90'), BTEX("repeating_command_block_conditional", 'rotate_270'), BTEX("repeating_command_block_conditional", 'rotate_270'), BTEX("repeating_command_block_conditional", 'rotate_270') ), -- facing east
			["south"] = OpaqueBlock( BTEX("repeating_command_block_conditional", 'rotate_270'), BTEX("repeating_command_block_conditional", 'rotate_90'), BTEX("repeating_command_block_back"), BTEX("repeating_command_block_front"), BTEX("repeating_command_block_conditional"), BTEX("repeating_command_block_conditional", 'rotate_180') ), -- facing south
			["west"]  = OpaqueBlock( BTEX("repeating_command_block_front"), BTEX("repeating_command_block_back"), BTEX("repeating_command_block_conditional", 'rotate_270'), BTEX("repeating_command_block_conditional", 'rotate_90'), BTEX("repeating_command_block_conditional", 'rotate_90'), BTEX("repeating_command_block_conditional", 'rotate_90') ), -- facing west
			["up"]    = OpaqueBlock( BTEX("repeating_command_block_conditional"), BTEX("repeating_command_block_back"), BTEX("repeating_command_block_front", 'rotate_180') ), -- facing up
			["down"]  = OpaqueBlock( BTEX("repeating_command_block_conditional", 'rotate_180'), BTEX("repeating_command_block_front", 'rotate_180'), BTEX("repeating_command_block_back") ) ) ); -- facing down
	["minecraft:rose_bush"] = StateAdapter( "half", -- Rose Bush
		["upper"] = XShapedBlock( BTEX("rose_bush_top") ), -- upper half
		["lower"] = XShapedBlock( BTEX("rose_bush_bottom") ); -- lower half

	-- >> S << --
	["minecraft:sand"] = OpaqueBlock( BTEX("sand") ); -- Sand
	["minecraft:sandstone"] = OpaqueBlock( BTEX("sandstone"), BTEX("sandstone_bottom"), BTEX("sandstone_top") ); -- Sandstone
	["minecraft:sandstone_slab"] =  StateAdapter( "type", -- Sandstone Slab
		["bottom"] = Slab( -8, 0, BTEX("sandstone"), BTEX("sandstone_bottom"), BTEX("sandstone_top") ), -- bottom slab
		["top"] = Slab( 0, -8, BTEX("sandstone"), BTEX("sandstone_bottom"), BTEX("sandstone_top") ), -- top slab
		["double"] = OpaqueBlock( BTEX("sandstone"), BTEX("sandstone_bottom"), BTEX("sandstone_top") ) ); -- double slab
	["minecraft:sea_grass"] = HashShapedBlock( -4, BTEX("sea_grass"), 0 ), -- Sea Grass
	["minecraft:sea_lantern"] = OpaqueBlock( BTEX("sea_lantern") ); -- Sea Lantern
	["minecraft:shulker_box"] = StateAdapter( "facing", -- Shulker Box
		["north"] = OpaqueBlock( BTEX("shulker_regular_side_right", 'rotate_90'), BTEX("shulker_regular_side_left", 'rotate_270'), BTEX("shulker_regular_top"), BTEX("shulker_regular_bottom", 'flip_x'), BTEX("shulker_regular_side_front", 'rotate_180'), BTEX("shulker_regular_side_back") ), -- facing north
		["east"]  = OpaqueBlock( BTEX("shulker_regular_bottom", 'flip_x'), BTEX("shulker_regular_top"), BTEX("shulker_regular_side_right", 'rotate_90'), BTEX("shulker_regular_side_left", 'rotate_270'), BTEX("shulker_regular_side_front", 'rotate_270'), BTEX("shulker_regular_side_back", 'rotate_270') ), -- facing east
		["south"] = OpaqueBlock( BTEX("shulker_regular_side_left", 'rotate_270'), BTEX("shulker_regular_side_right", 'rotate_90'), BTEX("shulker_regular_bottom", 'flip_x'), BTEX("shulker_regular_top"), BTEX("shulker_regular_side_front"), BTEX("shulker_regular_side_back", 'rotate_180') ), -- facing south
		["west"]  = OpaqueBlock( BTEX("shulker_regular_top"), BTEX("shulker_regular_bottom", 'flip_x'), BTEX("shulker_regular_side_left", 'rotate_270'), BTEX("shulker_regular_side_right", 'rotate_90'), BTEX("shulker_regular_side_front", 'rotate_90'), BTEX("shulker_regular_side_back", 'rotate_90') ), -- facing west
		["up"]    = OpaqueBlock( BTEX("shulker_regular_side_left"), BTEX("shulker_regular_side_right"), BTEX("shulker_regular_side_back"), BTEX("shulker_regular_side_front"), BTEX("shulker_regular_bottom", 'flip_y'), BTEX("shulker_regular_top") ), -- facing up
		["down"]  = OpaqueBlock( BTEX("shulker_regular_side_left", 'rotate_180'), BTEX("shulker_regular_side_right", 'rotate_180'), BTEX("shulker_regular_side_front", 'rotate_180'), BTEX("shulker_regular_side_back", 'rotate_180'), BTEX("shulker_regular_top"), BTEX("shulker_regular_bottom", 'flip_y') ) ); -- facing down
	["minecraft:smooth_red_sandstone"] = OpaqueBlock( BTEX("red_sandstone_top") ) ); -- Smooth Red Sandstone
	["minecraft:smooth_sandstone"] = OpaqueBlock( BTEX("sandstone_top") ) ); -- Smooth Sandstone
	["minecraft:smooth_stone"] = OpaqueBlock( BTEX("stone_slab_top") ) ); -- Smooth Stone
	["minecraft:smooth_quartz"] = OpaqueBlock( BTEX("quartz_block_side") ) ); -- Smooth Quartz
	["minecraft:snow"] = StateAdapter( "layers", -- Snow
		[1] = Slab( -14, 0, BTEX("snow") ), -- 1 layer
		[2] = Slab( -12, 0, BTEX("snow") ), -- 2 layer
		[3] = Slab( -10, 0, BTEX("snow") ), -- 3 layer
		[4] = Slab( -8, 0, BTEX("snow") ), -- 4 layer
		[5] = Slab( -6, 0, BTEX("snow") ), -- 5 layer
		[6] = Slab( -4, 0, BTEX("snow") ), -- 6 layer
		[7] = Slab( -2, 0, BTEX("snow") ), -- 7 layer
		[8] = OpaqueBlock( BTEX("snow") ) ); -- 8 layer/block
	["minecraft:snow_block"] = OpaqueBlock( BTEX("snow") ); -- Snow Block
	["minecraft:soul_sand"] = OpaqueBlock( BTEX("soul_sand") ); -- Soul Sand
	["minecraft:sponge"] = OpaqueBlock( BTEX("sponge") ); -- Sponge
	["minecraft:spruce_bark"] = OpaqueBlock( BTEX("spruce_log") ); -- Spruce Bark
	["minecraft:spruce_leaves"] = BiomeHollowOpaqueBlock( 2, BTEX("spruce_leaves") ); -- Spruce Leaves
	["minecraft:spruce_log"] = StateAdapter( "axis", -- Spruce Log
		["x"] = OpaqueBlock( BTEX("spruce_log_top"), BTEX("spruce_log_top", 'rotate_180'), BTEX("spruce_log", 'rotate_90'), BTEX("spruce_log", 'rotate_270'), BTEX("spruce_log", 'rotate_270'), BTEX("spruce_log", 'rotate_270') ), -- west-east
		["y"] = OpaqueBlock( BTEX("spruce_log"), BTEX("spruce_log_top") ), -- top-bottom
		["z"] = OpaqueBlock( BTEX("spruce_log", 'rotate_90'), BTEX("spruce_log", 'rotate_270'), BTEX("spruce_log_top", 'rotate_180'), BTEX("spruce_log_top"), BTEX("spruce_log", 'rotate_180'), BTEX("spruce_log") ) ); -- north-south
	["minecraft:spruce_planks"] = OpaqueBlock( BTEX("spruce_planks") ); -- Spruce Planks
	["minecraft:spruce_pressure_plate"] = CompactedBlock( -1, -1, -1, -1, 0, -15, BTEX("spruce_planks") ); -- Spruce Pressure Plate
	["minecraft:spruce_sapling"] = OpaqueBlock( BTEX("spruce_sapling") ); -- Spruce Sapling
	["minecraft:spruce_slab"] =  StateAdapter( "type", -- Spruce Slab
		["bottom"] = Slab( -8, 0, BTEX("spruce_planks") ), -- bottom slab
		["top"] = Slab( 0, -8, BTEX("spruce_planks") ), -- top slab
		["double"] = OpaqueBlock( BTEX("spruce_planks") ) ); -- double slab
	["minecraft:stone"] = OpaqueBlock( BTEX("stone") ); -- Stone
	["minecraft:stone_bricks"] = OpaqueBlock( BTEX("stone_bricks") ); -- Stone Brick
	["minecraft:stone_pressure_plate"] = CompactedBlock( -1, -1, -1, -1, 0, -15, BTEX("stone") ); -- Stone Pressure Plate
	["minecraft:stone_slab"] =  StateAdapter( "type", -- Stone Slab
		["bottom"] = Slab( -8, 0, BTEX("stone_slab_side"), BTEX("stone_slab_top") ), -- bottom slab
		["top"] = Slab( 0, -8, BTEX("stone_slab_side"), BTEX("stone_slab_top") ), -- top slab
		["double"] = OpaqueBlock( BTEX("stone_slab_side"), BTEX("stone_slab_top") ) ); -- double slab
	["minecraft:stone_brick_slab"] =  StateAdapter( "type", -- Stone Brick Slab
		["bottom"] = Slab( -8, 0, BTEX("stone_bricks") ), -- bottom slab
		["top"] = Slab( 0, -8, BTEX("stone_bricks") ), -- top slab
		["double"] = OpaqueBlock( BTEX("stone_bricks") ) ); -- double slab
	["minecraft:stripped_stripped_acacia_log"] = StateAdapter( "axis", -- Stripped Acacia Log
		["x"] = OpaqueBlock( BTEX("stripped_acacia_log_top"), BTEX("stripped_acacia_log_top", 'rotate_180'), BTEX("stripped_acacia_log", 'rotate_90'), BTEX("stripped_acacia_log", 'rotate_270'), BTEX("stripped_acacia_log", 'rotate_270'), BTEX("stripped_acacia_log", 'rotate_270') ), -- west-east
		["y"] = OpaqueBlock( BTEX("stripped_acacia_log"), BTEX("stripped_acacia_log_top") ), -- top-bottom
		["z"] = OpaqueBlock( BTEX("stripped_acacia_log", 'rotate_90'), BTEX("stripped_acacia_log", 'rotate_270'), BTEX("stripped_acacia_log_top", 'rotate_180'), BTEX("stripped_acacia_log_top"), BTEX("stripped_acacia_log", 'rotate_180'), BTEX("stripped_acacia_log") ) ); -- north-south
	["minecraft:stripped_stripped_birch_log"] = StateAdapter( "axis", -- Stripped Birch Log
		["x"] = OpaqueBlock( BTEX("stripped_birch_log_top"), BTEX("stripped_birch_log_top", 'rotate_180'), BTEX("stripped_birch_log", 'rotate_90'), BTEX("stripped_birch_log", 'rotate_270'), BTEX("stripped_birch_log", 'rotate_270'), BTEX("stripped_birch_log", 'rotate_270') ), -- west-east
		["y"] = OpaqueBlock( BTEX("stripped_birch_log"), BTEX("stripped_birch_log_top") ), -- top-bottom
		["z"] = OpaqueBlock( BTEX("stripped_birch_log", 'rotate_90'), BTEX("stripped_birch_log", 'rotate_270'), BTEX("stripped_birch_log_top", 'rotate_180'), BTEX("stripped_birch_log_top"), BTEX("stripped_birch_log", 'rotate_180'), BTEX("stripped_birch_log") ) ); -- north-south
	["minecraft:stripped_stripped_dark_oak_log"] = StateAdapter( "axis", -- Stripped Dark Oak Log
		["x"] = OpaqueBlock( BTEX("stripped_dark_oak_log_top"), BTEX("stripped_dark_oak_log_top", 'rotate_180'), BTEX("stripped_dark_oak_log", 'rotate_90'), BTEX("stripped_dark_oak_log", 'rotate_270'), BTEX("stripped_dark_oak_log", 'rotate_270'), BTEX("stripped_dark_oak_log", 'rotate_270') ), -- west-east
		["y"] = OpaqueBlock( BTEX("stripped_dark_oak_log"), BTEX("stripped_dark_oak_log_top") ), -- top-bottom
		["z"] = OpaqueBlock( BTEX("stripped_dark_oak_log", 'rotate_90'), BTEX("stripped_dark_oak_log", 'rotate_270'), BTEX("stripped_dark_oak_log_top", 'rotate_180'), BTEX("stripped_dark_oak_log_top"), BTEX("stripped_dark_oak_log", 'rotate_180'), BTEX("stripped_dark_oak_log") ) ); -- north-south
	["minecraft:stripped_stripped_jungle_log"] = StateAdapter( "axis", -- Stripped Jungle Log
		["x"] = OpaqueBlock( BTEX("stripped_jungle_log_top"), BTEX("stripped_jungle_log_top", 'rotate_180'), BTEX("stripped_jungle_log", 'rotate_90'), BTEX("stripped_jungle_log", 'rotate_270'), BTEX("stripped_jungle_log", 'rotate_270'), BTEX("stripped_jungle_log", 'rotate_270') ), -- west-east
		["y"] = OpaqueBlock( BTEX("stripped_jungle_log"), BTEX("stripped_jungle_log_top") ), -- top-bottom
		["z"] = OpaqueBlock( BTEX("stripped_jungle_log", 'rotate_90'), BTEX("stripped_jungle_log", 'rotate_270'), BTEX("stripped_jungle_log_top", 'rotate_180'), BTEX("stripped_jungle_log_top"), BTEX("stripped_jungle_log", 'rotate_180'), BTEX("stripped_jungle_log") ) ); -- north-south
	["minecraft:stripped_stripped_spruce_log"] = StateAdapter( "axis", -- Stripped Spruce Log
		["x"] = OpaqueBlock( BTEX("stripped_spruce_log_top"), BTEX("stripped_spruce_log_top", 'rotate_180'), BTEX("stripped_spruce_log", 'rotate_90'), BTEX("stripped_spruce_log", 'rotate_270'), BTEX("stripped_spruce_log", 'rotate_270'), BTEX("stripped_spruce_log", 'rotate_270') ), -- west-east
		["y"] = OpaqueBlock( BTEX("stripped_spruce_log"), BTEX("stripped_spruce_log_top") ), -- top-bottom
		["z"] = OpaqueBlock( BTEX("stripped_spruce_log", 'rotate_90'), BTEX("stripped_spruce_log", 'rotate_270'), BTEX("stripped_spruce_log_top", 'rotate_180'), BTEX("stripped_spruce_log_top"), BTEX("stripped_spruce_log", 'rotate_180'), BTEX("stripped_spruce_log") ) ); -- north-south
	["minecraft:structure_block"] = StateAdapter( "mode", -- Structure Block
		["corner"]  = OpaqueBlock( BTEX("structure_block_corner") ), -- corner
		["data"]    = OpaqueBlock( BTEX("structure_block_data") ), -- data
		["load"]    = OpaqueBlock( BTEX("structure_block_load") ), -- load
		["save"]    = OpaqueBlock( BTEX("structure_block_save") ) ); -- save

	-- >> T << --
	["minecraft:tall_grass"] = StateAdapter( "half", -- Tall Grass
		["upper"] = XShapedBlock( BTEX("tall_grass_top") ), -- upper half
		["lower"] = XShapedBlock( BTEX("tall_grass_bottom") ); -- lower half
	["minecraft:tall_sea_grass"] = StateAdapter( "half", -- Tall Sea Grass
		["upper"] = HashShapedBlock( -4, BTEX("tall_sea_grass_top"), 0 ), -- upper half
		["lower"] = HashShapedBlock( -4, BTEX("tall_sea_grass_bottom"), 0 ); -- lower half
	["minecraft:terracotta"] = OpaqueBlock( BTEX("terracotta") ); -- Terracotta
	["minecraft:tnt"] = OpaqueBlock( BTEX("tnt_side"), BTEX("tnt_bottom"), BTEX("tnt_top") ); -- TNT
	["minecraft:tube_coral_block"] = OpaqueBlock( BTEX("tube_coral_block") ); -- Tube/Blue Coral Block
	["minecraft:tube_coral"] = XShapedBlock( BTEX("tube_coral") ); -- Tube/Blue Coral Plant
	["minecraft:dead_tube_coral_block"] = OpaqueBlock( BTEX("dead_tube_coral_block") ); -- Tube/Blue Dead Coral Block

	-- >> U << --

	-- >> V << --
	-- ["minecraft:void_air"] (not visible)

	-- >> W << --
	["minecraft:water"] = TransparentBlock( 1, BTEX( "water_flow" ), BTEX( "water_still" ) ); -- Still Water
	["minecraft:wet_sponge"] = OpaqueBlock( BTEX("wet_sponge") ); -- Wet Sponge
	["minecraft:wheat"] = StateAdapter( "age", -- Wheat Crops
		[0] = HashShapedBlock( -4, BTEX("wheat_stage0"), 0 ), -- growthstate 0
		[1] = HashShapedBlock( -4, BTEX("wheat_stage1"), 0 ), -- growthstate 1
		[2] = HashShapedBlock( -4, BTEX("wheat_stage2"), 0 ), -- growthstate 2
		[3] = HashShapedBlock( -4, BTEX("wheat_stage3"), 0 ), -- growthstate 3
		[4] = HashShapedBlock( -4, BTEX("wheat_stage4"), 0 ), -- growthstate 4
		[5] = HashShapedBlock( -4, BTEX("wheat_stage5"), 0 ), -- growthstate 5
		[6] = HashShapedBlock( -4, BTEX("wheat_stage6"), 0 ), -- growthstate 6
		[7] = HashShapedBlock( -4, BTEX("wheat_stage7"), 0 ) ); -- growthstate 7
	["minecraft:white_carpet"] = CompactedBlock( 0, 0, 0, 0, 0, -15, BTEX("white_wool") ); -- White Carpet
	["minecraft:white_concrete"] = OpaqueBlock( BTEX("white_concrete") ); -- White Concrete
	["minecraft:white_concrete_powder"] = OpaqueBlock( BTEX("white_concrete_powder") ); -- White Concrete Powder
	["minecraft:white_glazed_terracotta"] = StateAdapter( "facing", -- White Glazed Terracotta
		["north"] = OpaqueBlock( BTEX("white_glazed_terracotta", 'rotate_180'), BTEX("white_glazed_terracotta"), BTEX("white_glazed_terracotta", 'rotate_90'), BTEX("white_glazed_terracotta", 'rotate_270'), BTEX("white_glazed_terracotta", 'rotate_180'), BTEX("white_glazed_terracotta", 'rotate_180') ), -- facing north
		["east"]  = OpaqueBlock( BTEX("white_glazed_terracotta", 'rotate_270'), BTEX("white_glazed_terracotta", 'rotate_90'), BTEX("white_glazed_terracotta", 'rotate_180'), BTEX("white_glazed_terracotta"), BTEX("white_glazed_terracotta", 'rotate_270'), BTEX("white_glazed_terracotta", 'rotate_90') ), -- facing east
		["south"] = OpaqueBlock( BTEX("white_glazed_terracotta"), BTEX("white_glazed_terracotta", 'rotate_180'), BTEX("white_glazed_terracotta", 'rotate_270'), BTEX("white_glazed_terracotta", 'rotate_90'), BTEX("white_glazed_terracotta"), BTEX("white_glazed_terracotta") ), -- facing south
		["west"]  = OpaqueBlock( BTEX("white_glazed_terracotta", 'rotate_90'), BTEX("white_glazed_terracotta", 'rotate_270'), BTEX("white_glazed_terracotta"), BTEX("white_glazed_terracotta", 'rotate_180'), BTEX("white_glazed_terracotta", 'rotate_90'), BTEX("white_glazed_terracotta", 'rotate_270') ) ); -- facing west
	["minecraft:white_shulker_box"] = StateAdapter( "facing", -- White Shulker Box
		["north"] = OpaqueBlock( BTEX("shulker_white_side_right", 'rotate_90'), BTEX("shulker_white_side_left", 'rotate_270'), BTEX("shulker_white_top"), BTEX("shulker_white_bottom", 'flip_x'), BTEX("shulker_white_side_front", 'rotate_180'), BTEX("shulker_white_side_back") ), -- facing north
		["east"]  = OpaqueBlock( BTEX("shulker_white_bottom", 'flip_x'), BTEX("shulker_white_top"), BTEX("shulker_white_side_right", 'rotate_90'), BTEX("shulker_white_side_left", 'rotate_270'), BTEX("shulker_white_side_front", 'rotate_270'), BTEX("shulker_white_side_back", 'rotate_270') ), -- facing east
		["south"] = OpaqueBlock( BTEX("shulker_white_side_left", 'rotate_270'), BTEX("shulker_white_side_right", 'rotate_90'), BTEX("shulker_white_bottom", 'flip_x'), BTEX("shulker_white_top"), BTEX("shulker_white_side_front"), BTEX("shulker_white_side_back", 'rotate_180') ), -- facing south
		["west"]  = OpaqueBlock( BTEX("shulker_white_top"), BTEX("shulker_white_bottom", 'flip_x'), BTEX("shulker_white_side_left", 'rotate_270'), BTEX("shulker_white_side_right", 'rotate_90'), BTEX("shulker_white_side_front", 'rotate_90'), BTEX("shulker_white_side_back", 'rotate_90') ), -- facing west
		["up"]    = OpaqueBlock( BTEX("shulker_white_side_left"), BTEX("shulker_white_side_right"), BTEX("shulker_white_side_back"), BTEX("shulker_white_side_front"), BTEX("shulker_white_bottom", 'flip_y'), BTEX("shulker_white_top") ), -- facing up
		["down"]  = OpaqueBlock( BTEX("shulker_white_side_left", 'rotate_180'), BTEX("shulker_white_side_right", 'rotate_180'), BTEX("shulker_white_side_front", 'rotate_180'), BTEX("shulker_white_side_back", 'rotate_180'), BTEX("shulker_white_top"), BTEX("shulker_white_bottom", 'flip_y') ) ); -- facing down
	["minecraft:white_tulip"] = XShapedBlock( BTEX("white_tulip") ); -- White Tulip
	["minecraft:white_wool"] = OpaqueBlock( BTEX("white_wool") ); -- White Wool

	-- >> X << --

	-- >> Y << --
	["minecraft:yellow_carpet"] = CompactedBlock( 0, 0, 0, 0, 0, -15, BTEX("yellow_wool") ); -- Yellow Carpet
	["minecraft:yellow_concrete"] = OpaqueBlock( BTEX("yellow_concrete") ); -- Yellow Concrete
	["minecraft:yellow_concrete_powder"] = OpaqueBlock( BTEX("yellow_concrete_powder") ); -- Yellow Concrete Powder
	["minecraft:yellow_glazed_terracotta"] = StateAdapter( "facing", -- Yellow Glazed Terracotta
		["north"] = OpaqueBlock( BTEX("yellow_glazed_terracotta", 'rotate_180'), BTEX("yellow_glazed_terracotta"), BTEX("yellow_glazed_terracotta", 'rotate_90'), BTEX("yellow_glazed_terracotta", 'rotate_270'), BTEX("yellow_glazed_terracotta", 'rotate_180'), BTEX("yellow_glazed_terracotta", 'rotate_180') ), -- facing north
		["east"]  = OpaqueBlock( BTEX("yellow_glazed_terracotta", 'rotate_270'), BTEX("yellow_glazed_terracotta", 'rotate_90'), BTEX("yellow_glazed_terracotta", 'rotate_180'), BTEX("yellow_glazed_terracotta"), BTEX("yellow_glazed_terracotta", 'rotate_270'), BTEX("yellow_glazed_terracotta", 'rotate_90') ), -- facing east
		["south"] = OpaqueBlock( BTEX("yellow_glazed_terracotta"), BTEX("yellow_glazed_terracotta", 'rotate_180'), BTEX("yellow_glazed_terracotta", 'rotate_270'), BTEX("yellow_glazed_terracotta", 'rotate_90'), BTEX("yellow_glazed_terracotta"), BTEX("yellow_glazed_terracotta") ), -- facing south
		["west"]  = OpaqueBlock( BTEX("yellow_glazed_terracotta", 'rotate_90'), BTEX("yellow_glazed_terracotta", 'rotate_270'), BTEX("yellow_glazed_terracotta"), BTEX("yellow_glazed_terracotta", 'rotate_180'), BTEX("yellow_glazed_terracotta", 'rotate_90'), BTEX("yellow_glazed_terracotta", 'rotate_270') ) ); -- facing west	
	["minecraft:yellow_shulker_box"] = StateAdapter( "facing", -- Yellow Shulker Box
		["north"] = OpaqueBlock( BTEX("shulker_yellow_side_right", 'rotate_90'), BTEX("shulker_yellow_side_left", 'rotate_270'), BTEX("shulker_yellow_top"), BTEX("shulker_yellow_bottom", 'flip_x'), BTEX("shulker_yellow_side_front", 'rotate_180'), BTEX("shulker_yellow_side_back") ), -- facing north
		["east"]  = OpaqueBlock( BTEX("shulker_yellow_bottom", 'flip_x'), BTEX("shulker_yellow_top"), BTEX("shulker_yellow_side_right", 'rotate_90'), BTEX("shulker_yellow_side_left", 'rotate_270'), BTEX("shulker_yellow_side_front", 'rotate_270'), BTEX("shulker_yellow_side_back", 'rotate_270') ), -- facing east
		["south"] = OpaqueBlock( BTEX("shulker_yellow_side_left", 'rotate_270'), BTEX("shulker_yellow_side_right", 'rotate_90'), BTEX("shulker_yellow_bottom", 'flip_x'), BTEX("shulker_yellow_top"), BTEX("shulker_yellow_side_front"), BTEX("shulker_yellow_side_back", 'rotate_180') ), -- facing south
		["west"]  = OpaqueBlock( BTEX("shulker_yellow_top"), BTEX("shulker_yellow_bottom", 'flip_x'), BTEX("shulker_yellow_side_left", 'rotate_270'), BTEX("shulker_yellow_side_right", 'rotate_90'), BTEX("shulker_yellow_side_front", 'rotate_90'), BTEX("shulker_yellow_side_back", 'rotate_90') ), -- facing west
		["up"]    = OpaqueBlock( BTEX("shulker_yellow_side_left"), BTEX("shulker_yellow_side_right"), BTEX("shulker_yellow_side_back"), BTEX("shulker_yellow_side_front"), BTEX("shulker_yellow_bottom", 'flip_y'), BTEX("shulker_yellow_top") ), -- facing up
		["down"]  = OpaqueBlock( BTEX("shulker_yellow_side_left", 'rotate_180'), BTEX("shulker_yellow_side_right", 'rotate_180'), BTEX("shulker_yellow_side_front", 'rotate_180'), BTEX("shulker_yellow_side_back", 'rotate_180'), BTEX("shulker_yellow_top"), BTEX("shulker_yellow_bottom", 'flip_y') ) ); -- facing down
	["minecraft:yellow_wool"] = OpaqueBlock( BTEX("yellow_wool") ); -- Yellow Wool

	-- >> Z << --
	
};

MC = {}

-- #### Strings ####
MC.strings = {}
MC.strings.reachedPlayerBlockLimit =	"You have reached your block limit!"
MC.strings.reachedGlobalBlockLimit =	"You have reached the global block limit!"

-- #### Settings ####
MC.healthMul = 1.0				-- Global health multiplier for all blocks
MC.buildDistance = 140			-- Distance where blocks can be placed
MC.deleteDistance = 130			-- Distance where blocks can be deleted
MC.globalBlockLimit = 2048		-- Global block limit
MC.playerBlockLimit = 200		-- Block limit per player
MC.shouldDropOnDie = false		-- Player will drop SWEP on death

MC.onlyDeleteMinecraftBlocks = true		-- Only delete minecraft blocks, doh

-- #### BlockTypes ####

-- Stability settings
local bondToWorld = { 0.0, 10.0, 1.0 } -- Strength of the connection from the block to the world. Vector defined as { Top, Bottom, Sideways }
local bondReduction = { 2.0, 0.5, 1.5 } -- Reduction of the strength of the connection from a block to a block. Vector defined as { Top, Bottom, Sideways }

-- Sound tables
local soundsGravel 	= { Sound("minecraft/gravel1.wav"), Sound("minecraft/gravel2.wav"), Sound("minecraft/gravel3.wav"), Sound("minecraft/gravel4.wav") }
local soundsGrass 	= { Sound("minecraft/grass1.wav"), Sound("minecraft/grass2.wav"), Sound("minecraft/grass3.wav"), Sound("minecraft/grass4.wav") }
local soundsStone 	= { Sound("minecraft/stone1.wav"), Sound("minecraft/stone2.wav"), Sound("minecraft/stone3.wav"), Sound("minecraft/stone4.wav") }
local soundsWood 	= { Sound("minecraft/wood1.wav"), Sound("minecraft/wood2.wav"), Sound("minecraft/wood3.wav"), Sound("minecraft/wood4.wav") }
local soundsSnow 	= { Sound("minecraft/snow1.wav"), Sound("minecraft/snow2.wav"), Sound("minecraft/snow3.wav"), Sound("minecraft/snow4.wav") }
local soundsCloth 	= { Sound("minecraft/cloth1.wav"), Sound("minecraft/cloth2.wav"), Sound("minecraft/cloth3.wav"), Sound("minecraft/cloth4.wav") }
local soundsSand 	= { Sound("minecraft/sand1.wav"), Sound("minecraft/sand2.wav"), Sound("minecraft/sand3.wav"), Sound("minecraft/sand4.wav") }

-- Materials
local matGravel		= { name = "Gravel",	baseHealth = 100,	soundTable = soundsGravel }
local matGrass		= { name = "Grass",		baseHealth = 100,	soundTable = soundsGrass }
local matStone		= { name = "Stone",		baseHealth = 400,	soundTable = soundsStone }
local matWood		= { name = "Wood",		baseHealth = 200,	soundTable = soundsWood }
local matMetal		= { name = "Metal",		baseHealth = 800,	soundTable = soundsStone }
local matSnow		= { name = "Snow",		baseHealth = 50,	soundTable = soundsSnow,	bondReduction = { 5.0, 1.0, 5.0 } }
local matIce		= { name = "Ice",		baseHealth = 50,	soundTable = soundsStone,	transparent = true }
local matWater		= { name = "Water",		baseHealth = -1,	soundTable = soundsStone,	transparent = true }
local matLava		= { name = "Lava",		baseHealth = -1,	soundTable = soundsStone }
local matCloth		= { name = "Cloth",		baseHealth = 100,	soundTable = soundsCloth }
local matSand		= { name = "Sand",		baseHealth = 100,	soundTable = soundsSand,	bondReduction = { 10.0, 1.0, 10.0 } }
local matGlass		= { name = "Glass",		baseHealth = 50,	soundTable = soundsStone,	grasGrowsBelow = true,	transparent = true }
local matObsidian	= { name = "Obsidian",	baseHealth = 1000,	soundTable = soundsStone }
local matBedrock	= { name = "Bedrock",	baseHealth = -1,	soundTable = soundsStone }
local matSponge		= { name = "Sponge",	baseHealth = 50,	soundTable = soundsCloth }
local matOrganic	= { name = "Organic",	baseHealth = 50,	soundTable = soundsGrass }
local matFire		= { name = "Fire",		baseHealth = -1,	soundTable = soundsCloth }

-- Classes of blocks (Geometries like stairs, slabs) TODO: Rename to geom for geometry or something similar
local classCube			= { name = "Cube" }
local classCubeDir		= { name = "Cube with direction",	healthMul = 1.0,	autoRotate = true }
local classSlab			= { name = "Slab",					healthMul = 0.5 }
local classStairs		= { name = "Stairs",				healthMul = 1.0,	autoRotate = true }
local classLiquid		= { name = "Liquid",														noCollide = true }
local classItemBlock	= { name = "Item",					healthMul = 0.2,	autoRotate = true,	noCollide = true }

MC.BlockTypes = {}

local function addBlock( ID, model, options )
	-- Default material is stone
	options.material = options.material or matStone
	options.class = options.class or classCube
	
	MC.BlockTypes[ID] = {}
	MC.BlockTypes[ID].model = model
	MC.BlockTypes[ID].material = options.material
	MC.BlockTypes[ID].class = options.class
	if options.material.baseHealth > 0 then
		MC.BlockTypes[ID].health = options.material.baseHealth * (options.class.healthMul or 1.0) * MC.healthMul
	else
		MC.BlockTypes[ID].health = options.material.baseHealth
	end
	
	-- Stability settings
	MC.BlockTypes[ID].bondToWorld = options.bondToWorld or options.class.bondToWorld or options.material.bondToWorld or bondToWorld
	MC.BlockTypes[ID].bondReduction = options.bondReduction or options.class.bondReduction or options.material.bondReduction or bondReduction
	
	-- Custom settings per block
	MC.BlockTypes[ID].grasGrowsBelow = options.grasGrowsBelow or options.class.grasGrowsBelow or options.material.grasGrowsBelow or false
	MC.BlockTypes[ID].autoRotate = options.autoRotate or options.class.autoRotate or options.material.autoRotate or false
	MC.BlockTypes[ID].contactDamage = options.contactDamage or options.class.contactDamage or options.material.contactDamage or 0
	MC.BlockTypes[ID].ignitePlayer = options.ignitePlayer or options.class.ignitePlayer or options.material.ignitePlayer or false
	MC.BlockTypes[ID].noCollide = options.noCollide or options.class.noCollide or options.material.noCollide or false
end

addBlock(   1, "models/MCModelPack/blocks/dirt.mdl"						, { material = matGravel } )
addBlock(   2, "models/MCModelPack/blocks/grass.mdl"					, { material = matGrass } )
addBlock(   3, "models/MCModelPack/blocks/farmland.mdl"					, { material = matGravel } )
addBlock(   4, "models/MCModelPack/blocks/gravel.mdl"					, { material = matGravel } )
addBlock(   5, "models/MCModelPack/blocks/clay.mdl"						, { material = matGravel } )
addBlock(   6, "models/MCModelPack/blocks/sand.mdl"						, { material = matSand } )
addBlock(   7, "models/MCModelPack/blocks/sandstone.mdl"				, { material = matSand } )
addBlock(   8, "models/MCModelPack/blocks/cobblestone.mdl"				, { } )
addBlock(   9, "models/MCModelPack/blocks/stone.mdl"					, { } )
addBlock(  10, "models/MCModelPack/blocks/ore.mdl"						, { } )
addBlock(  11, "models/MCModelPack/blocks/stoneslabs.mdl"				, { class = classSlab } )
addBlock(  12, "models/MCModelPack/blocks/stonebrick.mdl"				, { } )
addBlock(  13, "models/MCModelPack/blocks/obsidian.mdl"					, { material = matObsidian } )
--addBlock(  14, "models/MCModelPack/blocks/bedrock.mdl"					, { material = matBedrock } )
addBlock(  15, "models/MCModelPack/blocks/brick.mdl"					, { } )
addBlock(  16, "models/MCModelPack/blocks/solidblock.mdl"				, { material = matMetal } )
addBlock(  17, "models/MCModelPack/blocks/snowblock.mdl"				, { material = matSnow } )
addBlock(  18, "models/MCModelPack/blocks/sponge.mdl"					, { material = matSponge } )
addBlock(  19, "models/MCModelPack/blocks/netherrack.mdl"				, { material = matGravel } )
addBlock(  20, "models/MCModelPack/blocks/soulsand.mdl"					, { material = matSand } )
addBlock(  21, "models/MCModelPack/blocks/glowstone.mdl"				, { material = matGlass } )
addBlock(  22, "models/MCModelPack/blocks/glass.mdl"					, { material = matGlass } )
--addBlock(  23, "models/MCModelPack/blocks/dispencer.mdl"				, { class = classCubeDir } )
--addBlock(  24, "models/MCModelPack/blocks/furnace.mdl"					, { class = classCubeDir } )
addBlock(  25, "models/MCModelPack/blocks/chest.mdl"					, { material = matWood, class = classCubeDir } )
addBlock(  26, "models/MCModelPack/blocks/jukebox.mdl"					, { material = matWood } )
addBlock(  27, "models/MCModelPack/blocks/noteblock.mdl"				, { material = matWood } )
addBlock(  28, "models/MCModelPack/blocks/bookshelf.mdl"				, { material = matWood } )
addBlock(  29, "models/MCModelPack/blocks/planks.mdl"					, { material = matWood } )
addBlock(  30, "models/MCModelPack/blocks/workbench.mdl"				, { material = matWood } )
addBlock(  31, "models/MCModelPack/blocks/wood.mdl"						, { material = matWood } )
addBlock(  32, "models/MCModelPack/blocks/cactus.mdl"					, { material = matOrganic, contactDamage = 15.0 } )
addBlock(  33, "models/MCModelPack/blocks/melon.mdl"					, { material = matOrganic } )
addBlock(  34, "models/MCModelPack/blocks/pumpkin.mdl"					, { material = matOrganic, class = classCubeDir } )
--addBlock(  35, "models/MCModelPack/blocks/giantmushroom-base.mdl"		, { material = matOrganic } )
--addBlock(  36, "models/MCModelPack/blocks/giantmushroom-head.mdl"		, { material = matOrganic } )
--addBlock(  37, "models/MCModelPack/blocks/spawner.mdl"					, { material = matMetal } )
addBlock(  38, "models/MCModelPack/blocks/leaves.mdl"					, { material = matOrganic } )
--addBlock(  39, "models/MCModelPack/blocks/tnt.mdl"						, { } )
addBlock(  40, "models/MCModelPack/blocks/ice.mdl"						, { material = matIce } )
addBlock(  41, "models/MCModelPack/blocks/water.mdl"					, { material = matWater } )
--addBlock(  42, "models/MCModelPack/blocks/lava.mdl"						, { material = matLava } )
--addBlock(  43, "models/MCModelPack/blocks/nullblock.mdl"				, { } )
--addBlock(  44, "models/MCModelPack/other_blocks/piston.mdl"				, { material = matStone, } )
addBlock(  45, "models/MCModelPack/other_blocks/stairs-stone.mdl"		, { material = matStone, class = classStairs } )
addBlock(  46, "models/MCModelPack/other_blocks/stairs-brick.mdl"		, { material = matStone, class = classStairs } )
addBlock(  47, "models/MCModelPack/other_blocks/stairs-wood.mdl"		, { material = matWood, class = classStairs } )
--addBlock(  48, "models/MCModelPack/other_blocks/cake.mdl"				, { } )
addBlock(  49, "models/MCModelPack/other_blocks/brickslab.mdl"			, { material = matStone, class = classSlab } )
addBlock(  50, "models/MCModelPack/other_blocks/cobblestoneslab.mdl"	, { material = matStone, class = classSlab } )
addBlock(  51, "models/MCModelPack/other_blocks/stonebrickslab.mdl"		, { material = matStone, class = classSlab } )
addBlock(  52, "models/MCModelPack/other_blocks/stoneslab.mdl"			, { material = matStone, class = classSlab } )
addBlock(  53, "models/MCModelPack/other_blocks/sandstoneslab.mdl"		, { material = matSand, class = classSlab } )
addBlock(  54, "models/MCModelPack/other_blocks/woodenslab.mdl"			, { material = matWood, class = classSlab } )
addBlock(  55, "models/MCModelPack/other_blocks/trapdoor.mdl"			, { grasGrowsBelow = true } )
addBlock(  56, "models/MCModelPack/other_blocks/snow.mdl"				, { material = matSnow } )
--addBlock(  57, "models/MCModelPack/other_blocks/repeater-off.mdl"		, { material = matWood } )
--addBlock(  58, "models/MCModelPack/other_blocks/repeater-on.mdl"		, { material = matWood } )
addBlock(  59, "models/MCModelPack/other_blocks/portal.mdl"				, { grasGrowsBelow = true, autoRotate = true } )
addBlock(  60, "models/MCModelPack/other_blocks/ironbars.mdl"			, { material = matMetal, grasGrowsBelow = true, autoRotate = true } )
addBlock(  61, "models/MCModelPack/other_blocks/glasspane.mdl"			, { material = matGlass, grasGrowsBelow = true, autoRotate = true } )
addBlock(  62, "models/MCModelPack/other_blocks/door-wood.mdl"			, { material = matWood, grasGrowsBelow = true } )
addBlock(  63, "models/MCModelPack/other_blocks/door-iron.mdl"			, { material = matMetal, grasGrowsBelow = true } )
--addBlock(  64, "models/MCModelPack/entities/sign.mdl"					, { material = matWood, grasGrowsBelow = true } )
--addBlock(  65, "models/MCModelPack/entities/wallsign.mdl"				, { material = matWood, grasGrowsBelow = true } )
addBlock(  66, "models/MCModelPack/entities/torch.mdl"					, { material = matWood, grasGrowsBelow = true, noCollide = true } )
--addBlock(  67, "models/MCModelPack/entities/torch-redstone.mdl"			, { material = matWood, grasGrowsBelow = true } )
--addBlock(  68, "models/MCModelPack/entities/lever.mdl"					, { material = matWood, grasGrowsBelow = true } )
addBlock(  69, "models/MCModelPack/entities/fire.mdl"					, { material = matFire, grasGrowsBelow = true, ignitePlayer = true } )
--addBlock(  70, "models/MCModelPack/other_blocks/decoration.mdl"			, { material = matGrass } )
--addBlock(  71, "models/MCModelPack/other_blocks/crops.mdl"				, { material = matGrass } )
addBlock(  72, "models/MCModelPack/other_blocks/ladder.mdl"				, { material = matWood } )
--addBlock(  73, "models/MCModelPack/other_blocks/rail.mdl"				, { material = matWood, autoRotate = true } )
--addBlock(  74, "models/MCModelPack/other_blocks/rail-turn.mdl"			, { amaterial = matWood, utoRotate = true } )
--addBlock(  75, "models/MCModelPack/other_blocks/rail-detector.mdl"		, { material = matWood, autoRotate = true } )
--addBlock(  76, "models/MCModelPack/other_blocks/rail-powered.mdl"		, { material = matWood, autoRotate = true } )
addBlock(  77, "models/MCModelPack/other_blocks/bigchest.mdl"			, { material = matWood, autoRotate = true } )
addBlock(  78, "models/MCModelPack/entities/bed.mdl"					, { material = matWood, autoRotate = true } )
--addBlock(  79, "models/MCModelPack/blocks/cloth-old.mdl"				, { material = matCloth, material = matCloth } )
addBlock(  80, "models/MCModelPack/blocks/cloth-new.mdl"				, { material = matCloth } )
addBlock(  81, "models/MCModelPack/other_blocks/cobweb.mdl"				, { material = matCloth } )
addBlock(  82, "models/MCModelPack/other_blocks/vines.mdl"				, { material = matOrganic, grasGrowsBelow = true } )

--NEW

-- Random
-- addBlock(  83, "models/MCModelPack/mobs/slime.mdl"						, { } )
-- addBlock(  84, "models/MCModelPack/mobs/slime-big.mdl"					, { } )

-- Blocks
-- addBlock(  85, "models/MCModelPack/blocks/lamp.mdl"						, { } )
-- addBlock(  86, "models/MCModelPack/blocks/netherbrick.mdl"				, { } )
-- addBlock(  87, "models/MCModelPack/other_blocks/brewing_stand.mdl"		, { } )
-- addBlock(  88, "models/MCModelPack/other_blocks/cauldron.mdl"			, { } )
-- addBlock(  89, "models/MCModelPack/other_blocks/cocoa_plant-1.mdl"		, { } )
-- addBlock(  90, "models/MCModelPack/other_blocks/cocoa_plant-2.mdl"		, { } )
-- addBlock(  91, "models/MCModelPack/other_blocks/cocoa_plant-3.mdl"		, { } )

-- Entities
-- addBlock(  92, "models/MCModelPack/entities/chest-new.mdl"				, { autoRotate = true } )
-- addBlock(  93, "models/MCModelPack/entities/bigchest-new.mdl"			, { autoRotate = true } )
-- addBlock(  94, "models/MCModelPack/entities/enderchest.mdl"				, { autoRotate = true } )
-- addBlock(  95, "models/MCModelPack/entities/pressure_plate-stone.mdl"	, { } )
-- addBlock(  96, "models/MCModelPack/entities/pressure_plate-wood.mdl"	, { } )
-- addBlock(  97, "models/MCModelPack/entities/pressure_plate-wood.mdl"	, { } )
-- addBlock(  98, "models/MCModelPack/entities/button.mdl"					, { } )

-- Fences
-- addBlock(  99, "models/MCModelPack/fences/fence-1side.mdl"				, { } )
-- addBlock( 100, "models/MCModelPack/fences/fence-2sides.mdl"				, { } )
-- addBlock( 101, "models/MCModelPack/fences/fence-3sides.mdl"				, { } )
-- addBlock( 102, "models/MCModelPack/fences/fence-4sides.mdl"				, { } )
-- addBlock( 103, "models/MCModelPack/fences/fence-corner.mdl"				, { } )
-- addBlock( 104, "models/MCModelPack/fences/fence-gate.mdl"				, { } )
-- addBlock( 105, "models/MCModelPack/fences/fence-gate-open.mdl"			, { } )
-- addBlock( 106, "models/MCModelPack/fences/fence-post.mdl"				, { } )

-- Other blocks
-- addBlock( 107, "models/MCModelPack/other_blocks/netherbrickslab.mdl"	, { } )
-- addBlock( 108, "models/MCModelPack/other_blocks/nethervart.mdl"			, { } )
-- addBlock( 109, "models/MCModelPack/other_blocks/tripwire.mdl"			, { } )

-- Paintings
-- addBlock( 110, "models/MCModelPack/paintings/painting1x1.mdl"			, { } )
-- addBlock( 111, "models/MCModelPack/paintings/painting1x2.mdl"			, { } )
-- addBlock( 112, "models/MCModelPack/paintings/painting2x1.mdl"			, { } )
-- addBlock( 113, "models/MCModelPack/paintings/painting2x2.mdl"			, { } )
-- addBlock( 114, "models/MCModelPack/paintings/painting2x4.mdl"			, { } )
-- addBlock( 115, "models/MCModelPack/paintings/painting3x4.mdl"			, { } )
-- addBlock( 116, "models/MCModelPack/paintings/painting4x4.mdl"			, { } )

-- Redstone
-- addBlock( 117, "models/MCModelPack/redstone/wire0.mdl"					, { } )
-- addBlock( 118, "models/MCModelPack/redstone/wire1.mdl"					, { } )
-- addBlock( 119, "models/MCModelPack/redstone/wire2.mdl"					, { } )
-- addBlock( 120, "models/MCModelPack/redstone/wire3.mdl"					, { } )
-- addBlock( 121, "models/MCModelPack/redstone/wire4.mdl"					, { } )
-- addBlock( 122, "models/MCModelPack/redstone/wire-side.mdl"				, { } )

-- Carrots
-- addBlock( 123, "models/MCModelPack/other_blocks/carrots.mdl"			, { } )

-- Walls
-- addBlock( 124, "models/MCModelPack/fences/wall-1side.mdl"				, { } )
-- addBlock( 125, "models/MCModelPack/fences/wall-2sides.mdl"				, { } )
-- addBlock( 126, "models/MCModelPack/fences/wall-3sides.mdl"				, { } )
-- addBlock( 127, "models/MCModelPack/fences/wall-4sides.mdl"				, { } )
-- addBlock( 128, "models/MCModelPack/fences/wall-corner.mdl"				, { } )
-- addBlock( 129, "models/MCModelPack/fences/wall-post.mdl"				, { } )

-- End stuff
-- addBlock( 130, "models/MCModelPack/entities/anvil.mdl"					, { } )
-- addBlock( 131, "models/MCModelPack/other_blocks/ench_table.mdl"			, { } )
-- addBlock( 132, "models/MCModelPack/other_blocks/endportal.mdl"			, { } )
-- addBlock( 133, "models/MCModelPack/other_blocks/beacon.mdl"				, { } )
-- addBlock( 134, "models/MCModelPack/other_blocks/dragon_egg.mdl"			, { } )

-- Items
-- addBlock( 135, "models/MCModelPack/items/apple.mdl"						, { class = classItemBlock } )
-- addBlock( 136, "models/MCModelPack/items/arrow.mdl"						, { class = classItemBlock } )
-- addBlock( 137, "models/MCModelPack/items/axe.mdl"						, { class = classItemBlock } )
-- addBlock( 138, "models/MCModelPack/items/biscuit.mdl"					, { class = classItemBlock } )
-- addBlock( 139, "models/MCModelPack/items/body.mdl"						, { class = classItemBlock } )
-- addBlock( 140, "models/MCModelPack/items/bone.mdl"						, { class = classItemBlock } )
-- addBlock( 141, "models/MCModelPack/items/boots.mdl"						, { class = classItemBlock } )
-- addBlock( 142, "models/MCModelPack/items/bottle.mdl"					, { class = classItemBlock } )
-- addBlock( 143, "models/MCModelPack/items/bow.mdl"						, { class = classItemBlock } )
-- addBlock( 144, "models/MCModelPack/items/bread.mdl"						, { class = classItemBlock } )
-- addBlock( 145, "models/MCModelPack/items/cake.mdl"						, { class = classItemBlock } )
-- addBlock( 146, "models/MCModelPack/items/clock.mdl"						, { class = classItemBlock } )
-- addBlock( 147, "models/MCModelPack/items/coal.mdl"						, { class = classItemBlock } )
-- addBlock( 148, "models/MCModelPack/items/carrot.mdl"					, { class = classItemBlock } )
-- addBlock( 149, "models/MCModelPack/items/diamond.mdl"					, { class = classItemBlock } )
-- addBlock( 150, "models/MCModelPack/items/dust.mdl"						, { class = classItemBlock } )
-- addBlock( 151, "models/MCModelPack/items/egg.mdl"						, { class = classItemBlock } )
-- addBlock( 152, "models/MCModelPack/items/emerald.mdl"					, { class = classItemBlock } )
-- addBlock( 153, "models/MCModelPack/items/fish.mdl"						, { class = classItemBlock } )
-- addBlock( 154, "models/MCModelPack/items/fishing_rod.mdl"				, { class = classItemBlock } )
-- addBlock( 155, "models/MCModelPack/items/flint.mdl"						, { class = classItemBlock } )
-- addBlock( 156, "models/MCModelPack/items/flint_steel.mdl"				, { class = classItemBlock } )
-- addBlock( 157, "models/MCModelPack/items/helm.mdl"						, { class = classItemBlock } )
-- addBlock( 158, "models/MCModelPack/items/hoe.mdl"						, { class = classItemBlock } )
-- addBlock( 159, "models/MCModelPack/items/ignot.mdl"						, { class = classItemBlock } )
-- addBlock( 160, "models/MCModelPack/items/leggings.mdl"					, { class = classItemBlock } )
-- addBlock( 161, "models/MCModelPack/items/meat.mdl"						, { class = classItemBlock } )
-- addBlock( 162, "models/MCModelPack/items/melon.mdl"						, { class = classItemBlock } )
-- addBlock( 163, "models/MCModelPack/items/pearl.mdl"						, { class = classItemBlock } )
-- addBlock( 164, "models/MCModelPack/items/pickaxe.mdl"					, { class = classItemBlock } )
-- addBlock( 165, "models/MCModelPack/items/record.mdl"					, { class = classItemBlock } )
-- addBlock( 166, "models/MCModelPack/items/ruby.mdl"						, { class = classItemBlock } )
-- addBlock( 167, "models/MCModelPack/items/shears.mdl"					, { class = classItemBlock } )
-- addBlock( 168, "models/MCModelPack/items/shovel.mdl"					, { class = classItemBlock } )
-- addBlock( 169, "models/MCModelPack/items/snowball.mdl"					, { class = classItemBlock } )
-- addBlock( 170, "models/MCModelPack/items/spawnegg.mdl"					, { class = classItemBlock } )
-- addBlock( 171, "models/MCModelPack/items/sword.mdl"						, { class = classItemBlock } )

-- New blocks
-- addBlock( 172, "models/MCModelPack/other_blocks/sunflower.mdl"			, { } )
-- addBlock( 173, "models/MCModelPack/other_blocks/bigplant.mdl"			, { } )
-- addBlock( 174, "models/MCModelPack/other_blocks/comparator-off.mdl"		, { } )
-- addBlock( 175, "models/MCModelPack/other_blocks/comparator-on.mdl"		, { } )
-- addBlock( 176, "models/MCModelPack/other_blocks/repeater-blocked.mdl"	, { } )
-- addBlock( 177, "models/MCModelPack/other_blocks/hopper.mdl"				, { } )
-- addBlock( 178, "models/MCModelPack/other_blocks/hopper-side.mdl"		, { } )
-- addBlock( 179, "models/MCModelPack/other_blocks/string.mdl"				, { autoRotate = true } )
-- addBlock( 180, "models/MCModelPack/other_blocks/quartzslab.mdl"			, { class = classSlab } )
-- addBlock( 181, "models/MCModelPack/other_blocks/stairs-quartz.mdl"		, { class = classStairs } )
-- addBlock( 182, "models/MCModelPack/other_blocks/pot.mdl"				, { } )
-- addBlock( 183, "models/MCModelPack/blocks/hay.mdl"						, { } )
-- addBlock( 184, "models/MCModelPack/blocks/command.mdl"					, { } )
-- addBlock( 185, "models/MCModelPack/blocks/reactor.mdl"					, { } )
-- addBlock( 186, "models/MCModelPack/blocks/ore-quartz.mdl"				, { } )
-- addBlock( 187, "models/MCModelPack/other_blocks/detector-daylight.mdl"	, { } )
-- addBlock( 188, "models/MCModelPack/other_blocks/frame.mdl"				, { autoRotate = true } )
-- addBlock( 189, "models/MCModelPack/other_blocks/heads.mdl"				, { autoRotate = true } )
-- addBlock( 190, "models/MCModelPack/other_blocks/sprout1.mdl"			, { } )
-- addBlock( 191, "models/MCModelPack/other_blocks/sprout2.mdl"			, { } )
-- addBlock( 192, "models/MCModelPack/other_blocks/lily.mdl"				, { autoRotate = true } )
-- addBlock( 193, "models/MCModelPack/items/star.mdl"						, { } )
-- addBlock( 194, "models/MCModelPack/items/rocket.mdl"					, { } )
-- addBlock( 195, "models/MCModelPack/fences/lead.mdl"						, { } )
-- addBlock( 196, "models/MCModelPack/entities/beam.mdl"					, { } )
-- addBlock( 197, "models/MCModelPack/entities/crystal-stand.mdl"			, { } )
-- addBlock( 198, "models/MCModelPack/entities/crystal.mdl"				, { autoRotate = true } )
-- addBlock( 199, "models/MCModelPack/entities/camera.mdl"					, { autoRotate = true } )

--feel free to add more blocks; the blocksize is 36.5 units

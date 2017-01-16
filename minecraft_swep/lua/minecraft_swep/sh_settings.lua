-- #### Strings ####
MC.strings = {}
MC.strings.reachedPlayerBlockLimit =	"You have reached your block limit!"
MC.strings.reachedGlobalBlockLimit =	"You have reached the global block limit!"
MC.strings.refuseBuildByTeam =			"You are too close to a zombie!"
MC.strings.refuseUseToTeam =			"You try to operate the object, but you are not able! You dud!"

-- #### Settings ####
MC.healthMul = 1.0						-- Global health multiplier for all blocks
MC.buildDistance = 140					-- Distance where blocks can be placed
MC.deleteDistance = 130					-- Distance where blocks can be deleted
MC.globalBlockLimit = 2048				-- Global block limit
MC.playerBlockLimit = 200				-- Block limit per player
MC.shouldDropOnDie = false				-- Player will drop SWEP on death
MC.onlyDeleteMinecraftBlocks = true		-- Only delete minecraft blocks, doh

MC.refuseBuildByTeam = 3--TEAM_UNDEAD	-- The team which prevents humans to build, if they are too close
MC.refuseBuildByTeamDistance = 130		-- Distance under which building is denied
MC.refuseUseToTeam = 3--TEAM_UNDEAD		-- The team which isn't allowed to use any MC items/blocks

MC.physTimeout = 0.1					-- Freeze all blocks if the timeout is reached
MC.physTimeoutFrequency = 0.1			-- Frequency of the watchdog timer

-- #### BlockTypes ####

-- Stability settings
local bondToWorld = { 0.0, 10.0, 5.0 }	-- Strength of the connection from the block to the world. Vector defined as { Top, Bottom, Sideways }
local bondReduction = { 2.0, 0.5, 1.5 }	-- Reduction of the strength of the connection from a block to a block. Vector defined as { Top, Bottom, Sideways }

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
local matStone		= { name = "Stone",		baseHealth = 300,	soundTable = soundsStone }
local matWood		= { name = "Wood",		baseHealth = 200,	soundTable = soundsWood }
local matMetal		= { name = "Metal",		baseHealth = 400,	soundTable = soundsStone }
local matSnow		= { name = "Snow",		baseHealth = 50,	soundTable = soundsSnow,	bondReduction = { 5.0, 1.0, 5.0 } }
local matIce		= { name = "Ice",		baseHealth = 50,	soundTable = soundsStone,	transparent = true }
local matWater		= { name = "Water",		baseHealth = -1,	soundTable = soundsStone,	transparent = true }
local matLava		= { name = "Lava",		baseHealth = -1,	soundTable = soundsStone }
local matCloth		= { name = "Cloth",		baseHealth = 100,	soundTable = soundsCloth }
local matSand		= { name = "Sand",		baseHealth = 100,	soundTable = soundsSand,	bondReduction = { 10.0, 1.0, 10.0 } }
local matGlass		= { name = "Glass",		baseHealth = 50,	soundTable = soundsStone,	grasGrowsBelow = true,	transparent = true }
local matObsidian	= { name = "Obsidian",	baseHealth = 800,	soundTable = soundsStone }
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

addBlock(   1, "models/mcmodelpack/blocks/dirt.mdl"						, { material = matGravel } )
addBlock(   2, "models/mcmodelpack/blocks/grass.mdl"					, { material = matGrass } )
addBlock(   3, "models/mcmodelpack/blocks/farmland.mdl"					, { material = matGravel } )
addBlock(   4, "models/mcmodelpack/blocks/gravel.mdl"					, { material = matGravel } )
addBlock(   5, "models/mcmodelpack/blocks/clay.mdl"						, { material = matGravel } )
addBlock(   6, "models/mcmodelpack/blocks/sand.mdl"						, { material = matSand } )
addBlock(   7, "models/mcmodelpack/blocks/sandstone.mdl"				, { material = matSand } )
addBlock(   8, "models/mcmodelpack/blocks/cobblestone.mdl"				, { } )
addBlock(   9, "models/mcmodelpack/blocks/stone.mdl"					, { } )
addBlock(  10, "models/mcmodelpack/blocks/ore.mdl"						, { } )
addBlock(  11, "models/mcmodelpack/blocks/stoneslabs.mdl"				, { class = classSlab } )
addBlock(  12, "models/mcmodelpack/blocks/stonebrick.mdl"				, { } )
--addBlock(  13, "models/mcmodelpack/blocks/obsidian.mdl"					, { material = matObsidian } )
--addBlock(  14, "models/mcmodelpack/blocks/bedrock.mdl"					, { material = matBedrock } )
addBlock(  15, "models/mcmodelpack/blocks/brick.mdl"					, { } )
addBlock(  16, "models/mcmodelpack/blocks/solidblock.mdl"				, { material = matMetal } )
addBlock(  17, "models/mcmodelpack/blocks/snowblock.mdl"				, { material = matSnow } )
addBlock(  18, "models/mcmodelpack/blocks/sponge.mdl"					, { material = matSponge } )
addBlock(  19, "models/mcmodelpack/blocks/netherrack.mdl"				, { material = matGravel } )
addBlock(  20, "models/mcmodelpack/blocks/soulsand.mdl"					, { material = matSand } )
addBlock(  21, "models/mcmodelpack/blocks/glowstone.mdl"				, { material = matGlass } )
addBlock(  22, "models/mcmodelpack/blocks/glass.mdl"					, { material = matGlass } )
--addBlock(  23, "models/mcmodelpack/blocks/dispencer.mdl"				, { class = classCubeDir } )
--addBlock(  24, "models/mcmodelpack/blocks/furnace.mdl"					, { class = classCubeDir } )
addBlock(  25, "models/mcmodelpack/blocks/chest.mdl"					, { material = matWood, class = classCubeDir } )
addBlock(  26, "models/mcmodelpack/blocks/jukebox.mdl"					, { material = matWood } )
addBlock(  27, "models/mcmodelpack/blocks/noteblock.mdl"				, { material = matWood } )
addBlock(  28, "models/mcmodelpack/blocks/bookshelf.mdl"				, { material = matWood } )
addBlock(  29, "models/mcmodelpack/blocks/planks.mdl"					, { material = matWood } )
addBlock(  30, "models/mcmodelpack/blocks/workbench.mdl"				, { material = matWood } )
addBlock(  31, "models/mcmodelpack/blocks/wood.mdl"						, { material = matWood } )
addBlock(  32, "models/mcmodelpack/blocks/cactus.mdl"					, { material = matOrganic, contactDamage = 15.0 } )
addBlock(  33, "models/mcmodelpack/blocks/melon.mdl"					, { material = matOrganic } )
addBlock(  34, "models/mcmodelpack/blocks/pumpkin.mdl"					, { material = matOrganic, class = classCubeDir } )
--addBlock(  35, "models/mcmodelpack/blocks/giantmushroom-base.mdl"		, { material = matOrganic } )
--addBlock(  36, "models/mcmodelpack/blocks/giantmushroom-head.mdl"		, { material = matOrganic } )
--addBlock(  37, "models/mcmodelpack/blocks/spawner.mdl"					, { material = matMetal } )
addBlock(  38, "models/mcmodelpack/blocks/leaves.mdl"					, { material = matOrganic } )
--addBlock(  39, "models/mcmodelpack/blocks/tnt.mdl"						, { } )
addBlock(  40, "models/mcmodelpack/blocks/ice.mdl"						, { material = matIce } )
--addBlock(  41, "models/mcmodelpack/blocks/water.mdl"					, { material = matWater } )
--addBlock(  42, "models/mcmodelpack/blocks/lava.mdl"						, { material = matLava } )
--addBlock(  43, "models/mcmodelpack/blocks/nullblock.mdl"				, { } )
--addBlock(  44, "models/mcmodelpack/other_blocks/piston.mdl"				, { material = matStone, } )
addBlock(  45, "models/mcmodelpack/other_blocks/stairs-stone.mdl"		, { material = matStone, class = classStairs } )
addBlock(  46, "models/mcmodelpack/other_blocks/stairs-brick.mdl"		, { material = matStone, class = classStairs } )
addBlock(  47, "models/mcmodelpack/other_blocks/stairs-wood.mdl"		, { material = matWood, class = classStairs } )
--addBlock(  48, "models/mcmodelpack/other_blocks/cake.mdl"				, { } )
addBlock(  49, "models/mcmodelpack/other_blocks/brickslab.mdl"			, { material = matStone, class = classSlab } )
addBlock(  50, "models/mcmodelpack/other_blocks/cobblestoneslab.mdl"	, { material = matStone, class = classSlab } )
addBlock(  51, "models/mcmodelpack/other_blocks/stonebrickslab.mdl"		, { material = matStone, class = classSlab } )
addBlock(  52, "models/mcmodelpack/other_blocks/stoneslab.mdl"			, { material = matStone, class = classSlab } )
addBlock(  53, "models/mcmodelpack/other_blocks/sandstoneslab.mdl"		, { material = matSand, class = classSlab } )
addBlock(  54, "models/mcmodelpack/other_blocks/woodenslab.mdl"			, { material = matWood, class = classSlab } )
addBlock(  55, "models/mcmodelpack/other_blocks/trapdoor.mdl"			, { grasGrowsBelow = true } )
addBlock(  56, "models/mcmodelpack/other_blocks/snow.mdl"				, { material = matSnow } )
--addBlock(  57, "models/mcmodelpack/other_blocks/repeater-off.mdl"		, { material = matWood } )
--addBlock(  58, "models/mcmodelpack/other_blocks/repeater-on.mdl"		, { material = matWood } )
addBlock(  59, "models/mcmodelpack/other_blocks/portal.mdl"				, { grasGrowsBelow = true, autoRotate = true } )
addBlock(  60, "models/mcmodelpack/other_blocks/ironbars.mdl"			, { material = matMetal, grasGrowsBelow = true, autoRotate = true } )
addBlock(  61, "models/mcmodelpack/other_blocks/glasspane.mdl"			, { material = matGlass, grasGrowsBelow = true, autoRotate = true } )
addBlock(  62, "models/mcmodelpack/other_blocks/door-wood.mdl"			, { material = matWood, grasGrowsBelow = true } )
addBlock(  63, "models/mcmodelpack/other_blocks/door-iron.mdl"			, { material = matMetal, grasGrowsBelow = true } )
--addBlock(  64, "models/mcmodelpack/entities/sign.mdl"					, { material = matWood, grasGrowsBelow = true } )
--addBlock(  65, "models/mcmodelpack/entities/wallsign.mdl"				, { material = matWood, grasGrowsBelow = true } )
addBlock(  66, "models/mcmodelpack/entities/torch.mdl"					, { material = matWood, grasGrowsBelow = true, noCollide = true } )
--addBlock(  67, "models/mcmodelpack/entities/torch-redstone.mdl"			, { material = matWood, grasGrowsBelow = true } )
--addBlock(  68, "models/mcmodelpack/entities/lever.mdl"					, { material = matWood, grasGrowsBelow = true } )
--addBlock(  69, "models/mcmodelpack/entities/fire.mdl"					, { material = matFire, grasGrowsBelow = true, ignitePlayer = true } )
--addBlock(  70, "models/mcmodelpack/other_blocks/decoration.mdl"			, { material = matGrass } )
--addBlock(  71, "models/mcmodelpack/other_blocks/crops.mdl"				, { material = matGrass } )
addBlock(  72, "models/mcmodelpack/other_blocks/ladder.mdl"				, { material = matWood } )
--addBlock(  73, "models/mcmodelpack/other_blocks/rail.mdl"				, { material = matWood, autoRotate = true } )
--addBlock(  74, "models/mcmodelpack/other_blocks/rail-turn.mdl"			, { amaterial = matWood, utoRotate = true } )
--addBlock(  75, "models/mcmodelpack/other_blocks/rail-detector.mdl"		, { material = matWood, autoRotate = true } )
--addBlock(  76, "models/mcmodelpack/other_blocks/rail-powered.mdl"		, { material = matWood, autoRotate = true } )
addBlock(  77, "models/mcmodelpack/other_blocks/bigchest.mdl"			, { material = matWood, autoRotate = true } )
addBlock(  78, "models/mcmodelpack/entities/bed.mdl"					, { material = matWood, autoRotate = true } )
--addBlock(  79, "models/mcmodelpack/blocks/cloth-old.mdl"				, { material = matCloth, material = matCloth } )
addBlock(  80, "models/mcmodelpack/blocks/cloth-new.mdl"				, { material = matCloth } )
--addBlock(  81, "models/mcmodelpack/other_blocks/cobweb.mdl"				, { material = matCloth } )
addBlock(  82, "models/mcmodelpack/other_blocks/vines.mdl"				, { material = matOrganic, grasGrowsBelow = true } )

--NEW

-- Random
-- addBlock(  83, "models/mcmodelpack/mobs/slime.mdl"						, { } )
-- addBlock(  84, "models/mcmodelpack/mobs/slime-big.mdl"					, { } )

-- Blocks
-- addBlock(  85, "models/mcmodelpack/blocks/lamp.mdl"						, { } )
-- addBlock(  86, "models/mcmodelpack/blocks/netherbrick.mdl"				, { } )
-- addBlock(  87, "models/mcmodelpack/other_blocks/brewing_stand.mdl"		, { } )
-- addBlock(  88, "models/mcmodelpack/other_blocks/cauldron.mdl"			, { } )
-- addBlock(  89, "models/mcmodelpack/other_blocks/cocoa_plant-1.mdl"		, { } )
-- addBlock(  90, "models/mcmodelpack/other_blocks/cocoa_plant-2.mdl"		, { } )
-- addBlock(  91, "models/mcmodelpack/other_blocks/cocoa_plant-3.mdl"		, { } )

-- Entities
-- addBlock(  92, "models/mcmodelpack/entities/chest-new.mdl"				, { autoRotate = true } )
-- addBlock(  93, "models/mcmodelpack/entities/bigchest-new.mdl"			, { autoRotate = true } )
-- addBlock(  94, "models/mcmodelpack/entities/enderchest.mdl"				, { autoRotate = true } )
-- addBlock(  95, "models/mcmodelpack/entities/pressure_plate-stone.mdl"	, { } )
-- addBlock(  96, "models/mcmodelpack/entities/pressure_plate-wood.mdl"	, { } )
-- addBlock(  97, "models/mcmodelpack/entities/pressure_plate-wood.mdl"	, { } )
-- addBlock(  98, "models/mcmodelpack/entities/button.mdl"					, { } )

-- Fences
-- addBlock(  99, "models/mcmodelpack/fences/fence-1side.mdl"				, { } )
-- addBlock( 100, "models/mcmodelpack/fences/fence-2sides.mdl"				, { } )
-- addBlock( 101, "models/mcmodelpack/fences/fence-3sides.mdl"				, { } )
-- addBlock( 102, "models/mcmodelpack/fences/fence-4sides.mdl"				, { } )
-- addBlock( 103, "models/mcmodelpack/fences/fence-corner.mdl"				, { } )
-- addBlock( 104, "models/mcmodelpack/fences/fence-gate.mdl"				, { } )
-- addBlock( 105, "models/mcmodelpack/fences/fence-gate-open.mdl"			, { } )
-- addBlock( 106, "models/mcmodelpack/fences/fence-post.mdl"				, { } )

-- Other blocks
-- addBlock( 107, "models/mcmodelpack/other_blocks/netherbrickslab.mdl"	, { } )
-- addBlock( 108, "models/mcmodelpack/other_blocks/nethervart.mdl"			, { } )
-- addBlock( 109, "models/mcmodelpack/other_blocks/tripwire.mdl"			, { } )

-- Paintings
-- addBlock( 110, "models/mcmodelpack/paintings/painting1x1.mdl"			, { } )
-- addBlock( 111, "models/mcmodelpack/paintings/painting1x2.mdl"			, { } )
-- addBlock( 112, "models/mcmodelpack/paintings/painting2x1.mdl"			, { } )
-- addBlock( 113, "models/mcmodelpack/paintings/painting2x2.mdl"			, { } )
-- addBlock( 114, "models/mcmodelpack/paintings/painting2x4.mdl"			, { } )
-- addBlock( 115, "models/mcmodelpack/paintings/painting3x4.mdl"			, { } )
-- addBlock( 116, "models/mcmodelpack/paintings/painting4x4.mdl"			, { } )

-- Redstone
-- addBlock( 117, "models/mcmodelpack/redstone/wire0.mdl"					, { } )
-- addBlock( 118, "models/mcmodelpack/redstone/wire1.mdl"					, { } )
-- addBlock( 119, "models/mcmodelpack/redstone/wire2.mdl"					, { } )
-- addBlock( 120, "models/mcmodelpack/redstone/wire3.mdl"					, { } )
-- addBlock( 121, "models/mcmodelpack/redstone/wire4.mdl"					, { } )
-- addBlock( 122, "models/mcmodelpack/redstone/wire-side.mdl"				, { } )

-- Carrots
-- addBlock( 123, "models/mcmodelpack/other_blocks/carrots.mdl"			, { } )

-- Walls
-- addBlock( 124, "models/mcmodelpack/fences/wall-1side.mdl"				, { } )
-- addBlock( 125, "models/mcmodelpack/fences/wall-2sides.mdl"				, { } )
-- addBlock( 126, "models/mcmodelpack/fences/wall-3sides.mdl"				, { } )
-- addBlock( 127, "models/mcmodelpack/fences/wall-4sides.mdl"				, { } )
-- addBlock( 128, "models/mcmodelpack/fences/wall-corner.mdl"				, { } )
-- addBlock( 129, "models/mcmodelpack/fences/wall-post.mdl"				, { } )

-- End stuff
-- addBlock( 130, "models/mcmodelpack/entities/anvil.mdl"					, { } )
-- addBlock( 131, "models/mcmodelpack/other_blocks/ench_table.mdl"			, { } )
-- addBlock( 132, "models/mcmodelpack/other_blocks/endportal.mdl"			, { } )
-- addBlock( 133, "models/mcmodelpack/other_blocks/beacon.mdl"				, { } )
-- addBlock( 134, "models/mcmodelpack/other_blocks/dragon_egg.mdl"			, { } )

-- Items
-- addBlock( 135, "models/mcmodelpack/items/apple.mdl"						, { class = classItemBlock } )
-- addBlock( 136, "models/mcmodelpack/items/arrow.mdl"						, { class = classItemBlock } )
-- addBlock( 137, "models/mcmodelpack/items/axe.mdl"						, { class = classItemBlock } )
-- addBlock( 138, "models/mcmodelpack/items/biscuit.mdl"					, { class = classItemBlock } )
-- addBlock( 139, "models/mcmodelpack/items/body.mdl"						, { class = classItemBlock } )
-- addBlock( 140, "models/mcmodelpack/items/bone.mdl"						, { class = classItemBlock } )
-- addBlock( 141, "models/mcmodelpack/items/boots.mdl"						, { class = classItemBlock } )
-- addBlock( 142, "models/mcmodelpack/items/bottle.mdl"					, { class = classItemBlock } )
-- addBlock( 143, "models/mcmodelpack/items/bow.mdl"						, { class = classItemBlock } )
-- addBlock( 144, "models/mcmodelpack/items/bread.mdl"						, { class = classItemBlock } )
-- addBlock( 145, "models/mcmodelpack/items/cake.mdl"						, { class = classItemBlock } )
-- addBlock( 146, "models/mcmodelpack/items/clock.mdl"						, { class = classItemBlock } )
-- addBlock( 147, "models/mcmodelpack/items/coal.mdl"						, { class = classItemBlock } )
-- addBlock( 148, "models/mcmodelpack/items/carrot.mdl"					, { class = classItemBlock } )
-- addBlock( 149, "models/mcmodelpack/items/diamond.mdl"					, { class = classItemBlock } )
-- addBlock( 150, "models/mcmodelpack/items/dust.mdl"						, { class = classItemBlock } )
-- addBlock( 151, "models/mcmodelpack/items/egg.mdl"						, { class = classItemBlock } )
-- addBlock( 152, "models/mcmodelpack/items/emerald.mdl"					, { class = classItemBlock } )
-- addBlock( 153, "models/mcmodelpack/items/fish.mdl"						, { class = classItemBlock } )
-- addBlock( 154, "models/mcmodelpack/items/fishing_rod.mdl"				, { class = classItemBlock } )
-- addBlock( 155, "models/mcmodelpack/items/flint.mdl"						, { class = classItemBlock } )
-- addBlock( 156, "models/mcmodelpack/items/flint_steel.mdl"				, { class = classItemBlock } )
-- addBlock( 157, "models/mcmodelpack/items/helm.mdl"						, { class = classItemBlock } )
-- addBlock( 158, "models/mcmodelpack/items/hoe.mdl"						, { class = classItemBlock } )
-- addBlock( 159, "models/mcmodelpack/items/ignot.mdl"						, { class = classItemBlock } )
-- addBlock( 160, "models/mcmodelpack/items/leggings.mdl"					, { class = classItemBlock } )
-- addBlock( 161, "models/mcmodelpack/items/meat.mdl"						, { class = classItemBlock } )
-- addBlock( 162, "models/mcmodelpack/items/melon.mdl"						, { class = classItemBlock } )
-- addBlock( 163, "models/mcmodelpack/items/pearl.mdl"						, { class = classItemBlock } )
-- addBlock( 164, "models/mcmodelpack/items/pickaxe.mdl"					, { class = classItemBlock } )
-- addBlock( 165, "models/mcmodelpack/items/record.mdl"					, { class = classItemBlock } )
-- addBlock( 166, "models/mcmodelpack/items/ruby.mdl"						, { class = classItemBlock } )
-- addBlock( 167, "models/mcmodelpack/items/shears.mdl"					, { class = classItemBlock } )
-- addBlock( 168, "models/mcmodelpack/items/shovel.mdl"					, { class = classItemBlock } )
-- addBlock( 169, "models/mcmodelpack/items/snowball.mdl"					, { class = classItemBlock } )
-- addBlock( 170, "models/mcmodelpack/items/spawnegg.mdl"					, { class = classItemBlock } )
-- addBlock( 171, "models/mcmodelpack/items/sword.mdl"						, { class = classItemBlock } )

-- New blocks
-- addBlock( 172, "models/mcmodelpack/other_blocks/sunflower.mdl"			, { } )
-- addBlock( 173, "models/mcmodelpack/other_blocks/bigplant.mdl"			, { } )
-- addBlock( 174, "models/mcmodelpack/other_blocks/comparator-off.mdl"		, { } )
-- addBlock( 175, "models/mcmodelpack/other_blocks/comparator-on.mdl"		, { } )
-- addBlock( 176, "models/mcmodelpack/other_blocks/repeater-blocked.mdl"	, { } )
-- addBlock( 177, "models/mcmodelpack/other_blocks/hopper.mdl"				, { } )
-- addBlock( 178, "models/mcmodelpack/other_blocks/hopper-side.mdl"		, { } )
-- addBlock( 179, "models/mcmodelpack/other_blocks/string.mdl"				, { autoRotate = true } )
-- addBlock( 180, "models/mcmodelpack/other_blocks/quartzslab.mdl"			, { class = classSlab } )
-- addBlock( 181, "models/mcmodelpack/other_blocks/stairs-quartz.mdl"		, { class = classStairs } )
-- addBlock( 182, "models/mcmodelpack/other_blocks/pot.mdl"				, { } )
-- addBlock( 183, "models/mcmodelpack/blocks/hay.mdl"						, { } )
-- addBlock( 184, "models/mcmodelpack/blocks/command.mdl"					, { } )
-- addBlock( 185, "models/mcmodelpack/blocks/reactor.mdl"					, { } )
-- addBlock( 186, "models/mcmodelpack/blocks/ore-quartz.mdl"				, { } )
-- addBlock( 187, "models/mcmodelpack/other_blocks/detector-daylight.mdl"	, { } )
-- addBlock( 188, "models/mcmodelpack/other_blocks/frame.mdl"				, { autoRotate = true } )
-- addBlock( 189, "models/mcmodelpack/other_blocks/heads.mdl"				, { autoRotate = true } )
-- addBlock( 190, "models/mcmodelpack/other_blocks/sprout1.mdl"			, { } )
-- addBlock( 191, "models/mcmodelpack/other_blocks/sprout2.mdl"			, { } )
-- addBlock( 192, "models/mcmodelpack/other_blocks/lily.mdl"				, { autoRotate = true } )
-- addBlock( 193, "models/mcmodelpack/items/star.mdl"						, { } )
-- addBlock( 194, "models/mcmodelpack/items/rocket.mdl"					, { } )
-- addBlock( 195, "models/mcmodelpack/fences/lead.mdl"						, { } )
-- addBlock( 196, "models/mcmodelpack/entities/beam.mdl"					, { } )
-- addBlock( 197, "models/mcmodelpack/entities/crystal-stand.mdl"			, { } )
-- addBlock( 198, "models/mcmodelpack/entities/crystal.mdl"				, { autoRotate = true } )
-- addBlock( 199, "models/mcmodelpack/entities/camera.mdl"					, { autoRotate = true } )

--feel free to add more blocks; the blocksize is 36.5 units
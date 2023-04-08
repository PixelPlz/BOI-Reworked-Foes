BetterMonsters = RegisterMod("Better Vanilla Monsters", 1)
local mod = BetterMonsters

--[[ New entity enums ]]--
IRFentities = {
	-- Projectiles
	featherProjectile = Isaac.GetEntityVariantByName("Angelic Feather Projectile"),

	-- Enemies
	bubbleFly 	  = Isaac.GetEntityVariantByName("Bubble Fly"),
	teratomar 	  = Isaac.GetEntityVariantByName("Teratomar"),
	coffer 		  = Isaac.GetEntityVariantByName("Coffer"),
	forgottenBody = Isaac.GetEntityVariantByName("Forgotten Body (Boss)"),
	boneOrbital   = Isaac.GetEntityVariantByName("Enemy Bone Orbital"),
	mullicocoon   = Isaac.GetEntityVariantByName("Mullicocoon"),
	ragPlasma 	  = Isaac.GetEntityVariantByName("Rag Mega Plasma"),

	-- Effects
	healingAura    = Isaac.GetEntityVariantByName("Healing Aura"),
	holyTracer 	   = Isaac.GetEntityVariantByName("Holy Tracer"),
	brimstoneSwirl = Isaac.GetEntityVariantByName("Single Laser Brimstone Swirl"),
}



--[[ Colors ]]--
-- Bullets
brimstoneBulletColor = Color(1,0.25,0.25, 1, 0.25,0,0)

tarBulletColor = Color(0.5,0.5,0.5, 1, 0,0,0)
tarBulletColor:SetColorize(1, 1, 1, 1)

skyBulletColor = Color(1,1,1, 1, 0.55,0.55,0.55)
skyBulletColor:SetColorize(1, 1, 1, 1)

greenBulletColor = Color(1,1,1, 1, 0,0,0)
greenBulletColor:SetColorize(0, 1, 0, 1)

corpseGreenBulletColor = Color(1,1,1, 1, 0,0,0)
corpseGreenBulletColor:SetColorize(0.7, 1.25, 0.6, 1)
corpseGreenBulletTrail = Color(1,1,1, 1, 0,0,0)
corpseGreenBulletTrail:SetColorize(0.7, 1.25, 0.6, 1.75)

charredMeatColor = Color(1,1,1, 1, 0,0,0)
charredMeatColor:SetColorize(0.4,0.2,0.17, 1)

portalBulletColor = Color(0.5,0.5,0.7, 1, 0.05,0.05,0.125)
portalBulletTrail = Color(0,0,0, 1, 0.4,0.4,0.6)

forgottenBoneColor = Color(0.34,0.34,0.34, 1)
forgottenBulletColor = Color(0.8,0.8,0.8, 0.7, 0.1,0.2,0.4)
lostBulletColor = Color(1,1,1, 0.7, 0.25,0.25,0.25)

-- Misc.
sunBeamColor = Color(1,1,1, 1, 0.3,0.3,0)

ragManPsyColor = Color(0,0,0, 1, 0.6,0.1,0.6)
ragManBloodColor = Color(0,0,0, 1, 0.35,0.1,0.35)

ghostGibs = Color(1,1,1, 0.25, 1,1,1)
ghostTrailColor = Color(1,1,1, 0.25, 0.5,0.5,0.5)
ghostTrailColor:SetColorize(1, 1, 1, 1)

dustColor = Color(0.8,0.8,0.8, 0.8, 0.05,0.025,0)
dustColor:SetColorize(1, 1, 1, 1)

portalSpawnColor = Color(0.2,0.2,0.3, 0, 1.5,0.75,3)





--[[ Useful functions ]]--
-- Lerp functions
function mod:Lerp(first, second, percent)
	return (first + (second - first) * percent)
end

function mod:StopLerp(vector)
	return mod:Lerp(vector, Vector.Zero, 0.25)
end


-- Looping animation helpers
function mod:LoopingAnim(sprite, anim)
	if not sprite:IsPlaying(anim) then
		sprite:Play(anim, true)
	end
end

function mod:LoopingOverlay(sprite, anim, priority)
	if not sprite:IsOverlayPlaying(anim) then
		if priority then
			sprite:SetOverlayRenderPriority(priority)
		end
		sprite:PlayOverlay(anim, true)
	end
end


-- Shooting effect helper
function mod:shootEffect(entity, subtype, offset, color, scale, behind)
	local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BLOOD_EXPLOSION, subtype, entity.Position, Vector.Zero, entity):ToEffect()
	local sprite = effect:GetSprite()
	effect:FollowParent(entity)

	if subtype == 5 then
		sprite.PlaybackSpeed = 1.5
	end
	if offset then
		sprite.Offset = offset
	end
	if color then
		sprite.Color = color
	end
	if scale then
		effect.Scale = scale
	end
	if behind == true then
		effect.DepthOffset = entity.DepthOffset - 10
	else
		effect.DepthOffset = entity.DepthOffset + 10
	end
	
	return effect
end


-- Creep spawning helper
function mod:QuickCreep(type, spawner, position, scale, timeout)
	local creep = Isaac.Spawn(EntityType.ENTITY_EFFECT, type, 0, position, Vector.Zero, spawner):ToEffect()
	if scale then
		creep.SpriteScale = Vector(scale, scale)
	end
	if timeout then
		creep:SetTimeout(timeout)
	end
	creep:Update()
	
	return creep
end


-- Cord spawning helper
function mod:QuickCord(parent, child, anm2)
	local cord = Isaac.Spawn(EntityType.ENTITY_EVIS, 10, 0, parent.Position, Vector.Zero, parent):ToNPC()
	cord.Parent = parent
	cord.Target = child
	parent.Child = cord
	cord.DepthOffset = child.DepthOffset - 150
	
	if anm2 then
		cord:GetSprite():Load("gfx/" .. anm2 .. ".anm2", true)
	end
	
	return cord
end


-- Throw Dip
function mod:ThrowDip(position, spawner, targetPosition, variant, yOffset)
	-- If spawner is friendly
	if spawner:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) and spawner.SpawnerEntity and spawner.SpawnerEntity:ToPlayer() then
		local subtype = 0
		-- Corny
		if variant == 1 or variant == 3 then
			subtype = 2
		-- Brownie
		elseif variant == 2 then
			subtype = 20
		end
		spawner.SpawnerEntity:ToPlayer():ThrowFriendlyDip(subtype, position, targetPosition)

	else
		local spider = EntityNPC.ThrowSpider(position, spawner, targetPosition, false, yOffset)
		spider:GetData().thrownDip = variant

		-- Get the proper animatiom file
		local anm2 = "216.000_dip"
		if variant == 1 then
			anm2 = "216.001_corn"
		elseif variant == 2 then
			anm2 = "216.002_browniecorn"
		elseif variant == 3 then
			anm2 = "216.003_big corn"
		end

		local sprite = spider:GetSprite()
		sprite:Load("gfx/" .. anm2 .. ".anm2", true)
		sprite:Play("Move", true)
	end
end


-- Fire ring attack
function mod:FireRing(entity)
	local ring = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.FIRE_JET, 40, entity.Position, Vector.Zero, entity)
	ring.DepthOffset = entity.DepthOffset - 10
	ring.SpriteScale = Vector(1.35, 1.35)
	SFXManager():Play(SoundEffect.SOUND_FLAMETHROWER_END)

	for i, e in pairs(Isaac.FindInRadius(entity.Position, 65, 40)) do
		local dmg = 0
		if e.Type == EntityType.ENTITY_PLAYER then
			dmg = 1
		end
		e:TakeDamage(dmg, DamageFlag.DAMAGE_FIRE, EntityRef(entity), 0)
	end
	
	return ring
end


-- Revelations compatibility check for minibosses
function mod:CheckForRev()
	if REVEL and REVEL.IsRevelStage(true) then
		return true
	else
		return false
	end
end





--[[ Load scripts ]]--
function mod:LoadScripts(scripts, subfolder)
	if not subfolder then
		subfolder = ""
	end
	for i = 1, #scripts do
		include("scripts." .. subfolder .. "." .. scripts[i])
	end
end

-- General
local generalScripts = {
	"bossHealthBars",
	"configMenu",
	"hiddenEnemies",
	"misc",
	"projectiles",
}
mod:LoadScripts(generalScripts)

-- Enemies
local enemyScripts = {
	"flamingGaper",
	"drownedHive",
	"drownedCharger",
	"dankGlobin",
	"drownedBoomFly",
	"host",
	"hoppers",
	"redMaw",
	"angelicBaby",
	"selflessKnight",
	"pokies",
	"holyLeech",
	"lump",
	"membrain",
	"scarredParaBite",
	"eye",
	"boneOrbital",
	"nest",
	"babyLongLegs",
	"flamingFatty",
	"dankDeathsHead",
	"momsHand",
	"codWorm",
	"skinny",
	"camilloJr",
	"nerveEnding2",
	"psyTumor",
	"fatBat",
	"ragling",
	--"floatingKnight",
	"dartFly",
	"blackBony",
	"blackGlobin",
	"megaClotty",
	--"boneKnight",
	"fleshDeathHead",
	"ulcer",
	"blister",
	"portal",
}
mod:LoadScripts(enemyScripts, "enemies")

-- Minibosses
local minibossScripts = {
	"sloth",
	--"ultraPride",
	"lust",
	"wrath",
	"gluttony",
	"greed",
	"envy",
	"pride",
	"fallenAngels",
}
mod:LoadScripts(minibossScripts, "minibosses")

-- Bosses
local bossScripts = {
	"carrionQueen",
	--"chad",
	"gish",
	"mom",
	"pin",
	"conquest",
	"lokii",
	"teratoma",
	"steven",
	"blightedOvum",
	"satan",
	"maskInfamy",
	--"wretched",
	"daddyLongLegs",
	"blueBaby",
	"hushBaby",
	--"turdlings",
	--"dangle",
	"mrFred",
	--"lamb",
	"stain",
	"forsaken",
	"ragMega",
	--"sisterVis",
}
mod:LoadScripts(bossScripts, "bosses")

-- Champions
local championScripts = {
	"bloat",
	"fallen",
	"headlessHorseman",
	"megaMaw",
}
mod:LoadScripts(championScripts, "champions")
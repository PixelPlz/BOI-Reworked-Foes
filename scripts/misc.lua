local mod = BetterMonsters



--[[ Clotty variants ]]--
function mod:clottyUpdate(entity)
	if entity.Variant ~= 3 and entity.State == NpcState.STATE_ATTACK and entity:GetSprite():GetFrame() > 2 then
		entity.Velocity = Vector.Zero
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.clottyUpdate, EntityType.ENTITY_CLOTTY)

function mod:cloggyUpdate(entity)
	if entity.State == NpcState.STATE_ATTACK and entity:GetSprite():GetFrame() > 2 then
		entity.Velocity = Vector.Zero
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.cloggyUpdate, EntityType.ENTITY_CLOGGY)



--[[ Chubber ]]--
function mod:chubberInit(entity)
	if entity.Variant == 22 then
		entity.Mass = 0.1
		entity:AddEntityFlags(EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
		entity:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.chubberInit, EntityType.ENTITY_VIS)

function mod:chubberUpdate(entity)
	if entity.Variant == 2 then
		local sprite = entity:GetSprite()

		if sprite:IsEventTriggered("Shoot") or sprite:GetFrame() == 62 then
			entity:PlaySound(SoundEffect.SOUND_MEAT_JUMPS, 0.9, 0, false, 1)
			-- Blood effect
			if sprite:IsEventTriggered("Shoot") then
				mod:shootEffect(entity, 2, Vector(0, -14), nil, 0.8, true)
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.chubberUpdate, EntityType.ENTITY_VIS)



--[[ Scarred Guts ]]--
function mod:scarredGutsDeath(entity)
	if entity.Variant == 1 then
		local flesh = Isaac.Spawn(EntityType.ENTITY_LEPER, 1, 0, entity.Position, entity.Velocity * 0.6, entity):ToNPC()
		flesh.State = NpcState.STATE_INIT
		if entity:IsChampion() then
			flesh:MakeChampion(1, entity:GetChampionColorIdx(), true)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.scarredGutsDeath, EntityType.ENTITY_GUTS)



--[[ Fistula Scarred Womb skin ]]--
local function fistulaScarredSkin(entity)
	if IRFconfig.matriarchFistula == true and entity.Variant == 0 then
		if entity.SubType == 0 and Game():GetRoom():GetBackdropType() == BackdropType.SCARRED_WOMB then
			entity.SubType = 1000 -- The subtype that Matriarch fistula pieces use
		end

		if entity.SubType == 1000 then
			local sprite = entity:GetSprite()
			sprite:ReplaceSpritesheet(0, "gfx/bosses/classic/boss_025_fistula_scarred.png")
			sprite:LoadGraphics()
		end
	end
end

function mod:fistulaBigInit(entity)
	fistulaScarredSkin(entity)
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.fistulaBigInit, EntityType.ENTITY_FISTULA_BIG)

function mod:fistulaMediumInit(entity)
	fistulaScarredSkin(entity)
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.fistulaMediumInit, EntityType.ENTITY_FISTULA_MEDIUM)

function mod:fistulaSmallInit(entity)
	fistulaScarredSkin(entity)
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.fistulaSmallInit, EntityType.ENTITY_FISTULA_SMALL)



--[[ Big Spiders ]]--
function mod:bigSpiderInit(entity)
	entity.MaxHitPoints = 13
	entity.HitPoints = entity.MaxHitPoints
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.bigSpiderInit, EntityType.ENTITY_BIGSPIDER)



--[[ Classic eternal flies ]]--
function mod:eternalFlyInit(entity)
	if entity.Type == EntityType.ENTITY_ETERNALFLY or (FiendFolio and entity.Type == FiendFolio.FF.DeadFlyOrbital.ID and entity.Variant == FiendFolio.FF.DeadFlyOrbital.Var) then
		entity:GetData().isEternalFly = true
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.eternalFlyInit)

function mod:eternalFlyUpdate(entity)
	if entity:GetData().isEternalFly and entity.Variant ~= 4040 then
		entity:Morph(EntityType.ENTITY_ATTACKFLY, 4040, 0, entity:GetChampionColorIdx())
		entity.HitPoints = entity.MaxHitPoints
		entity.I1 = 0
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.eternalFlyUpdate, EntityType.ENTITY_ATTACKFLY)



--[[ Thrown Dip ]]--
function mod:thrownDipUpdate(entity)
	local data = entity:GetData()

	if data.thrownDip then
		if entity.State ~= NpcState.STATE_JUMP or entity:IsDead() then
			entity:Morph(EntityType.ENTITY_DIP, data.thrownDip, 0, -1)
			entity:PlaySound(SoundEffect.SOUND_BABY_HURT, 1, 0, false, 1)
			data.thrownDip = nil
			
			entity.State = NpcState.STATE_INIT
			entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
			if entity.Variant == 3 then
				entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NOPITS
			else
				entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.thrownDipUpdate, EntityType.ENTITY_SPIDER)



--[[ Gurglings ]]--
function mod:gurglingsUpdate(entity)
	if entity.State == NpcState.STATE_ATTACK then
		entity:AddEntityFlags(EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
	else
		entity:ClearEntityFlags(EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.gurglingsUpdate, EntityType.ENTITY_GURGLING)



--[[ Red Ghost ]]--
function mod:redGhostUpdate(entity)
	local sprite = entity:GetSprite()
	
	if IRFconfig.laserRedGhost == true and entity.State == NpcState.STATE_ATTACK and sprite:GetFrame() == 0 then
		local vector = 0
		if sprite:GetAnimation() == "ShootDown" then
			vector = 90
		elseif sprite:GetAnimation() == "ShootLeft" then
			vector = 180
		elseif sprite:GetAnimation() == "ShootUp" then
			vector = 270
		end

		local tracer = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.GENERIC_TRACER, 0, entity.Position + Vector(0, entity.SpriteScale.Y * -8), Vector.Zero, entity):ToEffect()
		tracer.LifeSpan = 15
		tracer.Timeout = 1
		tracer.TargetPosition = Vector.FromAngle(vector)
		tracer:GetSprite().Color = Color(1,0,0, 0.25)
		tracer.SpriteScale = Vector(2, 0)
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.redGhostUpdate, EntityType.ENTITY_RED_GHOST)



--[[ Delirium helper ]]--
function mod:deliriumHelper(entity)
	if not entity:GetData().wasDelirium then
		entity:GetData().wasDelirium = true
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.deliriumHelper, EntityType.ENTITY_DELIRIUM)



--[[ Tainted Faceless ]]--
function mod:tFacelessUpdate(entity)
	if entity.Variant == 1 then
		local sprite = entity:GetSprite()

		if sprite:IsOverlayPlaying("Attack") and sprite:GetOverlayFrame() == 14 then
			local params = ProjectileParams()
			params.CircleAngle = 0.5
			params.Scale = 1.5
			entity:FireProjectiles(entity.Position, Vector(5, 6), 9, params)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.tFacelessUpdate, EntityType.ENTITY_FACELESS)



--[[ Evis Cord ]]--
function mod:evisCordUpdate(entity)
	if entity.Variant == 10 and entity.Parent then
		entity.SplatColor = entity.Parent.SplatColor
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.evisCordUpdate, EntityType.ENTITY_EVIS)
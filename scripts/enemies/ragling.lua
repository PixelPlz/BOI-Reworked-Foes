local mod = BetterMonsters

local Settings = {
	SpeedMultiplier = 0.9,
	ShotSpeed = 9,
	Cooldown = 90,
	Range = 200
}



function mod:raglingInit(entity)
	if entity.Variant == 1 then
		entity.MaxHitPoints = 25 -- Same as the HP for Ragman's head
		entity.SplatColor = ragManBloodColor

		if entity.SpawnerType == EntityType.ENTITY_RAG_MAN and entity.SpawnerVariant == 1 and entity.SpawnerEntity then
			entity.HitPoints = entity.SpawnerEntity.HitPoints
		else
			entity.HitPoints = entity.MaxHitPoints
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.raglingInit, EntityType.ENTITY_RAGLING)

function mod:raglingUpdate(entity)
	local sprite = entity:GetSprite()

	if entity:GetChampionColorIdx() == 12 or entity:GetChampionColorIdx() == 20 then
		entity:MakeChampion(1, 6, true)
	end


	-- Better jumping
	entity.Velocity = entity.Velocity * Settings.SpeedMultiplier
	if sprite:IsPlaying("Hop") and sprite:GetFrame() == 22 then
		entity.Velocity = Vector.Zero
		entity.TargetPosition = entity.Position
	end


	-- Attack
	if entity.State == NpcState.STATE_ATTACK then
		entity.State = NpcState.STATE_ATTACK2
		sprite:Play("Attack", true)

	elseif entity.State == NpcState.STATE_ATTACK2 then
		entity.Velocity = Vector.Zero
		entity.TargetPosition = entity.Position

		if sprite:IsEventTriggered("Shoot") then
			local params = ProjectileParams()

			if entity.I1 == 0 then
				params.BulletFlags = ProjectileFlags.ORBIT_CW
				entity.I1 = entity.I1 + 1
			elseif entity.I1 == 1 then
				params.BulletFlags = ProjectileFlags.ORBIT_CCW
				entity.I1 = 0
			end
			-- Red champion raglings don't have homing shots
			if entity.Variant == 0 or (not entity.ParentNPC or entity.ParentNPC.SubType == 0) then
				params.BulletFlags = params.BulletFlags + ProjectileFlags.SMART
			end

			params.TargetPosition = entity.Position
			params.FallingAccelModifier = 0.06
			params.CircleAngle = 0

			entity:FireProjectiles(entity.Position, Vector(Settings.ShotSpeed, 3 - entity.Variant), 9, params)
			entity:PlaySound(SoundEffect.SOUND_BLOODSHOOT, 1, 0, false, 1)
		end

		if sprite:IsFinished("Attack") then
			entity.State = NpcState.STATE_MOVE
		end
	end
	
	
	-- Fix Rag Man's dead raglings rendering above entities
	if entity.Variant == 1 then
		if entity.State == NpcState.STATE_SPECIAL then
			if entity.V2 == Vector.Zero then
				entity.V2 = Vector(entity.DepthOffset, 0)
			end
			entity.DepthOffset = -1000
		
		elseif entity.State == NpcState.STATE_APPEAR_CUSTOM then
			entity.DepthOffset = entity.V2.X
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.raglingUpdate, EntityType.ENTITY_RAGLING)

function mod:raglingDeath(entity)
	if entity.Variant == 0 and entity:GetChampionColorIdx() ~= 15 then
		local rags = Isaac.Spawn(200, 4246, 0, entity.Position, Vector.Zero, nil)
		if entity:IsChampion() then
			rags:ToNPC():MakeChampion(1, entity:GetChampionColorIdx(), true)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.raglingDeath, EntityType.ENTITY_RAGLING)



-- Ragling Rags
function mod:raglingRagsInit(entity)
	if entity.Variant == 4246 then
		entity.ProjectileCooldown = Settings.Cooldown
		entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
		entity:AddEntityFlags(EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK | EntityFlag.FLAG_NO_TARGET | EntityFlag.FLAG_NO_STATUS_EFFECTS)
		entity.DepthOffset = -100

		-- Purple fire
		entity.Child = Isaac.Spawn(EntityType.ENTITY_FIREPLACE, 13, 0, entity.Position, Vector.Zero, entity)
		entity.Child.HitPoints = 4
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.raglingRagsInit, 200)

function mod:raglingRagsUpdate(entity)
	if entity.Variant == 4246 then
		local sprite = entity:GetSprite()
		local target = entity:GetPlayerTarget()

		entity.Velocity = Vector.Zero
		if entity.Child then
			entity.Child.Position = entity.Position
			entity.Child.Velocity = Vector.Zero
			entity.Child:ToNPC().Scale = entity.Scale
		end


		-- Die on room clear
		if entity:GetAliveEnemyCount() <= 0 then
			entity:Kill()
			if entity.Child then
				entity.Child:TakeDamage(100, DamageFlag.DAMAGE_EXPLOSION, EntityRef(nil), 0)
			end
		end


		-- Attack
		if entity.ProjectileCooldown <= 0 then
			if entity.Position:Distance(target.Position) <= Settings.Range and Game():GetRoom():CheckLine(entity.Position, target.Position, 3, 0, false, false) and entity.Child then
				mod:LoopingAnim(sprite, "Attack")
			end
			
			if sprite:IsEventTriggered("Shoot") then
				local params = ProjectileParams()
				params.BulletFlags = ProjectileFlags.SMART
				entity:FireProjectiles(entity.Position, (target.Position - entity.Position):Normalized() * Settings.ShotSpeed, 0, params)
				entity:PlaySound(SoundEffect.SOUND_BLOODSHOOT, 1, 0, false, 1)
				entity.ProjectileCooldown = Settings.Cooldown
			end
		
		else
			entity.ProjectileCooldown = entity.ProjectileCooldown - 1
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.raglingRagsUpdate, 200)

function mod:raglingRagsDMG(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if target.Variant == 4246 then
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.raglingRagsDMG, 200)
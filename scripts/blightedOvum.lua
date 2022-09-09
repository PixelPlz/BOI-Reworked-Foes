local mod = BetterMonsters
local game = Game()

local Settings = {
	DeathShotSpeed = 12,
	TransparencyTimer = 10,
	MoveSpeed = 4.5,
	Cooldown = 150,
	Range = 400,
	PushBackSpeed = 1.25
}



function mod:blightedOvumBabyInit(entity)
	if entity.Variant == 12 then
		entity.ProjectileCooldown = Settings.Cooldown / 2
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.blightedOvumBabyInit, EntityType.ENTITY_GEMINI)

function mod:blightedOvumBabyUpdate(entity)
	if entity.Variant == 12 then
		local sprite = entity:GetSprite()
		local data = entity:GetData()
		local target = entity:GetPlayerTarget()

		
		-- Transparency
		if data.transTimer ~= nil then -- trans rights
			if data.transTimer <= 0 then
				data.transTimer = nil
			else
				sprite.Color = Color(1,1,1, 0.35)
				data.transTimer = data.transTimer - 1
			end
		
		else
			sprite.Color = Color(1,1,1, 0.7)
		end


		if entity.State == NpcState.STATE_MOVE then
			if entity.Parent then
				entity.Velocity = (entity.Parent.Position - entity.Position):Normalized() * Settings.MoveSpeed
			end

			if entity.ProjectileCooldown <= 0 and entity.Position:Distance(target.Position) <= Settings.Range then
				entity.State = NpcState.STATE_ATTACK2
			end


		-- Replace laser attack
		elseif entity.State == NpcState.STATE_ATTACK then
			if entity.ProjectileCooldown > 0 then
				entity.State = NpcState.STATE_MOVE
				sprite:Play("Walk01", true)
			else
				entity.State = NpcState.STATE_ATTACK2
				sprite:Play("Attack01", true)
			end

		-- New laser attack
		elseif entity.State == NpcState.STATE_ATTACK2 then
			mod:LoopingAnim(sprite, "Attack01")

			-- Shoot laser
			if sprite:IsEventTriggered("GetPos") then
				data.angle = (target.Position - entity.Position):GetAngleDegrees()

				local tracer = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.GENERIC_TRACER, 0, entity.Position + (Vector.FromAngle(data.angle) * 10) + Vector(0, entity.SpriteScale.Y * -16), Vector.Zero, entity):ToEffect()
				tracer.LifeSpan = 15
				tracer.Timeout = 1
				tracer.TargetPosition = Vector.FromAngle(data.angle)
				tracer:GetSprite().Color = Color(1,0,0, 0.25)
				tracer.SpriteScale = Vector(2, 0)

			elseif sprite:IsEventTriggered("Shoot") then
				entity:PlaySound(SoundEffect.SOUND_CUTE_GRUNT, 0.9, 0, false, 0.9)
				entity.ProjectileCooldown = Settings.Cooldown

				-- Flip sprite
				if target.Position.X < entity.Position.X then
					sprite.FlipX = true
				elseif target.Position.X > entity.Position.X then
					sprite.FlipX = false
				end

				local laser_ent_pair = {laser = EntityLaser.ShootAngle(1, entity.Position, data.angle, 26, Vector(0, entity.SpriteScale.Y * -38), entity), entity}
				data.brim = laser_ent_pair.laser
				data.brim.DepthOffset = entity.DepthOffset + 10
			
			elseif sprite:IsEventTriggered("Stop") then
				entity.State = NpcState.STATE_MOVE
			end


			-- Push back
			if data.brim then
				if not data.brim:Exists() then
					data.brim = nil
				else
					entity.Velocity = -Vector.FromAngle(data.brim.Angle) * Settings.PushBackSpeed
				end
			else
				entity.Velocity = Vector.Zero
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.blightedOvumBabyUpdate, EntityType.ENTITY_GEMINI)

function mod:blightedOvumBabyDMG(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if target.Variant == 12 then
		target:GetData().transTimer = Settings.TransparencyTimer
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.blightedOvumBabyDMG, EntityType.ENTITY_GEMINI)

function mod:blightedOvumBabyCollide(entity, target, bool)
	if entity.Variant == 12 and target.Type == EntityType.ENTITY_GEMINI then
		return true -- Ignore collision
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.blightedOvumBabyCollide, EntityType.ENTITY_GEMINI)

function mod:blightedOvumDeath(entity)
	if entity.Variant == 2 then
		entity:FireProjectiles(entity.Position, Vector(Settings.DeathShotSpeed, 0), 8, ProjectileParams())
	
	elseif entity.Variant == 12 then
		Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.ENEMY_GHOST, 2, entity.Position, Vector.Zero, entity)
		SFXManager():Play(SoundEffect.SOUND_DEMON_HIT)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.blightedOvumDeath, EntityType.ENTITY_GEMINI)
local mod = BetterMonsters

local Settings = {
	SoundTimer = 30,
	MoveScreenShake = 6,
	MoveSpeed = 5,
	StompShotSpeed = 12,

	HeadSmashSpeed = 16,
	HeadSmashTimer = 30,
	HeadSmashScreenShake = 14,
	HeadSmashShotSpeed = 12
}



function mod:daddyLongLegsInit(entity)
	entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.daddyLongLegsInit, EntityType.ENTITY_DADDYLONGLEGS)

function mod:daddyLongLegsUpdate(entity)
	local sprite = entity:GetSprite()
	local data = entity:GetData()
	local target = entity:GetPlayerTarget()


	-- Triachnid
	if entity.Variant == 1 then
		if not data.timer then
			data.timer = Settings.SoundTimer + 5
		end

		if entity.State == NpcState.STATE_IDLE or entity.State == NpcState.STATE_ATTACK then
			-- Move towards target
			if data.timer <= 0 then
				data.timer = Settings.SoundTimer
				mod:PlaySound(nil, SoundEffect.SOUND_FORESTBOSS_STOMPS, 0.75)
				Game():ShakeScreen(Settings.MoveScreenShake)
			else
				data.timer = data.timer - 1

				if data.timer <= 15 then
					mod:ChasePlayer(entity, Settings.MoveSpeed, true)
				end
			end

		else
			data.timer = 10

			-- Stomp projectiles
			if entity.State == NpcState.STATE_STOMP and sprite:IsEventTriggered("Land") then
				local params = ProjectileParams()
				params.Color = IRFcolors.WhiteShot
				entity:FireProjectiles(entity.Position, Vector(Settings.StompShotSpeed - entity.I2, 0), 6 + entity.I2, params)
			end
		end
	end


	-- For both
	if entity.SpawnerType ~= EntityType.ENTITY_DADDYLONGLEGS then
		sprite.FlipX = false
	end

	if entity.State == NpcState.STATE_STOMP then
		-- Prevent long stomp attack and move to target instead
		if entity.SpawnerType ~= EntityType.ENTITY_DADDYLONGLEGS then
			entity.State = NpcState.STATE_ATTACK5
			sprite:Play("UpLoop", true)
			data.down = Settings.HeadSmashTimer

		-- Align position to grid
		elseif entity.FrameCount <= 1 then
			entity.Position = Game():GetRoom():GetGridPosition(Game():GetRoom():GetGridIndex(entity.Position))
		end


	-- Move to target
	elseif entity.State == NpcState.STATE_ATTACK5 then
		mod:ChasePlayer(entity, Settings.HeadSmashSpeed, true)

		if data.down <= 0 then
			entity.State = NpcState.STATE_APPEAR_CUSTOM
			sprite:Play("Down", true)
		else
			data.down = data.down - 1
		end


	-- Custom head smash
	elseif entity.State == NpcState.STATE_APPEAR_CUSTOM then
		if sprite:IsEventTriggered("Land") then
			entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL

			mod:PlaySound(nil, SoundEffect.SOUND_FORESTBOSS_STOMPS, 1.1)
			mod:PlaySound(nil, SoundEffect.SOUND_HELLBOSS_GROUNDPOUND, 1.1)
			Game():ShakeScreen(Settings.HeadSmashScreenShake)
			Game():MakeShockwave(entity.Position, 0.035, 0.025, 10)

			local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 2, entity.Position, Vector.Zero, entity):ToEffect()
			effect.Scale = 1.5
			effect.DepthOffset = entity.DepthOffset + 10

			local params = ProjectileParams()
			-- Daddy Long Legs
			if entity.Variant == 0 then
				params.Scale = 1.5
				params.CircleAngle = 0.41
				entity:FireProjectiles(entity.Position, Vector(Settings.HeadSmashShotSpeed - 5, 8), 9, params)

			-- Triachnid
			elseif entity.Variant == 1 then
				params.Color = IRFcolors.WhiteShot
				-- Creep
				for i = 1, 4 do
					mod:QuickCreep(EffectVariant.CREEP_WHITE, entity, entity.Position + Vector.FromAngle(i * 80):Resized(50), 2.25)
				end
			end

			params.Scale = 1.25
			entity:FireProjectiles(entity.Position, Vector(Settings.HeadSmashShotSpeed, 0), 8, params)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.daddyLongLegsUpdate, EntityType.ENTITY_DADDYLONGLEGS)

function mod:daddyLongLegsCollide(entity, target, bool)
	if target.Type == EntityType.ENTITY_DADDYLONGLEGS or (target.Type == EntityType.ENTITY_HOPPER and target.Variant == 1) then
		return true -- Ignore collision
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.daddyLongLegsCollide, EntityType.ENTITY_DADDYLONGLEGS)
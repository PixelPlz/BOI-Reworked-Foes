local mod = BetterMonsters
local game = Game()

local Settings = {
	SoundTimer = 30,
	MoveScreenShake = 6,
	MoveSpeed = 5,
	StompShotSpeed = 10,

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
				SFXManager():Play(SoundEffect.SOUND_FORESTBOSS_STOMPS, 0.75)
				game:ShakeScreen(Settings.MoveScreenShake)
			else
				data.timer = data.timer - 1

				if data.timer <= 15 then
					entity.Velocity = mod:Lerp(entity.Velocity, (target.Position - entity.Position):Normalized() * Settings.MoveSpeed, 0.25)
				end
			end

		else
			data.timer = 10

			-- Stomp projectiles
			if entity.State == NpcState.STATE_STOMP and sprite:IsEventTriggered("Land") then
				local params = ProjectileParams()
				params.Color = skyBulletColor
				params.FallingAccelModifier = 0.1

				entity:FireProjectiles(entity.Position, Vector(Settings.StompShotSpeed, 0), 5 + entity.I1 + entity.I2, params)
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
			entity.Position = game:GetRoom():GetGridPosition(game:GetRoom():GetGridIndex(entity.Position))
		end
	
	
	-- Move to target
	elseif entity.State == NpcState.STATE_ATTACK5 then
		entity.Velocity = mod:Lerp(entity.Velocity, (target.Position - entity.Position):Normalized() * Settings.HeadSmashSpeed, 0.25)

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
			SFXManager():Play(SoundEffect.SOUND_FORESTBOSS_STOMPS, 1.1)
			SFXManager():Play(SoundEffect.SOUND_HELLBOSS_GROUNDPOUND, 1.1)
			game:ShakeScreen(Settings.HeadSmashScreenShake)

			local params = ProjectileParams()
			-- Daddy Long Legs
			if entity.Variant == 0 then
				params.Scale = 1.5
				params.CircleAngle = 0.41
				entity:FireProjectiles(entity.Position, Vector(Settings.HeadSmashShotSpeed - 5, 8), 9, params)

			-- Triachnid
			elseif entity.Variant == 1 then
				params.Color = skyBulletColor
				-- Creep
				for i = 1, 4 do
					mod:QuickCreep(EffectVariant.CREEP_WHITE, entity, entity.Position + (Vector.FromAngle(i * 90) * 50), 2.25)
				end
			end

			params.Scale = 1.25
			entity:FireProjectiles(entity.Position, Vector(Settings.HeadSmashShotSpeed, 0), 8, params)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.daddyLongLegsUpdate, EntityType.ENTITY_DADDYLONGLEGS)

function mod:daddyLongLegsCollide(entity, target, bool)
	if target.Type == ENTITY_DADDYLONGLEGS or (target.Type == EntityType.ENTITY_HOPPER and target.Variant == 1) then
		return true -- Ignore collision
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.daddyLongLegsCollide, EntityType.ENTITY_DADDYLONGLEGS)
local mod = BetterMonsters
local game = Game()

local Settings = {
	SoundTimer = 30,
	MoveScreenShake = 6,
	MoveSpeed = 5,
	StompShotSpeed = 9,

	HeadSmashSpeed = 7,
	HeadSmashTimer = 24,
	HeadSmashScreenShake = 14,
	HeadSmashShotSpeed = 12
}



function mod:daddyLongLegsUpdate(entity)
	local sprite = entity:GetSprite()
	local data = entity:GetData()
	local target = entity:GetPlayerTarget()


	-- Triachnid specific
	if entity.Variant == 1 then
		if not data.timer then
			data.timer = Settings.SoundTimer + 5
		end

		if entity.State == NpcState.STATE_IDLE or entity.State == NpcState.STATE_ATTACK then
			if data.timer <= 0 then
				data.timer = Settings.SoundTimer
				SFXManager():Play(SoundEffect.SOUND_FORESTBOSS_STOMPS, 0.75)
				game:ShakeScreen(Settings.MoveScreenShake)
			else
				data.timer = data.timer - 1

				if data.timer <= 15 then
					entity.Velocity = (entity.Velocity + ((target.Position - entity.Position):Normalized() * Settings.MoveSpeed - entity.Velocity) * 0.25)
				end
			end

		else
			entity.Velocity = Vector.Zero
			data.timer = 10

			if entity.State == NpcState.STATE_STOMP and sprite:IsEventTriggered("Land") then
				local params = ProjectileParams()
				params.Color = skyBulletColor
				params.FallingAccelModifier = 0.125

				entity:FireProjectiles(entity.Position, Vector(Settings.StompShotSpeed, 0), 5 + entity.I1 + entity.I2, params)
			end
		end
	end


	-- For both
	if entity.SpawnerType ~= EntityType.ENTITY_DADDYLONGLEGS then
		sprite.FlipX = false
	end

	if sprite:IsPlaying("Up") and sprite:GetFrame() == 0 then
		data.pos = entity.Position
	end

	if entity.State == NpcState.STATE_STOMP then
		if entity.SpawnerType ~= EntityType.ENTITY_DADDYLONGLEGS then
			entity.Visible = false
			sprite:SetFrame(0)
			entity.Velocity = (target.Position - entity.Position):Normalized() * (Settings.HeadSmashSpeed + entity.Variant)

			if not data.down then
				data.down = Settings.HeadSmashTimer

			elseif data.down <= 0 then
				entity.State = NpcState.STATE_MOVE
				sprite:Play("Down", true)
				data.down = nil
				entity.Visible = true

			else
				data.down = data.down - 1
				entity.Visible = true

				if data.pos then
					entity.Position = data.pos
					data.pos = nil
				end
			end
		end

	elseif entity.State == NpcState.STATE_MOVE then
		if sprite:GetFrame() == 5 then
			entity.State = NpcState.STATE_APPEAR_CUSTOM
		end

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
				Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CREEP_WHITE, 0, entity.Position, Vector.Zero, entity):ToEffect().Scale = 1.75
				for i = 0, 8 do
					Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CREEP_WHITE, 0, entity.Position + (Vector.FromAngle(i * 45) * 50), Vector.Zero, entity):ToEffect().Scale = 1.75
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
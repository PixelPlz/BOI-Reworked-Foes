local mod = BetterMonsters

local Settings = {
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
	if entity.Variant == 0 then
		local sprite = entity:GetSprite()
		local data = entity:GetData()


		-- Don't flip the sprite from movement
		if entity.SpawnerType ~= EntityType.ENTITY_DADDYLONGLEGS then
			sprite.FlipX = false
		end

		if entity.State == NpcState.STATE_STOMP then
			-- Prevent long stomp attack and move to target instead
			if entity.SpawnerType ~= EntityType.ENTITY_DADDYLONGLEGS then
				entity.State = NpcState.STATE_ATTACK5
				sprite:Play("UpLoop", true)
				data.down = Settings.HeadSmashTimer

			-- Align position to grid for multi stomp attack
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

				-- Projectiles
				local params = ProjectileParams()
				params.CircleAngle = 0.41
				params.Scale = 1.5
				entity:FireProjectiles(entity.Position, Vector(Settings.HeadSmashShotSpeed - 4, 8), 9, params)
				params.Scale = 1.25
				entity:FireProjectiles(entity.Position, Vector(Settings.HeadSmashShotSpeed, 0), 8, params)

				-- Effects
				Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 2, entity.Position, Vector.Zero, entity).DepthOffset = entity.DepthOffset + 10
				mod:PlaySound(nil, SoundEffect.SOUND_FORESTBOSS_STOMPS, 1.1)
				mod:PlaySound(nil, SoundEffect.SOUND_HELLBOSS_GROUNDPOUND, 1.1)
				Game():ShakeScreen(Settings.HeadSmashScreenShake)
				Game():MakeShockwave(entity.Position, 0.035, 0.025, 10)
			end
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
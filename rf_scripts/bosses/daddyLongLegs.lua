local mod = ReworkedFoes

local Settings = {
	NewHealth = 650,

	HeadSmashSpeed = 17,
	HeadSmashTimer = 30,
	HeadSmashShotSpeed = 12
}



function mod:DaddyLongLegsInit(entity)
	entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)

	if entity.Variant == 0 then
		mod:ChangeMaxHealth(entity, Settings.NewHealth)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.DaddyLongLegsInit, EntityType.ENTITY_DADDYLONGLEGS)

function mod:DaddyLongLegsUpdate(entity)
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
				entity.Position = mod:GridAlignedPosition(entity.Position)
			end


		-- Move to target
		elseif entity.State == NpcState.STATE_ATTACK5 then
			mod:ChasePlayer(entity, Settings.HeadSmashSpeed)

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
				params.CircleAngle = mod:DegreesToRadians(22.5)
				params.Scale = 1.5
				entity:FireProjectiles(entity.Position, Vector(Settings.HeadSmashShotSpeed - 4, 8), 9, params)
				params.Scale = 1.25
				entity:FireProjectiles(entity.Position, Vector(Settings.HeadSmashShotSpeed, 0), 8, params)

				-- Destroy rocks he slams
				local room = Game():GetRoom()

				for i = -1, 1 do
					for j = -1, 1 do
						local gridPos = entity.Position + Vector(i * 30, j * 30)
						room:DestroyGrid(room:GetGridIndex(gridPos), true)
					end
				end

				-- Effects
				for i = 1, 2 do
					Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, i, entity.Position, Vector.Zero, entity):GetSprite().Color = mod.Colors.DustPoof
				end

				mod:PlaySound(nil, SoundEffect.SOUND_FORESTBOSS_STOMPS, 1.1)
				mod:PlaySound(nil, SoundEffect.SOUND_HELLBOSS_GROUNDPOUND, 1.1)
				Game():ShakeScreen(12)
				Game():MakeShockwave(entity.Position, 0.035, 0.025, 10)
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.DaddyLongLegsUpdate, EntityType.ENTITY_DADDYLONGLEGS)

-- Death effects
function mod:DaddyLongLegsRender(entity, offset)
	if entity.Variant == 0 and mod:ShouldDoRenderEffects() then
        local sprite = entity:GetSprite()
		local data = entity:GetData()

        if sprite:IsPlaying("Death") and sprite:IsEventTriggered("Land")
		and not data.DeathEffects then
			data.DeathEffects = true

			Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 2, entity.Position, Vector.Zero, entity):GetSprite().Color = mod.Colors.DustPoof
			mod:PlaySound(nil, SoundEffect.SOUND_FORESTBOSS_STOMPS)
			Game():ShakeScreen(6)
		end
	end
end

mod:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, mod.DaddyLongLegsRender, EntityType.ENTITY_DADDYLONGLEGS)

function mod:DaddyLongLegsCollision(entity, target, bool)
	if target.Type == EntityType.ENTITY_DADDYLONGLEGS or target.Type == EntityType.ENTITY_BLISTER or target.Type == EntityType.ENTITY_BOIL then
		return true -- Ignore collision
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.DaddyLongLegsCollision, EntityType.ENTITY_DADDYLONGLEGS)
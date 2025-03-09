local mod = ReworkedFoes



-- Uriel
function mod:FallenUrielInit(entity)
	if entity.Variant == 1 then
		mod:ChangeMaxHealth(entity, 500)
		entity:GetSprite():Load("gfx/271.001_fallen uriel.anm2", true)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.FallenUrielInit, EntityType.ENTITY_URIEL)

function mod:FallenUrielUpdate(entity)
	if entity.Variant == 1 then
		local sprite = entity:GetSprite()
		local target = entity:GetPlayerTarget()
		local data = entity:GetData()


		-- Custom laser attacks
		if (entity.State == NpcState.STATE_ATTACK2 or entity.State == NpcState.STATE_ATTACK3) then
			if sprite:IsPlaying("LaserShot") then
				entity.State = entity.State + 2
			end

			if entity.State == NpcState.STATE_ATTACK3 and sprite:GetFrame() == 5 and not sprite:IsPlaying("Float") then
				entity:SetColor(Color(1,1,1, 1, 0.7,0,0), 10, 1, true, false)
				mod:PlaySound(nil, SoundEffect.SOUND_LIGHTBOLT_CHARGE, 2)
			end



		--[[ Spread attack ]]--
		elseif entity.State == NpcState.STATE_ATTACK and sprite:IsPlaying("SpreadShot") then
			if sprite:IsEventTriggered("Shoot") then
				entity.V2 = target.Position

			elseif sprite:GetFrame() == 12 then
				entity:FireProjectiles(entity.Position, (entity.V2 - entity.Position):Resized(7.5), 4, ProjectileParams())
				mod:PlaySound(nil, SoundEffect.SOUND_THUMBS_DOWN, 0.6)
			end



		--[[ Single laser attack ]]--
		elseif entity.State == NpcState.STATE_ATTACK4 then
			if sprite:IsEventTriggered("Shoot") then
				data.brim = EntityLaser.ShootAngle(LaserVariant.THICK_RED, entity.Position - Vector(0, 40), 90, 20, Vector.Zero, entity)
				data.brim.DepthOffset = entity.DepthOffset + 100

				-- Shots
				local params = ProjectileParams()
				params.Variant = ProjectileVariant.PROJECTILE_HUSH
				params.Color = mod.Colors.BrimShot
				params.Scale = 1.25
				params.CircleAngle = 0
				mod:FireProjectiles(entity, Vector(entity.Position.X, Game():GetRoom():GetBottomRightPos().Y - 1), Vector(11, 16), 9, params, Color.Default)
			end

			if sprite:IsFinished("LaserShot") and (not data.brim or not data.brim:Exists()) then
				entity.State = NpcState.STATE_MOVE
			end



		--[[ Double laser attack ]]--
		elseif entity.State == NpcState.STATE_ATTACK5 then
			-- Lasers
			if sprite:IsEventTriggered("Shoot") then
				entity.I2 = 1
				entity.ProjectileCooldown = 30
				entity.V2 = target.Position

				for i = -1, 1, 2 do
					local basePos = (entity.Position - Vector(0, 40))
					local angle = (entity.V2 - basePos):GetAngleDegrees() + (i * 45)
					local laser = EntityLaser.ShootAngle(LaserVariant.THICK_RED, basePos, angle, 22, Vector.Zero, entity)
					laser.DepthOffset = entity.DepthOffset + 100
				end
			end

			-- Shots
			if entity.I2 == 1 then
				if entity.ProjectileCooldown == 18 then
					local params = ProjectileParams()
					params.Spread = 1.3
					entity:FireProjectiles(entity.Position, (entity.V2 - entity.Position):Resized(9), 5, params)
					mod:PlaySound(nil, SoundEffect.SOUND_THUMBS_DOWN, 0.6)
				end

				entity.ProjectileCooldown = entity.ProjectileCooldown - 1
			end

			-- Wait for the shots before finishing
			if sprite:IsFinished("LaserShot") and entity.ProjectileCooldown <= 0 then
				entity.State = NpcState.STATE_MOVE
				entity.I2 = 0
			end
		end


		-- Delirium skin
		if data.wasDelirium and sprite:GetFilename() ~= "gfx/272.001_fallen uriel.anm2" then
			sprite:Load("gfx/272.001_fallen uriel.anm2", true)

			for i = 0, 5 do
				sprite:ReplaceSpritesheet(i, "gfx/bosses/afterbirthplus/deliriumforms/rebirth/angelblack.png")
			end
			sprite:LoadGraphics()
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.FallenUrielUpdate, EntityType.ENTITY_URIEL)





--[[ Gabriel ]]--
function mod:GabrielInit(entity)
	local newHealth = 520
	if entity.Variant == 1 then
		newHealth = 666
		entity:GetSprite():Load("gfx/272.001_fallen gabriel.anm2", true)
	end

	mod:ChangeMaxHealth(entity, newHealth)
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.GabrielInit, EntityType.ENTITY_GABRIEL)

function mod:FallenGabrielUpdate(entity)
	if entity.Variant == 1 then
		local sprite = entity:GetSprite()
		local data = entity:GetData()


		-- Custom laser attacks
		if (entity.State == NpcState.STATE_ATTACK2 or entity.State == NpcState.STATE_ATTACK3) then
			if sprite:IsPlaying("LaserShot") then
				entity.State = entity.State + 2
			end

			if entity.State == NpcState.STATE_ATTACK3 and sprite:GetFrame() == 5 and not sprite:IsPlaying("Float") then
				entity:SetColor(Color(1,1,1, 1, 0.7,0,0), 10, 1, true, false)
				mod:PlaySound(nil, SoundEffect.SOUND_LIGHTBOLT_CHARGE, 2)
			end



		--[[ Spread attack ]]--
		elseif entity.State == NpcState.STATE_ATTACK and sprite:IsPlaying("SpreadShot") and sprite:GetFrame() == 10 then
			entity:FireProjectiles(entity.Position, Vector(8, 8), 8, ProjectileParams())
			mod:PlaySound(nil, SoundEffect.SOUND_THUMBS_DOWN, 0.6)



		--[[ Laser swirl attack ]]--
		elseif entity.State == NpcState.STATE_ATTACK4 then
			-- Laser swirls
			if sprite:IsEventTriggered("Shoot") then
				for i = 0, 2, 2 do
					local vector = Vector.FromAngle(i * 90)
					local swirl = Isaac.Spawn(EntityType.ENTITY_EFFECT, mod.Entities.BrimstoneSwirl, 0, entity.Position + Vector(0, -40), vector:Resized(10), entity)
					swirl.Parent = entity
				end

				mod:PlaySound(nil, SoundEffect.SOUND_LIGHTBOLT_CHARGE, 2)
			end

			if sprite:IsFinished("LaserShot") then
				entity.State = NpcState.STATE_MOVE
			end



		--[[ X laser attack ]]--
		elseif entity.State == NpcState.STATE_ATTACK5 then
			if sprite:IsEventTriggered("Shoot") then
				for i = 0, 3 do
					local angle = (i * 90) + (sprite:IsPlaying("LaserShot") and 45 or 0)
					EntityLaser.ShootAngle(LaserVariant.THICK_RED, entity.Position - Vector(0, 40), angle, 6, Vector.Zero, entity)
				end
			end

			-- Attack twice
			if sprite:IsFinished("LaserShot") then
				sprite:Play("SpreadShot", true)
			elseif sprite:IsFinished("SpreadShot") then
				entity.State = NpcState.STATE_MOVE
			end
		end


		-- Delirium skin
		if data.wasDelirium and sprite:GetFilename() ~= "gfx/272.001_fallen gabriel.anm2" then
			sprite:Load("gfx/272.001_fallen gabriel.anm2", true)

			for i = 0, 5 do
				sprite:ReplaceSpritesheet(i, "gfx/bosses/afterbirthplus/deliriumforms/rebirth/angel2black.png")
			end
			sprite:LoadGraphics()
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.FallenGabrielUpdate, EntityType.ENTITY_GABRIEL)

function mod:GabrielCollision(entity, target, cock)
	if target.SpawnerType == entity.Type then
		return true -- Ignore collision
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.GabrielCollision, EntityType.ENTITY_GABRIEL)



--[[ Single Laser Brimstone Swirl ]]--
function mod:SingleBrimstoneSwirlUpdate(effect)
	local sprite = effect:GetSprite()
	local target = effect.Parent and effect.Parent:ToNPC():GetPlayerTarget() or Isaac.GetPlayer(0)

	effect.Velocity = mod:StopLerp(effect.Velocity, 0.1)


	-- Get starting position + tracer
	if sprite:GetFrame() == 28 then
		effect.TargetPosition = (target.Position - effect.Position):Normalized()
		mod:QuickTracer(effect, effect.TargetPosition:GetAngleDegrees(), Vector.Zero, 15, 1, 2)
	end

	-- Shoot the laser
	if sprite:IsEventTriggered("Shoot") then
		effect.Velocity = Vector.Zero

		local spawner = effect.Parent or effect
		local laser = EntityLaser.ShootAngle(1, effect.Position, effect.TargetPosition:GetAngleDegrees(), 14, Vector.Zero, spawner)
		laser.DisableFollowParent = true
	end


	-- Get removed once it's done
	if sprite:IsFinished() then
		effect:Remove()
	end
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, mod.SingleBrimstoneSwirlUpdate, mod.Entities.BrimstoneSwirl)
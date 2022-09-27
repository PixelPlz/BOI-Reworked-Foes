local mod = BetterMonsters
local game = Game()



-- Uriel
function mod:fallenUrielUpdate(entity)
	if entity.Variant == 1 then
		local sprite = entity:GetSprite()
		local target = entity:GetPlayerTarget()
		local data = entity:GetData()


		-- Spread attack
		if entity.State == NpcState.STATE_ATTACK then
			if sprite:IsPlaying("SpreadShot") then
				if sprite:IsEventTriggered("Shoot") then
					entity.V2 = target.Position

				elseif sprite:GetFrame() == 10 then
					entity:FireProjectiles(entity.Position, (entity.V2 - entity.Position):Normalized() * 7.5, 4, ProjectileParams())
					entity:PlaySound(SoundEffect.SOUND_THUMBS_DOWN, 0.6, 0, false, 1)
				end
			end

		
		-- Laser attacks
		elseif (entity.State == NpcState.STATE_ATTACK2 or entity.State == NpcState.STATE_ATTACK3) then
			if sprite:IsPlaying("LaserShot") then
				entity.State = entity.State + 2
			end
			if entity.State == NpcState.STATE_ATTACK3 and sprite:GetFrame() == 10 and not sprite:IsPlaying("Float") then
				entity:SetColor(Color(1,1,1, 1, 0.7,0,0), 10, 1, true, false)
			end

		elseif entity.State == NpcState.STATE_ATTACK4 then
			if sprite:IsEventTriggered("Shoot") then
				local laser_ent_pair = {laser = EntityLaser.ShootAngle(1, entity.Position - Vector(0, 40), 90, 20, Vector.Zero, entity), entity}
				data.brim = laser_ent_pair.laser
				data.brim.DepthOffset = entity.DepthOffset + 100
				
				-- Shots
				local params = ProjectileParams()
				params.Variant = ProjectileVariant.PROJECTILE_HUSH
				params.Color = brimstoneBulletColor
				params.Scale = 1.25
				params.CircleAngle = 0
				entity:FireProjectiles(Vector(entity.Position.X, game:GetRoom():GetBottomRightPos().Y - 1), Vector(10, 16), 9, params)
			end
			
			if sprite:IsFinished("LaserShot") and (not data.brim or not data.brim:Exists()) then
				entity.State = NpcState.STATE_MOVE
				entity.I1 = 0
			end


		elseif entity.State == NpcState.STATE_ATTACK5 then
			-- Laser
			if sprite:IsEventTriggered("Shoot") then
				entity.I2 = 1
				entity.ProjectileCooldown = 30
				entity.V2 = target.Position

				for i = -1, 1, 2 do
					local laser_ent_pair = {laser = EntityLaser.ShootAngle(1, entity.Position - Vector(0, 40), (entity.V2 - (entity.Position - Vector(0, 40))):GetAngleDegrees() + (i * 35), 20, Vector.Zero, entity), entity}
					laser_ent_pair.laser.DepthOffset = entity.DepthOffset + 100
				end
			end
			
			-- Shots
			if entity.I2 == 1 then
				if entity.ProjectileCooldown == 20 then
					entity:FireProjectiles(entity.Position, (entity.V2 - (entity.Position - Vector(0, 40))):Normalized() * 9, 5, ProjectileParams())
					entity:PlaySound(SoundEffect.SOUND_THUMBS_DOWN, 0.6, 0, false, 1)
				end

				entity.ProjectileCooldown = entity.ProjectileCooldown - 1
			end
			
			if sprite:IsFinished("LaserShot") and entity.ProjectileCooldown <= 0 then
				entity.State = NpcState.STATE_MOVE
				entity.I1 = 0
				entity.I2 = 0
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.fallenUrielUpdate, EntityType.ENTITY_URIEL)



-- Gabriel
function mod:fallenGabrielUpdate(entity)
	if entity.Variant == 1 then
		local sprite = entity:GetSprite()
		local target = entity:GetPlayerTarget()
		local data = entity:GetData()


		-- Spread attack
		if entity.State == NpcState.STATE_ATTACK then
			if sprite:IsPlaying("SpreadShot") and sprite:GetFrame() == 10 then
				local params = ProjectileParams()
				params.CircleAngle = 0.09
				params.Scale = 1.5
				entity:FireProjectiles(entity.Position, Vector(8, 12), 9, params)
				entity:PlaySound(SoundEffect.SOUND_THUMBS_DOWN, 0.6, 0, false, 1)
			end

		
		-- Laser attacks
		elseif (entity.State == NpcState.STATE_ATTACK2 or entity.State == NpcState.STATE_ATTACK3) then
			if sprite:IsPlaying("LaserShot") then
				entity.State = entity.State + 2
			end
			if entity.State == NpcState.STATE_ATTACK3 and sprite:GetFrame() == 10 and not sprite:IsPlaying("Float") then
				entity:SetColor(Color(1,1,1, 1, 0.7,0,0), 15, 1, true, false)
			end

		elseif entity.State == NpcState.STATE_ATTACK4 then
			if sprite:IsEventTriggered("Shoot") then
				for i = 0, 3 do
					local laser_ent_pair = {laser = EntityLaser.ShootAngle(1, entity.Position - Vector(0, 40), (i * 90), 20, Vector.Zero, entity), entity}
					data.brim = laser_ent_pair.laser
					
					entity:FireProjectiles(entity.Position, Vector.FromAngle(data.brim.Angle - 45) * 10, 3, ProjectileParams())
				end
			end
			
			if sprite:IsFinished("LaserShot") and (not data.brim or not data.brim:Exists()) then
				entity.State = NpcState.STATE_MOVE
				entity.I1 = 0
			end


		elseif entity.State == NpcState.STATE_ATTACK5 then
			-- Laser swirls
			if sprite:IsEventTriggered("Shoot") then
				for i = 0, 3 do
					Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.ENEMY_BRIMSTONE_SWIRL, 0, entity.Position - Vector(0, 40) + (Vector.FromAngle(i * 90 - 45) * 10), Vector.FromAngle(i * 90 - 45) * 3, entity)
				end
				entity.I2 = 1
				entity.ProjectileCooldown = 60
			end

			if entity.I2 == 1 then
				entity.ProjectileCooldown = entity.ProjectileCooldown - 1
			end
			
			if sprite:IsFinished("LaserShot") and entity.ProjectileCooldown <= 0 then
				entity.State = NpcState.STATE_MOVE
				entity.I1 = 0
				entity.I2 = 0
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.fallenGabrielUpdate, EntityType.ENTITY_GABRIEL)

function mod:fallenGabrielDMG(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if damageSource.Type == EntityType.ENTITY_EFFECT and damageSource.SpawnerType == EntityType.ENTITY_GABRIEL then
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.fallenGabrielDMG, EntityType.ENTITY_GABRIEL)
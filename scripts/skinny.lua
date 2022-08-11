local mod = BetterMonsters
local game = Game()

local Settings = {
	MoveSpeed = 2,
	AngrySpeed = 4.25,
	CreepTime = 45,
	SoundTimer = {90, 150}
}

local States = {
	Moving = 0,
	Transition = 1,
	Angry = 2
}



function mod:skinnyReplace(entity)
	if entity.Variant < 2 then
		entity:Morph(200, 4226, entity.Variant, entity:GetChampionColorIdx())
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.skinnyReplace, EntityType.ENTITY_SKINNY)

function mod:skinnyUpdate(entity)
	if entity.Variant == 4226 then
		local sprite = entity:GetSprite()
		local data = entity:GetData()
		local target = entity:GetPlayerTarget()
		
		
		if not data.state then
			data.state = States.Moving

		else
			local speed = Settings.MoveSpeed
			local anim = "Head"

			if data.state == States.Angry then
				speed = Settings.AngrySpeed
				anim = "HeadFast"
				
				-- Creep
				if entity.SubType == 0 and entity:IsFrame(4, 0) then
					local creep = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CREEP_RED, 0, entity.Position, Vector.Zero, entity):ToEffect()
					creep.Scale = 0.75
					creep:SetTimeout(Settings.CreepTime)
					creep:Update()

				-- Bullets
				elseif entity.SubType == 1 and entity:IsFrame(16, 0) then
					local params = ProjectileParams()
					params.BulletFlags = ProjectileFlags.CHANGE_FLAGS_AFTER_TIMEOUT
					params.ChangeFlags = ProjectileFlags.ANTI_GRAVITY
					params.ChangeTimeout = 48
					
					params.FallingAccelModifier = -0.2
					params.Scale = 1 + (math.random(25, 40) / 100)
					entity:FireProjectiles(entity.Position, Vector.Zero, 0, params)
				end


			elseif data.state == States.Transition then
				anim = "Transition"
				if sprite:IsOverlayPlaying(anim) then
					if sprite:GetOverlayFrame() == 5 then
						SFXManager():Play(SoundEffect.SOUND_SKIN_PULL, 0.75, 0, false, 0.9)

					elseif sprite:GetOverlayFrame() == 14 then
						data.state = States.Angry
						if entity.SubType == 1 then
							local skull = Isaac.Spawn(EntityType.ENTITY_DEATHS_HEAD, 0, 0, entity.Position + Vector(0, entity.Scale * -5), Vector.Zero, entity)
							skull:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
							skull:ToNPC().Scale = entity.Scale
						end
					end
				end
			end


			-- Animation
			entity:AnimWalkFrame("WalkHori", "WalkVert", 0.1)
			if not sprite:IsOverlayPlaying(anim) then
				sprite:PlayOverlay(anim, true)
			end
			if anim == "Head" then
				sprite:SetOverlayFrame(anim, sprite:GetFrame())
			end


			-- Movement
			if entity:HasEntityFlags(EntityFlag.FLAG_FEAR) or entity:HasEntityFlags(EntityFlag.FLAG_SHRINK) then
				speed = -speed
			end

			if entity:HasEntityFlags(EntityFlag.FLAG_CONFUSION) then
				entity.Pathfinder:MoveRandomly(false)
			else
				if entity.Pathfinder:HasPathToPos(target.Position) then
					if game:GetRoom():CheckLine(entity.Position, target.Position, 0, 0, false, false) then
						entity.Velocity = (entity.Velocity + ((target.Position - entity.Position):Normalized() * speed - entity.Velocity) * 0.25)
					else
						entity.Pathfinder:FindGridPath(target.Position, speed / 6, 500, false)
					end
				
				else
					entity.Velocity = (entity.Velocity + (Vector.Zero - entity.Velocity) * 0.25)
				end
			end


			-- Sounds
			if not data.soundTimer then
				data.soundTimer = (math.random(Settings.SoundTimer[1], Settings.SoundTimer[2])) / 2
			elseif data.soundTimer <= 0 then
				entity:PlaySound(SoundEffect.SOUND_ANGRY_GURGLE, 1, 0, false, 1)
				data.soundTimer = math.random(Settings.SoundTimer[1], Settings.SoundTimer[2])
			else
				data.soundTimer = data.soundTimer - 1
			end


			-- Transition
			if data.state == States.Moving and entity.HitPoints <= ((entity.MaxHitPoints / 3) * 2) then
				data.state = States.Transition
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.skinnyUpdate, 200)

-- Take 50% less damage in 1st phase
function mod:skinnyDMG(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if target.Variant == 4226 and target:GetData().state ~= States.Angry then
		if not (damageFlags & DamageFlag.DAMAGE_NOKILL > 0) then
			target:TakeDamage(damageAmount / 2, damageFlags + DamageFlag.DAMAGE_NOKILL, damageSource, damageCountdownFrames)
			return false
		end
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.skinnyDMG, 200)
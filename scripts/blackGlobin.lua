local mod = BetterMonsters
local game = Game()

local Settings = {
	RegenTime = 75,
	BodySpeed = 3.75,
	SoundTimer = {90, 150},

	HeadSpeed = 3.25,
	SlideTime = 45,
	SlideSpeed = 15,
	CreepTime = 45
}

local States = {
	Moving = 0,
	Regen = 1,
	KnockedOff = 2,
	Recover = 3
}



function mod:blackGlobinReplace(entity)
	entity:Morph(200, 4278, 0, entity:GetChampionColorIdx())
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.blackGlobinReplace, EntityType.ENTITY_BLACK_GLOBIN)

function mod:blackGlobinHeadReplace(entity)
	entity:Morph(200, 4279, 0, entity:GetChampionColorIdx())
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.blackGlobinHeadReplace, EntityType.ENTITY_BLACK_GLOBIN_HEAD)



function mod:blackGlobinUpdate(entity)
	if entity.Variant == 4278 or entity.Variant == 4279 then
		local sprite = entity:GetSprite()
		local data = entity:GetData()
		local target = entity:GetPlayerTarget()
		
		
		if not data.state then
			data.state = States.Moving

		-- Movement
		elseif data.state == States.Moving then
			local speed = Settings.BodySpeed
			if entity.Variant == 4279 then
				speed = Settings.HeadSpeed
			end
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
		end


		-- Main body
		if entity.Variant == 4278 then
			-- Sounds
			if not data.soundTimer then
				data.soundTimer = (math.random(Settings.SoundTimer[1], Settings.SoundTimer[2])) / 2
			elseif data.soundTimer <= 0 then
				entity:PlaySound(SoundEffect.SOUND_ZOMBIE_WALKER_KID, 1, 0, false, 1)
				data.soundTimer = math.random(Settings.SoundTimer[1], Settings.SoundTimer[2])
			else
				data.soundTimer = data.soundTimer - 1
			end

			if data.state == States.Moving then
				entity:AnimWalkFrame("WalkHori", "WalkVert", 0.1)

			-- Spawn from head
			elseif data.state == States.Regen then
				entity.Velocity = Vector.Zero

				if not sprite:IsPlaying("Appear") then
					sprite:Play("Appear", true)
				end
				if sprite:IsEventTriggered("Regen") then
					data.state = States.Moving
				end
			end


		-- Head
		elseif entity.Variant == 4279 then
			-- Creep
			if entity:IsFrame(4, 0) then
				local creep = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CREEP_RED, 0, entity.Position, Vector.Zero, entity):ToEffect()
				creep.Scale = 1
				creep:SetTimeout(Settings.CreepTime)
			end

			if data.state == States.Moving then
				if not sprite:IsPlaying("Walk") then
					sprite:Play("Walk", true)
				end

				-- Regen
				if not data.timer then
					data.timer = Settings.RegenTime * 2.5 -- Make them start with a longer regen time if spawned through the room layout

				elseif data.timer <= 0 then
					local spawn = Isaac.Spawn(200, 4278, 0, entity.Position, Vector.Zero, entity)
					spawn:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
					spawn:GetData().state = States.Regen
					spawn:GetSprite():Play("Appear", true)
					spawn.HitPoints = 20

					if entity:IsChampion() then
						spawn:ToNPC():MakeChampion(1, entity:GetChampionColorIdx(), true)
					end
					SFXManager():Play(SoundEffect.SOUND_DEATH_REVERSE, 1.2)
					entity:Remove()
				else
					data.timer = data.timer - 1
				end

			-- Sliding
			elseif data.state == States.KnockedOff then
				if not sprite:IsPlaying("Sliding") and not sprite:IsPlaying("KnockedOff") then
					sprite:Play("Sliding", true)
					entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
				end

				if data.timer <= 0 then
					data.state = States.Recover
				else
					data.timer = data.timer - 1
				end

				if entity:CollidesWithGrid() or sprite:IsEventTriggered("Splat") then
					SFXManager():Play(SoundEffect.SOUND_MEAT_JUMPS)
					local impactCreep = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CREEP_RED, 0, entity.Position, Vector.Zero, entity):ToEffect()
					impactCreep.Scale = 1.5
					impactCreep:SetTimeout(Settings.CreepTime)
				end

			-- Recover
			elseif data.state == States.Recover then
				entity.Velocity = (entity.Velocity + (Vector.Zero - entity.Velocity) * 0.25)

				if not sprite:IsPlaying("Recover") then
					sprite:Play("Recover", true)
				end
				
				if sprite:IsEventTriggered("Splat") then
					SFXManager():Play(SoundEffect.SOUND_GOOATTACH0, 0.9)
				elseif sprite:IsEventTriggered("Recover") then
					data.state = States.Moving
					data.timer = Settings.RegenTime
				end
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.blackGlobinUpdate, 200)

function mod:blackGlobinDMG(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if target.Variant == 4278 then
		target:ToNPC().V2 = damageSource.Position
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.blackGlobinDMG, 200)

function mod:blackGlobinDeath(entity)
	if entity.Variant == 4278 then
		local head = Isaac.Spawn(200, 4279, 0, entity.Position, Vector.Zero, entity)
		head:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
		head:GetData().state = States.KnockedOff
		head:GetData().timer = Settings.SlideTime
		head.Velocity = (entity.Position - entity.V2):Normalized() * Settings.SlideSpeed
		head:GetSprite():Play("KnockedOff", true)
		head.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
		
		local body = Isaac.Spawn(EntityType.ENTITY_BLACK_GLOBIN_BODY, 0, 0, entity.Position, Vector.Zero, entity):ToNPC()
		body.State = NpcState.STATE_MOVE
		
		if entity:IsChampion() then
			head:ToNPC():MakeChampion(1, entity:GetChampionColorIdx(), true)
			body:MakeChampion(1, entity:GetChampionColorIdx(), true)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.blackGlobinDeath, 200)
local mod = ReworkedFoes

function mod:ShouldChampionDropReward(rng)
    if Game().Difficulty == Difficulty.DIFFICULTY_NORMAL
    or (Game().Difficulty == Difficulty.DIFFICULTY_HARD and rng:RandomInt(3) == 0) then
        return true
    end
    return false
end



-- Dark red champion unique goo sprites
function mod:DarkRedChampionRender(entity)
    if entity:GetChampionColorIdx() == ChampionColor.DARK_RED then
        local sprite = entity:GetSprite()

        if sprite:GetAnimation() == "ReGenChamp" then
            if not entity:GetData().ReplacedGooSprite then
                local gooSize = 1

                -- Get sprite size
                if entity.Size >= 18 then
                    gooSize = 5
                elseif entity.Size >= 15 then
                    gooSize = 4
                elseif entity.Size >= 12 then -- 13 is the size of globins so I'm basing the other sizes off of it
                    gooSize = 3
                elseif entity.Size >= 9 then
                    gooSize = 2
                end

                sprite:ReplaceSpritesheet(1, "gfx/monsters/better/champion_regen_" .. tostring(gooSize) .. ".png")
                sprite:LoadGraphics()
                entity:GetData().ReplacedGooSprite = true
            end

        elseif entity:GetData().ReplacedGooSprite then
            entity:GetData().ReplacedGooSprite = nil
        end
    end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, mod.DarkRedChampionRender)



function mod:ChampionDeath(entity)
    if mod.Config.ChampionChanges == true and entity:IsChampion() then
        -- Grey champion creep
        if entity:GetChampionColorIdx() == ChampionColor.GREY then
            local creep = mod:QuickCreep(EffectVariant.CREEP_RED, entity, entity.Position, 2)
            creep.Color = mod.Colors.CageCreep
        end


        -- New drops
        if Game():GetRoom():IsFirstVisit() and Isaac.GetChallenge() ~= Challenge.CHALLENGE_ULTRA_HARD and entity.SpawnerType ~= EntityType.ENTITY_PORTAL
        and Game():GetLevel():GetStage() ~= LevelStage.STAGE7 and Game():GetVictoryLap() < 1 then -- Ugly but I think this is all the checks
            local rng = entity:GetDropRNG()
            local room = Game():GetRoom()

            -- Magenta - Half soul heart
            if entity:GetChampionColorIdx() == ChampionColor.PINK then
                if mod:ShouldChampionDropReward(rng) == true then
                    local pos = room:FindFreeTilePosition(entity.Position, 40)
                    Game():Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, pos, Vector.Zero, entity, HeartSubType.HEART_HALF_SOUL, entity.DropSeed)
                end


            -- Pulsating grey - Card
            elseif entity:GetChampionColorIdx() == ChampionColor.PULSE_GREY then
                if mod:ShouldChampionDropReward(rng) == true then
                    local pos = room:FindFreeTilePosition(entity.Position, 40)
                    Game():Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TAROTCARD, pos, Vector.Zero, entity, Game():GetItemPool():GetCard(entity.DropSeed, true, false, false), entity.DropSeed)
                end
            end
        end
    end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.ChampionDeath)



-- Modified drops
function mod:ChampionOverrideDrop(type, variant, subtype, pos, vel, spawner, seed) -- This might accidentally replace unintended things, but it'd be rare and there's no better way
    if mod.Config.ChampionChanges == true and spawner and spawner:ToNPC() and spawner:ToNPC():IsChampion() then
        local npc = spawner:ToNPC()

        -- Light white - Pretty fly pill
        if npc:GetChampionColorIdx() == ChampionColor.FLY_PROTECTED
        and type == EntityType.ENTITY_ATTACKFLY then
            local rng = npc:GetDropRNG()

            if mod:ShouldChampionDropReward(rng) == true -- Have to add this since the attack fly always spawns no matter what difficulty
            and rng:RandomInt(5) == 0 then
                return {EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_PILL, Game():GetItemPool():ForceAddPillEffect(PillEffect.PILLEFFECT_PRETTY_FLY), seed}
            else
                return {type, variant, 96, seed} -- Turn the Attack Fly into an Attack Eternal Fly
            end


        -- Pulsating red - Blended heart
        elseif npc:GetChampionColorIdx() == ChampionColor.PULSE_RED
        and type == EntityType.ENTITY_PICKUP and variant == PickupVariant.PICKUP_HEART and subtype == HeartSubType.HEART_FULL then
            return {type, variant, HeartSubType.HEART_BLENDED, seed}
        end
    end
end
mod:AddCallback(ModCallbacks.MC_PRE_ENTITY_SPAWN, mod.ChampionOverrideDrop)
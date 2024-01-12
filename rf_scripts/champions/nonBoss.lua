local mod = ReworkedFoes

function mod:darkRedRender(entity)
    if not entity:GetChampionColorIdx(ChampionColor.DARK_RED) then return end

    local sprite = entity:GetSprite()
    if sprite:GetAnimation() == "ReGenChamp" then
        print(entity.Size)
        if entity.Size >= 18 then
            sprite:ReplaceSpritesheet(1, "gfx/monsters/classic/champion_regen_5.png")
        elseif entity.Size >= 15 then
            sprite:ReplaceSpritesheet(1, "gfx/monsters/classic/champion_regen_4.png")
        elseif entity.Size >= 13 then -- 13 is the size of globins so im basing the other sizes off of it
            sprite:ReplaceSpritesheet(1, "gfx/monsters/classic/champion_regen_3.png")
        elseif entity.Size >= 8 then
            sprite:ReplaceSpritesheet(1, "gfx/monsters/classic/champion_regen_2.png")
        elseif entity.Size > 0 then
            sprite:ReplaceSpritesheet(1, "gfx/monsters/classic/champion_regen_1.png")
        end

        sprite:LoadGraphics()
    end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, mod.darkRedRender)

function mod:championDeath(entity)
    if entity:IsChampion() then
        if entity:GetChampionColorIdx() == ChampionColor.GREY then
            local creep = mod:QuickCreep(EffectVariant.CREEP_RED, entity, entity.Position, 10)
            creep.Color = mod.Colors.GateCreep
        end

        if Game():GetRoom():IsFirstVisit() and Isaac.GetChallenge() ~= Challenge.CHALLENGE_ULTRA_HARD and entity.SpawnerType ~= EntityType.ENTITY_PORTAL and Game():GetLevel():GetStage() ~= LevelStage.STAGE7 and Game():GetVictoryLap() < 1 then -- ugly but i think this is all the checks
            local rng = entity:GetDropRNG()
            local room = Game():GetRoom()

            if entity:GetChampionColorIdx() == ChampionColor.PINK then -- half soul heart
                if Game().Difficulty == Difficulty.DIFFICULTY_NORMAL or (Game().Difficulty == Difficulty.DIFFICULTY_HARD and rng:RandomInt(3) == 0) then
                    Game():Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, room:FindFreeTilePosition(entity.Position, 40.0), Vector.Zero, entity, HeartSubType.HEART_HALF_SOUL, entity.DropSeed)
                end
            elseif entity:GetChampionColorIdx() == ChampionColor.PULSE_GREY then -- card
                if Game().Difficulty == Difficulty.DIFFICULTY_NORMAL or (Game().Difficulty == Difficulty.DIFFICULTY_HARD and rng:RandomInt(3) == 0) then
                    Game():Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TAROTCARD, room:FindFreeTilePosition(entity.Position, 40.0), Vector.Zero, entity, Game():GetItemPool():GetCard(entity.DropSeed, true, false, false), entity.DropSeed)
                end
            end

            -- todo: add glyph of balance stuff with repentogon
        end
    end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.championDeath)

function mod:championOverrideDrop(type, variant, subtype, pos, vel, spawner, seed) -- this might accidentally replace unintended things, but it'd be rare and there's not any better way
    if spawner and spawner:ToNPC() then
        local npc = spawner:ToNPC()

        if npc:IsChampion() then
            if npc:GetChampionColorIdx() == ChampionColor.FLY_PROTECTED then -- pretty fly pill
                local rng = npc:GetDropRNG()
                if type == EntityType.ENTITY_ATTACKFLY then
                    if Game().Difficulty == Difficulty.DIFFICULTY_NORMAL or (Game().Difficulty == Difficulty.DIFFICULTY_HARD and rng:RandomInt(3) == 0) then -- have to add this since the attack fly always spawns no matter what difficulty
                        if rng:RandomInt(5) == 0 then
                            return {EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_PILL, Game():GetItemPool():ForceAddPillEffect(PillEffect.PILLEFFECT_PRETTY_FLY), seed}
                        end
                    end
                end
            elseif npc:GetChampionColorIdx() == ChampionColor.PULSE_RED then -- blended heart
                if type == EntityType.ENTITY_PICKUP and variant == PickupVariant.PICKUP_HEART and subtype == HeartSubType.HEART_FULL then
                    return {type, variant, HeartSubType.HEART_BLENDED, seed}
                end
            end
        end
    end
end
mod:AddCallback(ModCallbacks.MC_PRE_ENTITY_SPAWN, mod.championOverrideDrop)
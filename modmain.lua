Assets = {
    Asset("SOUNDPACKAGE", "sound/chenbo.fev"),
    Asset("SOUND", "sound/chenbo.fsb"),
}

RemapSoundEvent("chenbo/mans/man", "chenbo/mans/man")
print("召唤陈伯!")

local function SpawnHoundAtPlayer(player)
    if player and player.Transform then
        local x, y, z = player.Transform:GetWorldPosition()
        local offset = 4
        local angle = player.Transform:GetRotation() or 0
        local rad = math.rad(angle)
        local dx = math.cos(rad) * offset
        local dz = -math.sin(rad) * offset
        local pig = GLOBAL.SpawnPrefab("pigman")
        if pig then
            pig.Transform:SetPosition(x + dx, y, z + dz)
        end
    end
end

local SPAWN_PIGMAN_RPC = "summoner_spawn_pigman"
local MAX_PIGS = 6
local current_pigs = 0

-- 猪人死亡时自动减少计数
local function OnPigmanDeath(inst)
    if inst.summoner_tag then
        current_pigs = math.max(0, current_pigs - 1)
    end
end

AddModRPCHandler("summoner", SPAWN_PIGMAN_RPC, function(player)
    if current_pigs >= MAX_PIGS then
        if player and player.components and player.components.talker then
            player.components.talker:Say("野猪已达上限！")
        end
        return
    end

    -- 生成猪人
    if player and player.Transform then
        local x, y, z = player.Transform:GetWorldPosition()
        local offset = 4
        local angle = player.Transform:GetRotation() or 0
        local rad = math.rad(angle)
        local dx = math.cos(rad) * offset
        local dz = -math.sin(rad) * offset
        local pig = GLOBAL.SpawnPrefab("pigman")
        if pig then
            pig.Transform:SetPosition(x + dx, y, z + dz)
            pig.summoner_tag = true -- 打上标记
            current_pigs = current_pigs + 1
            pig:ListenForEvent("onremove", OnPigmanDeath)
            pig:ListenForEvent("death", OnPigmanDeath)
            if pig.components.follower then
                pig.components.follower:SetLeader(player)
            end
            -- 禁止吃怪物肉
            local forbidden = {
                monstermeat = true,
                cookedmonstermeat = true,
                monstermeat_dried = true,
            }
            if pig.components.eater then
                local old_CanEat = pig.components.eater.CanEat
                function pig.components.eater:CanEat(food)
                    if food and forbidden[food.prefab] then
                        return false
                    end
                    return old_CanEat(self, food)
                end
            end
        end
    end
end)

AddClassPostConstruct("widgets/controls", function(self)
    if not GLOBAL.TheNet:IsDedicated() then
        self.inst:DoTaskInTime(2, function()
            if self.summonpigman_button then return end
            local ImageButton = require "widgets/imagebutton"
            local button = self:AddChild(ImageButton("images/hud.xml", "craft_slot.tex"))
            button:SetPosition(150, 100, 0) -- 左下角，完整可见
            button:SetScale(1.2)
            button:SetOnClick(function()
                print("按钮被点击了")
                print("尝试播放声音: mans")
                
                GLOBAL.TheFrontEnd:GetSound():PlaySound("chenbo/mans/man")
                
                SendModRPCToServer(MOD_RPC.summoner.summoner_spawn_pigman)
            end)
            button:SetTooltip("Man")
            self.summonpigman_button = button
        end)
    end
end)


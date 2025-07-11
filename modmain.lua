print("hound quick start!")

local function SpawnHoundAtPlayer(player)
    if player and player.Transform then
        local x, y, z = player.Transform:GetWorldPosition()
        local hound = GLOBAL.SpawnPrefab("hound")
        if hound then
            hound.Transform:SetPosition(x + 2, y, z + 2)
            -- 直接设置leader，不要重复添加组件
            hound.components.follower:SetLeader(player)

            -- 让疯狗保护玩家
            hound.components.combat:SetRetargetFunction(1, function(hound_inst)
                local leader = hound_inst.components.follower and hound_inst.components.follower.leader
                if leader and leader.components.combat and leader.components.combat.target then
                    local target = leader.components.combat.target
                    if target ~= leader then
                        return target
                    end
                end
                return nil
            end)
            hound.components.combat:SetKeepTargetFunction(function(hound_inst, target)
                local leader = hound_inst.components.follower and hound_inst.components.follower.leader
                return target ~= leader
            end)
        end
    end
end

AddClassPostConstruct("widgets/controls", function(self)
    if not GLOBAL.TheNet:IsDedicated() then
        self.inst:DoTaskInTime(2, function() -- 延迟2秒，确保HUD加载完成
            if self.summonhound_button then return end

            local ImageButton = require "widgets/imagebutton"
            local button = self:AddChild(ImageButton("images/hud.xml", "craft_slot.tex"))
            button:SetPosition(0, 0, 0) -- 屏幕正中央，方便调试
            button:SetScale(1.2)
            button:SetOnClick(function()
                SpawnHoundAtPlayer(self.owner)
            end)
            button:SetTooltip("召唤疯狗")
            self.summonhound_button = button
        end)
    end
end)
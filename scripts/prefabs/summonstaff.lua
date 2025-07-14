local assets = {}

-- 跟踪每个玩家召唤的猪人
local player_pigs = {}

local function cleanup_dead_pigs(player)
    local pigs = player_pigs[player] or {}
    for i = #pigs, 1, -1 do
        if not pigs[i] or not pigs[i]:IsValid() or pigs[i].components.follower == nil or pigs[i].components.follower.leader ~= player then
            table.remove(pigs, i)
        end
    end
    player_pigs[player] = pigs
end

local function onuse(inst, user)
    print("[summonstaff] onuse called! inst:", inst, "user:", user)
    if user and user.components and user.components.talker then
        print("[summonstaff] user has talker component, saying话...")
        user.components.talker:Say("出来面对我！")
    else
        print("[summonstaff] user没有talker组件")
    end
    if user and user.SoundEmitter then
        print("[summonstaff] user has SoundEmitter, playing sound...")
        user.SoundEmitter:PlaySound("chenbo/mans/man")
    else
        print("[summonstaff] user没有SoundEmitter")
    end
    
    -- 服务器端直接执行召唤逻辑
    if TheWorld.ismastersim then
        print("[summonstaff] is mastersim, will try to spawn pigman...")
        if user and user.Transform then
            cleanup_dead_pigs(user)
            local pigs = player_pigs[user] or {}
            if #pigs >= 6 then
                if user.components.talker then
                    user.components.talker:Say("你已经有6个猪仔了！")
                end
                print("[summonstaff] 猪仔数量已达上限")
                return
            end
            local x, y, z = user.Transform:GetWorldPosition()
            local offset = 4
            local angle = user.Transform:GetRotation() or 0
            local rad = math.rad(angle)
            local dx = math.cos(rad) * offset
            local dz = -math.sin(rad) * offset
            print("[summonstaff] user pos:", x, y, z, "angle:", angle)
            -- 直接生成猪人
            local pig = SpawnPrefab("pigman")
            if pig then
                print("[summonstaff] pigman spawned!")
                pig.Transform:SetPosition(x + dx, y, z + dz)
                pig.summoner_tag = true
                -- 让猪人跟随玩家
                if pig.components.follower then
                    print("[summonstaff] pigman has follower, set leader.")
                    pig.components.follower:SetLeader(user)
                else
                    print("[summonstaff] pigman没有follower组件")
                end
                table.insert(pigs, pig)
                player_pigs[user] = pigs

                -- 随机喊一句话
                local lines = {
                    {"出来面对我!", {1, 0.5, 0, 1}},      -- 橙色
                    {"就这?一把龟", {0, 0, 1, 1}},        -- 蓝色
                    {"就这?一把猪", {1, 0, 0, 1}},        -- 红色
                    {"我们是亚军", {0, 1, 0, 1}},          -- 绿色
                    {"旭你真猛", {0, 0, 1, 1}},            -- 蓝色
                    {"小明订房!", {0.5, 0, 0.5, 1}},       -- 紫色
                    {"就这?一把猴", {1, 0, 0, 1}},         -- 红色
                    {"你没有发烧吧？", {1, 0.4, 0.7, 1}}    -- 粉色
                }
                local idx = math.random(#lines)
                local text, color = lines[idx][1], lines[idx][2]
                if pig.components.talker then
                    pig.allow_mod_talk = true
                    pig.components.talker:Say(text, 9, nil, true, nil, color)
                end

                -- 定时让猪人说话
                if pig.talkertask ~= nil then
                    pig.talkertask:Cancel()
                end
                pig.talkertask = pig:DoPeriodicTask(math.random(12, 18), function(inst)
                    if inst.components.talker then
                        local lines = {
                            {"出来面对我!", {1, 0.5, 0, 1}},
                            {"就这?一把龟", {0, 0, 1, 1}},
                            {"就这?一把猪", {1, 0, 0, 1}},
                            {"我们是亚军", {0, 1, 0, 1}},
                            {"旭你真猛", {0, 0, 1, 1}},
                            {"小明订房!", {0.5, 0, 0.5, 1}},
                            {"就这?一把猴", {1, 0, 0, 1}},
                            {"你没有发烧吧？", {1, 0.4, 0.7, 1}}
                        }
                        local idx = math.random(#lines)
                        local text, color = lines[idx][1], lines[idx][2]
                        inst.allow_mod_talk = true
                        inst.components.talker:Say(text, 9, nil, true, nil, color)
                    end
                end)

                -- 猪人死亡或移除时，取消定时任务
                local function cancel_talkertask(inst)
                    if inst.talkertask ~= nil then
                        inst.talkertask:Cancel()
                        inst.talkertask = nil
                    end
                end
                pig:ListenForEvent("onremove", cancel_talkertask)
                pig:ListenForEvent("death", cancel_talkertask)

                -- 监听猪人死亡或移除
                pig:ListenForEvent("onremove", function()
                    cleanup_dead_pigs(user)
                end)
                -- 监听猪人死亡事件（可选，防止有些情况下onremove不触发）
                pig:ListenForEvent("death", function()
                    cleanup_dead_pigs(user)
                end)
            else
                print("[summonstaff] pigman spawn失败")
            end
        else
            print("[summonstaff] user没有Transform")
        end
    else
        print("[summonstaff] not mastersim, skip spawn")
    end
    
    -- 用完后消耗一次耐久
    if inst.components.finiteuses then
        print("[summonstaff] has finiteuses, use 1")
        inst.components.finiteuses:Use(1)
    else
        print("[summonstaff] 没有finiteuses组件")
    end
end

local function fn()
    print("[summonstaff] fn called!")
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.AnimState:SetBank("spear")
    inst.AnimState:SetBuild("spear")
    inst.AnimState:PlayAnimation("idle")
    inst.entity:AddNetwork()
    MakeInventoryPhysics(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        print("[summonstaff] not mastersim, return inst early")
        return inst
    end

    print("[summonstaff] Adding components (mastersim)")
    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "icestaff"
    inst.components.inventoryitem.atlasname = "images/inventoryimages.xml"

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(12)
    inst.components.finiteuses:SetUses(12)
    inst.components.finiteuses:SetOnFinished(inst.Remove)

    -- 将 onuse 函数暴露给外部调用
    inst.onuse = onuse
    
    return inst
end

return Prefab("summonstaff", fn, assets) 
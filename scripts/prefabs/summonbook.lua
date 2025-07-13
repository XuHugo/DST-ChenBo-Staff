local assets = {}

local function onuse(inst, user)
    print("onuse函数被调用！")
    print("用户:", user)
    print("是否为主服务器:", TheWorld.ismastersim)
    
    if user and user.components and user.components.talker then
        user.components.talker:Say("Man!出来面对我！")
        print("用户说话了！")
    end
    if user and user.SoundEmitter then
        user.SoundEmitter:PlaySound("chenbo/mans/man")
        print("播放音效！")
    end
    
    -- 服务器端直接执行召唤逻辑
    if TheWorld.ismastersim then
        print("开始执行召唤逻辑...")
        if user and user.Transform then
            local x, y, z = user.Transform:GetWorldPosition()
            local offset = 4
            local angle = user.Transform:GetRotation() or 0
            local rad = math.rad(angle)
            local dx = math.cos(rad) * offset
            local dz = -math.sin(rad) * offset
            
            print("玩家位置:", x, y, z)
            print("生成位置:", x + dx, y, z + dz)
            
            -- 直接生成猪人
            local pig = SpawnPrefab("pigman")
            if pig then
                pig.Transform:SetPosition(x + dx, y, z + dz)
                pig.summoner_tag = true
                
                -- 让猪人跟随玩家
                if pig.components.follower then
                    pig.components.follower:SetLeader(user)
                    print("猪人开始跟随玩家！")
                end
                
                print("成功召唤猪人！位置:", x + dx, y, z + dz)
            else
                print("生成猪人失败！")
            end
        else
            print("用户或Transform无效！")
        end
    else
        print("不是主服务器，跳过召唤逻辑")
    end
    
    -- 用完后消耗一次耐久
    if inst.components.finiteuses then
        inst.components.finiteuses:Use(1)
        print("消耗耐久度！")
    end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    
    -- 只在客户端设置动画，避免服务器端报错
    if not TheNet:IsDedicated() then
        inst.entity:AddAnimState()
        inst.AnimState:SetBank("book_birds")
        inst.AnimState:SetBuild("book_birds")
        inst.AnimState:PlayAnimation("idle")
    end
    
    inst.entity:AddNetwork()
    MakeInventoryPhysics(inst)

    inst:AddTag("book")
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "book_birds"
    inst.components.inventoryitem.atlasname = "images/inventoryimages.xml"

    -- 使用useableitem组件，让所有角色都能右键使用
    inst:AddComponent("useableitem")
    inst.components.useableitem:SetOnUseFn(onuse)

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(12)
    inst.components.finiteuses:SetUses(12)
    inst.components.finiteuses:SetOnFinished(inst.Remove)

    return inst
end

return Prefab("summonbook", fn, assets)

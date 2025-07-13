PrefabFiles = {
    "summonstaff",
}

Assets = {
    Asset("SOUNDPACKAGE", "sound/chenbo.fev"),
    Asset("SOUND", "sound/chenbo.fsb"),
    Asset("ATLAS", "images/inventoryimages/summonstaff.xml"),
    Asset("IMAGE", "images/inventoryimages/summonstaff.tex"),
}

RemapSoundEvent("chenbo/mans/man", "chenbo/mans/man")
print("召唤猪仔!")

-- 添加RPC处理
local function find_summonstaff(player)
    local inv = player.components.inventory
    -- 先查手上
    local inst = inv:GetEquippedItem(GLOBAL.EQUIPSLOTS.HANDS)
    if inst and inst.prefab == "summonstaff" and inst.onuse then
        return inst
    end
    -- 再查背包
    for k,v in pairs(inv.itemslots) do
        if v and v.prefab == "summonstaff" and v.onuse then
            return v
        end
    end
    return nil
end

AddModRPCHandler("summonstaff", "summon_pig", function(player)
    print("[DEBUG] 服务器收到召唤猪人RPC请求")
    if not player or not GLOBAL.TheWorld.ismastersim then 
        print("[DEBUG] 玩家无效或不是主服务器")
        return 
    end
    print("[DEBUG] 开始执行召唤逻辑")
    local inst = find_summonstaff(player)
    if inst then
        print("[DEBUG] 找到召唤法杖，调用onuse")
        inst.onuse(inst, player)
    else
        print("[DEBUG] 找不到召唤法杖或onuse函数")
    end
end)

-- 1. 定义全局动作
GLOBAL.SUMMONPIG = AddAction("SUMMONPIG", "召唤猪仔", function(act)
    print("[DEBUG] SUMMONPIG 动作模板被调用 (AddAction)")
    return true
end)

-- 2. 让物品右键出现动作
AddComponentAction("INVENTORY", "inventoryitem", function(inst, doer, actions, right)
    print("[DEBUG] AddComponentAction 被调用，inst.prefab:", inst.prefab, "right:", right)
    if inst.prefab == "summonstaff" then
        print("[DEBUG] 添加 SUMMONPIG 动作到 actions")
        table.insert(actions, GLOBAL.SUMMONPIG)
    end
end)

-- 3. 绑定 Stategraph
AddStategraphActionHandler("wilson", GLOBAL.ActionHandler(GLOBAL.SUMMONPIG, "dolongaction"))
AddStategraphActionHandler("wilson_client", GLOBAL.ActionHandler(GLOBAL.SUMMONPIG, "dolongaction"))

-- 4. 在 Stategraph handler 里触发 RPC
AddStategraphPostInit("wilson_client", function(sg)
    print("[DEBUG] StategraphPostInit for wilson_client")
    local old_onenter = sg.states["dolongaction"].onenter
    sg.states["dolongaction"].onenter = function(inst, ...)
        print("[DEBUG] wilson_client.dolongaction.onenter 被调用")
        local buffaction = inst:GetBufferedAction()
        if buffaction and buffaction.action == GLOBAL.SUMMONPIG then
            print("[DEBUG] 检测到 SUMMONPIG 动作，发送RPC")
            SendModRPCToServer(GLOBAL.MOD_RPC.summonstaff.summon_pig)
            if buffaction.invobject and buffaction.invobject.components.finiteuses then
                print("[DEBUG] 消耗法杖耐久")
                buffaction.invobject.components.finiteuses:Use(1)
            end
        end
        return old_onenter(inst, ...)
    end
end)

print("[DEBUG] 动作系统设置完成")

GLOBAL.STRINGS.NAMES.SUMMONSTAFF = "召唤法杖"
GLOBAL.STRINGS.RECIPE_DESC.SUMMONSTAFF = "一根可以召唤猪崽的神秘法杖。"
GLOBAL.STRINGS.CHARACTERS.GENERIC.DESCRIBE.SUMMONSTAFF = "出来面对我！"
GLOBAL.STRINGS.ACTIONS.SUMMONPIG = "召唤猪仔"
print("字符串定义完成：召唤法杖")

AddPrefabPostInit("world", function(inst)
    print("[DEBUG] 世界初始化，开始注册配方")
    
    local summonstaff_recipe = AddRecipe2(
        "summonstaff",
        {
          GLOBAL.Ingredient("twigs",2),
          GLOBAL.Ingredient("cutgrass",2),
          GLOBAL.Ingredient("berries",3)
        },
        GLOBAL.TECH.NONE,
        {
          tabs = { GLOBAL.RECIPETABS.TOOLS },
          nounlock = false,
        },
        { "TOOLS", "MODS" }
    )

    if summonstaff_recipe then
        print("召唤法杖配方注册成功！(工具栏，无需科技)")
        print("配方名称:", summonstaff_recipe.name)
        print("配方标签:", summonstaff_recipe.tab)
        print("科技等级:", summonstaff_recipe.level)
    else
        print("召唤法杖配方注册失败！")
    end
    
    print("[DEBUG] 配方注册完成")
end)

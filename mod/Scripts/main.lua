-- Автоматический поиск файла конфига AutoMiner.ini
local function ResolveConfigPath()
    local paths = {
        "../../shimloader/cfg/AutoMiner.ini",
        "../../../../shimloader/cfg/AutoMiner.ini"
    }
    local appdata = os.getenv("APPDATA")
    if appdata then
        table.insert(paths, appdata .. "\\r2modmanPlus-local\\VotV\\profiles\\Default\\shimloader\\cfg\\AutoMiner.ini")
    end

    for _, p in ipairs(paths) do
        local f = io.open(p, "r")
        if f then
            f:close()
            return p
        end
    end
    return paths[1]
end

local CONFIG_PATH = ResolveConfigPath()
print("[AutoMiner] Активный путь к конфигу: " .. CONFIG_PATH .. "\n")

-- Настройки по умолчанию
local Config = {
    CollectThreshold = 10,
    CheckIntervalMs = 2000,
    DisablePowerUsage = true,
    MiningSpeedMultiplier = 1.0,
    ShowNotifications = true
}

local LastPointsMap = {}

-- Создание стандартного .ini файла для отображения в ModMenu
local function SaveDefaultIni()
    local out = io.open(CONFIG_PATH, "w")
    if out then
        out:write("[Settings]\n")
        out:write("CollectThreshold=10\n")
        out:write("CheckIntervalMs=2000\n")
        out:write("DisablePowerUsage=true\n")
        out:write("MiningSpeedMultiplier=1.0\n")
        out:write("ShowNotifications=true\n")
        out:close()
    end
end

-- Чтение настроек из AutoMiner.ini на лету
local function LoadConfig()
    local file = io.open(CONFIG_PATH, "r")
    if not file then
        SaveDefaultIni()
        return
    end

    local content = file:read("*a")
    file:close()

    for line in content:gmatch("[^\r\n]+") do
        local key, val = line:match("^%s*([%w_]+)%s*=%s*(.-)%s*$")
        if key and val then
            val = val:gsub('^"(.*)"$', "%1")

            if key == "CollectThreshold" then
                local num = tonumber(val)
                if num then Config.CollectThreshold = num end
            elseif key == "CheckIntervalMs" then
                local num = tonumber(val)
                if num and num >= 200 then Config.CheckIntervalMs = num end
            elseif key == "DisablePowerUsage" then
                local low = val:lower()
                if low == "true" or low == "1" then
                    Config.DisablePowerUsage = true
                elseif low == "false" or low == "0" then
                    Config.DisablePowerUsage = false
                end
            elseif key == "MiningSpeedMultiplier" then
                local num = tonumber(val)
                if num and num > 0 then Config.MiningSpeedMultiplier = num end
            elseif key == "ShowNotifications" then
                local low = val:lower()
                if low == "true" or low == "1" then
                    Config.ShowNotifications = true
                elseif low == "false" or low == "0" then
                    Config.ShowNotifications = false
                end
            end
        end
    end
end

local function RefreshHUD(gm)
    local funcs = {"updPoints", "updatePoints", "refreshPoints", "updHud"}
    for _, fnName in ipairs(funcs) do
        pcall(function()
            if gm and gm:IsValid() and gm[fnName] then
                gm[fnName](gm, 0)
            end
        end)
    end
end

-- Начисление поинтов через родную AddPoints и показ родного уведомления через Add Hint from Gamemode
local function GivePointsAndNotify(gm, slotObj, amount, showNotif)
    local addedViaNative = false

    -- 1. Вызываем родную функцию AddPoints напрямую (передаём число Add)
    if gm and gm:IsValid() then
        local ok = pcall(function()
            gm:AddPoints(amount)
            addedViaNative = true
        end)
    end

    if not addedViaNative and slotObj and slotObj:IsValid() and type(slotObj.Points) == "number" then
        slotObj.Points = slotObj.Points + amount
        RefreshHUD(gm)
    end

    -- 2. Вызываем родное уведомление напрямую по порядку аргументов: (self, InText, Type, debug)
    if showNotif and gm and gm:IsValid() then
        local currentBalance = (slotObj and slotObj:IsValid() and slotObj.Points) or 0
        local msg = string.format("AutoMiner: +%d pts (Balance: %d)", amount, currentBalance)

        local ok, err = pcall(function()
            gm["Add Hint from Gamemode"](gm, FText(msg), 0, false)
        end)

        -- Если вдруг вызов вернёт ошибку, выведем её в консоль UE4SS для диагностики
        if not ok then
            print("[AutoMiner] Ошибка вызова уведомления: " .. tostring(err) .. "\n")
        end
    end
end




-- Основной цикл обработки всех майнинг-ферм
local function AutoMineAndCollect()
    LoadConfig()

    local miners = FindAllOf("prop_miner_C")
    local gm = FindFirstOf("mainGamemode_C")
    local slotObj = nil

    if gm and gm:IsValid() then
        pcall(function() slotObj = gm.saveSlot end)
    end

    local totalCollectedThisTick = 0

    if miners then
        for _, miner in ipairs(miners) do
            if miner:IsValid() then
                local addr = tostring(miner:GetAddress())

                -- 1. Снятие лимита 512 поинтов и защита от перегрева/взрыва
                pcall(function()
                    miner.maxPoints = 999999
                    miner.overheat = 0.0
                end)

                -- 2. Отключение расхода электричества стойкой (если включено в конфиге)
                if Config.DisablePowerUsage then
                    pcall(function() miner.powerUsage = 0.0 end)
                    pcall(function() miner.powerUse = 0.0 end)
                    pcall(function() miner.power = 0.0 end)
                end

                -- 3. Ускорение/замедление майнинга по множителю MiningSpeedMultiplier
                pcall(function()
                    local acc = miner.accumulatedPoints
                    if type(acc) == "number" then
                        local prev = LastPointsMap[addr]
                        if prev ~= nil and acc > prev and Config.MiningSpeedMultiplier ~= 1.0 then
                            local delta = acc - prev
                            local adjustedDelta = delta * Config.MiningSpeedMultiplier
                            acc = prev + adjustedDelta
                            miner.accumulatedPoints = acc
                        end
                        LastPointsMap[addr] = acc
                    end
                end)

                -- 4. Снятие поинтов со стойки при достижении порога CollectThreshold
                if slotObj and slotObj:IsValid() then
                    pcall(function()
                        local acc = miner.accumulatedPoints
                        if type(acc) == "number" and acc >= Config.CollectThreshold then
                            local wholePoints = math.floor(acc)
                            if wholePoints >= 1 then
                                local remainder = acc - wholePoints
                                miner.accumulatedPoints = remainder
                                LastPointsMap[addr] = remainder
                                totalCollectedThisTick = totalCollectedThisTick + wholePoints
                            end
                        end
                    end)
                end
            end
        end
    end

    -- Начисляем суммарно собранные поинты за цикл и выводим уведомление
    if totalCollectedThisTick > 0 and slotObj and slotObj:IsValid() then
        GivePointsAndNotify(gm, slotObj, totalCollectedThisTick, Config.ShowNotifications)
        print(string.format("[AutoMiner] Собрано %d поинтов! Новый баланс: %d\n", totalCollectedThisTick, slotObj.Points or 0))
    end

    -- Обнуляем общую нагрузку в энергосети базы при активной галочке DisablePowerUsage
    if Config.DisablePowerUsage and gm and gm:IsValid() then
        pcall(function()
            if type(gm.usedPower) == "number" and gm.usedPower > 0 then
                gm.usedPower = 0.0
            end
        end)
    end
end

-- Инициализация и динамический перезапуск таймера при изменении CheckIntervalMs
LoadConfig()
print(string.format("[AutoMiner] Запущен! Порог=%d, Интервал=%dмс, БезЭнергии=%s, Скорость=x%.1f, Уведомления=%s\n",
    Config.CollectThreshold, Config.CheckIntervalMs, tostring(Config.DisablePowerUsage), Config.MiningSpeedMultiplier, tostring(Config.ShowNotifications)))

local function ScheduleLoop()
    LoopAsync(Config.CheckIntervalMs, function()
        pcall(AutoMineAndCollect)
        ScheduleLoop()
        return true
    end)
end

ScheduleLoop()

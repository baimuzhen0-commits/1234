-- ==========================================
-- 木子天下专属修改器 - 本地纯云端引导加载器
-- ==========================================

local pcallFunc = pcall

-- 模拟/兼容 GG 环境 (本地测试用)
if not gg then
    local visFlag = false
    gg = {
        toast = function(msg) print("[GG提示]: " .. msg) end,
        alert = function(msg) print("[GG弹窗]: " .. msg) end,
        prompt = function(title, default, type) return {default[1]} end,
        makeRequest = function(url) return {content = ""} end,
        sleep = function() end,
        isVisible = function() 
            if not visFlag then visFlag = true return true end
            return false 
        end
    }
end

pcallFunc(function()
    gg.setVisible(false)
end)

-- ==========================================
-- 1. 动态使用次数统计逻辑
-- ==========================================
local function getAndAddUsageCount()
    local countFile = gg.EXT_CACHE_DIR and (gg.EXT_CACHE_DIR .. "/muzi_usage_count.txt") or "/sdcard/muzi_usage_count.txt"
    local currentCount = 1058
    
    local file = io.open(countFile, "r")
    if file then
        local content = file:read("*all")
        file:close()
        local num = tonumber(content)
        if num then currentCount = num + 1 end
    end
    
    file = io.open(countFile, "w")
    if file then
        file:write(tostring(currentCount))
        file:close()
    end
    
    return currentCount
end

-- ==========================================
-- 2. 云端卡密验证、日期检查与核心代码加载
-- ==========================================
local function verifyAndLoadCore()
    -- 已更新為你的新 Google 试算表 API 网址
    local sheetUrl = "https://docs.google.com/spreadsheets/d/17qCAfEIGhXZXc-dC33VVqsa6CbzJZ_bZKademr2y_c0/gviz/tq?tqx=out:json"
    local maxRetries = 3
    local usageCount = getAndAddUsageCount()
    
    for i = 1, maxRetries do
        local input = gg.prompt(
            {"木子体系专属辅助：\n当前使用次数(" .. usageCount .. ") | 剩余尝试: " .. (maxRetries - i + 1)},
            {[1] = ""},
            {[1] = "text"}
        )
        
        if not input or not input[1] then
            gg.toast("已取消验证，退出脚本")
            os.exit()
        end
        
        local userCard = input[1]:gsub("^%s*(.-)%s*$", "%1")
        gg.toast("正在连接云端验证卡密...")
        
        local response = gg.makeRequest(sheetUrl)
        if response and response.content then
            local content = response.content
            local foundCard = false
            local isExpired = true
            local expiryDateStr = "未找到有效日期"
            
            -- 在 JSON 中寻找卡密位置
            local cardPos = content:find('"' .. userCard .. '"')
            if not cardPos then
                cardPos = content:find("'" .. userCard .. "'")
            end
            
            if cardPos then
                foundCard = true
                local subContent = content:sub(cardPos, cardPos + 150)
                
                -- 精确匹配纯年月日格式：YYYY-MM-DD 或 YYYY/MM/DD
                local y, m, d = subContent:match("(%d%d%d%d)[%-%:/](%d%d?)[%-%:/](%d%d?)")
                if y and m and d then
                    local timeTable = {
                        year  = tonumber(y),
                        month = tonumber(m),
                        day   = tonumber(d),
                        hour  = 23, min = 59, sec = 59
                    }
                    expiryDateStr = string.format("%04d-%02d-%02d", timeTable.year, timeTable.month, timeTable.day)
                    local expirySec = os.time(timeTable)
                    local currentSec = os.time()
                    
                    if expirySec and expirySec >= currentSec then
                        isExpired = false
                    else
                        isExpired = true
                    end
                else
                    isExpired = true
                    expiryDateStr = "日期格式解析失败"
                end
            end
            
            if not foundCard then
                gg.toast("卡密不存在，請重新輸入！")
            elseif isExpired then
                gg.alert("验证失败：该卡密已过期或日期格式不符！\n\n到期日期: " .. expiryDateStr)
                os.exit()
            else
                gg.toast("卡密验证成功，正在从试算表加载核心模組...")
                
                -- ==========================================
                -- 3. 从试算表提取并执行核心代码
                -- ==========================================
                -- 请确保你的试算表代码最上方写有 START_CORE，最下方写有 END_CORE
                local coreStart, coreEnd = content:find("START_CORE(.-)END_CORE")
                
                if coreStart then
                    local rawCoreCode = content:sub(coreStart + 10, coreEnd - 9)
                    
                    -- 清洗 Google 试算表 JSON 转义符
                    rawCoreCode = rawCoreCode:gsub("\\n", "\n"):gsub('\\"', '"'):gsub("\\\\", "\\")
                    
                    local loadedFunction, err = load(rawCoreCode)
                    if loadedFunction then
                        gg.toast("核心加载成功，欢迎使用！")
                        loadedFunction() -- 启动核心选单
                        return true
                    else
                        gg.alert("核心模組解析失敗：\n" .. tostring(err))
                        os.exit()
                    end
                else
                    gg.alert("错误：无法在试算表中找到核心代码区块（请检查是否有加 START_CORE 与 END_CORE）！")
                    os.exit()
                end
            end
        else
            gg.toast("网络连线异常，无法完成验证！")
        end
    end
    
    gg.alert("错误次数过多, 验证失败, 脚本已退出。")
    os.exit()
end

-- 执行云端验证与核心加载
verifyAndLoadCore()

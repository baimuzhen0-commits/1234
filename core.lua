-- ==========================================
-- 木子体系 - 云端验证与纯文字直链加载器 (简体中文版)
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

local function verifyAndLoadCore()
    -- 卡密验证表单依然使用你的 Google 试算表
    local cardSheetUrl = "https://docs.google.com/spreadsheets/d/1QxkrMH-KlAT6ybKb1tgfa7AymjyqstjFhmT0fuQoEbw/gviz/tq?tqx=out:json"
    
    -- 功能代码改从 GitHub 的 Raw 纯文字直鏈获取（请在这里填入你刚刚复制的 Raw 链接）
    local codeRawUrl = "https://raw.githubusercontent.com/你的用户名/你的仓库名/main/code.lua"
    
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
        
        local cardResponse = gg.makeRequest(cardSheetUrl)
        if cardResponse and cardResponse.content then
            local cardContent = cardResponse.content
            local foundCard = false
            local isExpired = true
            local expiryDateStr = "未找到有效日期"
            
            local cardPos = cardContent:find('"' .. userCard .. '"')
            if not cardPos then
                cardPos = cardContent:find("'" .. userCard .. "'")
            end
            
            if cardPos then
                foundCard = true
                local subContent = cardContent:sub(cardPos, cardPos + 150)
                
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
                gg.toast("卡密不存在，请重新输入！")
            elseif isExpired then
                gg.alert("验证失败：该卡密已过期或日期格式不符！\n\n到期日期: " .. expiryDateStr)
                os.exit()
            else
                gg.toast("卡密验证成功，正在下载核心代码...")
                
                local codeResponse = gg.makeRequest(codeRawUrl)
                if codeResponse and codeResponse.content then
                    local rawCoreCode = codeResponse.content
                    
                    -- 直接加载纯文本 Lua，告别所有斜线与转义报错
                    local loadedFunction, err = load(rawCoreCode)
                    if loadedFunction then
                        gg.toast("核心加载成功，欢迎使用！")
                        local status, runErr = pcall(loadedFunction)
                        if not status then
                            gg.alert("核心运行时发生错误：\n" .. tostring(runErr))
                            os.exit()
                        end
                        return true
                    else
                        gg.alert("核心模块解析失败：\n" .. tostring(err))
                        os.exit()
                    end
                else
                    gg.toast("网络连线异常，无法下载 GitHub 核心代码！")
                end
            end
        else
            gg.toast("网络连线异常，无法完成验证！")
        end
    end
    
    gg.alert("错误次数过多, 验证失败, 脚本已退出。")
    os.exit()
end

verifyAndLoadCore()

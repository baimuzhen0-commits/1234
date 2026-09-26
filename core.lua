-- ==========================================
-- 2. 云端卡密验证与核心代码加载 (极速流畅版)
-- ==========================================

local function getAndAddUsageCount()
    return 1
end

local function verifyAndLoadCore()
    local cardSheetUrl = "https://docs.google.com/spreadsheets/d/1QxkrMH-KlAT6ybKb1tgfa7AymjyqstjFhmT0fuQoEbw/gviz/tq?tqx=out:json"
    local codeSheetUrl = "https://docs.google.com/spreadsheets/d/17qCAfEIGhXZXc-dC33VVqsa6CbzJZ_bZKademr2y_c0/gviz/tq?tqx=out:json"
    
    local maxRetries = 3
    local usageCount = getAndAddUsageCount()
    
    for i = 1, maxRetries do
        -- 一进来或是重试时，立刻精准弹窗要求输入卡密
        local input = gg.prompt(
            {"木子体系专属辅助：\n当前使用次数(" .. tostring(usageCount) .. ") | 剩余尝试: " .. tostring(maxRetries - i + 1)},
            {[1] = ""},
            {[1] = "text"}
        )
        
        if not input or not input[1] then
            gg.toast("已取消验证，退出脚本")
            os.exit()
        end
        
        local userCard = tostring(input[1]):gsub("^%s*(.-)%s*$", "%1")
        gg.toast("正在连接云端验证卡密...")
        
        local cardResponse = gg.makeRequest(cardSheetUrl)
        if cardResponse and cardResponse.content then
            local cardContent = cardResponse.content
            local foundCard = false
            local isExpired = true
            local expiryDateStr = "未找到有效日期"
            
            local cardPos = cardContent:find(userCard, 1, true)
            
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
                    expiryDateStr = "卡密错误"
                end
            end
            
            if not foundCard then
                gg.toast("卡密不存在，請重新輸入！")
            elseif isExpired then
                gg.alert("[WIG]卡密已过期！\n\n到期日期: " .. expiryDateStr)
                os.exit()
            else
                gg.toast("卡密验证成功，正在加载核心...")
                
                -- 验证通过，立刻去代码表单抓取核心
                local codeResponse = gg.makeRequest(codeSheetUrl)
                if codeResponse and codeResponse.content then
                    local codeContent = codeResponse.content
                    local coreStart, coreEnd = codeContent:find("START_CORE(.-)END_CORE")
                    
                    if coreStart then
                        local rawCoreCode = codeContent:sub(coreStart + 10, coreEnd - 9)
                        rawCoreCode = rawCoreCode:gsub("\\n", "\n"):gsub('\\"', '"'):gsub("\\\\", "\\")
                        
                        local loadedFunction, err = load(rawCoreCode)
                        if loadedFunction then
                            gg.toast("核心加载成功，欢迎使用！")
                            local status, runErr = pcall(loadedFunction)
                            if not status then
                                gg.alert("核心運行時報錯：\n" .. tostring(runErr))
                                os.exit()
                            end
                            return true
                        else
                            gg.alert("核心模組解析失敗：\n" .. tostring(err))
                            os.exit()
                        end
                    else
                        gg.alert("错误：无法在核心试算表中找到代码区块！")
                        os.exit()
                    end
                else
                    gg.toast("网络连线异常，无法下载核心代码！")
                end
            end
        else
            gg.toast("网络连线异常，无法完成卡密验证！")
        end
    end
    
    gg.alert("错误次数过多, 验证失败, 脚本已退出。")
    os.exit()
end

-- 直接觸發，點擊開啟時第一時間彈出輸入框
verifyAndLoadCore()

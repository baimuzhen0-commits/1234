local _u1, _u2, _u3 = string.char, table.concat, pcall

-- ==================== 防封与大厅防模块 ====================
function LobbyAntiBan()
    pcall(function()
        gg.clearResults()
        gg.setRanges(gg.REGION_ANONYMOUS | gg.REGION_C_ALLOC | gg.REGION_CODE_APP)
        gg.toast("大厅防已成功开启")
    end)
end

function CoreAntiBan()
    pcall(function()
        gg.clearResults()
        gg.setRanges(gg.REGION_ANONYMOUS | gg.REGION_C_ALLOC | gg.REGION_CODE_APP | gg.REGION_CODE_SYS)
        gg.toast("核心防封已成功开启")
    end)
end

function AntiBanMenu()
    while true do
        local c = gg.choice({
            "大厅防",
            "防封",
            "返回上一级"
        }, nil, "防封区")
        
        if not c or c == 3 then break end
        if c == 1 then
            LobbyAntiBan()
        elseif c == 2 then
            CoreAntiBan()
        end
    end
end

-- ==================== 远端 Google Sheets 卡密验证模块 ====================
function CheckCardKey()
    local csvUrl = "https://docs.google.com/spreadsheets/d/1QxkrMH-KlAT6ybKb1tgfa7AymjyqstjFhmT0fuQoEbw/export?format=csv"
    
    while true do
        local input = gg.prompt(
            {"请输入您的专属卡密（支持英文与数字）："},
            {""},
            {"text"}
        )
        
        if input == nil then
            gg.toast("已取消验证")
            os.exit()
        end
        
        local userKey = tostring(input[1]):gsub("^%s*(.-)%s*$", "%1")
        
        if userKey == "" then
            gg.toast("卡密不能为空，请重新输入！")
        else
            gg.toast("正在连线云端资料库验证...")
            local response = gg.makeRequest(csvUrl)
            
            if not response or not response.content then
                gg.toast("无法连线至云端伺服器，请检查网路！")
                os.exit()
            end
            
            local content = response.content
            local found = false
            local expiryDate = "未知期限"
            
            for line in content:gmatch("[^\r\n]+") do
                if not line:match("卡密") and not line:match("Key") then
                    local k, d = line:match("([^,]+),([^,]+)")
                    if not k then
                        k, d = line:match("([^\t]+)\t([^\t]+)")
                    end
                    
                    if k then
                        k = k:gsub("^%s*(.-)%s*$", "%1"):gsub('"', '')
                        if d then
                            d = d:gsub("^%s*(.-)%s*$", "%1"):gsub('"', '')
                        end
                        
                        if k == userKey then
                            found = true
                            if d and d ~= "" then
                                expiryDate = d
                            end
                            break
                        end
                    end
                end
            end
            
            if found then
                gg.toast("验证成功！有效期限至：" .. expiryDate)
                print("卡密授权成功。到期日: " .. expiryDate)
                LobbyAntiBan()
                _mainMenu()
                break
            else
                gg.toast("卡密错误或已过期失效，请重新输入！")
            end
        end
    end
end

local function _m1(_s1, _s2, _s3, _s4, _s5)
    _u3(function()
        gg.clearResults()
        gg.setRanges(_s4)
        if _s1[1][1] ~= false then
            gg.searchAddress(_s1[1][1], 0xFFFFFFFF, _s1[1][4] or _s3, gg.SIGN_EQUAL, _s1[1][5] or 1, _s1[1][6] or -1)
        end
        gg.searchNumber(_s1[1][2], _s1[1][4] or _s3, false, gg.SIGN_EQUAL, _s1[1][5] or 1, _s1[1][6] or -1)
        
        local _c1 = gg.getResultCount()
        local _r1 = gg.getResults(_c1)
        gg.clearResults()
        
        local _d1 = {}
        local _b1 = _s1[1][3]
        if (_c1 > 0) then
            for _i, _v in ipairs(_r1) do
                _v.isUseful = true
            end
            for _k = 2, #_s1 do
                local _tmp = {}
                local _offset = _s1[_k][2] - _b1
                local _num = _s1[_k][1]
                for _i, _v in ipairs(_r1) do
                    _tmp[#_tmp + 1] = {}
                    _tmp[#_tmp].address = _v.address + _offset
                    _tmp[#_tmp].flags = _s1[_k][3] or _s3
                end
                _tmp = gg.getValues(_tmp)
                for _i, _v in ipairs(_tmp) do
                    local _vals
                    if _v.flags == 16 or _v.flags == 64 then
                        _vals = tostring(_v.value):sub(1, 6)
                        _num = tostring(_num):sub(1, 6)
                    else
                        _vals = _v.value
                    end
                    if tostring(_vals) ~= tostring(_num) then
                        _r1[_i].isUseful = false
                    end
                end
            end
            for _i, _v in ipairs(_r1) do
                if (_v.isUseful) then
                    _d1[#_d1 + 1] = _v.address
                end
            end
            if (#_d1 > 0) then
                local _t1 = {}
                for _i = 1, #_d1 do
                    for _k, _w in ipairs(_s2) do
                        local _offset = _w[2] - _b1
                        if _w[1] ~= false then
                            _t1[#_t1 + 1] = {}
                            _t1[#_t1].address = _d1[_i] + _offset
                            _t1[#_t1].flags = _w[3] or _s3
                            _t1[#_t1].value = _w[1]
                        end
                    end
                end
                gg.setValues(_t1)
                gg.clearResults()
                gg.toast(_s5 .. " 开启成功 ")
            else
                gg.clearResults()
                gg.toast(_s5 .. " 开启成功")
            end
        else
            gg.clearResults()
            gg.toast(_s5 .. " 没开成功")
        end
    end)
end

local function _range()
    gg.alert("木子自定义范围")
    local a = gg.prompt({"自己看要多少"}, {[1] = "4.25"}, {[1] = "text"})
    if a and a[1] then
        _m1(
            {{false, 0.15, 0, 16, nil, nil}, {1, -16, 4}},
            {{a[1], 0, 16, false}},
            16, 4, "范围锁头"
        )
    end
end

local function _armor()
    gg.alert("自定义锁甲")
    local a = gg.prompt({"输入锁甲数值"}, {[1] = "0"}, {[1] = "text"})
    if a and a[1] then
        _m1(
            {{false, 0.15, 0, 16, nil, nil}, {1, -16, 4}},
            {{a[1], 0, 16, false}},
            16, 4, "锁甲修改"
        )
    end
end

local function HS3()
    pcall(function()
        local _p = gg.prompt({"请输入高跳修改数值:"}, {[1] = "200"}, {[1] = "text"})
        if not _p then return end
        local _val = tonumber(_p[1]) or 200

        gg.clearResults()
        gg.setRanges(32)
        gg.searchNumber("0.1;0.3;200;1.8", gg.TYPE_DOUBLE, false, gg.SIGN_EQUAL, 0, -1)
        gg.refineNumber("0.1", gg.TYPE_DOUBLE)

        local results = gg.getResults(gg.getResultCount())
        if #results > 0 then
            for i, result in ipairs(results) do
                result.name = "高跳" .. i  
            end
            gg.addListItems(results)
            gg.toast("已找到 " .. #results .. " 个结果")

            for i, result in ipairs(results) do
                result.value = _val  
                result.freeze = true  
            end
            gg.setValues(results)
            gg.toast("高跳修改成功：" .. _val)
        else
            gg.toast("未找到任何匹配的结果")
        end
    end)
end

function HS5()
    gg.clearResults()
    gg.setRanges(gg.REGION_C_ALLOC)
    gg.searchNumber("1123024896D;0F;120;0.2;0.4;0.6", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1)
    gg.refineNumber("1123024896D;0F", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1)
    local res = gg.getResults(gg.getResultCount())
    if #res > 0 then
        for _, v in ipairs(res) do
            v.value = 120
            v.freeze = true
        end
        gg.addListItems(res)
        gg.setValues(res)
        gg.toast("千逐内透开启成功")
    else
        gg.toast("未找到任何匹配的结果")
    end
end

function b3()
    gg.clearResults()
    gg.setRanges(gg.REGION_VIDEO)
    gg.searchNumber("4923D;-1;0.99900001287::", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1)
    gg.searchNumber("0.99900001287", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1)
    if gg.getResultCount() > 0 then
        gg.getResults(100)
        gg.editAll("2;999;2;2", gg.TYPE_FLOAT)
        gg.toast("国际服彩色渐变内透开启成功")
    else
        gg.toast("未找到匹配結果")
    end
    gg.clearResults()
end

local function _speed()
    local _p = gg.prompt({"输入移速 千万不要超过1.7不然拉回卡死你、1.31几乎无拉回:"}, {[1] = "1.31"}, {[1] = "text"})
    if not _p then return end
    local _val = _p[1]

    pcall(function()
        gg.clearResults()
        gg.searchNumber("1.0", gg.TYPE_DOUBLE, false, gg.SIGN_EQUAL, 0, -1)
        local count2 = gg.getResultCount()
        if count2 > 0 then
            gg.getResults(1100)
            gg.editAll(_val, gg.TYPE_DOUBLE)
            gg.toast("移速成功")
        else
            gg.clearResults()
            gg.searchNumber("1;0.84::60", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1)
            gg.searchNumber("1", gg.TYPE_DOUBLE, false, gg.SIGN_EQUAL, 0, -1)
            gg.getResults(100)
            gg.editAll(_val, gg.TYPE_DOUBLE)
            gg.toast("跳远成功")
        end
    end)

    gg.clearResults()
    pcall(function() gg.setRanges(32) end)
    gg.searchNumber("0.1", gg.TYPE_DOUBLE, false, gg.SIGN_EQUAL, 0, -1)

    pcall(function()
        gg.clearResults()
        gg.searchNumber("1.0", gg.TYPE_DOUBLE, false, gg.SIGN_EQUAL, 0, -1)
        local count2 = gg.getResultCount()
        if count2 > 0 then
            gg.getResults(1100)
            gg.editAll(_val, gg.TYPE_DOUBLE)
            gg.toast("确保开启执行成功")
        else
            gg.clearResults()
            gg.searchNumber("1;0.84::60", gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1)
            gg.searchNumber("1", gg.TYPE_DOUBLE, false, gg.SIGN_EQUAL, 0, -1)
            gg.getResults(100)
            gg.editAll(_val, gg.TYPE_DOUBLE)
            gg.toast("确保开启执行成功")
        end
    end)

    gg.clearResults()
    pcall(function() gg.setRanges(32) end)
    gg.searchNumber("0.1", gg.TYPE_DOUBLE, false, gg.SIGN_EQUAL, 0, -1)
end

function p()
    local qmnb = {
        {memory = gg.REGION_C_ALLOC},
        {value = 1471235529, type = gg.TYPE_DWORD},
        {lv = 80, offset = -8, type = gg.TYPE_BYTE},
        {lv = -80, offset = -80, type = gg.TYPE_BYTE},
        {lv = -1679557945, offset = 24, type = gg.TYPE_DWORD}
    }
    local qmxg = {
        {value = -80, offset = -8, type = gg.TYPE_BYTE, freeze = true},
        {value = -80, offset = -80, type = gg.TYPE_BYTE, freeze = true}
    }
    xqmnb_helper = function(t)
        local gg_setRanges, gg_searchNumber, gg_getResults, gg_editAll, gg_clearResults = gg.setRanges, gg.searchNumber, gg.getResults, gg.editAll, gg.clearResults
        gg_clearResults()
        for _, v in ipairs(t) do
            if v.memory then gg_setRanges(v.memory) end
            if v.value then gg_searchNumber(v.value, v.type or gg.TYPE_DWORD, false, gg.SIGN_EQUAL, 0, -1) end
        end
        if qmxg then
            local res = gg_getResults(10000)
            if res and #res > 0 then
                for _, v in ipairs(res) do v.value, v.freeze = qmxg[1].value, qmxg[1].freeze or false end
                gg.setValues(res)
            end
        end
    end
    xqmnb_helper(qmnb)
    gg.clearResults()
    gg.setRanges(gg.REGION_C_ALLOC)
    gg.searchNumber('-9.80000019073F;10000000000F::', gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1)
    gg.searchNumber('10000000000', gg.TYPE_FLOAT, false, gg.SIGN_EQUAL, 0, -1)
    gg.getResults(500)
    gg.editAll("-20", gg.TYPE_FLOAT)
    gg.toast("转圈圈开启")
end

function q()
    gg.clearResults()
    gg.setRanges(gg.REGION_CODE_APP)
    gg.searchNumber("1000", gg.TYPE_DOUBLE, false, gg.SIGN_EQUAL, 0, -1)
    gg.getResults(100)
    gg.editAll("100.123456", gg.TYPE_DOUBLE)
    gg.toast("秒落开启")
    gg.sleep(5000)
    gg.clearResults()
    gg.setRanges(gg.REGION_CODE_APP)
    gg.searchNumber("100.123456", gg.TYPE_DOUBLE, false, gg.SIGN_EQUAL, 0, -1)
    gg.getResults(100)
    gg.editAll("1000", gg.TYPE_DOUBLE)
    gg.toast("秒落关闭")
end

function takong()
    gg.editAll("999", gg.TYPE_FLOAT)
    gg.toast("踏空开启成功")
    gg.clearResults()
    gg.setRanges(gg.REGION_C_ALLOC)
    gg.searchNumber("3.0E;500.0E;4.9e-324E;10.0E:", gg.TYPE_DOUBLE, false, gg.SIGN_EQUAL, 0, -1)
    gg.searchNumber("3", gg.TYPE_DOUBLE, false, gg.SIGN_EQUAL, 0, -1)
    gg.getResults(100)
    gg.editAll("50", gg.TYPE_DOUBLE)
end

-- ==================== 新增遁地功能模块 ====================
function duandiOpen1()
    gg.toast("正在执行：遁地开启 1")
    -- 在此加入遁地开启1的具体修改逻辑
end

function duandiOpen2()
    gg.toast("正在执行：遁地开启 2")
    -- 在此加入遁地开启2的具体修改逻辑
end

function duandiRestore1()
    gg.toast("正在执行：遁地恢复 1")
    -- 在此加入遁地恢复1的具体修改逻辑
end

function duandiRestore2()
    gg.toast("正在执行：遁地恢复 2")
    -- 在此加入遁地恢复2的具体修改逻辑
end

function _hackMenu()
    while true do
        local c = gg.choice({
            "自定义范围锁头", 
            "自定义锁甲", 
            "自定义高跳(千逐二改)", 
            "千逐内透", 
            "国际服彩色渐变内透", 
            "自定义加速", 
            "转圈圈", 
            "秒落开关", 
            "踏空", 
            "遁地开启 1",
            "遁地开启 2",
            "遁地恢复 1",
            "遁地恢复 2",
            "返回上一级"
        }, nil, "打狗区")
        
        if not c or c == 14 then break end
        if c == 1 then _range()
        elseif c == 2 then _armor()
        elseif c == 3 then HS3()
        elseif c == 4 then HS5()
        elseif c == 5 then b3()
        elseif c == 6 then _speed()
        elseif c == 7 then p()
        elseif c == 8 then q()
        elseif c == 9 then takong()
        elseif c == 10 then duandiOpen1()
        elseif c == 11 then duandiOpen2()
        elseif c == 12 then duandiRestore1()
        elseif c == 13 then duandiRestore2()
        end
    end
end

function _mainMenu()
    while true do
        local _choice = gg.choice({
            "打狗区",
            "防封区",
            "退出脚本"
        }, nil, "木子体系 · 千逐核心")
        
        if _choice == nil then 
            break 
        end
        
        if _choice == 1 then
            _hackMenu()
        elseif _choice == 2 then
            AntiBanMenu()
        elseif _choice == 3 then
            gg.clearResults()
            os.exit()
        end
    end
end

CheckCardKey()

while true do
    if gg.isVisible() then
        gg.setVisible(false)
        _mainMenu()
    end
    gg.sleep(100)
end

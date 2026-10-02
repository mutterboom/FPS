-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Boomxico FPS Boost v1.1                                      ║
-- ║  ฟีเจอร์: Auto-detect + เลือกโหมดเองได้ Light/Medium/Potato  ║
-- ║  มีปุ่มพับ + ปุ่มเปิด/ปิดสคริปต์                              ║
-- ╚═══════════════════════════════════════════════════════════════╝
do
    if not game:IsLoaded() then game.Loaded:Wait() end
    
    local P = game:GetService("Players")
    local U = game:GetService("UserInputService")
    local L = game:GetService("Lighting")
    local LP = P.LocalPlayer
    local isPC = U.KeyboardEnabled and not U.TouchEnabled
    local isMobile = U.TouchEnabled
    
    -- ═══════════════════════════════════════════
    -- ★ ตรวจสอบสเปก
    -- ═══════════════════════════════════════════
    local vp = workspace.CurrentCamera.ViewportSize
    local minSide = math.min(vp.X, vp.Y)
    local totalPixels = vp.X * vp.Y
    local memUsageMB = gcinfo() / 1024
    
    local deviceType, autoTier
    if isMobile then
        if minSide < 380 or totalPixels < 300000 then
            deviceType = "Mobile-เล็ก"; autoTier = "potato"
        elseif minSide < 450 or totalPixels < 500000 then
            deviceType = "Mobile-กลาง"; autoTier = "medium"
        elseif minSide < 600 then
            deviceType = "Mobile-ใหญ่"; autoTier = "medium"
        else
            deviceType = "Tablet"; autoTier = "light"
        end
    else
        if vp.Y < 700 then
            deviceType = "PC-เล็ก"; autoTier = "medium"
        elseif vp.Y < 900 then
            deviceType = "PC-กลาง"; autoTier = "light"
        else
            deviceType = "PC-ใหญ่"; autoTier = "light"
        end
    end
    
    if memUsageMB < 300 then
        if autoTier == "potato" then autoTier = "medium"
        elseif autoTier == "medium" then autoTier = "light" end
    end
    
    print("[FPS Boost] Platform:", deviceType, "| Auto Tier:", autoTier)
    print("[FPS Boost] Screen:", vp.X, "x", vp.Y, "| Mem:", math.floor(memUsageMB) .. "MB")
    
    -- ═══════════════════════════════════════════
    -- ★ State
    -- ═══════════════════════════════════════════
    local isOn = false
    local currentTier = autoTier
    local scriptAlive = true
    
    local backup = {
        lighting = {
            GlobalShadows = L.GlobalShadows,
            FogEnd = L.FogEnd,
            Brightness = L.Brightness,
            Ambient = L.Ambient,
            OutdoorAmbient = L.OutdoorAmbient,
            EnvironmentDiffuseScale = L.EnvironmentDiffuseScale,
            EnvironmentSpecularScale = L.EnvironmentSpecularScale,
        },
        postEffects = {},
        sky = nil,
        atmosphere = nil,
        particles = {},
        decals = {},
        terrain = {WaterWaveSize = 0, WaterWaveSpeed = 0}
    }
    
    -- ═══════════════════════════════════════════
    -- ★ ฟังก์ชัน FPS
    -- ═══════════════════════════════════════════
    local function enableFPS()
        if isOn then return end
        isOn = true
        local tier = currentTier
        
        -- 1) Particle/Fire/Smoke/Sparkles/Trail/Beam
        for _, o in ipairs(workspace:GetDescendants()) do
            if o:IsA("ParticleEmitter") or o:IsA("Fire") or o:IsA("Smoke") 
               or o:IsA("Sparkles") or o:IsA("Trail") or o:IsA("Beam") then
                if o.Enabled then
                    table.insert(backup.particles, {o=o, v=true})
                    o.Enabled = false
                end
            end
        end
        
        -- 2) Decal/Texture (Medium + Potato)
        if tier == "medium" or tier == "potato" then
            for _, o in ipairs(workspace:GetDescendants()) do
                if o:IsA("Decal") or o:IsA("Texture") then
                    if o.Transparency < 1 then
                        table.insert(backup.decals, {o=o, v=o.Transparency})
                        o.Transparency = 1
                    end
                end
            end
        end
        
        -- 3) Lighting
        L.GlobalShadows = false
        L.FogEnd = 100000
        L.Brightness = 2
        
        if tier == "potato" then
            L.Ambient = Color3.fromRGB(200,200,200)
            L.OutdoorAmbient = Color3.fromRGB(200,200,200)
            L.EnvironmentDiffuseScale = 0
            L.EnvironmentSpecularScale = 0
        elseif tier == "medium" then
            L.Ambient = Color3.fromRGB(180,180,180)
            L.OutdoorAmbient = Color3.fromRGB(180,180,180)
        end
        
        -- 4) PostEffect
        for _, o in ipairs(L:GetChildren()) do
            if o:IsA("PostEffect") and o.Enabled then
                table.insert(backup.postEffects, o)
                o.Enabled = false
            end
        end
        
        -- 5) Sky + Atmosphere (Potato)
        if tier == "potato" then
            local sky = L:FindFirstChildOfClass("Sky")
            if sky then backup.sky = sky; sky.Parent = nil end
            local atm = L:FindFirstChildOfClass("Atmosphere")
            if atm then backup.atmosphere = atm; atm.Parent = nil end
        end
        
        -- 6) Terrain Water
        local terrain = workspace:FindFirstChildOfClass("Terrain")
        if terrain then
            backup.terrain.WaterWaveSize = terrain.WaterWaveSize
            backup.terrain.WaterWaveSpeed = terrain.WaterWaveSpeed
            terrain.WaterWaveSize = 0
            terrain.WaterWaveSpeed = 0
        end
        
        print("[FPS Boost] เปิดโหมด:", tier)
    end
    
    local function disableFPS()
        if not isOn then return end
        isOn = false
        
        -- คืน Particle
        for _, d in ipairs(backup.particles) do
            if d.o and d.o.Parent then pcall(function() d.o.Enabled = d.v end) end
        end
        backup.particles = {}
        
        -- คืน Decal
        for _, d in ipairs(backup.decals) do
            if d.o and d.o.Parent then pcall(function() d.o.Transparency = d.v end) end
        end
        backup.decals = {}
        
        -- คืน Lighting
        for k, v in pairs(backup.lighting) do
            pcall(function() L[k] = v end)
        end
        
        -- คืน PostEffect
        for _, o in ipairs(backup.postEffects) do
            if o and o.Parent then pcall(function() o.Enabled = true end) end
        end
        backup.postEffects = {}
        
        -- คืน Sky + Atmosphere
        if backup.sky then pcall(function() backup.sky.Parent = L end) end
        if backup.atmosphere then pcall(function() backup.atmosphere.Parent = L end) end
        backup.sky = nil; backup.atmosphere = nil
        
        -- คืน Terrain
        local terrain = workspace:FindFirstChildOfClass("Terrain")
        if terrain then
            terrain.WaterWaveSize = backup.terrain.WaterWaveSize
            terrain.WaterWaveSpeed = backup.terrain.WaterWaveSpeed
        end
        
        print("[FPS Boost] ปิด")
    end
    
    -- ═══════════════════════════════════════════
    -- ★ UI
    -- ═══════════════════════════════════════════
    local gui = Instance.new("ScreenGui")
    gui.Name = "BoomFPSBoost"
    gui.ResetOnSpawn = false
    gui.Parent = LP:WaitForChild("PlayerGui")
    
    -- ปุ่มพับ (กลม)
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 60, 0, 60)
    toggleBtn.Position = UDim2.new(0, 20, 0, 100)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    toggleBtn.BackgroundTransparency = 0.2
    toggleBtn.Text = "⚙"
    toggleBtn.TextColor3 = Color3.fromRGB(255, 200, 0)
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextSize = 26
    toggleBtn.Active = true
    toggleBtn.Draggable = true
    toggleBtn.Parent = gui
    Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(1, 0)
    local toggleStroke = Instance.new("UIStroke", toggleBtn)
    toggleStroke.Color = Color3.fromRGB(255, 180, 0)
    toggleStroke.Thickness = 2
    
    -- หน้าต่างเมนู
    local menu = Instance.new("Frame")
    menu.Size = UDim2.new(0, 220, 0, 260)
    menu.Position = UDim2.new(0, 90, 0, 100)
    menu.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    menu.BackgroundTransparency = 0.1
    menu.Visible = false
    menu.Active = true
    menu.Draggable = true
    menu.Parent = gui
    Instance.new("UICorner", menu).CornerRadius = UDim.new(0, 14)
    local menuStroke = Instance.new("UIStroke", menu)
    menuStroke.Color = Color3.fromRGB(255, 180, 0)
    menuStroke.Thickness = 1.5
    
    -- หัวข้อ
    local mTitle = Instance.new("TextLabel")
    mTitle.Size = UDim2.new(1, 0, 0, 32)
    mTitle.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
    mTitle.Text = "FPS Boost | By Boomxico"
    mTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    mTitle.Font = Enum.Font.GothamBold
    mTitle.TextSize = 13
    mTitle.Parent = menu
    Instance.new("UICorner", mTitle).CornerRadius = UDim.new(0, 14)
    
    -- ข้อมูลอุปกรณ์
    local infoLbl = Instance.new("TextLabel")
    infoLbl.Size = UDim2.new(1, -10, 0, 32)
    infoLbl.Position = UDim2.new(0, 5, 0, 36)
    infoLbl.BackgroundTransparency = 1
    infoLbl.Text = deviceType .. " | " .. vp.X .. "x" .. vp.Y .. "\n" .. math.floor(memUsageMB) .. "MB | Auto: " .. autoTier:upper()
    infoLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
    infoLbl.Font = Enum.Font.SourceSans
    infoLbl.TextSize = 11
    infoLbl.TextWrapped = true
    infoLbl.Parent = menu
    
    -- ปุ่มเลือกโหมด
    local modeRow = Instance.new("Frame")
    modeRow.Size = UDim2.new(0.9, 0, 0, 36)
    modeRow.Position = UDim2.new(0.05, 0, 0.28, 0)
    modeRow.BackgroundTransparency = 1
    modeRow.Parent = menu
    
    local function mkModeBtn(txt, xPos, tier)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0.31, 0, 1, 0)
        b.Position = UDim2.new(xPos, 0, 0, 0)
        b.BackgroundColor3 = (currentTier == tier) and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(50, 50, 70)
        b.Text = txt
        b.TextColor3 = Color3.fromRGB(255, 255, 255)
        b.Font = Enum.Font.GothamBold
        b.TextSize = 11
        b.Parent = modeRow
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
        return b
    end
    
    local btnLight = mkModeBtn("Light", 0, "light")
    local btnMedium = mkModeBtn("Medium", 0.345, "medium")
    local btnPotato = mkModeBtn("Potato", 0.69, "potato")
    
    local function refreshModeBtns()
        btnLight.BackgroundColor3 = (currentTier == "light") and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(50, 50, 70)
        btnMedium.BackgroundColor3 = (currentTier == "medium") and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(50, 50, 70)
        btnPotato.BackgroundColor3 = (currentTier == "potato") and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(50, 50, 70)
    end
    
    local function setTier(t)
        -- ปิดก่อนถ้าเปิดอยู่
        if isOn then disableFPS() end
        currentTier = t
        refreshModeBtns()
        -- ถ้าเปิดอยู่ → เปิดใหม่ด้วยโหมดใหม่
        if isOn then enableFPS() end
    end
    
    btnLight.MouseButton1Click:Connect(function() setTier("light") end)
    btnMedium.MouseButton1Click:Connect(function() setTier("medium") end)
    btnPotato.MouseButton1Click:Connect(function() setTier("potato") end)
    
    -- ปุ่มเปิด/ปิด FPS
    local powerBtn = Instance.new("TextButton")
    powerBtn.Size = UDim2.new(0.9, 0, 0, 40)
    powerBtn.Position = UDim2.new(0.05, 0, 0.56, 0)
    powerBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    powerBtn.Text = "เปิด FPS Boost"
    powerBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    powerBtn.Font = Enum.Font.GothamBold
    powerBtn.TextSize = 14
    powerBtn.Parent = menu
    Instance.new("UICorner", powerBtn).CornerRadius = UDim.new(0, 10)
    
    powerBtn.MouseButton1Click:Connect(function()
        if isOn then
            disableFPS()
            powerBtn.Text = "เปิด FPS Boost"
            powerBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
            toggleBtn.Text = "⚙"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
        else
            enableFPS()
            powerBtn.Text = "ปิด FPS Boost"
            powerBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
            toggleBtn.Text = "✓"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
        end
    end)
    
    -- ปุ่มปิดสคริปต์ทั้งหมด
    local killBtn = Instance.new("TextButton")
    killBtn.Size = UDim2.new(0.9, 0, 0, 32)
    killBtn.Position = UDim2.new(0.05, 0, 0.78, 0)
    killBtn.BackgroundColor3 = Color3.fromRGB(120, 20, 20)
    killBtn.Text = "ปิดสคริปต์ทั้งหมด"
    killBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    killBtn.Font = Enum.Font.GothamBold
    killBtn.TextSize = 12
    killBtn.Parent = menu
    Instance.new("UICorner", killBtn).CornerRadius = UDim.new(0, 10)
    
    killBtn.MouseButton1Click:Connect(function()
        scriptAlive = false
        if isOn then disableFPS() end
        if gui then gui:Destroy() end
        print("[FPS Boost] ปิดสคริปต์ทั้งหมด")
    end)
    
    -- ปุ่มพับ toggle
    toggleBtn.MouseButton1Click:Connect(function()
        menu.Visible = not menu.Visible
    end)
    
    print("[FPS Boost] โหลดเสร็จ | Platform:", deviceType, "| Auto Tier:", autoTier)
end

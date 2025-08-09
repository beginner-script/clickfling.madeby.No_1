local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local mouse = localPlayer:GetMouse()

local flingEnabled = false -- 버튼으로 플링 활성화 상태 제어
local flingActive = false -- 실제 플링 동작 중 상태
local originalCFrame = nil
local angularVelocity = nil
local connection = nil
local targetCharacter = nil

local function isCharacter(part)
    return part and part.Parent and Players:FindFirstChild(part.Parent.Name) and part.Parent:FindFirstChild("HumanoidRootPart")
end

-- 부드러운 이동 함수 (lerp)
local function smoothMove(part, goalCFrame, duration)
    duration = duration or 0.5 -- 기본 0.5초 동안 이동
    local startTime = tick()
    local startCFrame = part.CFrame

    local moveConnection
    moveConnection = RunService.Heartbeat:Connect(function()
        local elapsed = tick() - startTime
        local alpha = math.clamp(elapsed / duration, 0, 1)
        part.CFrame = startCFrame:Lerp(goalCFrame, alpha)
        if alpha >= 1 then
            moveConnection:Disconnect()
        end
    end)
end

local function stopFling()
    flingActive = false
    if angularVelocity then
        angularVelocity:Destroy()
        angularVelocity = nil
    end

    if localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") and originalCFrame then
        -- 원래 위치에서 Y축으로 3만큼 올린 위치로 부드럽게 이동
        local targetCFrame = originalCFrame * CFrame.new(0, 3, 0)
        smoothMove(localPlayer.Character.HumanoidRootPart, targetCFrame, 0.7)
    end

    if connection then
        connection:Disconnect()
        connection = nil
    end
    targetCharacter = nil
    print("플링 중단됨 (조금 높은 위치로 부드럽게 이동)")
end

local function flingTarget()
    if not targetCharacter then return end
    local targetHRP = targetCharacter:FindFirstChild("HumanoidRootPart")
    local localHRP = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not targetHRP or not localHRP then
        stopFling()
        return
    end

    originalCFrame = localHRP.CFrame

    angularVelocity = Instance.new("BodyAngularVelocity")
    angularVelocity.MaxTorque = Vector3.new(0, math.huge, 0)
    angularVelocity.Parent = localHRP

    local startTime = tick()
    local duration = 3

    connection = RunService.Heartbeat:Connect(function()
        if not flingActive then
            stopFling()
            return
        end

        local elapsed = tick() - startTime
        if elapsed > duration then
            stopFling()
            return
        end

        -- 대상 몸 위치 그대로 따라가기
        localHRP.CFrame = targetHRP.CFrame
        if angularVelocity then
            angularVelocity.AngularVelocity = Vector3.new(0, 9999999, 0)
        end
    end)
end

-- 마우스 클릭으로 플링 시도
mouse.Button1Down:Connect(function()
    if not flingEnabled then
        return -- 버튼 꺼져있으면 무시
    end

    if flingActive then
        stopFling()
        return
    end

    local target = mouse.Target
    if target and isCharacter(target) then
        local tChar = target.Parent
        if tChar ~= localPlayer.Character then
            targetCharacter = tChar
            flingActive = true
            print("플링 시작됨")
            flingTarget()
        else
            print("자기 자신은 플링할 수 없습니다.")
        end
    end
end)

-- 버튼 UI 생성
local playerGui = localPlayer:WaitForChild("PlayerGui")
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FlingToggleGui"
screenGui.Parent = playerGui

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 120, 0, 40)
toggleButton.Position = UDim2.new(0, 10, 0, 10)
toggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
toggleButton.TextColor3 = Color3.new(1,1,1)
toggleButton.Text = "플링 OFF"
toggleButton.Parent = screenGui

toggleButton.MouseButton1Click:Connect(function()
    flingEnabled = not flingEnabled
    if flingEnabled then
        toggleButton.Text = "플링 ON"
        print("플링 활성화됨")
    else
        toggleButton.Text = "플링 OFF"
        -- 플링 도중이면 중단
        if flingActive then
            stopFling()
        end
        print("플링 비활성화됨")
    end
end)

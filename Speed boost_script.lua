local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Config
local basePushForce = 24.5
local updateRateMin, updateRateMax = 0.05, 0.07
local active = false
local followLoop
local maxVelocity = 30 -- caps speed so it doesn’t spike

-- GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LeafyHubPushGui"
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 220, 0, 100)
frame.Position = UDim2.new(0, 10, 0, 10)
frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = ScreenGui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 12)
frameCorner.Parent = frame

local frameStroke = Instance.new("UIStroke")
frameStroke.Color = Color3.fromRGB(0,170,255)
frameStroke.Thickness = 2
frameStroke.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0,25)
title.Position = UDim2.new(0,0,0,0)
title.Text = "🌺LeafyHub🌺 Speed"
title.TextColor3 = Color3.fromRGB(255,255,255)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.BackgroundTransparency = 1
title.Parent = frame

local noCloneLabel = Instance.new("TextLabel")
noCloneLabel.Size = UDim2.new(0,200,0,50)
noCloneLabel.Position = UDim2.new(0.5,-100,0.5,-25)
noCloneLabel.Text = "No Clone Found"
noCloneLabel.TextColor3 = Color3.fromRGB(255,0,0)
noCloneLabel.TextScaled = true
noCloneLabel.Font = Enum.Font.GothamBold
noCloneLabel.BackgroundTransparency = 1
noCloneLabel.Visible = false
noCloneLabel.Parent = ScreenGui

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0.9,0,0,25)
toggleBtn.Position = UDim2.new(0.05,0,0,60)
toggleBtn.Text = "Toggle Speed Boost"
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 14
toggleBtn.TextColor3 = Color3.fromRGB(255,255,255)
toggleBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
toggleBtn.BorderSizePixel = 0
toggleBtn.Parent = frame

local toggleCorner = Instance.new("UICorner", toggleBtn)
toggleCorner.CornerRadius = UDim.new(0,8)
local toggleStroke = Instance.new("UIStroke", toggleBtn)
toggleStroke.Color = Color3.fromRGB(0,170,255)
toggleStroke.Thickness = 1.5

-- Utilities
local function getRoot(model)
    return model and model:FindFirstChild("HumanoidRootPart")
end

-- Clone push logic
local function startPush()
    local clone
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj.Name:match("_Clone") and getRoot(obj) then
            clone = obj
            break
        end
    end
    if not clone then return end

    local cloneRoot = getRoot(clone)
    cloneRoot.Anchored = true

    followLoop = task.spawn(function()
        while active do
            local char = LocalPlayer.Character
            local myRoot = char and getRoot(char)
            if not myRoot then
                task.wait(0.1)
                continue
            end

            -- Clone slightly behind player
            local backwardOffset = -myRoot.CFrame.LookVector * (3 + math.random()*0.5)
            local randomY = math.random()*0.2 - 0.1 -- small Y variation
            local targetPos = myRoot.Position + backwardOffset + Vector3.new(0, randomY, 0)
            cloneRoot.CFrame = CFrame.new(targetPos.X, myRoot.Position.Y, targetPos.Z)

            -- Smooth push using lerp with minor randomization
            local forwardDir = Vector3.new(myRoot.CFrame.LookVector.X, 0, myRoot.CFrame.LookVector.Z).Unit
            local forceVariation = basePushForce + (math.random()*1 - 0.5)
            local bv = myRoot:FindFirstChild("LeafyHubPush")
            if not bv then
                bv = Instance.new("BodyVelocity")
                bv.Name = "LeafyHubPush"
                bv.MaxForce = Vector3.new(1e5,0,1e5)
                bv.Velocity = Vector3.new(0,0,0)
                bv.Parent = myRoot
            end
            local newVel = forwardDir * forceVariation
            -- cap max velocity
            if newVel.Magnitude > maxVelocity then
                newVel = newVel.Unit * maxVelocity
            end
            bv.Velocity = bv.Velocity:Lerp(newVel, 0.5)

            task.wait(updateRateMin + math.random()*(updateRateMax - updateRateMin))
        end
    end)
end

-- Toggle button logic
toggleBtn.MouseButton1Click:Connect(function()
    local foundClone
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj.Name:match("_Clone") and getRoot(obj) then
            foundClone = obj
            break
        end
    end
    if not foundClone then
        noCloneLabel.Visible = true
        task.delay(1, function() noCloneLabel.Visible = false end)
        toggleBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
        active = false
        return
    end

    active = not active
    if active then
        toggleBtn.BackgroundColor3 = Color3.fromRGB(60,170,90)
        startPush()
    else
        toggleBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
        if followLoop then
            task.cancel(followLoop)
            followLoop = nil
        end
        local char = LocalPlayer.Character
        local myRoot = char and getRoot(char)
        if myRoot then
            local bv = myRoot:FindFirstChild("LeafyHubPush")
            if bv then bv:Destroy() end
        end
    end
end)
--// CelestialUI - Step 2 (v2): Window + Orb Repulsion Effect

local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")

local CelestialUI = {}

function CelestialUI:CreateWindow(title)
    local player = game.Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")

    local gui = Instance.new("ScreenGui")
    gui.Name = "CelestialUI"
    gui.ResetOnSpawn = false
    gui.Parent = playerGui

    -- Main frame
    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, 450, 0, 300)
    main.Position = UDim2.new(0.5, -225, 0.5, -150)
    main.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    main.BorderSizePixel = 0
    main.Active = true
    main.Draggable = true
    main.ClipsDescendants = true
    main.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = main

    -- Topbar
    local topbar = Instance.new("Frame")
    topbar.Size = UDim2.new(1, 0, 0, 35)
    topbar.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    topbar.BorderSizePixel = 0
    topbar.Parent = main

    local topCorner = Instance.new("UICorner")
    topCorner.CornerRadius = UDim.new(0, 12)
    topCorner.Parent = topbar

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -40, 1, 0)
    titleLabel.Position = UDim2.new(0, 10, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title or "Celestial UI"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 16
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = topbar

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 25, 0, 25)
    closeBtn.Position = UDim2.new(1, -30, 0, 5)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "×"
    closeBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
    closeBtn.TextScaled = true
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = topbar

    local visible = true
    closeBtn.MouseButton1Click:Connect(function()
        visible = not visible
        main.Visible = visible
    end)

    ----------------------------------------------------------------
    -- 🪩 ORB SYSTEM (inside the UI only)
    ----------------------------------------------------------------
    local ORB_COUNT = 10
    local ORB_REPEL_DISTANCE = 120
    local ORB_BOUNCE_FORCE = 150
    local ORB_RESTORE_SPEED = 2

    local orbs = {}
    local orbStates = {}

    for i = 1, ORB_COUNT do
        local orb = Instance.new("Frame")
        orb.Size = UDim2.new(0, math.random(25, 50), 0, math.random(25, 50))
        orb.Position = UDim2.new(math.random(), -25, math.random(), -25)
        orb.BackgroundColor3 = Color3.fromRGB(math.random(80, 255), math.random(80, 255), math.random(80, 255))
        orb.BackgroundTransparency = 0.6
        orb.BorderSizePixel = 0
        orb.ZIndex = 0
        orb.ClipsDescendants = false
        orb.Parent = main

        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(1, 0)
        c.Parent = orb

        table.insert(orbs, orb)
        orbStates[i] = {
            pos = orb.Position,
            vel = Vector2.new(0, 0),
        }
    end

    RS.RenderStepped:Connect(function(dt)
        if not main.Visible then return end
        local mouse = UIS:GetMouseLocation()
        local mainAbsPos = main.AbsolutePosition
        local mainSize = main.AbsoluteSize

        for i, orb in ipairs(orbs) do
            local state = orbStates[i]
            local orbCenter = orb.AbsolutePosition + orb.AbsoluteSize / 2
            local diff = Vector2.new(mouse.X - orbCenter.X, mouse.Y - orbCenter.Y)
            local dist = diff.Magnitude

            if dist < ORB_REPEL_DISTANCE then
                local dir = -diff.Unit
                state.vel = state.vel + dir * ((1 - dist / ORB_REPEL_DISTANCE) * ORB_BOUNCE_FORCE) * dt
            end

            -- Restore back toward original local position
            local target = Vector2.new(
                mainAbsPos.X + state.pos.X.Offset + orb.AbsoluteSize.X / 2,
                mainAbsPos.Y + state.pos.Y.Offset + orb.AbsoluteSize.Y / 2
            )
            local cur = orb.AbsolutePosition + orb.AbsoluteSize / 2
            local toTarget = (target - cur)

            state.vel = state.vel + toTarget * ORB_RESTORE_SPEED * dt
            state.vel = state.vel * (1 - math.clamp(6 * dt, 0, 1))

            local newPos = UDim2.new(state.pos.X.Scale, state.pos.X.Offset + state.vel.X * 0.5,
                state.pos.Y.Scale, state.pos.Y.Offset + state.vel.Y * 0.5)
            orb.Position = newPos
            state.pos = newPos
        end
    end)

    ----------------------------------------------------------------

    return {
        GUI = gui,
        Main = main,
        Topbar = topbar,
        Visible = function(state)
            main.Visible = state
        end
    }
end

return CelestialUI

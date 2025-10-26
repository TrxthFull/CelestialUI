--// CelestialUI - Step 1: Base UI Loader

local CelestialUI = {}

function CelestialUI:CreateWindow(title)
    -- Services
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

    -- Create the main ScreenGui
    local gui = Instance.new("ScreenGui")
    gui.Name = "CelestialUI"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.Parent = PlayerGui

    -- Create the main frame
    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, 400, 0, 250)
    main.Position = UDim2.new(0.5, -200, 0.5, -125)
    main.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    main.BorderSizePixel = 0
    main.Active = true
    main.Draggable = true
    main.Parent = gui

    -- Topbar
    local topbar = Instance.new("Frame")
    topbar.Size = UDim2.new(1, 0, 0, 30)
    topbar.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    topbar.BorderSizePixel = 0
    topbar.Parent = main

    -- Title label
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -10, 1, 0)
    titleLabel.Position = UDim2.new(0, 10, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title or "Celestial UI"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 16
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = topbar

    -- Return window object
    local window = {}
    window.GUI = gui
    window.Main = main
    window.Topbar = topbar

    return window
end

return CelestialUI

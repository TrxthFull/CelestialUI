--[[
    CelestialUI Library
    Basic Window System (Red → Black gradient + Toggle Close Button)
    Author: TrxthFull
]]

local function CreateCelestialUI()
    -- Create ScreenGui
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "CelestialUI_Root"
    ScreenGui.Parent = game:GetService("CoreGui")

    -- Create main window frame
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "CelestialWindow"
    MainFrame.Size = UDim2.new(0, 400, 0, 300)
    MainFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
    MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui

    -- Add rounded corners
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 12)
    Corner.Parent = MainFrame

    -- Add gradient background (red top-left → black bottom-right)
    local Gradient = Instance.new("UIGradient")
    Gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
    }
    Gradient.Rotation = 45
    Gradient.Parent = MainFrame

    -- Add title label
    local Title = Instance.new("TextLabel")
    Title.Text = "CelestialUI"
    Title.Size = UDim2.new(1, -30, 0, 30)
    Title.BackgroundTransparency = 1
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 18
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Position = UDim2.new(0, 10, 0, 0)
    Title.Parent = MainFrame

    -- Add close ("X") button
    local CloseButton = Instance.new("TextButton")
    CloseButton.Text = "×"
    CloseButton.Size = UDim2.new(0, 30, 0, 30)
    CloseButton.Position = UDim2.new(1, -30, 0, 0)
    CloseButton.BackgroundTransparency = 1
    CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseButton.Font = Enum.Font.GothamBold
    CloseButton.TextSize = 20
    CloseButton.Parent = MainFrame

    -- Toggle UI visibility on click
    CloseButton.MouseButton1Click:Connect(function()
        MainFrame.Visible = not MainFrame.Visible
    end)

    -- Return the main frame for expansion (tabs, sections, etc.)
    return MainFrame
end

return CreateCelestialUI

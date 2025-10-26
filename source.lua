--[[
    CelestialUI Library
    Basic Window System (Red → Black gradient + Toggle Close Button + Dragging)
    Author: TrxthFull
]]

local function CreateCelestialUI()
    -- Create ScreenGui
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "CelestialUI_Root"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = game:GetService("CoreGui")

    -- Main window frame
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "CelestialWindow"
    MainFrame.Size = UDim2.new(0, 400, 0, 300)
    MainFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
    MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui

    -- Rounded corners
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 12)
    Corner.Parent = MainFrame

    -- Gradient (red top-left → black bottom-right)
    local Gradient = Instance.new("UIGradient")
    Gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
    }
    Gradient.Rotation = 45
    Gradient.Parent = MainFrame

    -- Title label
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

    -- Close button
    local CloseButton = Instance.new("TextButton")
    CloseButton.Text = "×"
    CloseButton.Size = UDim2.new(0, 30, 0, 30)
    CloseButton.Position = UDim2.new(1, -30, 0, 0)
    CloseButton.BackgroundTransparency = 1
    CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseButton.Font = Enum.Font.GothamBold
    CloseButton.TextSize = 20
    CloseButton.Parent = MainFrame

    -- Toggle visibility
    CloseButton.MouseButton1Click:Connect(function()
        MainFrame.Visible = not MainFrame.Visible
    end)

    -- Dragging logic
    local UIS = game:GetService("UserInputService")
    local dragging = false
    local dragStart, startPos

    local function update(input)
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end

    Title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input)
        end
    end)

    -- Return main frame
    return MainFrame
end

    -- CreateTab function
    function MainFrame:CreateTab(tabName)
        local TabButton = Instance.new("TextButton")
        TabButton.Name = tabName .. "_Button"
        TabButton.Text = tabName
        TabButton.Size = UDim2.new(0, 100, 0, 30)
        TabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        TabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        TabButton.Font = Enum.Font.Gotham
        TabButton.TextSize = 14
        TabButton.Parent = MainFrame

        -- Rounded corners for tab button
        local Corner = Instance.new("UICorner")
        Corner.CornerRadius = UDim.new(0, 6)
        Corner.Parent = TabButton

        -- Create tab page
        local TabPage = Instance.new("Frame")
        TabPage.Name = tabName .. "_Page"
        TabPage.Size = UDim2.new(1, -10, 1, -40)
        TabPage.Position = UDim2.new(0, 5, 0, 35)
        TabPage.BackgroundTransparency = 1
        TabPage.Visible = true
        TabPage.Parent = MainFrame

        -- TabButton toggles visibility of its page
        TabButton.MouseButton1Click:Connect(function()
            for _, child in ipairs(MainFrame:GetChildren()) do
                if child:IsA("Frame") and child.Name:find("_Page") then
                    child.Visible = false
                end
            end
            TabPage.Visible = true
        end)

        -- Return the tab page
        return TabPage
    end


return CreateCelestialUI

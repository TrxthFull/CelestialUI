--// CelestialUI - Step 2: Styled Window with Orbs & Toggle Button

local TweenService = game:GetService("TweenService")

local CelestialUI = {}

function CelestialUI:CreateWindow(title)
	-- Services
	local Players = game:GetService("Players")
	local LocalPlayer = Players.LocalPlayer
	local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

	-- ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name = "CelestialUI"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = PlayerGui

	-- Main window
	local main = Instance.new("Frame")
	main.Size = UDim2.new(0, 450, 0, 300)
	main.Position = UDim2.new(0.5, -225, 0.5, -150)
	main.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	main.BorderSizePixel = 0
	main.Active = true
	main.Draggable = true
	main.Parent = gui

	-- Rounded corners
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = main

	-- Topbar
	local topbar = Instance.new("Frame")
	topbar.Size = UDim2.new(1, 0, 0, 35)
	topbar.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
	topbar.BorderSizePixel = 0
	topbar.Parent = main

	local topCorner = Instance.new("UICorner")
	topCorner.CornerRadius = UDim.new(0, 10)
	topCorner.Parent = topbar

	-- Title label
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

	-- Toggle button (X)
	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 25, 0, 25)
	closeBtn.Position = UDim2.new(1, -30, 0, 5)
	closeBtn.BackgroundTransparency = 1
	closeBtn.Text = "×"
	closeBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
	closeBtn.TextScaled = true
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.Parent = topbar

	-- Toggle behavior
	local visible = true
	closeBtn.MouseButton1Click:Connect(function()
		visible = not visible
		main.Visible = visible
	end)

	-- Orb generator
	local function createOrb(parent, size, position, color)
		local orb = Instance.new("Frame")
		orb.Size = UDim2.new(0, size, 0, size)
		orb.Position = position
		orb.BackgroundColor3 = color
		orb.BackgroundTransparency = 0.8
		orb.BorderSizePixel = 0
		orb.ZIndex = 0
		orb.Parent = parent

		local orbCorner = Instance.new("UICorner")
		orbCorner.CornerRadius = UDim.new(1, 0)
		orbCorner.Parent = orb

		-- Animation
		task.spawn(function()
			while orb.Parent do
				local newPos = UDim2.new(math.random(), -size/2, math.random(), -size/2)
				local newSize = UDim2.new(0, math.random(200, 400), 0, math.random(200, 400))
				local tween = TweenService:Create(orb, TweenInfo.new(8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
					Position = newPos,
					Size = newSize,
					BackgroundTransparency = math.random(70, 90) / 100
				})
				tween:Play()
				tween.Completed:Wait()
			end
		end)
	end

	-- Create orbs
	createOrb(main, 300, UDim2.new(0.2, 0, 0.2, 0), Color3.fromRGB(100, 60, 255))
	createOrb(main, 250, UDim2.new(0.6, 0, 0.4, 0), Color3.fromRGB(255, 100, 200))
	createOrb(main, 200, UDim2.new(0.4, 0, 0.7, 0), Color3.fromRGB(100, 255, 220))

	-- Return object
	local window = {}
	window.GUI = gui
	window.Main = main
	window.Topbar = topbar
	window.Visible = function(state)
		main.Visible = state
	end

	return window
end

return CelestialUI

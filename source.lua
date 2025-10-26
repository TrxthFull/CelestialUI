-- CelestialUILib.lua
-- Original UI library: tabs, sections, buttons, toggles, sliders, dropdowns, notifications, themes, draggable window, orb background.
-- Designed for client-side execution in Roblox. Place in your GitHub as "source.lua" (or whatever) and load via HttpGet + loadstring.

local CelestialUI = {}
CelestialUI.__index = CelestialUI

-- CONFIG
local ORB_COUNT = 12
local ORB_MIN_SIZE = 18
local ORB_MAX_SIZE = 42
local ORB_REPEL_DISTANCE = 140
local ORB_BOUNCE_FORCE = 220
local DEFAULT_TOGGLE_KEY = Enum.KeyCode.RightBracket
local NOTIF_DURATION = 3

-- Services (client-side)
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local TS = game:GetService("TweenService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

-- Helper to create instances
local function new(name, class)
	local obj = Instance.new(class)
	obj.Name = name
	return obj
end

-- Clean up previous UI
do
	local existing = CoreGui:FindFirstChild("CelestialUI_Root")
	if existing then
		pcall(function() existing:Destroy() end)
	end
end

-- Root ScreenGui
local RootGui = Instance.new("ScreenGui")
RootGui.Name = "CelestialUI_Root"
RootGui.ResetOnSpawn = false
-- Try to parent into CoreGui safely
local ok, err = pcall(function() RootGui.Parent = CoreGui end)
if not ok then
	RootGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
end

-- default palette (exposed on returned API)
local DEFAULT_THEME = {
	TopLeft = Color3.fromRGB(40,120,255),
	BottomRight = Color3.fromRGB(10,10,10),
	Accent = Color3.fromRGB(140,180,255),
	Background = Color3.fromRGB(20,20,20),
	Text = Color3.fromRGB(235,235,245),
	Element = Color3.fromRGB(28,28,28),
	Button = Color3.fromRGB(33,33,33),
	NotifBg = Color3.fromRGB(20,20,20)
}

-- Notification helper
local function notify(text, dur)
	dur = dur or NOTIF_DURATION
	local frame = new("CelNotif", "Frame")
	frame.Size = UDim2.new(0, 320, 0, 40)
	frame.AnchorPoint = Vector2.new(1,0)
	frame.Position = UDim2.new(1, -10, 0, 10)
	frame.BackgroundTransparency = 0
	frame.BackgroundColor3 = DEFAULT_THEME.NotifBg
	frame.ZIndex = 9999
	frame.Parent = RootGui

	local corner = new("c", "UICorner"); corner.Parent = frame; corner.CornerRadius = UDim.new(0,8)
	local lbl = new("txt", "TextLabel"); lbl.Parent = frame
	lbl.Size = UDim2.new(1, -24, 1, 0); lbl.Position = UDim2.new(0, 12, 0, 0)
	lbl.BackgroundTransparency = 1; lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Font = Enum.Font.Gotham; lbl.TextSize = 14; lbl.Text = text; lbl.TextColor3 = DEFAULT_THEME.Text

	frame.Position = UDim2.new(1, 340, 0, 10)
	TS:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Position = UDim2.new(1, -10, 0, 10)}):Play()
	task.delay(dur, function()
		if frame and frame.Parent then
			TS:Create(frame, TweenInfo.new(0.25), {Position = UDim2.new(1, 340, 0, 10)}):Play()
			task.wait(0.3)
			pcall(function() frame:Destroy() end)
		end
	end)
end

-- Main constructor
function CelestialUI:CreateWindow(title, opts)
	title = title or "CelestialUI"
	opts = opts or {}
	local toggleKey = opts.ToggleKey or DEFAULT_TOGGLE_KEY
	local uiVisible = true
	local self = {}
	setmetatable(self, CelestialUI)

	-- Window base
	local Window = new("CelestialWindow", "Frame")
	Window.Size = UDim2.new(0, 720, 0, 460)
	Window.Position = UDim2.new(0, 40, 0, 40)
	Window.BackgroundColor3 = DEFAULT_THEME.Background
	Window.BorderSizePixel = 0
	Window.Parent = RootGui
	Window.ZIndex = 10
	local wcorner = new("wc","UICorner"); wcorner.Parent = Window; wcorner.CornerRadius = UDim.new(0,14)

	-- Topbar (draggable)
	local TopBar = new("TopBar","Frame")
	TopBar.Size = UDim2.new(1,0,0,52)
	TopBar.BackgroundTransparency = 1
	TopBar.Parent = Window

	-- Title
	local TitleLbl = new("Title","TextLabel")
	TitleLbl.Parent = Window
	TitleLbl.Size = UDim2.new(1,0,0,24)
	TitleLbl.Position = UDim2.new(0, 12, 0, 12)
	TitleLbl.BackgroundTransparency = 1
	TitleLbl.Text = title
	TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
	TitleLbl.Font = Enum.Font.GothamBold
	TitleLbl.TextSize = 18
	TitleLbl.TextColor3 = DEFAULT_THEME.Text

	-- Top right controls
	local RightControls = new("RightControls","Frame"); RightControls.Parent = TopBar
	RightControls.Size = UDim2.new(0,120,1,0); RightControls.Position = UDim2.new(1,-130,0,0); RightControls.BackgroundTransparency = 1

	local BtnSettings = new("BtnSettings","TextButton"); BtnSettings.Parent = RightControls
	BtnSettings.Size = UDim2.new(0,38,0,38); BtnSettings.Position = UDim2.new(0,0,0,7)
	BtnSettings.BackgroundColor3 = DEFAULT_THEME.Element; BtnSettings.Text = "⚙"; BtnSettings.Font = Enum.Font.Gotham; BtnSettings.TextSize = 20
	local BtnClose = new("BtnClose","TextButton"); BtnClose.Parent = RightControls
	BtnClose.Size = UDim2.new(0,38,0,38); BtnClose.Position = UDim2.new(0,44,0,7)
	BtnClose.BackgroundColor3 = DEFAULT_THEME.Element; BtnClose.Text = "X"; BtnClose.Font = Enum.Font.GothamBold; BtnClose.TextColor3 = Color3.fromRGB(255,180,180)

	-- settings panel (simple)
	local SettingsPanel = new("Settings","Frame"); SettingsPanel.Parent = TopBar
	SettingsPanel.Size = UDim2.new(0, 260, 0, 160); SettingsPanel.Position = UDim2.new(1, -400, 0, 54)
	SettingsPanel.BackgroundColor3 = DEFAULT_THEME.Element; SettingsPanel.Visible = false; SettingsPanel.ZIndex = 12
	local spCorner = new("spc", "UICorner"); spCorner.Parent = SettingsPanel; spCorner.CornerRadius = UDim.new(0,10)
	local spTitle = new("spTitle","TextLabel"); spTitle.Parent = SettingsPanel; spTitle.Size = UDim2.new(1,0,0,28); spTitle.Text = "Settings"; spTitle.BackgroundTransparency = 1; spTitle.Font = Enum.Font.GothamBold; spTitle.TextColor3 = DEFAULT_THEME.Text; spTitle.TextSize = 14; spTitle.Position = UDim2.new(0,0,0,6)

	-- Content: tab column + page area
	local content = new("Content","Frame"); content.Parent = Window
	content.Size = UDim2.new(1, -24, 1, -72); content.Position = UDim2.new(0,12,0,60); content.BackgroundTransparency = 1

	local TabColumn = new("TabColumn","Frame"); TabColumn.Parent = content
	TabColumn.Size = UDim2.new(0,160,1,0); TabColumn.BackgroundTransparency = 1

	local PageArea = new("PageArea","Frame"); PageArea.Parent = content
	PageArea.Size = UDim2.new(1, -172, 1, 0); PageArea.Position = UDim2.new(0, 172, 0, 0); PageArea.BackgroundTransparency = 1

	-- orb background container
	local GradientFrame = new("OrbContainer","Frame"); GradientFrame.Parent = Window
	GradientFrame.Size = UDim2.new(1,0,1,0); GradientFrame.Position = UDim2.new(0,0,0,0); GradientFrame.BackgroundTransparency = 1; GradientFrame.ZIndex = 1

	-- create orbs and inner map to avoid storing on Instance to prevent "invalid member" issues
	local orbs = {}
	local orb_inners = {}
	for i=1, ORB_COUNT do
		local orb = new("Orb"..i, "ImageLabel")
		orb.Size = UDim2.new(0, math.random(ORB_MIN_SIZE, ORB_MAX_SIZE), 0, math.random(ORB_MIN_SIZE, ORB_MAX_SIZE))
		orb.Position = UDim2.new(math.random(), 0, math.random(), 0)
		orb.BackgroundTransparency = 1
		orb.Image = "" -- not using image
		orb.ImageTransparency = 1
		orb.Parent = GradientFrame
		orb.ZIndex = 1
		local inner = new("inner", "Frame"); inner.Parent = orb; inner.Size = UDim2.new(1,0,1,0)
		local innerCorner = new("ic","UICorner"); innerCorner.Parent = inner; innerCorner.CornerRadius = UDim.new(1,0)
		inner.BackgroundColor3 = DEFAULT_THEME.TopLeft
		inner.BackgroundTransparency = 0.9
		orbs[#orbs+1] = orb
		orb_inners[orb] = inner
	end

	-- orb states for physics
	local orbStates = {}
	for i=1, #orbs do orbStates[i] = {pos = orbs[i].Position, vel = Vector2.new(0,0)} end

	-- API containers
	local tabs = {}
	local activePage = nil

	-- tab creation function
	function self:CreateTab(name)
		assert(type(name) == "string", "Tab name must be string")
		local tab = {}

		-- create button
		local btn = new(name.."Btn", "TextButton")
		btn.Size = UDim2.new(1, -16, 0, 36)
		btn.Position = UDim2.new(0,8,0, 10 + (#tabs * 44))
		btn.BackgroundColor3 = DEFAULT_THEME.Element
		btn.Text = name
		btn.Font = Enum.Font.Gotham
		btn.TextSize = 14
		btn.TextColor3 = DEFAULT_THEME.Text
		btn.Parent = TabColumn
		new("ub","UICorner").Parent = btn

		-- page frame
		local page = new(name.."Page", "Frame")
		page.Size = UDim2.new(1,0,1,0)
		page.BackgroundTransparency = 1
		page.Parent = PageArea
		page.Visible = false

		-- section factory on tab
		function tab:CreateSection(title)
			local section = {}
			local secFrame = new(title.."Sec", "Frame")
			secFrame.Size = UDim2.new(1, -20, 0, 120)
			secFrame.Position = UDim2.new(0, 10, 0, (#page:GetChildren() * 6))
			secFrame.BackgroundColor3 = DEFAULT_THEME.Element
			secFrame.BackgroundTransparency = 0.06
			secFrame.Parent = page
			local sc = new("sc","UICorner"); sc.Parent = secFrame; sc.CornerRadius = UDim.new(0,8)

			local secTitle = new("secTitle","TextLabel"); secTitle.Parent = secFrame
			secTitle.Size = UDim2.new(1, -16, 0, 20); secTitle.Position = UDim2.new(0,8,0,8)
			secTitle.BackgroundTransparency = 1; secTitle.Font = Enum.Font.GothamBold
			secTitle.TextSize = 14; secTitle.Text = title; secTitle.TextColor3 = DEFAULT_THEME.Text

			local y = 36

			function section:AddButton(text, callback)
				local b = new(text.."Btn","TextButton"); b.Parent = secFrame
				b.Size = UDim2.new(1, -24, 0, 30); b.Position = UDim2.new(0, 12, 0, y)
				b.BackgroundColor3 = DEFAULT_THEME.Button; b.Font = Enum.Font.Gotham; b.Text = text; b.TextSize = 13; b.TextColor3 = DEFAULT_THEME.Text
				new("cb","UICorner").Parent = b
				b.MouseButton1Click:Connect(function()
					pcall(function() if callback then callback() end end)
				end)
				y = y + 36
				return b
			end

			function section:AddToggle(text, default, callback)
				local lbl = new("lbl","TextLabel"); lbl.Parent = secFrame
				lbl.Size = UDim2.new(0.7, 0, 0, 24); lbl.Position = UDim2.new(0,12, 0, y); lbl.BackgroundTransparency = 1
				lbl.Text = text; lbl.Font = Enum.Font.Gotham; lbl.TextColor3 = DEFAULT_THEME.Text; lbl.TextSize = 13

				local toggle = new("tog","TextButton"); toggle.Parent = secFrame
				toggle.Size = UDim2.new(0,44,0,24); toggle.Position = UDim2.new(1,-64,0,y)
				toggle.BackgroundColor3 = default and DEFAULT_THEME.Accent or Color3.fromRGB(60,60,60); toggle.Text = ""; new("rt","UICorner").Parent = toggle

				local state = default and true or false
				toggle.MouseButton1Click:Connect(function()
					state = not state
					toggle.BackgroundColor3 = state and DEFAULT_THEME.Accent or Color3.fromRGB(60,60,60)
					pcall(callback, state)
				end)
				y = y + 36
				return toggle
			end

			function section:AddSlider(text, min, max, default, callback)
				min = min or 0; max = max or 100; default = default or min
				local lbl = new("slabel","TextLabel"); lbl.Parent = secFrame
				lbl.Size = UDim2.new(0.5,0,0,20); lbl.Position = UDim2.new(0,12,0,y); lbl.BackgroundTransparency = 1
				lbl.Text = text .. ": " .. tostring(default); lbl.Font = Enum.Font.Gotham; lbl.TextSize = 13; lbl.TextColor3 = DEFAULT_THEME.Text

				local barBack = new("barb","Frame"); barBack.Parent = secFrame
				barBack.Size = UDim2.new(1, -40, 0, 12); barBack.Position = UDim2.new(0,12,0,y+22); barBack.BackgroundColor3 = Color3.fromRGB(40,40,40); new("barc","UICorner").Parent = barBack
				local fill = new("fill","Frame"); fill.Parent = barBack; fill.Size = UDim2.new((default - min) / math.max(1, (max - min)), 0, 1, 0); fill.BackgroundColor3 = DEFAULT_THEME.Accent; new("fc","UICorner").Parent = fill

				local dragging = false
				barBack.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
				end)
				UIS.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
				end)
				UIS.InputChanged:Connect(function(input)
					if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
						local mx = input.Position.X
						local x0 = barBack.AbsolutePosition.X
						local w = barBack.AbsoluteSize.X
						local t = math.clamp((mx - x0) / math.max(1,w), 0, 1)
						fill.Size = UDim2.new(t, 0, 1, 0)
						local value = min + (max - min) * t
						lbl.Text = text .. ": " .. math.floor(value)
						pcall(callback, value)
					end
				end)
				y = y + 56
				return {bar = barBack, fill = fill}
			end

			function section:AddDropdown(text, choices, callback)
				local lbl = new("dlabel","TextLabel"); lbl.Parent = secFrame
				lbl.Size = UDim2.new(0.6,0,0,20); lbl.Position = UDim2.new(0,12,0,y); lbl.BackgroundTransparency = 1
				lbl.Text = text; lbl.Font = Enum.Font.Gotham; lbl.TextSize = 13; lbl.TextColor3 = DEFAULT_THEME.Text

				local dd = new("dd","TextButton"); dd.Parent = secFrame
				dd.Size = UDim2.new(0,120,0,26); dd.Position = UDim2.new(1,-136,0,y); dd.Text = choices[1] or "Select"; dd.Font = Enum.Font.Gotham; new("ddc","UICorner").Parent = dd

				local listFrame = new("list","Frame"); listFrame.Parent = secFrame
				listFrame.Size = UDim2.new(0,120,0,#choices * 28); listFrame.Position = UDim2.new(1,-136,0,y+30); listFrame.BackgroundColor3 = Color3.fromRGB(25,25,25); new("lfc","UICorner").Parent = listFrame
				listFrame.Visible = false

				for i,choice in ipairs(choices) do
					local it = new("it"..i, "TextButton"); it.Parent = listFrame
					it.Size = UDim2.new(1,0,0,28); it.Position = UDim2.new(0,0,0,(i-1)*28); it.Text = choice; it.Font = Enum.Font.Gotham; it.TextSize = 13
					it.BackgroundTransparency = 0.2
					it.MouseButton1Click:Connect(function()
						dd.Text = choice
						listFrame.Visible = false
						pcall(callback, choice)
					end)
				end

				dd.MouseButton1Click:Connect(function()
					listFrame.Visible = not listFrame.Visible
				end)

				y = y + 36
				return dd
			end

			return section
		end

		-- clicking tab button switches pages
		btn.MouseButton1Click:Connect(function()
			for _,t in ipairs(tabs) do
				if t.page then t.page.Visible = false end
			end
			page.Visible = true
			activePage = page
			for _,t in ipairs(tabs) do if t.btn then t.btn.BackgroundColor3 = DEFAULT_THEME.Element end
			end
			btn.BackgroundColor3 = DEFAULT_THEME.Button
		end)

		-- register tab
		tabs[#tabs+1] = {btn = btn, page = page, name = name}
		-- auto open first tab
		if #tabs == 1 then
			btn:MouseButton1Click()
		end

		return tab
	end

	-- Settings controls
	BtnSettings.MouseButton1Click:Connect(function()
		SettingsPanel.Visible = not SettingsPanel.Visible
	end)
	BtnClose.MouseButton1Click:Connect(function()
		uiVisible = false
		Window.Visible = false
		notify("GUI hidden — press toggle key to show")
	end)

	-- toggle key
	self.ToggleKey = toggleKey
	UIS.InputBegan:Connect(function(inp, gp)
		if gp then return end
		if inp.KeyCode == toggleKey then
			uiVisible = not uiVisible
			Window.Visible = uiVisible
			if uiVisible then notify("GUI shown", 1.5) end
		end
	end)

	-- draggable topbar
	do
		local dragging = false
		local dragStart = Vector2.new()
		local startPos = UDim2.new()
		TopBar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = true
				dragStart = input.Position
				startPos = Window.Position
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragging = false
					end
				end)
			end
		end)
		UIS.InputChanged:Connect(function(input)
			if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
				local delta = input.Position - dragStart
				Window.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
			end
		end)
	end

	-- orbit physics update
	RS.RenderStepped:Connect(function(dt)
		local mouseX, mouseY = UIS:GetMouseLocation().X, UIS:GetMouseLocation().Y
		for i, orb in ipairs(orbs) do
			local absPos = orb.AbsolutePosition + Vector2.new(orb.AbsoluteSize.X/2, orb.AbsoluteSize.Y/2)
			local diff = Vector2.new(absPos.X - mouseX, absPos.Y - mouseY)
			local dist = diff.Magnitude
			if dist < ORB_REPEL_DISTANCE then
				local dir = diff.Unit or Vector2.new(0,0)
				local force = (1 - dist/ORB_REPEL_DISTANCE) * ORB_BOUNCE_FORCE
				orbStates[i].vel = orbStates[i].vel + dir * (force * dt)
			end
			-- attract to original pos:
			local posUD = orbStates[i].pos
			local target = Vector2.new(Window.AbsolutePosition.X + posUD.X.Offset + orb.AbsoluteSize.X/2, Window.AbsolutePosition.Y + posUD.Y.Offset + orb.AbsoluteSize.Y/2)
			local cur = orb.AbsolutePosition + Vector2.new(orb.AbsoluteSize.X/2, orb.AbsoluteSize.Y/2)
			local toTarget = (target - cur)
			orbStates[i].vel = orbStates[i].vel + toTarget * 3 * dt
			orbStates[i].vel = orbStates[i].vel * (1 - math.clamp(6*dt, 0, 1))
			local newPos = UDim2.new(posUD.X.Scale, posUD.X.Offset + orbStates[i].vel.X * 0.5, posUD.Y.Scale, posUD.Y.Offset + orbStates[i].vel.Y * 0.5)
			orbStates[i].pos = newPos
			pcall(function()
				TS:Create(orb, TweenInfo.new(0.06, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Position = newPos}):Play()
			end)
			local inner = orb_inners[orb]
			if inner then
				pcall(function()
					inner.BackgroundColor3 = DEFAULT_THEME.TopLeft:Lerp(DEFAULT_THEME.BottomRight or DEFAULT_THEME.BottomRight, i / #orbs)
				end)
			end
		end
	end)

	-- public API
	function self:Notify(txt, dur) notify(txt, dur) end

	function self:Destroy()
		if RootGui and RootGui.Parent then
			pcall(function() RootGui:Destroy() end)
		end
	end

	-- expose raw parts if needed
	self._internal = {
		Window = Window,
		RootGui = RootGui,
		Tabs = tabs,
		SettingsPanel = SettingsPanel
	}

	return self
end

-- Make the module callable: UI("Name")
return setmetatable({}, {
	__call = function(_, ...)
		local ctor = CelestialUI
		return ctor:CreateWindow(...)
	end
})

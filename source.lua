-- CelestialUILib.lua (fixed & hardened)
-- Client-side UI library for Roblox (tabs, sections, buttons, toggles, sliders, dropdowns, notifications, theme, draggable window, orb background).

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
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local TS = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

-- Helper to create instances
local function new(name, class)
	local obj = Instance.new(class)
	obj.Name = name
	return obj
end

-- Clean up previous UI (safe)
do
	local ok, existing = pcall(function() return CoreGui:FindFirstChild("CelestialUI_Root") end)
	if ok and existing then
		pcall(function() existing:Destroy() end)
	end
end

-- Root ScreenGui
local RootGui = Instance.new("ScreenGui")
RootGui.Name = "CelestialUI_Root"
RootGui.ResetOnSpawn = false
-- Try to parent into CoreGui safely, else PlayerGui
local parentOk = pcall(function() RootGui.Parent = CoreGui end)
if not parentOk or not RootGui.Parent then
	local plr = Players.LocalPlayer
	if plr then
		RootGui.Parent = plr:WaitForChild("PlayerGui")
	else
		-- fallback – try CoreGui again
		RootGui.Parent = CoreGui
	end
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

-- notification stacking container
local notifContainer = new("NotifContainer", "Frame")
notifContainer.Size = UDim2.new(0, 340, 0, 0)
notifContainer.AnchorPoint = Vector2.new(1, 0)
notifContainer.Position = UDim2.new(1, -10, 0, 10)
notifContainer.BackgroundTransparency = 1
notifContainer.Parent = RootGui
notifContainer.ZIndex = 9999
local notifStack = {} -- track stacked frames

-- Notification helper
local function notify(text, dur)
	dur = dur or NOTIF_DURATION
	local frame = new("CelNotif", "Frame")
	frame.Size = UDim2.new(0, 320, 0, 40)
	frame.AnchorPoint = Vector2.new(1,0)
	frame.Position = UDim2.new(1, 0, 0, (#notifStack) * 48)
	frame.BackgroundTransparency = 0
	frame.BackgroundColor3 = DEFAULT_THEME.NotifBg
	frame.ZIndex = 9999
	frame.Parent = notifContainer

	local corner = new("c", "UICorner"); corner.Parent = frame; corner.CornerRadius = UDim.new(0,8)
	local lbl = new("txt", "TextLabel"); lbl.Parent = frame
	lbl.Size = UDim2.new(1, -24, 1, 0); lbl.Position = UDim2.new(0, 12, 0, 0)
	lbl.BackgroundTransparency = 1; lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Font = Enum.Font.Gotham; lbl.TextSize = 14; lbl.Text = text; lbl.TextColor3 = DEFAULT_THEME.Text

	table.insert(notifStack, frame)

	-- slide in
	frame.Position = UDim2.new(1, 340, 0, frame.Position.Y.Offset)
	TS:Create(frame, TweenInfo.new(0.28, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Position = UDim2.new(1, 0, 0, frame.Position.Y.Offset)}):Play()

	task.delay(dur, function()
		if frame and frame.Parent then
			TS:Create(frame, TweenInfo.new(0.22), {Position = UDim2.new(1, 340, 0, frame.Position.Y.Offset)}):Play()
			task.wait(0.28)
			pcall(function() frame:Destroy() end)
		end
		-- rebuild stack positions
		for i, f in ipairs(notifStack) do
			if f and f.Parent then
				local targetY = (i-1) * 48
				TS:Create(f, TweenInfo.new(0.18), {Position = UDim2.new(1, 0, 0, targetY)}):Play()
			else
				notifStack[i] = nil
			end
		end
		-- compact notifStack table
		local compact = {}
		for _,f in ipairs(notifStack) do if f and f.Parent then table.insert(compact, f) end end
		notifStack = compact
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

	-- create orbs and inner map
	local orbs = {}
	local orb_inners = {}
	for i=1, ORB_COUNT do
		local orb = new("Orb"..i, "ImageLabel")
		local w = math.random(ORB_MIN_SIZE, ORB_MAX_SIZE)
		local h = math.random(ORB_MIN_SIZE, ORB_MAX_SIZE)
		orb.Size = UDim2.new(0, w, 0, h)
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

		-- use UIListLayout to stack sections automatically
		local listLayout = Instance.new("UIListLayout")
		listLayout.Parent = page
		listLayout.SortOrder = Enum.SortOrder.LayoutOrder
		listLayout.Padding = UDim.new(0, 8)

		-- section factory on tab
		function tab:CreateSection(title)
			local section = {}
			local secFrame = new(title.."Sec", "Frame")
			secFrame.Size = UDim2.new(1, -20, 0, 120)
			secFrame.LayoutOrder = (#page:GetChildren() + 1)
			secFrame.BackgroundColor3 = DEFAULT_THEME.Element
			secFrame.BackgroundTransparency = 0.06
			secFrame.Parent = page
			local sc = new("sc","UICorner"); sc.Parent = secFrame; sc.CornerRadius = UDim.new(0,8)

			local secTitle = new("secTitle","TextLabel"); secTitle.Parent = secFrame
			secTitle.Size = UDim2.new(1, -16, 0, 20); secTitle.Position = UDim2.new(0,8,0,8)
			secTitle.BackgroundTransparency = 1; secTitle.Font = Enum.Font.GothamBold
			secTitle.TextSize = 14; secTitle.Text = title; secTitle.TextColor3 = DEFAULT_THEME.Text

			-- We'll stack inside the section using a UIListLayout as well
			local innerList = Instance.new("UIListLayout")
			innerList.Parent = secFrame
			innerList.Padding = UDim.new(0, 8)
			innerList.SortOrder = Enum.SortOrder.LayoutOrder

			local function addLayoutElement(element)
				-- set LayoutOrder to push elements down; re-parent will be done by section functions
				element.LayoutOrder = (#secFrame:GetChildren() + 1)
				return element
			end

			function section:AddButton(text, callback)
				local b = new(text.."Btn","TextButton"); b.Parent = secFrame
				b.Size = UDim2.new(1, -24, 0, 30); b.Position = UDim2.new(0, 12, 0, 36) -- position won't matter due to list; kept for safety
				b.BackgroundColor3 = DEFAULT_THEME.Button; b.Font = Enum.Font.Gotham; b.Text = text; b.TextSize = 13; b.TextColor3 = DEFAULT_THEME.Text
				new("cb","UICorner").Parent = b
				b.MouseButton1Click:Connect(function()
					pcall(function() if callback then callback() end end)
				end)
				addLayoutElement(b)
				return b
			end

			function section:AddToggle(text, default, callback)
				local root = new("toggleRow", "Frame"); root.Size = UDim2.new(1, -24, 0, 24); root.BackgroundTransparency = 1; root.Parent = secFrame
				local lbl = new("lbl","TextLabel"); lbl.Parent = root
				lbl.Size = UDim2.new(0.7, 0, 1, 0); lbl.Position = UDim2.new(0,0,0,0); lbl.BackgroundTransparency = 1
				lbl.Text = text; lbl.Font = Enum.Font.Gotham; lbl.TextColor3 = DEFAULT_THEME.Text; lbl.TextSize = 13
				local toggle = new("tog","TextButton"); toggle.Parent = root
				toggle.Size = UDim2.new(0,44,0,24); toggle.Position = UDim2.new(1,-44,0,0)
				toggle.BackgroundColor3 = default and DEFAULT_THEME.Accent or Color3.fromRGB(60,60,60); toggle.Text = ""
				new("rt","UICorner").Parent = toggle

				local state = default and true or false
				toggle.MouseButton1Click:Connect(function()
					state = not state
					toggle.BackgroundColor3 = state and DEFAULT_THEME.Accent or Color3.fromRGB(60,60,60)
					pcall(callback, state)
				end)
				addLayoutElement(root)
				return toggle
			end

			function section:AddSlider(text, min, max, default, callback)
				min = min or 0; max = max or 100; default = default or min
				local root = new("sliderRow","Frame"); root.Size = UDim2.new(1, -24, 0, 48); root.BackgroundTransparency = 1; root.Parent = secFrame
				local lbl = new("slabel","TextLabel"); lbl.Parent = root
				lbl.Size = UDim2.new(0.5,0,0,20); lbl.Position = UDim2.new(0,0,0,0); lbl.BackgroundTransparency = 1
				lbl.Text = text .. ": " .. tostring(default); lbl.Font = Enum.Font.Gotham; lbl.TextSize = 13; lbl.TextColor3 = DEFAULT_THEME.Text

				local barBack = new("barb","Frame"); barBack.Parent = root
				barBack.Size = UDim2.new(1, 0, 0, 12); barBack.Position = UDim2.new(0,0,0,24); barBack.BackgroundColor3 = Color3.fromRGB(40,40,40); new("barc","UICorner").Parent = barBack
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
						lbl.Text = string.format("%s: %d", text, math.floor(value))
						pcall(callback, value)
					end
				end)
				addLayoutElement(root)
				return {bar = barBack, fill = fill}
			end

			function section:AddDropdown(text, choices, callback)
				local root = new("dropRow","Frame"); root.Size = UDim2.new(1, -24, 0, 36); root.BackgroundTransparency = 1; root.Parent = secFrame
				local lbl = new("dlabel","TextLabel"); lbl.Parent = root
				lbl.Size = UDim2.new(0.6,0,0,20); lbl.Position = UDim2.new(0,0,0,0); lbl.BackgroundTransparency = 1
				lbl.Text = text; lbl.Font = Enum.Font.Gotham; lbl.TextSize = 13; lbl.TextColor3 = DEFAULT_THEME.Text

				local dd = new("dd","TextButton"); dd.Parent = root
				dd.Size = UDim2.new(0,120,0,26); dd.Position = UDim2.new(1,-120,0,0); dd.Text = choices[1] or "Select"; dd.Font = Enum.Font.Gotham; new("ddc","UICorner").Parent = dd

				local listFrame = new("list","ScrollingFrame"); listFrame.Parent = root
				listFrame.Size = UDim2.new(0,120,0, math.clamp(#choices * 28, 0, 200)); listFrame.Position = UDim2.new(1,-120,0,26); listFrame.BackgroundColor3 = Color3.fromRGB(25,25,25); new("lfc","UICorner").Parent = listFrame
				listFrame.Visible = false
				listFrame.CanvasSize = UDim2.new(0,0,0,#choices * 28)
				listFrame.ScrollBarThickness = 4

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

				addLayoutElement(root)
				return dd
			end

			return section
		end

		-- clicking tab button switches pages
		local function switchToPage()
			for _,t in ipairs(tabs) do
				if t and t.page and t.page.Parent then
					t.page.Visible = false
				end
			end
			if page and page.Parent then
				page.Visible = true
				activePage = page
			end
			for _,t in ipairs(tabs) do
				if t and t.btn and t.btn.Parent then
					t.btn.BackgroundColor3 = DEFAULT_THEME.Element
				end
			end
			if btn and btn.Parent then
				btn.BackgroundColor3 = DEFAULT_THEME.Button
			end
		end

		btn.MouseButton1Click:Connect(switchToPage)

		-- register tab
		tabs[#tabs+1] = {btn = btn, page = page, name = name}
		-- auto open first tab
		if #tabs == 1 then
			-- directly set visible (no event spam)
			page.Visible = true
			btn.BackgroundColor3 = DEFAULT_THEME.Button
			activePage = page
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
		-- guard against non-keyboard input
		local ok, key = pcall(function() return inp.KeyCode end)
		if not ok then return end
		if key == toggleKey then
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

	-- orbit physics update (safe & performant)
	RS.RenderStepped:Connect(function(dt)
		local mouseX, mouseY = UIS:GetMouseLocation().X, UIS:GetMouseLocation().Y
		for i, orb in ipairs(orbs) do
			-- safe-guards
			if not orb or not orb.Parent or not orbStates[i] then
				goto continue_orb
			end

			local absPos = orb.AbsolutePosition + Vector2.new(orb.AbsoluteSize.X/2, orb.AbsoluteSize.Y/2)
			local diff = Vector2.new(absPos.X - mouseX, absPos.Y - mouseY)
			local dist = diff.Magnitude
			if dist < ORB_REPEL_DISTANCE then
				local dir = (dist > 0) and diff.Unit or Vector2.new(0,0)
				local force = (1 - dist/ORB_REPEL_DISTANCE) * ORB_BOUNCE_FORCE
				orbStates[i].vel = orbStates[i].vel + dir * (force * dt)
			end

			-- attract to original pos:
			local posUD = orbStates[i].pos
			if not (posUD and posUD.X and posUD.Y) then
				posUD = orb.Position
				orbStates[i].pos = posUD
			end
			local target = Vector2.new(Window.AbsolutePosition.X + posUD.X.Offset + orb.AbsoluteSize.X/2, Window.AbsolutePosition.Y + posUD.Y.Offset + orb.AbsoluteSize.Y/2)
			local cur = orb.AbsolutePosition + Vector2.new(orb.AbsoluteSize.X/2, orb.AbsoluteSize.Y/2)
			local toTarget = (target - cur)
			orbStates[i].vel = orbStates[i].vel + toTarget * 3 * dt
			orbStates[i].vel = orbStates[i].vel * (1 - math.clamp(6*dt, 0, 1))
			local newPos = UDim2.new(posUD.X.Scale, posUD.X.Offset + orbStates[i].vel.X * 0.5, posUD.Y.Scale, posUD.Y.Offset + orbStates[i].vel.Y * 0.5)
			orbStates[i].pos = newPos

			-- apply position directly (cheap)
			pcall(function() orb.Position = newPos end)

			local inner = orb_inners[orb]
			if inner then
				pcall(function()
					inner.BackgroundColor3 = DEFAULT_THEME.TopLeft:Lerp(DEFAULT_THEME.BottomRight or DEFAULT_THEME.TopLeft, i / #orbs)
				end)
			end

			::continue_orb::
		end
	end)

	-- public API
	function self:Notify(txt, dur) notify(txt, dur) end

	function self:Destroy()
		-- disconnecting RenderStepped not required (anonymous connection), just destroy GUI safely
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
return setmetatable(CelestialUI, {
	__call = function(_, ...)
		return CelestialUI:CreateWindow(...)
	end
})

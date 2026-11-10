-- Shared plant-art reviewer, explicitly opened in a Studio playtest client (docs/PLANT_GROWTH.md).
-- The plot, controls and clock exist only for this review. Close restores the camera and HUD.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Input = game:GetService("UserInputService")

local function open(cropId: string?, seconds: number?)
	assert(RunService:IsStudio() and RunService:IsClient(), "Use the Studio playtest Client command bar")

	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	local PlotView = require(player.PlayerScripts:WaitForChild("PlotView"))
	local CropConfig = require(ReplicatedStorage.CropConfig)
	local GardenConfig = require(ReplicatedStorage.GardenConfig)
	local Locale = require(ReplicatedStorage.Locale)
	local choices, modules = {}, {}
	for _, candidate in CropConfig.Crops do
		local module = ReplicatedStorage:FindFirstChild(candidate.id .. "Plant")
		if module and module:IsA("ModuleScript") then
			table.insert(choices, candidate)
			modules[candidate.id] = module
		end
	end
	assert(#choices > 0, "No plant recipes to review")
	local crop = assert(CropConfig.ById[cropId or choices[1].id], "Unknown review crop")
	local Growth = require(ReplicatedStorage.PlantGrowth)
	local recipe = require(assert(modules[crop.id], "No art recipe for " .. crop.id))
	local duration = seconds or math.min(crop.growSeconds, 10)
	local elapsed = 0
	assert(duration > 0, "Review duration must be positive")
	local name = "PlantGrowthReview"
	assert(not workspace:FindFirstChild(name), "Close the existing plant review first")
	local drawn = workspace:WaitForChild("GardenView")
	local slot
	for n = 13, GardenConfig.PlotSlots do
		if not drawn:FindFirstChild(string.format("Slot_%02d", n)) then
			slot = n
			break
		end
	end
	assert(slot, "The review needs a free outer plot slot")
	local root = Instance.new("Folder")
	root.Name = name
	local view = PlotView.new(slot, root)
	local cells = table.create(CropConfig.MaxSquares, "#0")
	for i = 1, 12 do cells[i] = ".0" end
	cells[2] = if crop.id == "Potato" then "k3" else "a2"
	view:SetState({name = player.DisplayName, incCount = 1, eggs = {},
		field = {crops = table.concat(cells), pets = {"Cat:3:review:4:1:1"}}})
	view:SetDetail("full")
	while view:Step(os.clock() + 0.006) do task.wait() end

	local poses = {0, 0.2, 0.5, 0.75, 1}
	local plants = {}
	local rings = {}
	local fieldLabels = {}
	for _, label in view.root:GetDescendants() do
		if label:IsA("BillboardGui") and label.Enabled then table.insert(fieldLabels, label) end
	end
	local fieldAnchor = workspace:FindFirstChild("FieldRings")
	local template = fieldAnchor and fieldAnchor:FindFirstChildWhichIsA("BillboardGui", true)

	local function addRing(square)
		local attachment = Instance.new("Attachment")
		attachment.Parent = view.pieces["sq" .. square]:FindFirstChild("Soil" .. square)
		attachment.WorldCFrame = view:SquareCFrame(square)
		local gui
		if template then
			gui = template:Clone()
			gui.Time.Visible = false
			gui.Disc.Inner.Icon.Text = crop.icon
		else
			-- An empty player field has no live ring to clone. Use a crop marker
			-- at the production disc size and offset for the overlap check.
			gui = Instance.new("BillboardGui")
			gui.Size = UDim2.fromScale(2.3, 2.3)
			gui.StudsOffset = Vector3.new(0, 1.3, 3)
			local icon = Instance.new("TextLabel")
			icon.Size = UDim2.fromScale(1, 1)
			icon.BackgroundColor3 = Color3.fromRGB(35,35,40)
			icon.Text = crop.icon
			icon.TextScaled = true
			icon.Parent = gui
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0.5,0)
			corner.Parent = icon
		end
		gui.Enabled = root:GetAttribute("Rings")
		gui.StudsOffset = Vector3.new(0,Growth.RecipeRingHeight(recipe,root:GetAttribute("SizeFactor")),3)
		gui.Adornee = attachment
		gui.Parent = attachment
		table.insert(rings, {attachment = attachment, gui = gui})
	end

	local function fillRing(ring, progress)
		local disc = ring.gui:FindFirstChild("Disc")
		if not disc then return end
		disc.Check.Visible = progress >= 1
		local color = if progress >= 1 then Color3.fromRGB(90,225,90) else Color3.fromRGB(245,200,70)
		for _, half in disc.Pie:GetChildren() do
			half.Fill.BackgroundColor3 = color
			half.Fill.UIGradient.Rotation = if half.Name == "Right" then math.min(180, 360*progress) else math.max(0, 360*progress-180)
		end
	end

	local function addPlant(square, seed, progress)
		local frame = Growth.PlantCFrame(view:SquareCFrame(square), seed, recipe)
		local plant = recipe.new(root, frame, seed, root:GetAttribute("SizeFactor"))
		plant:SetGrowth(progress)
		table.insert(plants, plant)
		addRing(square)
		fillRing(rings[#rings], progress)
	end

	local camera = workspace.CurrentCamera
	local originalType, originalFrame, originalFocus = camera.CameraType, camera.CFrame, camera.Focus
	local eye, target
	local function rebuild()
		for _, plant in plants do plant:Destroy() end
		for _, ring in rings do ring.attachment:Destroy() end
		table.clear(plants)
		table.clear(rings)
		local mode = root:GetAttribute("View")
		local seed = root:GetAttribute("Seed")
		local base = view:SquareCFrame(9)
		local center, distance, height
		if mode == "Plant" then
			addPlant(9, seed, root:GetAttribute("Growth"))
			center, distance, height = 0, 7.5, 3.2
		elseif mode == "Poses" then
			for i, progress in poses do addPlant(6+i, seed, progress) end
			center, distance, height = 0, 18, 6
		else
			for i = 1, 6 do addPlant(6+i, i, 1) end
			center, distance, height = 2.75, 21, 7
		end
		local reviewHeight = recipe.ReviewHeight
		local targetHeight = 1.25
		if reviewHeight then
			-- A tall trained vine needs its living canopy and rigid support in frame.
			targetHeight = reviewHeight / 2
			height = math.max(height, reviewHeight * 0.9)
			distance = math.max(distance, reviewHeight * 1.15)
		end
		-- Keep the full comparison row in view on narrower Studio windows.
		local aspect = camera.ViewportSize.X / math.max(1, camera.ViewportSize.Y)
		distance *= math.max(1, 1.55/aspect)
		target = base:PointToWorldSpace(Vector3.new(center, targetHeight, 0))
		eye = base:PointToWorldSpace(Vector3.new(center, height, distance))
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = name
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.AutoLocalize = false
	gui.DisplayOrder = 100
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	local panel = Instance.new("Frame")
	panel.Name = "Controls"
	panel.AnchorPoint = Vector2.new(0.5, 1)
	panel.Position = UDim2.new(0.5,0,1,-12)
	panel.Size = UDim2.new(0.94,0,0,149)
	panel.BackgroundColor3 = Color3.fromRGB(32,49,43)
	panel.Parent = gui
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(624,149)
	limit.Parent = panel
	local round = Instance.new("UICorner")
	round.Parent = panel

	local function control(id, index, columns, y, fn)
		local b = Instance.new("TextButton")
		b.Name, b.Text = id, ""
		b.AutoLocalize = false
		b.Position = UDim2.new((index-1)/columns,4,0,y)
		b.Size = UDim2.new(1/columns,-8,0,30)
		b.Font = Enum.Font.GothamMedium
		b.TextSize = 14
		b.TextColor3 = Color3.fromRGB(244,248,237)
		b.BackgroundColor3 = Color3.fromRGB(54,79,65)
		b.Parent = panel
		b.Activated:Connect(fn)
		return b
	end

	local picker = Instance.new("ScrollingFrame")
	picker.Name = "CropPicker"
	picker.BackgroundColor3 = Color3.fromRGB(32,49,43)
	picker.BorderSizePixel = 0
	picker.AutomaticCanvasSize = Enum.AutomaticSize.Y
	picker.CanvasSize = UDim2.fromOffset(0,0)
	picker.ScrollBarThickness = 6
	picker.ZIndex = 3
	picker.Visible = false
	picker.Parent = panel
	local padding = Instance.new("UIPadding")
	padding.PaddingTop, padding.PaddingBottom = UDim.new(0,4), UDim.new(0,4)
	padding.PaddingLeft, padding.PaddingRight = UDim.new(0,4), UDim.new(0,10)
	padding.Parent = picker
	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0,4)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = picker
	local cropButton = control("Crop",1,1,5,function()
		local height = math.min(240,#choices*34+8,math.max(40,panel.AbsolutePosition.Y-12))
		picker.Position = UDim2.fromOffset(4,-height-6)
		picker.Size = UDim2.new(1,-8,0,height)
		picker.Visible = not picker.Visible
	end)
	cropButton.TextWrapped = true
	local chooseCrop
	local cropButtons = {}
	for i, candidate in choices do
		local b = Instance.new("TextButton")
		b.Name = candidate.id
		b.AutoLocalize = false
		b.Size = UDim2.new(1,0,0,30)
		b.LayoutOrder = i
		b.Font = Enum.Font.GothamMedium
		b.TextSize = 14
		b.TextColor3 = Color3.fromRGB(244,248,237)
		b.TextWrapped = true
		b.BorderSizePixel = 0
		b.ZIndex = 4
		b.Parent = picker
		b.Activated:Connect(function() chooseCrop(candidate) end)
		cropButtons[candidate.id] = b
	end

	local function showMode(mode)
		root:SetAttribute("Playing", false)
		root:SetAttribute("View", mode)
	end
	local modes = {}
	for i, mode in {"Plant", "Poses", "Seeds"} do
		modes[mode] = control(mode,i,4,40,function() showMode(mode) end)
	end
	local function close()
		root:Destroy()
	end
	local closeButton = control("Close",4,4,40,close)
	local play = control("Play",1,4,75,function()
		root:SetAttribute("View","Plant")
		root:SetAttribute("Playing", not root:GetAttribute("Playing"))
	end)
	local seedButton = control("Seed",2,4,75,function()
		if root:GetAttribute("View") == "Seeds" then showMode("Plant") end
		root:SetAttribute("Seed", root:GetAttribute("Seed")%6+1)
	end)
	local ringsButton = control("Rings",3,4,75,function()
		root:SetAttribute("Rings", not root:GetAttribute("Rings"))
	end)
	local lowSize, highSize = CropConfig.SizeBounds()
	local sizes = {lowSize, 1, highSize}
	local sizeIndex = 2
	local sizeButton = control("Size",4,4,75,function()
		sizeIndex = sizeIndex % #sizes + 1
		root:SetAttribute("SizeFactor", sizes[sizeIndex])
	end)
	local slider = Instance.new("TextButton")
	slider.Name = "Scrubber"
	slider.Position = UDim2.fromOffset(8,113)
	slider.Size = UDim2.new(1,-16,0,28)
	slider.AutoButtonColor = false
	slider.Text = ""
	slider.BackgroundColor3 = Color3.fromRGB(22,37,30)
	slider.Parent = panel
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(0,1)
	fill.BackgroundColor3 = Color3.fromRGB(69,125,77)
	fill.BorderSizePixel = 0
	fill.Parent = slider
	local value = Instance.new("TextLabel")
	value.Size = UDim2.fromScale(1,1)
	value.BackgroundTransparency = 1
	value.Font = Enum.Font.GothamBold
	value.TextSize = 16
	value.TextColor3 = Color3.new(1,1,1)
	value.Parent = slider
	local function refreshGrowth()
		local p = root:GetAttribute("Growth")
		value.Text = string.format("%d%%", math.round(p*100))
		fill.Size = UDim2.fromScale(p,1)
		if plants[1] and root:GetAttribute("View") == "Plant" then
			plants[1]:SetGrowth(p)
			fillRing(rings[1], p)
		end
	end
	local function refreshRings()
		local enabled = root:GetAttribute("Rings")
		ringsButton.Text = if enabled then "Rings ✓" else "Rings ○" -- loc: ignore (Studio review)
		for _,ring in rings do ring.gui.Enabled = enabled end
		for _,label in fieldLabels do label.Enabled = enabled end
		view:ShowSelect(if enabled and root:GetAttribute("View") == "Plant" then 9 else nil)
	end
	local function seek(x)
		root:SetAttribute("Playing", false)
		root:SetAttribute("View", "Plant")
		local p = math.clamp((x-slider.AbsolutePosition.X)/slider.AbsoluteSize.X,0,1)
		root:SetAttribute("Growth", math.round(100*p)/100)
	end

	root:SetAttribute("Growth", 1)
	root:SetAttribute("View", "Plant")
	root:SetAttribute("Seed", 1)
	root:SetAttribute("SizeFactor", 1)
	root:SetAttribute("Rings", false)
	root:SetAttribute("Playing", false)
	root:SetAttribute("CropId", crop.id)
	local function refreshControls()
		local mode = root:GetAttribute("View")
		for id, button in modes do
			button.BackgroundColor3 = if id == mode then Color3.fromRGB(76,119,86) else Color3.fromRGB(54,79,65)
		end
		modes.Plant.Text = "One plant" -- loc: ignore (Studio review)
		modes.Poses.Text = "Five poses" -- loc: ignore (Studio review)
		modes.Seeds.Text = "Six seeds" -- loc: ignore (Studio review)
		closeButton.Text = "Close" -- loc: ignore (Studio review)
		play.Text = if root:GetAttribute("Playing") then "Pause" else "Play" -- loc: ignore (Studio review)
		seedButton.Text = "Seed " .. root:GetAttribute("Seed") -- loc: ignore (Studio review)
		sizeButton.Text = string.format("Size ×%.2f",root:GetAttribute("SizeFactor")) -- loc: ignore (Studio review)
		cropButton.Text = crop.icon .. " " .. Locale.CropName(crop) .. " ▼"
		for _, candidate in choices do
			local b = cropButtons[candidate.id]
			b.Text = candidate.icon .. " " .. Locale.CropName(candidate)
			b.BackgroundColor3 = if candidate.id == crop.id then Color3.fromRGB(76,119,86) else Color3.fromRGB(54,79,65)
		end
		slider.Visible = mode == "Plant"
		refreshRings()
	end
	local function refreshStudy()
		rebuild()
		refreshControls()
		refreshGrowth()
	end
	chooseCrop = function(nextCrop)
		picker.Visible = false
		if nextCrop.id == crop.id then return end
		local nextRecipe = require(modules[nextCrop.id])
		crop, recipe = nextCrop, nextRecipe
		duration = seconds or math.min(crop.growSeconds,10)
		elapsed = root:GetAttribute("Growth")*duration
		root:SetAttribute("CropId",crop.id)
		-- Keep the comparison neighbour distinct from the selected crop, without replacing soil or the field pet.
		cells[2] = if crop.id == "Potato" then "k3" else "a2"
		view:SetState({name = player.DisplayName,incCount = 1,eggs = {},
			field = {crops = table.concat(cells),pets = {"Cat:3:review:4:1:1"}}})
		view:Step(math.huge)
		refreshStudy()
	end
	root:GetAttributeChangedSignal("View"):Connect(refreshStudy)
	root:GetAttributeChangedSignal("Seed"):Connect(refreshStudy)
	root:GetAttributeChangedSignal("SizeFactor"):Connect(refreshStudy)
	root:GetAttributeChangedSignal("Growth"):Connect(refreshGrowth)
	root:GetAttributeChangedSignal("Rings"):Connect(refreshRings)
	root:GetAttributeChangedSignal("Playing"):Connect(function()
		local playing = root:GetAttribute("Playing")
		play.Text = if playing then "Pause" else "Play" -- loc: ignore (Studio review)
		elapsed = if root:GetAttribute("Growth") >= 1 then 0 else root:GetAttribute("Growth")*duration
	end)
	refreshStudy()
	local languageChanged = Locale.Changed:Connect(refreshControls)
	local dismiss = Input.InputBegan:Connect(function(event)
		if not picker.Visible then return end
		if event.UserInputType ~= Enum.UserInputType.MouseButton1 and event.UserInputType ~= Enum.UserInputType.Touch then return end
		local function inside(object)
			local at, size = object.AbsolutePosition, object.AbsoluteSize
			return event.Position.X >= at.X and event.Position.X <= at.X+size.X
				and event.Position.Y >= at.Y and event.Position.Y <= at.Y+size.Y
		end
		if not inside(picker) and not inside(cropButton) then picker.Visible = false end
	end)

	local held
	slider.InputBegan:Connect(function(event)
		if event.UserInputType == Enum.UserInputType.MouseButton1 or event.UserInputType == Enum.UserInputType.Touch then
			held = event
			seek(event.Position.X)
		end
	end)
	local moved = Input.InputChanged:Connect(function(event)
		if held and (event == held or (held.UserInputType == Enum.UserInputType.MouseButton1 and event.UserInputType == Enum.UserInputType.MouseMovement)) then
			seek(event.Position.X)
		end
	end)
	local ended = Input.InputEnded:Connect(function(event)
		if held == event or event.UserInputType == Enum.UserInputType.MouseButton1 then held = nil end
	end)
	local hidden = {}
	for _, screen in playerGui:GetChildren() do
		if screen:IsA("ScreenGui") and screen.Enabled then
			screen.Enabled = false
			table.insert(hidden, screen)
		end
	end
	root.Destroying:Connect(function()
		RunService:UnbindFromRenderStep(name)
		moved:Disconnect()
		ended:Disconnect()
		dismiss:Disconnect()
		languageChanged:Disconnect()
		for _, plant in plants do plant:Destroy() end
		for _, ring in rings do ring.attachment:Destroy() end
		view:Destroy()
		gui:Destroy()
		for _,screen in hidden do if screen.Parent then screen.Enabled = true end end
		camera.CFrame, camera.Focus, camera.CameraType = originalFrame, originalFocus, originalType
	end)
	root.Parent, gui.Parent = workspace, playerGui
	RunService:BindToRenderStep(name, Enum.RenderPriority.Last.Value+1, function(dt)
		camera.CFrame = CFrame.lookAt(eye,target)
		camera.Focus = CFrame.new(target)
		if root:GetAttribute("Playing") then
			elapsed = (elapsed+dt)%(duration+1)
			root:SetAttribute("Growth", math.min(elapsed/duration,1))
		end
	end)
	return root:GetFullName()
end

return {Open = open}

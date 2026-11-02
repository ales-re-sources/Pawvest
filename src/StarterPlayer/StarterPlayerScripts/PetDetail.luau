-- PetDetail (P3a, docs/ROADMAP.md → P3): the detail page of one pet, drawn over the Pets panel (PetsPanel mounts it and opens it
-- from the "i" badge on a row's portrait; a tap on the row itself still equips). Display only, like the Pets panel: the numbers come
-- from PetClient.State (PetsChanged) and PetConfig, every action is a request the server validates (PetService).
--   Mount(panel, color, onClose)  builds the page as a child of `panel` (covers it, same size and UIScale) and returns
--                                 { Open(uid), Close(), IsOpen() }; onClose() closes the whole Pets panel (the X)
-- Sections: header (turning portrait, kind, rarity + tier stars, where the pet is), growth (level, XP bar, how it grows, the next
-- look, the Coin bonus), one card per working aptitude (PetConfig.Shown; only for players with the field: level / rarity cap,
-- effect bar, field hours to the next level, reach), actions (Equip / Unequip, Sell with a second tap). The page re-renders on
-- PetsChanged and Locale.Changed and closes itself when the pet is gone (sold).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local PetConfig = require(ReplicatedStorage:WaitForChild("PetConfig"))
local PetLook = require(ReplicatedStorage:WaitForChild("PetLook"))
local StudStyle = require(ReplicatedStorage:WaitForChild("StudStyle"))
local Locale = require(ReplicatedStorage:WaitForChild("Locale"))
local GardenConfig = require(ReplicatedStorage:WaitForChild("GardenConfig"))
local PetClient = require(script.Parent:WaitForChild("PetClient"))
local PetPortrait = require(script.Parent:WaitForChild("PetPortrait"))

local remotes = PetClient.Remotes
local fieldAccess = GardenConfig.HasFieldAccess(Players.LocalPlayer.UserId)

local PORTRAIT = 104
local BAR_HEIGHT = 16
local SPIN_SPEED = 0.6 -- radians per second
local CONFIRM_SECONDS = 3
local PAGE_Z = 20 -- the page's ZIndex; its contents are lifted by as much

local COLOR_INFO = Color3.fromRGB(190, 190, 190)
local COLOR_DIM = Color3.fromRGB(150, 150, 150)
local COLOR_ERROR = Color3.fromRGB(240, 100, 90)
local COLOR_OK = Color3.fromRGB(120, 230, 120)
local COLOR_EQUIPPED = Color3.fromRGB(255, 205, 60)
local COLOR_XP = Color3.fromRGB(120, 200, 255)
local COLOR_APT = Color3.fromRGB(140, 220, 120)
local COLOR_EQUIP = StudStyle.Colors.Yellow
local COLOR_LOCKED = StudStyle.Colors.Grey
local COLOR_SELL = StudStyle.Colors.Red
local COLOR_SELL_IDLE = StudStyle.Colors.Wood

local REJECT_KEYS = {
	coins = "common.reject.coins",
	slots = "pets.reject.slots",
	equipped = "pets.reject.equipped",
	penned = "pets.reject.penned",
	field = "pets.reject.field",
	loading = "common.reject.loading",
}

local function create(className: string, props, children)
	local instance = Instance.new(className)
	for key, value in props do
		instance[key] = value
	end
	for _, child in children or {} do
		child.Parent = instance
	end
	return instance
end

local function label(name: string, props)
	props.Name = name
	props.BackgroundTransparency = 1
	props.Font = props.Font or StudStyle.Font
	props.TextColor3 = props.TextColor3 or Color3.new(1, 1, 1)
	props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
	return create("TextLabel", props)
end

-- a wrapping text line that grows with its text (Czech is longer)
local function line(name: string, order: number, props)
	props.LayoutOrder = order
	props.Size = UDim2.new(1, 0, 0, 0)
	props.AutomaticSize = Enum.AutomaticSize.Y
	props.TextWrapped = true
	props.Font = props.Font or Enum.Font.Gotham
	props.TextSize = props.TextSize or 13
	props.TextColor3 = props.TextColor3 or COLOR_INFO
	return label(name, props)
end

local function button(name: string, props, studs: number?)
	props.Name = name
	props.TextColor3 = Color3.new(1, 1, 1)
	local instance = create("TextButton", props)
	StudStyle.Brick(instance, { studs = studs })
	return instance
end

-- a bar 0..1 with a centred text on it
local function bar(name: string, order: number, share: number, color: Color3, text: string)
	return create("Frame", {
		Name = name,
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, BAR_HEIGHT),
		BackgroundColor3 = Color3.fromRGB(30, 30, 30),
		BorderSizePixel = 0,
	}, {
		create("UICorner", { CornerRadius = UDim.new(0, 6) }),
		create("Frame", {
			Name = "Fill",
			Size = UDim2.fromScale(math.clamp(share, 0, 1), 1),
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			Visible = share > 0,
		}, { create("UICorner", { CornerRadius = UDim.new(0, 6) }) }),
		label("Text", {
			Size = UDim2.fromScale(1, 1),
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextStrokeTransparency = 0.5,
			Text = text,
			ZIndex = 2,
		}),
	})
end

-- a dark card holding a vertical list
local function card(name: string, order: number, color: Color3)
	return create("Frame", {
		Name = name,
		LayoutOrder = order,
		Size = UDim2.new(1, -2, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = StudStyle.PetRowColor(color),
	}, {
		create("UICorner", { CornerRadius = UDim.new(0, 8) }),
		create("UIPadding", {
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
			PaddingTop = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 10),
		}),
		create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5) }),
	})
end

-- weighted field seconds as hours with one decimal, in the viewer's decimal mark
local function hours(seconds: number)
	return { decimal = string.format("%.1f", seconds / 3600) }
end

local PetDetail = {}

function PetDetail.Mount(panel: GuiObject, color: Color3, onClose: () -> ())
	local currentUid: string? = nil
	local sellArmed = false
	local sellToken = 0
	local messageToken = 0
	local portraitKey: string? = nil
	local portrait: ViewportFrame? = nil
	local spin: RBXScriptConnection? = nil

	local titleLabel = label("TitleLabel", {
		Size = UDim2.new(1, 0, 0, 34),
		TextSize = 20,
		TextXAlignment = Enum.TextXAlignment.Center,
	})
	local backButton = button("Back", {
		Position = UDim2.new(0, 6, 0, 4),
		Size = UDim2.fromOffset(30, 28),
		ZIndex = 2,
		BackgroundColor3 = StudStyle.Colors.Wood,
		TextSize = 16,
		Text = "<",
	}, 1)
	local closeButton = button("Close", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -6, 0, 4),
		Size = UDim2.fromOffset(30, 28),
		ZIndex = 2,
		BackgroundColor3 = COLOR_SELL,
		TextSize = 16,
		Text = "X",
	}, 1)
	local content = create("ScrollingFrame", {
		Name = "Content",
		Position = UDim2.new(0, 8, 0, 42),
		Size = UDim2.new(1, -16, 1, -50),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 5,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, {
		create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) }),
		create("UIPadding", { PaddingRight = UDim.new(0, 6), PaddingTop = UDim.new(0, 2), PaddingLeft = UDim.new(0, 2) }),
	})
	local page = create("Frame", {
		Name = "Detail",
		Size = UDim2.fromScale(1, 1),
		ZIndex = PAGE_Z,
		Visible = false,
	}, { titleLabel, backButton, closeButton, content })
	StudStyle.Panel(page, color)
	-- PetsGui uses Global ZIndex (a ScreenGui made in code): everything on the page is lifted above the list under it
	local function lift(instance: Instance)
		if instance:IsA("GuiObject") then
			instance.ZIndex += PAGE_Z
		end
	end
	for _, descendant in page:GetDescendants() do
		lift(descendant)
	end
	page.DescendantAdded:Connect(lift)
	page.Parent = panel

	-- the header and the action row stay; the cards in between are rebuilt on every render
	local portraitHolder = PetPortrait.Holder({
		Size = UDim2.fromOffset(PORTRAIT, PORTRAIT),
		BackgroundColor3 = StudStyle.Shade(color, 0.18),
	}, nil)
	local kindLabel = label("Kind", { Size = UDim2.new(1, 0, 0, 24), TextSize = 22, TextTruncate = Enum.TextTruncate.AtEnd })
	local rarityLabel = label("Rarity", { Size = UDim2.new(1, 0, 0, 20), TextSize = 16, TextTruncate = Enum.TextTruncate.AtEnd })
	local whereLabel = label("Where", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextSize = 14,
		TextWrapped = true,
	})
	local header = create("Frame", {
		Name = "Header",
		LayoutOrder = 1,
		Size = UDim2.new(1, 0, 0, PORTRAIT),
		BackgroundTransparency = 1,
	}, {
		portraitHolder,
		create("Frame", {
			Name = "Names",
			Position = UDim2.fromOffset(PORTRAIT + 10, 4),
			Size = UDim2.new(1, -(PORTRAIT + 10), 1, -4),
			BackgroundTransparency = 1,
		}, {
			create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) }),
			kindLabel,
			rarityLabel,
			whereLabel,
		}),
	})
	header.Parent = content

	local equipButton = button("Equip", {
		Size = UDim2.new(0.5, -4, 0, 36),
		TextSize = 15,
	}, 3)
	local sellButton = button("Sell", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.new(0.5, -4, 0, 36),
		TextSize = 15,
	}, 3)
	local actions = create("Frame", {
		Name = "Actions",
		LayoutOrder = 90,
		Size = UDim2.new(1, -2, 0, 40),
		BackgroundTransparency = 1,
	}, { equipButton, sellButton })
	actions.Parent = content
	local messageLabel = line("Message", 91, { TextSize = 14, Text = "" })
	messageLabel.Parent = content

	local cards = {}

	local function pet()
		local state = PetClient.State
		if not (currentUid and state and state.pets[currentUid]) then
			return nil, nil
		end
		for _, owned in PetClient.Inventory() do
			if owned.uid == currentUid then
				return owned, state.pets[currentUid]
			end
		end
		return nil, nil
	end

	local function message(text: string, colour: Color3)
		messageToken += 1
		local mine = messageToken
		messageLabel.Text = text
		messageLabel.TextColor3 = colour
		task.delay(3, function()
			if messageToken == mine then
				messageLabel.Text = ""
			end
		end)
	end

	local function setPortrait(owned)
		local key = owned.uid .. ":" .. owned.kind .. ":" .. owned.level
		if key == portraitKey then
			return
		end
		portraitKey = key
		if portrait then
			portrait:Destroy()
		end
		portrait = PetPortrait.Make(owned.kind, owned.level, owned.uid)
		if portrait then
			portrait.Parent = portraitHolder
		end
	end

	-- the portrait turns slowly while the page is open: the camera circles the model
	local function startSpin()
		if spin then
			return
		end
		spin = RunService.RenderStepped:Connect(function(dt)
			local frame = portrait
			local camera = frame and frame.CurrentCamera
			local model = frame and frame:FindFirstChildOfClass("Model")
			if not (camera and model) then
				return
			end
			local focus = model:GetBoundingBox().Position
			local offset = CFrame.Angles(0, dt * SPIN_SPEED, 0):VectorToWorldSpace(camera.CFrame.Position - focus)
			camera.CFrame = CFrame.lookAt(focus + offset, focus)
		end)
	end

	local function stopSpin()
		if spin then
			spin:Disconnect()
			spin = nil
		end
	end

	local function growthCard(owned)
		local growth = card("Growth", 2, color)
		label("Level", {
			LayoutOrder = 1,
			Size = UDim2.new(1, 0, 0, 22),
			TextSize = 18,
			Text = Locale.T("petDetail.level", { level = owned.level, max = PetConfig.MaxLevel }),
		}).Parent = growth
		if owned.xpNext then
			bar("Xp", 2, owned.xp / owned.xpNext, COLOR_XP, Locale.T("pet.xp", { xp = owned.xp, next = owned.xpNext })).Parent = growth
			line("Grow", 3, { Text = Locale.T("petDetail.grow") }).Parent = growth
		else
			bar("Xp", 2, 1, COLOR_XP, Locale.T("petDetail.levelMax")).Parent = growth
		end
		local nextTier = nil
		for _, level in PetConfig.Tiers do
			if owned.level < level then
				nextTier = level
				break
			end
		end
		line("Look", 4, {
			Text = if nextTier
				then Locale.T("petDetail.nextLook", { stars = string.rep("★", PetLook.Tier(nextTier)), level = nextTier })
				else Locale.T("petDetail.allLooks"),
		}).Parent = growth
		line("Bonus", 5, {
			TextColor3 = if owned.equipped then COLOR_OK else COLOR_INFO,
			Text = Locale.T("petDetail.bonus", { bonus = Locale.T("common.percentBonus", { pct = Locale.Decimal(PetClient.Percent(owned.bonus)) }) }),
		}).Parent = growth
		return growth
	end

	local function aptitudeCard(order: number, owned, stored, id: string)
		local level = PetConfig.AptitudeLevel(stored, id)
		local cap = PetConfig.AptitudeCap(owned.kind)
		local apt = card("Apt_" .. id, order, color)
		label("Name", {
			LayoutOrder = 1,
			Size = UDim2.new(1, 0, 0, 22),
			TextSize = 18,
			TextColor3 = COLOR_APT,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Text = Locale.T("petDetail.aptLevel", { name = Locale.T("pet.apt." .. id), level = level, cap = cap }),
		}).Parent = apt
		line("Desc", 2, { Text = Locale.T("petDetail.aptDesc." .. id) }).Parent = apt
		local strength = PetConfig.Strength(level)
		bar("Effect", 3, strength, COLOR_APT, Locale.T("petDetail.effect", { pct = math.round(strength * 100) })).Parent = apt
		if level >= cap then
			line("Xp", 4, { Text = Locale.T("petDetail.aptMax", { rarity = Locale.RarityName(owned.rarity.id) }) }).Parent = apt
		else
			local need = PetConfig.AptitudeXpToNext(level)
			local xp = stored.Apt[id].XP or 0
			bar("Xp", 4, xp / need, COLOR_XP, Locale.T("petDetail.aptXp", { xp = hours(xp), next = hours(need) })).Parent = apt
			line("Grow", 5, { Text = Locale.T("petDetail.aptGrow") }).Parent = apt
		end
		if id == "Tending" then
			local shape = PetConfig.ReachShape(level)
			local squares = ({ 1, 5, 9 })[shape + 1]
			local reach = Locale.T("petDetail.reach", { count = squares })
			local nextLevel = if shape == 0 then 4 elseif shape == 1 then 7 else nil
			if nextLevel and nextLevel <= cap then
				reach ..= " · " .. Locale.T("petDetail.reachNext", { count = ({ 1, 5, 9 })[shape + 2], level = nextLevel })
			end
			line("Reach", 6, { Text = reach }).Parent = apt
		end
		return apt
	end

	local function render()
		local owned, stored = pet()
		if not owned then
			return false
		end
		titleLabel.Text = Locale.PetName(owned.kind, owned.level)
		setPortrait(owned)
		kindLabel.Text = Locale.PetKindName(owned.kind)
		kindLabel.TextColor3 = owned.rarity.color
		rarityLabel.Text = Locale.RarityName(owned.rarity.id) .. PetLook.TierStars(owned.level)
		rarityLabel.TextColor3 = owned.rarity.color
		whereLabel.Text = if owned.equipped
			then Locale.T("petDetail.where.equipped")
			elseif owned.field then Locale.T("petDetail.where.field", { n = owned.field })
			elseif owned.penned then Locale.T("petDetail.where.pen", { pen = owned.penned })
			else Locale.T("petDetail.where.resting")
		whereLabel.TextColor3 = if owned.equipped then COLOR_EQUIPPED else COLOR_INFO

		for _, old in cards do
			old:Destroy()
		end
		table.clear(cards)
		local growth = growthCard(owned)
		growth.Parent = content
		table.insert(cards, growth)
		if fieldAccess then
			local order, any = 10, false
			for _, id in PetConfig.Aptitudes do
				if PetConfig.Shown[id] and PetConfig.AptitudeLevel(stored, id) > 0 then
					local apt = aptitudeCard(order, owned, stored, id)
					apt.Parent = content
					table.insert(cards, apt)
					order += 1
					any = true
				end
			end
			if not any then
				local none = line("NoJob", order, { TextColor3 = COLOR_DIM, Text = Locale.T("petDetail.noJob") })
				none.Parent = content
				table.insert(cards, none)
			end
		end

		local busy = owned.penned ~= nil or owned.field ~= nil
		equipButton.Text = Locale.T(if owned.equipped then "petDetail.unequip" else "petDetail.equip")
		equipButton.BackgroundColor3 = if busy then COLOR_LOCKED elseif owned.equipped then COLOR_SELL_IDLE else COLOR_EQUIP
		sellButton.Text = Locale.T(if sellArmed then "pets.sellSure" else "pets.sell", { price = owned.sellValue })
		sellButton.BackgroundColor3 = if busy or owned.equipped then COLOR_LOCKED elseif sellArmed then COLOR_SELL else COLOR_SELL_IDLE
		return true
	end

	local api = {}

	function api.IsOpen(): boolean
		return currentUid ~= nil
	end

	function api.Close()
		currentUid = nil
		sellArmed = false
		page.Visible = false
		stopSpin()
	end

	function api.Open(uid: string)
		currentUid = uid
		sellArmed = false
		messageLabel.Text = ""
		portraitKey = nil
		if render() then
			content.CanvasPosition = Vector2.zero
			page.Visible = true
			startSpin()
		else
			api.Close()
		end
	end

	equipButton.Activated:Connect(function()
		local owned = pet()
		if not owned then
			return
		end
		if owned.penned then
			message(Locale.T(REJECT_KEYS.penned), COLOR_ERROR)
		elseif owned.field then
			message(Locale.T(REJECT_KEYS.field), COLOR_ERROR)
		elseif owned.equipped then
			remotes.Unequip:FireServer(owned.uid)
		elseif PetClient.State and #PetClient.State.equipped >= PetClient.State.slots then
			message(Locale.T(REJECT_KEYS.slots), COLOR_ERROR)
		else
			remotes.Equip:FireServer(owned.uid)
		end
	end)

	sellButton.Activated:Connect(function()
		local owned = pet()
		if not owned then
			return
		end
		local reason = if owned.penned then "penned" elseif owned.field then "field" elseif owned.equipped then "equipped" else nil
		if reason then
			message(Locale.T(REJECT_KEYS[reason]), COLOR_ERROR)
			return
		end
		if sellArmed then
			sellArmed = false
			remotes.SellPet:FireServer(owned.uid)
			render()
			return
		end
		sellArmed = true
		sellToken += 1
		local mine = sellToken
		task.delay(CONFIRM_SECONDS, function()
			if sellToken == mine and sellArmed then
				sellArmed = false
				if currentUid then
					render()
				end
			end
		end)
		render()
	end)

	backButton.Activated:Connect(api.Close)
	closeButton.Activated:Connect(function()
		api.Close()
		onClose()
	end)

	PetClient.Changed:Connect(function()
		if currentUid and not render() then
			api.Close() -- sold (the Pets panel shows the sale)
		end
	end)
	PetClient.Result:Connect(function(action, ok, detail)
		if currentUid and not ok and (action == "Equip" or action == "Unequip" or action == "SellPet") then
			message(Locale.T(REJECT_KEYS[detail] or "common.reject.failed"), COLOR_ERROR)
		end
	end)
	Locale.Changed:Connect(function()
		if currentUid then
			render()
		end
	end)

	return api
end

return PetDetail

-- PetDetail (P3a, docs/ROADMAP.md → P3): the detail page of one pet, drawn over the Pets panel (PetsPanel mounts it and opens it
-- from the "i" badge on a row's portrait; a tap on the row itself still equips). Display only, like the Pets panel: the numbers come
-- from PetClient.State (PetsChanged) and PetConfig, every action is a request the server validates (PetService).
--   Mount(panel, color, onClose)  builds the page as a child of `panel` (covers it, same size and UIScale) and returns
--                                 { Open(uid), Close(), IsOpen() }; onClose() closes the whole Pets panel (the X)
-- Sections: header (turning portrait, kind, rarity + tier stars, where the pet is), growth (P4: the level = the best working trait,
-- which trait food and obby XP train now, the next look), one card per working trait (PetConfig.Shown, for every player since P4;
-- Cuteness: the Coin bonus and its XP; the work traits for players without the field: "for later" and their care XP up to the care
-- cap; with the field: level / rarity cap, effect bar, field hours to the next level, reach; E2c Scouting: meter bonus, medal finishes to the next level, the equipped scouts' total; E4b Pest control: the chance to chase
-- crows off, the speciality, the squares it guards), actions (Equip / Unequip, Sell with a second tap). Under the header the name row
-- (P3b): a text box and a button that names (free the first time), renames (PetConfig.RenamePrice) or removes the name; the server
-- cleans, filters and prices it (PetRemotes.Rename), the page shows only the filtered name it sends back. The page re-renders on
-- PetsChanged and Locale.Changed and closes itself when the pet is gone (sold).
-- Feed card (E1a3, players with the field, under Growth while they hold crops and the pet is below the max level): one row per held
-- crop with its XP, Feed (one) and All (as many as the pet can take); GardenRemotes.FeedCrop, the server clamps and answers on
-- GardenRemotes.Result ("FeedCrop"). The held crops come from GardenRemotes.State.field.items.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local PetConfig = require(ReplicatedStorage:WaitForChild("PetConfig"))
local PetLook = require(ReplicatedStorage:WaitForChild("PetLook"))
local StudStyle = require(ReplicatedStorage:WaitForChild("StudStyle"))
local Locale = require(ReplicatedStorage:WaitForChild("Locale"))
local GardenConfig = require(ReplicatedStorage:WaitForChild("GardenConfig"))
local CropConfig = require(ReplicatedStorage:WaitForChild("CropConfig"))
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
-- answers to GardenRemotes.FeedCrop (E1a3)
local FEED_REJECT_KEYS = {
	items = "field.reason.items",
	maxed = "petDetail.feed.maxed",
	locked = "field.reason.locked",
	loading = "common.reject.loading",
}
-- answers to PetRemotes.Rename (P3b)
local RENAME_REJECT_KEYS = {
	name = "petDetail.reject.name",
	same = "petDetail.reject.same",
	cooldown = "petDetail.reject.cooldown",
	filter = "petDetail.reject.filter",
	coins = "common.reject.coins",
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

	-- name row (P3b)
	local nameBox = create("TextBox", {
		Name = "NameBox",
		Size = UDim2.new(1, -112, 1, 0),
		BackgroundColor3 = Color3.fromRGB(30, 30, 30),
		TextColor3 = Color3.new(1, 1, 1),
		PlaceholderColor3 = COLOR_DIM,
		Font = StudStyle.Font,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ClearTextOnFocus = false,
		Text = "",
	}, {
		create("UICorner", { CornerRadius = UDim.new(0, 6) }),
		create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }),
	})
	local nameButton = button("NameSave", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.new(0, 104, 1, 0),
		TextSize = 14,
	}, 2)
	local nameRow = create("Frame", {
		Name = "NameRow",
		LayoutOrder = 2,
		Size = UDim2.new(1, -2, 0, 34),
		BackgroundTransparency = 1,
	}, { nameBox, nameButton })
	nameRow.Parent = content
	local nameNote = line("NameNote", 3, { TextSize = 12, Text = "" })
	nameNote.Parent = content
	local nameNoteToken = 0 -- while a result note shows (non-zero), the hint waits until it lapses

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
	local heldCrops: { [string]: number } = {} -- GardenRemotes.State.field.items (E1a3)
	local feedEvent: RemoteEvent? = nil
	local feedNote: { text: string, color: Color3 }? = nil
	local feedToken = 0
	local render: () -> boolean

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
		local growth = card("Growth", 4, color)
		label("Level", {
			LayoutOrder = 1,
			Size = UDim2.new(1, 0, 0, 22),
			TextSize = 18,
			Text = Locale.T("petDetail.level", { level = owned.level, max = PetConfig.MaxLevel }),
		}).Parent = growth
		-- P4: the level is the best working trait's; food and obby XP train owned.care (its bar is on the trait's card)
		bar("Xp", 2, owned.level / PetConfig.MaxLevel, COLOR_XP, if owned.level >= PetConfig.MaxLevel
			then Locale.T("petDetail.levelMax")
			else Locale.T("petDetail.levelNote")).Parent = growth
		line("Grow", 3, {
			Text = if owned.care
				then Locale.T("petDetail.care", { trait = Locale.T("pet.apt." .. owned.care) })
				else Locale.T("petDetail.careDone"),
		}).Parent = growth
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
		-- P4: every player sees the traits; the work traits do something only on the crop field (Scouting fills its seed meters)
		local later = id ~= "Cuteness" and not fieldAccess
		line("Desc", 2, { Text = Locale.T(if later then "petDetail.aptDesc.later" else "petDetail.aptDesc." .. id) }).Parent = apt
		local limit = PetConfig.CareLimit(owned.kind, id)
		if id == "Cuteness" then
			local bonus = Locale.T("common.percentBonus", { pct = Locale.Decimal(PetClient.Percent(owned.bonus)) })
			bar("Effect", 3, level / cap, COLOR_APT, Locale.T("petDetail.bonus", { bonus = bonus })).Parent = apt
			if level >= cap then
				line("Xp", 4, { Text = Locale.T("petDetail.aptMax", { rarity = Locale.RarityName(owned.rarity.id) }) }).Parent = apt
			else
				local need = PetConfig.CuteXpToNext(level) or 1
				local xp = math.floor(stored.Apt.Cuteness.XP or 0)
				bar("Xp", 4, xp / need, COLOR_XP, Locale.T("pet.xp", { xp = xp, next = need })).Parent = apt
				line("Grow", 5, { Text = Locale.T("petDetail.cuteGrow") }).Parent = apt
			end
			return apt
		elseif later then
			if level < limit then
				local rate = PetConfig.CareSecondsPerXp
				local need = math.ceil(PetConfig.AptitudeXpToNext(level) / rate)
				local xp = math.floor((stored.Apt[id].XP or 0) / rate)
				bar("Xp", 4, xp / need, COLOR_XP, Locale.T("pet.xp", { xp = xp, next = need })).Parent = apt
			end
			line("Grow", 5, { Text = Locale.T("petDetail.careNote", { cap = limit }) }).Parent = apt
			return apt
		end
		if level < limit then
			line("Care", 8, { Text = Locale.T("petDetail.careNote", { cap = limit }) }).Parent = apt
		end
		local strength = PetConfig.Strength(level)
		local scouting = id == "Scouting" -- E2c: a with-you aptitude, its XP counts medal finishes
		local guarding = id == "PestControl" -- E4b: chases crows off on the field
		local rules = PetConfig.Scouting
		if guarding then
			local chance = PetConfig.GuardChance(level, stored.Spec, "Crows")
			bar("Effect", 3, chance, COLOR_APT, Locale.T("petDetail.guardEffect", { pct = math.round(chance * 100) })).Parent = apt
		else
			bar("Effect", 3, strength, COLOR_APT, if scouting
				then Locale.T("petDetail.scoutEffect", { pct = math.round(rules.PerStrength * strength * 100) })
				else Locale.T("petDetail.effect", { pct = math.round(strength * 100) })).Parent = apt
		end
		if level >= cap then
			line("Xp", 4, { Text = Locale.T("petDetail.aptMax", { rarity = Locale.RarityName(owned.rarity.id) }) }).Parent = apt
		else
			local need = PetConfig.AptitudeXpToNext(level)
			local xp = stored.Apt[id].XP or 0
			bar("Xp", 4, xp / need, COLOR_XP, if scouting
				then Locale.T("petDetail.scoutXp", { done = math.floor(xp / rules.XpPerFinish), need = math.ceil(need / rules.XpPerFinish) })
				else Locale.T("petDetail.aptXp", { xp = hours(xp), next = hours(need) })).Parent = apt
			line("Grow", 5, { Text = Locale.T(if scouting then "petDetail.scoutGrow" else "petDetail.aptGrow") }).Parent = apt
		end
		if scouting then
			local state = PetClient.State
			local team = {}
			for _, uid in (state and state.equipped or {}) do
				table.insert(team, state.pets[uid])
			end
			line("Team", 6, { Text = Locale.T("petDetail.scoutTeam", {
				pct = math.round(PetConfig.ScoutBonus(team) * 100),
				cap = math.round(rules.Cap * 100),
			}) }).Parent = apt
			line("Pouch", 7, { Text = Locale.T("petDetail.scoutPouch", { pct = math.round(rules.PouchExtraAt * 100) }) }).Parent = apt
		end
		if guarding and type(stored.Spec) == "string" then
			line("Spec", 7, { Text = Locale.T(if stored.Spec == "Crows" then "petDetail.guardSpec" else "petDetail.guardSpecLater", {
				critter = Locale.T("pet.critter." .. stored.Spec),
				mult = PetConfig.Guard.SpecMult,
			}) }).Parent = apt
		end
		if id == "Tending" or guarding then
			local shape = PetConfig.ReachShape(level)
			local squares = ({ 1, 5, 9 })[shape + 1]
			local reach = Locale.T(if guarding then "petDetail.guardReach" else "petDetail.reach", { count = squares })
			local nextLevel = if shape == 0 then 4 elseif shape == 1 then 7 else nil
			if nextLevel and nextLevel <= cap then
				reach ..= " · " .. Locale.T("petDetail.reachNext", { count = ({ 1, 5, 9 })[shape + 2], level = nextLevel })
			end
			line("Reach", 6, { Text = reach }).Parent = apt
		end
		return apt
	end

	-- Crops the pet can still take: as many as reach the max level (the last one may go past it).
	local function canTake(owned, crop): number
		local stored = PetClient.State and PetClient.State.pets[owned.uid]
		return if stored then math.ceil(GardenConfig.XpToMax(stored) / crop.xp) else 0
	end

	local function feedCard(owned)
		if not fieldAccess then
			return nil
		end
		local rows = {}
		if owned.xpNext then -- no rows at the max level
			for _, crop in CropConfig.Crops do
				if (heldCrops[crop.id] or 0) > 0 then
					table.insert(rows, crop)
				end
			end
		end
		if #rows == 0 and not feedNote then -- the result line stays while it shows (the pet may just have reached the max level)
			return nil
		end
		local feed = card("Feed", 5, color)
		label("Title", {
			LayoutOrder = 1,
			Size = UDim2.new(1, 0, 0, 22),
			TextSize = 18,
			Text = Locale.T("petDetail.feed.title"),
		}).Parent = feed
		for index, crop in rows do
			local held = heldCrops[crop.id]
			local all = math.min(held, canTake(owned, crop))
			local oneButton = button("One", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, if all > 1 then -76 else 0, 0.5, 0),
				Size = UDim2.fromOffset(70, 32),
				BackgroundColor3 = COLOR_EQUIP,
				TextSize = 14,
				Text = Locale.T("petDetail.feed.one"),
			}, 2)
			local allButton = button("All", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, 0, 0.5, 0),
				Size = UDim2.fromOffset(70, 32),
				BackgroundColor3 = COLOR_EQUIP,
				TextSize = 14,
				Visible = all > 1,
				Text = Locale.T("petDetail.feed.all", { count = all }),
			}, 2)
			local text = create("Frame", {
				Name = "Text",
				Size = UDim2.new(1, if all > 1 then -152 else -76, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
			}, {
				create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }),
				line("Crop", 1, {
					TextSize = 15,
					TextColor3 = Color3.new(1, 1, 1),
					Font = StudStyle.Font,
					Text = Locale.T("petDetail.feed.crop", { icon = crop.icon, crop = Locale.CropName(crop), count = held }),
				}),
				line("Xp", 2, { TextSize = 12, TextColor3 = COLOR_XP, Text = Locale.T("petDetail.feed.xp", { xp = crop.xp }) }),
			})
			create("Frame", {
				Name = "Row_" .. crop.id,
				LayoutOrder = 1 + index,
				Size = UDim2.new(1, 0, 0, 36),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
			}, { text, oneButton, allButton }).Parent = feed
			local function send(count: number)
				if feedEvent then
					feedEvent:FireServer(owned.uid, crop.id, count)
				end
			end
			oneButton.Activated:Connect(function()
				send(1)
			end)
			allButton.Activated:Connect(function()
				send(all)
			end)
		end
		if feedNote then
			line("Note", 50, { TextSize = 13, TextColor3 = feedNote.color, Text = feedNote.text }).Parent = feed
		end
		return feed
	end

	local function feedResult(text: string, colour: Color3)
		feedToken += 1
		local mine = feedToken
		feedNote = { text = text, color = colour }
		if currentUid then
			render()
		end
		task.delay(4, function()
			if feedToken == mine then
				feedNote = nil
				if currentUid then
					render()
				end
			end
		end)
	end

	-- The name button and its hint for the text in the box (P3b): Save · free / Save · price / Remove, or greyed when there is
	-- nothing to save.
	local function updateName()
		local owned = pet()
		if not owned then
			return
		end
		nameBox.PlaceholderText = Locale.T("petDetail.name.placeholder")
		local clean = PetConfig.CleanName(nameBox.Text)
		local price = if owned.renamed then PetConfig.RenamePrice else 0
		local hint, hintColor = nil, COLOR_DIM
		if clean == nil then
			nameButton.Text = Locale.T("petDetail.name.save")
			nameButton.BackgroundColor3 = COLOR_LOCKED
			hint, hintColor = Locale.T("petDetail.reject.name", { max = PetConfig.NameMaxLength }), COLOR_ERROR
		elseif clean == (owned.name or "") then
			nameButton.Text = Locale.T("petDetail.name.save")
			nameButton.BackgroundColor3 = COLOR_LOCKED
			hint = if price > 0 then Locale.T("petDetail.name.priceNote", { price = price }) else Locale.T("petDetail.name.freeNote")
		elseif clean == "" then
			nameButton.Text = Locale.T("petDetail.name.clear")
			nameButton.BackgroundColor3 = COLOR_SELL_IDLE
			hint = Locale.T("petDetail.name.clearNote")
		else
			nameButton.Text = if price > 0 then Locale.T("petDetail.name.buy", { price = price }) else Locale.T("petDetail.name.free")
			nameButton.BackgroundColor3 = COLOR_EQUIP
			hint = if price > 0 then Locale.T("petDetail.name.priceNote", { price = price }) else Locale.T("petDetail.name.freeNote")
		end
		if nameNoteToken == 0 then
			nameNote.Text = hint
			nameNote.TextColor3 = hintColor
		end
	end

	local function nameResult(text: string, colour: Color3)
		nameNoteToken += 1
		local mine = nameNoteToken
		nameNote.Text = text
		nameNote.TextColor3 = colour
		task.delay(4, function()
			if nameNoteToken == mine then
				nameNoteToken = 0
				updateName()
			end
		end)
	end

	function render()
		local owned, stored = pet()
		if not owned then
			return false
		end
		titleLabel.Text = Locale.PetName(owned.kind, owned.level, owned.name)
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
		local feed = feedCard(owned)
		if feed then
			feed.Parent = content
			table.insert(cards, feed)
		end
		-- P4: the trait cards for every player (Cuteness first); "no field job" only for players with the field
		local order = 10
		for _, id in PetConfig.Aptitudes do
			if PetConfig.Shown[id] and PetConfig.AptitudeLevel(stored, id) > 0 then
				local apt = aptitudeCard(order, owned, stored, id)
				apt.Parent = content
				table.insert(cards, apt)
				order += 1
			end
		end
		if fieldAccess and owned.tending == 0 and owned.guard == 0 then
			local none = line("NoJob", order, { TextColor3 = COLOR_DIM, Text = Locale.T("petDetail.noJob") })
			none.Parent = content
			table.insert(cards, none)
		end

		local busy = owned.penned ~= nil or owned.field ~= nil
		equipButton.Text = Locale.T(if owned.equipped then "petDetail.unequip" else "petDetail.equip")
		equipButton.BackgroundColor3 = if busy then COLOR_LOCKED elseif owned.equipped then COLOR_SELL_IDLE else COLOR_EQUIP
		sellButton.Text = Locale.T(if sellArmed then "pets.sellSure" else "pets.sell", { price = owned.sellValue })
		sellButton.BackgroundColor3 = if busy or owned.equipped then COLOR_LOCKED elseif sellArmed then COLOR_SELL else COLOR_SELL_IDLE
		updateName()
		return true
	end

	local api = {}

	function api.IsOpen(): boolean
		return currentUid ~= nil
	end

	-- A Frame lets clicks through to the buttons under it (and a button over them would show the hand cursor everywhere): while the
	-- page is open, the panel's own controls under it are hidden.
	local hidden: { GuiObject } = {}
	local function hideList()
		for _, child in panel:GetChildren() do
			if child ~= page and child:IsA("GuiObject") and child.Visible then
				child.Visible = false
				table.insert(hidden, child)
			end
		end
	end
	local function showList()
		for _, child in hidden do
			child.Visible = true
		end
		table.clear(hidden)
	end

	function api.Close()
		currentUid = nil
		sellArmed = false
		page.Visible = false
		showList()
		stopSpin()
	end

	function api.Open(uid: string)
		currentUid = uid
		sellArmed = false
		messageLabel.Text = ""
		portraitKey = nil
		nameNoteToken = 0
		feedToken += 1
		feedNote = nil
		nameBox.Text = PetClient.NameOf(uid) or ""
		if render() then
			content.CanvasPosition = Vector2.zero
			if not page.Visible then
				hideList()
			end
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

	-- at most NameMaxLength characters in the box (the server checks again)
	nameBox:GetPropertyChangedSignal("Text"):Connect(function()
		local text = nameBox.Text
		local length = utf8.len(text)
		if length and length > PetConfig.NameMaxLength then
			nameBox.Text = string.sub(text, 1, (utf8.offset(text, PetConfig.NameMaxLength + 1) :: number) - 1)
			return
		end
		if currentUid then
			updateName()
		end
	end)

	nameButton.Activated:Connect(function()
		local owned = pet()
		if not owned then
			return
		end
		local clean = PetConfig.CleanName(nameBox.Text)
		if clean == nil then
			nameResult(Locale.T("petDetail.reject.name", { max = PetConfig.NameMaxLength }), COLOR_ERROR)
			return
		end
		if clean == (owned.name or "") then
			return
		end
		local price = if clean ~= "" and owned.renamed then PetConfig.RenamePrice else 0
		if PetClient.Coins < price then
			nameResult(Locale.T("common.reject.coins"), COLOR_ERROR)
			return
		end
		nameResult(Locale.T("petDetail.name.checking"), COLOR_INFO)
		remotes.Rename:FireServer(owned.uid, clean)
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
		if currentUid and action == "Rename" then
			if ok and type(detail) == "table" and detail.uid == currentUid then
				nameBox.Text = detail.name or ""
				nameResult(if detail.name then Locale.T("petDetail.name.done", { name = detail.name }) else Locale.T("petDetail.name.removed"), COLOR_OK)
			elseif not ok then
				nameResult(Locale.T(RENAME_REJECT_KEYS[detail] or "common.reject.failed", { max = PetConfig.NameMaxLength }), COLOR_ERROR)
			end
			return
		end
		if currentUid and not ok and (action == "Equip" or action == "Unequip" or action == "SellPet") then
			message(Locale.T(REJECT_KEYS[detail] or "common.reject.failed"), COLOR_ERROR)
		end
	end)
	Locale.Changed:Connect(function()
		if currentUid then
			render()
		end
	end)

	if fieldAccess then
		task.spawn(function()
			local gardenRemotes = ReplicatedStorage:WaitForChild("GardenRemotes")
			feedEvent = gardenRemotes:WaitForChild("FeedCrop") :: RemoteEvent
			local gotState = false
			gardenRemotes:WaitForChild("State").OnClientEvent:Connect(function(state)
				gotState = true
				local items = type(state) == "table" and type(state.field) == "table" and state.field.items
				heldCrops = if type(items) == "table" then items else {}
				if currentUid then
					render()
				end
			end)
			gardenRemotes:WaitForChild("Result").OnClientEvent:Connect(function(action, ok, detail)
				if action ~= "FeedCrop" or not currentUid then
					return
				end
				if not ok then
					feedResult(Locale.T(FEED_REJECT_KEYS[detail] or "common.reject.failed"), COLOR_ERROR)
					return
				end
				if type(detail) ~= "table" or detail.uid ~= currentUid then
					return
				end
				local crop = CropConfig.ById[detail.crop]
				local leveled = nil -- P4: the last trait that gained a level
				for _, step in (if type(detail.trained) == "table" then detail.trained else {}) do
					if type(step) == "table" and (step.levels or 0) > 0 and PetConfig.Shown[step.id] then
						leveled = step
					end
				end
				local args = {
					icon = if crop then crop.icon else "",
					count = detail.used,
					xp = detail.xp,
					trait = if leveled then Locale.T("pet.apt." .. leveled.id) else "",
					level = if leveled then leveled.level else detail.level,
				}
				feedResult(Locale.T(if leveled then "petDetail.feed.doneLevel" else "petDetail.feed.done", args), COLOR_OK)
			end)
			-- the State sent at join may have arrived before this listener; a request at the same moment as another script's can be
			-- dropped by the garden remotes' rate limit, so ask once more if nothing came
			local requestState = gardenRemotes:WaitForChild("RequestState")
			requestState:FireServer()
			task.delay(2, function()
				if not gotState then
					requestState:FireServer()
				end
			end)
		end)
	end

	return api
end

return PetDetail

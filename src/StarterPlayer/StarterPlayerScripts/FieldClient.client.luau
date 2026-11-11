-- Field client (E1a2; U4): the field's toasts and join notices. The Garden panel it held is gone (U4): squares → the rings and the
-- square card (FieldHand, FieldRings), seeds and the market cart → the plaza's seed stall (SeedStallClient), seeds / crops held, Sell
-- and the crow forecast → the Barn panel (BarnClient), upgrades / tools → the Skills panel's Garden tab (GardenSkills), field pet
-- slots → the Pets panel.
--   * toasts for the answers of the field actions on GardenRemotes.Result (eggs and food share that remote: ignored here): plant,
--     harvest (size, record, Shears, Renown level-up), seeds / cart bought, sale, square bought, upgrades and tools, field pets;
--   * once per session the notices of State.field.notice (an old profile's pen conversion, what the pets harvested while away, what
--     the crows ate and which guards chased them off).
-- The GUI is built here (ScreenGui FieldGui with the toast only), stud-brick wood look (StudStyle).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

local CropConfig = require(ReplicatedStorage:WaitForChild("CropConfig"))
local PetConfig = require(ReplicatedStorage:WaitForChild("PetConfig"))
local StudStyle = require(ReplicatedStorage:WaitForChild("StudStyle"))
local Locale = require(ReplicatedStorage:WaitForChild("Locale"))
local PetClient = require(script.Parent:WaitForChild("PetClient"))

local remotes = ReplicatedStorage:WaitForChild("GardenRemotes")
local requestStateEvent = remotes:WaitForChild("RequestState")

local NOTICE_SECONDS = 8
local COLOR_PANEL = StudStyle.Colors.Wood
local COLOR_ERROR = StudStyle.Text.Error
local COLOR_OK = StudStyle.Text.Ok

-- the reasons GardenField answers with (texts: field.reason.<reason>)
local REJECT_KEYS = { -- coins, stale, loading, noplot: Locale.Reject's common.reject.*
	obby = "field.reason.obby",
	far = "field.reason.far",
	square = "field.reason.square",
	occupied = "field.reason.occupied",
	renown = "field.reason.renown",
	seeds = "field.reason.seeds",
	empty = "field.reason.empty",
	notripe = "field.reason.notripe",
	barn = "field.reason.barn",
	items = "field.reason.items",
	maxed = "field.reason.maxed",
	open = "field.reason.open",
	soldout = "field.reason.soldOut",
}
-- the field pet actions' own texts for some reasons (E1b)
local PET_REJECT_KEYS = setmetatable({
	occupied = "field.reason.petOccupied",
	equipped = "field.reason.equipped",
	aptitude = "field.reason.aptitude",
	slots = "field.reason.slots",
	maxed = "field.reason.slotsMaxed",
}, { __index = REJECT_KEYS })
local UPGRADE_REJECT_KEYS = setmetatable({ maxed = "field.reason.upgradeMaxed" }, { __index = REJECT_KEYS })
local STALL_REJECT_KEYS = setmetatable({ far = "seedStall.reason.far" }, { __index = REJECT_KEYS })
local PET_ACTIONS = { PlacePet = true, LiftPet = true, BuyPetSlot = true }
-- the field upgrades' texts (E1c1): name, effect now → next level, effect at the top level
local UPGRADE_KEYS = {
	Growth = { name = "field.upgrade.growth", effect = "field.upgrade.growth.effect", max = "field.upgrade.growth.max" },
	Barn = { name = "field.upgrade.barn", effect = "field.upgrade.barn.effect", max = "field.upgrade.barn.max" },
}
-- the garden tools' texts (E1c3), the same shape; every effect is shown in %
local TOOL_KEYS = {
	Sorter = { name = "field.tool.sorter", effect = "field.tool.sorter.effect", max = "field.tool.sorter.max" },
	Cloches = { name = "field.tool.cloches", effect = "field.tool.cloches.effect", max = "field.tool.cloches.max" },
	Shears = { name = "field.tool.shears", effect = "field.tool.shears.effect", max = "field.tool.shears.max" },
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

local function cropOf(id: string)
	return CropConfig.ById[id]
end

-- "7.4" (Czech "7,4"): the weight of a crop of size `factor`, to 0.1 kg (E1c2).
local function kgText(crop, factor: number): string
	return Locale.Decimal(string.format("%.1f", crop.kg * factor))
end

local fieldState = nil -- GardenRemotes.State.field (only its notice is read here)
local noticesShown = {} -- [kind] = true once this session's notice was shown
local toastToken = 0

local toast = create("TextLabel", {
	Name = "Toast",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 108),
	Size = UDim2.new(1, -16, 0, 34),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 1,
	Font = StudStyle.Font,
	TextColor3 = Color3.new(1, 1, 1),
	TextSize = 18,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Center,
	Visible = false,
})
create("UISizeConstraint", { MaxSize = Vector2.new(360, 200), Parent = toast })
StudStyle.Plate(toast, COLOR_PANEL, 4)
StudStyle.Title(toast, COLOR_PANEL)

local screenGui = create("ScreenGui", {
	Name = "FieldGui",
	ResetOnSpawn = false,
	DisplayOrder = 6,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	AutoLocalize = false, -- translated by Locale (L2)
}, { toast })

-- Toast -------------------------------------------------------------------------------------------------------------------

local function showToast(text: string, color: Color3?, seconds: number?)
	toastToken += 1
	local mine = toastToken
	toast.Text = text
	toast.TextColor3 = color or Color3.new(1, 1, 1)
	toast.Visible = true
	task.delay(seconds or 3, function()
		if toastToken == mine then
			toast.Visible = false
		end
	end)
end


-- "Cat Lv 4" for a uid in the pet state ("" when unknown)
local function petNameOf(uid: string?): string
	local pet = uid and PetClient.State and PetClient.State.pets[uid]
	return if pet then Locale.PetName(pet.Kind, PetConfig.PetLevel(pet), PetClient.NameOf(uid)) else ""
end

-- Once per session: an old profile's pen conversion (FA), what the pets harvested while the player was away (State.field.notice, E1b) and the
-- crows' raid (E4b: what they ate, which guards chased them off).
local function showNotices(field)
	local notice = field and field.notice
	if type(notice) ~= "table" then
		return
	end
	local lines = {}
	if notice.converted and not noticesShown.converted then
		noticesShown.converted = true
		local c = notice.converted
		table.insert(lines, Locale.T("field.notice.converted", { count = c.slots }))
		if c.refund > 0 then
			table.insert(lines, Locale.T("field.notice.refund", { count = c.refund }))
		end
		if c.returned > 0 then
			table.insert(lines, Locale.T("field.notice.returned", { count = c.returned }))
		end
	end
	if notice.tended and not noticesShown.tended then
		noticesShown.tended = true
		local items = {}
		for _, crop in CropConfig.Crops do
			local n = notice.tended[crop.id]
			if n then
				table.insert(items, Locale.T("field.notice.item", { count = n, crop = Locale.CropName(crop) }))
			end
		end
		table.insert(lines, Locale.T("field.notice.tended", { items = table.concat(items, ", ") }))
	end
	local crows = notice.crows -- E4b: { ate = { [crop] = n }, chased = { [uid] = n } }
	local chased = type(crows) == "table" and type(crows.chased) == "table" and crows.chased or {}
	-- the guards' names need the pet state: wait for it (PetClient.Changed calls this again)
	if type(crows) == "table" and not noticesShown.crows and (next(chased) == nil or PetClient.State ~= nil) then
		noticesShown.crows = true
		local items = {}
		for _, crop in CropConfig.Crops do
			local n = type(crows.ate) == "table" and crows.ate[crop.id]
			if n then
				table.insert(items, Locale.T("field.notice.item", { count = n, crop = Locale.CropName(crop) }))
			end
		end
		if #items > 0 then
			table.insert(lines, Locale.T("field.notice.crowsAte", { items = table.concat(items, ", ") }))
		end
		for uid, n in chased do
			table.insert(lines, Locale.T("field.notice.chased", { pet = petNameOf(tostring(uid)), count = n }))
		end
	end
	if #lines > 0 then
		showToast(table.concat(lines, "\n"), COLOR_OK, NOTICE_SECONDS)
	end
end

remotes:WaitForChild("State").OnClientEvent:Connect(function(state)
	fieldState = if type(state) == "table" then state.field else nil
	showNotices(fieldState)
end)

PetClient.Changed:Connect(function()
	showNotices(fieldState) -- a crow notice waits for the guards' names (E4b)
end)

-- Answers of the field pet actions (E1b): toasts.
local function petResult(action: string, ok: boolean, detail)
	if not ok then
		showToast(Locale.Reject(detail, PET_REJECT_KEYS), COLOR_ERROR)
		return
	end
	if action == "PlacePet" then
		local name = petNameOf(detail.uid)
		showToast(Locale.T(if detail.moved then "field.toast.petMoved" else "field.toast.petPlaced", { pet = name, n = detail.square }), COLOR_OK)
	elseif action == "LiftPet" then
		showToast(Locale.T("field.toast.petLifted", { pet = petNameOf(detail.uid) }), COLOR_OK)
	else
		showToast(Locale.T("field.toast.slot", { n = detail }), COLOR_OK)
	end
end

remotes:WaitForChild("Result").OnClientEvent:Connect(function(action, ok, detail)
	if PET_ACTIONS[action] then
		return petResult(action, ok, detail)
	end
	if action == "BuyUpgrade" or action == "BuyTool" then
		local names = if action == "BuyTool" then TOOL_KEYS else UPGRADE_KEYS
		if not ok then
			showToast(Locale.Reject(detail, UPGRADE_REJECT_KEYS), COLOR_ERROR)
		elseif type(detail) == "table" and names[detail.id] then
			showToast(Locale.T("field.toast.upgrade", { name = Locale.T(names[detail.id].name), level = detail.level }), COLOR_OK)
		end
		return
	end
	if
		action ~= "Plant"
		and action ~= "Harvest"
		and action ~= "BuySeeds"
		and action ~= "BuyCart"
		and action ~= "Sell"
		and action ~= "BuySquare"
	then
		return -- incubators and the food stand answer on the same remote
	end
	if not ok then
		showToast(Locale.Reject(detail, if action == "BuySeeds" or action == "BuyCart" then STALL_REJECT_KEYS else REJECT_KEYS), COLOR_ERROR)
		return
	end
	local crop = type(detail) == "table" and detail.crop and cropOf(detail.crop)
	local name = if crop then Locale.CropName(crop) else ""
	if action == "Harvest" then
		local size = if type(detail.size) == "number" then detail.size else 1
		local lines = { Locale.T("field.toast.harvestSize", { crop = name, kg = kgText(crop, size) }) }
		if detail.extra then
			table.insert(lines, Locale.T("field.toast.shears"))
		end
		local tag = CropConfig.SizeLabel(size)
		local extra = {}
		if tag then
			table.insert(extra, Locale.T(if tag == "Giant" then "field.size.giant" else "field.size.big"))
		end
		if detail.best then
			table.insert(extra, Locale.T("field.size.record"))
		end
		if #extra > 0 then
			table.insert(lines, table.concat(extra, " "))
		end
		if detail.levelUp then
			table.insert(lines, Locale.T("field.toast.renownUp", { level = detail.level }))
		end
		showToast(table.concat(lines, "\n"), COLOR_OK)
	elseif action == "Sell" then
		showToast(Locale.T("field.toast.sell", { count = detail.paid }), COLOR_OK)
	elseif action == "BuySeeds" or action == "BuyCart" then
		showToast(Locale.T("field.toast.seeds", { crop = name, count = detail.count }), COLOR_OK)
	elseif action == "BuySquare" then
		showToast(Locale.T("field.toast.square", { n = detail.square }), COLOR_OK)
	else
		showToast(Locale.T("field.toast.plant", { crop = name }), COLOR_OK)
	end
end)

requestStateEvent:FireServer()
screenGui.Parent = player:WaitForChild("PlayerGui")

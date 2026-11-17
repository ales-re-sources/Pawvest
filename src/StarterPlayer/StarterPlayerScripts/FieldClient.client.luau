-- Field client (E1a2; U4): the field's toasts and join notices. The Garden panel it held is gone (U4): squares → the rings and the
-- square card (FieldHand, FieldRings), seeds and the market cart → the plaza's seed stall (SeedStallClient), seeds / crops held, Sell
-- and the crow forecast → the Barn panel (BarnClient), upgrades / tools → the Skills panel's Garden tab (GardenSkills), field pet
-- slots → the Pets panel.
--   * toasts for the answers of the field actions on GardenRemotes.Result (eggs and food share that remote: ignored here): plant,
--     harvest (size, record, Shears, mastery level-up, crop unlocked), seeds / cart bought, sale, square bought, quest pieces, upgrades and
--     tools, crop upgrade points (EV3c), field pets;
--   * once per session the notices of State.field.notice (an old profile's pen conversion, what the pets harvested while away, what
--     the crows ate and which guards chased them off).
-- The GUI is built here (ScreenGui FieldGui with the toast only), stud-brick wood look (StudStyle).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

local CropConfig = require(ReplicatedStorage:WaitForChild("CropConfig"))
local PetConfig = require(ReplicatedStorage:WaitForChild("PetConfig"))
local StudStyle = require(ReplicatedStorage:WaitForChild("StudStyle"))
local UiKit = require(ReplicatedStorage:WaitForChild("UiKit"))
local Locale = require(ReplicatedStorage:WaitForChild("Locale"))
local PetClient = require(script.Parent:WaitForChild("PetClient"))
local GardenUi = require(script.Parent:WaitForChild("GardenUi"))

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
	locked = "field.reason.locked",
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
-- EV3b: handing crops in toward a milestone quest
local QUEST_REJECT_KEYS = setmetatable({
	none = "field.reason.questNone",
	crop = "field.reason.questCrop",
	crops = "field.reason.items",
}, { __index = REJECT_KEYS })
-- EV3c: spending a crop's upgrade point
local POINT_REJECT_KEYS = setmetatable({
	points = "field.reason.points",
	maxed = "field.reason.pointTaken",
	crop = "field.reason.pointCrop",
}, { __index = REJECT_KEYS })
-- the upgrade lines' names (EV3c)
local POINT_LINE_KEYS = { Value = "field.point.value", Size = "field.point.size", Speed = "field.point.speed" }
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

local create = UiKit.Create

local fieldState = nil -- GardenRemotes.State.field (only its notice is read here)
local noticesShown = {} -- [kind] = true once this session's notice was shown

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

local showToast = UiKit.Toast(toast, 3)


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
		showToast(Locale.T(if detail.moved then "field.toast.petMoved" else "field.toast.petPlaced", { pet = name }), COLOR_OK)
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
		and action ~= "Quest"
		and action ~= "CropPoint"
	then
		return -- incubators and the food stand answer on the same remote
	end
	if not ok then
		local keys = if action == "BuySeeds" or action == "BuyCart" then STALL_REJECT_KEYS
			elseif action == "Quest" then QUEST_REJECT_KEYS
			elseif action == "CropPoint" then POINT_REJECT_KEYS
			else REJECT_KEYS
		showToast(Locale.Reject(detail, keys), COLOR_ERROR)
		return
	end
	local crop = type(detail) == "table" and detail.crop and CropConfig.ById[detail.crop]
	local name = if crop then Locale.CropName(crop) else ""
	if action == "Harvest" then
		local size = if type(detail.size) == "number" then detail.size else 1
		local lines = { Locale.T("field.toast.harvestSize", { crop = name, kg = GardenUi.KgText(crop, size) }) }
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
		local mastery = type(detail.mastery) == "table" and detail.mastery
		if detail.levelUp and mastery then -- EV3b: "Garlic ★2!"
			table.insert(lines, Locale.T("field.toast.masteryUp", { crop = name, level = mastery.level }))
			table.insert(lines, Locale.T("field.toast.pointFree")) -- EV3c: every level gives a point
		end
		local opened = type(detail.unlocked) == "string" and CropConfig.ById[detail.unlocked]
		if opened then
			table.insert(lines, Locale.T("field.toast.unlocked", { crop = GardenUi.CropTitle(opened) }))
		end
		showToast(table.concat(lines, "\n"), COLOR_OK)
	elseif action == "Quest" then -- EV3b: a quest piece handed in; the last one opens the crop and gives its seeds
		local lines = { Locale.T("field.toast.questPiece", { crop = name, count = detail.count }) }
		local opened = type(detail.unlocked) == "string" and CropConfig.ById[detail.unlocked]
		if opened then
			table.insert(lines, Locale.T("field.toast.unlocked", { crop = GardenUi.CropTitle(opened) }))
			table.insert(lines, Locale.T("field.toast.seeds", { crop = Locale.CropName(opened), count = detail.seeds or 0 }))
		end
		showToast(table.concat(lines, "\n"), COLOR_OK)
	elseif action == "CropPoint" then -- EV3c: "Upgraded: Cucumber · 💰 Price"
		local line = POINT_LINE_KEYS[detail.line]
		showToast(Locale.T("field.toast.point", { crop = name, line = if line then Locale.T(line) else "" }), COLOR_OK)
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

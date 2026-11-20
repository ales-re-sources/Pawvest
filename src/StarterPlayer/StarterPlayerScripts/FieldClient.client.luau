-- Field client (E1a2; U4): the field's toasts and join notices. The Garden panel it held is gone (U4): squares → the rings and the
-- square card (FieldHand, FieldRings), seeds and the market cart → the plaza's seed stall (SeedStallClient), seeds / crops held, Sell
-- and the crow forecast → the Barn panel (BarnClient), upgrades / tools → the Skills panel's Garden tab (GardenSkills), field pet
-- slots → the Pets panel.
--   * toasts for the answers of the field actions on GardenRemotes.Result (eggs and food share that remote: ignored here): plant,
--     harvest (size, record, Shears, mastery level-up, crop unlocked), seeds / cart bought, sale, square bought, quest pieces, upgrades and
--     tools, crop upgrade points (EV3c), field pets; a finished request (E5a, "Request": joins the harvest toast that finished it);
--   * once per session the notices of State.field.notice (an old profile's pen conversion, what the pets harvested while away, what
--     the crows ate and which guards chased them off);
--   * after an absence of 30 min or more (notice.away, E5b) the "While you were away" ledger instead of the harvest / crow toasts.
-- The GUI is built here (ScreenGui FieldGui with the toast; the ledger is a HudPopup), stud-brick wood look (StudStyle).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

local CropConfig = require(ReplicatedStorage:WaitForChild("CropConfig"))
local PetConfig = require(ReplicatedStorage:WaitForChild("PetConfig"))
local GardenConfig = require(ReplicatedStorage:WaitForChild("GardenConfig"))
local StudStyle = require(ReplicatedStorage:WaitForChild("StudStyle"))
local UiKit = require(ReplicatedStorage:WaitForChild("UiKit"))
local Locale = require(ReplicatedStorage:WaitForChild("Locale"))
local PetClient = require(script.Parent:WaitForChild("PetClient"))
local GardenUi = require(script.Parent:WaitForChild("GardenUi"))
local GardenView = require(script.Parent:WaitForChild("GardenView"))
local HudPopup = require(script.Parent:WaitForChild("HudPopup"))
local Hints = require(script.Parent:WaitForChild("Hints"))

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
local STALL_REJECT_KEYS = setmetatable({
	far = "seedStall.reason.far",
	stock = "seedStall.reason.stock", -- ST: a rotating crop not in this restock
	soldOut = "seedStall.reason.soldOut", -- ST: this restock's seeds of it are bought
}, { __index = REJECT_KEYS })
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
local LIKE_REJECT_KEYS = { -- SH: GardenLikes' refusals (loading: common.reject.loading)
	self = "garden.like.reason.self",
	free = "garden.like.reason.free",
	liked = "garden.like.reason.liked",
	far = "garden.like.reason.far",
}
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

local rawToast = UiKit.Toast(toast, 3)
local REQUEST_WAIT = 0.3 -- a finished request (E5a) is answered just before the harvest that finished it: they share one toast
local pendingRequest: string? = nil

-- Shows `text`; a finished request's lines that arrived just before join a success toast.
local function showToast(text: string, color: Color3?, seconds: number?)
	if pendingRequest and color == COLOR_OK then
		text ..= "\n" .. pendingRequest
		pendingRequest = nil
		seconds = math.max(seconds or 3, 4)
	end
	rawToast(text, color, seconds)
end

-- E5a: "📜 Request done! +1 200 Coins" and the drop; shown with the next success toast within REQUEST_WAIT, else alone.
local function requestToast(detail)
	local lines = { Locale.T("field.toast.request", { count = tonumber(detail.coins) or 0 }) }
	local drop = type(detail.drop) == "table" and detail.drop
	local seed = drop and type(drop.seed) == "string" and CropConfig.ById[drop.seed]
	local egg = drop and type(drop.egg) == "string" and PetConfig.Eggs[drop.egg]
	if seed then
		table.insert(lines, Locale.T("field.toast.requestSeed", { crop = GardenUi.CropTitle(seed) }))
	elseif egg then
		table.insert(lines, Locale.T("field.toast.requestEgg", { egg = Locale.EggName(egg) }))
	end
	local text = table.concat(lines, "\n")
	pendingRequest = if pendingRequest then pendingRequest .. "\n" .. text else text
	local mine = pendingRequest
	task.delay(REQUEST_WAIT, function()
		if pendingRequest == mine then
			pendingRequest = nil
			rawToast(mine, COLOR_OK, 4)
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
	local ledger = notice.away ~= nil -- E5b: the ledger shows the harvests and the crows
	if notice.tended and not ledger and not noticesShown.tended then
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
	if type(crows) == "table" and not ledger and not noticesShown.crows and (next(chased) == nil or PetClient.State ~= nil) then
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

-- Ledger (E5b, D4) ----------------------------------------------------------------------------------------------------------
-- Once per session after an absence of 30 min or more (notice.away, set by GardenField): "While you were away" with the lines
-- that apply, in this order: what the pets harvested (≤ LEDGER_CROPS crops, then "+ n more") and the biggest of them, the crows,
-- ripe squares, ready eggs, ribbons won, new requests. It waits for the join's ribbon check (at most RIBBON_WAIT s), the guards'
-- names (the pet state) and the end of a stage run; it closes with its button or a tap outside it. Information only.
local LEDGER_ORDER = { "tended", "crows", "ripe", "eggs", "ribbons", "requests" }
local LEDGER_ICONS = { tended = "🧺", crows = "🐦", ripe = "🌱", eggs = "🥚", ribbons = "🎀", requests = "📜" }
local LEDGER_CROPS = 3
local RIBBON_WAIT = 10 -- seconds the ledger waits for the join's ribbon check
local LEDGER_CLOSE = 600 -- seconds: closes by itself only if left alone this long
local COLOR_LEDGER = Color3.fromRGB(255, 214, 102)
local COLOR_LEDGER_BUTTON = Color3.fromRGB(70, 170, 80)

local ledgerPopup = HudPopup.new("AwayLedger", {
	displayOrder = 8, -- above the field toast and the HUD popups
	width = 340,
	position = UDim2.fromScale(0.5, 0.5),
	anchor = Vector2.new(0.5, 0.5),
	padding = { top = 14, bottom = 14 },
	gap = 8,
	stroke = { color = COLOR_LEDGER, thickness = 3 },
	pop = true,
})
ledgerPopup.gui.IgnoreGuiInset = true
create("TextButton", { -- a tap outside the panel closes it
	Name = "Shade",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.new(0, 0, 0),
	BackgroundTransparency = 0.55,
	AutoButtonColor = false,
	Text = "",
	ZIndex = 0,
	Parent = ledgerPopup.gui,
}).Activated:Connect(ledgerPopup.Hide)
local ledgerTitle = ledgerPopup.Line("Title", 1, 24, { TextColor3 = COLOR_LEDGER, RichText = false })
local ledgerAway = ledgerPopup.Line("Away", 2, 15, { TextColor3 = Color3.fromRGB(200, 200, 200), RichText = false })
local ledgerRows = {}
for i, kind in LEDGER_ORDER do
	ledgerRows[kind] = ledgerPopup.Line("Row_" .. kind, 2 + i, 17, { TextXAlignment = Enum.TextXAlignment.Left, RichText = false })
end
local ledgerButton = ledgerPopup.Button("Ok", 10, COLOR_LEDGER_BUTTON, 40, 18)
ledgerButton.Activated:Connect(ledgerPopup.Hide)

-- "5× Potato, 2× Corn + 2 more": crops of `counts` ({ [cropId] = n }), most first (ties in crop order), at most `limit`.
local function cropList(counts, limit: number?): string
	local list = {}
	for index, crop in CropConfig.Crops do
		local n = type(counts) == "table" and tonumber(counts[crop.id])
		if n and n > 0 then
			table.insert(list, { crop = crop, n = n, index = index })
		end
	end
	table.sort(list, function(a, b)
		return if a.n ~= b.n then a.n > b.n else a.index < b.index
	end)
	local items = {}
	for i, entry in list do
		if limit and i > limit then
			break
		end
		table.insert(items, Locale.T("field.notice.item", { count = entry.n, crop = Locale.CropName(entry.crop) }))
	end
	local text = table.concat(items, ", ")
	if limit and #list > limit then
		text ..= " " .. Locale.T("field.ledger.more", { count = #list - limit })
	end
	return text
end

-- "7 h 20 min", "2 d 3 h"
local function awayText(seconds: number): string
	seconds = math.max(0, math.floor(seconds))
	if seconds >= 86400 then
		return Locale.T("common.duration.dh", { d = seconds // 86400, h = (seconds % 86400) // 3600 })
	end
	return Locale.Duration(seconds)
end

-- [kind] = the ledger's line for `notice` (nil when it has nothing to say)
local function ledgerTexts(notice)
	local texts = {}
	if type(notice.tended) == "table" and next(notice.tended) then
		local parts = { Locale.T("field.ledger.tended", { items = cropList(notice.tended, LEDGER_CROPS) }) }
		local big = type(notice.biggest) == "table" and notice.biggest
		local crop = big and CropConfig.ById[big.crop]
		if crop and type(big.factor) == "number" then
			local tag = CropConfig.SizeLabel(big.factor, GardenUi.PointsOf(GardenView.OwnField(), crop))
			local key = if tag == "Giant" then "field.ledger.biggestGiant" elseif tag then "field.ledger.biggestBig" else "field.ledger.biggest"
			table.insert(parts, Locale.T(key, { crop = GardenUi.CropTitle(crop), kg = GardenUi.KgText(crop, big.factor) }))
		end
		texts.tended = table.concat(parts, " ")
	end
	local crows = type(notice.crows) == "table" and notice.crows
	if crows then
		local parts = {}
		local ate = cropList(crows.ate, LEDGER_CROPS)
		if ate ~= "" then
			table.insert(parts, Locale.T("field.ledger.crowsAte", { items = ate }))
		end
		for uid, n in (if type(crows.chased) == "table" then crows.chased else {}) do
			table.insert(parts, Locale.T("field.notice.chased", { pet = petNameOf(tostring(uid)), count = n }))
		end
		texts.crows = if #parts > 0 then table.concat(parts, " ") else nil
	end
	for _, kind in { "ripe", "eggs", "requests" } do
		local n = tonumber(notice[kind])
		if n and n > 0 then
			texts[kind] = Locale.T("field.ledger." .. kind, { count = n })
		end
	end
	if type(notice.ribbons) == "table" then
		local items = {}
		for _, crop in CropConfig.Crops do
			local n = tonumber(notice.ribbons[crop.id])
			if n and n > 1 then
				table.insert(items, Locale.T("field.notice.item", { count = n, crop = Locale.CropName(crop) }))
			elseif n == 1 then
				table.insert(items, Locale.CropName(crop))
			end
		end
		if #items > 0 then
			texts.ribbons = Locale.T("field.ledger.ribbons", { items = table.concat(items, ", ") })
		end
	end
	return texts
end

local ledgerDone = false -- shown (or found empty) this session
local ledgerSince = nil -- os.clock() the ledger notice first arrived (the ribbon wait)
local ledgerRetry = false

local function tryLedger()
	local notice = fieldState and fieldState.notice
	if ledgerDone or type(notice) ~= "table" or type(notice.away) ~= "number" then
		return
	end
	ledgerSince = ledgerSince or os.clock()
	local crows = type(notice.crows) == "table" and notice.crows
	local chased = crows and type(crows.chased) == "table" and next(crows.chased) ~= nil
	if chased and PetClient.State == nil then
		return -- the guards' names: PetClient.Changed calls again
	end
	if Hints.Running or (notice.ribbonsReady == false and os.clock() - ledgerSince < RIBBON_WAIT) then
		if not ledgerRetry then -- a stage run ends / the ribbon check answers: look again shortly
			ledgerRetry = true
			task.delay(0.5, function()
				ledgerRetry = false
				tryLedger()
			end)
		end
		return
	end
	ledgerDone = true
	ledgerPopup.Show(function()
		local texts = ledgerTexts(notice)
		local any = false
		for _, kind in LEDGER_ORDER do
			local label = ledgerRows[kind]
			label.Visible = texts[kind] ~= nil
			label.Text = if texts[kind] then LEDGER_ICONS[kind] .. "  " .. texts[kind] else ""
			any = any or texts[kind] ~= nil
		end
		if not any then
			return false
		end
		ledgerTitle.Text = Locale.T("field.ledger.title")
		ledgerAway.Text = Locale.T("field.ledger.away", { time = awayText(notice.away) })
		ledgerButton.Text = Locale.T("field.ledger.ok")
		return true
	end, LEDGER_CLOSE)
end

-- ST: once per restock block, while the player is in the garden, "New seeds at the stall" when a rotating crop of theirs is in stock
-- (not on join: the first State only sets the block).
local stallBlock = nil
-- Whether the character stands on the garden island: within the outer plot ring and two plot depths (a field lies behind its plot) of
-- the garden centre, measured flat.
local function inGarden(): boolean
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not (root and root:IsA("BasePart")) then
		return false
	end
	local offset = root.Position - GardenConfig.PlotCentre
	local reach = GardenConfig.PlotRings[#GardenConfig.PlotRings].radius + 2 * GardenConfig.PlotSize
	return Vector3.new(offset.X, 0, offset.Z).Magnitude <= reach
end

local function stallRestock(field)
	local stall = field and field.stall
	if type(stall) ~= "table" or stall.block == stallBlock then
		return
	end
	local first = stallBlock == nil
	stallBlock = stall.block
	local any = false
	for _, left in stall.left do
		any = any or left > 0
	end
	if not first and any and inGarden() then
		showToast(Locale.T("seedStall.toast.restock"), COLOR_OK)
	end
end

remotes:WaitForChild("State").OnClientEvent:Connect(function(state)
	fieldState = if type(state) == "table" then state.field else nil
	showNotices(fieldState)
	tryLedger()
	stallRestock(fieldState)
end)

PetClient.Changed:Connect(function()
	showNotices(fieldState) -- a crow notice waits for the guards' names (E4b)
	tryLedger()
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
	if action == "Request" then -- E5a: a request finished
		if ok and type(detail) == "table" then
			requestToast(detail)
		end
		return
	end
	if action == "Like" then -- SH
		if not ok then
			showToast(Locale.Reject(detail, LIKE_REJECT_KEYS), COLOR_ERROR)
		elseif type(detail) == "table" and type(detail.name) == "string" then
			showToast(Locale.T("garden.like.sent", { name = detail.name }), COLOR_OK)
		end
		return
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
		local field = GardenView.OwnField()
		local tag = CropConfig.SizeLabel(size, field and GardenUi.PointsOf(field, crop))
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
	elseif action == "CropPoint" then -- EV3c: "Upgraded: Cucumber · 💰 Price ●●○"
		local line = POINT_LINE_KEYS[detail.line]
		local have = math.clamp(tonumber(detail.points) or 0, 0, CropConfig.Mastery.Points.PerLine)
		local level = string.rep("●", have) .. string.rep("○", CropConfig.Mastery.Points.PerLine - have)
		showToast(Locale.T("field.toast.point", { crop = name, line = if line then Locale.T(line) .. " " .. level else "" }), COLOR_OK)
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

-- SH: another player liked this player's plot (GardenLikes)
remotes:WaitForChild("Liked").OnClientEvent:Connect(function(name)
	if type(name) == "string" then
		showToast(Locale.T("garden.like.got", { name = name }), COLOR_OK)
	end
end)

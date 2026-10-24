-- StageMastery: "done here" state of a stage for one player (docs/GDD.md §3 "Mastered stage").
-- A stage is mastered when its top medal (Gold) is earned and every challenge coin of the stage is found; a stage without
-- coins needs only the medal. Shared by the door face (HubPortalMedals: ticks + seal) and the gate decor (GateMastery).
-- Everything is read from the player attributes the server already replicates (Medal_<folder>, CollectedCoins).

local StageConfig = require(script.Parent.StageConfig)
local ChallengeCoinConfig = require(script.Parent.ChallengeCoinConfig)

local StageMastery = {}

StageMastery.Gold = Color3.fromRGB(255, 213, 74)
StageMastery.Ink = Color3.fromRGB(58, 42, 6)
StageMastery.TickGreen = Color3.fromRGB(110, 220, 120)

-- A check mark drawn from two rounded bars inside a square Frame (size it with Size / SizeConstraint). The ✔ glyph is no
-- option: Roblox draws it from a fallback font that ignores the text colour.
function StageMastery.NewCheck(color: Color3, outline: Color3?): Frame
	local box = Instance.new("Frame")
	box.Name = "Check"
	box.BackgroundTransparency = 1
	local function bar(centerX: number, centerY: number, length: number, rotation: number)
		local part = Instance.new("Frame")
		part.AnchorPoint = Vector2.new(0.5, 0.5)
		part.Position = UDim2.fromScale(centerX, centerY)
		part.Size = UDim2.fromScale(length, 0.2)
		part.Rotation = rotation
		part.BackgroundColor3 = color
		part.BorderSizePixel = 0
		part.Parent = box
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.5, 0)
		corner.Parent = part
		if outline then
			local stroke = Instance.new("UIStroke")
			stroke.Color = outline
			stroke.Thickness = 2
			stroke.Parent = part
		end
	end
	bar(0.25, 0.65, 0.42, 45)
	bar(0.62, 0.52, 0.78, -45)
	return box
end

-- A green check drawn right after the text of `line`, shown once its goal is done; it follows the scaled text width.
-- TextBounds is computed lazily and fires no change signal for a GUI that was never on screen, so it is polled (a tick with
-- no text size yet stays hidden: its outline would show as a dot). Returns the setter of the goal state. Client only.
function StageMastery.AddTick(line: TextLabel): (boolean) -> ()
	local tick = StageMastery.NewCheck(StageMastery.TickGreen, StageMastery.Ink)
	tick.Name = "Tick"
	tick.AnchorPoint = Vector2.new(0, 0.5)
	tick.Visible = false
	tick.Parent = line
	local done = false
	local function place()
		local bounds = line.TextBounds
		tick.Size = UDim2.fromOffset(bounds.Y, bounds.Y)
		tick.Position = UDim2.new(0.5, bounds.X / 2 + bounds.Y * 0.25, 0.5, 0)
		tick.Visible = done and bounds.Y > 0
	end
	line:GetPropertyChangedSignal("TextBounds"):Connect(place)
	task.spawn(function()
		while line.Parent do
			place()
			task.wait(0.5)
		end
	end)
	return function(value: boolean)
		done = value
		place()
	end
end

-- The start gate model of a stage (Sign, TopBeam, pillars): `Gate` of a world stage, `LandingPad.StartGate` of the Tutorial.
-- Waits for the scene (30 s); nil when the stage has none.
function StageMastery.WaitGate(stage): Model?
	local folder = StageConfig.StageFolder(stage)
	if StageConfig.Worlds[stage.world] then
		return folder:WaitForChild("Gate", 30)
	end
	local pad = folder:WaitForChild("LandingPad", 30)
	return pad and pad:WaitForChild("StartGate", 30)
end

-- { gold = top medal earned, coins = every coin found (true when the stage has none), mastered = both }.
function StageMastery.Goals(stage, player: Player)
	local gold = (player:GetAttribute(StageConfig.MedalAttribute(stage)) or 0) >= #StageConfig.Medals
	local collected = ChallengeCoinConfig.Decode(player:GetAttribute(ChallengeCoinConfig.CollectedAttribute))
	local found, total = ChallengeCoinConfig.Found(stage.key, collected)
	local coins = found >= total
	return { gold = gold, coins = coins, mastered = gold and coins }
end

-- Goals of a whole world (the hub world gates): every built stage Gold, every coin of its stages found. `complete` is false
-- while stages of the world are not built yet (StageConfig.Worlds[..].stageCount) or the world is marked `soon`: nothing is
-- done then. { gold, coins, found, total, mastered }.
function StageMastery.WorldGoals(worldIndex: number, player: Player)
	local world = StageConfig.Worlds[worldIndex]
	local count, golds = 0, 0
	local found, total = 0, 0
	local collected = ChallengeCoinConfig.Decode(player:GetAttribute(ChallengeCoinConfig.CollectedAttribute))
	for _, stage in StageConfig.Stages do
		if stage.world == worldIndex then
			count += 1
			if (player:GetAttribute(StageConfig.MedalAttribute(stage)) or 0) >= #StageConfig.Medals then
				golds += 1
			end
			local f, t = ChallengeCoinConfig.Found(stage.key, collected)
			found += f
			total += t
		end
	end
	local complete = count > 0 and count >= (world and world.stageCount or 0) and not (world and world.soon)
	local gold = complete and golds == count
	local coins = complete and total > 0 and found >= total
	return { gold = gold, coins = coins, found = found, total = total, mastered = gold and (total == 0 or coins) }
end

-- Fires `callback()` now and whenever a medal of the world or the collected coins change.
function StageMastery.WatchWorld(worldIndex: number, player: Player, callback: () -> ())
	for _, stage in StageConfig.Stages do
		if stage.world == worldIndex then
			player:GetAttributeChangedSignal(StageConfig.MedalAttribute(stage)):Connect(callback)
		end
	end
	player:GetAttributeChangedSignal(ChallengeCoinConfig.CollectedAttribute):Connect(callback)
	callback()
end

-- Fires `callback()` now and whenever the medal or the collected coins of the player change.
function StageMastery.Watch(stage, player: Player, callback: () -> ())
	player:GetAttributeChangedSignal(StageConfig.MedalAttribute(stage)):Connect(callback)
	player:GetAttributeChangedSignal(ChallengeCoinConfig.CollectedAttribute):Connect(callback)
	callback()
end

return StageMastery

-- HatchReveal (docs/GDD.md §7.6 → hatchery): the hatch animation and the summary of the new pet, drawn over the hatchery panel's
-- content. Display only: everything comes from the Hatch answer (egg, uid, kind, rarity, equipped, traits) and PetClient.State.
--   new(parent, opts)   builds the page (a Frame "Reveal", hidden) in `parent` (the panel). opts: onDone(), onViewPet(uid).
--                       Returns { frame, Show(detail), Hide(), Layout(tap) }; it re-renders itself on Locale.Changed.
-- Sequence (about 4 s; a click / tap anywhere skips to the summary):
--   1. wobble: the bought egg (EggLook) wobbles and hops, harder each time (Epic / Legendary once more); on the last one a glow
--      behind it takes the rarity colour;
--   2. burst: a white flash, the shell's upper courses fly off and spin, the lower ones fade;
--   3. reveal: the pet's portrait pops in, rays in the rarity colour turn behind it, the rarity name stamps in, confetti from Rare up;
--   4. summary: the portrait moves to the top left corner; name, rarity and the egg's chance of it, where it went, the pet count;
--      one row per trait it was born with (title, level / rarity cap, what it does; Cuteness: this pet's Coin bonus; field
--      traits: that it works on the crop field), a line on how traits grow; View pet / Great!.
-- Buttons by path: Reveal.Buttons.View, Reveal.Buttons.Ok, Reveal.Skip.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local PetConfig = require(ReplicatedStorage:WaitForChild("PetConfig"))
local EggLook = require(ReplicatedStorage:WaitForChild("EggLook"))
local StudStyle = require(ReplicatedStorage:WaitForChild("StudStyle"))
local Locale = require(ReplicatedStorage:WaitForChild("Locale"))
local UiKit = require(ReplicatedStorage:WaitForChild("UiKit"))
local UiSounds = require(ReplicatedStorage:WaitForChild("UiSounds"))
local PetClient = require(script.Parent:WaitForChild("PetClient"))
local PetPortrait = require(script.Parent:WaitForChild("PetPortrait"))
local PetRow = require(script.Parent:WaitForChild("PetRow"))

local create = UiKit.Create

local TITLE_H = 30
local EGG_SIZE = 210
local BIG = 150 -- portrait while it is revealed
local SMALL = 96 -- portrait in the summary's corner
local INSET = 4 -- room for the portrait's outline (a UIStroke outside the frame; the page clips its children)
local TOP = TITLE_H + 4 -- the summary starts under the title
local RAYS = 6 -- bars through the centre: 12 rays
local SPIN_SPEED = 0.6 -- radians per second (as the pet page)
local FIELD_TRAITS = { Tending = true, PestControl = true }
local CONFETTI = { Rare = 18, Epic = 30, Legendary = 50 }
local CONFETTI_COLORS = {
	Color3.fromRGB(255, 205, 60), Color3.fromRGB(110, 190, 255), Color3.fromRGB(255, 130, 190), Color3.fromRGB(120, 220, 110),
}
local COLOR_STAGE = Color3.fromRGB(24, 22, 18)
local COLOR_ROW = Color3.fromRGB(28, 28, 28)
local WHITE = Color3.new(1, 1, 1)

local HatchReveal = {}

local function hex(color: Color3): string
	return "#" .. color:ToHex()
end

local function tween(instance: Instance, seconds: number, props, style: Enum.EasingStyle?, direction: Enum.EasingDirection?)
	local t = TweenService:Create(instance, TweenInfo.new(seconds, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

function HatchReveal.new(parent: GuiObject, opts: { onDone: () -> (), onViewPet: (string) -> () })
	local root = create("Frame", {
		Name = "Reveal",
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Visible = false,
		Parent = parent,
	})
	local title = UiKit.Label("Title", {
		Size = UDim2.new(1, 0, 0, TITLE_H),
		TextSize = 24,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 6,
		Text = "",
		Parent = root,
	})

	-- the stage: everything of the animation, centred in the page
	local stage = create("Frame", {
		Name = "Stage",
		Position = UDim2.fromOffset(0, TOP),
		Size = UDim2.new(1, 0, 1, -TOP),
		BackgroundColor3 = COLOR_STAGE,
		BackgroundTransparency = 0.35,
		Parent = root,
	}, { create("UICorner", { CornerRadius = UDim.new(0, 12) }) })
	local glow = create("Frame", {
		Name = "Glow",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(150, 150),
		BackgroundColor3 = WHITE,
		BackgroundTransparency = 1,
		ZIndex = 1,
		Parent = stage,
	}, { create("UICorner", { CornerRadius = UDim.new(0.5, 0) }) })
	local rays = {}
	for i = 1, RAYS do
		rays[i] = create("Frame", {
			Name = "Ray" .. i,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(380, 30),
			BorderSizePixel = 0,
			BackgroundColor3 = WHITE,
			BackgroundTransparency = 1,
			ZIndex = 1,
			Parent = stage,
		}, {
			create("UIGradient", {
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(0.35, 0.55),
					NumberSequenceKeypoint.new(0.5, 0.2),
					NumberSequenceKeypoint.new(0.65, 0.55),
					NumberSequenceKeypoint.new(1, 1),
				}),
			}),
		})
	end
	local flash = create("Frame", {
		Name = "Flash",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = WHITE,
		BackgroundTransparency = 1,
		ZIndex = 7,
		Parent = stage,
	}, { create("UICorner", { CornerRadius = UDim.new(0, 12) }) })
	local stamp = UiKit.Label("Rarity", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, BIG / 2 + 30),
		Size = UDim2.new(1, -20, 0, 40),
		TextSize = 34,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextStrokeTransparency = 0.3,
		TextTransparency = 1,
		TextStrokeColor3 = Color3.new(0, 0, 0),
		ZIndex = 6,
		Text = "",
		Parent = stage,
	})
	local stampScale = create("UIScale", { Scale = 1, Parent = stamp })
	local skipLabel = UiKit.Label("SkipHint", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -8),
		Size = UDim2.new(1, 0, 0, 20),
		TextSize = 14,
		TextColor3 = StudStyle.Text.Dim,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 6,
		Text = "",
		Parent = stage,
	})
	local eggView: ViewportFrame? = nil

	-- the portrait: one holder that moves from the stage's centre to the summary's corner
	local holder = create("Frame", {
		Name = "PortraitHolder",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(30, 30, 30),
		Visible = false,
		ZIndex = 4,
		Parent = root,
	}, { create("UICorner", { CornerRadius = UDim.new(0, 10) }) })
	local holderStroke = create("UIStroke", { Thickness = 3, Color = WHITE, Parent = holder })
	-- confetti over the stage and under the portrait, centred like the stage; it keeps falling while the summary slides in
	local confetti = create("Frame", {
		Name = "Confetti",
		Position = UDim2.fromOffset(0, TOP),
		Size = UDim2.new(1, 0, 1, -TOP),
		BackgroundTransparency = 1,
		ZIndex = 3,
		Parent = root,
	})
	local holderScale = create("UIScale", { Scale = 1, Parent = holder })
	local portrait: ViewportFrame? = nil
	local function centrePosition(): UDim2
		return UDim2.new(0.5, 0, 0.5, TOP / 2)
	end
	local function cornerPosition(): UDim2
		return UDim2.fromOffset(INSET + SMALL / 2, TOP + INSET + SMALL / 2)
	end

	-- summary
	local info = create("Frame", {
		Name = "Info",
		Position = UDim2.fromOffset(INSET + SMALL + 12, TOP + INSET),
		Size = UDim2.new(1, -(INSET + SMALL + 12), 0, SMALL),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = root,
	}, {
		create("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 2),
		}),
	})
	local nameLabel = UiKit.Paragraph("PetName", { LayoutOrder = 1, Font = StudStyle.Font, TextSize = 24, RichText = true, Parent = info })
	local rarityLabel = UiKit.Paragraph("RarityLine", { LayoutOrder = 2, Font = StudStyle.Font, TextSize = 15, RichText = true, Parent = info })
	local whereLabel = UiKit.Paragraph("Where", { LayoutOrder = 3, TextSize = 14, TextColor3 = WHITE, Parent = info })
	local countLabel = UiKit.Paragraph("Count", { LayoutOrder = 4, TextSize = 13, Parent = info })

	local list = create("ScrollingFrame", {
		Name = "Traits",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 5,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Visible = false,
		Parent = root,
	}, {
		create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) }),
		create("UIPadding", { PaddingRight = UDim.new(0, 6), PaddingTop = UDim.new(0, 2), PaddingLeft = UDim.new(0, 2) }),
	})

	local buttons = create("Frame", {
		Name = "Buttons",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = root,
	}, {
		create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 12),
		}),
	})
	local viewButton = UiKit.Button("View", {
		LayoutOrder = 1, BackgroundColor3 = StudStyle.Colors.Blue, TextSize = 18, Text = "", Parent = buttons,
	}, 3)
	local okButton = UiKit.Button("Ok", {
		LayoutOrder = 2, BackgroundColor3 = StudStyle.Colors.Green, TextSize = 18, Text = "", Parent = buttons,
	}, 3)

	local skip = create("TextButton", {
		Name = "Skip",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 20,
		Visible = false,
		Parent = root,
	})
	skip:SetAttribute("UiSound", "None")

	local token = 0
	local confettiToken = 0
	local fillToken = 0 -- the summary's rows being drawn (a redraw replaces them)
	local current = nil -- the Hatch answer being shown
	local phase = "hidden" -- "anim" | "summary" | "hidden"
	local tap = 48
	local spin: RBXScriptConnection? = nil
	local rayAngle = 0

	local function rarityOf()
		return current and PetConfig.RarityById[current.rarity]
	end
	local function rarityColor(): Color3
		local rarity = rarityOf()
		return if rarity then rarity.color else WHITE
	end

	local function storedPet()
		return current and PetClient.State and PetClient.State.pets and PetClient.State.pets[current.uid]
	end

	local function stopSpin()
		if spin then
			spin:Disconnect()
			spin = nil
		end
	end

	-- the rays turn and the portrait's camera circles the pet while the page shows
	local function startSpin()
		stopSpin()
		spin = RunService.RenderStepped:Connect(function(dt)
			rayAngle = (rayAngle + dt * 25) % 180
			for i, ray in rays do
				ray.Rotation = rayAngle + (i - 1) * 180 / RAYS
			end
			local frame = portrait
			local camera = frame and frame.CurrentCamera
			local model = frame and frame:FindFirstChildOfClass("Model")
			if camera and model then
				local focus = model:GetBoundingBox().Position
				local offset = CFrame.Angles(0, dt * SPIN_SPEED, 0):VectorToWorldSpace(camera.CFrame.Position - focus)
				camera.CFrame = CFrame.lookAt(focus + offset, focus)
			end
		end)
	end

	-- runs fn(alpha 0..1) every frame for `seconds`; false when the sequence was skipped or replaced
	local function animate(mine: number, seconds: number, fn: (number) -> ()): boolean
		local start = os.clock()
		while true do
			if token ~= mine then
				return false
			end
			local alpha = math.min((os.clock() - start) / seconds, 1)
			fn(alpha)
			if alpha >= 1 then
				return true
			end
			RunService.RenderStepped:Wait()
		end
	end

	local function pause(mine: number, seconds: number): boolean
		task.wait(seconds)
		return token == mine
	end

	local function clearConfetti()
		confettiToken += 1
		for _, child in confetti:GetChildren() do
			child:Destroy()
		end
	end

	local function clearEgg()
		if eggView then
			eggView:Destroy()
			eggView = nil
		end
	end

	local function burstConfetti()
		local rarity = rarityOf()
		local count = rarity and CONFETTI[rarity.id] or 0
		if count == 0 then
			return
		end
		local pieces = {}
		local rng = Random.new()
		for i = 1, count do
			local color = if i % 3 == 0 then rarityColor() else CONFETTI_COLORS[rng:NextInteger(1, #CONFETTI_COLORS)]
			local piece = create("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(rng:NextInteger(5, 8), rng:NextInteger(9, 13)),
				BorderSizePixel = 0,
				BackgroundColor3 = color,
				ZIndex = 3,
				Parent = confetti,
			})
			local angle = rng:NextNumber(-math.pi * 0.85, -math.pi * 0.15) -- upwards, fanned out
			local speed = rng:NextNumber(220, 420)
			table.insert(pieces, {
				frame = piece, vx = math.cos(angle) * speed, vy = math.sin(angle) * speed, spin = rng:NextNumber(-540, 540),
			})
		end
		local mine = confettiToken
		task.spawn(function()
			local life = 1.6
			local start = os.clock()
			local last = start
			while confettiToken == mine do
				local now = os.clock()
				local alpha = math.min((now - start) / life, 1)
				local dt = now - last
				last = now
				for _, p in pieces do
					p.vy += 700 * dt
					local pos = p.frame.Position
					p.frame.Position = UDim2.new(0.5, pos.X.Offset + p.vx * dt, 0.5, pos.Y.Offset + p.vy * dt)
					p.frame.Rotation += p.spin * dt
					p.frame.BackgroundTransparency = math.clamp((alpha - 0.7) / 0.3, 0, 1)
				end
				if alpha >= 1 then
					clearConfetti()
					return
				end
				RunService.RenderStepped:Wait()
			end
		end)
	end

	local function traitRow(id: string, order: number, stored, popIn: boolean): Frame?
		local trait = PetRow.ByTrait[id]
		if not trait or not current then
			return nil
		end
		local level = if stored then math.max(1, PetConfig.AptitudeLevel(stored, id)) else 1
		local cap = PetConfig.AptitudeCap(tostring(current.kind))
		local what
		if id == "Cuteness" then
			local rarity = rarityOf()
			local permille = if stored then PetConfig.PetBonus(stored)
				elseif rarity then math.floor(PetConfig.BaseBonus(rarity, 1) + 0.5)
				else 0
			what = Locale.T("petDetail.bonus", { bonus = Locale.T("common.percentBonus", { pct = Locale.Decimal(PetClient.Percent(permille)) }) })
		else
			what = Locale.T("petDetail.aptDesc." .. id)
		end
		local row = create("Frame", {
			Name = "Trait_" .. id,
			LayoutOrder = order,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = COLOR_ROW,
		}, {
			create("UICorner", { CornerRadius = UDim.new(0, 8) }),
			create("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = trait.color, Thickness = 2 }),
			create("UIPadding", {
				PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10),
			}),
			create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2) }),
		})
		UiKit.Paragraph("Head", {
			LayoutOrder = 1,
			Font = StudStyle.Font,
			TextSize = 17,
			RichText = true,
			TextColor3 = trait.color,
			Text = Locale.T("petRow.chip.head", { icon = trait.icon, trait = Locale.T("pet.apt." .. id), level = level, cap = cap }),
			Parent = row,
		})
		UiKit.Paragraph("What", { LayoutOrder = 2, TextSize = 14, TextColor3 = WHITE, Text = what, Parent = row })
		if FIELD_TRAITS[id] then
			UiKit.Paragraph("Field", { LayoutOrder = 3, TextSize = 13, Text = Locale.T("hatchery.reveal.field"), Parent = row })
		end
		if popIn then
			local scale = create("UIScale", { Scale = 0.85, Parent = row })
			tween(scale, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)
		end
		return row
	end

	-- the summary's texts and rows (again on a language change or when the stored pet arrives)
	local function fillSummary(animated: boolean)
		if not current then
			return
		end
		fillToken += 1
		local mine = fillToken
		local rarity = rarityOf()
		local color = rarityColor()
		local stored = storedPet()
		nameLabel.Text = string.format("<font color='%s'>%s</font>", hex(color), Locale.PetKindName(tostring(current.kind)))
		local rarityText = Locale.RarityName(tostring(current.rarity))
		local egg = current.egg and PetConfig.Eggs[current.egg]
		local weight = egg and rarity and egg.weights[rarity.id]
		if egg and weight then
			rarityText ..= " · " .. Locale.T("hatchery.reveal.odds", {
				egg = Locale.EggName(egg),
				chance = Locale.Decimal(PetClient.Percent(weight)),
			})
		end
		rarityLabel.Text = string.format("<font color='%s'>%s</font>", hex(color), rarityText)
		whereLabel.Text = Locale.T(if current.equipped then "hatchery.reveal.follows" else "hatchery.reveal.panel")
		local count = 0
		local pets = PetClient.State and PetClient.State.pets
		if type(pets) == "table" then
			for _ in pets do
				count += 1
			end
			if not pets[current.uid] then
				count += 1 -- the pets list has not caught up with the hatch yet
			end
		end
		countLabel.Text = Locale.T("hatchery.reveal.count", { count = count, max = PetConfig.MaxPets })
		countLabel.Visible = count > 0

		for _, child in list:GetChildren() do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end
		UiKit.Paragraph("Heading", {
			LayoutOrder = 0, Font = StudStyle.Font, TextSize = 16, TextColor3 = StudStyle.Text.Rare,
			Text = Locale.T("hatchery.reveal.traits"), Parent = list,
		})
		local traits = if type(current.traits) == "table" then current.traits else {}
		local owned = {}
		for _, id in traits do
			owned[id] = true
		end
		local shown = {}
		for _, trait in PetRow.Traits do
			if owned[trait.id] then
				table.insert(shown, trait.id)
			end
		end
		local grow = UiKit.Paragraph("Grow", {
			LayoutOrder = 99, TextSize = 13, Text = Locale.T("hatchery.reveal.grow"), Parent = list,
		})
		if animated then
			grow.Visible = false
			task.spawn(function()
				for order, id in shown do
					if fillToken ~= mine then
						return
					end
					local row = traitRow(id, order, storedPet(), true)
					if row then
						row.Parent = list
					end
					task.wait(0.18)
				end
				if fillToken == mine then
					grow.Visible = true
				end
			end)
		else
			for order, id in shown do
				local row = traitRow(id, order, stored, false)
				if row then
					row.Parent = list
				end
			end
		end
	end

	local function layoutSummary()
		local listTop = TOP + 2 * INSET + SMALL + 6
		list.Position = UDim2.fromOffset(0, listTop)
		list.Size = UDim2.new(1, 0, 1, -(listTop + tap + 10))
		buttons.Size = UDim2.new(1, 0, 0, tap)
		viewButton.Size = UDim2.fromOffset(160, tap)
		okButton.Size = UDim2.fromOffset(160, tap)
	end

	local function texts()
		viewButton.Text = Locale.T("hatchery.reveal.view")
		okButton.Text = Locale.T("hatchery.reveal.ok")
		skipLabel.Text = Locale.T("hatchery.reveal.skip")
		title.Text = Locale.T(if phase == "anim" and not holder.Visible then "hatchery.reveal.hatching" else "hatchery.reveal.title")
		if current then
			stamp.Text = Locale.RarityName(tostring(current.rarity))
		end
	end

	-- straight to the summary (end of the sequence or a skip)
	local function showSummary(animated: boolean)
		token += 1
		local mine = token
		phase = "summary"
		skip.Visible = false
		clearEgg()
		if not animated then
			clearConfetti()
		end
		flash.BackgroundTransparency = 1
		texts()
		holder.Visible = true
		holderScale.Scale = 1
		layoutSummary()
		if animated then
			tween(holder, 0.4, { Position = cornerPosition(), Size = UDim2.fromOffset(SMALL, SMALL) })
			tween(stage, 0.35, { BackgroundTransparency = 1 })
			tween(glow, 0.3, { BackgroundTransparency = 1 })
			tween(stamp, 0.25, { TextTransparency = 1, TextStrokeTransparency = 1 })
			for _, ray in rays do
				tween(ray, 0.3, { BackgroundTransparency = 1 })
			end
			task.delay(0.35, function()
				if token == mine then
					stage.Visible = false
				end
			end)
		else
			holder.Position = cornerPosition()
			holder.Size = UDim2.fromOffset(SMALL, SMALL)
			stage.Visible = false
		end
		info.Visible = true
		list.Visible = true
		buttons.Visible = true
		if animated then
			info.Position = UDim2.fromOffset(INSET + SMALL + 32, TOP + INSET)
			tween(info, 0.35, { Position = UDim2.fromOffset(INSET + SMALL + 12, TOP + INSET) })
		else
			info.Position = UDim2.fromOffset(INSET + SMALL + 12, TOP + INSET)
		end
		fillSummary(animated)
	end

	local function run(mine: number)
		local rarity = rarityOf()
		local color = rarityColor()
		local big = rarity and rarity.order >= 4
		-- 1. wobble
		local view = EggLook.Portrait(tostring(current.egg or "Basic"), UDim2.fromOffset(EGG_SIZE, EGG_SIZE))
		view.AnchorPoint = Vector2.new(0.5, 0.5)
		view.Position = UDim2.fromScale(0.5, 0.5)
		view.ZIndex = 3
		view.Parent = stage
		eggView = view
		local model = view:FindFirstChildOfClass("Model")
		local parts = {}
		if model then
			for _, part in model:GetChildren() do
				if part:IsA("BasePart") then
					local course = tonumber(string.match(part.Name, "^Course(%d+)_"))
					table.insert(parts, { part = part, base = part.CFrame, course = course })
				end
			end
		end
		local function pose(cframe: CFrame)
			for _, p in parts do
				p.part.CFrame = cframe * p.base
			end
		end
		local amplitudes = if big then { 7, 11, 15, 21 } else { 8, 13, 19 }
		if not pause(mine, 0.25) then
			return
		end
		for n, amplitude in amplitudes do
			local last = n == #amplitudes
			UiSounds.Play("EggWobble")
			if last then
				glow.BackgroundColor3 = color
				glow.Size = UDim2.fromOffset(110, 110)
				tween(glow, 0.5, { BackgroundTransparency = 0.45, Size = UDim2.fromOffset(190, 190) })
			end
			local ok = animate(mine, 0.42, function(alpha)
				local swing = math.sin(alpha * math.pi * 3) * (1 - alpha * 0.4)
				local hop = math.sin(alpha * math.pi) * 0.25 * (amplitude / 15)
				pose(CFrame.new(0, hop, 0) * CFrame.Angles(math.rad(swing * amplitude * 0.25), 0, math.rad(swing * amplitude)))
			end)
			if not ok then
				return
			end
			pose(CFrame.identity)
			if not pause(mine, if last then 0.08 else 0.22) then
				return
			end
		end
		-- 2. burst
		UiSounds.Play("EggCrack")
		flash.BackgroundTransparency = 0.05
		tween(flash, 0.45, { BackgroundTransparency = 1 })
		local rng = Random.new()
		for _, p in parts do
			local position = p.base.Position
			local out = Vector3.new(position.X, 0, position.Z)
			out = if out.Magnitude > 0.05 then out.Unit else Vector3.new(rng:NextNumber(-1, 1), 0, rng:NextNumber(-1, 1)).Unit
			p.flies = (p.course or 0) >= 5
			p.velocity = out * rng:NextNumber(4, 7) + Vector3.new(0, if p.flies then rng:NextNumber(6, 10) else 0, 0)
			p.turn = Vector3.new(rng:NextNumber(-6, 6), rng:NextNumber(-6, 6), rng:NextNumber(-6, 6))
		end
		task.spawn(function()
			animate(mine, 0.6, function(alpha)
				for _, p in parts do
					if p.flies then
						local offset = p.velocity * alpha + Vector3.new(0, -12 * alpha * alpha, 0)
						p.part.CFrame = CFrame.new(offset) * p.base * CFrame.Angles(p.turn.X * alpha, p.turn.Y * alpha, p.turn.Z * alpha)
					end
					p.part.Transparency = math.clamp(if p.flies then (alpha - 0.4) / 0.6 else alpha / 0.5, 0, 1)
				end
			end)
			clearEgg()
		end)
		-- 3. reveal
		if not pause(mine, 0.12) then
			return
		end
		UiSounds.Play("EggReveal")
		title.Text = Locale.T("hatchery.reveal.title")
		holder.Position = centrePosition()
		holder.Size = UDim2.fromOffset(BIG, BIG)
		holderScale.Scale = 0.1
		holder.Visible = true
		tween(holderScale, 0.4, { Scale = 1 }, Enum.EasingStyle.Back)
		for _, ray in rays do
			ray.BackgroundColor3 = color
			tween(ray, 0.4, { BackgroundTransparency = 0.25 })
		end
		stamp.TextColor3 = color
		stampScale.Scale = 2.2
		tween(stamp, 0.25, { TextTransparency = 0, TextStrokeTransparency = 0.3 })
		tween(stampScale, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
		burstConfetti()
		if not pause(mine, if big then 1.6 else 1.2) then
			return
		end
		-- 4. summary
		showSummary(true)
	end

	local api = { frame = root }

	function api.Show(detail)
		token += 1
		local mine = token
		current = detail
		phase = "anim"
		root.Visible = true
		-- reset everything a previous hatch left
		clearEgg()
		clearConfetti()
		stage.Visible = true
		stage.BackgroundTransparency = 0.35
		glow.BackgroundTransparency = 1
		flash.BackgroundTransparency = 1
		stamp.TextTransparency = 1
		stamp.TextStrokeTransparency = 1
		for _, ray in rays do
			ray.BackgroundTransparency = 1
		end
		info.Visible = false
		list.Visible = false
		buttons.Visible = false
		holder.Visible = false
		if portrait then
			portrait:Destroy()
			portrait = nil
		end
		local stored = storedPet()
		portrait = PetPortrait.Make(tostring(detail.kind), if stored then PetConfig.PetLevel(stored) else 1, detail.uid)
		if portrait then
			portrait.Size = UDim2.fromScale(1, 1)
			portrait.ZIndex = 4
			portrait.Parent = holder
		end
		holderStroke.Color = rarityColor()
		skip.Visible = true
		texts()
		startSpin()
		task.spawn(run, mine)
	end

	function api.Hide()
		token += 1
		phase = "hidden"
		current = nil
		stopSpin()
		clearEgg()
		clearConfetti()
		root.Visible = false
	end

	-- panel resize: `tapHeight` = the panel's tap height
	function api.Layout(tapHeight: number)
		tap = tapHeight
		layoutSummary()
	end

	Locale.Changed:Connect(function()
		texts()
		if phase == "summary" then
			fillSummary(false)
		end
	end)

	skip.Activated:Connect(function()
		if phase == "anim" then
			showSummary(false)
		end
	end)
	okButton.Activated:Connect(function()
		opts.onDone()
	end)
	viewButton.Activated:Connect(function()
		if current then
			opts.onViewPet(current.uid)
		end
	end)
	-- the stored pet may arrive after the Hatch answer: redraw the summary's numbers
	PetClient.Changed:Connect(function()
		if phase == "summary" and current then
			fillSummary(false)
		end
	end)

	return api
end

return HatchReveal

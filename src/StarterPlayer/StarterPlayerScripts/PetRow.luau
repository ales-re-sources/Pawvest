-- PetRow (U1, docs/UI_GARDEN_PETS.md §9): the left part of a pet row, shared by the Pets panel and the food stand. Display only:
-- the numbers come from PetClient (OwnedPet) and the stored pet (PetClient.State.pets[uid]).
--   Traits                        the working traits in chip order: { id, icon, color }; ByTrait[id] = the same entry
--   Fill(row, entry, opts)        adds to `row` (a Frame ROW px high): portrait with a level badge (PetConfig.PetLevel) and a status
--                                 corner icon (✓ with you, 🌾 on the field), the name in the rarity colour, one chip per working trait
--                                 (icon + level in the trait's colour, a thin progress fill along its bottom edge, ▲ on the trait food
--                                 and obby XP train now) and "✔ Trained" when nothing can train. opts: portrait (a PetPortrait.Cache),
--                                 panelColor, right (px kept free on the right for the caller's buttons), highlight (a trait id: its
--                                 chip gets a white outline, the food stand), trainedTag (false: no "✔ Trained" tag), dim (greyed),
--                                 tooltip (from PetRow.Tooltip: hover / hold on a chip shows its exact numbers). Returns the chips.
--   Progress(stored, id, kind)    share 0..1 of the trait's way to its next level (1 at the rarity cap): the pet page's bar
--   ChipText(entry, stored, id)   the chip's exact numbers (rich text, several lines)
--   Tooltip(panel, color, opts?)  one tooltip for a panel: { Attach(guiObject, textFn), ShowAt(guiObject, text?), Hide() }.
--                                 opts: name (default "ChipTooltip"), room (a target closer than this to the panel's top gets
--                                 the tip below it; default 120). ShowAt places it by hand (FoodShop's food buttons). Attach: mouse: shown while hovering;
--                                 touch: shown while the finger holds the chip (and 2 s after). Placed above the chip (below it near
--                                 the panel's top), kept inside the panel; works under a UIScale.
-- Its children are drawn in code; the caller's ScreenGui uses ZIndexBehavior Sibling.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")

local PetConfig = require(ReplicatedStorage:WaitForChild("PetConfig"))
local StudStyle = require(ReplicatedStorage:WaitForChild("StudStyle"))
local UiKit = require(ReplicatedStorage:WaitForChild("UiKit"))
local Locale = require(ReplicatedStorage:WaitForChild("Locale"))
local PetClient = require(script.Parent:WaitForChild("PetClient"))
local PetPortrait = require(script.Parent:WaitForChild("PetPortrait"))

local PetRow = {}

PetRow.Traits = {
	{ id = "Cuteness", icon = "💗", color = Color3.fromRGB(255, 130, 190) },
	{ id = "Tending", icon = "🌱", color = Color3.fromRGB(120, 220, 110) },
	{ id = "PestControl", icon = "🛡", color = Color3.fromRGB(255, 170, 80) },
	{ id = "Scouting", icon = "🔭", color = Color3.fromRGB(110, 190, 255) },
}
PetRow.ByTrait = {}
for _, trait in PetRow.Traits do
	PetRow.ByTrait[trait.id] = trait
end

PetRow.PORTRAIT = 52
PetRow.TEXT_LEFT = 74 -- name and chips start right of the portrait
PetRow.CHIP_WIDTH = 50
PetRow.CHIP_HEIGHT = 24
PetRow.CHIP_GAP = 4

local COLOR_CHIP = Color3.fromRGB(28, 28, 28)
local COLOR_TRACK = Color3.fromRGB(60, 60, 60)
local COLOR_CARE = Color3.fromRGB(255, 205, 60) -- ▲
local COLOR_TRAINED = StudStyle.Text.Ok
local COLOR_WITH_YOU = StudStyle.Colors.Green
local COLOR_FIELD = StudStyle.Colors.Wood

local create = UiKit.Create

local function label(name: string, props)
	props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Center
	return UiKit.Label(name, props)
end

-- Share of the way to the next level, as the pet page's XP bar for that trait: Cuteness XP / CuteXpToNext, a work trait's field
-- seconds / AptitudeXpToNext (Scouting: the same seconds, counted as medal finishes); 1 at the rarity cap.
function PetRow.Progress(stored, id: string, kind: string): number
	local level = PetConfig.AptitudeLevel(stored, id)
	if level < 1 then
		return 0
	end
	if level >= PetConfig.AptitudeCap(kind) then
		return 1
	end
	local xp = stored.Apt[id].XP or 0
	local need = if id == "Cuteness" then PetConfig.CuteXpToNext(level) or 1 else PetConfig.AptitudeXpToNext(level)
	return math.clamp(xp / math.max(need, 1), 0, 1)
end

-- The chip's exact numbers: "💗 Cuteness · Lv 3 / 8", then the progress as the pet page words it, the Coin bonus for Cuteness, and
-- "▲ …" when food and obby XP train this trait now.
function PetRow.ChipText(entry, stored, id: string): string
	local trait = PetRow.ByTrait[id]
	local level = PetConfig.AptitudeLevel(stored, id)
	local cap = PetConfig.AptitudeCap(entry.kind)
	local lines = {
		Locale.T("petRow.chip.head", { icon = trait.icon, trait = Locale.T("pet.apt." .. id), level = level, cap = cap }),
	}
	if level >= cap then
		table.insert(lines, Locale.T("petDetail.aptMax", { rarity = Locale.RarityName(entry.rarity.id) }))
	elseif id == "Cuteness" then
		local need = PetConfig.CuteXpToNext(level) or 1
		table.insert(lines, Locale.T("pet.xp", { xp = math.floor(stored.Apt.Cuteness.XP or 0), next = need }))
	elseif id == "Scouting" then
		local rules = PetConfig.Scouting
		local need = PetConfig.AptitudeXpToNext(level)
		local xp = stored.Apt[id].XP or 0
		table.insert(lines, Locale.T("petDetail.scoutXp", {
			done = math.floor(xp / rules.XpPerFinish),
			need = math.ceil(need / rules.XpPerFinish),
		}))
	else
		local need = PetConfig.AptitudeXpToNext(level)
		local xp = stored.Apt[id].XP or 0
		table.insert(lines, Locale.T("petDetail.aptXp", {
			xp = { decimal = string.format("%.1f", xp / 3600) },
			next = { decimal = string.format("%.1f", need / 3600) },
		}))
	end
	if id == "Cuteness" then
		local bonus = Locale.T("common.percentBonus", { pct = Locale.Decimal(PetClient.Percent(entry.bonus)) })
		table.insert(lines, Locale.T("petDetail.bonus", { bonus = bonus }))
	end
	if entry.care == id then
		table.insert(lines, string.format("<font color='#%s'>%s</font>", COLOR_CARE:ToHex(), Locale.T("petRow.chip.care")))
	end
	return table.concat(lines, "\n")
end

local function cornerIcon(text: string, color: Color3, props)
	local icon = label("Status", {
		Size = UDim2.fromOffset(22, 22),
		BackgroundTransparency = 0,
		BackgroundColor3 = color,
		TextSize = 15,
		Text = text,
		ZIndex = 3,
	})
	for key, value in props do
		(icon :: any)[key] = value
	end
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = icon })
	create("UIStroke", { Color = StudStyle.Shade(color, 0.5), Thickness = 1.5, Parent = icon })
	return icon
end

function PetRow.Fill(row: GuiObject, entry, opts)
	local stored = PetClient.State and PetClient.State.pets[entry.uid]
	local dim = opts.dim == true
	local fade = if dim then 0.45 else 0
	local rowHeight = row.Size.Y.Offset
	local top = math.floor((rowHeight - PetRow.PORTRAIT) / 2)

	create("Frame", {
		Name = "RarityBar",
		Size = UDim2.new(0, 4, 1, -12),
		Position = UDim2.new(0, 4, 0, 6),
		BackgroundColor3 = entry.rarity.color,
		BackgroundTransparency = fade,
		BorderSizePixel = 0,
		Parent = row,
	}, { create("UICorner", { CornerRadius = UDim.new(0, 2) }) })

	local holder = PetPortrait.Holder({
		Position = UDim2.fromOffset(12, top),
		Size = UDim2.fromOffset(PetRow.PORTRAIT, PetRow.PORTRAIT),
		BackgroundColor3 = StudStyle.Shade(opts.panelColor, 0.18),
	}, opts.portrait and opts.portrait(entry))
	holder.Parent = row
	local portrait = holder:FindFirstChild("Portrait")
	if portrait then
		(portrait :: ViewportFrame).ImageTransparency = fade
	end
	-- the pet level (P4: its best working trait)
	local badge = label("Level", {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, 4, 1, 4),
		Size = UDim2.fromOffset(22, 20),
		BackgroundTransparency = 0,
		BackgroundColor3 = Color3.fromRGB(30, 30, 30),
		TextSize = 14,
		TextTransparency = fade,
		Text = tostring(entry.level),
		ZIndex = 3,
		Parent = holder,
	})
	create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = badge })
	create("UIStroke", { Color = entry.rarity.color, Thickness = 1.5, Parent = badge })
	if entry.equipped then
		cornerIcon("✓", COLOR_WITH_YOU, { Position = UDim2.fromOffset(-4, -4) }).Parent = holder
	elseif entry.field then
		cornerIcon("🌾", COLOR_FIELD, { Position = UDim2.fromOffset(-4, -4) }).Parent = holder
	end

	local textWidth = -(PetRow.TEXT_LEFT + (opts.right or 0))
	local trained = entry.care == nil and opts.trainedTag ~= false
	-- "✔ Trained" ends the name line (the chips can fill their line); the name truncates before it
	local tagWidth = 0
	if trained then
		local text = Locale.T("pets.trained")
		tagWidth = TextService:GetTextSize(text, 14, StudStyle.Font, Vector2.new(400, 40)).X + 4
		label("Trained", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -(opts.right or 0), 0, top),
			Size = UDim2.fromOffset(tagWidth, 20),
			TextSize = 14,
			TextColor3 = COLOR_TRAINED,
			TextTransparency = fade,
			TextXAlignment = Enum.TextXAlignment.Right,
			Text = text,
			Parent = row,
		})
		tagWidth += 6
	end
	local nameLabel = label("Name", {
		Position = UDim2.new(0, PetRow.TEXT_LEFT, 0, top - 1),
		Size = UDim2.new(1, textWidth - tagWidth, 0, 22),
		TextSize = 17,
		TextColor3 = entry.rarity.color,
		TextTransparency = fade,
		TextStrokeTransparency = 0.4,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Text = entry.name or Locale.PetKindName(entry.kind), -- the level is on the badge
		Parent = row,
	})

	local chips = {}
	local chipBar = create("Frame", {
		Name = "Traits",
		Position = UDim2.new(0, PetRow.TEXT_LEFT, 0, top + PetRow.PORTRAIT - PetRow.CHIP_HEIGHT),
		Size = UDim2.new(1, textWidth, 0, PetRow.CHIP_HEIGHT),
		BackgroundTransparency = 1,
		Parent = row,
	}, {
		create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, PetRow.CHIP_GAP),
		}),
	})
	for order, trait in PetRow.Traits do
		local level = if stored then PetConfig.AptitudeLevel(stored, trait.id) else 0
		if level > 0 then
			local share = PetRow.Progress(stored, trait.id, entry.kind)
			local chip = create("Frame", {
				Name = "Chip_" .. trait.id,
				LayoutOrder = order,
				Size = UDim2.fromOffset(PetRow.CHIP_WIDTH, PetRow.CHIP_HEIGHT),
				BackgroundColor3 = COLOR_CHIP,
				BackgroundTransparency = fade,
				ClipsDescendants = false,
				Parent = chipBar,
			}, {
				create("UICorner", { CornerRadius = UDim.new(0, 6) }),
				label("Text", {
					Size = UDim2.new(1, 0, 1, -3),
					TextSize = 14,
					TextColor3 = trait.color,
					TextTransparency = fade,
					TextStrokeTransparency = 0.6,
					Text = trait.icon .. " " .. level,
				}),
				-- the thin progress fill along the bottom edge
				create("Frame", {
					Name = "Track",
					AnchorPoint = Vector2.new(0, 1),
					Position = UDim2.new(0, 4, 1, -2),
					Size = UDim2.new(1, -8, 0, 3),
					BackgroundColor3 = COLOR_TRACK,
					BackgroundTransparency = fade,
					BorderSizePixel = 0,
				}, {
					create("Frame", {
						Name = "Fill",
						Size = UDim2.fromScale(share, 1),
						BackgroundColor3 = trait.color,
						BackgroundTransparency = fade,
						BorderSizePixel = 0,
						Visible = share > 0,
					}),
				}),
			})
			chip:SetAttribute("Level", level)
			chip:SetAttribute("Share", share)
			if opts.highlight == trait.id then
				create("UIStroke", {
					Name = "Highlight",
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					Color = Color3.new(1, 1, 1),
					Thickness = 2,
					Parent = chip,
				})
			end
			if entry.care == trait.id then
				label("Care", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(1, -3, 0, 2),
					Size = UDim2.fromOffset(14, 14),
					TextSize = 12,
					TextColor3 = COLOR_CARE,
					TextStrokeTransparency = 0.2,
					Text = "▲",
					ZIndex = 2,
					Parent = chip,
				})
			end
			if opts.tooltip then
				opts.tooltip.Attach(chip, function()
					local now = PetClient.State and PetClient.State.pets[entry.uid]
					return if now then PetRow.ChipText(entry, now, trait.id) else nil
				end)
			end
			chips[trait.id] = chip
		end
	end
	return chips, nameLabel
end

function PetRow.Tooltip(panel: GuiObject, color: Color3, opts: { name: string?, room: number? }?)
	local room = opts and opts.room or 120
	local tip = label(opts and opts.name or "ChipTooltip", {
		AnchorPoint = Vector2.new(0.5, 1),
		Size = UDim2.fromOffset(230, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 0,
		BackgroundColor3 = StudStyle.Shade(color, 0.2),
		TextSize = 14,
		TextWrapped = true,
		RichText = true,
		ZIndex = 30,
		Visible = false,
		Parent = panel,
	})
	create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = tip })
	create("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = COLOR_CARE, Thickness = 2, Parent = tip })
	create("UIPadding", {
		PaddingTop = UDim.new(0, 5),
		PaddingBottom = UDim.new(0, 5),
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
		Parent = tip,
	})

	local owner: GuiObject? = nil
	local token = 0
	local api = {}

	function api.Hide()
		owner = nil
		token += 1
		tip.Visible = false
	end

	-- the tip with `text` over (or, near the panel's top, under) `target`, inside the panel's width; nil text hides it
	function api.ShowAt(target: GuiObject, text: string?)
		if not (text and target.Parent and panel.AbsoluteSize.X > 0) then
			return api.Hide()
		end
		owner = target
		token += 1
		tip.Text = text
		-- panel pixels: the panel may sit under a UIScale
		local scale = panel.AbsoluteSize.X / math.max(panel.Size.X.Offset, 1)
		local x = (target.AbsolutePosition.X - panel.AbsolutePosition.X + target.AbsoluteSize.X / 2) / scale
		local topY = (target.AbsolutePosition.Y - panel.AbsolutePosition.Y) / scale
		local half = tip.Size.X.Offset / 2
		x = math.clamp(x, half + 4, panel.Size.X.Offset - half - 4)
		if topY < room then
			tip.AnchorPoint = Vector2.new(0.5, 0)
			tip.Position = UDim2.fromOffset(x, topY + target.AbsoluteSize.Y / scale + 6)
		else
			tip.AnchorPoint = Vector2.new(0.5, 1)
			tip.Position = UDim2.fromOffset(x, topY - 6)
		end
		tip.Visible = true
	end

	local function show(target: GuiObject, textFn: () -> string?)
		api.ShowAt(target, textFn())
	end

	function api.Attach(target: GuiObject, textFn: () -> string?)
		target.Active = false -- a chip never takes the tap (the row does nothing on a tap either)
		target.MouseEnter:Connect(function()
			show(target, textFn)
		end)
		target.MouseLeave:Connect(function()
			if owner == target then
				api.Hide()
			end
		end)
		target.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch then
				show(target, textFn)
			end
		end)
		target.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch and owner == target then
				token += 1
				local mine = token
				task.delay(2, function()
					if token == mine then
						api.Hide()
					end
				end)
			end
		end)
	end

	return api
end

return PetRow

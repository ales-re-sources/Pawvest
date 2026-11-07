-- Pet filter chips shared by the Pets panel and the Food Stand: All n/50 · With me · On the field · Best for ▼ (a trait: the pets
-- that have it, highest first; the menu opens under the chip). Each Mount keeps its own choice for the session.
--   PetFilterBar.Mount(panel, { color, width, top, height, onPress?, onChange })
--   bar.Filtered(inventory) -> the pets the filter shows (inventory order, or by the trait's level for "Best for")
--   bar.Refresh(inventory)  -> chip texts and highlight (call on every refresh)
--   bar.SetTexts()          -> texts that do not depend on the state (on Locale.Changed)
--   bar.SetLayout(top, height), bar.HideMenu(), bar.Filter()
-- `onPress` runs on any chip press (hide tooltips); `onChange` after a filter was picked (reset the scroll, refresh).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PetConfig = require(ReplicatedStorage:WaitForChild("PetConfig"))
local StudStyle = require(ReplicatedStorage:WaitForChild("StudStyle"))
local Locale = require(ReplicatedStorage:WaitForChild("Locale"))
local PetClient = require(script.Parent:WaitForChild("PetClient"))
local PetRow = require(script.Parent:WaitForChild("PetRow"))

local FILTERS = { "all", "with", "field", "best" }
local RIGHT = 10
local COLOR_FILTER_ON = StudStyle.Colors.Yellow
local COLOR_MENU_STROKE = Color3.fromRGB(255, 205, 60)

local PetFilterBar = {}

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

-- a brick button (StudStyle.Brick: colour and text keep being set on the button itself)
local function button(name: string, props, studs: number?)
	props.Name = name
	props.TextColor3 = Color3.new(1, 1, 1)
	local instance = create("TextButton", props)
	StudStyle.Brick(instance, { studs = studs })
	return instance
end

local function traitWord(id: string): string
	return if id == "Cuteness" then Locale.T("pets.filter.coins") else Locale.T("pet.apt." .. id)
end

function PetFilterBar.Mount(panel: Frame, opts)
	local width: number = opts.width
	local top: number = opts.top
	local height: number = opts.height
	local colorFilter = StudStyle.Shade(opts.color, 0.7)
	local filter = "all" -- "all" | "with" | "field" | "best"
	local bestTrait = "Cuteness" -- the trait of "Best for"
	local bar = {}

	local chipWidth = math.floor((width - 10 - RIGHT - 6 * (#FILTERS - 1)) / #FILTERS)
	local chips = {}
	for index, id in FILTERS do
		local chip = button("Filter_" .. id, {
			Position = UDim2.fromOffset(10 + (index - 1) * (chipWidth + 6), top),
			Size = UDim2.fromOffset(chipWidth, height),
			BackgroundColor3 = colorFilter,
			TextSize = 14,
			TextWrapped = true,
		}, 2)
		chip:SetAttribute("UiSound", "Tab") -- filters are tabs (UiSoundsClient)
		chip.Parent = panel
		chips[id] = chip
	end

	-- "Best for ▼" opens a list of the traits under its chip
	local menu = create("Frame", {
		Name = "BestMenu",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromOffset(width - RIGHT, top + height + 4),
		Size = UDim2.fromOffset(180, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = StudStyle.Shade(opts.color, 0.2),
		ZIndex = 12,
		Visible = false,
		Parent = panel,
	}, {
		create("UICorner", { CornerRadius = UDim.new(0, 8) }),
		create("UIStroke", { Color = COLOR_MENU_STROKE, Thickness = 2 }),
		create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) }),
		create("UIPadding", {
			PaddingTop = UDim.new(0, 6),
			PaddingBottom = UDim.new(0, 8),
			PaddingLeft = UDim.new(0, 6),
			PaddingRight = UDim.new(0, 6),
		}),
	})
	local options = {}
	for order, trait in PetRow.Traits do
		local option = button("Best_" .. trait.id, {
			LayoutOrder = order,
			Size = UDim2.new(1, 0, 0, height),
			BackgroundColor3 = colorFilter,
			TextSize = 15,
			ZIndex = 13,
		}, 3)
		option:SetAttribute("UiSound", "Tab")
		option.Parent = menu
		options[trait.id] = option
	end

	function bar.SetTexts()
		chips.with.Text = Locale.T("pets.filter.withMe")
		chips.field.Text = Locale.T("pets.filter.field")
		for id, option in options do
			option.Text = PetRow.ByTrait[id].icon .. " " .. traitWord(id)
		end
	end

	function bar.SetLayout(newTop: number, newHeight: number)
		top, height = newTop, newHeight
		for _, chip in chips do
			chip.Position = UDim2.fromOffset(chip.Position.X.Offset, top)
			chip.Size = UDim2.fromOffset(chipWidth, height)
		end
		menu.Position = UDim2.fromOffset(width - RIGHT, top + height + 4)
		for _, option in options do
			option.Size = UDim2.new(1, 0, 0, height)
		end
	end

	function bar.HideMenu()
		menu.Visible = false
	end

	function bar.Filter(): string
		return filter
	end

	local function setFilter(id: string)
		filter = id
		opts.onChange()
	end

	for id, chip in chips do
		chip.Activated:Connect(function()
			if opts.onPress then
				opts.onPress()
			end
			if id == "best" then
				menu.Visible = not menu.Visible
				return
			end
			menu.Visible = false
			setFilter(id)
		end)
	end
	for id, option in options do
		option.Activated:Connect(function()
			menu.Visible = false
			bestTrait = id
			setFilter("best")
		end)
	end

	-- the pets the filter shows, in its order: inventory order, or (Best for) the trait's level, highest first
	function bar.Filtered(inventory)
		local state = PetClient.State
		local shown = {}
		for index, pet in inventory do
			local keep = filter == "all"
				or (filter == "with" and pet.equipped)
				or (filter == "field" and pet.field ~= nil)
				or (filter == "best" and PetConfig.AptitudeLevel(state.pets[pet.uid], bestTrait) > 0)
			if keep then
				table.insert(shown, { pet = pet, index = index })
			end
		end
		if filter == "best" then
			table.sort(shown, function(a, b)
				local la = PetConfig.AptitudeLevel(state.pets[a.pet.uid], bestTrait)
				local lb = PetConfig.AptitudeLevel(state.pets[b.pet.uid], bestTrait)
				if la ~= lb then
					return la > lb
				end
				return a.index < b.index
			end)
		end
		local pets = {}
		for _, item in shown do
			table.insert(pets, item.pet)
		end
		return pets
	end

	function bar.Refresh(inventory)
		chips.all.Text = Locale.T("pets.filter.all", { count = #inventory, max = PetConfig.MaxPets })
		local bestKey = if filter == "best" then "pets.filter.bestTrait" else "pets.filter.best"
		chips.best.Text = Locale.T(bestKey, { icon = PetRow.ByTrait[bestTrait].icon, trait = traitWord(bestTrait) })
		for id, chip in chips do
			chip.BackgroundColor3 = if filter == id then COLOR_FILTER_ON else colorFilter
		end
		for id, option in options do
			option.BackgroundColor3 = if filter == "best" and bestTrait == id then COLOR_FILTER_ON else colorFilter
		end
	end

	bar.SetTexts()
	return bar
end

return PetFilterBar

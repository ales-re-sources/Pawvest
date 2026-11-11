--!strict
-- ConfirmTap (U4, docs/UI_GARDEN_PETS.md §10): the one confirm pattern for every spend over THRESHOLD Coins and for Sell. Client only.
-- The first tap turns the button orange with "Tap again" for SECONDS; a second tap within that time fires. Spends at or under the
-- threshold fire on the first tap. The armed state is kept by `key`, so a panel that rebuilds its rows between the two taps keeps it.
--
--   ConfirmTap.Wrap(button, key, needsConfirm, onConfirm, armedText?)   wires `button` (a StudStyle brick: colour and text are set
--                                                                        on the button itself); `needsConfirm()` is asked on every tap
--   ConfirmTap.Over(price) -> boolean                                     price > THRESHOLD
--   ConfirmTap.Tap(key, onLapse?) -> boolean                              for a button that draws itself: true = confirmed, else
--                                                                        armed (IsArmed(key) while it waits; Disarm(key))
--   ConfirmTap.Reset()                                                    disarms everything (a panel closed)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Locale = require(ReplicatedStorage:WaitForChild("Locale"))

local ConfirmTap = {}

ConfirmTap.THRESHOLD = 1000
ConfirmTap.SECONDS = 3
ConfirmTap.COLOR = Color3.fromRGB(240, 140, 40)

local armedUntil: { [string]: number } = {}

function ConfirmTap.Over(price: number): boolean
	return price > ConfirmTap.THRESHOLD
end

function ConfirmTap.Reset()
	table.clear(armedUntil)
end

function ConfirmTap.IsArmed(key: string): boolean
	local untilTime = armedUntil[key]
	return untilTime ~= nil and os.clock() < untilTime
end

function ConfirmTap.Disarm(key: string)
	armedUntil[key] = nil
end

-- One tap on `key`: true when it confirms (it was armed: now disarmed); otherwise arms `key` for SECONDS and returns false.
-- onLapse runs once the arming has lapsed (or was disarmed) without a second tap: redraw the button there.
function ConfirmTap.Tap(key: string, onLapse: (() -> ())?): boolean
	if ConfirmTap.IsArmed(key) then
		armedUntil[key] = nil
		return true
	end
	local mine = os.clock() + ConfirmTap.SECONDS
	armedUntil[key] = mine
	task.delay(ConfirmTap.SECONDS, function()
		if armedUntil[key] == mine then
			armedUntil[key] = nil
		end
		if onLapse and not ConfirmTap.IsArmed(key) then
			onLapse()
		end
	end)
	return false
end

function ConfirmTap.Wrap(button: GuiButton, key: string, needsConfirm: () -> boolean, onConfirm: () -> (), armedText: string?)
	local textButton = button :: any
	local normalColor = button.BackgroundColor3
	local normalText = textButton.Text
	local function showArmed(on: boolean)
		if not button.Parent then
			return
		end
		button.BackgroundColor3 = if on then ConfirmTap.COLOR else normalColor
		textButton.Text = if on then (armedText or Locale.T("common.tapAgain")) else normalText
	end
	if ConfirmTap.IsArmed(key) then
		showArmed(true) -- rebuilt between the two taps
	end
	button.Activated:Connect(function()
		if not needsConfirm() then
			ConfirmTap.Disarm(key)
			showArmed(false)
			onConfirm()
		elseif ConfirmTap.Tap(key, function()
			showArmed(false)
		end) then
			showArmed(false)
			onConfirm()
		else
			showArmed(true)
		end
	end)
end

return ConfirmTap

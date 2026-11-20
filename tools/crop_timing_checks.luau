-- Run via Studio MCP execute_luau in Edit mode. Exercises current production settle / timer code with in-memory fixtures only.
-- No live profiles, remotes or DataStores are read or written. Temporary modules are removed even if a check fails.
assert(not game:GetService("RunService"):IsRunning(), "Run crop timing checks in Edit mode")
local storage = game:GetService("ReplicatedStorage")
local config = storage.CropConfig:Clone()
config.Name = "CropTimingCheckConfig"
config.Parent = storage
local harness = Instance.new("ModuleScript")
harness.Name = "CropTimingCheckHarness"
harness.Parent = storage
local source = game.ServerScriptService.GardenField.Source
local settle = assert(source:match("(local RIPEN_EPSILON.-)\nGardenField.Settle = settle"), "settle source boundary changed")
local window = assert(source:match("(local function onlineSpeed.-)\n%-%- EV3b: the state's mastery"), "window source boundary changed")
harness.Source = [=[
local CropConfig = require(script.Parent.CropTimingCheckConfig)
local context = { strength = {}, guards = {} }
local function addRest() end
local function pointsOf(garden, crop) return garden.Crops[crop.id] and garden.Crops[crop.id].Pts end
local function tendingStrength() return context.strength end
local function guardStrength() return context.guards end
local function tendRoll() return 0 end
local function crowRoll() return 0 end
local function guardRoll() return 0 end
local function shearsExtra() return false end
local function addPlant() end
local function store(_, garden, crop)
    garden.Items[crop.id] = (garden.Items[crop.id] or 0) + 1
    return 1
end
local PetConfig = { GainAptitudeXp = function(pet, job, seconds)
    pet[job] = (pet[job] or 0) + seconds
    return 0
end }
]=] .. settle .. "\n" .. window .. [=[
local passed = 0
local function check(ok, message)
    assert(ok, message)
    passed += 1
end
local function close(a, b, message) check(math.abs(a - b) < 1e-6, message .. ': ' .. a .. ' vs ' .. b) end
local function fixture(crop, elapsed, grown)
    local field = { SettledAt = os.time() - elapsed, Squares = { ['1'] = { Crop = crop, Grown = grown or 0, N = 1 } },
        Upgrades = {}, Plantings = 1 }
    local profile = { Garden = { FieldPets = {}, Items = {}, Seeds = {}, Tools = {}, Crops = {}, Unlocked = {} }, Pets = {} }
    context.strength, context.guards = {}, {}
    return field, profile
end
local player = { UserId = 1 }
for _, case in { { 'Sunflower', 24 * 3600, false }, { 'Pineapple', 48 * 3600, false }, { 'GiantMelon', 24 * 3600, true } } do
    local field, profile = fixture(case[1], case[2])
    settle(player, profile, field, { [1] = true }, true)
    check((field.Squares['1'].Grown >= CropConfig.ById[case[1]].growSeconds) == case[3], case[1] .. ' respects capped absence')
    close(field.Squares['1'].Grown, math.min(case[2], CropConfig.OfflineCapSeconds), 'offline cap')
end
for _, case in { { 'Sunflower', 18 * 3600 }, { 'Pineapple', 24 * 3600 } } do
    local field, profile = fixture(case[1], case[2])
    settle(player, profile, field, { [1] = true }, false)
    close(field.Squares['1'].Grown, CropConfig.ById[case[1]].growSeconds, case[1] .. ' has pre-OG2 online duration')
end
do
    local field, profile = fixture('Sunflower', 24 * 3600)
    settle(player, profile, field, { [1] = true }, true)
    field.SettledAt -= 12 * 3600
    settle(player, profile, field, { [1] = true }, true)
    close(field.Squares['1'].Grown, CropConfig.ById.Sunflower.growSeconds, 'Sunflower needs 36 h across capped absences')
end
do
    local field, profile = fixture('Sunflower', 300, 123)
    settle(player, profile, field, { [1] = true }, true)
    field.SettledAt -= 120
    settle(player, profile, field, { [1] = true }, false)
    close(field.Squares['1'].Grown, 123 + 300 + 240, 'old progress plus mixed clocks')
end
do
    local field, profile = fixture('Sunflower', 3600)
    profile.Pets.p = {}
    profile.Garden.FieldPets.p = {}
    settle(player, profile, field, { [1] = true }, false)
    close(profile.Pets.p.Tending, 3600, 'online Tending XP unchanged')
    close(profile.Pets.p.PestControl, 3600, 'online guard XP unchanged')
    field.SettledAt -= 3600
    settle(player, profile, field, { [1] = true }, true)
    close(profile.Pets.p.Tending, 5400, 'offline Tending XP unchanged')
    close(profile.Pets.p.PestControl, 5400, 'offline guard XP unchanged')
end
do
    local field, profile = fixture('Potato', 60)
    profile.Garden.Seeds.Potato = 4
    context.strength[1] = 1
    settle(player, profile, field, { [1] = true }, true)
    close(profile.Garden.Items.Potato, 3, 'Tending cycles at new offline rate')
    close(profile.Garden.Seeds.Potato, 1, 'Tending consumes one seed per replant')
    close(field.Squares['1'].Grown, 0, 'Tending keeps remainder')
end
do
    -- Force an overlapping crow block; the production code still decides exposure / protection from actual ripeness.
    CropConfig.CrowsBetween = function() return true end
    local field, profile = fixture('Sunflower', 20 * 3600, 20 * 3600)
    profile.Garden.Unlocked[CropConfig.Crows.FromCrop] = true
    local _, _, raid = settle(player, profile, field, { [1] = true }, true)
    check(field.Squares['1'] == nil and raid.ate.Sunflower == 1, 'newly ripe offline crop exposed to crows')
    field, profile = fixture('Sunflower', 20 * 3600, 20 * 3600)
    profile.Garden.Unlocked[CropConfig.Crows.FromCrop] = true
    context.guards[1] = { uid = 'g', chance = 1 }
    _, _, raid = settle(player, profile, field, { [1] = true }, true)
    check(field.Squares['1'] ~= nil and raid.chased.g == 1, 'guard protects newly ripe crop')
end
for growth = 0, 4 do
    for points = 0, 3 do
        for cloches = 0, 3 do
            local upgrades, tools, pts = { Growth = growth }, { Cloches = cloches }, { Speed = points }
            local off, on = CropConfig.GrowthRates(upgrades, tools, pts)
            close(on / off, CropConfig.CountdownRate(tools), 'shared rates agree')
            local field = { SettledAt = 1000, Upgrades = upgrades }
            local garden = { Tools = tools, Crops = { Sunflower = { Pts = pts } } }
            close(onlineSpeed(garden, field, CropConfig.ById.Sunflower), on, 'server uses shared rates')
            local duration = CropConfig.ById.Sunflower.growSeconds
            local startAt, readyAt = growthWindow(field, { Grown = 123 }, duration, on)
            check(readyAt >= 1000 + (duration - 123) / on - 1e-6 and readyAt < 1001 + (duration - 123) / on,
                'harvest boundary rounds to first whole second')
            local left = CropConfig.TimeLeft(readyAt, 1000, tools)
            close(left - CropConfig.TimeLeft(readyAt, 1001, tools), on / off, 'countdown ticks at online bonus')
            local share, ripe, displayed = CropConfig.Progress({ grown = 123, readyAt = readyAt }, CropConfig.ById.Sunflower, 1000, 1001, tools)
            check(share > 123 / duration and not ripe and displayed > 0, 'card / ring progress advances')
            local final, ripeNow, zero = CropConfig.Progress({ grown = 123, readyAt = readyAt }, CropConfig.ById.Sunflower, 1000, readyAt, tools)
            check(final == 1 and ripeNow and zero == 0, 'timer / ripeness share exact boundary')
        end
    end
end
close(CropConfig.CountdownRate(nil), 2, 'base countdown multiplier')
close(CropConfig.CountdownRate({ Cloches = 3 }), 2.4, 'top Cloches multiplier')
return tostring(passed) .. ' crop timing fixture checks passed (no live data)'
]=]
local ok, result = pcall(require, harness)
harness:Destroy()
config:Destroy()
assert(ok, result)
return result

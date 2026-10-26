-- Coplanar-face audit for kit doors (docs/STAGES.md → "Moving parts vs frame").
-- Run through the Studio MCP `execute_luau` in Edit mode (paste the file as `code`; nothing in the place is changed).
-- A KitDoor is checked in five states from closed to open (the same formula as ObstacleKit): any face of the door that
-- lies in the same plane, faces the same way and overlaps a face of another visible part z-fights (flickering mixed
-- textures). Touching faces that point opposite ways (a door resting on its sill) are fine.
-- Prints one line per clash, or "clean". Extend `tagged` to audit other moving parts by giving them a state function.
local CollectionService = game:GetService("CollectionService")

local PLANE_EPS, MIN_AREA, STEPS = 0.02, 0.05, 4

local function faces(cf: CFrame, size: Vector3)
	local axes = { cf.RightVector, cf.UpVector, cf.LookVector }
	local sizes = { size.X, size.Y, size.Z }
	local list = {}
	for i = 1, 3 do
		for _, sign in { 1, -1 } do
			local n = axes[i] * sign
			table.insert(list, {
				n = n,
				c = cf.Position + n * sizes[i] / 2,
				u = axes[i % 3 + 1],
				v = axes[(i + 1) % 3 + 1],
				hu = sizes[i % 3 + 1] / 2,
				hv = sizes[(i + 1) % 3 + 1] / 2,
				name = (if sign > 0 then "+" else "-") .. ({ "X", "Y", "Z" })[i],
			})
		end
	end
	return list
end

local function overlapArea(a, b): number
	local lo = { u = math.huge, v = math.huge }
	local hi = { u = -math.huge, v = -math.huge }
	for _, su in { -1, 1 } do
		for _, sv in { -1, 1 } do
			local d = b.c + b.u * b.hu * su + b.v * b.hv * sv - a.c
			local pu, pv = d:Dot(a.u), d:Dot(a.v)
			lo.u, hi.u = math.min(lo.u, pu), math.max(hi.u, pu)
			lo.v, hi.v = math.min(lo.v, pv), math.max(hi.v, pv)
		end
	end
	local w = math.min(a.hu, hi.u) - math.max(-a.hu, lo.u)
	local h = math.min(a.hv, hi.v) - math.max(-a.hv, lo.v)
	return if w > 0 and h > 0 then w * h else 0
end

local function doorCFrame(part: BasePart, base: CFrame, t: number): CFrame
	local turn = part:GetAttribute("OpenTurn") or 0
	local axis = part:GetAttribute("OpenAxis") or Vector3.yAxis
	local distance = part:GetAttribute("OpenDistance") or (if turn ~= 0 then 0 else part.Size.Y)
	local hinge = part:GetAttribute("OpenHinge")
	local turned = CFrame.Angles(0, math.rad(turn * t), 0)
	local placed
	if typeof(hinge) == "Vector3" then
		local pivot = base.Position + hinge
		placed = CFrame.new(pivot) * turned * CFrame.new(-pivot) * base
	else
		placed = turned * base.Rotation + base.Position
	end
	return placed + axis.Unit * distance * t
end

local report = {}
for _, door in CollectionService:GetTagged("KitDoor") do
	if door:IsA("BasePart") and door:IsDescendantOf(workspace) then
		local params = OverlapParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		for step = 0, STEPS do
			local cf = doorCFrame(door, door.CFrame, step / STEPS)
			params.FilterDescendantsInstances = {}
			for _, other in workspace:GetPartBoundsInBox(cf, door.Size + Vector3.one * 0.2, params) do
				if other ~= door and other.Transparency < 1 and other.AssemblyRootPart ~= door.AssemblyRootPart then
					for _, fa in faces(cf, door.Size) do
						for _, fb in faces(other.CFrame, other.Size) do
							if
								fa.n:Dot(fb.n) > 0.999
								and math.abs(fa.n:Dot(fb.c - fa.c)) < PLANE_EPS
								and overlapArea(fa, fb) > MIN_AREA
							then
								table.insert(report, string.format(
									"%s (open %d%%, face %s) z-fights with %s (face %s)",
									door:GetFullName(), step * 100 / STEPS, fa.name, other:GetFullName(), fb.name
								))
							end
						end
					end
				end
			end
		end
	end
end
return if #report == 0 then "clean" else table.concat(report, "\n")

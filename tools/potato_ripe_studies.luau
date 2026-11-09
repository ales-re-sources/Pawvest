-- Studio playtest, Client command context. Static ripe Potato design review only.
-- Upright branching reference and rationale: docs/EXPANSION.md CG3 and docs/art/potato/reference.png.
-- Uses the production PlotView renderer in the first unused slot >=13; squares 8/9/10
-- contain A/B/C, left to right when viewed from plot-local +Z. Square 7 has a real
-- neighboring crop; square 11 has a Cat. No garden requests, profile writes, motion,
-- or Potato recipe registration. Destroy workspace.PotatoRipeStudies after review.
local RunService = game:GetService("RunService")
assert(RunService:IsStudio() and RunService:IsClient(), "Run in the Studio playtest client")
local player = game:GetService("Players").LocalPlayer
local PlotView = require(player.PlayerScripts:WaitForChild("PlotView"))
local CropConfig = require(game.ReplicatedStorage.CropConfig)
local GardenConfig = require(game.ReplicatedStorage.GardenConfig)
local garden = assert(workspace:FindFirstChild("GardenView"), "Wait for GardenView")
assert(not workspace:FindFirstChild("PotatoRipeStudies"), "Remove previous review folder first")
local slot = 13
while GardenConfig.PlotCFrame(slot) and garden:FindFirstChild(string.format("Slot_%02d", slot)) do
	slot += 1
end
assert(GardenConfig.PlotCFrame(slot), "No free review slot >=13")
assert(not garden:FindFirstChild(string.format("Slot_%02d", slot)), "Review slot occupied")

local V = Vector3.new
local green = Color3.fromRGB(61, 132, 60)
local light = Color3.fromRGB(91, 157, 67)
local stem = Color3.fromRGB(80, 119, 54)
local tan = Color3.fromRGB(173, 133, 83)
local function block(model, name, size, cf, color, variant)
	local p = Instance.new("Part")
	p.Name, p.Size, p.CFrame, p.Color = name, size, cf, color
	p.Material, p.MaterialVariant = Enum.Material.Plastic, variant or "StudsSmall"
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
	p.Parent = model
	return p
end
local function axis(a, b)
	local direction = (b-a).Unit
	return CFrame.lookAt((a+b)/2, a, if math.abs(direction.Y)>0.98 then Vector3.xAxis else Vector3.yAxis)
end
local function twig(model, base, a, b)
	block(model, "Stem", V(0.12,0.12,(b-a).Magnitude), base*axis(a,b), stem)
end
-- Two folded blocks per blade: a broad base rises to a crease; the narrower
-- terminal step droops. Paired blades read as potato foliage, never hanging fruit.
local function blade(model, base, at, direction, width, color)
	local crease = at + direction*0.60 + V(0,0.12,0)
	local tip = at + direction
	block(model, "LeafFold", V(width,0.14,(crease-at).Magnitude), base*axis(at,crease), color, "Studs")
	block(model, "LeafTip", V(width*0.62,0.13,(tip-crease).Magnitude), base*axis(crease,tip), color)
end
-- Each branch is a short rachis with an opposed leaf pair. Branches sit at
-- separate heights, leaving sections of the upright green shoots visible.
local function compoundPair(model, base, node, outward, scale)
	local branchEnd = node + outward*0.46 + V(0,0.09,0)
	twig(model,base,node,branchEnd)
	local side = V(-outward.Z,0,outward.X)
	blade(model,base,branchEnd, (outward*0.48+side*0.70+V(0,0.10,0))*scale,0.46*scale,green)
	blade(model,base,branchEnd, (outward*0.48-side*0.70+V(0,0.04,0))*scale,0.43*scale,light)
end
local function shoulder(model,base,at,turn)
	-- The wide middle block is partly buried. Narrow ends and a raised crown
	-- describe a rounded voxel tuber shoulder, with its body below soil level.
	local cf = base*CFrame.new(at)*CFrame.Angles(0,turn,0)
	block(model,"TuberBuriedSides",V(0.73,0.34,0.45),cf*CFrame.new(0,-0.08,0),tan)
	block(model,"TuberRoundedEnds",V(0.53,0.33,0.62),cf*CFrame.new(0,-0.08,0),tan)
	block(model,"TuberCrown",V(0.44,0.14,0.35),cf*CFrame.new(0,0.13,0),tan)
end
-- Flowers face plot-local +Z and slightly upward, so their five lobes and
-- raised yellow centre remain readable from the usual gameplay view.
local function flower(model, base, at, turn)
	local normal = V(0,0.55,0.84).Unit
	local face = CFrame.lookAt(at,at+normal)*CFrame.Angles(0,0,turn)
	for petal=1,5 do
		local angle = (petal-1)*math.pi*2/5
		local petalCF = face*CFrame.Angles(0,0,angle)*CFrame.new(0,0.105,0)
		block(model,"FlowerPetal",V(0.125,0.17,0.065),base*petalCF,Color3.fromRGB(245,242,220),"StudsSmall")
	end
	block(model,"FlowerYellowCone",V(0.095,0.11,0.105),base*face*CFrame.new(0,0,-0.067),Color3.fromRGB(234,184,45),"StudsSmall")
end
local function flowers(model,base,top,later)
	local fork = top + V(0,0.20,0.09)
	twig(model,base,top,fork)
	local left = fork+V(-0.18,0.13,0.04)
	twig(model,base,fork,left)
	flower(model,base,left,0.16)
	if later then
		-- Decorative, non-edible potato berries only: no crop state, rewards,
		-- harvest target, or production recipe is added by this review fixture.
		local side = fork+V(-0.70,-0.35,0.90)
		twig(model,base,fork,side)
		local first = block(model,"DecorativeGreenBerry",V(0.29,0.30,0.29),base*CFrame.new(side+V(-0.11,-0.10,0)),Color3.fromRGB(132,169,70))
		local second = block(model,"DecorativeGreenBerry",V(0.27,0.28,0.27),base*CFrame.new(side+V(0.18,-0.13,0.04)),Color3.fromRGB(117,155,62))
		first.Shape, second.Shape = Enum.PartType.Ball, Enum.PartType.Ball
		model:SetAttribute("DecorativeBerryCount",2)
	else
		local right = fork+V(0.17,0.07,-0.02)
		twig(model,base,fork,right)
		flower(model,base,right,-0.25)
		model:SetAttribute("DecorativeBerryCount",0)
	end
	model:SetAttribute("DecorativeFlowerCount",if later then 1 else 2)
end
local studies = {
	{
		name="A - Bushy upright", tiers={0.38,0.77}, leafScale=1.30,
		shoots={V(-0.54,1.98,-0.15),V(0.51,2.13,-0.20),V(0.05,1.90,0.54)},
		shoulders={V(-0.57,0,0.46),V(0.55,0,0.60)},
	},
	{
		name="B - Open branching", tiers={0.28,0.55,0.84}, leafScale=1.25,
		shoots={V(-0.66,2.12,-0.12),V(0.62,2.04,0.13)},
		shoulders={V(-0.46,0,0.57),V(0.45,0,0.63)},
	},
	{
		name="C - Leaning upright", tiers={0.36,0.76}, leafScale=1.28,
		shoots={V(-0.67,1.86,-0.20),V(0.61,2.03,-0.32),V(0.55,1.91,0.51)},
		shoulders={V(-0.60,0,0.48),V(0.38,0,0.70)},
	},
}
local function drawStudy(parent,base,study)
	local model = Instance.new("Model")
	model.Name = study.name
	model:SetAttribute("StaticRipeStudy",true)
	for i,top in study.shoots do
		local origin = V((i-2)*0.08,0.08,0)
		local elbow = origin:Lerp(top,0.52)+V((if i%2==0 then -0.08 else 0.08),0,0.07)
		twig(model,base,origin,elbow)
		twig(model,base,elbow,top)
		local outward = V(top.X,0,top.Z).Unit
		for tier,fraction in study.tiers do
			local node = if fraction<=0.52 then origin:Lerp(elbow,fraction/0.52)
				else elbow:Lerp(top,(fraction-0.52)/0.48)
			local angle = (tier-1)*0.72 + (i-1)*0.18
			local radial = CFrame.Angles(0,angle,0):VectorToWorldSpace(outward)
			compoundPair(model,base,node,radial,study.leafScale*(if tier==1 then 1 else 0.91))
		end
		blade(model,base,top,outward*0.39+V(0,0.20,0),0.33,light)
	end
	for i,at in study.shoulders do shoulder(model,base,at,i*0.60) end
	flowers(model,base,study.shoots[2],study.name:sub(1,1)=="C")
	assert(#model:GetChildren()<=66,"Study part budget exceeded")
	model:SetAttribute("PartCount",#model:GetChildren())
	model.Parent=parent
end
local folder = Instance.new("Folder")
folder.Name = "PotatoRipeStudies"
local view = PlotView.new(slot,folder)
local cells = table.create(CropConfig.MaxSquares,"#0")
for i=1,12 do cells[i]=".0" end
cells[7]="a2"
view:SetState({name=player.DisplayName,incCount=1,eggs={},field={crops=table.concat(cells),pets={"Cat:3:review:11:1:1"}}})
view:SetDetail("full")
while view:Step(os.clock()+0.006) do task.wait() end
for i,study in studies do drawStudy(folder,view:SquareCFrame(7+i),study) end
local rings = workspace:FindFirstChild("FieldRings")
local template = rings and rings:FindFirstChildWhichIsA("BillboardGui",true)
if template then
	local attachment = Instance.new("Attachment")
	attachment.Parent=view.pieces.sq7:FindFirstChild("Soil7")
	attachment.WorldCFrame=view:SquareCFrame(7)
	local ring=template:Clone()
	ring.Adornee,ring.Enabled=attachment,true
	ring.Time.Visible=false
	ring.Disc.Inner.Icon.Text=CropConfig.ById.Potato.icon
	ring.Parent=attachment
end
folder:SetAttribute("ReviewSlot",slot)
folder.Parent=workspace
return folder:GetFullName()

-- Studio playtest, Client command context. Static ripe Potato design review only.
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
local soil = Color3.fromRGB(106, 76, 49)
local function block(model, name, size, cf, color, variant)
	local p = Instance.new("Part")
	p.Name, p.Size, p.CFrame, p.Color = name, size, cf, color
	p.Material, p.MaterialVariant = Enum.Material.Plastic, variant or "StudsSmall"
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
	p.Parent = model
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
local function shoot(model, base, a, b, outward, width)
	twig(model,base,a,b)
	local side = V(-outward.Z,0,outward.X).Unit
	blade(model,base,b,outward+side*0.30,width,green)
	blade(model,base,b,outward*-0.66-side*0.36+V(0,0.06,0),width*0.84,light)
end
local function shoulder(model,base,at,turn)
	-- Only the upper shoulder peeks through soil; the tuber body stays underground.
	local cf = base*CFrame.new(at)*CFrame.Angles(0,turn,0)
	block(model,"TuberShoulder",V(0.56,0.18,0.40),cf,tan)
	block(model,"TuberCrown",V(0.35,0.09,0.28),cf*CFrame.new(0,0.11,0),tan)
end
local studies = {
	{name="A - Low rosette", height=0.44, spread=0.64, blade=0.89, width=0.53, shoulders={V(0.46,0.04,0.60)}},
	{name="B - Tufted bush", height=1.01, spread=0.30, blade=0.70, width=0.57, shoulders={V(-0.50,0.04,0.49)}},
	{name="C - Mounded tubers", height=0.56, spread=0.55, blade=0.75, width=0.59, shoulders={V(-0.56,0.13,0.61),V(0.50,0.13,0.48)}, mound=true},
}
local function drawStudy(parent,base,study)
	local model = Instance.new("Model")
	model.Name = study.name
	model:SetAttribute("StaticRipeStudy",true)
	if study.mound then
		block(model,"SoilMound",V(1.75,0.16,1.40),base*CFrame.new(0,0.02,0),soil,"Studs")
		block(model,"SoilMoundTop",V(1.18,0.13,0.91),base*CFrame.new(0,0.14,-0.08),soil,"Studs")
	end
	for i=1,4 do
		local angle = (i-1)*math.pi/2 + math.rad(25)
		local radial = V(math.cos(angle),0,math.sin(angle))
		local h = study.height + (if i%2==0 then 0.12 else 0)
		shoot(model,base,V(0,0.10,0),radial*study.spread+V(0,h,0),radial*study.blade+V(0,0.08,0),study.width)
	end
	for i,at in study.shoulders do shoulder(model,base,at,i*0.45) end
	assert(#model:GetChildren()<=30,"Study part budget exceeded")
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

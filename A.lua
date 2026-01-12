--==================================================
-- KILL HUB FINAL - SCRIPT ÚNICO
--==================================================

-- SERVIÇOS
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ESTADOS
local enabled = false
local killing = false
local godMode = false
local targetPlayer = nil
local oldCFrame = nil

local spinConn
local healthConn

local allMode = false
local waitingAll = false
local allQueue = {}

local physics = {}

--==================================================
-- FUNÇÕES BÁSICAS
--==================================================

local function makeInvisible()
	if not LocalPlayer.Character then return end
	for _,v in pairs(LocalPlayer.Character:GetDescendants()) do
		if v:IsA("BasePart") then
			v.Transparency = 1
		end
	end
end

local function makeVisible()
	if not LocalPlayer.Character then return end
	for _,v in pairs(LocalPlayer.Character:GetDescendants()) do
		if v:IsA("BasePart") then
			v.Transparency = 0
		end
	end
end

--==================================================
-- GOD MODE
--==================================================

local function enableGod()
	local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
	if not hum then return end

	godMode = true
	hum.MaxHealth = math.huge
	hum.Health = hum.MaxHealth

	healthConn = hum.HealthChanged:Connect(function()
		if godMode then
			hum.Health = hum.MaxHealth
		end
	end)
end

local function disableGod()
	godMode = false
	if healthConn then healthConn:Disconnect() end

	local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
	if hum then
		hum.MaxHealth = 100
		hum.Health = 100
	end
end

--==================================================
-- ANTI FÍSICA (ANTI LANÇAMENTO)
--==================================================

local function lockPhysics(root)
	if physics.vel then physics.vel:Destroy() end
	if physics.ang then physics.ang:Destroy() end

	local bv = Instance.new("BodyVelocity")
	bv.MaxForce = Vector3.new(1e9,1e9,1e9)
	bv.Velocity = Vector3.zero
	bv.Parent = root

	local bav = Instance.new("BodyAngularVelocity")
	bav.MaxTorque = Vector3.new(1e9,1e9,1e9)
	bav.AngularVelocity = Vector3.new(0,50,0)
	bav.Parent = root

	physics.vel = bv
	physics.ang = bav
end

local function unlockPhysics()
	if physics.vel then physics.vel:Destroy() end
	if physics.ang then physics.ang:Destroy() end
	physics = {}
end

--==================================================
-- RESET TOTAL
--==================================================

local function resetAll()
	killing = false
	allMode = false
	waitingAll = false
	allQueue = {}

	if spinConn then spinConn:Disconnect() spinConn = nil end

	disableGod()
	unlockPhysics()
	makeVisible()

	if LocalPlayer.Character and oldCFrame then
		pcall(function()
			LocalPlayer.Character:PivotTo(oldCFrame)
		end)
	end

	if LocalPlayer.Character then
		local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
		if hum then
			Camera.CameraSubject = hum
		end
	end

	targetPlayer = nil
end

--==================================================
-- BUSCA POR NOME (INTELIGENTE)
--==================================================

local function findPlayerByNick(text)
	local matches = {}
	for _,p in pairs(Players:GetPlayers()) do
		if p ~= LocalPlayer and string.find(string.lower(p.Name), string.lower(text)) then
			table.insert(matches,p)
		end
	end
	if #matches == 1 then
		return matches[1]
	end
	return nil
end

--==================================================
-- START KILL
--==================================================

local function startKill()
	if killing or not targetPlayer then return end
	killing = true

	local char = LocalPlayer.Character
	if not char then resetAll() return end

	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then resetAll() return end

	enableGod()
	oldCFrame = char:GetPivot()
	makeInvisible()
	lockPhysics(root)

	Camera.CameraSubject = targetPlayer.Character:FindFirstChild("Humanoid")

	spinConn = RunService.Heartbeat:Connect(function()
		if not killing then return end
		if targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
			root.CFrame =
				targetPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0,0,2)
		else
			resetAll()
		end
	end)

	local th = targetPlayer.Character and targetPlayer.Character:FindFirstChild("Humanoid")
	if th then
		th.Died:Connect(function()
			resetAll()
			if allMode then
				task.wait(0.4)
				if #allQueue > 0 then
					targetPlayer = table.remove(allQueue,1)
					startKill()
				end
			end
		end)
	end
end

--==================================================
-- MODO ALL
--==================================================

local function buildAllQueue()
	allQueue = {}
	for _,p in pairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then
			table.insert(allQueue,p)
		end
	end
end

--==================================================
-- GUI
--==================================================

local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "KillHub"

local button = Instance.new("TextButton", gui)
button.Size = UDim2.new(0.18,0,0.08,0)
button.Position = UDim2.new(0.41,0,0.02,0)
button.Text = "OFF"
button.BackgroundColor3 = Color3.fromRGB(170,0,0)
button.TextColor3 = Color3.new(1,1,1)
button.Font = Enum.Font.SourceSansBold
button.TextScaled = true

local box = Instance.new("TextBox", gui)
box.Size = UDim2.new(0.35,0,0.08,0)
box.Position = UDim2.new(0.325,0,0.45,0)
box.PlaceholderText = "nick kill"
box.Visible = false
box.BackgroundColor3 = Color3.fromRGB(100,100,100)
box.BackgroundTransparency = 0.4
box.TextColor3 = Color3.new(1,1,1)
box.TextScaled = true

--==================================================
-- EVENTOS
--==================================================

button.MouseButton1Click:Connect(function()
	enabled = not enabled
	button.Text = enabled and "ON" or "OFF"
	button.BackgroundColor3 = enabled and Color3.fromRGB(0,170,0) or Color3.fromRGB(170,0,0)
	box.Visible = enabled

	if not enabled then
		box.Text = ""
		resetAll()
	end
end)

box:GetPropertyChangedSignal("Text"):Connect(function()
	if not enabled then return end

	local text = string.lower(box.Text)
	resetAll()

	if #text < 2 then return end

	-- MODO ALL
	if text == "all" then
		waitingAll = true

		task.delay(4,function()
			if waitingAll and string.lower(box.Text) == "all" then
				allMode = true
				buildAllQueue()
				if #allQueue > 0 then
					targetPlayer = table.remove(allQueue,1)
					startKill()
				end
			end
		end)
		return
	end

	waitingAll = false

	local found = findPlayerByNick(text)
	if found then
		targetPlayer = found
		startKill()
	end
end)

--==================================================
-- RESPAWN SAFETY
--==================================================

LocalPlayer.CharacterAdded:Connect(function()
	task.wait(0.5)
	resetAll()
end)

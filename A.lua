--// SERVIÇOS
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--// VARIÁVEIS
local enabled = false
local killing = false
local targetPlayer = nil
local oldCFrame = nil
local tpConnection, spinConnection
local godMode = false
local healthConn

--// GUI
local gui = Instance.new("ScreenGui")
gui.Name = "KillHub"
gui.Parent = game.CoreGui

--// LOADING
local loadFrame = Instance.new("Frame", gui)
loadFrame.Size = UDim2.new(0.4,0,0.15,0)
loadFrame.Position = UDim2.new(0.3,0,0.4,0)
loadFrame.BackgroundColor3 = Color3.fromRGB(20,20,20)

local loadText = Instance.new("TextLabel", loadFrame)
loadText.Size = UDim2.new(1,0,0.4,0)
loadText.BackgroundTransparency = 1
loadText.TextColor3 = Color3.new(1,1,1)
loadText.Font = Enum.Font.SourceSansBold
loadText.TextScaled = true

local barBg = Instance.new("Frame", loadFrame)
barBg.Position = UDim2.new(0.05,0,0.6,0)
barBg.Size = UDim2.new(0.9,0,0.2,0)
barBg.BackgroundColor3 = Color3.fromRGB(50,50,50)

local bar = Instance.new("Frame", barBg)
bar.Size = UDim2.new(0,0,1,0)
bar.BackgroundColor3 = Color3.fromRGB(0,170,0)

for i = 0,100 do
	loadText.Text = "LOAD "..i.."%"
	bar.Size = UDim2.new(i/100,0,1,0)
	task.wait(0.08)
end
loadFrame:Destroy()

--// BOTÃO ON/OFF
local button = Instance.new("TextButton", gui)
button.Size = UDim2.new(0.18,0,0.08,0)
button.Position = UDim2.new(0.41,0,0.02,0)
button.Text = "OFF"
button.BackgroundColor3 = Color3.fromRGB(170,0,0)
button.TextColor3 = Color3.new(1,1,1)
button.Font = Enum.Font.SourceSansBold
button.TextScaled = true

--// BOTÃO BUG
local bugButton = Instance.new("TextButton", gui)
bugButton.Size = UDim2.new(0.14,0,0.08,0)
bugButton.Position = UDim2.new(0.60,0,0.02,0)
bugButton.Text = "BUG"
bugButton.BackgroundColor3 = Color3.fromRGB(0,120,255)
bugButton.TextColor3 = Color3.new(1,1,1)
bugButton.Font = Enum.Font.SourceSansBold
bugButton.TextScaled = true

--// TEXTBOX
local box = Instance.new("TextBox", gui)
box.Size = UDim2.new(0.35,0,0.08,0)
box.Position = UDim2.new(0.325,0,0.45,0)
box.PlaceholderText = "nick kill"
box.Visible = false
box.BackgroundColor3 = Color3.fromRGB(100,100,100)
box.BackgroundTransparency = 0.4
box.TextColor3 = Color3.new(1,1,1)
box.Font = Enum.Font.SourceSans
box.TextScaled = true

--// GOD MODE
local function enableGod()
	local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
	if not hum then return end
	godMode = true
	hum.MaxHealth = math.huge
	hum.Health = hum.MaxHealth
	healthConn = hum.HealthChanged:Connect(function()
		if godMode then hum.Health = hum.MaxHealth end
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

--// FUNÇÕES
local function makeVisible()
	if LocalPlayer.Character then
		for _,v in pairs(LocalPlayer.Character:GetDescendants()) do
			if v:IsA("BasePart") then
				v.Transparency = 0
			end
		end
	end
end

local function makeInvisible()
	if LocalPlayer.Character then
		for _,v in pairs(LocalPlayer.Character:GetDescendants()) do
			if v:IsA("BasePart") then
				v.Transparency = 1
			end
		end
	end
end

local function resetAll()
	killing = false
	disableGod()
	if tpConnection then tpConnection:Disconnect() end
	if spinConnection then spinConnection:Disconnect() end
	if LocalPlayer.Character and oldCFrame then
		LocalPlayer.Character:PivotTo(oldCFrame)
	end
	makeVisible()
	Camera.CameraSubject = LocalPlayer.Character:FindFirstChild("Humanoid")
	targetPlayer = nil
end

local function findPlayerByNick(text)
	local matches = {}
	for _,p in pairs(Players:GetPlayers()) do
		if string.find(string.lower(p.Name), string.lower(text)) then
			table.insert(matches,p)
		end
	end
	if #matches ~= 1 then return nil end
	return matches[1]
end

local function startKill()
	if killing then return end
	killing = true

	local char = LocalPlayer.Character
	if not char then return end

	enableGod()
	oldCFrame = char:GetPivot()
	makeInvisible()

	Camera.CameraSubject = targetPlayer.Character:FindFirstChild("Humanoid")

	spinConnection = RunService.Heartbeat:Connect(function()
		if not killing then return end
		char.HumanoidRootPart.RotVelocity = Vector3.new(0,999999,0)
	end)

	tpConnection = RunService.Heartbeat:Connect(function()
		if not killing then return end
		if targetPlayer and targetPlayer.Character then
			char.HumanoidRootPart.CFrame =
				targetPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0,0,3)
		end
	end)
end

--// EVENTOS
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
	resetAll()
	if #box.Text < 2 then return end
	local found = findPlayerByNick(box.Text)
	if found then
		targetPlayer = found
		startKill()
	end
end)

bugButton.MouseButton1Click:Connect(function()
	bugButton.BackgroundColor3 = Color3.fromRGB(170,0,0)

	-- mata a aba
	if gui then
		gui:Destroy()
	end

	-- reseta personagem
	LocalPlayer:LoadCharacter()

	-- espera 4 segundos
	task.wait(4)

	-- recria o hub
	StartKillHub()
end)

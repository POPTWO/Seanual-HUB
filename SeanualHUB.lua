getgenv().autoOrbsEnabled = true
getgenv().autoRebirthEnabled = true
getgenv().autoClickEnabled = true
getgenv().autoBuyEnabled = true
getgenv().autoUpgradeEnabled = true
getgenv().infiniteJumpEnabled = true
getgenv().setTradingEnabled = true
getgenv().AimbotEnabled = true


function MDR1()
	task.spawn(function()
-- Bot Settings
getgenv().AimSens = 1/45; -- Aimbot sens
getgenv().LookSens = 1/80; -- Aim while walking sens
getgenv().PreAimDis = 55; -- if within 55 Studs then preaim
getgenv().KnifeOutDis = 85; -- if within 85 Studs then swap back to gun
getgenv().ReloadDis = 50; -- if over 50 Studs away then reload
getgenv().RecalDis = 15; -- if player moves over this many studs then recalculate path to them

-- Services
local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService('TweenService');
local VIM = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")

-- Local Plr
local Plr = Players.LocalPlayer
local Char = Plr.Character or Plr.CharacterAdded:Wait()
local Head = Char:WaitForChild("Head", 1337)
local Root = Char:WaitForChild("HumanoidRootPart", 1337)
local Humanoid = Char:WaitForChild("Humanoid", 1337)

-- error bypass
for i,v in pairs(getconnections(game:GetService("ScriptContext").Error)) do v:Disable() end

-- Simple ESP
loadstring(game:HttpGet("https://raw.githubusercontent.com/Babyhamsta/RBLX_Scripts/main/Universal/SimpleESP.lua", true))()

-- Aimbot Vars
local Camera = workspace.CurrentCamera;

-- Mouse
local Mouse = Plr:GetMouse();

-- Map Spawns
local Spawns = workspace:WaitForChild("Map", 1337):WaitForChild("Spawns", 1337)

-- Ignore
local Map = workspace:WaitForChild("Map", 1337)
local RayIgnore = workspace:WaitForChild("Ray_Ignore", 1337)
local MapIgnore = Map:WaitForChild("Ignore", 1337)

-- Temp Vars
local ClosestPlr;
local IsAiming;
local InitialPosition;
local CurrentEquipped = "Gun";
local WalkToObject;

-- Get Closest plr
local function getClosestPlr()
	local nearestPlayer, nearestDistance
	for _, player in pairs(Players:GetPlayers()) do
		if player.TeamColor ~= Plr.TeamColor and player ~= Plr then
			local character = player.Character
			if character then
				local nroot = character:FindFirstChild("HumanoidRootPart")
				if character and nroot and character:FindFirstChild("Spawned") then
					local distance = Plr:DistanceFromCharacter(nroot.Position)
					if (nearestDistance and distance >= nearestDistance) then continue end
					nearestDistance = distance
					nearestPlayer = player
				end
			end
		end
	end
	return nearestPlayer
end

-- Wallcheck / Visible Check
local function IsVisible(target, ignorelist)
	local obsParts = Camera:GetPartsObscuringTarget({target}, ignorelist);
	
	if #obsParts == 0 then
		return true;
	else
		return false;
	end
end

-- Aimbot/Triggerbot
local function Aimlock()
	-- Temp Holder
	local aimpart = nil;
	
	-- Detect first visible part
	if ClosestPlr and ClosestPlr.Character then
		for i,v in ipairs(ClosestPlr.Character:GetChildren()) do
			if v and v:IsA("Part") then -- is part
				if IsVisible(v.Position,{Camera,Char,ClosestPlr.Character,RayIgnore,MapIgnore}) then -- is visible
					aimpart = v;
					break;
				end
			end
		end
	end
	
	-- If visible aim and shoot
	if aimpart then
		IsAiming = true;
		-- Aim at player
		local tcamcframe = Camera.CFrame;
		for i = 0, 1, AimSens do
			if not aimpart then break; end
			if (Head.Position.Y + aimpart.Position.Y) < 0 then break; end -- Stop bot from aiming at the ground
			Camera.CFrame = tcamcframe:Lerp(CFrame.new(Camera.CFrame.p, aimpart.Position), i)
			task.wait(0)
		end
		
		-- Mouse down and back up
		VIM:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, true, game, 1)
		task.wait(0.25)
		VIM:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, false, game, 1)
	end
	
	IsAiming = false;
end

local function OnPathBlocked()
   -- try again
   warn("[AimmyAI] - Path was blocked, trying again.")
   WalkToObject();
end

-- Pathfinding to Plr function
WalkToObject = function()
	if ClosestPlr and ClosestPlr.Character then
		-- RootPart
		local CRoot = ClosestPlr.Character:FindFirstChild("HumanoidRootPart")
		if CRoot then
			-- Get start position
			InitialPosition = CRoot.Position;
			
			-- Calculate path and waypoints
			local currpath = PathfindingService:CreatePath({["WaypointSpacing"] = 4, ["AgentHeight"] = 5, ["AgentRadius"] = 3, ["AgentCanJump"] = true});
			
			-- Listen for block connect
			currpath.Blocked:Connect(OnPathBlocked)
			
			local success, errorMessage = pcall(function()
				currpath:ComputeAsync(Root.Position, CRoot.Position)
			end)
			if success and currpath.Status == Enum.PathStatus.Success then
				local waypoints = currpath:GetWaypoints();
				
				-- Navigate to each waypoint
				for i, wap in pairs(waypoints) do
					-- Catcher
					if i == 1 then continue end -- skip first waypoint
					if not ClosestPlr or not ClosestPlr.Character or ClosestPlr ~= getClosestPlr() or not ClosestPlr.Character:FindFirstChild("Spawned") or not Char:FindFirstChild("Spawned") then
						ClosestPlr = nil;
						return;
					elseif (InitialPosition - CRoot.Position).Magnitude > RecalDis  then -- moved too far from start
						WalkToObject(); -- restart
						return;
					end

					-- Detect if needing to jump
					if wap.Action == Enum.PathWaypointAction.Jump then
						Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
					end

					-- Aim while walking (either path or plr)
					task.spawn(function()
						local primary = ClosestPlr.Character.PrimaryPart.Position;
						local studs = Plr:DistanceFromCharacter(primary)
						
						local tcamcframe = Camera.CFrame;
						for i = 0, 1, LookSens do
							if IsAiming then break; end
							if primary and studs then
								-- If close aim at player
								if math.floor(studs + 0.5) < PreAimDis then
									if ClosestPlr and ClosestPlr.Character then
										local CChar = ClosestPlr.Character;
										if Char:FindFirstChild("Head") and CChar and CChar:FindFirstChild("Head") then
											local MiddleAim = (Vector3.new(wap.Position.X,Char.Head.Position.Y,wap.Position.Z) + Vector3.new(CChar.Head.Position.X,CChar.Head.Position.Y,CChar.Head.Position.Z))/2;
											Camera.CFrame = tcamcframe:Lerp(CFrame.new(Camera.CFrame.p, MiddleAim), i);
										end
									end
								else -- else aim at waypoint
									local mixedaim = (Camera.CFrame.p.Y + Char.Head.Position.Y)/2;
									Camera.CFrame = tcamcframe:Lerp(CFrame.new(Camera.CFrame.p, Vector3.new(wap.Position.X,mixedaim,wap.Position.Z)), i);
								end
							end
							task.wait(0)
						end
					end)
					
					-- Auto Knife out (for faster running and realism)
					task.spawn(function()
						local primary = ClosestPlr.Character.PrimaryPart.Position;
						local studs = Plr:DistanceFromCharacter(primary)
						
						if primary and studs then
							local arms = Camera:FindFirstChild("Arms");
							if arms then
								arms = arms:FindFirstChild("Real");
								if math.floor(studs + 0.5) > KnifeOutDis and not IsVisible(primary, {Camera,Char,ClosestPlr.Character,RayIgnore,MapIgnore}) then
									if arms.Value ~= "Knife" and CurrentEquipped == "Gun" then
										VIM:SendKeyEvent(true, Enum.KeyCode.Q, false, game);
										CurrentEquipped = "Knife";
									end
								elseif arms.Value == "Knife" and CurrentEquipped ~= "Gun" then
									VIM:SendKeyEvent(true, Enum.KeyCode.Q, false, game);
									CurrentEquipped = "Gun";
								end
							end
						end
					end)
					
					-- Move to Waypoint
					if Humanoid then
						Humanoid:MoveTo(wap.Position);
						Humanoid.MoveToFinished:Wait(); -- Wait for us to get to Waypoint
					end
				end
			else
				-- Can't find path, move to a random spawn.
				warn("[AimmyAI] - Unable to calculate path!");
			end
		end
	end
end

-- Walk to the Plr
local function WalkToPlr()
	-- Get Closest Plr
	ClosestPlr = getClosestPlr();
	
	-- Walk to Plr
	if ClosestPlr and ClosestPlr.Character and ClosestPlr.Character:FindFirstChild("HumanoidRootPart") then
		if Humanoid.WalkSpeed > 0 and Char:FindFirstChild("Spawned") and ClosestPlr.Character:FindFirstChild("Spawned") then
			--Create ESP
			local studs = Plr:DistanceFromCharacter(ClosestPlr.Character.PrimaryPart.Position)
			SESP_Create(ClosestPlr.Character.Head, ClosestPlr.Name, "TempTrack", Color3.new(1, 0, 0), math.floor(studs + 0.5));
			
			-- Auto Reload (if next plr is far enough and out of site)
			if math.floor(studs + 0.5) > ReloadDis and not IsVisible(ClosestPlr.Character.HumanoidRootPart.Position, {Camera,Char,ClosestPlr.Character,RayIgnore,MapIgnore}) then
				VIM:SendKeyEvent(true, Enum.KeyCode.R, false, game)
			end
			
			-- AI Walk to Plr
			WalkToObject(ClosestPlr.Character.HumanoidRootPart);
		end
	else
		--RandomWalk();
	end
end

-- Loop Pathfind
task.spawn(function()
	while task.wait() do
		if (ClosestPlr == nil or ClosestPlr ~= getClosestPlr()) then
			SESP_Clear("TempTrack");
			WalkToPlr();
		end
	end
end)

-- Loop Aimlock
task.spawn(function()
	while task.wait() do
		if ClosestPlr ~= nil and Camera then
			if Char:FindFirstChild("Spawned") and Humanoid.WalkSpeed > 0 then
				Aimlock();
			end
		end
	end
end)

-- Detect Stuck Bot
local stuckamt = 0;
Humanoid.Running:Connect(function(speed)
	if speed < 3 and Char:FindFirstChild("Spawned") and Humanoid.WalkSpeed > 0 then
		stuckamt = stuckamt + 1;
		if stuckamt == 4 then
			-- Double jump
			Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		elseif stuckamt >= 10 then
			stuckamt = 0;
			-- Clear and redo path
			SESP_Clear("TempTrack");
			WalkToPlr();
		end
	end
end)
end)
end



function MDR2()
	task.spawn(function()
		local ReplicatedStorage = game:GetService("ReplicatedStorage")
		local Players = game:GetService("Players")
		local RunService = game:GetService("RunService")
		local LP = Players.LocalPlayer
		local roles
		
		-- > Functions <--
		
		function CreateHighlight() -- make any new highlights for new players
			for i, v in pairs(Players:GetChildren()) do
				if v ~= LP and v.Character and not v.Character:FindFirstChild("Highlight") then
					Instance.new("Highlight", v.Character)           
				end
			end
		end
		
		function UpdateHighlights() -- Get Current Role Colors (messy)
			for _, v in pairs(Players:GetChildren()) do
				if v ~= LP and v.Character and v.Character:FindFirstChild("Highlight") then
					Highlight = v.Character:FindFirstChild("Highlight")
					if v.Name == Sheriff and IsAlive(v) then
						Highlight.FillColor = Color3.fromRGB(0, 0, 225)
					elseif v.Name == Murder and IsAlive(v) then
						Highlight.FillColor = Color3.fromRGB(225, 0, 0)
					elseif v.Name == Hero and IsAlive(v) and not IsAlive(game.Players[Sheriff]) then
						Highlight.FillColor = Color3.fromRGB(255, 250, 0)
					else
						Highlight.FillColor = Color3.fromRGB(0, 225, 0)
					end
				end
			end
		end	
		
		function IsAlive(Player) -- Simple sexy function
			for i, v in pairs(roles) do
				if Player.Name == i then
					if not v.Killed and not v.Dead then
						return true
					else
						return false
					end
				end
			end
		end
		
		
		-- > Loops < --
		
		RunService.RenderStepped:connect(function()
			roles = ReplicatedStorage:FindFirstChild("GetPlayerData", true):InvokeServer()
			for i, v in pairs(roles) do
				if v.Role == "Murderer" then
					Murder = i
				elseif v.Role == 'Sheriff'then
					Sheriff = i
				elseif v.Role == 'Hero'then
					Hero = i
				end
			end
			CreateHighlight()
			UpdateHighlights()
		end)
	end)

end


function POPTWO()
	task.spawn(function()
loadstring(game:HttpGet('https://raw.githubusercontent.com/POPTWO/Seanual-HUB/main/1.txt'))()
	end)
end

function Aimbot()
	task.spawn(function()
		repeat task.wait() until game:IsLoaded()
if not hookmetamethod then game.Players.LocalPlayer:Kick('your exploit is not supported') end

local players = game:GetService('Players')
local RunService = game:GetService('RunService')
local Teams = game:GetService('Teams')
local user_input_service = game:GetService('UserInputService')
local workspace = game:GetService('Workspace')

local camera = workspace.CurrentCamera
local wtvp = camera.WorldToViewportPoint
local localplayer = players.LocalPlayer

local function indexExists(object, index)
    local _, value = pcall(function() return object[index] end)
    return value
end

local function get_character(player) return indexExists(player, 'Character') end

local function get_mouse_location() return user_input_service:GetMouseLocation() end

local function is_alive(player) return player.Character and player.Character:FindFirstChild('Humanoid') and player.Character:FindFirstChild('Humanoid').Health > 0 end
local function is_team(player) return #Teams:GetChildren() > 0 and player.Team == localplayer.Team end

local function getClosestPlayerToCursor(fov)

    local maxDistance = fov or math.huge

    local closestPlayer = nil
    local closestPlayerDistance = math.huge

    for _, player in pairs(players:GetPlayers()) do

        if player ~= localplayer and not is_team(player) and get_character(player) and is_alive(player) then
            local pos, on_screen = wtvp(camera, get_character(player).Head.Position)

            if not on_screen then continue end

            local distance = (get_mouse_location() - Vector2.new(pos.X, pos.Y)).magnitude

            if distance <= maxDistance and distance < closestPlayerDistance then
                closestPlayer = player
                closestPlayerDistance = distance
            end
        end
    end

    return closestPlayer
end

shared.fov = 400
local circle = Drawing.new('Circle')
circle.Thickness = 2
circle.NumSides = 12
circle.Radius = shared.fov or 400
circle.Filled = false
circle.Transparency = 1
circle.Color = Color3.new(1, 0, 0.384313)
circle.Visible = true
local target = nil
RunService.Heartbeat:Connect(function(deltaTime)
    task.wait(deltaTime ^ 2)
    target = getClosestPlayerToCursor(shared.fov)
    circle.Position = get_mouse_location()
end)

local OldNamecall
OldNamecall = hookmetamethod(workspace, '__namecall', newcclosure(function(...)
    local args = { ... }
    local method = string.lower(getnamecallmethod())
    local caller = getcallingscript()
    if method == 'findpartonraywithwhitelist' and tostring(caller) == 'First Person Controller' then

        local HitPart = target and target.Character and target.Character.Head or nil
        if HitPart then
            local Origin = HitPart.Position + Vector3.new(0, 5, 0)
            local Direction = (HitPart.Position - Origin)
            args[2] = Ray.new(Origin, Direction)

            return OldNamecall(unpack(args))
        else
            return OldNamecall(...)
        end
    end
    return OldNamecall(...)
end))
end)
end



function walkSpeed(speed)
    game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = speed
end


function autoRebirth()
	task.spawn(function() 
		while wait() do
			if not autoRebirthEnabled then break end
			game:GetService("ReplicatedStorage").Remotes.Rebirth:FireServer()
		end
	end)
end



function autoBuy(egg)
	task.spawn(function()
		while wait() do
			if not autoBuyEnabled then break end
			game:GetService("ReplicatedStorage").Remotes.CanBuyEgg:InvokeServer(egg)
		end
	end)
end

function autoUpgrade(egg)
	listEgg = {"", "D", "G", "E", "R"}
	while wait() do
		if not autoUpgradeEnabled then break end
		for i,v in pairs(listEgg) do
			newEgg = egg..v
			game:GetService("ReplicatedStorage").Remotes.UpgradePet:FireServer(newEgg)
		end
	end
end

function setTrading()
	local enabled = "Off"
	if setTradingEnabled then enabled = "On" end
	game:GetService("ReplicatedStorage").Remotes.EnableTrading:FireServer(enabled)
end



-------------------------------------------------------------------------------------------


function TP1()
	task.spawn(function()
		game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-357.528992, 72.1782074, 481.868622, -0.150605321, 0, 0.988593936, 0, 1, 0, -0.988593936, 0, -0.150605321)
    end)
end

function TP2()
	task.spawn(function()
		game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-358.084015, 90.5001755, 529.388, -1, 0, 0, 0, 1, 0, 0, 0, -1)
    end)
end

function TP3()
	task.spawn(function()
		game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-129.150635, 70.2929993, 798.731384, 0.669109941, -0, -0.743163466, 0, 1, -0, 0.743163466, 0, 0.669109941)
    end)
end

function TP4()
	task.spawn(function()
		game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(210.564117, 68.2201385, 764.895691, 0.15644598, 0, 0.987686574, 0, 1, 0, -0.987686574, 0, 0.15644598)
    end)
end

function TP5()
	task.spawn(function()
		game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-134.686737, 69.8866959, 191.914948, 1, 0, 0, 0, 1, 0, 0, 0, 1)
    end)
end

function TP6()
	task.spawn(function()
		game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(142.211899, 70.3590927, 277.606812, 0, 0, 1, 0, 1, -0, -1, 0, 0)
    end)
end

function TP7()
	task.spawn(function()
		game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-367.709686, 70.4865494, 293.057068, 1, 0, 0, 0, 1, 0, 0, 0, 1)
    end)
end

function TP7()
	task.spawn(function()
		game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-198.573181, 67.2704468, 265.765106, 0.707134247, 0, 0.707079291, 0, 1, 0, -0.707079291, 0, 0.707134247)
    end)
end

function TP8()
	task.spawn(function()
		game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-709.731628, 190.591721, -166.829651, -0.979230046, 0.00010348903, -0.202752486, -0.00353825511, 0.999838889, 0.0175989848, 0.20272164, 0.0179508459, -0.979071975)
    end)
end



function autoClick()
    task.spawn(function()
        while wait(0.001) do
            if not autoClickEnabled then break end
            game:GetService("ReplicatedStorage").Remotes.Click:FireServer()
        end
    end)
end


function NoClip()
	task.spawn(function()
		local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart

local function isDescendantOfTerrain(part)
    local terrain = game.Workspace.Terrain
    return terrain and terrain:IsAncestorOf(part)
end

local noClipEnabled = false

local switch = Instance.new("BoolValue")
switch.Name = "เปิดเดินทะลุอยู่"
switch.Parent = player

switch:GetPropertyChangedSignal("Value"):Connect(function()
    noClipEnabled = switch.Value
end)

local gui = Instance.new("ScreenGui")
gui.Name = "NoClipGui"
gui.Parent = game.CoreGui

local button = Instance.new("TextButton")
button.Name = "NoClipButton"
button.Text = "กดแล้วพ่อตาย"
button.Size = UDim2.new(0, 200, 0, 50)
button.Position = UDim2.new(0.5, -100, 0.9, -25)
button.BackgroundTransparency = 0
button.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
button.BorderColor3 = Color3.new(0, 0, 0)
button.TextColor3 = Color3.new(1, 1, 1)
button.Font = Enum.Font.SourceSans
button.TextSize = 24
button.TextWrapped = true
button.ClipsDescendants = true
button.AutoButtonColor = false
button.Parent = gui

button.MouseButton1Click:Connect(function()
    switch.Value = not switch.Value
    button.Text = "เดินทะลุ: " .. (switch.Value and "ON" or "OFF")
    button.BackgroundColor3 = switch.Value and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
end)

game:GetService("RunService").Stepped:Connect(function()
    if noClipEnabled then
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") and not isDescendantOfTerrain(part) then
                part.CanCollide = false
            end
        end
    end
end)
end)
end





function infiniteJump()
	task.spawn(function()
		local character = game.Players.LocalPlayer.Character
		local humanoid = character:FindFirstChild("Humanoid")
		while true do
			if not infiniteJumpEnabled then break end
			if humanoid.Jump and humanoid.FloorMaterial == Enum.Material.Air then
				humanoid.JumpPower = 50
				humanoid:ChangeState("Jumping")
			end
			wait()
		end
	end)
end



function TPAutoFramA()
		
			game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-60.7853699, 28.0049992, -326.502686, 0, -1, 0, 1, 0, -0, 0, 0, 1)
			game.Players.LocalPlayer.Character.HumanoidRootPart.Anchored = false
	    end
   



function AutoFramA()
	while wait() do 
		game:GetService("ReplicatedStorage").RemoteEvents.GeneralAttack:FireServer()
		end
	end




function AutoFram1()
	task.spawn(function()
		_G.Farm = true
function CheckQuest()
   local Lv = game.Players.LocalPlayer.Data.Level.Value
    if Lv == 1 or Lv <= 999 then
    Ms = "Bandit [Lv. 5]"
    NM = "Bandit"
    LQ = 1
    NQ = "BanditQuest1"
    CQ = CFrame.new(1389.74451, 88.1519318, -1298.90796, -0.342042685, 0, 0.939684391, 0, 1, 0, -0.939684391, 0, -0.342042685)
    end
end


function TP(P)
    Distance = (P.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
    if Distance < 10 then
        Speed = 1000
    elseif Distance < 170 then
        game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = P
        Speed = 350
    elseif Distance < 1000 then
        Speed = 350
    elseif Distance >= 1000 then
        Speed = 300
    end
    game:GetService("TweenService"):Create(
        game.Players.LocalPlayer.Character.HumanoidRootPart,
        TweenInfo.new(Distance/Speed, Enum.EasingStyle.Linear),
        {CFrame = P}
    ):Play()
end

spawn(function()
   while task.wait() do
       if _G.Farm then
           CheckQuest()
           if game:GetService("Players").LocalPlayer.PlayerGui.Main.Quest.Visible == false then
                TP(CQ)
                wait(0.9)
                game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("StartQuest",NQ,LQ)
                elseif game:GetService("Players").LocalPlayer.PlayerGui.Main.Quest.Visible == true then
                    for i,v in pairs(game:GetService("Workspace").Enemies:GetChildren()) do
                        if v.Name == Ms then
                        TP(v.HumanoidRootPart.CFrame * CFrame.new(0,20,0))
                        v.HumanoidRootPart.Size = Vector3.new(60,60,60)
                    end
                end
            end
        end
    end
end)
end)
end

function bringmob1()
	task.spawn(function()
		_G.bringmob = true
		while _G.bringmob do wait()
			pcall(function()
		for i,v in pairs(game:GetService("Workspace").Enemies:GetChildren()) do
		for x,y in pairs(game:GetService("Workspace").Enemies:GetChildren()) do
		if v.Name == "Bandit [Lv. 5]" then
			if y.Name == "Bandit [Lv. 5]" then
		   v.HumanoidRootPart.CFrame = y.HumanoidRootPart.CFrame
		   v.HumanoidRootPart.Size = Vector3.new(60,60,60)
		   y.HumanoidRootPart.Size = Vector3.new(60,60,60)
		   v.HumanoidRootPart.Transparency = 1
		   v.HumanoidRootPart.CanCollide = false
		   y.HumanoidRootPart.CanCollide = false
		   v.Humanoid.WalkSpeed = 0
		   y.Humanoid.WalkSpeed = 0
		   v.Humanoid.JumpPower = 0
		   y.Humanoid.JumpPower = 0
		   if sethiddenproperty then
			 sethiddenproperty(game.Players.LocalPlayer, "SimulationRadius", math.huge)
		end
		end
		end
		end
		end
		end)
		end
 end)	
end	


function FastAttack()
	task.spawn(function() 
		local CombatFramework = require(game:GetService("Players").LocalPlayer.PlayerScripts.CombatFramework)
    local Camera = require(game.ReplicatedStorage.Util.CameraShaker)
    Camera:Stop()
    coroutine.wrap(function()
        game:GetService("RunService").Stepped:Connect(function()
            if getupvalues(CombatFramework)[2]['activeController'].timeToNextAttack then
                getupvalues(CombatFramework)[2]['activeController'].timeToNextAttack = 0
                getupvalues(CombatFramework)[2]['activeController'].hitboxMagnitude = 25
                getupvalues(CombatFramework)[2]['activeController']:attack()
            end
        end)
    end)()
end)
end

function autoOrbs()
	task.spawn(function()
		local character = game.Players.LocalPlayer.Character
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")

		while wait() do
			if not autoOrbsEnabled then break end
			for i,v in pairs(game:GetService("Workspace").OrbSpawns:GetChildren()) do
				firetouchinterest(humanoidRootPart, v, 0)
			end
		end
	end)
end

function AutoHop(player)
	task.spawn(function() 
	local PlaceID = game.PlaceId
	local AllIDs = {}
	local foundAnything = ""
	local actualHour = os.date("!*t").hour
	local Deleted = false
	function TPReturner()
		local Site;
		if foundAnything == "" then
			Site = game.HttpService:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/' .. PlaceID .. '/servers/Public?sortOrder=Asc&limit=100'))
		else
			Site = game.HttpService:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/' .. PlaceID .. '/servers/Public?sortOrder=Asc&limit=100&cursor=' .. foundAnything))
		end
		local ID = ""
		if Site.nextPageCursor and Site.nextPageCursor ~= "null" and Site.nextPageCursor ~= nil then
			foundAnything = Site.nextPageCursor
		end
		local num = 0;
		for i,v in pairs(Site.data) do
			local Possible = true
			ID = tostring(v.id)
			if tonumber(v.maxPlayers) > tonumber(v.playing) then
				for _,Existing in pairs(AllIDs) do
					if num ~= 0 then
						if ID == tostring(Existing) then
							Possible = false
						end
					else
						if tonumber(actualHour) ~= tonumber(Existing) then
							local delFile = pcall(function()
								AllIDs = {}
								table.insert(AllIDs, actualHour)
							end)
						end
					end
					num = num + 1
				end
				if Possible == true then
					table.insert(AllIDs, ID)
					wait()
					pcall(function()
						wait()
						game:GetService("TeleportService"):TeleportToPlaceInstance(PlaceID, ID, game.Players.LocalPlayer)
					end)
					wait(4)
				end
			end
		end
	end
	function Teleport() 
		while wait() do
			pcall(function()
				TPReturner()
				if foundAnything ~= "" then
					TPReturner()
				end
			end)
		end
	end
	Teleport()
end)                   

function isnil(thing)
	return (thing == nil)
end
local function round(n)
	return math.floor(tonumber(n) + 0.5)
end
Number = math.random(1, 1000000)


end




function teleportTo(player)    
	local localPlayer = game.Players.LocalPlayer
	localPlayer.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame  
	wait()        
end



		
local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()
local Window = OrionLib:MakeWindow({Name = "Seanual HUB BETA", HidePremium = false, SaveConfig = true, ConfigFolder = "SpeedRunSimulator", IntroText = "Seanual HUB"})


local Auto = Window:MakeTab({
	Name = "ฟังชั้นใช้ได้เกือบทุกแมพ",
	Icon = "rbxassetid://259820115",
	PremiumOnly = false
})



Auto:AddButton({
	Name = "ออโต้คลิ้กใช้ได้ทุกแมพ ",
	Callback = function()
		autoClick()
	end
})


Auto:AddButton({
	Name = "เดินทะลุ ใช้ได้ทุกแมพ",
	Callback = function()
		NoClip()
	end
})



Auto:AddButton({
	Name = "Hop ใช้ได้ทุกแมพ",
	Callback = function()
		AutoHop(player)
	end
})


Auto:AddSlider({
	Name = "วิ่งไว ใช้ได้ทุกแมพ",
	Min = 32,
	Max = 600,
	Default = 32,
	Color = Color3.fromRGB(51, 204, 51),
	Increment = 1,
	ValueName = "Walk Speed",
	Callback = function(Value)
		walkSpeed(Value)
	end    
})



local TeleportTo = Window:MakeTab({
	Name = "Teleport Player",
	Icon = "rbxassetid://259820115",
	PremiumOnly = false
})

TeleportTo:AddSection({
	Name = "Teleport To A Player"
})

for i, player in ipairs(game.Players:GetPlayers()) do
	TeleportTo:AddButton({
		Name = player.Name,
		Callback = function()
			teleportTo(player)
		end
	})
end





---Demon Soul Simulator

local GAY = Window:MakeTab({
	Name = "MAP Demon Soul Simulator ",
	Icon = "rbxassetid://259820115",
	PremiumOnly = false
})

GAY:AddButton({
	Name = "ตีออโต้ MAP Demon Soul Simulator",
	Callback = function()
		AutoFramA()
	  end    
})

GAY:AddButton({
	Name = "วาปไปตีมอนAFK MAP Demon Soul Simulator",
	Callback = function()
		TPAutoFramA()
	  end    
})


---BLOXFRUIT


local NARAK = Window:MakeTab({
	Name = "MAP BLOXFRUIT ",
	Icon = "rbxassetid://259820115",
	PremiumOnly = false
})


NARAK:AddButton({
	Name = "ตีออโต้ MAP BLOXFRU",
	Callback = function()
		FastAttack()
	  end    
})

NARAK:AddButton({
	Name = "ดึงม่อนเกาะ1 MAP BLOXFR",
	Callback = function()
		bringmob1()
	  end    
})

NARAK:AddButton({
	Name = "ฟามม่อนเกาะ1 MAP BLOXFRU",
	Callback = function()
		AutoFram1()
	  end    
})



---MAP Speed Run Simulator ⚡

local NAHEE = Window:MakeTab({
	Name = " Speed Run Simulator ",
	Icon = "rbxassetid://259820115",
	PremiumOnly = false
})



NAHEE:AddToggle({
	Name = "ปั้มสปีดแบบชิวๆ (Only Synapse X) MAP Speed Run Simulator ⚡",
	Callback = function()
		autoOrbsEnabled = not autoOrbsEnabled
		autoOrbs()
	  end    
})


NAHEE:AddToggle({
	Name = "Auto Buy Eggs",
	Callback = function()
		autoBuyEnabled = not autoBuyEnabled
	  end    
})


NAHEE:AddDropdown({
	Name = "ซื้อไข่กี่ใบไอเอ๋อ",
	Default = "EggOne",
	Options = {"EggOne","EggTwo","EggThree", "EggFour", "EggFive", "EggSix", "EggSeven", "EggEight", "EggNine", "EggTen", "EggEleven"},
	Callback = function(value)
		autoBuy(value)
	end    
})

NAHEE:AddToggle({
	Name = "Auto อัพไข่เอง",
	Callback = function()
		autoUpgradeEnabled = not autoUpgradeEnabled
	  end    
})

NAHEE:AddDropdown({
	Name = "อัพเกตเองไอควาย",
	Default = "Phoenix",
	Options = {'Baby Chick', 'Cat', 'Chicken', 'Cloud', 'Cow', 'Cupid', 'Detective', 'Dragon', 'Elf', 'Fire Bunny', 'Fire King', 'Giraffe', 'Gnome', 'Horse', 'Ice Bat', 'Ice King', 'Mummy', 'Officer', 'Pharaoh', 'Phoenix', 'Pig', 'Piggy', 'Plant', 'Professor', 'Santa', 'Satan', 'Scorpion', 'Skeleton', 'Troll', 'Vampire', 'Wizard', 'Yeti'},
	Callback = function(value)
		autoUpgrade(value)
	end    
})


------------------------------------------------------
Auto:AddToggle({
	Name = "กระโดดไม่จำกัด  ใช้ได้ทุกแมพ ⚡",
	Callback = function()
		infiniteJumpEnabled = not infiniteJumpEnabled
            infiniteJump()
	  end    
})
------------------------------------------------------

----🌺City BanNa🌼

local AB = Window:MakeTab({
	Name = "🌺City BanNa🌼",
	Icon = "rbxassetid://259820115",
	PremiumOnly = false
})

AB:AddButton({
	Name = "TP ปล้น1⚡",
	Callback = function()
		TP1()
	  end    
})


AB:AddButton({
	Name = "TP ปล้น2⚡",
	Callback = function()
		TP2()
	  end    
})


AB:AddButton({
	Name = "TP ปล้น3⚡",
	Callback = function()
		TP3()
	  end    
})


AB:AddButton({
	Name = "TP ปล้น4⚡",
	Callback = function()
		TP4()
	  end    
})

AB:AddButton({
	Name = "TP ปล้น5⚡",
	Callback = function()
		TP5()
	  end    
})


AB:AddButton({
	Name = "TP ปล้น6⚡",
	Callback = function()
		TP6()
	  end    
})


AB:AddButton({
	Name = "TP ปล้น7⚡",
	Callback = function()
		TP7()
	  end    
})


AB:AddButton({
	Name = "TP หนีตรชิวๆ⚡",
	Callback = function()
		TP8()
	  end    
})

----------------------------------------------------------------------

local AC = Window:MakeTab({
	Name = "BIG Paintball!🔫",
	Icon = "rbxassetid://259820115",
	PremiumOnly = false
})


AC:AddButton({
	Name = "ยิงทะลุโลกทีเดียวจอด",
	Callback = function()
		Aimbot()
	  end    
})

----------------------------------------------------------------------------

local BB = Window:MakeTab({
	Name = "วาปไปหาคนแบบค้าง",
	Icon = "rbxassetid://259820115",
	PremiumOnly = false
})

BB:AddButton({
	Name = "วาปไปหาคนแบบค้าง",
	Callback = function()
		POPTWO()
	  end    
})

----------------------------------------------------------------------------

local AZB = Window:MakeTab({
	Name = "Murder Mystery 2",
	Icon = "rbxassetid://259820115",
	PremiumOnly = false
})

AZB:AddButton({
	Name = "ESP มองหาไครเป็นอะไรบ้าง",
	Callback = function()
		MDR2()
	  end    
})

AZB:AddSection({
	Name = "Murder Red  Sheriff Blue Hero Yellow Gold  Innocent Green",
	Callback = function()
	  end    
})

-------------------------------------------------------------------------------------

local AZA = Window:MakeTab({
	Name = " Arsenal",
	Icon = "rbxassetid://259820115",
	PremiumOnly = false
})

AZB:AddButton({
	Name = "ออโต้ BOT ยิงให้เอง",
	Callback = function()
		MDR1()
	  end    
})
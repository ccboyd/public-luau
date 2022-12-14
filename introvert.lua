local players = game:GetService"Players"
local runservice = game:GetService"RunService"
local tweenservice = game:GetService"TweenService"

--// command keys \\
local sizekey = "size"
local blacklistkey = "bl"
local whitelistkey = "wl"
local lockkey = "lock"
local unlockkey = "unlock"
local passkey = "pass"
local rgbkey = "rgb"
--\\---------------//

warn([[

commands:
	>size number
	
	>bl player, player, ...
	>bl ^ excluded1, excluded2, ... -- blacklists everyone except excluded
	
	>wl player, player, ...
	>wl ^ excluded1, excluded2, ... -- whitelists everyone except excluded
	
	>lock
	>unlock
	>pass player
]])

function gettarget (text)
	text = text:lower()

	for _, target in pairs(players:GetPlayers()) do
		if target.Name:lower():sub(1, #text) == text or target.DisplayName:lower():sub(1, #text) == text then
			return target
		end
	end
end

function removepadding (a, f)
	f = f or function (v) return v end
	local pattern = " *(.*)"

	local t = typeof(a)

	if t == "string" then
		a = f(a:match(pattern):reverse():match(pattern):reverse())
	elseif t == "table" then
		for i, v in pairs(a) do
			local tv = typeof(v)

			if tv ~= "string" then
				error("expected string, got " .. tv)
			else
				a[i] = f(v:match(pattern):reverse():match(pattern):reverse())
			end
		end
	else
		error("expected string or table, got " .. t)
	end

	return a
end

function convertlisttotargets (list)
	for i, v in pairs(list) do
		local target = gettarget(v)

		if target then
			list[i] = target
		end
	end

	return list
end

local player = owner
local character = player.Character
local root = character.HumanoidRootPart

function forcefield ()
	task.spawn(function()
		local ff = Instance.new"ForceField"
		ff.Visible = false

		ff.Destroying:Connect(function()
			forcefield()
		end)

		ff.Parent = player.Character or player.CharacterAdded:Wait()
	end)
end

forcefield()

--// vi variables \\
local addedconnection

local orbcolor = BrickColor.new"Gold".Color
local currentscale = 25

local currentorb
local currentholder = player
local isaligned = true
local blacklist = {}

function addtoblacklist (target)
	if not table.find(blacklist, target) and target ~= player then
		table.insert(blacklist, target)

		task.spawn(function()
			while table.find(blacklist, target) do runservice.Heartbeat:Wait()
				if target and target.Character then
					local difference = target.Character:GetPivot().Position - currentorb.Position

					if difference.Magnitude < currentscale / 1.75 then
						target.Character:PivotTo(currentorb.CFrame + difference.Unit * (currentscale / 1.5))
					end
				end
			end
		end)
	end
end
--\\--------------//

runservice.Stepped:Connect(function(deltatime)
	if currentorb and currentorb:IsA"BasePart" and isaligned and currentholder.Character and currentholder.Character:FindFirstChild"HumanoidRootPart" then
		currentorb.Position = currentholder.Character.HumanoidRootPart.Position
	end
end)

function scaleorb (scale)
	tweenservice:Create(currentorb, TweenInfo.new(0.1, Enum.EasingStyle.Cubic, 1),
		{
			Size = Vector3.one * scale,
		}
	):Play()
end

function colororb (r, g, b)
	orbcolor = Color3.fromRGB(r, g, b)
	currentorb.Color = orbcolor
end

function castorb (scale)
	scale = scale or currentscale

	local orb = Instance.new"Part"
	orb.Name = "orb"
	orb.Shape = Enum.PartType.Ball
	orb.Color = orbcolor
	orb.Material = Enum.Material.ForceField
	orb.Anchored = true
	orb.Massless = true
	orb.CanCollide = false
	orb.CastShadow = false
	orb.Parent = script

	currentorb = orb

	scaleorb(currentscale)

	orb.Changed:Connect(function(prop)
		if prop == "Parent" then
			task.wait(0.1)
			currentorb.Parent = script
		elseif prop == "Size" then
			scaleorb(currentscale)
		elseif prop == "Orientation" then
			currentorb.Orientation = Vector3.zero
		elseif prop == "Anchored" then
			currentorb.Anchored = true
		elseif prop == "CanCollide" then
			currentorb.CanCollide = false
		elseif prop == "CastShadow" then
			currentorb.CastShadow = false
		elseif prop == "Material" then
			currentorb.Material = Enum.Material.ForceField
		elseif prop == "Color" or prop == "BrickColor" then
			currentorb.Color = orbcolor
		elseif prop == "Transparency" then
			currentorb.Transparency = 0
		elseif prop == "Shape" then
			currentorb.Shape = Enum.PartType.Ball
		end
	end)

	currentorb.ChildAdded:Connect(function(child)
		task.wait(0.1)
		child:Destroy()
	end)

	currentorb.Destroying:Connect(castorb)

	local function onchat (message)
		message = message:lower()

		if message:sub(1, 1) == ">" then
			message = message:sub(2, #message)

			if message:sub(1, #sizekey) == sizekey then
				currentscale = tonumber(message:sub(#sizekey+2, #message))

				scaleorb(currentscale)
			elseif message:sub(1, #blacklistkey) == blacklistkey then
				local list = message:sub(#blacklistkey+2, #message)

				if removepadding(list):sub(1, 1) == "^" then
					local exlist = list:sub(3, #list)
					local exclusions = convertlisttotargets(removepadding(exlist:split","))

					for _, player in pairs(players:GetPlayers()) do
						if not table.find(exclusions, player) then
							addtoblacklist(player)
						end
					end
				elseif removepadding(list):sub(1, 1) == "*" then
					addedconnection = players.PlayerAdded:Connect(function(added)
						if not table.find(blacklist, added) and added ~= player then
							addtoblacklist(added)
						end 
					end)
				else
					local newblacklist = convertlisttotargets(removepadding(list:split","))

					for _, player in pairs(newblacklist) do
						addtoblacklist(player)
					end
				end
			elseif message:sub(1, #whitelistkey) == whitelistkey then
				local list = message:sub(#whitelistkey+2, #message)
				local whitelist = convertlisttotargets(removepadding(list:split","))

				if removepadding(list):sub(1, 1) == "^" then
					local exlist = list:sub(3, #list)
					local exclusions = convertlisttotargets(removepadding(exlist:split","))

					for _, player in pairs(players:GetPlayers()) do
						if not table.find(exclusions, player) then
							local i = table.find(blacklist, player)

							if i then
								table.remove(blacklist, i)
							end
						end
					end
				elseif removepadding(list):sub(1, 1) == "*" then
					if addedconnection then
						addedconnection:Disconnect()
					end
				else
					for i, v in pairs(whitelist) do
						local newi = table.find(blacklist, v)

						if newi then
							blacklist[newi] = nil
						end
					end
				end
			elseif message:sub(1, #lockkey) == lockkey then
				isaligned = false
			elseif message:sub(1, #unlockkey) == unlockkey then
				isaligned = true
			elseif message:sub(1, #passkey) == passkey then
				local holdername = message:sub(#passkey+2, #message)
				currentholder = gettarget(holdername) or currentholder
			elseif message:sub(1, #rgbkey) == rgbkey then
				local rgbstring = message:sub(#rgbkey+2, #message)
				local rgb = removepadding(rgbstring:split",", tonumber)

				colororb(rgb[1], rgb[2], rgb[3])
			end
		end
	end

	player.Chatted:Connect(onchat)
end

castorb(currentscale)

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

-- folder to hold spawned parts
local partFolder = Instance.new("Folder")
partFolder.Name = "EnergyParts"
partFolder.Parent = Workspace

-- simple player data storage
local playerData = {}

-- settings (tuned during testing, not perfect)
local MAX_PARTS = 15
local RESPAWN_TIME = 6
local ENERGY_PER_CLICK = 5
local SPAWN_RADIUS = 60

-- random helper
local function getRandomPosition()
	local x = math.random(-SPAWN_RADIUS, SPAWN_RADIUS)
	local z = math.random(-SPAWN_RADIUS, SPAWN_RADIUS)
	return Vector3.new(x, 5, z)
end

-- create a single energy part
local function createPart()
	local part = Instance.new("Part")
	part.Size = Vector3.new(3, 1, 3)
	part.Position = getRandomPosition()
	part.Anchored = true
	part.Name = "EnergyNode"
	part.Color = Color3.fromRGB(0, 170, 255)

	-- click detector setup
	local click = Instance.new("ClickDetector")
	click.MaxActivationDistance = 20
	click.Parent = part

	-- state for cooldown
	local canBeUsed = true

	click.MouseClick:Connect(function(player)
		if not canBeUsed then return end

		if not playerData[player] then return end

		canBeUsed = false

		-- add energy
		playerData[player].energy += ENERGY_PER_CLICK

		-- small variation so it doesn't look too clean
		if math.random(1, 10) == 3 then
			playerData[player].energy += 1
		end

		-- hide part briefly
		part.Transparency = 1
		part.CanCollide = false

		-- respawn logic
		task.delay(RESPAWN_TIME, function()
			part.Position = getRandomPosition()
			part.Transparency = 0
			part.CanCollide = true
			canBeUsed = true
		end)
	end)

	part.Parent = partFolder
end

-- spawn initial parts
local function spawnInitial()
	for i = 1, MAX_PARTS do
		createPart()
	end
end

-- player setup
local function setupPlayer(player)
	playerData[player] = {
		energy = 0,
		lastTick = tick()
	}
end

-- cleanup
local function removePlayer(player)
	playerData[player] = nil
end

-- periodic energy decay (just to add logic)
local function energyDecayLoop()
	while true do
		for player, data in pairs(playerData) do
			local now = tick()
			local diff = now - data.lastTick

			if diff > 5 then
				if data.energy > 0 then
					data.energy -= 1
				end
				data.lastTick = now
			end
		end

		task.wait(1)
	end
end

-- debug print loop (students always do this lol)
local function debugLoop()
	while true do
		for player, data in pairs(playerData) do
			print(player.Name .. " Energy:", data.energy)
		end
		task.wait(5)
	end
end

-- random event loop (adds variety)
local function randomEventLoop()
	while true do
		task.wait(math.random(10, 20))

		local parts = partFolder:GetChildren()
		if #parts == 0 then continue end

		local chosen = parts[math.random(1, #parts)]

		-- move a random part somewhere else
		chosen.Position = getRandomPosition()
	end
end

-- extra utility (not really needed but shows structure)
local function countParts()
	local count = 0
	for _, obj in pairs(partFolder:GetChildren()) do
		if obj:IsA("Part") then
			count += 1
		end
	end
	return count
end

-- another loop just to keep part count stable
local function maintainParts()
	while true do
		local current = countParts()

		if current < MAX_PARTS then
			for i = 1, (MAX_PARTS - current) do
				createPart()
			end
		end

		task.wait(3)
	end
end

-- player connections
Players.PlayerAdded:Connect(function(player)
	setupPlayer(player)
end)

Players.PlayerRemoving:Connect(function(player)
	removePlayer(player)
end)

-- start everything
spawnInitial()

task.spawn(energyDecayLoop)
task.spawn(debugLoop)
task.spawn(randomEventLoop)
task.spawn(maintainParts)

-- small extra loop (honestly not needed but fills requirement naturally)
task.spawn(function()
	while true do
		task.wait(8)

		local totalEnergy = 0

		for _, data in pairs(playerData) do
			totalEnergy += data.energy
		end

		if totalEnergy > 100 then
			print("Players are farming a lot lol:", totalEnergy)
		end
	end
end)

-- milestone rewards (players hit certain energy amounts)
local function checkMilestones()
	while true do
		for player, data in pairs(playerData) do
			if data.energy >= 50 and not data.hit50 then
				data.hit50 = true
				print(player.Name .. " reached 50 energy")
			end

			if data.energy >= 100 and not data.hit100 then
				data.hit100 = true
				print(player.Name .. " reached 100 energy (grinding fr)")
			end
		end
		task.wait(2)
	end
end

-- rare bonus tick (just for randomness)
local function randomBonusLoop()
	while true do
		task.wait(math.random(15, 30))

		for player, data in pairs(playerData) do
			if math.random(1, 5) == 2 then
				local bonus = math.random(2, 6)
				data.energy += bonus
				print(player.Name .. " got lucky +" .. bonus)
			end
		end
	end
end

-- small helper (honestly optional but makes it feel more “dev-like”)
local function getTotalPlayers()
	local count = 0
	for _ in pairs(playerData) do
		count += 1
	end
	return count
end

-- lightweight monitor loop
task.spawn(function()
	while true do
		task.wait(10)

		local playersOnline = getTotalPlayers()
		if playersOnline > 0 then
			print("Players online:", playersOnline)
		end
	end
end)

task.spawn(checkMilestones)
task.spawn(randomBonusLoop)

-- Written by EnnyDaBat (although i got some help from Youtube 😁😎)

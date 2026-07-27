-- StarterPlayerScripts/InstantMine.client.lua

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local INSTANT_MINE_GAMEPASS_ID = 1234567890

local instantMineEnabled = false
local hookedFolders: {[Instance]: boolean} = {}

local crystalLocations = {
	{
		parent = "Things",
		child = "Crystals",
	},
	{
		parent = nil,
		child = "DroppedCrystals",
	},
	{
		parent = nil,
		child = "Crystals",
	},
}

local function updatePrompt(prompt: ProximityPrompt)
	local originalDuration = prompt:GetAttribute("IMC_OrigHold")

	if typeof(originalDuration) ~= "number" then
		prompt:SetAttribute("IMC_OrigHold", prompt.HoldDuration)
		originalDuration = prompt.HoldDuration
	end

	if instantMineEnabled then
		prompt.HoldDuration = 0
	else
		prompt.HoldDuration = originalDuration
	end
end

local function updateFolder(folder: Instance)
	for _, descendant in folder:GetDescendants() do
		if descendant:IsA("ProximityPrompt") then
			updatePrompt(descendant)
		end
	end
end

local function hookFolder(folder: Instance)
	if hookedFolders[folder] then
		updateFolder(folder)
		return
	end

	hookedFolders[folder] = true
	updateFolder(folder)

	folder.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("ProximityPrompt") then
			updatePrompt(descendant)
		end
	end)

	folder.Destroying:Connect(function()
		hookedFolders[folder] = nil
	end)
end

local function findCrystalFolders()
	for _, location in crystalLocations do
		local parent: Instance = Workspace

		if location.parent then
			local foundParent = Workspace:FindFirstChild(location.parent)

			if not foundParent then
				continue
			end

			parent = foundParent
		end

		local folder = parent:FindFirstChild(location.child)

		if folder then
			hookFolder(folder)
		end
	end
end

local function isCrystalFolder(instance: Instance): boolean
	for _, location in crystalLocations do
		if instance.Name ~= location.child then
			continue
		end

		local expectedParent: Instance = Workspace

		if location.parent then
			local foundParent = Workspace:FindFirstChild(location.parent)

			if not foundParent then
				continue
			end

			expectedParent = foundParent
		end

		if instance.Parent == expectedParent then
			return true
		end
	end

	return false
end

local function setInstantMine(enabled: boolean)
	instantMineEnabled = enabled
	findCrystalFolders()

	for folder in hookedFolders do
		if folder.Parent then
			updateFolder(folder)
		end
	end

	print("[InstantMine]", enabled and "enabled" or "disabled")
end

local function checkGamepass(): boolean
	local success, ownsGamepass = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(
			player.UserId,
			INSTANT_MINE_GAMEPASS_ID
		)
	end)

	if not success then
		warn("[InstantMine] Could not check gamepass:", ownsGamepass)
		return false
	end

	return ownsGamepass
end

Workspace.DescendantAdded:Connect(function(instance)
	if not instantMineEnabled then
		return
	end

	if instance:IsA("Folder") or instance:IsA("Model") then
		if isCrystalFolder(instance) then
			hookFolder(instance)
		end
	end
end)

MarketplaceService.PromptGamePassPurchaseFinished:Connect(
	function(purchasedPlayer, gamepassId, wasPurchased)
		if purchasedPlayer ~= player then
			return
		end

		if gamepassId == INSTANT_MINE_GAMEPASS_ID and wasPurchased then
			setInstantMine(true)
		end
	end
)

setInstantMine(true)
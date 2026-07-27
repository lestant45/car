-- NoHoldPickup.client.lua

local Workspace = game:GetService("Workspace")

local function isCrystalPrompt(prompt: ProximityPrompt): boolean
	if prompt.ObjectText == "Crystal" then
		return true
	end

	local current: Instance? = prompt.Parent

	while current and current ~= Workspace do
		if string.find(string.lower(current.Name), "crystal", 1, true) then
			return true
		end

		current = current.Parent
	end

	return false
end

local function patchPrompt(instance: Instance)
	if not instance:IsA("ProximityPrompt") then
		return
	end

	if not isCrystalPrompt(instance) then
		return
	end

	if typeof(instance:GetAttribute("OriginalHoldDuration")) ~= "number" then
		instance:SetAttribute("OriginalHoldDuration", instance.HoldDuration)
	end

	instance.HoldDuration = 0
	instance.Enabled = true

	print("[NoHoldPickup] patched:", instance:GetFullName())
end

for _, instance in Workspace:GetDescendants() do
	patchPrompt(instance)
end

Workspace.DescendantAdded:Connect(function(instance)
	patchPrompt(instance)
end)

print("[NoHoldPickup] ready")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RagdollSystem = require(
	ReplicatedStorage
		:WaitForChild("RagdollSystemPackage")
		:WaitForChild("RagdollSystem")
)

local function disableRagdoll()
	local ragdoll = RagdollSystem:getLocalRagdoll()

	if not ragdoll then
		return
	end

	if ragdoll:isRagdolled() then
		ragdoll:deactivateRagdollPhysics()

		pcall(function()
			RagdollSystem.Remotes.DeactivateRagdoll:FireServer()
		end)
	end
end

RagdollSystem.Signals.ActivateLocalRagdoll:Connect(function()
	task.defer(disableRagdoll)
end)

RagdollSystem.Signals.ActivateRagdoll:Connect(function(character)
	local players = game:GetService("Players")
	local player = players.LocalPlayer

	if character == player.Character then
		task.defer(disableRagdoll)
	end
end)

RagdollSystem.Signals.CollapseLocalRagdoll:Connect(function()
	task.defer(disableRagdoll)
end)

RagdollSystem.Signals.CollapseRagdoll:Connect(function(character)
	local players = game:GetService("Players")
	local player = players.LocalPlayer

	if character == player.Character then
		task.defer(disableRagdoll)
	end
end)

task.spawn(function()
	while task.wait(0.1) do
		disableRagdoll()
	end
end)

print("[NoRagdoll] always-off controller ready")
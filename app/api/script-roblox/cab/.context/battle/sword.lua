local Event = game:GetService("ReplicatedStorage").Brainrot.Battle.Server.Send
Event:InvokeServer(
    "1441",
    1,
    (function(bytes) --[[Type: buffer]]
        local b = buffer.create(#bytes)
        for i = 1, #bytes do
            buffer.writeu8(b, i - 1, bytes[i])
        end
        return b
    end)({ 4, 0, 3 })
)
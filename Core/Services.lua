--[[
    BaoSaveInstance API Framework
    File: Core/Services.lua
    Description: Roblox Services Container
]]

local Services = {}

-- Cache all services
Services.Players = game:GetService("Players")
Services.Workspace = game:GetService("Workspace")
Services.Lighting = game:GetService("Lighting")
Services.ReplicatedStorage = game:GetService("ReplicatedStorage")
Services.ReplicatedFirst = game:GetService("ReplicatedFirst")
Services.StarterGui = game:GetService("StarterGui")
Services.StarterPack = game:GetService("StarterPack")
Services.StarterPlayer = game:GetService("StarterPlayer")
Services.SoundService = game:GetService("SoundService")
Services.Chat = game:GetService("Chat")
Services.Teams = game:GetService("Teams")
Services.RunService = game:GetService("RunService")
Services.HttpService = game:GetService("HttpService")
Services.TweenService = game:GetService("TweenService")
Services.UserInputService = game:GetService("UserInputService")
Services.CoreGui = game:GetService("CoreGui")
Services.MaterialService = game:GetService("MaterialService")
Services.InsertService = game:GetService("InsertService")
Services.MarketplaceService = game:GetService("MarketplaceService")
Services.TeleportService = game:GetService("TeleportService")
Services.CollectionService = game:GetService("CollectionService")
Services.PhysicsService = game:GetService("PhysicsService")
Services.Debris = game:GetService("Debris")
Services.TextService = game:GetService("TextService")
Services.LocalizationService = game:GetService("LocalizationService")

-- Get local player
Services.LocalPlayer = Services.Players.LocalPlayer

-- Get service safely
function Services.Get(serviceName)
    if Services[serviceName] then
        return Services[serviceName]
    end
    
    local success, service = pcall(function()
        return game:GetService(serviceName)
    end)
    
    if success then
        Services[serviceName] = service
        return service
    end
    
    return nil
end

-- Check if service exists
function Services.Exists(serviceName)
    return Services.Get(serviceName) ~= nil
end

return Services
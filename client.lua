--- globals ---
local i


--- functions ---
function SpawnVehicle(coords)
    local hash = GetHashKey("trash")
    RequestModel(hash)
    while not HasModelLoaded(hash) do
        RequestModel(hash)
        Citizen.Wait(0)
    end
    return CreateVehicle(hash, coords.x,coords.y,coords.z,coords.h,true,false)
end

function SelectRoute()
    i = 1
    local src = source
    local rand = math.random(1,6)
    local route = Garbage.routes[rand]
    return route
end

function CreateRouteBlip(lastblip,coords)
    if lastblip ~= nil then
        RemoveBlip(lastblip)
    end
    local blip = AddBlipForCoord(coords)
    SetBlipSprite(blip, 304)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 1.0)
    SetBlipColour(blip, 5)
    SetBlipAsShortRange(blip, true)
	BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('Dumpster')
    EndTextCommandSetBlipName(blip)
    return blip
end
--- Events ---
RegisterNetEvent("fd_garbage:SpawnVehicle")
AddEventHandler("fd_garbage:SpawnVehicle", function(coords)
    local ped = PlayerPedId()
    local truck = SpawnVehicle(coords)
    SetPedIntoVehicle(ped,truck,-1)
end)

--- Threads ---
-- On and Offduty Zones --
Citizen.CreateThread(function()
    local sleep = 1000
    while true do
        for i=1, #Garbage.SignOnAndOff do
            local ped = PlayerPedId()
            local pedPos = GetEntityCoords(ped)
            local distance = Vdist(pedPos.x, pedPos.y, pedPos.z, Garbage.SignOnAndOff[i].x, Garbage.SignOnAndOff[i].y, Garbage.SignOnAndOff[i].z)
            if distance <= 5.0 then
                sleep = 10
                exports["drp_core"]:DrawText3Ds(Garbage.SignOnAndOff[i].x, Garbage.SignOnAndOff[i].y, Garbage.SignOnAndOff[i].z,tostring("~b~[E]~w~ to sign on duty or ~r~[X]~w~ to sign off duty"))
            end
            if IsControlJustPressed(1, 86) then
                TriggerServerEvent("fd_garbage:ToggleDuty", false)
            elseif IsControlJustPressed(1, 73) then
                TriggerServerEvent("fd_garbage:ToggleDuty", true)
            end
        end
        Citizen.Wait(sleep)
    end
end)
-- Garage Zones --
Citizen.CreateThread(function()
    local sleepTimer=1000
    while true do
        for a=1, #Garbage.Garages do
            local ped = PlayerPedId()
            local pedPos = GetEntityCoords(ped)
            local distance = Vdist(pedPos.x,pedPos.y,pedPos.z, Garbage.Garages[a].x, Garbage.Garages[a].y, Garbage.Garages[a].z)
            if distance <= 5.0 then
               sleepTimer = 10
               exports['drp_core']:DrawText3Ds(Garbage.Garages[a].x, Garbage.Garages[a].y, Garbage.Garages[a].z, tostring("~b~[E]~w~ to spawn a garbage truck ~r~[X]~w~ to delete your truck"))
               if IsControlJustPressed(1,86) then
                TriggerServerEvent("fd_garbage:SpawnVehicle",Garbage.CarSpawns[a])
                SelectRoute()
               elseif IsControlJustPressed(1,73) then
                DeleteVehicle(GetVehiclePedIsIn(ped,true))
                TriggerServerEvent("fd_garbage:payOut")
               end
            end
        end
        Citizen.Wait(sleepTimer)
    end
end)
-- Blips --
Citizen.CreateThread(function()
    local blip = AddBlipForCoord(vector3(-454, -1704.25, 19))
    SetBlipSprite(blip, 318)
	BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('Landfill')
    EndTextCommandSetBlipName(blip)
    SetBlipAsShortRange(blip,true)
end)
-- Route Tracking --
Citizen.CreateThread(function ()
    local sleep = 1000
    while true do
        local ped = PlayerPedId()
        local pedPos = GetEntityCoords(ped)
        local distance = GetDistanceBetweenCoords(ped,route[i])
        if distance <= 4.0 then
            i = i+1
        end
        Citizen.Wait(sleep)
    end
end)
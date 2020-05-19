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
    local rand = math.random(1,5)
    local route = Garbage.Routes[rand]
    return route
end

function CreateRouteBlip(lastblip,coords)
    if lastblip ~= nil then
        RemoveBlip(lastblip)
    end
    local blip = AddBlipForCoord(coords)
    SetBlipSprite(blip, 1)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 1.0)
    SetBlipColour(blip, 5)
    SetBlipRoute(blip,true)
    SetBlipAsShortRange(blip, true)
	BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('Dumpster')
    EndTextCommandSetBlipName(blip)
    return blip
end

function DrivingRoute(blip,route)
    local lastblip,ped,pedPos,distance
    local a = 1
    if a < #route then
        Citizen.Wait(1000)
        lastblip=CreateRouteBlip(blip,route[a])
        ped = PlayerPedId()
        pedPos = GetEntityCoords(ped)
        distance = GetDistanceBetweenCoords(pedPos,route[a])
        while distance > 5 do
            Citizen.Wait(1000)
            ped = PlayerPedId()
            pedPos = GetEntityCoords(ped)
            distance = GetDistanceBetweenCoords(pedPos,route[a])
            print(distance)
        end
        TriggerEvent("DRP_Core:Info","Waste Management",tostring("Proceed to the next point on the route"),4500,true,"leftCenter")
        a = a + 1
        DrivingRoute(lastblip,route)
    end
    TriggerEvent("DRP_Core:Info","Waste Management",tostring("Head back to the landfill and return your truck to receive your pay"),4500,true,"leftCenter")
    lastblip=AddBlipForCoord(Garbage.Garages.x,Garbage.Garages.y,Garbage.Garages.z)
    SetBlipSprite(lastblip, 1)
    SetBlipDisplay(lastblip, 4)
    SetBlipScale(lastblip, 1.0)
    SetBlipColour(lastblip, 5)
    SetBlipRoute(lastblip,true)
    SetBlipAsShortRange(lastblip, true)
	BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('Landfill')
    EndTextCommandSetBlipName(lastblip)
    ped = PlayerPedId()
    pedPos = GetEntityCoords(ped)
    distance = GetDistanceBetweenCoords(pedPos,route[a])
    while distance > 5 and GetVehiclePedIsIn(ped,false) ~= 0 do
        Citizen.Wait(1000)
        ped = PlayerPedId()
        pedPos = GetEntityCoords(ped)
        distance = GetDistanceBetweenCoords(pedPos,route[a])
        print(distance)
    end
    TriggerServerEvent("fd_garbage:PayOut",route)

    -- if blip == nil then
    --     lastblip=CreateRouteBlip(blip,route[i])
    --     local ped = PlayerPedId()
    --     local pedPos = GetEntityCoords(ped)
    --     local distance = GetDistanceBetweenCoords(ped,route[i])
    --     while distance > 5.0 do
    --         Citizen.Wait(0)
    --         ped = PlayerPedId()
    --         pedPos = GetEntityCoords(ped)
    --         distance = GetDistanceBetweenCoords(ped,route[i])
    --         print(distance)
    --     end
    --     nextblip=CreateRouteBlip(lastblip,route[i])
    --     DrivingRoute(nextblip,route)
    --     i = i + 1
    -- else
    --     while route[i+1] ~= nil and lastblip ~= nil do
    --         Citizen.Wait(0)
    --         lastblip=CreateRouteBlip(blip,route[i])
    --         local ped = PlayerPedId()
    --         local pedPos = GetEntityCoords(ped)
    --         local distance = GetDistanceBetweenCoords(ped,route[i])
    --         if distance <= 5.0 and route[i+1]~=nil then
    --             print("Next Blip should be drawn")
    --             i = i+1
    --             nextblip=CreateRouteBlip(lastblip,route[i])
    --             DrivingRoute(nextblip,route)
    --         end
    --     end
    -- end
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
                local route = SelectRoute()
                DrivingRoute(nil,route)
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
--- globals ---
local i,truck,aipartner,aiontruck,bag


--- functions ---
function SpawnVehicle(coords)
    local hash = GetHashKey("trash")
    RequestModel(hash)
    while not HasModelLoaded(hash) do
        RequestModel(hash)
        Citizen.Wait(0)
    end
    local newCar = CreateVehicle(hash, coords.x,coords.y,coords.z,coords.h,true,false)
    exports["drp_LegacyFuel"]:SetFuel(newCar,100)
    return newCar
end

function SpawnPartner()
    local hash
    local num = GetRandomIntInRange(1, 2)
    if num == 1 then 
        hash = "s_m_y_garbage"
    elseif num == 2 then
        hash = "s_m_m_gardener_01" 
    end
    RequestModel(hash)
    while not HasModelLoaded(hash) do
        RequestModel(hash)
        Citizen.Wait(0)
    end
    aipartner = CreatePed(4,hash,Garbage.SignOnAndOff[1].x,Garbage.SignOnAndOff[1].y,Garbage.SignOnAndOff[1].z,0.0,false,true)
    TriggerEvent("DRP_Core:Info","Waste Management",tostring("Wait for your coworker to get on the truck before beginning your route"),4500,false,"leftCenter")
end

function AiGetOnTruck(bool, coords)
    if bool and not DoesEntityExist(bag) then
        while not DoesEntityExist(aipartner) do 
            Citizen.Wait(50)
        end
        repeat
            TaskEnterVehicle(aipartner, truck, -1, 2, 1.0, 1, 0)
            Citizen.Wait(1000)
        until GetVehiclePedIsIn(aipartner,false) ~= 0
        aiontruck = true
        print("ped should be on truck")
    elseif bool and DoesEntityExist(bag) then
        local truckpos = GetOffsetFromEntityInWorldCoords(truck, 0.0, -6.0, 0.0)
        TaskGoToCoordAnyMeans(aipartner, truckpos.x, truckpos.y, truckpos.z, 1.0, 0, 0, 786603, 1.0)
        local aipos = GetEntityCoords(aipartner,false)
        local distance = GetDistanceBetweenCoords(truckpos,aipos)
        while distance > 3.0 do
            aipos = GetEntityCoords(aipartner,false)
            distance = GetDistanceBetweenCoords(truckpos,aipos)
            Citizen.Wait(1000)
            print("Ai to truck: "..distance)
        end
        ThrowBagInTruck()
        ClearPedTasksImmediately(aipartner)
        repeat
            TaskEnterVehicle(aipartner, truck, -1, 2, 1.0, 1, 0)
            Citizen.Wait(1000)
        until GetVehiclePedIsIn(aipartner,false) ~= 0
        aiontruck = true
    else
        TaskLeaveVehicle(aipartner, truck, 256)
        aiontruck = false
        AiToDumpster(coords)
    end
end

function AiToDumpster(coords)
    local distance = GetDistanceBetweenCoords(coords,GetEntityCoords(aipartner,false))
    if not aiontruck then
        TaskGoToCoordAnyMeans(aipartner, coords.x, coords.y, coords.z, 1.0, 0, 0, 786603, 1.0)
        while distance > 1.5 do
            distance = GetDistanceBetweenCoords(coords,GetEntityCoords(aipartner,false))
            print("Ai to dumpster: "..distance)
            Citizen.Wait(1000)
        end
        GetBagFromBin()
        Citizen.Wait(500)
        AiGetOnTruck(true,nil)
    end
end

function GetBagFromBin()
    if not HasAnimDictLoaded("anim@heists@narcotics@trash") then
		RequestAnimDict("anim@heists@narcotics@trash") 
		while not HasAnimDictLoaded("anim@heists@narcotics@trash") do 
			Citizen.Wait(0)
		end
    end
    TaskStartScenarioInPlace(aipartner, "PROP_HUMAN_BUM_BIN", 0, true)
    ClearPedTasksImmediately(aipartner)
    bag = CreateObject(GetHashKey("prop_cs_street_binbag_01"), 0, 0, 0, true, true, true)
    AttachEntityToEntity(bag, aipartner, GetPedBoneIndex(aipartner, 57005), 0.4, 0, 0, 0, 270.0, 60.0, true, true, false, true, 1, true)
    TaskPlayAnim(aipartner, 'anim@heists@narcotics@trash', 'walk', 1.0, -1.0,-1,49,0,0, 0,0)
end

function ThrowBagInTruck()
    if not HasAnimDictLoaded("anim@heists@narcotics@trash") then
		RequestAnimDict("anim@heists@narcotics@trash") 
		while not HasAnimDictLoaded("anim@heists@narcotics@trash") do 
			Citizen.Wait(0)
		end
	end
	ClearPedTasksImmediately(aipartner)
	TaskPlayAnim(aipartner, 'anim@heists@narcotics@trash', 'throw_b', 1.0, -1.0,-1,2,0,0, 0,0)
    Citizen.Wait(800)
    DeleteEntity(bag)
    Citizen.Wait(100)
    ClearPedTasksImmediately(aipartner)
end

function SelectRoute()
    i = 1
    local src = source
    local rand = math.random(1,5)
    local route = Garbage.Routes[rand]
    return route
end

function CreateRouteBlip(coords)
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

function DrivingRoute(route)
    local lastblip,ped,pedPos,distance
    local player = PlayerPedId()
    if i < #route then
        Citizen.Wait(1000)
        lastblip=CreateRouteBlip(route[i])
        ped = aipartner
        pedPos = GetEntityCoords(ped)
        distance = GetDistanceBetweenCoords(pedPos,route[i])
        while distance > 10 and GetVehiclePedIsIn(ped,false)~=0 do
            Citizen.Wait(1000)
            ped = aipartner
            pedPos = GetEntityCoords(ped)
            distance = GetDistanceBetweenCoords(pedPos,route[i])
            --print(distance,i,GetVehiclePedIsIn(ped,true)==truck,GetVehiclePedIsIn(ped,false)==0)
        end
        if GetVehiclePedIsIn(player,true) == truck and aiontruck then
            AiGetOnTruck(false,route[i])
            TriggerEvent("DRP_Core:Info","Waste Management",tostring("Proceed to the next point on the route"),4500,true,"leftCenter")
            i = i + 1
            RemoveBlip(lastblip)
            DrivingRoute(route)
        else
            TriggerEvent("DRP_Core:Warning","Waste Management", tostring("You must be using your provided garbage truck"),4500,true,"leftCenter")
        end
    end
    RemoveBlip(lastblip)
end

function EndRoute(route)
    TriggerEvent("DRP_Core:Info","Waste Management",tostring("Head back to the landfill and return your truck to receive your pay"),4500,true,"leftCenter")
    local landfill = vector3(Garbage.Garages[1].x,Garbage.Garages[1].y,Garbage.Garages[1].z)
    lastblip=AddBlipForCoord(landfill)
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
    distance = GetDistanceBetweenCoords(pedPos,landfill)
    while distance > 5 do
        Citizen.Wait(1000)
        ped = PlayerPedId()
        pedPos = GetEntityCoords(ped)
        distance = GetDistanceBetweenCoords(pedPos,landfill)
    end
    RemoveBlip(lastblip)
    if GetVehiclePedIsIn(ped,false) == truck then
        DeleteVehicle(GetVehiclePedIsIn(ped,true))
        DeletePed(aipartner)
        TriggerServerEvent("fd_garbage:PayOut",route)
    end
end

--- Events ---
RegisterNetEvent("fd_garbage:SpawnVehicle")
AddEventHandler("fd_garbage:SpawnVehicle", function(coords)
    local ped = PlayerPedId()
    truck = SpawnVehicle(coords)
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
                if IsControlJustPressed(1, 86) then
                    TriggerServerEvent("fd_garbage:ToggleDuty", false)
                elseif IsControlJustPressed(1, 73) then
                    TriggerServerEvent("fd_garbage:ToggleDuty", true)
                end
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
                SpawnPartner()
                Citizen.Wait(2500)
                AiGetOnTruck(true,nil)
                print(aiontruck,DoesEntityExist(aipartner))
                DrivingRoute(route)
                EndRoute(route)
               elseif IsControlJustPressed(1,73) then
                DeleteVehicle(GetVehiclePedIsIn(ped,true))
               end
            end
        end
        Citizen.Wait(sleepTimer)
    end
end)
-- Blips --
Citizen.CreateThread(function()
    local blip = AddBlipForCoord(Garbage.SignOnAndOff[1].x, Garbage.SignOnAndOff[1].y, Garbage.SignOnAndOff[1].z)
    SetBlipSprite(blip, 318)
	BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('Landfill')
    EndTextCommandSetBlipName(blip)
    SetBlipAsShortRange(blip,true)
end)




--- Threads ---
Citizen.CreateThread(function()
    local sleep = 1000
    while true do
        for i=1, #Config.SignOnAndOff do
            local ped = PlayerPedId()
            local pedPos = GetEntityCoords(ped)
            local distance = Vdist(pedPos.x, pedPos.y, pedPos.z, Config.SignOnAndOff[i].x, Config.SignOnAndOff[i].y, Config.SignOnAndOff[i].z)
            if distance <= 5.0 then
                exports["drp_core"]:DrawText3Ds(Config.SignOnAndOff[i].x, Config.SignOnAndOff[i].y, Config.SignOnAndOff[i].z,tostring("~b~[E]~w~ to sign on duty or ~r~[X]~w~ to sign off duty"))
            end
            if IsControlJustPressed(1, 86) then
                TriggerServerEvent("fd_garbage:ToggleDuty", false)
            elseif IsControlJustPressed(1, 73) then
                TriggerServerEvent("fd_garbage:ToggleDuty", true)
            end
        end
    end

end)
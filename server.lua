RegisterServerEvent("fd_garbage:ToggleDuty")
AddEventHandler("fd_garbage:ToggleDuty", function(unemployed)
    local src = source
    local job = string.upper("trash")
    local jobLabel = "Los Santos Waste Management"
    local characterInfo = exports["drp_id"]:GetCharacterData(src)
    local currentPlayerJob = exports["drp_jobcore"]:GetPlayerJob(src)
    local unemployed = unemployed
    if unemployed then
        if currentPlayerJob.job ~= "UNEMPLOYED" then
            exports["drp_jobcore"]:RequestJobChange(src, false, false, false)
            TriggerEvent("DRP_Clothing:RestartClothing", src)
        else
            TriggerClientEvent("DRP_Core:Error", src, "Job Manager", tostring("You're already not working"), 2500, true, "leftCenter")
        end
    else
        if exports["drp_jobcore"]:DoesJobExist(job) then
            exports["drp_jobcore"]:RequestJobChange(src, job, jobLabel, false)
            --TriggerClientEvent("DRP_Core:Info", src, "Government", tostring("Welcome to "..jobLabel,characterInfo.name..""), 4500, true, "leftCenter")
        end
    end
end)

RegisterServerEvent("fd_garbage:SpawnVehicle")
AddEventHandler("fd_garbage:SpawnVehicle", function(coords)
    local src = source
    local srcJob = exports["drp_jobcore"]:GetPlayerJob(src)
    print(srcJob.job)
    if srcJob.job == "TRASH" then
        TriggerClientEvent("fd_garbage:SpawnVehicle", src, coords)
    end
end)

RegisterServerEvent("fd_garbage:PayOut")
AddEventHandler("fd_garbage:PayOut", function(route)
    local pay = 50 * #route
    local src = source
    local player = exports["drp_id"]:GetCharacterData(src)
    local playerJob = exports["drp_jobcore"]:GetPlayerJob(src)
    if playerJob.job == "TRASH" then
        TriggerEvent("DRP_Bank:AddBankMoney", player, pay)
    end
end)
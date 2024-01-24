local QBCore = exports['qb-core']:GetCoreObject()
local isLoggedIn = false

local doorInfoLoop = {}
local doorInfo = {}
local locked = false
local inZone = false

function formatTime(seconds)
    local minutes = math.floor(seconds / 60)
    local hours = math.floor(minutes / 60)
    local days = math.floor(hours / 24)

    if days > 0 then
        return string.format("%d days, %d hours", days, hours % 24)
    elseif hours > 0 then
        return string.format("%d hours, %d minutes", hours, minutes % 60)
    elseif minutes > 0 then
        return string.format("%d minutes", minutes)
    else
        return string.format("%d seconds", seconds)
    end
end

function lockUnlockDoor(doorObj, doorData)
    local PlayerData = QBCore.Functions.GetPlayerData()
    local items = PlayerData.items
    local foundKey = false

    for _, item in pairs(items) do
        if item.name == Config.KeyName then
            if item.info.room == doorData.room then
                foundKey = true
                RequestAnimDict("anim@heists@keycard@")
                while not HasAnimDictLoaded("anim@heists@keycard@") do
                    Wait(0)
                end
                TaskPlayAnim(PlayerPedId(), "anim@heists@keycard@", "exit", 8.0, 1.0, -1, 48, 0, 0, 0, 0)
                
                if doorInfo[doorObj].locked then
                    doorInfo[doorObj].locked = false
                    TriggerServerEvent('jc-motels:server:updateDoorState', doorObj, doorInfo[doorObj].locked)
                    DoorSystemSetDoorState(doorObj, 0, false, false)
                else
                    doorInfo[doorObj].locked = true
                    TriggerServerEvent('jc-motels:server:updateDoorState', doorObj, doorInfo[doorObj].locked)
                    DoorSystemSetDoorState(doorObj, 4, false, false)
                    DoorSystemSetDoorState(doorObj, 1, false, false)
                end
                break
            else
                foundKey = true
                QBCore.Functions.Notify('You don\'t have the key for this room!', 'error', 3000)
                break
            end
        end
    end

    if not foundKey then
        QBCore.Functions.Notify('You don\'t have the key!', 'error', 3000)
    end
end

Citizen.CreateThread(function()
    while true do
        Wait(0)
        if inZone then
            if inZone == 'door' then
                if IsControlJustPressed(0, 51) then
                    print('Pressed E')
                    print(doorInfoLoop.entity)
                    TriggerServerEvent('jc-motels:server:checkDoorState', doorInfoLoop.entity, doorInfoLoop.room)
                end
            elseif inZone == 'storage' then
                local room = doorInfoLoop.room
                if IsControlJustPressed(0, 51) then
                    print('Pressed E')
                    TriggerServerEvent('inventory:server:OpenInventory', 'stash', room.room, {
                        maxweight = room.weight,
                        slots = room.slots,
                    })
                    TriggerEvent('inventory:client:SetCurrentStash', room.room)
                end
            elseif inZone == 'wardrobe' then
                if IsControlJustPressed(0, 51) then
                    print('Pressed E')
                    TriggerServerEvent("InteractSound_SV:PlayOnSource", "Clothes1", 0.4)
                    TriggerEvent('qb-clothing:client:openOutfitMenu')
                end
            end
        end
    end
end)

Citizen.CreateThread(function()
    local function checkMotels()
        QBCore.Functions.TriggerCallback('getMotels', function(data)
            local motels = data

            if motels then
                for _, motel in pairs(motels) do
                    for _, m in pairs(Config.MotelRooms) do
                        if m.room == motel.roomid and not m.renter then
                            m.renter = motel.renter
                        end
                    end
                end
            end
        end)
    end

    checkMotels()
    for i, motel in pairs(Config.Motels) do
        local coords = motel.coords

        local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
        SetBlipSprite(blip, 78)
        SetBlipScale(blip, 3)
        SetBlipDisplay(blip, 4)
        SetBlipColour(blip, 0)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName(motel.label)
        EndTextCommandSetBlipName(blip)

        if Config.UseTarget then
            if Config.Target == 'qb' then
                exports['qb-target']:AddCircleZone(i, vector3(coords.x, coords.y, coords.z), 1.5, {
                    name = i,
                    debugPoly = false,
                }, {
                    options = {
                        {
                            label = 'Motel Lobby',
                            icon = 'fas fa-lobby',
                            action = function()
                                lib.registerContext({
                                    id = i,
                                    title = motel.label,
                                    options = {
                                        {
                                            title = 'Rented Rooms',
                                            description = 'Watch your rented rooms!',
                                            onSelect = function()
                                                local PlayerData = QBCore.Functions.GetPlayerData()
                                                local tableData = {}

                                                QBCore.Functions.TriggerCallback('getMotels', function(data)
                                                    local motels = data

                                                    if motels then
                                                        for _, motel in pairs(motels) do
                                                            if PlayerData.citizenid == motel.citizenid then
                                                                tableData[#tableData + 1] = {
                                                                    title = motel.room,
                                                                    description = 'Rent ends in: ' .. formatTime(motel.rentedTime),
                                                                    onSelect = function()
                                                                        lib.registerContext({
                                                                            id = 'manage_' .. motel.roomid,
                                                                            title = 'Manage Hotel Room',
                                                                            options = {
                                                                                {
                                                                                    title = 'Duplicate Key',
                                                                                    description = 'Duplicate your key to give to friends!',
                                                                                    onSelect = function()
                                                                                        TriggerServerEvent('jc-motels:server:duplicateKey', motel.roomid, motel.room)
                                                                                    end
                                                                                },
                                                                                {
                                                                                    title = 'Lost Key',
                                                                                    description = 'Get a new key for your room!',
                                                                                    onSelect = function()
                                                                                        local PlayerData = QBCore.Functions.GetPlayerData()
                                                                                        local items = PlayerData.items
                                                                                        local foundMatch = false
                                                                                        
                                                                                        for _, k in pairs(items) do
                                                                                            if k.name == 'motel_key' and k.info.room == motel.roomid then
                                                                                                foundMatch = true
                                                                                                break
                                                                                            end
                                                                                        end

                                                                                        if foundMatch then
                                                                                            QBCore.Functions.Notify('What are you talking about?? The key is on you...', 'error', 3000)
                                                                                        else
                                                                                            TriggerServerEvent('jc-motels:server:lostKeys', motel.roomid, motel.room)
                                                                                        end
                                                                                    end
                                                                                },
                                                                                {
                                                                                    title = 'Extend Rent',
                                                                                    description = 'Pay to rent for another week!',
                                                                                    onSelect = function()
                                                                                        if motel.rentedTime > 84600 then
                                                                                            QBCore.Functions.Notify('You can only rent for a week at a time! You can first pay when there\'s 24 hours or less left!', 'error', 3000)
                                                                                        else
                                                                                            for _, m in pairs(Config.BeachMotels) do
                                                                                                if m.room == motel.roomid then
                                                                                                    TriggerServerEvent('jc-motels:server:extendRent', motel.roomid, m.price)
                                                                                                    break
                                                                                                else
                                                                                                    QBCore.Functions.Notify('Something went wrong.. Room not found!', 'error', 3000)
                                                                                                end
                                                                                            end
                                                                                        end
                                                                                    end
                                                                                },
                                                                                {
                                                                                    title = 'End Rent',
                                                                                    description = 'Stop renting the motel room!',
                                                                                    onSelect = function()
                                                                                        local PlayerData = QBCore.Functions.GetPlayerData()
                                                                                        local items = PlayerData.items
                                                                                        local hasKey = false

                                                                                        for _, item in pairs(items) do
                                                                                            if item.info.room == motel.roomid then
                                                                                                hasKey = true
                                                                                                break
                                                                                            end
                                                                                        end
                                                                                        
                                                                                        if hasKey then
                                                                                            for _, m in pairs(Config.BeachMotels) do
                                                                                                if m.room == motel.roomid then
                                                                                                    m.renter = nil
                                                                                                    TriggerServerEvent('jc-motels:server:cancelRent', motel.roomid, motel.room_name)
                                                                                                    break
                                                                                                else
                                                                                                    QBCore.Functions.Notify('Something went wrong.. Room not found!', 'error', 3000)
                                                                                                end
                                                                                            end
                                                                                        else
                                                                                            QBCore.Functions.Notify('You need your key so you can deliver it!', 'error', 3000)
                                                                                        end
                                                                                    end
                                                                                }
                                                                            }
                                                                        })
                                                                        lib.showContext('manage_' .. motel.roomid)
                                                                    end
                                                                }
                                                            end
                                                        end

                                                        lib.registerContext({
                                                            id = 'rented_rooms',
                                                            title = 'Rented Rooms',
                                                            options = tableData
                                                        })
                                                        lib.showContext('rented_rooms')
                                                    else
                                                        QBCore.Functions.Notify('You don\'t have any rented rooms here!', 'error', 3000)
                                                    end
                                                end)
                                            end
                                        },
                                        {
                                            title = 'Rent Room',
                                            description = 'Rent a room with weekly pay!',
                                            onSelect = function()
                                                local tableData = {}
                                                local boughtRoom = false
                                                checkMotels()
                                                Wait(100)
                                
                                                for _, rooms in pairs(Config.BeachMotels) do
                                                    if rooms.category == i and not rooms.renter then
                                                        tableData[#tableData + 1] = {
                                                            title = rooms.label,
                                                            description = 'Price: $' .. rooms.price .. '\n Storage Space: ' .. rooms.slots,
                                                            onSelect = function()
                                                                if not boughtRoom then
                                                                    TriggerServerEvent('jc-motels:server:buyRoom', rooms)
                                                                    boughtRoom = true
                                                                    Wait(1000)
                                                                    boughtRoom = false
                                                                end
                                                            end
                                                        }
                                                    end
                                                end
                                
                                                lib.registerContext({
                                                    id = 'rent_' .. i .. '_room',
                                                    title = 'Rent Motel Room',
                                                    options = tableData
                                                })
                                                lib.showContext('rent_' .. i .. '_room')
                                            end
                                        }
                                    }
                                })
                                lib.showContext(i)
                            end
                        }
                    },
                    distance = 2.5
                })
            elseif Config.Target == 'ox' then
                -- Logic for using ox_target
            end
        else
            local mcoords = motel.coords
            local reception = BoxZone:Create(vector3(mcoords.x, mcoords.y, mcoords.z), 2.5, 2.5, {
                name=i,
                heading=0,
                minZ=24,
                maxZ=31,
                debugPoly=true,
            })

            reception:onPlayerInOut(function(isPointInside)
                if isPointInside then
                    lib.registerContext({
                        id = i,
                        title = motel.label,
                        options = {
                            {
                                title = 'Rented Rooms',
                                description = 'Watch your rented rooms!',
                                onSelect = function()
                                    local PlayerData = QBCore.Functions.GetPlayerData()
                                    local tableData = {}

                                    QBCore.Functions.TriggerCallback('getMotels', function(data)
                                        local motels = data

                                        if motels then
                                            for _, motel in pairs(motels) do
                                                if PlayerData.citizenid == motel.citizenid then
                                                    tableData[#tableData + 1] = {
                                                        title = motel.room,
                                                        description = 'Rent ends in: ' .. formatTime(motel.rentedTime),
                                                        onSelect = function()
                                                            lib.registerContext({
                                                                id = 'manage_' .. motel.roomid,
                                                                title = 'Manage Hotel Room',
                                                                options = {
                                                                    {
                                                                        title = 'Lost Key',
                                                                        description = 'Get a new key for your room!',
                                                                        onSelect = function()
                                                                            TriggerServerEvent('jc-motels:server:extendRent', motel.roomid, motel.room)
                                                                        end
                                                                    },
                                                                    {
                                                                        title = 'Extend Rent',
                                                                        description = 'Pay to rent for another week!',
                                                                        onSelect = function()
                                                                            if motel.rentedTime > 84600 then
                                                                                QBCore.Functions.Notify('You can only rent for a week at a time! You can first pay when there\'s 24 hours or less left!', 'error', 3000)
                                                                            else
                                                                                for _, m in pairs(Config.BeachMotels) do
                                                                                    if m.room == motel.roomid then
                                                                                        TriggerServerEvent('jc-motels:server:extendRent', motel.roomid, m.price)
                                                                                        break
                                                                                    else
                                                                                        QBCore.Functions.Notify('Something went wrong.. Room not found!', 'error', 3000)
                                                                                        break
                                                                                    end
                                                                                end
                                                                            end
                                                                        end
                                                                    },
                                                                    {
                                                                        title = 'End Rent',
                                                                        description = 'Stop renting the motel room!',
                                                                        onSelect = function()
                                                                            local PlayerData = QBCore.Functions.GetPlayerData()
                                                                            local items = PlayerData.items
                                                                            local hasKey = false

                                                                            for _, item in pairs(items) do
                                                                                if item.info.room == motel.roomid then
                                                                                    hasKey = true
                                                                                    break
                                                                                end
                                                                            end
                                                                            
                                                                            if hasKey then
                                                                                for _, m in pairs(Config.BeachMotels) do
                                                                                    if m.room == motel.roomid then
                                                                                        m.renter = nil
                                                                                        TriggerServerEvent('jc-motels:server:cancelRent', motel.roomid, motel.room_name)
                                                                                        break
                                                                                    else
                                                                                        QBCore.Functions.Notify('Something went wrong.. Room not found!', 'error', 3000)
                                                                                        break
                                                                                    end
                                                                                end
                                                                            else
                                                                                QBCore.Functions.Notify('You need your key so you can deliver it!', 'error', 3000)
                                                                            end
                                                                        end
                                                                    }
                                                                }
                                                            })
                                                            lib.showContext('manage_' .. motel.roomid)
                                                        end
                                                    }
                                                end
                                            end

                                            lib.registerContext({
                                                id = 'rented_rooms',
                                                title = 'Rented Rooms',
                                                options = tableData
                                            })
                                            lib.showContext('rented_rooms')
                                        else
                                            QBCore.Functions.Notify('You don\'t have any current rented rooms!', 'error', 3000)
                                        end
                                    end)
                                end
                            },
                            {
                                title = 'Rent Room',
                                description = 'Rent a room with weekly pay!',
                                onSelect = function()
                                    local tableData = {}
                                    local boughtRoom = false
                                    checkMotels()
                                    Wait(100)
                    
                                    for _, rooms in pairs(Config.BeachMotels) do
                                        if rooms.category == i and not rooms.renter then
                                            tableData[#tableData + 1] = {
                                                title = rooms.label,
                                                description = 'Price: $' .. rooms.price .. '\n Storage Space: ' .. rooms.slots,
                                                onSelect = function()
                                                    if not boughtRoom then
                                                        TriggerServerEvent('jc-motels:server:buyRoom', rooms)
                                                        boughtRoom = true
                                                        Wait(1000)
                                                        boughtRoom = false
                                                    end
                                                end
                                            }
                                        end
                                    end
                    
                                    lib.registerContext({
                                        id = 'rent_' .. i .. '_room',
                                        title = 'Rent Motel Room',
                                        options = tableData
                                    })
                                    lib.showContext('rent_' .. i .. '_room')
                                end
                            }
                        }
                    })
                    lib.showContext(i)
                end
            end)
        end
    end
end)

Citizen.CreateThread(function()
    while not isLoggedIn do
        Wait(1000)

        if LocalPlayer.state.isLoggedIn then
            isLoggedIn = true
            print('Logged in!')
        end
    end

    for i, motels in pairs(Config.MotelRooms) do
        for k, rooms in pairs(motels) do 
            local doorObj = GetClosestObjectOfType(rooms.doorCoords, 2.0, rooms.doorHash, false, false, false)
    
            if doorObj and doorObj ~= 0 then
                -- print(rooms.room, doorObj)
                if not IsDoorRegisteredWithSystem(doorObj) then
                    local objCoords = rooms.doorCoords
                    local objHeading = GetEntityHeading(doorObj)
                    
                    AddDoorToSystem(doorObj, rooms.doorHash, objCoords.x, objCoords.y, objCoords.z, false, false, false)
                    if rooms.locked then
                        DoorSystemSetDoorState(doorObj, 4, false, false)
                        DoorSystemSetDoorState(doorObj, 1, false, false)
                    else
                        DoorSystemSetDoorState(doorObj, 0, false, false)
                    end
                end

                if Config.UseTarget then
                    if Config.Target == 'qb' then
                        exports['qb-target']:AddTargetEntity(doorObj, {
                            options = {
                                {
                                    label = 'Lock/Unlock door',
                                    icon = 'fas fa-key',
                                    action = function(entity) 
                                        TriggerServerEvent('jc-motels:server:checkDoorState', entity, rooms)
                                    end
                                }
                            },
                            distance = 2.5
                        })

                        local s_coords = rooms.storage
                        exports['qb-target']:AddCircleZone('stash_' .. rooms.room, vector3(s_coords.x, s_coords.y, s_coords.z), 1.5, {
                            name = 'stash_' .. rooms.room,
                            useZ = true,
                            debugPoly = false,
                        }, {
                            options = {
                                {
                                    label = 'Open Stash',
                                    icon = 'fas fa-box',
                                    action = function()
                                        if Config.Inventory == 'qb' then
                                            TriggerServerEvent('inventory:server:OpenInventory', 'stash', rooms.room, {
                                                maxweight = rooms.weight,
                                                slots = rooms.slots,
                                            })
                                            TriggerEvent('inventory:client:SetCurrentStash', rooms.room)
                                        elseif Config.Inventory == 'ox' then
                                            -- Add the logic of ox_inventory
                                        end
                                    end
                                },
                            },
                            distance = 2.5
                        })

                        local w_coords = rooms.wardrobe
                        exports['qb-target']:AddCircleZone('wardrobe_' .. rooms.room, vector3(w_coords.x, w_coords.y, w_coords.z), 1.5, {
                            name = 'wardrobe_' .. rooms.room,
                            useZ = true,
                            debugPoly = false,
                        }, {
                            options = {
                                {
                                    label = 'Open Wardrobe',
                                    icon = 'fas fa-box',
                                    action = function()
                                        TriggerServerEvent("InteractSound_SV:PlayOnSource", "Clothes1", 0.4)
                                        TriggerEvent('qb-clothing:client:openOutfitMenu')
                                    end
                                },
                            },
                            distance = 2.5
                        })

                    elseif Config.Target == 'ox' then
                        -- Logic for using ox_target
                    end
                else
                    local doorCoords = GetEntityCoords(doorObj)
                    local doorZone = BoxZone:Create(doorCoords, 2.5, 2.5, {
                        name=i,
                        heading=0,
                        minZ=rooms.minZ,
                        maxZ=rooms.maxZ,
                        debugPoly=true,
                    })

                    local storage = BoxZone:Create(rooms.storage, 1, 1, {
                        name=i,
                        heading=0,
                        minZ=rooms.minZ,
                        maxZ=rooms.maxZ,
                        debugPoly=true,
                    })

                    local wardrobe = BoxZone:Create(rooms.wardrobe, 1, 1, {
                        name=i,
                        heading=0,
                        minZ=rooms.minZ,
                        maxZ=rooms.maxZ,
                        debugPoly=true,
                    })
                    
                    doorZone:onPlayerInOut(function(isPointInside)
                        if isPointInside then
                            exports['qb-core']:DrawText('Press ~E~ to unlock door', 'right')
                            doorInfoLoop = {
                                entity = doorObj,
                                room = rooms
                            }
                            inZone = 'door'
                        else
                            inZone = false
                            exports['qb-core']:HideText()
                        end
                    end)

                    storage:onPlayerInOut(function(isPointInside)
                        if isPointInside then
                            exports['qb-core']:DrawText('Press ~E~ to open stash', 'right')
                            doorInfoLoop = {
                                entity = doorObj,
                                room = rooms
                            }
                            inZone = 'storage'
                        else
                            inZone = nil
                            exports['qb-core']:HideText()
                        end
                    end)

                    wardrobe:onPlayerInOut(function(isPointInside)
                        if isPointInside then
                            exports['qb-core']:DrawText('Press ~E~ to open wardrobe', 'right')
                            doorInfoLoop = {
                                entity = doorObj,
                                room = rooms
                            }
                            inZone = 'wardrobe'
                        else
                            inZone = nil
                            exports['qb-core']:HideText()
                        end
                    end)
                end
            end
        end 
    end
end)

RegisterNetEvent('jc-motels:client:updateDoorState')
AddEventHandler('jc-motels:client:updateDoorState', function(doorObj, doorData, state)
    if not doorInfo[doorObj] then
        doorInfo[doorObj] = {locked = state}
    end

    lockUnlockDoor(doorObj, doorData)
end)

AddEventHandler('onClientResourceStart', function(resourceName)
    for i, motels in pairs(Config.MotelRooms) do
        for k, rooms in pairs(motels) do 
            local doorObj = GetClosestObjectOfType(rooms.doorCoords, 2.0, rooms.doorHash, false, false, false)
    
            if doorObj and doorObj ~= 0 then
                -- print(rooms.room, doorObj)
                if not IsDoorRegisteredWithSystem(doorObj) then
                    local objCoords = rooms.doorCoords
                    local objHeading = GetEntityHeading(doorObj)
                    
                    AddDoorToSystem(doorObj, rooms.doorHash, objCoords.x, objCoords.y, objCoords.z, false, false, false)
                    if rooms.locked then
                        DoorSystemSetDoorState(doorObj, 4, false, false)
                        DoorSystemSetDoorState(doorObj, 1, false, false)
                    else
                        DoorSystemSetDoorState(doorObj, 0, false, false)
                    end
                end
            end
        end
    end
end)

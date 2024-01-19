local QBCore = exports['qb-core']:GetCoreObject()

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

Citizen.CreateThread(function()
    Wait(1000)

    local function checkMotels()
        QBCore.Functions.TriggerCallback('getMotels', function(data)
            local motels = data

            if motels then
                for _, motel in pairs(motels) do
                    for _, m in pairs(Config.BeachMotels) do
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

                                                for _, motel in pairs(motels) do
                                                    print(motel.citizenid)
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
                                                                                TriggerServerEvent('jc-motels:server:lostKeys', motel.roomid, motel.room)
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

                                        for _, motel in pairs(motels) do
                                            print(motel.citizenid)
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

    for _, doors in pairs(Config.BeachMotels) do
        local doorObj = nil
        local doorLocked = false
        local coords = doors.targetCoords
        local stashCoords = doors.storage
        local wardrobeCoords = doors.wardrobe
        local entityPos = nil
        local entityHeading = nil

        if doors.locked then
            doorLocked = true
            doorObj = GetClosestObjectOfType(doors.doorCoords, 2.0, doors.doorHash, false, false, false)
            entityPos = GetEntityCoords(doorObj)
            entityHeading = GetEntityHeading(doorObj)

            FreezeEntityPosition(doorObj, true)
        end

        if Config.UseTarget then
            exports['qb-target']:AddCircleZone(doors.room, vector3(coords.x, coords.y, coords.z), 1.5, {
                name = doors.room,
                debugPoly = false
            }, {
                options = {
                    {
                        label = 'Lock/Unlock Room',
                        icon = 'fas fa-keys',
                        targeticon = 'fas fa-eye',
                        action = function()
                            local PlayerData = QBCore.Functions.GetPlayerData()
                            local items = PlayerData.items
                            
                            for _, item in pairs(items) do
                                if item.label == 'Motel Key' and item.info.room == doors.room then
                                    RequestAnimDict("anim@heists@keycard@")
                                    while not HasAnimDictLoaded("anim@heists@keycard@") do
                                        Wait(0)
                                    end
                                    TaskPlayAnim(PlayerPedId(), "anim@heists@keycard@", "exit", 8.0, 1.0, -1, 48, 0, 0, 0, 0)
                                    if doorLocked then
                                        FreezeEntityPosition(doorObj, false)
                                        doorLocked = false
                                    else
                                        FreezeEntityPosition(doorObj, true)
                                        doorLocked = true
                                        SetEntityCoords(doorObj, entityPos)
                                        SetEntityHeading(doorObj, entityHeading)
                                    end
                                else
                                    QBCore.Functions.Notify('You don\'t have the key for this door!', 'error', 3000)
                                end
                            end
                        end
                    }
                },
                distance = 2.5
            })

            exports['qb-target']:AddCircleZone(doors.room .. '_storage', vector3(stashCoords.x, stashCoords.y, stashCoords.z), 1.5, {
                name = doors.room .. '_storage',
                debugPoly = false,
            }, {
                options = {
                    {
                        label = 'Stash',
                        icon = 'fas fa-chest',
                        targeticon = 'fas fa-eye',
                        action = function()
                            TriggerServerEvent('inventory:server:OpenInventory', 'stash', doors.room, {
                                maxweight = doors.weight,
                                slots = doors.slots,
                            })
                            TriggerEvent('inventory:client:SetCurrentStash', doors.room)
                        end
                    }
                },
                distance = 2.5
            })

            exports['qb-target']:AddCircleZone(doors.room .. '_wardrobe', vector3(wardrobeCoords.x, wardrobeCoords.y, wardrobeCoords.z), 1.5, {
                name = doors.room .. '_wardrobe',
                debugPoly = false,
            }, {
                options = {
                    {
                        label = 'Wardrobe',
                        icon = 'fas fa-wardrobe',
                        targeticon = 'fas fa-eye',
                        action = function()
                            TriggerServerEvent("InteractSound_SV:PlayOnSource", "Clothes1", 0.4)
                            TriggerEvent('qb-clothing:client:openOutfitMenu')
                        end
                    }
                },
                distance = 2.5
            })
        else
            local doorCoords = doors.doorCoords
            local playerCoords = GetEntityCoords(PlayerPedId())
            local doorZone = BoxZone:Create(vector3(doorCoords.x, doorCoords.y, doorCoords.z), 2.5, 2.5, {
                name="Test",
                heading=0,
                minZ = doors.minZ,
                maxZ = doors.maxZ,
                debugPoly= true,
            })
            
            local inZone = false
            local menuOpen = false

            local function interactDoor(door)
                if IsControlJustPressed(0, 51) then
                    local PlayerData = QBCore.Functions.GetPlayerData()
                    local items = PlayerData.items
                    
                    for _, item in pairs(items) do
                        if item.label == 'Motel Key' and item.info.room == door.room then
                            RequestAnimDict("anim@heists@keycard@")
                            while not HasAnimDictLoaded("anim@heists@keycard@") do
                                Wait(0)
                            end
                            TaskPlayAnim(PlayerPedId(), "anim@heists@keycard@", "exit", 8.0, 1.0, -1, 48, 0, 0, 0, 0)
                            if doorLocked then
                                FreezeEntityPosition(doorObj, false)
                                doorLocked = false
                            else
                                FreezeEntityPosition(doorObj, true)
                                doorLocked = true
                                SetEntityCoords(doorObj, entityPos)
                                SetEntityHeading(doorObj, entityHeading)
                            end
                        else
                            QBCore.Functions.Notify('You don\'t have the key for this door!', 'error', 3000)
                        end
                    end
                end
            end
            
            doorZone:onPlayerInOut(function(isPointInside, _, _)
                if isPointInside then
                    print('Motel room: ' .. doors.room)
                    exports['qb-core']:DrawText('Press ~E~ to unlock door', 'right')
                    inZone = true
                else
                    inZone = false
                    exports['qb-core']:HideText()
                    print('Exited 1')
                end
            end)

            Citizen.CreateThread(function()
                while true do
                    Wait(0)
                    if inZone then
                        interactDoor(doors)
                    end
                end
            end)
        end
    end
end)

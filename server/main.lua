local QBCore = exports['qb-core']:GetCoreObject()

Citizen.CreateThread(function()
    while true do
        Wait(1000)
        MySQL.execute('UPDATE `motels` SET `rentedTime` = GREATEST(`rentedTime` - 1, 0) WHERE `rentedTime` > 0', {})
    end
end)

QBCore.Functions.CreateCallback('getMotels', function(source, cb)
    local tableData = {}
    MySQL.query('SELECT `room_name`, `renter`, `roomid`, `renter_citizenid`, `rentedTime` FROM `motels`', {}, function(response)
        if response and #response > 0 then
            for i = 1, #response do
                local row = response[i]
                tableData[#tableData + 1] = {
                    room = row.room_name,
                    renter = row.renter,
                    roomid = row.roomid,
                    citizenid = row.renter_citizenid,
                    rentedTime = row.rentedTime,
                }
            end

            cb(tableData)
        else
            cb(false)
        end
    end)
end)

RegisterServerEvent('jc-motels:server:buyRoom')
AddEventHandler('jc-motels:server:buyRoom', function(room)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    local citizenid = player.PlayerData.citizenid
    local name = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
    local money = player.PlayerData.money['cash']

    if money >= room.price then

        MySQL.query('SELECT `roomid` FROM `motels` WHERE `roomid` = ?', {
            room.room
        }, function(response)
            if response and #response > 0 then
                for i = 1, #response do
                    local row = response[i]

                    MySQL.update('UPDATE motels SET renter = ?, renter_citizenid = ?, rentedTime = ? WHERE roomid = ?', {
                        name, citizenid, 604800, room.room
                    }, function(affectedRows)
                        player.Functions.RemoveMoney('cash', room.price)

                        local info = {}
                        info.label = room.label
                        info.room = room.room
                
                        player.Functions.AddItem('motel_key', 1, nil, info)
                        TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items['motel_key'], 'add')
                    end)
                end
            else
                MySQL.insert('INSERT INTO `motels` (room_name, roomid, renter, renter_citizenid, rentedTime) VALUES (?, ?, ?, ?, ?)', {
                    room.label, room.room, name, citizenid, 604800
                }, function(id)
                    player.Functions.RemoveMoney('cash', room.price)

                    local info = {}
                    info.label = room.label
                    info.room = room.room
            
                    player.Functions.AddItem('motel_key', 1, nil, info)
                    TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items['motel_key'], 'add')
                end)
            end
        end)
    else
        QBCore.Functions.Notify(src, 'You don\'t have enough money to rent a hotel room!', 'error', 3000)
    end
end)

RegisterServerEvent('jc-motels:server:extendRent')
AddEventHandler('jc-motels:server:extendRent', function(roomid, price)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)

    MySQL.update('UPDATE motels SET rentedTime = rentedTime + ? WHERE roomid = ?', {
        518400, roomid
    }, function(affectedRows)
        player.Functions.RemoveMoney('cash', price)
    end)
end)

RegisterServerEvent('jc-motels:server:cancelRent')
AddEventHandler('jc-motels:server:cancelRent', function(roomid, room)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)

    MySQL.query('DELETE FROM `motels` WHERE `roomid` = ?', {roomid}, function(response) end)
    QBCore.Functions.Notify(src, 'You have cancelled your rent!')

    player.Functions.RemoveItem('motel_key', 1, nil, info)
    TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items['motel_key'], 'remove')
end)

RegisterServerEvent('jc-motels:server:lostKeys')
AddEventHandler('jc-motels:server:extendRent', function(room, label)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)

    player.Functions.RemoveMoney('cash', 100)
    local info = {}
    info.label = label
    info.room = room
    player.Functions.AddItem('motel_key', 1, nil, info)
    TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items['motel_key'], 'add')
end)

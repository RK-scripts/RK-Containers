ESX = nil

ESX = exports["es_extended"]:getSharedObject()

local ContainerCache = {}

MySQL.ready(function ()
    local query = "SELECT pin, container_id, container_number FROM containers WHERE pin IS NOT NULL"
    local results = MySQL.Sync.fetchAll(query, {})
    if results then
        for i = 1, #results do
            local result = results[i]
            for j = 1, #Config_Container.Inventari do
                local stashId = 'Container' .. result.container_number .. '_' .. j
              
                exports.ox_inventory:RegisterStash(stashId, 'Container ' .. result.container_number .. ' Inventario ' .. j, 100, 100000)
            end
            ContainerCache[tostring(result.pin)] = {id = result.container_id, number = result.container_number}
        end
    end
end)

RegisterServerEvent('RK_scripts:container:purchase', function(container_id, coords)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if not coords or not coords.x or not coords.y or not coords.z then
     
        TriggerClientEvent('esx:showNotification', src, 'Errore durante l\'acquisto del container. Riprova.')
        
        return
    end
    
    if xPlayer.getAccount('bank').money >= Config_Container.ContainerCost then
        xPlayer.removeAccountMoney('bank', Config_Container.ContainerCost)
       
        -- Genera un numero di container unico
        local container_number = nil
        repeat
            container_number = Config_Container.ContainerCodePrefix .. math.random(111111, 999999)
            local exists = MySQL.scalar.await('SELECT container_id FROM containers WHERE container_number = ?', {container_number})
            Wait(100)
        until not exists
        -- Chiedi al giocatore di impostare un PIN
        TriggerClientEvent('RK_scripts:container:setPIN', src, container_id, container_number, coords)
    else
        TriggerClientEvent('esx:showNotification', src, 'Non hai abbastanza soldi per acquistare un container!')
    end
end)


RegisterServerEvent('RK_scripts:container:confirmPIN', function(container_id, container_number, pin, coords)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
   
    if not xPlayer then
   
        return
    end

    local identifier = xPlayer.identifier
    if not identifier then
 
        return
    end

    if not pin or pin == '' then
        return
    end

    -- Inserisci il nuovo container nel database
    MySQL.insert('INSERT INTO containers (container_id, container_number, pin, blip_x, blip_y, blip_z, owner) VALUES (?, ?, ?, ?, ?, ?, ?)', 
        {container_id, container_number, pin, coords.x, coords.y, coords.z, identifier},
        function(insertId)
            if insertId then
                -- Aggiorna la cache
                ContainerCache[tostring(pin)] = {id = container_id, number = container_number, coords = coords, owner = identifier}
                -- Registra gli stash
                for i = 1, #Config_Container.Inventari do
                    local stashId = 'Container' .. container_number .. '_' .. i
                    
                    exports.ox_inventory:RegisterStash(stashId, 'Container ' .. container_number .. ' Inventario ' .. i, 100, 100000)
                end
                TriggerClientEvent('esx:showNotification', src, 'Container acquistato con successo! Il tuo PIN è: ' .. pin)
                
                TriggerClientEvent("BakiTelli_battlepass:Task", src, "container", 1)
                -- Crea il blip solo per il proprietario
                TriggerClientEvent('RK_scripts:container:createBlip', src, container_id, coords)
               
                
            else
                TriggerClientEvent('esx:showNotification', src, 'Errore durante l\'acquisto del container. Riprova.')
            end
        end
    )
end)

RegisterNetEvent('RK_scripts:container:loadBlips')
AddEventHandler('RK_scripts:container:loadBlips', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if not xPlayer then
       
        return
    end

    local identifier = xPlayer.identifier
    
    
    MySQL.Async.fetchAll('SELECT container_id, blip_x, blip_y, blip_z FROM containers WHERE owner = ?', {identifier}, function(results)
        if results and #results > 0 then
            
            for _, container in ipairs(results) do
                
                TriggerClientEvent('RK_scripts:container:createBlip', src, container.container_id, {x = container.blip_x, y = container.blip_y, z = container.blip_z})
            end
        else
            
        end
    end)
end)

RegisterServerEvent('RK_scripts:container:enterContainer', function(pin)
    local src = source
    local container = ContainerCache[tostring(pin)]
    if container then
        TriggerClientEvent('RK_scripts:container:enter', src, container.id, container.number)
        SetPlayerRoutingBucket(src, tonumber(container.id))
    else
        TriggerClientEvent('esx:showNotification', src, 'PIN non valido!')
    end
end)

RegisterServerEvent('RK_scripts:container:exitContainer', function()
    local src = source
    SetPlayerRoutingBucket(src, 0)
end)

AddEventHandler('playerDropped', function()
    local src = source
    SetPlayerRoutingBucket(src, 0)
end)
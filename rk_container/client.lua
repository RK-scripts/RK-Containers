ESX = nil

Citizen.CreateThread(function()
    while ESX == nil do
        ESX = exports["es_extended"]:getSharedObject()
        Citizen.Wait(0)
    end
end)

local CreatedZones = {}
local containerBlips = {}

local CurrentContainer = nil
local ContainerPed = nil
local InventoryProps = {}

AddEventHandler('playerSpawned', function()
  
    TriggerServerEvent('RK_scripts:container:loadBlips')
end)

AddEventHandler('onClientResourceStart', function(resourceName)
    if(GetCurrentResourceName() ~= resourceName) then
      return
    end

    TriggerServerEvent('RK_scripts:container:loadBlips')
end)

-- Funzione per creare il PED
local function CreateContainerPed()
    local model = GetHashKey('cs_movpremmale')
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(1)
    end

    ContainerPed = CreatePed(4, model, 
        Config_Container.CoordinateNpc.x,
        Config_Container.CoordinateNpc.y,
        Config_Container.CoordinateNpc.z,
        Config_Container.CoordinateNpc.w,
        false, true)

    SetEntityHeading(ContainerPed, Config_Container.CoordinateNpc.w)
    FreezeEntityPosition(ContainerPed, true)
    SetEntityInvincible(ContainerPed, true)
    SetBlockingOfNonTemporaryEvents(ContainerPed, true)

    exports.ox_target:addLocalEntity(ContainerPed, {
        {
            name = 'container_purchase',
            event = 'RK_scripts:scegli:container',
            icon = 'fas fa-home',
            label = 'Acquista Container'
        }
    })
end


AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
    if DoesEntityExist(ContainerPed) then
        DeleteEntity(ContainerPed)
    end
    if InventoryProps then
        for _, prop in pairs(InventoryProps) do
            if DoesEntityExist(prop) then
                DeleteObject(prop)
            end
        end
    end


   
    -- Rimuovi tutte le zone create
    if CreatedZones then
        for _, zoneId in pairs(CreatedZones) do
            exports.ox_target:removeZone(zoneId)
        end
        CreatedZones = {}
    end
end)


-- Crea il PED quando la risorsa viene avviata
CreateThread(function()
    CreateContainerPed()
   
end)

RegisterNetEvent('RK_scripts:container:setPIN', function(container_id, container_number, coords)
    ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'set_pin', {
        title = 'Imposta un PIN di 6 cifre per il tuo container'
    }, function(data, menu)
        local pin = tonumber(data.value)
        if pin and pin >= 100000 and pin <= 999999 then
            menu.close()
            TriggerServerEvent('RK_scripts:container:confirmPIN', container_id, container_number, pin, coords)
        else
            ESX.ShowNotification('Inserisci un PIN valido di 6 cifre')
        end
    end, function(data, menu)
        menu.close()
    end)
    TriggerServerEvent('RK_scripts:container:confirmPIN', container_id, container_number, pin, coords)
end)


RegisterNetEvent('RK_scripts:container:createBlip', function(container_id, coords)

    if containerBlips[container_id] then

        RemoveBlip(containerBlips[container_id])
    end

    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, 474)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 0.7)
    SetBlipColour(blip, 5)
    SetBlipAsShortRange(blip, true)

    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Il tuo Container")
    EndTextCommandSetBlipName(blip)

    containerBlips[container_id] = blip

end)

RegisterNetEvent('RK_scripts:scegli:container', function ()
    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'purchase_container', {
        title    = 'Acquista Container',
        align    = 'top-left',
        elements = {
            {label = 'Acquista Container ($' .. Config_Container.ContainerCost .. ')', value = 'purchase'},
            {label = 'Annulla', value = 'cancel'}
        }
    }, function(data, menu)
        if data.current.value == 'purchase' then
            menu.close()
            ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'select_container', {
                title    = 'Seleziona Container',
                align    = 'top-left',
                elements = Config_Container.Lista
            }, function(data2, menu2)
                local containerData = data2.current
                if containerData and containerData.value and containerData.entrata then
                    TriggerServerEvent('RK_scripts:container:purchase', containerData.value, {x = containerData.entrata.x, y = containerData.entrata.y, z = containerData.entrata.z})
                else
            
                end
                menu2.close()
            end, function(data2, menu2)
                menu2.close()
            end)
        else
            menu.close()
        end
    end, function(data, menu)
        menu.close()
    end)
end)

-- Funzione per entrare nel container
local InventoryProp = nil

local function EnterContainer()
    ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'enter_pin', {
        title = 'Inserisci il PIN del Container'
    }, function(data, menu)
        local pin = tonumber(data.value)
        if pin and pin >= 100000 and pin <= 999999 then
            menu.close()
            TriggerServerEvent('RK_scripts:container:enterContainer', pin)
        else
            ESX.ShowNotification('Inserisci un PIN valido di 6 cifre')
        end
    end, function(data, menu)
        menu.close()
    end)
end

local InventoryProps = {}

RegisterNetEvent('RK_scripts:container:enter', function(container_id, container_number)
    CurrentContainer = {id = container_id, number = container_number}
    SetEntityCoords(PlayerPedId(), Config_Container.Uscita)

    for _, zoneId in pairs(CreatedZones) do
        exports.ox_target:removeZone(zoneId)
    end
    CreatedZones = {}

    Citizen.SetTimeout(1000, function()
      
    end) 
    
    -- Crea i prop dell'inventario
    local model = GetHashKey('ex_prop_crate_jewels_racks_bc') -- Puoi cambiare questo con il modello del prop che preferisci
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(1)
    end
    
    
    for i, coords in pairs(Config_Container.Inventari) do
        local prop = CreateObject(model, coords.x, coords.y, coords.z - 1.0, false, false, false)
        SetEntityHeading(prop, 0.0)
        FreezeEntityPosition(prop, true)
        
        -- Aggiungi l'interazione con ox_target
        exports.ox_target:addLocalEntity(prop, {
            {
                name = 'container_inventory_' .. i,
                onSelect = function(data)
                    TriggerEvent('RK_scripts:container:openInventory', {inventoryNumber = i})
                end,
                icon = 'fas fa-box',
                label = 'Apri Inventario ' .. i,
            }
        })
        
        table.insert(InventoryProps, prop)


    end

    -- Aggiungi le altre zone di interazione come prima
    -- exports.ox_target:addSphereZone({
    --     coords = Config_Container.Camerino,
    --     radius = 1,
    --     options = {
    --         {
    --             name = 'container_changing_room',
    --             event = 'RK_scripts:container:openChangingRoom',
    --             icon = 'fas fa-tshirt',
    --             label = 'Apri Camerino'
    --         }
    --     }
    -- })



    local exitZoneId = exports.ox_target:addSphereZone({
        coords = Config_Container.Uscita,
        radius = 1,
        options = {
            {
                name = 'container_exit',
                event = 'RK_scripts:container:exit',
                icon = 'fas fa-door-open',
                label = 'Esci dal Container'
            }
        }
    })
    table.insert(CreatedZones, exitZoneId)
end)

RegisterNetEvent('RK_scripts:container:openInventory', function(data)
    if not data or not data.inventoryNumber then

        return
    end
    local inventoryNumber = data.inventoryNumber
    local stashId = 'Container' .. CurrentContainer.number .. '_' .. inventoryNumber

    exports.ox_inventory:openInventory('stash', stashId)
end)

RegisterNetEvent('RK_scripts:container:openChangingRoom', function()
    Config_Container.CamerinoFunzione()
end)

RegisterNetEvent('RK_scripts:container:exit', function()
    for k, v in pairs(Config_Container.Lista) do
        if tonumber(v.value) == tonumber(CurrentContainer.id) then
            SetEntityCoords(PlayerPedId(), v.entrata)
            break
        end
    end
    TriggerServerEvent('RK_scripts:container:exitContainer')
    
    -- Rimuovi i prop dell'inventario
    for i, prop in pairs(InventoryProps) do
        if DoesEntityExist(prop) then
            DeleteObject(prop)
        end
    end
    InventoryProps = {}
    
    -- Rimuovi tutte le zone create
    for _, zoneId in pairs(CreatedZones) do
        exports.ox_target:removeZone(zoneId)
    end
    CreatedZones = {}
    
    CurrentContainer = nil

    Citizen.SetTimeout(1000, function()
       
    end)   
end)

-- Aggiungi zone di interazione per ogni container
CreateThread(function()
    for k, v in pairs(Config_Container.Lista) do
        exports.ox_target:addSphereZone({
            coords = v.entrata,
            radius = 1.5,
            options = {
                {
                    name = 'container_enter_' .. v.value,
                    event = 'RK_scripts:container:tryEnter',
                    icon = 'fas fa-door-open',
                    label = 'Entra nel Container'
                }
            }
        })
    end
end)

RegisterNetEvent('RK_scripts:container:tryEnter', function()
    EnterContainer() 
end)

-- Gestione degli eventi di riavvio della risorsa
AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
    CreateContainerPed()

end)

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
    if DoesEntityExist(ContainerPed) then
        DeleteEntity(ContainerPed)
    end

end)
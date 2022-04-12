local QBCore = exports['qb-core']:GetCoreObject()

local Jobs = {}
local LastTime = nil

local function RunAt(h, m, cb)
	Jobs[#Jobs+1] = {
		h  = h,
		m  = m,
		cb = cb
	}
end

local function GetTime()
	local timestamp = os.time()
	local d = os.date('*t', timestamp).wday
	local h = tonumber(os.date('%H', timestamp))
	local m = tonumber(os.date('%M', timestamp))
	return {d = d, h = h, m = m}
end

local function OnTime(d, h, m)
	for i=1, #Jobs, 1 do
		if Jobs[i].h == h and Jobs[i].m == m then
			Jobs[i].cb(d, h, m)
		end
	end
end

local function Tick()
	local time = GetTime()
	if time.h ~= LastTime.h or time.m ~= LastTime.m then
		OnTime(time.d, time.h, time.m)
		LastTime = time
	end
	SetTimeout(60000, Tick)
end

LastTime = GetTime()

Tick()

local function InventoryItems()
    local results = MySQL.Sync.fetchAll('SELECT citizenid, inventory FROM players', {})
	if results[1] ~= nil then
        local citizenid = nil
        for k = 1, #results, 1 do
            local row = results[k]
            citizenid = row.citizenid
            local sentItems = {}
            local items = nil
            local isOnline = QBCore.Functions.GetPlayerByCitizenId(citizenid)
            if isOnline then
                items = isOnline.PlayerData.items
                for a, item in pairs(items) do
                    local itemInfo = QBCore.Shared.Items[item.name:lower()]
                    if item.info ~= nil and item.info.quality ~= nil then
                        local decayAmount = QBCore.Shared.Items[item.name:lower()]["decay"] ~= nil and QBCore.Shared.Items[item.name:lower()]["decay"] or 0.0
                        if item.info.quality == 0.0 then
                            -- do nothing
                        elseif (item.info.quality - decayAmount) > 0.0 then
                            item.info.quality = item.info.quality - decayAmount
                        elseif (item.info.quality - decayAmount) <= 0.0 then
                            item.info.quality = 0.0
                        end
                    else
                        if type(item.info) == 'table' then
                            item.info.quality = 100.0
                        elseif type(item.info) == 'string' and item.info == '' then
                            item.info = {}
                            item.info.quality = 100.0
                        end
                    end
                    local modifiedItem = {
                        name = itemInfo["name"],
                        amount = tonumber(item.amount),
                        info = item.info ~= nil and item.info or "",
                        label = itemInfo["label"],
                        description = itemInfo["description"] ~= nil and itemInfo["description"] or "",
                        weight = itemInfo["weight"], 
                        type = itemInfo["type"], 
                        unique = itemInfo["unique"], 
                        useable = itemInfo["useable"], 
                        image = itemInfo["image"],
                        slot = item.slot,
                    }
                    sentItems[#sentItems+1] = modifiedItem
                end
                isOnline.Functions.SetInventory(sentItems)
                TriggerClientEvent("inventory:client:UpdatePlayerInventory", isOnline.PlayerData.source, false)
            else
                if row.inventory ~= nil then
                    row.inventory = json.decode(row.inventory)
                    if row.inventory ~= nil then 
                        for l = 1, #row.inventory, 1 do
                            item = row.inventory[l]
                            local itemInfo = QBCore.Shared.Items[item.name:lower()]
                            if itemInfo ~= nil then
                                if item.info ~= nil and item.info.quality ~= nil then
                                    local decayAmount = QBCore.Shared.Items[item.name:lower()]["decay"] ~= nil and QBCore.Shared.Items[item.name:lower()]["decay"] or 0.0
                                    if item.info.quality == 0.0 then
                                        --do nothing
                                    elseif (item.info.quality - decayAmount) > 0.0 then
                                        item.info.quality = item.info.quality - decayAmount
                                    elseif (item.info.quality - decayAmount) <= 0.0 then
                                        item.info.quality = 0.0
                                    end
                                else
                                    if type(item.info) == 'table' then
                                        item.info.quality = 100.0
                                    elseif type(item.info) == 'string' and item.info == '' then
                                        item.info = {}
                                        item.info.quality = 100.0
                                    end
                                end
                                local modifiedItem = {
                                    name = itemInfo["name"],
                                    amount = tonumber(item.amount),
                                    info = item.info ~= nil and item.info or "",
                                    label = itemInfo["label"],
                                    description = itemInfo["description"] ~= nil and itemInfo["description"] or "",
                                    weight = itemInfo["weight"], 
                                    type = itemInfo["type"], 
                                    unique = itemInfo["unique"], 
                                    useable = itemInfo["useable"], 
                                    image = itemInfo["image"],
                                    slot = item.slot,
                                }
                                sentItems[#sentItems+1] = modifiedItem
                            end
                        end
                        MySQL.Async.execute('UPDATE players SET inventory = ? WHERE citizenid = ?', { json.encode(sentItems), citizenid })
                    end
                end
            end
            Wait(500)
        end
	end
end

local function StashItems()
    local results = MySQL.Sync.fetchAll('SELECT * FROM stashitems', {})
	if results[1] ~= nil then
        local id = nil
        for k = 1, #results, 1 do
            local row = results[k]
            id = row.id
            local items = {}
            if row.items ~= nil then
                row.items = json.decode(row.items)
                if row.items ~= nil then 
                    for l, p in pairs(row.items) do
                        item = row.items[l]
                        local itemInfo = QBCore.Shared.Items[item.name:lower()]
                        if item.info ~= nil and item.info.quality ~= nil then
                            local decayAmount = QBCore.Shared.Items[item.name:lower()]["decay"] ~= nil and QBCore.Shared.Items[item.name:lower()]["decay"] or 0.0
                            if item.info.quality == 0.0 then
                                --do nothing
                            elseif (item.info.quality - decayAmount) > 0.0 then
                                item.info.quality = item.info.quality - decayAmount
                            elseif (item.info.quality - decayAmount) <= 0.0 then
                                item.info.quality = 0.0
                            end
                        else
                            if type(item.info) == 'table' then
                                item.info.quality = 100.0
                            elseif type(item.info) == 'string' and item.info == '' then
                                item.info = {}
                                item.info.quality = 100.0
                            end
                        end
                        local modifiedItem = {
                            name = itemInfo["name"],
                            amount = tonumber(item.amount),
                            info = item.info ~= nil and item.info or "",
                            label = itemInfo["label"],
                            description = itemInfo["description"] ~= nil and itemInfo["description"] or "",
                            weight = itemInfo["weight"], 
                            type = itemInfo["type"], 
                            unique = itemInfo["unique"], 
                            useable = itemInfo["useable"], 
                            image = itemInfo["image"],
                            slot = item.slot,
                        }
                        items[#items+1] = modifiedItem
                    end
                end
            end
            MySQL.Async.execute('UPDATE stashitems SET items = ? WHERE id = ?', { json.encode(items), id })
            Wait(500)
        end
	end
end

local function GloveboxItems()
    local results = MySQL.Sync.fetchAll('SELECT * FROM gloveboxitems', {})
	if results[1] ~= nil then
        local id = nil
        for k = 1, #results, 1 do
            local row = results[k]
            id = row.id
            local items = {}
            if row.items ~= nil then
                row.items = json.decode(row.items)
                if row.items ~= nil then 
                    for l, p in pairs(row.items) do
                        item = row.items[l]
                        local itemInfo = QBCore.Shared.Items[item.name:lower()]
                        if item.info ~= nil and item.info.quality ~= nil then
                            local decayAmount = QBCore.Shared.Items[item.name:lower()]["decay"] ~= nil and QBCore.Shared.Items[item.name:lower()]["decay"] or 0.0
                            if item.info.quality == 0.0 then
                                --do nothing
                            elseif (item.info.quality - decayAmount) > 0.0 then
                                item.info.quality = item.info.quality - decayAmount
                            elseif (item.info.quality - decayAmount) <= 0.0 then
                                item.info.quality = 0.0
                            end
                        else
                            if type(item.info) == 'table' then
                                item.info.quality = 100.0
                            elseif type(item.info) == 'string' and item.info == '' then
                                item.info = {}
                                item.info.quality = 100.0
                            end

                        end
                        local modifiedItem = {
                            name = itemInfo["name"],
                            amount = tonumber(item.amount),
                            info = item.info ~= nil and item.info or "",
                            label = itemInfo["label"],
                            description = itemInfo["description"] ~= nil and itemInfo["description"] or "",
                            weight = itemInfo["weight"], 
                            type = itemInfo["type"], 
                            unique = itemInfo["unique"], 
                            useable = itemInfo["useable"], 
                            image = itemInfo["image"],
                            slot = item.slot,
                        }
                        items[#items+1] = modifiedItem
                    end
                end
            end
            MySQL.Async.execute('UPDATE gloveboxitems SET items = ? WHERE id = ?', { json.encode(items), id })
            Wait(500)
        end
	end
end

local function TrunkItems()
    local results = MySQL.Sync.fetchAll('SELECT * FROM trunkitems', {})
	if results[1] ~= nil then
        local id = nil
        for k = 1, #results, 1 do
            local row = results[k]
            id = row.id
            local items = {}
            if row.items ~= nil then
                row.items = json.decode(row.items)
                if row.items ~= nil then
                    for l, p in pairs(row.items) do
                        item = row.items[l]
                        local decayAmount = QBCore.Shared.Items[item.name:lower()]["decay"] ~= nil and QBCore.Shared.Items[item.name:lower()]["decay"] or 0.0
                        local itemInfo = QBCore.Shared.Items[item.name:lower()]
                        if item.info ~= nil and item.info.quality ~= nil and decayAmount > 0.0 then
                            if item.info.quality == 0.0 then
                                --do nothing
                            elseif (item.info.quality - decayAmount) > 0.0 then
                                item.info.quality = item.info.quality - decayAmount
                            elseif (item.info.quality - decayAmount) <= 0.0 then
                                item.info.quality = 0.0
                            end
                        else
                            if type(item.info) == 'table' then
                                item.info.quality = 100.0
                            elseif type(item.info) == 'string' and item.info == '' then
                                item.info = {}
                                item.info.quality = 100.0
                            end

                        end
                        local modifiedItem = {
                            name = itemInfo["name"],
                            amount = tonumber(item.amount),
                            info = item.info ~= nil and item.info or "",
                            label = itemInfo["label"],
                            description = itemInfo["description"] ~= nil and itemInfo["description"] or "",
                            weight = itemInfo["weight"], 
                            type = itemInfo["type"], 
                            unique = itemInfo["unique"], 
                            useable = itemInfo["useable"], 
                            image = itemInfo["image"],
                            slot = item.slot,
                        }
                        items[#items+1] = modifiedItem
                    end
                end
            end
            MySQL.Async.execute('UPDATE trunkitems SET items = ? WHERE id = ?', { json.encode(items), id })
            Wait(500)
        end
	end
end

local function Decay()
    InventoryItems()
    Wait(500)
    StashItems()
    Wait(500)
    TrunkItems()
    Wait(500)
    GloveboxItems()
end

CreateThread(function()
    for k = 1, #Config.Decay, 1 do
        time = Config.Decay[k]
        RunAt(time, 00, Decay)
    end
end)

QBCore.Commands.Add("forcedecay", "Description", {}, true, function(source, args)  
    InventoryItems()
    StashItems()
    TrunkItems()
    GloveboxItems()
end, "god")
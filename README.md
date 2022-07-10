# Inventory Decay

![image](https://user-images.githubusercontent.com/80186604/163069477-114e14ec-bec1-4f93-8421-42017c605f15.png)

## Credits:
>### aj - aj-inventory
>### loljoshie - lj-inventory
>### qbcore - qb-inventory

## Installation

you need to add a decay and created value in your qb-core/shared/items for all items, the decay is set to be the days the item lasts

```lua
["created"] = nil
["decay"] = 28.0 -- for 28 days
```

## Changes to QB-CORE

### self.Functions.AddItem | server/player.lua | replace with below:
```lua
self.Functions.AddItem = function(item, amount, slot, info, created)
    local totalWeight = QBCore.Player.GetTotalWeight(self.PlayerData.items)
    local itemInfo = QBCore.Shared.Items[item:lower()]
    local time = os.time()
    if not created then 
        itemInfo['created'] = time
    else 
        itemInfo['created'] = created
    end
    -- itemInfo['created'] = time
    if itemInfo["type"] == 'item' and info == nil then
        info = { quality = 100 }
    end
    if itemInfo == nil then
        TriggerClientEvent('QBCore:Notify', self.PlayerData.source, Lang:t('error.item_not_exist'), 'error')
        return
    end
    local amount = tonumber(amount)
    local slot = tonumber(slot) or QBCore.Player.GetFirstSlotByItem(self.PlayerData.items, item)
    if itemInfo['type'] == 'weapon' and info == nil then
        info = {
            serie = tostring(QBCore.Shared.RandomInt(2) .. QBCore.Shared.RandomStr(3) .. QBCore.Shared.RandomInt(1) .. QBCore.Shared.RandomStr(2) .. QBCore.Shared.RandomInt(3) .. QBCore.Shared.RandomStr(4)),
        }
    end
    if (totalWeight + (itemInfo['weight'] * amount)) <= QBCore.Config.Player.MaxWeight then
        if (slot and self.PlayerData.items[slot]) and (self.PlayerData.items[slot].name:lower() == item:lower()) and self.PlayerData.items[slot].info.quality == info.quality and (itemInfo['type'] == 'item' and not itemInfo['unique']) then
            self.PlayerData.items[slot].amount = self.PlayerData.items[slot].amount + amount
            self.Functions.UpdatePlayerData()
            TriggerEvent('qb-log:server:CreateLog', 'playerinventory', 'AddItem', 'green', '**' .. GetPlayerName(self.PlayerData.source) .. ' (citizenid: ' .. self.PlayerData.citizenid .. ' | id: ' .. self.PlayerData.source .. ')** got item: [slot:' .. slot .. '], itemname: ' .. self.PlayerData.items[slot].name .. ', added amount: ' .. amount .. ', new total amount: ' .. self.PlayerData.items[slot].amount)
            return true
        elseif not itemInfo['unique'] or (not slot or slot == nil) or itemInfo['type'] == 'item' and self.PlayerData.items[slot].info.quality ~= info.quality and self.PlayerData.items[slot].name:lower() == item:lower() then
            for i = 1, QBConfig.Player.MaxInvSlots, 1 do
                if self.PlayerData.items[i] == nil then
                    self.PlayerData.items[i] = { name = itemInfo['name'], amount = amount, info = info or '', label = itemInfo['label'], description = itemInfo['description'] or '', weight = itemInfo['weight'], type = itemInfo['type'], unique = itemInfo['unique'], useable = itemInfo['useable'], image = itemInfo['image'], shouldClose = itemInfo['shouldClose'], slot = i, combinable = itemInfo['combinable'], created = itemInfo['created'] }
                    self.Functions.UpdatePlayerData()
                    TriggerEvent('qb-log:server:CreateLog', 'playerinventory', 'AddItem', 'green', '**' .. GetPlayerName(self.PlayerData.source) .. ' (citizenid: ' .. self.PlayerData.citizenid .. ' | id: ' .. self.PlayerData.source .. ')** got item: [slot:' .. i .. '], itemname: ' .. self.PlayerData.items[i].name .. ', added amount: ' .. amount .. ', new total amount: ' .. self.PlayerData.items[i].amount)
                

                    return true
                end
            end
        elseif (itemInfo['unique']) or (not slot or slot == nil) or (itemInfo['type'] == 'weapon') then
            for i = 1, QBConfig.Player.MaxInvSlots, 1 do
                if self.PlayerData.items[i] == nil then
                    self.PlayerData.items[i] = { name = itemInfo['name'], amount = amount, info = info or '', label = itemInfo['label'], description = itemInfo['description'] or '', weight = itemInfo['weight'], type = itemInfo['type'], unique = itemInfo['unique'], useable = itemInfo['useable'], image = itemInfo['image'], shouldClose = itemInfo['shouldClose'], slot = i, combinable = itemInfo['combinable'], created = itemInfo['created'] }
                    self.Functions.UpdatePlayerData()
                    TriggerEvent('qb-log:server:CreateLog', 'playerinventory', 'AddItem', 'green', '**' .. GetPlayerName(self.PlayerData.source) .. ' (citizenid: ' .. self.PlayerData.citizenid .. ' | id: ' .. self.PlayerData.source .. ')** got item: [slot:' .. i .. '], itemname: ' .. self.PlayerData.items[i].name .. ', added amount: ' .. amount .. ', new total amount: ' .. self.PlayerData.items[i].amount)
                    return true
                end
            end
        end
    else
        TriggerClientEvent('QBCore:Notify', self.PlayerData.source, Lang:t('error.too_heavy'), 'error')
    end
    return false
end
```


### QBCore.Player.LoadInventory | server/player.lua | replace with below:
```lua
function QBCore.Player.LoadInventory(PlayerData)
    PlayerData.items = {}
    local inventory = MySQL.Sync.prepare('SELECT inventory FROM players WHERE citizenid = ?', { PlayerData.citizenid })
    local missingItems = {}
    if inventory then
        inventory = json.decode(inventory)
        if next(inventory) then
            for _, item in pairs(inventory) do
                if item then
                    local itemInfo = QBCore.Shared.Items[item.name:lower()]
                    if itemInfo then
                        PlayerData.items[item.slot] = {
                            name = itemInfo['name'],
                            amount = item.amount,
                            info = item.info or '',
                            label = itemInfo['label'],
                            description = itemInfo['description'] or '',
                            weight = itemInfo['weight'],
                            type = itemInfo['type'],
                            unique = itemInfo['unique'],
                            useable = itemInfo['useable'],
                            image = itemInfo['image'],
                            shouldClose = itemInfo['shouldClose'],
                            slot = item.slot,
                            combinable = itemInfo['combinable'],
                            created = item.created,
                        }
                    else
                        missingItems[#missingItems+1] = item.name:lower()
                    end

                end
            end
        end
    end

    if #missingItems > 0 then
        print(("%s the following items removed as they no longer exist: %s"):format(GetPlayerName(PlayerData.source), json.encode(missingItems)))
    end
    return PlayerData
end
```

### QBCore.Player.SaveInventory | server/player.lua | replace with below:
```lua
function QBCore.Player.SaveInventory(source)
    if not QBCore.Players[source] then return end
    local PlayerData = QBCore.Players[source].PlayerData
    local items = PlayerData.items
    local ItemsJson = {}
    if items and next(items) then
        for slot, item in pairs(items) do
            if items[slot] then
                ItemsJson[#ItemsJson+1] = {
                    name = item.name,
                    amount = item.amount,
                    info = item.info,
                    type = item.type,
                    slot = slot,
                    created = item.created
                }
            end
        end
        MySQL.Async.prepare('UPDATE players SET inventory = ? WHERE citizenid = ?', { json.encode(ItemsJson), PlayerData.citizenid })
    else
        MySQL.Async.prepare('UPDATE players SET inventory = ? WHERE citizenid = ?', { '[]', PlayerData.citizenid })
    end
end
```


# if u are on Latest updated qbcore u need to replace these function not above


### self.Functions.AddItem | server/player.lua | replace with below:

```lua
    function self.Functions.AddItem(item, amount, slot, info,created)
        local totalWeight = QBCore.Player.GetTotalWeight(self.PlayerData.items)
        local itemInfo = QBCore.Shared.Items[item:lower()]

        local time = os.time()
        if not created then 
            itemInfo['created'] = time
        else 
            itemInfo['created'] = created
        end
        -- itemInfo['created'] = time
        if itemInfo["type"] == 'item' and info == nil then
            info = { quality = 100 }
        end

        if not itemInfo and not self.Offline then
            TriggerClientEvent('QBCore:Notify', self.PlayerData.source, Lang:t('error.item_not_exist'), 'error')
            return
        end

        amount = tonumber(amount)
        slot = tonumber(slot) or QBCore.Player.GetFirstSlotByItem(self.PlayerData.items, item)
        if itemInfo['type'] == 'weapon' and not info then
            info = {
                serie = tostring(QBCore.Shared.RandomInt(2) .. QBCore.Shared.RandomStr(3) .. QBCore.Shared.RandomInt(1) .. QBCore.Shared.RandomStr(2) .. QBCore.Shared.RandomInt(3) .. QBCore.Shared.RandomStr(4)),
            }
        end
        if (totalWeight + (itemInfo['weight'] * amount)) <= QBCore.Config.Player.MaxWeight then
            if (slot and self.PlayerData.items[slot]) and (self.PlayerData.items[slot].name:lower() == item:lower()) and self.PlayerData.items[slot].info.quality == info.quality and (itemInfo['type'] == 'item' and not itemInfo['unique']) then
 
                self.PlayerData.items[slot].amount = self.PlayerData.items[slot].amount + amount
 

                if not self.Offline then
                    self.Functions.UpdatePlayerData()
                    TriggerEvent('qb-log:server:CreateLog', 'playerinventory', 'AddItem', 'green', '**' .. GetPlayerName(self.PlayerData.source) .. ' (citizenid: ' .. self.PlayerData.citizenid .. ' | id: ' .. self.PlayerData.source .. ')** got item: [slot:' .. slot .. '], itemname: ' .. self.PlayerData.items[slot].name .. ', added amount: ' .. amount .. ', new total amount: ' .. self.PlayerData.items[slot].amount)
                end

                return true

            elseif not itemInfo['unique'] or (not slot or slot == nil) or itemInfo['type'] == 'item' and self.PlayerData.items[slot].info.quality ~= info.quality and self.PlayerData.items[slot].name:lower() == item:lower() then
                for i = 1, QBConfig.Player.MaxInvSlots, 1 do
                    if self.PlayerData.items[i] == nil then
                        self.PlayerData.items[i] = { name = itemInfo['name'], amount = amount, info = info or '', label = itemInfo['label'], description = itemInfo['description'] or '', weight = itemInfo['weight'], type = itemInfo['type'], unique = itemInfo['unique'], useable = itemInfo['useable'], image = itemInfo['image'], shouldClose = itemInfo['shouldClose'], slot = i, combinable = itemInfo['combinable'], created = itemInfo['created'] }

                        if not self.Offline then
                            self.Functions.UpdatePlayerData()
                            TriggerEvent('qb-log:server:CreateLog', 'playerinventory', 'AddItem', 'green', '**' .. GetPlayerName(self.PlayerData.source) .. ' (citizenid: ' .. self.PlayerData.citizenid .. ' | id: ' .. self.PlayerData.source .. ')** got item: [slot:' .. i .. '], itemname: ' .. self.PlayerData.items[i].name .. ', added amount: ' .. amount .. ', new total amount: ' .. self.PlayerData.items[i].amount)
                        end

                        return true
                    end
                end

            elseif itemInfo['unique'] or (not slot or slot == nil) or itemInfo['type'] == 'weapon' then
                for i = 1, QBConfig.Player.MaxInvSlots, 1 do
                    if self.PlayerData.items[i] == nil then
                        self.PlayerData.items[i] = { name = itemInfo['name'], amount = amount, info = info or '', label = itemInfo['label'], description = itemInfo['description'] or '', weight = itemInfo['weight'], type = itemInfo['type'], unique = itemInfo['unique'], useable = itemInfo['useable'], image = itemInfo['image'], shouldClose = itemInfo['shouldClose'], slot = i, combinable = itemInfo['combinable'], created = itemInfo['created'] }

                        if not self.Offline then
                            self.Functions.UpdatePlayerData()
                            TriggerEvent('qb-log:server:CreateLog', 'playerinventory', 'AddItem', 'green', '**' .. GetPlayerName(self.PlayerData.source) .. ' (citizenid: ' .. self.PlayerData.citizenid .. ' | id: ' .. self.PlayerData.source .. ')** got item: [slot:' .. i .. '], itemname: ' .. self.PlayerData.items[i].name .. ', added amount: ' .. amount .. ', new total amount: ' .. self.PlayerData.items[i].amount)
                        end

                        return true
                    end
                end
            end
        elseif not self.Offline then
            TriggerClientEvent('QBCore:Notify', self.PlayerData.source, Lang:t('error.too_heavy'), 'error')
        end
        return false
    end
```




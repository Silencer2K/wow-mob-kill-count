local addonName, addon = ...

LibStub('AceAddon-3.0'):NewAddon(addon, addonName, 'AceEvent-3.0')

local L = LibStub('AceLocale-3.0'):GetLocale(addonName)

local COLOR_SILVER = 'ffc7c7cf'

function addon:OnInitialize()
    self.db = LibStub('AceDB-3.0'):New('MobKillCountDB')

    self:RegisterEvent('COMBAT_LOG_EVENT_UNFILTERED', function(...)
        addon:OnCombatEvent(...)
    end)

    self:RegisterEvent('ZONE_CHANGED_NEW_AREA', function(...)
        addon:OnZoneChanged(...)
    end)

    GameTooltip:HookScript('OnTooltipCleared', function(self)
        addon:OnGameTooltipCleared(self)
    end)

    GameTooltip:HookScript('OnTooltipSetUnit', function(self)
        addon:OnGameTooltipSetUnit(self)
    end)

    self.mobHitCache = {}
end

function addon:UnitInfoFromGuid(guid)
    local parts = {strsplit('-', guid)}
    local type = parts[1]

    if type == 'Creature' or type == 'Vehicle' then
        local id = tonumber(parts[6])
        return type, id
    end

    return type
end

function addon:GetPlayerName()
    local name = GetUnitName('player')
    local _, class = UnitClass('player')

    return string.format(
        '|c%s%s|r',
        RAID_CLASS_COLORS[class].colorStr,
        name
    )
end

function addon:OnCombatEvent(event, timeStamp, logEvent, hideCaster,
    sourceGuid, sourceName, sourceFlags, sourceFlags2,
    destGuid, destName, destFlags, destFlags2, ...
)
    if destGuid then
        local type, id = self:UnitInfoFromGuid(destGuid)

        if type == 'Creature' or type == 'Vehicle' then
            if logEvent:match('_DAMAGE$') then
                if sourceGuid == UnitGUID('player') then
                    if self.mobHitCache[destGuid] == nil then
                        self.mobHitCache[destGuid] = 1
                    end
                end

            elseif logEvent == 'UNIT_DIED' or logEvent == 'PARTY_KILL' then
                if self.mobHitCache[destGuid] and self.mobHitCache[destGuid] ~= 0 then
                    self.mobHitCache[destGuid] = 0
                    self:IncMobKillCount(id)
                end
            end
        end
    end
end

function addon:OnZoneChanged()
    self.mobHitCache = {}
end

function addon:OnGameTooltipCleared(tooltip)
end

function addon:OnGameTooltipSetUnit(tooltip)
    local name, unit = tooltip:GetUnit()

    if unit then
        local guid = UnitGUID(unit)

        if (guid) then
            local type, id = self:UnitInfoFromGuid(guid)

            if type == 'Creature' or type == 'Vehicle' then
                if UnitIsDead(unit) and self.mobHitCache[guid] and self.mobHitCache[guid] ~= 0 then
                    self:IncMobKillCount(id, 1)
                end

                local byChar = self:GetMobKillCountFromDb(id, self.db.char)
                local total  = self:GetMobKillCountFromDb(id, self.db.global)

                if byChar > 0 or total > 0 or not UnitIsFriend(unit, 'player') then
                    tooltip:AddDoubleLine(
                        string.format(
                            L.tooltip_text,
                            COLOR_SILVER,
                            self:GetPlayerName()
                        ),
                        string.format(
                            '|c%s%s / %s|r',
                            COLOR_SILVER,
                            byChar,
                            total
                        )
                    )
                end
            end
        end
    end
end

function addon:IncMobKillCountInDb(id, db)
    if db.killCount == nil then
        db.killCount = {}
    end

    if db.killCount[id] == nil then
        db.killCount[id] = 1
    else
        db.killCount[id] = db.killCount[id] + 1
    end

    return db.killCount[id]
end

function addon:GetMobKillCountFromDb(id, db)
    if db.killCount == nil or db.killCount[id] == nil then
        return 0
    end

    return db.killCount[id]
end

function addon:IncMobKillCount(id, quiet)
    self:IncMobKillCountInDb(id, self.db.char)
    self:IncMobKillCountInDb(id, self.db.global)

    local total = self:IncMobKillCountInDb(0, self.db.char)
    self:IncMobKillCountInDb(0, self.db.global)
end

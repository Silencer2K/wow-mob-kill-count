local addonName, addon = ...

LibStub('AceAddon-3.0'):NewAddon(addon, addonName, 'AceEvent-3.0')

local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

local COLOR_SILVER = 'ffc7c7cf'

local function OnCombatEvent(event, timeStamp, logEvent, hideCaster,
                             sourceGuid, sourceName, sourceFlags, sourceFlags2,
                             destGuid, destName, destFlags, destFlags2
)
	if logEvent == 'PARTY_KILL' then
		if bit.band(destFlags, COMBATLOG_OBJECT_CONTROL_NPC) > 0 then
			addon:UpdateMobKillCount(destName)
		end
	end
end

function addon:OnInitialize()
	self.db = LibStub('AceDB-3.0'):New('MobKillCountDB')
	self:RegisterEvent('COMBAT_LOG_EVENT', OnCombatEvent)

	GameTooltip:HookScript('OnTooltipCleared', function(self)
		addon:OnGameTooltipCleared(self)
	end);
	GameTooltip:HookScript('OnTooltipSetUnit', function(self)
		addon:OnGameTooltipSetUnit(self)
	end);
end

function addon:OnEnable()
end

function addon:OnDisable()
end

function addon:UpdateMobKillCountInDb(name, db)
	if db.killCount == nil then
		db.killCount = {}
	end
	if db.killCount[name] == nil then
		db.killCount[name] = 1
	else
		db.killCount[name] = db.killCount[name] + 1
	end
	return db.killCount[name]
end

function addon:GetMobKillCountFromDb(name, db)
	if db.killCount == nil then
		db.killCount = {}
	end
	if db.killCount[name] == nil then
		return 0
	end
	return db.killCount[name]
end

function addon:UpdateMobKillCount(name)
	self:UpdateMobKillCountInDb(name, self.db.char)
	self:UpdateMobKillCountInDb(name, self.db.global)

	self:UpdateMobKillCountInDb('__total__', self.db.char)
	self:UpdateMobKillCountInDb('__total__', self.db.global)
end

function addon:GetPlayerName()
	local name = GetUnitName("player")
	local _, class = UnitClass("player")

	return string.format(
		'|c%s%s|r',
		RAID_CLASS_COLORS[class].colorStr,
		name
	)
end

function addon:OnGameTooltipCleared(tooltip)
end

function addon:OnGameTooltipSetUnit(tooltip)
	local name, unit = tooltip:GetUnit()
	if unit and not UnitIsPlayer(unit) then
		tooltip:AddDoubleLine(
			string.format(
				L.tooltip_text,
				COLOR_SILVER,
				self:GetPlayerName(),
				COLOR_SILVER
			),
			string.format(
				'|c%s%s / %s|r',
				COLOR_SILVER,
				self:GetMobKillCountFromDb(name, self.db.char),
				self:GetMobKillCountFromDb(name, self.db.global)
			)
		)
	end
end

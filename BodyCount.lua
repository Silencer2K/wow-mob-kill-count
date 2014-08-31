local addonName = ...

local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)

local L = LibStub('AceLocale-3.0'):GetLocale(addonName)

function addon:InitializeBodyCount()
	local bodyCount = CreateFrame('Frame', nil, UIParent)

	function bodyCount:Update(count, quiet)
		-- print('Total:', count)
	end

	self.bodyCount = bodyCount
end

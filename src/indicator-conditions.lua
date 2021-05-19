local A, _, L, Cache = Tabu:Spread(...);

local COMPARERS = {
	["="] = function(current, expected) return current == expected end,
	["<"] = function(current, expected) return current < expected end,
	["<="] = function(current, expected) return current <= expected end,
	[">"] = function(current, expected) return current > expected end,
	[">="] = function(current, expected) return current >= expected end,
}

local CMN = {};
_.mixin(CMN, {
	InstanceCheck = function(yesValue, instanceTypeValue)

		local yes, instanceType = IsInInstance();
		-- instanceType:
		-- "none" when outside an instance
		-- "pvp" when in a battleground
		-- "arena" when in an arena
		-- "party" when in a 5-man instance
		-- "raid" when in a raid instance
		-- nil when in a scenario


		if (yes == nil and yesValue == nil) then
			return true;
		end
		if (yes ~= yesValue) then
			return false;
		end

		if not instanceTypeValue then return true end

		if (type(instanceTypeValue) == "table") then
			return _.arrayHasAny(instanceTypeValue, instanceTypeValue);
		end
		
		return instanceTypeValue == instanceType

	end,
	Cooldown = function(entityType, entityId)
		local start, duration;
		if entityType == "spell" then
			start, duration = CMN.SpellCooldown(entityId);
		elseif entityType == "item" then
			start, duration = CMN.ItemCooldown(entityId);
		end
		return start, duration
	end,
	SpellCooldown = function(spell)
		-- local isKnown = IsSpellKnown(spellId);
		-- if isKnown == false then return end;
		return GetSpellCooldown(spell);
	end,
	ItemCooldown = function(itemID)
		return GetSpellCooldown(itemID);
	end,
	GetAura = function(unit, entityId, filter)
		-- name, rank, icon, count, debuffType, 
		-- duration, expirationTime, unitCaster, isStealable, 
		-- shouldConsolidate, spellId
		--local entityName = GetSpellInfo(entityId);
		return _.getUnitAura(unit, entityId, filter);
		--return UnitAura(unit, entityName, nil, filter);
	end,
	HasAura = function(unit, entityId, filter)
		local name, icon, count, debufType = CMN.GetAura(unit, entityId, filter);
		return name ~= nil, icon;
	end,
	HasDebuff = function(unit, entityId)
		return CMN.HasAura(unit, entityId, "HARMFUL");
	end,
	HasBuff = function(unit, entityId)
		return CMN.HasAura(unit, entityId, "HELPFUL");
	end,
});

local CONDITIONS = {
	------
	incombat = { 
		label = "In combat", 
		exec = function()
			return InCombatLockdown();
		end
	},
	inpartyorraid = {
		label = "In party or raid",
		exec = function()
			return UnitInRaid("player") or UnitInParty("player");
		end
	},
	indungeon = {
		label = "In a dungeon",
		exec = function()
			return CMN.InstanceCheck(true, { "party", "raid" });
		end
	},
	inbattleground = {
		label = "In a battleground",
		exec = function()
			return CMN.InstanceCheck(true, "pvp");
		end
	},
	inarena = {
		label = "In an arena",
		exec = function()
			return CMN.InstanceCheck(true, "arena");
		end
	},
	-------
	cooldown = {
		label = "Has cooldown",
		exec = function(item)
			local start, duration = CMN.Cooldown(item.type, item.info.id);
			return start and start > 0 and duration > 1.5 or false;
			-- local start, duration;
			-- if (item.type == "item") then
			-- 	start, duration = CMN.ItemCooldown(item.typeName);
			-- elseif (item.type == "spell") then
			-- 	start, duration = CMN.SpellCooldown(item.typeName);
			-- end
			-- -- local start, duration = CMN.Cooldown(entityType, entityId);
			-- return start and start > 0;
		end
	},
	playerDebuff = {
		label = "Player has a debuff",
		exec = function(item)
			local yes, icon = CMN.HasDebuff("player", item.typeName);
			if (icon and not item.info.icon) then
				item.info.icon = icon;
			end
			return yes;
		end
	},
	playerBuff = {
		label = "Player has a buff",
		exec = function(item)
			local yes, icon = CMN.HasBuff("player", item.typeName);
			if (icon and not item.info.icon) then
				item.info.icon = icon;
			end
			return yes;
		end
	},	
	-------
	spellcastcount = {
		label = "Spell casts count (by mana)",
		exec = function(spellType, spellId)
			return _.getSpellManaCount(spellId) or 0;
		end
	},
	notenoughmana = {
		label = "Not enough mana for spell",
		exec = function(spellType, spellId)
			local pm = UnitPower("player", 0);
			local cost = _.getSpellManaCost(spellId);
			return cost > pm;
		end
	}
}


A.IndiConditions = {
	CheckCondition = function (...)
		local item, conditionKey, compare, expectedValue = select(1, ...);
		local check = CONDITIONS[conditionKey];
		local currentValue = check.exec(item);
		local res = COMPARERS[compare](currentValue, expectedValue);
		return res;
	end
}


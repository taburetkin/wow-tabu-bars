local A, _, L = Tabu:Spread(...);

A.COMMONFRAME = CreateFrame("Frame", nil, UIParent, "SecureHandlerAttributeTemplate");

-- local F = [[Interface\AddOns\Tabu-Bars\]];
-- TabuBars.Fonts = {
-- 	ActionMan = F..[[Fonts\ActionMan.ttf]],
-- 	ContinuumMedium = F..[[Fonts\ContinuumMedium.ttf]],
-- 	DieDieDie = F..[[Fonts\DieDieDie.ttf]],
-- 	Expressway = F..[[Fonts\Expressway.ttf]],
-- 	Homespun = F..[[Fonts\Homespun.ttf]],
-- 	Invisible = F..[[Fonts\Invisible.ttf]],
-- 	PTSansNarrow = F..[[Fonts\PTSansNarrow.ttf]]
-- }



A.barsChangeDisabled = function()
	return InCombatLockdown();
	--return TabuBars.inCombat == true;
end

A.LockAnounce = function(type)
	_.print("Any changes not allowed while in combat", type);
end

A.Locked = function(type)
	if (A.barsChangeDisabled()) then
		A.LockAnounce(type);
		return true;
	end
	return false;
end

A.isDragging = function()
	return A.awaitingDrop == true;
end

A.dragStart = function()
	A.awaitingDrop = true;
	A.COMMONFRAME:SetAttribute("dragging", TabuBars.awaitingDrop);
	A.Bar.ShowLastButtons();
end

A.dragStop = function()
	A.awaitingDrop = false;
	A.COMMONFRAME:SetAttribute("dragging", TabuBars.awaitingDrop);
	A.Bar.HideLastButtons();
end


A.GetCursorInfoData = function()
	local thingType, id, arg, arg2 = GetCursorInfo();
	local info;
	local rType, rTypeName;
	if (thingType == "spell") then
		local sa, sb = GetSpellBookItemInfo(id, arg);
		info = _.GetSpellInfoTable(sb);
		return {
			type = "spell",
			typeName = info.name,
			attrs = {
				["*type1"] = "spell",
				spell = info.name,
				entity_id = info.id,
			},
			info = info
		};
	elseif (thingType == "item") then
		info = _.GetItemInfoTable(id);
		return {
			type = "item",
			typeName = info.name,
			attrs = {
				["*type1"] = "item",
				item = info.name,
				entity_id = info.id
			},
			info = info			
		}
	elseif (thingType == "macro") then
		info = _.GetMacroInfoTable(id);
		return {
			type = "macro",
			typeName = info.name,
			attrs = {
				["*type1"] = "macro",
				macro = info.name,
				entity_id = info.id
			},
			info = info				
		}
	end
	print("MISSING CASE", thingType, id, arg, arg2);
end

-- print();
-- print(unpack(select(2,...)));

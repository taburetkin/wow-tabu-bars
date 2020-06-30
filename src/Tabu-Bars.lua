local A, _, L, Cache = Tabu:Spread(...);

local function tabubarsSlashProcessor(type)
	local subtype;
	if (type == "" or type == nil) then
		type = "info"
	end

	local type, subtype = strsplit(" ", type);

	if (type == "add") then
		A.Bar.NewBar();
	elseif (type == "wipeall") then
		wipe(Cache());
		ReloadUI();
	elseif (type == "wipe") then
		if (subtype) then
			Cache().bars[subtype] = nil;
		else
			_.print("Wrong command use", type);
		end
	elseif (type == "dump") then
		Tabu.dump(Cache());
	elseif (type == "info") then
		A.ShowInfo();
	elseif (type == "debug") then
		A.debug();
	elseif (type == "inspect") then
		local model = A.Models.GetById(subtype);
		Tabu.dump(model and model.item);
	elseif (type == "disable") then
		if (not subtype) then 
			_.print('specify what to disable, id or "all"');
			return 
		elseif (subtype == "all") then
			A.Bar.Iterate(A.Bar.Disable)
		else
			local model = A.Models.GetById(subtype);
			if (not model) then return end;
			A.Bar.Disable(model.item);
		end
		ReloadUI();
	elseif (type == "enable") then
		if (not subtype) then 
			return 
		elseif (subtype == "all") then
			A.Bar.Iterate(A.Bar.Enable)
		else
			local model = A.Models.GetById(subtype);
			if (not model) then return end;
			A.Bar.Enable(model.item);
		end
		ReloadUI();

	elseif (type == "list") then
		A.Bar.Iterate(function(bar) 
			_.print("Bar", bar.id, (bar.disabled and "disabled" or "enabled"));
		end)
	else
		_.print("Unknown command", type);
	end
end

local function initializeSlashCommands()
	SLASH_TABUBARS1 = "/tabubars";
	SLASH_TABUBARS2 = "/tabu-bars";
	SLASH_TABUBARS3 = "/Tabu-Bars";
	SLASH_TABUBARS4 = "/TabuBars";
	SlashCmdList["TABUBARS"] = tabubarsSlashProcessor;
end


local chatCommands = {
	"|cffffff00/tabubars|r for info",
	"|cffffff00/tabubars add|r to add action bar",
	"|cffffff00/tabubars wipeall|r to clean all data and restart the UI",
}



A.ShowInfo = function()
	if (not A.infoFrame) then
		A.infoFrame = A.Settings.CreateInfoFrame(chatCommands);
	end
	if (A.infoFrame:IsShown()) then
		A.infoFrame:Hide();
	else
		A.infoFrame:Show()
	end
end

local refreshButtonEvents = {
	"BAG_UPDATE",
	"BAG_UPDATE_COOLDOWN",
	"ACTIONBAR_UPDATE_COOLDOWN",
	"ACTIONBAR_UPDATE_USABLE",
	"SPELL_UPDATE_COOLDOWN",
	"SPELL_UPDATE_USABLE"
}

local initializeCache = function ()
	local cache = Cache();
	if (not cache.bars) then
		cache.bars = {};
	end
	if (not cache.barDefaults) then
		cache.barDefaults = {
			buttonsInLine = 12,
			buttonSize = 36
		};
	end
	if (not cache.buttonDefaults) then
		cache.buttonDefaults = {};
	end
end

local function initialize()	
	initializeSlashCommands();
	_.initializeUniqueId();
	initializeCache();
	-- C_Timer.After(5, function() 
	-- end)
	A.Bar.BuildAll();
	A.Bar.RefreshButtonsOn(refreshButtonEvents);

	_.print(L(chatCommands[1]));
	_.print(L(chatCommands[2]));

	--A.specialBars();

end

local getDefaults = function (t)
	local c = Cache();
	if (t == 'button') then
		return c.buttonDefaults;
	elseif t == 'bar' then
		return c.barDefaults;
	else
		return {}
	end
end

A.GetDefaultValue = function(entityType, key, entity, fb1, fb2, fb3)
	local defs = getDefaults(entityType);
	if (entity[key] ~= nil) then
		return entity[key]
	elseif defs[key] ~= nil then
		return defs[key];
	elseif fb1 ~= nil then
		return fb1
	elseif fb2 ~= nil then
		return fb2
	else
		return fb3
	end
end

Tabu.test = function()
	--Tabu.dump(A.Lib);
	local tbl = A.Lib.SharedMedia:HashTable( A.Lib.SharedMedia.MediaType.FONT );
	Tabu.dump(tbl);
end


A.specialBars = function()
	_.print("okey. now specials begin")
	A.spellBookBar();
end

A.spellBookBar = function()
	if (Cache().bars["SpellBookBar"]) then 
		_.print("SpellBook exist. done");
		return 
	end;

	raw = {
		id = "SpellBookBar",
		special = true,
		automatic = {
			type = "SpellBook"
		},		
		point = "LEFT",
		posX = 100,
		posY = 200,
	}
	A.Bar.NewBar(nil, raw);
end


A.Bus.On("PLAYER_LOGIN", initialize);


local MicroButtons = {
"CharacterMicroButton",
"SpellbookMicroButton",
"TalentMicroButton",
"QuestLogMicroButton",
"SocialsMicroButton",
"WorldMapMicroButton",
"MainMenuMicroButton",
"HelpMicroButton"
}

local noop = function() end;
A.HideBlizMicroMenu = function()
	for i, id in pairs(MicroButtons) do
		local frame = _G[id];
		frame.Show = noop;
		frame:Hide();
	end
end

A.hbmm = A.HideBlizMicroMenu;

A.ShowBlizMicroMenu = function()
	local prev;
	for i, id in pairs(MicroButtons) do
		local frame = _G[id];
		frame:SetParent(UIParent);
		frame:ClearAllPoints();
		if (not prev) then
			frame:SetPoint("CENTER", -100, -100);
		else
			frame:SetPoint("TOPLEFT", prev, "TOPRIGHT", 5, 0);
		end
		frame:Show();

		local width, height = frame:GetSize();
		frame:SetHitRectInsets(0,0,0,0);
		frame:SetSize(width * 3, height * 3);

		prev = frame;
	end	
end

A.sbmm = A.ShowBlizMicroMenu;

--A.sbmm();
-- HideMicroMenu = A.HideBlizMicroMenu;
-- ShowMicroMenu = A.ShowBlizMicroMenu;

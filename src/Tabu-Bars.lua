local A, _, L, Cache = Tabu:Spread(...);

local function tabubarsSlashProcessor(type)
	if (type == "" or type == nil) then
		type = "info"
	end

	if (type == "add") then
		A.Bar.NewBar();
	elseif (type == "wipeall") then
		wipe(Cache());
		ReloadUI();
	elseif (type == "dump") then
		Tabu.dump(Cache());
	elseif (type == "info") then
		A.ShowInfo();
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
	--"UPDATE_SHAPESHIFT_FORMS",
	--"PLAYER_ALIVE",
	--"PLAYER_CONTROL_GAINED",
	--"PLAYER_REGEN_ENABLED",
	--"PLAYER_REGEN_DISABLED",
	--"PLAYER_UNGHOST",
	"BAG_UPDATE",
	"BAG_UPDATE_COOLDOWN",
	"ACTIONBAR_UPDATE_COOLDOWN",
	"SPELL_UPDATE_COOLDOWN",
	--"UPDATE_BATTLEFIELD_STATUS"
	--"GET_ITEM_INFO_RECEIVED"
}

local initializeCache = function ()
	local cache = Cache();
	if (not cache.bars) then
		cache.bars = {};
	end
end

local function initialize()	
	initializeSlashCommands();
	_.initializeUniqueId();
	initializeCache();

	A.Bar.BuildAll();
	A.Bar.RefreshButtonsOn(refreshButtonEvents);
	_.print(L(chatCommands[1]));
	_.print(L(chatCommands[2]));
end


A.Bus.On("PLAYER_LOGIN", initialize);




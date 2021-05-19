local A, _, L, Cache = Tabu:Spread(...);
A.IndiBar = {}

local IndiBarMixin = {

	GetBarFrame = function (self)
		return self.frames.bar;
	end,

	SetBarFrame = function (self, frame)
		self.frames.bar = frame;
	end,

	BuildShouldBeSkipped = function(self)
		return self.deleted or self.hidden or self.disabled or false
	end,

	InitializeBar = function(self, optionsChanged)
		if not self.frames then
			self.frames = {};
		end
	end,

	CreateBarFrame = function(self)
		local id = self.item.id;
		local frame = CreateFrame("Frame", _.buildFrameName(id), UIParent);
		return frame;
	end,

	InitializeBarFrame = function(self)
		local frame = self:GetBarFrame();
		local isNew = false;
		if not frame then
			frame = self:CreateBarFrame();
			self:SetBarFrame(frame);
			isNew = true
			self:SetupPosition();
		end
		return frame, isNew;
	end,

	SetupPosition = function(self)
		local frame = self:GetBarFrame();
		frame:ClearAllPoints();
		local point, posX, posY = "CENTER", 0, -100;
		frame:SetPoint(point, posX, posY);
	end,

	ResizeBar = function(self)
		local frame = self:GetBarFrame();
		local children = { frame:GetChildren() };
		local width = 0;
		local height = 0;
		local prevChild;
		for _ind, child in pairs(children) do
			if child:IsShown() then
				width = width + child:GetWidth();
				if height == 0 then
					height = child:GetHeight();
				end
				if prevChild then
					child:SetPoint("TOPLEFT", prevChild, "TOPRIGHT", 0, 0);
				else
					child:ClearAllPoints();
					child:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0);
				end
				prevChild = child;
			end
		end
		frame:SetSize(width, height);
	end,

	GetIndicators = function(self, sort)
		local result = self.item.items or {};
		if sort then
			table.sort(result, A.IndiBar.Comparator);
		end
		return result;
	end,

	SetIndicators = function(self, newindicators)
		self.item.items = newindicators;
	end,

	BuildIndicators = function(self)
		local indicators = self:GetIndicators(true);
		for _indx, indicator in pairs(indicators) do
			local model = A.Indi.Build(indicator);
		end
		self:SetIndicators(indicators);
	end,


}

A.IndiBar.Comparator = function(a,b) 
	return (a.index or 1000) < (b.index or 1000);
end

A.IndiBar.Build = function (bar, index, optionsChanged)

	if (not bar) then
		_.print("IndiBar.Build nil argument");
		return;
	end

	if (index ~= nil) then
		bar.index = index;
	end

	local model = A.IndiBar.ToModel(bar);

	--(model.deleted or model.hidden or bar.disabled)
	if (not optionsChanged and model:BuildShouldBeSkipped()) then
		return;
	end

	
	model:InitializeBar(optionsChanged);
	local frame, isnew = model:InitializeBarFrame();

	model:BuildIndicators(optionsChanged);

	if optionsChanged then
		model:SetupPosition();
	end
	model:ResizeBar();

	model.builded = true;

	return model.item;
end

A.IndiBar.Refresh = function(bar)
	if type(bar.items) ~= "table" then return end
	for _k, item in pairs(bar.items) do
		A.Indi.Refresh(item);
	end
	local model = A.IndiBar.ToModel(bar);
	model:ResizeBar();
end

A.IndiBar.BuildAll = function()
	local index = 1;
	local cache = Cache();
	if not cache.indicators or 1 == 1 then
		cache.indicators = {
			["IBr1"] = {
				id = "IBr1",
				type = "icon",
				point = "center",
				posX = 0,
				posY = 100,
				items = {
					{
						id = "Indi2",
						barId = "IBr1",
						type = "buff",
						typeName = "Аура благочестия",
						unit = "player",
						indicator = {
							show = true,
							checks = {
								{ "playerBuff", "=", true }
							}
						}
					},
					{
						id = "Indi3",
						barId = "IBr1",
						type = "buff",
						typeName = "Слово силы: Стойкость",
						unit = "player",
						indicator = {
							show = true,
							checks = {
								{ "playerBuff", "=", true }
							}
						}
					},					
					{
						id = "Indi4",
						barId = "IBr1",
						type = "buff",
						typeName = "Благословение могущества",
						unit = "player",
						indicator = {
							show = true,
							checks = {
								{ "playerBuff", "=", true }
							}
						}
					},
					{
						id = "Indi5",
						barId = "IBr1",
						type = "spell",
						typeName = "Божественная защита",
						unit = "player",
						indicator = {
							show = true,
							checks = {
								{ "cooldown", "=", true }
							}
						}
					}										
				}
			}
		};
	end
	local dictionary = cache.indicators;

	for name, bar in pairs(dictionary) do	
		bar = A.IndiBar.Build(bar, nil, index);
		index = index + 1;	
	end
end

local REFRESHFRAME = CreateFrame("Frame", nil, UIParent);

local REFRESHEVENTS = {
	"UNIT_AURA",
	"PLAYER_REGEN_DISABLED",
	"PLAYER_REGEN_ENABLED",
	"BAG_UPDATE",
	"BAG_UPDATE_COOLDOWN",
	"ACTIONBAR_UPDATE_COOLDOWN",
	"ACTIONBAR_UPDATE_USABLE",
	"SPELL_UPDATE_USABLE",
	"UNIT_POWER_UPDATE",
	"PLAYER_ALIVE",
	"PLAYER_UNGHOST",
	"PLAYER_DEAD",
	"PLAYER_LEVEL_UP"
}

A.IndiBar.SetupRefreshListeners = function()

	for _i, event in pairs(REFRESHEVENTS) do
		REFRESHFRAME:RegisterEvent(event);
	end

	local refreshtimer;	
	REFRESHFRAME:SetScript("OnEvent", function() 
		if refreshtimer then return end;
		refreshtimer = C_Timer.NewTimer(.1, function() 
			A.IndiBar.RefreshAll();
			refreshtimer = nil;
		end);
	end);
end

A.IndiBar.RefreshAll = function()
	local cache = Cache();
	local dictionary = cache.indicators or {};
	for name, bar in pairs(dictionary) do	
		bar = A.IndiBar.Refresh(bar);
	end
end


A.IndiBar.ToModel = function(indiBar)
	if (indiBar == nil) then
		return;
	end
	local model = A.Models.ToModel(indiBar, IndiBarMixin, "IndiBarToModel");
	if (model._initialized) then return model end
	indiBar = model.item;

	-- add initialize things here

	model._initialized = true;
	return model;	
end


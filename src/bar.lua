local A, _, L, Cache = Tabu:Spread(...);
A.Bar = {}



local getBarSideOffset = function (value, growTo, side)
	if 
	(
		((growTo == "RIGHT" or growTo == "TOP") and growTo ~= side) 
		or
		((growTo == "LEFT" or growTo == "BOTTOM") and growTo == side)
	)
	then 
			value = -value;
	end;
	return value;
end

local BarFrameMixins = {
	CreateSecureBg = function (self, barid)
		local frame = self;
		local sbg = CreateFrame("Frame", _.buildFrameName(barid.."SECBG"), frame, "SecureHandlerEnterLeaveTemplate");
		local size = 100;
		sbg:SetFrameLevel(UIParent:GetFrameLevel());
		frame.sbg = sbg;
		sbg:SetPoint("TOPLEFT", frame, "TOPLEFT", -size, size);
		sbg:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", size, -size);
		--A.Frames.CreateColorTexture(sbg, 1,1,0,0.2);
		sbg:Hide();
	
		sbg:SetFrameRef("common", A.COMMONFRAME);
	
		sbg.hidePopups = function()
			A.Popup.HideAll();
		end
	
		sbg:SetAttribute("_onenter", [=[
			self:Hide();
			local cmn = self:GetFrameRef("common");
			if (not cmn) then return end;
			local i = 1;
			local popup = cmn:GetFrameRef("popup_"..i);
			while(popup) do
				popup:Hide();
				i = i + 1;
				popup = cmn:GetFrameRef("popup_"..i);
			end
		]=])
	
	end
}


local function createDraggableFrame(model, frame)
	if (model.frames.draggable) then return end;

	frame:SetMovable(true);
	local df = CreateFrame("Button", nil, frame);
	_.createColorTexture(df, 0,1,0,.5);
	df:SetAllPoints();
	df:SetFrameLevel(frame:GetFrameLevel() + 100);
	df:Hide();
	df:SetScript("OnShow", function() 
		model.unlocked = true;
	end);
	df:SetScript("OnHide", function() 
		model.unlocked = false;
	end);
	df:RegisterForClicks("AnyUp");
	df:RegisterForDrag("LeftButton");
	df:SetScript("OnClick", function(self, button) 
		if (button == "RightButton") then
			self:Hide();
		end
	end);
	df:SetScript("OnDragStart", function() 
		frame:StartMoving();
	end)
	df:SetScript("OnDragStop", function() 
		frame:StopMovingOrSizing();
		local point, rlTo, rlPoint, posX, posY = frame:GetPoint(1);
		model.item.point = point;
		model.item.posX = posX;
		model.item.posY = posY;
	end)
	model.frames.draggable = df;
end

local BarMixin = {
	SetBarDefaults = function (self)
		if (self.builded) then return end;

		local bar = self.item;
		local parentButton = self.parentButton;
		local parentBar = self:GetParentBarBar();
		local defaultGrow, defaultGrowId;
		--local parentGrow, growId;
		local grow, growId;
		local parentAntiPoint;
		local relativeToParent;
		local GROWS = A.Grows.items;
		--TabuBars.Frames.GROWS;
	
		defaultGrowId = "rightDown";
		defaultGrow = A.Grows.Get(defaultGrowId);
		local buttonsInLine, buttonSize, padding, spacing, alignCenter = 12, 40, 0, 0, 0;
	
		if (parentButton) then
			--print('# 0', type(parentBar), parentButton.id, parentButton.barId);
			local pgrow = A.Grows.Get(parentBar.grow);
			bar.grow = bar.grow or parentBar.grow;
			bar.attachSide = bar.attachSide or pgrow.dir[2]; 
			buttonsInLine = parentBar. buttonsInLine
			buttonSize = parentBar.buttonSize
			padding = parentBar.padding
			spacing = parentBar.spacing
			alignCenter = parentBar.alignCenter
		else
			bar.grow = bar.grow or defaultGrowId;
			bar.point = bar.point or "CENTER";
		end
		bar.buttonsInLine = bar.buttonsInLine or buttonsInLine;
		bar.buttonSize = bar.buttonSize or buttonSize;
		bar.padding = bar.padding or padding;
		bar.spacing = bar.spacing or spacing;
		bar.alignCenter = bar.alignCenter or alignCenter;
		
	end,

	IsActive = function(self)
		if (self.deleted or self.hidden) then
			return false;
		else
			return true;
		end
	end,

	Lock = function(self)
		if (A.Locked("LockBar") or self.item.isNested) then return end;
		self.frames.draggable:Hide();
	end,
	Unlock = function(self)
		if (A.Locked("UnlockBar") or self.item.isNested) then return end;
		self.frames.draggable:Show();
	end,

	--#region Frame
	GetBarFrame = function (self)
		return self.frames.bar;
	end,

	SetBarFrame = function (self, frame)
		self.frames.bar = frame;
	end,

	InitializeBarFrame = function (self)
		if (self.builded) then return end;

		local bar = self.item;
		local point = bar.point;
		local posX = bar.posX;
		local posY = bar.posY;
		local parentFrame = self:GetParentButtonFrame();
		local frame = CreateFrame("Frame", _.buildFrameName(bar.id), parentFrame or UIParent, "SecureHandlerBaseTemplate");	
		_.mixin(frame, BarFrameMixins, "InitBarFrame");
		self:SetBarFrame(frame);

		frame:EnableMouse(true);
		frame:SetFrameLevel(UIParent:GetFrameLevel() + 2);
		frame:SetSize(1, 1);
		_.createColorTexture(frame, 0,0,0, 0.8);	

		frame:CreateSecureBg(bar.id);

		if (bar.isNested) then
			A.Models.StoreAdd("popups", frame, self.id);
			-- local index = A.Models.StoreAdd("popups", frame, self.id);
			-- TabuBars.COMMONFRAME:SetFrameRef("popup_"..index, frame);
			frame:Hide();
		else
			createDraggableFrame(self, frame);
		end

	end,

	UpdateBarPosition = function (self)
		local bar = self.item;
		local frame = self:GetBarFrame();
		local point, offsetX, ofssetY, relativeToParent;
		local parentBar, parentButton;
		parentBar = self:GetParentBarBar();
		frame:ClearAllPoints();
	
		if (bar.isNested) then

			parentFrame = self:GetParentButtonFrame();

			local owngrowid = bar.grow;
			local growid = bar.grow or "rightDown";

			local grow = A.Grows.Get(growid);
			local side = bar.attachSide;
	
			if (growid ~= owngrowid) then
				bar.grow = growid;
				if (not _.arrayHasValue(grow.dir, sid)) then
					bar.attachSide = grow.dir[1];
					side = bar.attachSide;
				end
			end
	
			local center = bar.alignCenter;
			local offsetX = 0;
			local offsetY = 0;

			local parentPad = parentBar.padding;
			local popupPad = bar.padding;

			local hg = A.Grows.hgrow(grow.dir);
			local ohg = A.Grows.oppositeSide(hg);
			local vg = A.Grows.vgrow(grow.dir);
			local ovg = A.Grows.oppositeSide(vg);
	
			if (side == ohg or side == ovg) then
				_.print("NOT ALLOWED Side for current grow");
				side = grow.dir[1];
			end
	
			point = ovg..ohg;

			if (A.Grows.isHorizontalSide(side))	then
				relativeToParent = ovg..hg;
				offsetX =  getBarSideOffset(0, hg, side);
				offsetY = getBarSideOffset(popupPad, vg, side);
			else
				relativeToParent = vg..ohg;			
				offsetX =  getBarSideOffset(popupPad, hg, side);
				offsetY = getBarSideOffset(0, vg, side);
			end
			
			frame:SetPoint(point, parentFrame, relativeToParent, offsetX, offsetY);
			frame:SetFrameLevel(parentFrame:GetFrameLevel() + 1);
		else
			point = bar.point or "CENTER";
			offsetX = bar.posX or 0;
			offsetY = bar.posY or 0;
			frame:SetPoint(point, offsetX, offsetY);
		end
	end,

	GetBarLinesAndItems = function (self)
		local bar = self.item;
		local btns = bar.buttons or {}
		local items = 0;
		for _, b in pairs(btns) do
			local buttonModel = A.Button.ToModel(b);
			if (buttonModel:IsActive()) then
				items = items + 1;
			end
		end
		local lines = math.modf((items > 0 and items - 1 or 0) / bar.buttonsInLine) + 1;
		if (items > bar.buttonsInLine) then
			items = bar.buttonsInLine
		elseif (items == 0) then
			items = 1
		end
		return lines, items;
	end,

	ResizeBar = function (self)
		local bar = self.item;
		local lines, items = self:GetBarLinesAndItems();
		local padding = bar.padding;
		local spacing = bar.spacing;
		local width = items;
		local height = lines;
		local grow = A.Grows.Get(bar.grow);
		local rev = grow.axisReverted == true;
		if (rev) then
			width = lines;
			height = items;
		end
		width = width * bar.buttonSize + padding*2 + (width - 1)*spacing;
		height = height * bar.buttonSize + padding*2 + (height - 1)*spacing;
		local frame = self:GetBarFrame();
		frame:SetSize(width, height);	
	end,
	--#endregion

	--#region Parents
	GetParentBarModel = function (self)
		local buttonModel = self:GetParentButtonModel();
		if (not buttonModel) then return end;
		return buttonModel:GetParentBarModel();
	end,

	GetParentBarBar = function (self)
		local model = self:GetParentBarModel();
		return model and model.item;
	end,

	GetParentBarBarFrame = function (self)
		local model = self:GetParentBarModel();
		return model and model:GetBarFrame();
	end,

	GetParentButtonModel = function (self)
		if (not self.parentButton) then return end;
		return A.Button.ToModel(self.parentButton);
	end,

	GetParentButtonFrame = function(self)
		local btnModel = self:GetParentButtonModel();
		if (not btnModel) then return end;
		return btnModel:GetButtonFrame();
	end,
	--#endregion

	--#region Buttons
	GetAutomaticButtons = function(self)
		local bar = self.item;
		local type = bar.automatic.type;
		if (type == "SpellBook") then
			return A.Bar.SpellBookTabsButtons(self);
		elseif (type == "SpellBookTab") then
			return A.Bar.SpellBookTabSpellsButtons(self);
		else
			_.print("unknown automatic bar", type);
		end
		return {};
	end,
	GetButtons = function(self)
		local bar = self.item;
		if (not bar.automatic) then
			return bar.buttons or {};
		end
		return self:GetAutomaticButtons();
	end,
	BuildButtons = function (self, iteration)
		local bar = self.item;

		local btns = self:GetButtons();

		table.sort(btns, function(a,b) return (a.index or 1000) < (b.index or 1000) end);

		local index = 0;
		self.buttonsCount = 0;
		local newbtns = {};
		for _, button in pairs(btns) do
			if (A.Button.Build(button, index)) then
				index = index + 1;
				self.buttonsCount = index;
				table.insert(newbtns, button);
			end
		end
		bar.buttons = newbtns;
		if (self.buttonsCount == 1 and self.prevButton.hidden) then
			self.prevButton.hidden = false;
			A.Button.ToModel(self.prevButton):GetButtonFrame():Show();
		end
	end,

	AddButton = function (self, silent, mixWith)
		local btnModel = A.Button.NewButton(self.item);
		if (not self.item.buttons) then
			self.item.buttons = {}
		end
		if (mixWith) then
			_.mixin(btnModel.item, mixWith);
		end
		table.insert(self.item.buttons, btnModel.item);
		if (not silent) then
			self:Rebuild();
		end
	end,

	Rebuild = function(self)
		A.Bar.Build(self.item);
	end,
	--endregion

	Delete = function(self, silent)
		self.deleted = true;
		for i, child in pairs(self.frames) do
			child:Hide();
			child:SetAttribute("WasDeleted", true);
		end
		if (self.item.isNested) then
			local bmodel = self:GetParentButtonModel();
			bmodel.item.bar = nil;
		else
			Cache().bars[self.item.id] = nil;
		end
		if (not silent) then
			A.Bar.UpdateButtonsRefs();
		end
	end,

	TryExpand = function(self, btnModel)
		if (self.prevButton == btnModel.item and btnModel.item.type) then
			btnModel.item.hidden = false;
			self:AddButton(nil, { hidden = true });
		end
	end,
	GetFirstAvailableButton = function(self)
		local start, dur, en;
		for x, button in ipairs(self.item.buttons) do
			if (button.type) then
				print(button.type, button.typeName);
				if (button.type == "item") then
					start, dur, en = GetItemCooldown(button.info.id)
				elseif (button.type == "spell") then
					start, dur, en = GetSpellCooldown(button.info.id)
				end
				print(button.typeName, start, dur, en);
				if (not start or start == 0) then
					return button;
				end
			end
		end
		return {};
	end,
	GetFirstAvailableButtonData = function(self)
		local btn = GetFirstAvailableButton() or self.item.buttons[1];
		return btn.attrs, btn.info
	end

}

A.Bar.ToModel = function (bar)
	if (bar == nil) then
		return;
	end
	local parentButton;
	local model = A.Models.ToModel(bar, BarMixin, "BarToModel");
	if (model._initialized) then return model end
	bar = model.item;

	if (bar.parentButtonId) then
		parentButton = A.Button.getButtonById(bar.parentButtonId);
	end
	model.parentButton = parentButton;
	model._initialized = true;
	return model;
end

A.Bar.Build = function (bar, index)
	if (not bar) then
		_.print("Bar.Build nil argument");
		return;
	end
	if (index ~= nil) then
		bar.index = index;
	end
	local model = A.Bar.ToModel(bar);
	if (model.deleted) then
		return;
	end


	model:SetBarDefaults();
	model:InitializeBarFrame();
	model:BuildButtons();
	model:ResizeBar();
	model:UpdateBarPosition();
	model.builded = true;
	return model.item;
end

local NewBar = function(buttonId, rawBar)
	local button, isNested;
	if (type(buttonId) == "table") then
		button = buttonId;
		buttonId = button.id;
	end
	local rawId = _.uniqueId();
	local id = "Br"..rawId;
	isNested = buttonId ~= nil;
	local bar = {
		id = id,
		rawId = rawId,
		parentButtonId = buttonId,
		isNested = isNested,
		buttons = {};
	}
	if (rawBar) then
		_.mixin(bar, rawBar);
	end
	return bar;
end

A.Bar.NewBar = function(btnModel, rawBar)
	local btn = btnModel and btnModel.item or nil;
	local bar = NewBar(btn, rawBar);
	local model = A.Bar.ToModel(bar);
	if (not bar.automatic) then
		model:AddButton(true);
	end
	if (not btnModel) then
		model:Rebuild();
		A.Bar.UpdateButtonsRefs();
		if (not bar.virtual) then
			Cache().bars[model.item.id] = model.item;
		end
	end
	return model;
end

A.Bar.BuildAll = function()
	local index = 1;
	local dictionary = Cache().bars;
	for name, bar in pairs(dictionary) do	
		bar = A.Bar.Build(bar, nil, index);
		index = index + 1;	
	end
	A.Bar.UpdateButtonsRefs();
end

A.Bar.getBarById = function(id)
	local model = A.Bar.ToModel(id);
	return model and model.item;
end


A.Bar.getBarFrame = function(id)
	local model = A.Bar.ToModel(id);
	return model and model:GetBarFrame();
end

local pops;
local function setButtonPopupReferences(btn, parentPopups)
	local model = A.Button.ToModel(btn);
	local buttonFrame = model:GetButtonFrame();
	if (not buttonFrame) then return end;
	local bar = model.parentBar;
	local buttonPopupId = btn.bar and btn.bar.id or nil;

	local hides = {}
	local popups = A.Models.Store("popups");

	for id, info in pairs(popups.byId) do
		local isParentPopup = _.arrayHasValue(parentPopups, id);
		local isChildPopup = id == buttonPopupId;
		if (not (isParentPopup or isChildPopup)) then
			table.insert(hides, info.item);
		end
	end

	for index, frame in pairs(hides) do
		buttonFrame:SetFrameRef("popup_"..index, frame);
	end
end

local function updateBarButtonsRefs(bar, parentPopups)
	if (not bar) then return end;

	local model = A.Bar.ToModel(bar);
	if (not bar.buttons or model.deleted) then
		return;
	end		
	if (bar.isNested) then
		table.insert(parentPopups, bar.id);
	else
		parentPopups = {};
	end


	local nesteds = {}

	for _, btn in pairs(bar.buttons) do
		setButtonPopupReferences(btn, parentPopups);
		if (btn.bar) then
			table.insert(nesteds, btn.bar);
		end
	end
	A.Bar.UpdateButtonsRefs(nesteds, parentPopups);

end

A.Bar.UpdateButtonsRefs = function(data, parentPopups)
	if (not data) then
		data = Cache().bars;
			
	end
	local initial = not parentPopups;

	for i, bar in pairs(data) do
		updateBarButtonsRefs(bar, parentPopups);
	end
	if (initial) then
		local items = A.Models.StoreItems("popups");
		for indx, frame in pairs(items) do
			A.COMMONFRAME:SetFrameRef("popup_"..indx, frame);
		end
	end
end


local function showBarLastButton(bar)
	if (not bar) then return end
	local btns = bar.buttons or {};
	for _, btn in pairs(btns) do
		showBarLastButton(btn.bar)
	end
	local model = A.Bar.ToModel(bar);
	if (not model.prevButton) then return end
	local btnModel = A.Button.ToModel(model.prevButton);
	local frame = btnModel:GetButtonFrame();
	if (frame) then
		frame:Show();
		model.prevButton.hidden = false;
		model:ResizeBar();
	end
end

local function hideBarLastButton(bar)
	if (not bar) then return end
	local btns = bar.buttons or {};
	for _, btn in pairs(btns) do
		hideBarLastButton(btn.bar)
	end
	local model =  A.Bar.ToModel(bar);
	if (not model.prevButton or model.prevButton.type or model.buttonsCount <= 1) then return end
	local btnModel = A.Button.ToModel(model.prevButton);
	local frame = btnModel:GetButtonFrame();
	if (frame) then
		frame:Hide();
		model.prevButton.hidden = true;
		model:ResizeBar();
	end
end

A.Bar.ShowLastButtons = function ()
	for _, bar in pairs(Cache().bars) do
		showBarLastButton(bar);
	end
end

A.Bar.HideLastButtons = function ()
	for _, bar in pairs(Cache().bars) do
		hideBarLastButton(bar);
	end
end

local function RefreshBarButtons(bar)
	for x, button in pairs(bar.buttons or {}) do
		local model = A.Button.ToModel(button);
		if (model.item.useFirstAvailable) then
			model:SetupButtonFrame();	
		end
		model:UpdateButtonFrame();

		if (button.bar) then
			RefreshBarButtons(button.bar);
		end
	end
end

local function RefreshButtons()
	local db = Cache().bars;
	for x, bar in pairs(db) do
		RefreshBarButtons(bar);
	end

end

A.Bar.RefreshButtonsOn = function(events)
	for x, event in pairs(events) do
		A.Bus.On(event, RefreshButtons);
	end
end

A.Bar.SpellBookTabSpellsButtons = function(barModel)
	local bar = barModel.item;
	local auto = bar.automatic;
	local btns = {};
	local offset = auto.offset;
	local numSpells = auto.spellsCount;

	for s = offset + 1, offset + numSpells do

		local proto = A.Button.SpellButtonProto(s, BOOKTYPE_SPELL);
		local btn = {
			id = "SpellButton"..proto.info.id,
			barId = bar.id,
		}
		_.mixin(btn, proto);

		table.insert(btns, btn);
		-- DEFAULT_CHAT_FRAME:AddMessage(name..": "..spell);
	end

	return btns;
end

A.Bar.SpellBookTabsButtons = function(barModel)
	local btns = {};
	for i = 1, MAX_SKILLLINE_TABS do
		local name, texture, offset, spellsCount = GetSpellTabInfo(i);

		if not name then
		   break;
		end
		local btn = A.Button.Empty();
		btn.id = "SpellBookTabButton"..offset;
		btn.barId = barModel.item.id;
		btn.info.icon = texture;
		btn.bar = {
			id = "SpellBookTabBar"..offset,
			parentButtonId = btn.id,
			isNested = true,
			automatic = {
				type = "SpellBookTab",
				offset = offset,
				spellsCount = spellsCount
			}
		}
		table.insert(btns, btn);
		-- for s = offset + 1, offset + numSpells do
		--    local	spell, rank = GetSpellName(s, BOOKTYPE_SPELL);
		   
		--    if rank then
		-- 	   spell = spell.." "..rank;
		--    end
		   
		--    DEFAULT_CHAT_FRAME:AddMessage(name..": "..spell);
		-- end
	 end	

	 return btns;
end

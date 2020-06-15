local A, _, L, Cache = Tabu:Spread(...);
A.Button = {}

local EMPTYSLOT = "Interface\\Buttons\\UI-Quickslot";


local detectOffset = function (point, kind, value)
	if (string.find(point, kind)) then
		return value * -1;
	else
		return value
	end
end

local getButtonOffsetX = function (point, value, rev)
	return rev and detectOffset(point, "LEFT", value) or detectOffset(point, "RIGHT", value);
end

local getButtonOffsetY = function (point, value, rev)
	return rev and detectOffset(point, "BOTTOM", value) or detectOffset(point, "TOP", value);
end


local function updateSpellButtonFrame(button, frame)
	frame = frame or ToModel(button):GetButtonFrame();
	if (not button.info.id) then
		return;
	end

	local count = _.getSpellCount(button.info.id);
	frame:SetAmount(count);
	frame:ToggleCooldown(button.info.id, "Spell");

	local command = "SPELL "..button.info.name;
	local key = _.getSpellBindingKey(button.info.name, button.info.id);
	frame:SetButtonHotKey(key);

end

local function updateMacroButtonFrame(button, frame)
	frame = frame or ToModel(button):GetButtonFrame();
	if (not button.info.id) then
		return;
	end	
	local count;
	local thingId = GetMacroSpell(button.info.id);
	local thingType = "Spell";

	if (not thingId) then
		local iname = GetMacroItem(button.info.id);
		if (iname) then
			thingId = GetItemInfoInstant(iname);
		end
		if (thingId) then
			--button.info.macroItemId = thingId;
		else
			--thingId = button.info.macroItemId;
		end
		thingType = thingId and "Item" or "none";
	end

	
	if (thingType == "Spell") then 
		count = _.getSpellCount(thingId);
	elseif (thingType == "Item") then
		count = GetItemCount(thingId);
	end

	frame:SetAmount(count);
	frame:ToggleCooldown(thingId, thingType, "Macro");
	local command = "MACRO "..button.info.name;
	key = GetBindingKey(command);
	frame:SetButtonHotKey(key);
end

local function updateItemButtonFrame(button, frame)
	frame = frame or ToModel(button):GetButtonFrame();
	if (not frame) then return end;
	local count = GetItemCount(button.info.id);
	frame:SetAmount(count);
	frame:ToggleCooldown(button.info.id, "Item", "Item");
end

local function cleanButtonFrame(button, frame)
	frame = frame or ToModel(button):GetButtonFrame();
	if (not frame) then return end;
	--local count = GetItemCount(button.info.id);
	frame:SetAmount("");
	frame:SetButtonHotKey("");
	frame:ToggleCooldown();
end




local ButtonFrameMixin = {
	SetAmount = function(self, count)
		local frame = self;
		local fontString = frame.countText;
		if (count == 0) then
			frame.bgOverlay:SetColorTexture(0, 0, 0, 0.7);
			frame.bgOverlay:Show();
			fontString:SetTextColor(1,0,0,1);
		else
			frame.bgOverlay:SetColorTexture(0, 0, 0, 0);
			frame.bgOverlay:Hide();
			fontString:SetTextColor(1,1,1,1);
		end
		fontString:SetText(count or "");
		self:SetAttribute("entity_count", count or "");
	end,
	ToggleCooldown = function(self, id, type, kind)
		local frame = self;
		local cd = frame.cooldownFrame;
		if (id and type) then
			cd:Show();
		else
			cd:Hide();
		end

		local start, duration, enabled;
		if (id and type == "Spell") then
			start, duration, enabled = GetSpellCooldown(id);
		elseif (id and type == "Item") then
			start, duration, enabled = GetItemCooldown(id);			
		end
		if (start) then
			self:SetAttribute("entity_cd", start > 0 and start or "");
			cd:SetCooldown(start, duration, 1);
		else
			self:SetAttribute("entity_cd", "");
			if (not id) then
				cd:SetCooldown(0, 0);
			end
		end
	end,
	SetButtonHotKey = function(self, key)
		local frame = self;
		local original = key;
		if (not key) then 
			key = "";
		else
			key = key:gsub("ALT", "a");
			key = key:gsub("CTRL", "c");
			key = key:gsub("SHIFT", "s");
			key = key:gsub("SPACE", "sp");
			key = key:gsub("BUTTON", "m");
			key = key:gsub("MOUSEWHEELDOWN", "wD");
			key = key:gsub("MOUSEWHEELUP", "wU");
			frame.hotKeyAssigned = original;
		end
	
		frame.hotKeyText:SetText(key);
	end,
	ShowButtonTooltip = function (self)
		if (InCombatLockdown()) then return end;
		local atype = self:GetAttribute("*type1");
		if (not atype or atype == "") then
			return;
		end
		GameTooltip:SetOwner(self);
		local id = self:GetAttribute("entity_id");
		local link;
		if (atype == "spell") then
			local name = self:GetAttribute("spell");
			link = _.GetSpellLink(id);
			GameTooltip:SetHyperlink(link);
		elseif (atype == "item") then
			link = select(2, GetItemInfo(id));
			GameTooltip:SetHyperlink(link);
		elseif (atype == "macro") then
			local macroName = self:GetAttribute("macro");
			local body = GetMacroBody(macroName);
			local lines = { strsplit("\n", body) }
			GameTooltip:AddLine("macro: " .. macroName);
			GameTooltip:AddLine("------------");
			for _,line in pairs(lines) do
				GameTooltip:AddLine(line);
			end
		end

		if (self.hotKeyAssigned) then
			GameTooltip:AddLine("|cffff3000HotKey: |cffffffff"..self.hotKeyAssigned.."|r");
		end
		if (self.isNested) then
			GameTooltip:AddLine("SHIFT-RightButton for swap with parent button");
		end
		GameTooltip:Show();
	end,

	HideButtonTooltip = function() 
		GameTooltip:Hide();
	end,

	SetupAction = function(self, attrs, icon)
		local btn = self;
		if (not attrs) then
			attrs = {
				["*type1"] = "";
			}
		end
		for key, value in pairs(attrs) do
			btn:SetAttribute(key, value);
		end
		btn.icon:SetTexture(icon or EMPTYSLOT);
	end
	

}

local function CopyButton(self)
	return _.cloneTable(self.item, false, "type", "typeName", "attrs", "info");
end

local ButtonMixin = {

	IsActive = function(self)
		if (self.deleted or self.item.hidden) then
			return false;
		else
			return true;
		end
	end,

	HasPopup = function(self)
		return self.item.bar ~= nil;
	end,

	--#region Frame
	GetButtonFrame = function (self)
		return self.frames.button;
	end,

	SetButtonFrame = function (self, frame)
		self.frames.button = frame;
	end,


	HideButtonFrame = function (self)
		local frame = self:GetButtonFrame();
		if (not frame) then return end
		frame:Hide();
	end,

	ShowButtonFrame = function (self)
		local frame = self:GetButtonFrame();
		if (not frame) then return end
		frame:Show();
	end,


	SetupButtonFrame = function (self)
		local btn = self:GetButtonFrame();
		local attrs, icon;
		if (self.item.useFirstAvailable and false) then
			-- self.bestButton = self:GetPopupModel():GetFirstAvailableButton();
			-- attrs, info = self.bestButton.attrs, self.bestButton.info;
			-- icon = info and info.icon;
		else
		--btnModel
			local button = self.item;		
			attrs = button.attrs or {}
			local info = button.info or {};
			icon = info.icon;

			if (not attrs.entity_id) then
				attrs.entity_id = info.id;
			end

			if (attrs.type1) then
				attrs["*type1"] = attrs.type1;
				attrs.type1 = nil;
			end

			if (button.type == "macro") then
				local check = _.GetMacroInfoTable(button.info.id);
				if (check.name ~= button.info.name) then
					local newid = GetMacroIndexByName(info.name);
					_.print("MACRO MISMATCH. ", button.info.name, button.info.id, ", NOW:", check.name, "new id should be: ", newid);
					button.attrs["*type1"] = "macro";
					button.attrs["macro"] = button.info.name;
					button.attrs.entity_id = newid;
					button.info.id = newid;
				end
			end
		end
		btn:SetupAction(attrs, icon);

		-- for key, value in pairs(attrs) do
		-- 	btn:SetAttribute(key, value);
		-- end
		-- btn.icon:SetTexture(info.icon or EMPTYSLOT);
	end,

	UpdateButtonFrame = function (self)
		local button = self.item;
		if (self.item.useFirstAvailable and self.bestButton) then
			button = self.bestButton;
		end
		if (not button) then return end;

		local frame = self:GetButtonFrame();		
		if (not frame) then return end;

		if (not button.type) then
			cleanButtonFrame(button, frame);
		elseif (button.type == "item") then
			updateItemButtonFrame(button, frame);
		elseif (button.type == "spell") then
			updateSpellButtonFrame(button, frame);
		elseif (button.type == "macro") then
			updateMacroButtonFrame(button, frame);
		else
	
		end
	end,

	GetUpdateContext = function(self, index)
		local parentModel = self:GetParentBarModel();
		local parentBar = parentModel.item;
		local buttons = parentBar.buttons;
		index = index or self.item.index or parentBar.buttonsCount or 0;
		local lineSize = self.parentBar.buttonsInLine;
		local lineNumber = math.modf(index / parentBar.buttonsInLine);
		local lineIndex = math.fmod(index, parentBar.buttonsInLine);
		local prevButton = index > 0 and buttons[index + 1];
		local prevLineFirstButton = index >= lineSize and buttons[(lineNumber * lineSize) + 1] or nil;
		return index, lineSize, lineNumber, lineIndex, prevButton, prevLineFirstButton;
	end,

	UpdateButtonPosition = function (self, context)
		local frame = self:GetButtonFrame();
		local btn = self.item;

		local index = context.index;
		local lineSize = context.lineSize;
		local lineNumber = context.lineNumber;
		local lineIndex = context.lineIndex;

		local bar = self:GetParentBarBar();
		local barPadding = bar.padding;
		local barSpacing = bar.spacing;

		local point, parent, relativePoint;
		local offsetX = 0;
		local offsetY = 0;
		local grow = A.Grows.Get(bar.grow);
		
		point = grow.point;
		local ids;
		if (index == 0) then
			
			offsetY = getButtonOffsetY(point, barPadding);
			offsetX = getButtonOffsetX(point, barPadding);
			relativePoint = point;
			parent = self:GetParentBarFrame();
			ids = bar.id;

		elseif (lineIndex > 0) then
			parent = A.Button.getButtonFrame(context.prevButton);
			relativePoint = grow.relativePoint;
			ids = context.prevButton.id;
			if (grow.axisReverted) then
				offsetY = getButtonOffsetY(point, barSpacing);
			else
				offsetX = getButtonOffsetX(point, barSpacing);
			end
	
		else
			parent = A.Button.getButtonFrame(context.prevLineFirstButton);
			relativePoint = grow.relativePointFirst;
			ids = context.prevLineFirstButton.id;
			if (grow.axisReverted) then
				offsetX = getButtonOffsetX(point, barSpacing);
			else
				offsetY = getButtonOffsetY(point, barSpacing);
			end		
	
			
		end
	
		frame:SetSize(bar.buttonSize, bar.buttonSize);
		frame:ClearAllPoints();
		frame:SetPoint(point, parent, relativePoint, offsetX, offsetY);
	
	end,
	

	InitializeButtonFrame = function(self, context)

		if (self.builded) then return end;

		local bar = self.parentBar;
		local barModel = A.Bar.ToModel(bar);
		local buttonModel = self;
		local button = self.item;
		local size = bar.buttonSize;
		local parent = self:GetParentBarFrame();
		local frame = CreateFrame("Button", _.buildFrameName(button.id), parent, "SecureActionButtonTemplate, TabuBars_Button, SecureHandlerEnterLeaveTemplate");
		self:SetButtonFrame(frame);
		if (barModel.item.isNested) then
			frame.isNested = true;
		end
		if (button.hidden) then
			frame:Hide();
		end
		frame:SetSize(size, size);
	
		frame.icon:SetTexCoord(.08, .92, .08, .92);

		_.addFrameBorder(frame, 0.15, 0.15, 0.15, 1);

		frame:SetFrameLevel(parent:GetFrameLevel()+1);
		frame:RegisterForClicks("AnyUp");
		frame:RegisterForDrag("LeftButton");
		frame:SetFrameRef("common", A.COMMONFRAME);
		frame:SetFrameRef("barsbg", parent.sbg);
		frame:SetAttribute("type2", "showContextMenu");

		
		_.mixin(frame, ButtonFrameMixin);
		if (frame.isNested) then
			frame:SetAttribute("shift-type2", "swapWithParent");
			frame.swapWithParent = function() 
				if (A.Locked("SwapWithParent click")) then return end;
				buttonModel:SwapWithParent(); 
			end
		end
		
		frame.acceptNewThing = function() 

			if (A.Locked("acceptNewThing")) then return end;
			local newbutton = A.GetCursorInfoData();	
			ClearCursor();

			if newbutton then
				buttonModel:Pickup();
				buttonModel:Change(newbutton);
				barModel:TryExpand(buttonModel);
			end		
		end;
	
		frame.showContextMenu = function(self, clicked)
			if (A.Locked("showContextMenu")) then return end;
			if (not self.contextMenu) then
				self.contextMenu = A.Settings.GetButtonMenuFrame();
			end
			UIDropDownMenu_Initialize(self.contextMenu, function()
				A.Settings.PopulateButtonMenu(self, button, bar);
			end, "MENU");
			ToggleDropDownMenu(1, nil, self.contextMenu, "cursor", 3, -3);
		end
	
		SecureHandlerWrapScript(frame, "OnEnter", frame, [=[
			local sbg = self:GetFrameRef("barsbg");
			if (not sbg) then return end;
			sbg:Show();
			self:CallMethod("ShowButtonTooltip");
		]=]);

		SecureHandlerWrapScript(frame, "OnLeave", frame, [=[
			self:CallMethod("HideButtonTooltip");
		]=]);
	
		SecureHandlerWrapScript(frame, "OnClick", frame, [=[
			local common = self:GetFrameRef("common");
			local isDragging = common:GetAttribute("dragging");
			if (isDragging) then
				self:CallMethod("acceptNewThing");
				return false;
			end
		]=]);
	
		frame:SetScript("OnDragStart", function(self, clickedbutton) 
			if (A.Locked("onDragStart")) then return end;
			local shift_key = IsShiftKeyDown();
			local noShift = not shift_key;
			local alt_key = IsAltKeyDown();
			local noSpecialKey = not (shift_key or alt_key);
			local noSimpleSwap = noShift or not button.type;
			local noButtonSwap = not alt_key;
			if (
				noSimpleSwap
				or A.barsChangeDisabled()
			) then return end;
			
			if (shift_key) then
				buttonModel:Pickup();
				buttonModel:Clean();
				buttonModel:UpdateButtonFrame();
			elseif (alt_key) then
				A.draggingButton = button;
			end
		end);
	


		if (not button.hidden) then
			frame:Show();
		end	
	end,

	--endregion

	--#region Relations
	GetParentBarBar = function(self)
		return self.parentBar;
	end,

	GetParentBarModel = function(self) 
		local bar = self:GetParentBarBar();
		return A.Bar.ToModel(bar);
	end,

	GetParentBarFrame = function(self)
		local model = self:GetParentBarModel();
		return model and model:GetBarFrame();
	end,
	GetPopupModel = function(self)
		if (not self.item.bar) then return end;
		local model = A.Bar.ToModel(self.item.bar);
		return model;
	end,
	GetPopupFrame = function(self)
		local model = self:GetPopupModel();
		return model and model:GetBarFrame();
	end,
	GetParentButtonModel = function(self)
		local barModel = self:GetParentBarModel();
		return barModel:GetParentButtonModel();
	end,
	--#endregion

	--#region Popup
	SetupButtonPopupBehavior  = function (self)

		local buttonFrame = self:GetButtonFrame();
		local popupFrame = self:GetPopupFrame();

		if (popupFrame) then
			buttonFrame:SetFrameRef("popupFrame", popupFrame);
			buttonFrame:SetAttribute("popupFrameDeleted", false);
		end

		if (self.builded) then return end

		buttonFrame:SetAttribute("_onenter", [=[
			local popup = self:GetFrameRef("popupFrame");
			if popup then
				local deleted = popup:GetAttribute("wasDeleted");
				if (not deleted) then
					popup:Show();
				end
			end
	
			local i = 1;
			local popup = self:GetFrameRef("popup_"..i)
			while(popup) do
				popup:Hide();
				i = i + 1;
				popup = self:GetFrameRef("popup_"..i)
			end
		]=]);
	
	
	end,
	--#endregion

	Rebuild = function (self)
		A.Button.Build(self.item);
	end,

	Delete = function (self)
		local parentModel = self:GetParentBarModel();
		local popupModel = self:GetPopupModel();
		if (popupModel) then
			popupModel:Delete(true);		
		end
		self.deleted = true;
		for i, child in pairs(self.frames) do
			child:Hide();
			child:SetAttribute("WasDeleted", true);
		end
		parentModel:Rebuild();
		A.Bar.UpdateButtonsRefs(Cache().bars);
	end,

	AddBar = function (self)
		local barModel = A.Bar.NewBar(self);
		self.item.bar = barModel.item;
		self:Rebuild();
		A.Bar.UpdateButtonsRefs();

	end,

	Pickup = function(self)
		local button = self.item;
		if (button.type == "spell") then
			PickupSpell(button.info.id);
		elseif (button.type == "item") then
			PickupItem(button.info.id);
		elseif (button.type == "macro") then
			PickupMacro(button.info.id);
		end
	end,

	Change = function(self, newbutton)
		local button = self.item;
		_.mixin(button, newbutton);
		self:SetupButtonFrame();
		self:UpdateButtonFrame();		
	end,

	Clean = function(self)
		local button = self.item;
		button.type = nil;
		button.typeName = nil;
		button.attrs = { ["*type1"] = "" };
		button.info = {
			icon = EMPTYSLOT
		};
		self:SetupButtonFrame();
		self:UpdateButtonFrame();	
	end,

	SwapWithParent = function(self)	

		if (not self:GetParentBarBar().isNested) then return end;
		local parent = self:GetParentButtonModel();
		local t_btn = CopyButton(self);
		self:Clean();

		local p_btn = CopyButton(parent);
		parent:Clean();

		_.mixin(self.item, p_btn);
		self:SetupButtonFrame();
		self:UpdateButtonFrame();	

		_.mixin(parent.item, t_btn);
		parent:SetupButtonFrame();
		parent:UpdateButtonFrame();	

	end
}



A.Button.ToModel = function (button)
	if (button == nil) then
		_.print("Button.ToModel argument is nil");
		error("Button.ToModel argument is nil")
		return;
	end	
	local parentBar;
	local model = A.Models.ToModel(button, ButtonMixin, "ButtonToModel");
	if (model._initialized) then return model end

	button = model.item;

	if (button.barId) then
		parentBar = A.Bar.getBarById(button.barId);
	else
		_.print("no bar id", button.id);
	end

	model.parentBar = parentBar;
	model._initialized = true;

	return model;

end



A.Button.Build = function (button, index)
	if (not button) then
		_.print("Button.Build nil argument");
		return;
	end

	local model = A.Button.ToModel(button);
	if (model.deleted) then
		return false;
	end

	local barModel = model:GetParentBarModel();
	local bar = barModel.item;

	model:InitializeButtonFrame();
	
	if (index ~= nil) then
		local context = {
			popup = bar.parentButtonId ~= nil,
			index = index,
			bar = bar,
			lineSize = bar.buttonsInLine,
			lineNumber = math.modf(index / bar.buttonsInLine),
			lineIndex = math.fmod(index, bar.buttonsInLine);
			prevButton = barModel.prevButton,
			prevLineFirstButton = barModel.prevLineFirstButton
		}
		barModel.prevButton = button;
		if (context.lineIndex == 0) then
			barModel.prevLineFirstButton = button;
		end
		button.index = index;
		model:UpdateButtonPosition(context);
	end

	if (button.bar) then
		A.Bar.Build(button.bar);
	end

	model:SetupButtonFrame();
	model:UpdateButtonFrame();
	model:SetupButtonPopupBehavior();

	model.builded = true;

	return true;
end



local NewButton = function(barId)
	local bar;
	if (type(barId) == "table") then
		bar = barId;
		barId = bar.id;
	end
	local rawId = _.uniqueId();
	local id = "Btn"..rawId;
	local btn = {
		id = id,
		rawId = rawId,
		barId = barId
	}
	return btn;
end

A.Button.NewButton = function(bar)
	local button = NewButton(bar);
	return A.Button.ToModel(button);
end

A.Button.getButtonById = function(id)
	local model = A.Button.ToModel(id);
	return model and model.item;
end


A.Button.getButtonFrame = function(button)
	local model = A.Button.ToModel(button);
	if (not model) then return end;
	return model:GetButtonFrame();
end




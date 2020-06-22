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

	local count, costType = _.getSpellCount(button.info.id);
	frame:SetAmount(count, costType);
	frame:ToggleCooldown(button.info.id, "Spell");

	local command = "SPELL "..button.info.name;
	local key = _.getSpellBindingKey(button.info.name, button.info.id);
	frame:SetButtonHotKey(key);
	frame:SetTwoChars("");
end

local function updateMacroButtonFrame(button, frame)
	frame = frame or ToModel(button):GetButtonFrame();
	if (not button.info.id) then
		return;
	end	
	local count;
	local thingId = GetMacroSpell(button.info.id);
	local thingType = "Spell";
	local costType;
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
		count, costType = _.getSpellCount(thingId);
	elseif (thingType == "Item") then
		count = GetItemCount(thingId);
	end

	frame:SetAmount(count, costType);
	frame:ToggleCooldown(thingId, thingType, "Macro");
	local command = "MACRO "..button.info.name;
	key = GetBindingKey(command);
	frame:SetButtonHotKey(key);
	frame:SetTwoChars("");
end

local function updateItemButtonFrame(button, frame)
	frame = frame or ToModel(button):GetButtonFrame();
	if (not frame) then return end;
	local count = GetItemCount(button.info.id);
	frame:SetAmount(count);
	frame:ToggleCooldown(button.info.id, "Item", "Item");
	frame:SetTwoChars("");
end

local function updateSpecialButtonFrame(button, frame)
	frame:SetTwoChars(button.info.twoChars);
end

local function cleanButtonFrame(button, frame)
	frame = frame or ToModel(button):GetButtonFrame();
	if (not frame) then return end;
	--local count = GetItemCount(button.info.id);
	frame:SetAmount("");
	frame:SetButtonHotKey("");
	frame:ToggleCooldown();
	frame:SetTwoChars("");
end




local ButtonFrameMixin = {
	SetTwoChars = function(self, txt)
		-- txt = txt or "";
		-- self.twoChars:SetText(txt);
		-- if (txt ~= "") then
		-- 	local height = self:GetHeight();
		-- 	self.twoChars:SetTextHeight(height * 0.5);
		-- end
	end,

	SetAmount = function(self, count, costType)
		local frame = self;
		local fontString = frame.Count;

		if (costType and costType ~= "MANA" and costType ~= "REAGENT") then
			count = nil;
		end

		if (type(count) == "number" and count == 0) then
			frame.bgOverlay:SetColorTexture(.01, 0, 0, .77);
			fontString:SetTextColor(1,0,0,1);
		elseif (type(count) == "number" and count > 0) then
			frame.bgOverlay:SetColorTexture(.1, 0, 0, 0);
			if (costType == "MANA") then
				fontString:SetTextColor(0, .7, 1, 1);
			else
				fontString:SetTextColor(1,1,1,1);
			end
		else
			frame.bgOverlay:SetColorTexture(.1, 0, 0, 0);
			fontString:SetTextColor(1,1,1,1);
		end
		local fnt, fntsize = fontString:GetFont();
		fontString:SetFont(fnt, fntsize, "THICKOUTLINE");
		fontString:SetText(count or "");
	end,

	ToggleCooldown = function(self, id, type, kind)
		local cd = self.cooldown;
		local start, dur, enab = _.getCooldown(type, id);
		if (start and start > 0) then
			cd:SetCooldown(start, dur, enab);
		else
			cd:SetCooldown(0,0);
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

		local f, h = frame.HotKey:GetFont();
		-- frame.hotKeyText:SetFont("Fonts\\ARIALN.ttf", 10, "THICK");
		frame.HotKey:SetTextColor(0,1,1,1);
		frame.HotKey:SetFont(f,h, "THICKOUTLINE");
		frame.HotKey:SetText(key);

	end,
	ShowButtonTooltip = function (self)
		if (InCombatLockdown()) then return end;
		if (self:GetAttribute("special")) then
			return;
		end
		--if (self.special) then return end;

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

		if (self.hotKeyAssigned and self.hotKeyAssigned ~= "") then
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

	SetupIcon = function(self, btn, shouldStop)
		local info = btn.info or {};
		local icon = info.icon;

		if (btn.type ~= "special-button" and not icon) then
			icon = EMPTYSLOT;
		end

		-- if (icon == EMPTYSLOT) then
		-- 	icon = nil;
		-- end

		if (icon == false or icon == nil) then
			self.icon:Hide();	
		else
			if (type(icon) == "function") then
				icon(self.icon);
			else
				self.icon:Show();
				self.icon:SetTexture(icon);
			end	
		end

	end,

	SetupAction = function(self, attrs, icon)
		if (InCombatLockdown()) then return end;
		local btn = self;
		if (not attrs) then
			attrs = A.Button.EmptyButtonAttributes()
		end
		for key, value in pairs(attrs) do
			btn:SetAttribute(key, value);
		end

		-- local ic = [[Interface\Buttons\UI-MicroButton-Help-Up]];
		-- ic = [[Interface\AddOns\Tabu-Bars\Media\Icons\UI-MicroButton-Help-Up]]
		-- btn.icon:SetTexture(ic); --icon or EMPTYSLOT);
		-- btn.icon:ClearAllPoints();
		-- btn.icon:SetSize(40,60);
		-- btn.icon:SetPoint("BOTTOMLEFT", 0, 5);
	end
	

}

local function CopyButton(self)
	return _.cloneTable(self.item, false, "type", "typeName", "attrs", "info");
end

local function buildButtonFrameAttrs(btn)
	res = {};
	return res;
end


local ButtonMixin = {

	IsActive = function(self)
		if (self.deleted or self.item.hidden) then
			return false;
		else
			return true;
		end
	end,

	GetType = function(self)
		return self.item and self.item.type;
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
		local button = self.item;
		local attrs, icon;

		-- if (self.item.useFirstAvailable and false) then
		-- 	-- self.bestButton = self:GetPopupModel():GetFirstAvailableButton();
		-- 	-- attrs, info = self.bestButton.attrs, self.bestButton.info;
		-- 	-- icon = info and info.icon;
		-- elseif (HUHUHUHUHUHUHUHU) then
		-- 	local button = self.item;		
		-- 	attrs = button.attrs or {}
		-- 	local info = button.info or {};
		-- 	icon = info.icon;

		-- 	if (not attrs.entity_id) then
		-- 		attrs.entity_id = info.id;
		-- 	end

		-- 	if (attrs.type1) then
		-- 		attrs["*type1"] = attrs.type1;
		-- 		attrs.type1 = nil;
		-- 	end

		-- 	attrs = _.cloneTable(attrs);

		-- 	if (button.type == "macro") then
		-- 		local check = _.GetMacroInfoTable(button.info.id);
		-- 		if (check.name ~= button.info.name) then
		-- 			local newid = GetMacroIndexByName(info.name);
		-- 			_.print("MACRO MISMATCH. ", button.info.name, button.info.id, ", NOW:", check.name, "new id should be: ", newid);
		-- 			button.attrs["*type1"] = "macro";
		-- 			button.attrs["macro"] = button.info.name;
		-- 			button.attrs.entity_id = newid;
		-- 			button.info.id = newid;
		-- 		end
		-- 		attrs["checkselfcast"] = true;
		-- 		attrs["checkfocuscast"] = true;
		-- 	elseif (button.type == "spell") then
		-- 		attrs["checkselfcast"] = true;
		-- 		attrs["checkfocuscast"] = true;
		-- 	end
		-- end

		--local attrs = 
		--buildButtonFrameAttrs(button);
		if (button.type == "item") then
			if (type(button.info.id) ~= "number") then
				C_Timer.After(2, function() 
					local info = _.GetItemInfoTable(button.typeName);
					button.info = info;
					btn:SetupAction(button.attrs);
					btn:SetupIcon(button);
				end)
			else
				btn:SetupAction(button.attrs);
				btn:SetupIcon(button);
			end
			-- local name = GetItemInfo(button.typeName);
			-- local id = GetItemInfoInstant(button.typeName);
			-- print("LOOKING FOR", button.typeName, name, id, button.info.id);
			-- if (not button.info or type(button.info.id) ~= "number") then
			-- 	A.Bus.OnItem(button.typeName, function(info) 
			-- 		print("OPLYA!");
			-- -- 		button.info = info;
			-- -- 		btn:SetupAction(button.attrs);
			-- -- 		btn:SetupIcon(button);
			-- 	 end);
			-- 	 GetItemInfo(button.typeName);
			-- else
			-- 	btn:SetupAction(button.attrs);
			-- 	btn:SetupIcon(button);
			-- end
		else
			btn:SetupAction(button.attrs);
			btn:SetupIcon(button);
		end

	end,

	UpdateButtonFrame = function (self)
		local button = self.item;
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
		elseif (button.type == "special-button") then
			updateSpecialButtonFrame(button, frame);
		end
	end,

	-- GetUpdateContext = function(self, index)
	-- 	local parentModel = self:GetParentBarModel();
	-- 	local parentBar = parentModel.item;
	-- 	local buttons = parentBar.buttons;
	-- 	index = index or self.item.index or parentBar.buttonsCount or 0;
	-- 	local lineSize = self.parentBar.buttonsInLine;
	-- 	local lineNumber = math.modf(index / parentBar.buttonsInLine);
	-- 	local lineIndex = math.fmod(index, parentBar.buttonsInLine);
	-- 	local prevButton = index > 0 and buttons[index + 1];
	-- 	local prevLineFirstButton = index >= lineSize and buttons[(lineNumber * lineSize) + 1] or nil;
	-- 	return index, lineSize, lineNumber, lineIndex, prevButton, prevLineFirstButton;
	-- end,

	UpdateButtonPosition = function (self)

		local barModel = self:GetParentBarModel();
		local bar = barModel.item;
		local frame = self:GetButtonFrame();
		local btn = self.item;

		local index = self.index;
			--context.index;
		local lineSize = bar.buttonsInLine;
			--context.lineSize;

		-- local lineNumber = context.lineNumber;
		-- local lineIndex = context.lineIndex;

		local lineNumber = math.modf(index / lineSize);
		local lineIndex = math.fmod(index, lineSize);

		local bar = self:GetParentBarBar();
		local barPadding = bar.padding;
		local barSpacing = bar.spacing;

		local point, parent, relativePoint;
		local offsetX = 0;
		local offsetY = 0;
		local grow = A.Grows.Get(bar.grow);
		
		point = grow.point;
		--local ids;
		if (index == 0) then
			
			offsetY = getButtonOffsetY(point, barPadding);
			offsetX = getButtonOffsetX(point, barPadding);
			relativePoint = point;
			parent = self:GetParentBarFrame();
			--ids = bar.id;

		elseif (lineIndex > 0) then

			parent = barModel.lastButton:GetButtonFrame();
				--A.Button.getButtonFrame(context.prevButton);
			relativePoint = grow.relativePoint;
			--ids = barModel.lastButton.item.id;
				--context.prevButton.id;
			if (grow.axisReverted) then
				offsetY = getButtonOffsetY(point, barSpacing);
			else
				offsetX = getButtonOffsetX(point, barSpacing);
			end
	
		else
			parent = barModel.lastLineFirstButton:GetButtonFrame();
				--A.Button.getButtonFrame(context.prevLineFirstButton);
			relativePoint = grow.relativePointFirst;

			--ids = barModel.lastFirstLineButton.item.id;
				--context.prevLineFirstButton.id;
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
	SetupRefreshListeners = function(model)
		local frame = model:GetButtonFrame();
		model.refreshOn = {
			["BAG_UPDATE"] = 2,
			["BAG_UPDATE_COOLDOWN"] = 2,
			["ACTIONBAR_UPDATE_COOLDOWN"] = 3,
			["ACTIONBAR_UPDATE_USABLE"] = 3,
			["SPELL_UPDATE_USABLE"] = 1,
			["UNIT_POWER_UPDATE"] = { 1, function(arg) return arg=="player" end },
			["PLAYER_ALIVE"] = 3,
			["PLAYER_UNGHOST"] = 3,
			["PLAYER_DEAD"] = 3,
			["PLAYER_LEVEL_UP"] = 3,
		}
		for event, x in pairs(model.refreshOn) do
			frame:RegisterEvent(event);
		end
		-- for event, x in pairs(model.spellRefreshOn) do
		-- 	frame:RegisterEvent(event);
		-- end
		
		frame:SetScript("OnEvent", function(self, event, arg) 
			if (model.deleted or model.hidden) then
				return;
			end
			local modelType = model:GetType();
			local checkTbl;
			if (modelType ~= "item" and modelType ~="spell") then
				return
			end
			local checkArg;
			local modelBit = modelType == "item" and 2 or 1;
			local checkBit = model.refreshOn[event] or 0;
			if (type(checkBit) == "table") then
				checkBit = model.refreshOn[event][1];
				checkArg = model.refreshOn[event][2];
			end
			if (bit.band(modelBit,checkBit) == modelBit) then
				if (checkArg) then
					if (not checkArg(arg)) then return end
				end
				model:UpdateButtonFrame();
			end
		end)
	end,
	InitializeButton = function(self)
		if (self.builded) then return end;
		local btn = self.item;
		local mixData = A.Button.BuildAttributes(btn, true);
		if (type(mixData) == "table") then
			_.mixin(btn, mixData);
		end
	end,
	InitializeButtonFrame = function(self, context)

		if (self.builded) then return end;

		local bar = self.parentBar;
		local barModel = A.Bar.ToModel(bar);
		local buttonModel = self;
		local button = self.item;
		local size = bar.buttonSize;
		local parent = self:GetParentBarFrame();
		local frame = CreateFrame("Button", _.buildFrameName(button.id), parent, "ActionButtonTemplate, SecureActionButtonTemplate, SecureHandlerEnterLeaveTemplate");
		self:SetButtonFrame(frame);

		if (barModel.item.isNested) then
			frame.isNested = true;
		end
		-- if (buttonModel.item.type == "special-button") then
		-- 	frame.special = true;
		-- end
		if (button.hidden) then
			frame:Hide();
		end
		frame:SetSize(size, size);
		local ntsize = size * 1.83333; --1.78378378;
		frame.NormalTexture:SetSize(.1, .1);
		--frame.FlyoutBorder:Show();
		frame.icon:SetTexCoord(.08, .92, .08, .92);
		local pt = frame:GetPushedTexture();
		pt:SetTexCoord(.08, .92, .08, .92);

		local hlt = frame:GetHighlightTexture();
		hlt:ClearAllPoints();
		hlt:SetPoint("TOPLEFT", 0, 0);
		hlt:SetPoint("BOTTOMRIGHT", 0, 0);
		hlt:SetAllPoints();

		--hlt:SetSize(size, size);

		hlt:SetTexCoord(.08, .92, .08, .92);

		_.setFrameBorder(frame, 0, 0, 0, .8);
		local bg = _.createColorTexture(frame, 0, 0, 0, .1, "BACKGROUND");
		bg:SetDrawLayer("BACKGROUND", -1);
		--print("#", frame.icon:GetFrameLevel(), bg:GetFrameLevel());

		frame.bgOverlay = _.createColorTexture(frame, .5, 0, 0, 0, "BORDER");

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
			local newbutton = A.GetDragItem();
			ClearCursor();
			--A.ClearCursor();

			if newbutton then
				local item = buttonModel:Pickup();
				buttonModel:Change(newbutton);
				A.dragStop();
				barModel:TryExpand(buttonModel);
				if (item) then
					A.dragStart(item);
				end
			end		
		end;
	
		frame.showContextMenu = function(self, clicked)
			if (A.Locked("showContextMenu")) then return end;
			if (not self.contextMenu) then
				self.contextMenu = A.Settings.GetButtonMenuFrame();
			end
			UIDropDownMenu_Initialize(self.contextMenu, function(self,level)
				A.Settings.PopulateButtonMenu(self, button, bar, level);
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
				
				local item = buttonModel:Pickup();
				buttonModel:Clean();
				buttonModel:UpdateButtonFrame();
				if item then
					A.dragStart(item);
				end
			-- elseif (alt_key) then
			-- 	A.draggingButton = button;
			end
		end);
	
		self:SetupRefreshListeners();

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
	IsEmpty = function(self)
		return self.item.type == nil or self.item.type == "";
	end,
	IsShown = function(self)
		local frame = self:GetButtonFrame();
		if (not frame) then return false end;
		return frame:IsShown() == true;
	end,
	IsHidden = function(self)
		return not self:IsShown();
	end,
	Show = function(self)
		local frame = self:GetButtonFrame();
		frame:Show();
	end,
	Hide = function(self)
		local frame = self:GetButtonFrame();
		frame:Hide();
	end,
	--#region Popup
	SetupButtonPopupBehavior  = function (self)
		if (InCombatLockdown()) then return end;
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

	-- Rebuild = function (self)
	-- 	print(".....", "Bu Rebuild");
	-- 	--A.Button.Build(self.item);
	-- end,

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
		self:GetParentBarModel():Rebuild();
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
		elseif (button.type == "special-button") then

			-- C_Timer.After(1, function() 
			-- 	SetCursor("Interact.blp");
			-- end)

			-- if (not A.PickupHolder) then
			-- 	A.PickupHolder = CreateFrame("Frame", nil, UIParent);
			-- 	A.PickupHolder:SetSize(32, 32);
			-- 	_.createColorTexture(A.PickupHolder, 0,0,0, 1, "BACKGROUND");
			-- 	A.PickupHolder.icon = A.PickupHolder:CreateTexture();
			-- 	A.PickupHolder.icon:SetAllPoints();
			-- 	A.PickupHolder:SetMovable(true);
			-- end
			-- local scale = UIParent:GetEffectiveScale();
			-- local x, y = GetCursorPosition();
			-- local txt = self:GetButtonFrame().icon:GetTexture();
			-- print("###", x, y, txt);
			-- A.PickupHolder.icon:SetTexture(txt);
			-- A.PickupHolder.icon:SetAllPoints();
			--A.PickupHolder:SetPoint("BOTTOMLEFT", x / scale + 25, y / scale + 25);
			--A.PickupHolder:StartMoving();

			--PickupSpecialButton(self);
			-- A.pickedUpButton = {
			-- 	type = self.item.type,
			-- 	typeName = self.item.typeName
			-- }
			--A.dragStart();
		end
		if (_.isValue(self.item.type)) then
			return _.cloneTable(self.item, nil, "type", "typeName", "info");
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
		button.attrs = { ["*type1"] = "", special = false };
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

A.Button.EmptyButtonAttributes = function()
	return {
		["*type1"] = "", 
		special = false
	}
end

A.Button.Empty = function()
	return {
		type = nil,
		typeName = nil,
		attrs = A.Button.EmptyButtonAttributes(),
		info = { icon = EMPTYSLOT }
	}
end

-- A.Button.SpellButtonProto = function(id, arg)
-- 	local sa, sb = GetSpellBookItemInfo(id, arg);
-- 	info = _.GetSpellInfoTable(sb);
-- 	return {
-- 		type = "spell",
-- 		typeName = info.name,
-- 		attrs = {
-- 			["*type1"] = "spell",
-- 			spell = info.name,
-- 			entity_id = info.id,
-- 		},
-- 		info = info
-- 	};
-- end

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
		return false, model, false;
	end

	local barModel = model:GetParentBarModel();
	local bar = barModel.item;

	model:InitializeButton();
	model:InitializeButtonFrame();
	local firstInLine = false;

	if (index ~= nil) then
		firstInLine = math.fmod(index, bar.buttonsInLine) == 0;
		model.index = index;
	end

	model:UpdateButtonPosition();

	if (button.bar) then
		A.Bar.Build(button.bar);
	end


	model:SetupButtonFrame();
	model:UpdateButtonFrame();
	model:SetupButtonPopupBehavior();

	model.builded = true;

	return true, model, firstInLine;
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


A.Button.BuildAttributes = function(thingType, thingId)
	local info;
	local isRealButton = type(thingType) == "table";
	local cacheForced;
	local btn;
	if (isRealButton) then
		btn = thingType;
		cacheForced = thingId == true;
		thingId = thingType.typeName;
		thingType = thingType.type;
	end
	if (isRealButton and not thingType) then
		return A.Button.Empty();
	elseif (thingType == "spell") then
		local sa, sb = GetSpellBookItemInfo(thingId, "");
		--print("#", sa, sb, " -- ", thingId);
		if (type(sb) == "number") then
			info = _.GetSpellInfoTable(sb);
		elseif (btn) then
			info = btn.info;
		else
			info = {
				name = thingId
			}
		end
		return {
			type = "spell",
			typeName = info.name,
			attrs = {
				["*type1"] = "spell",
				spell = info.name,
				checkselfcast = true,
				checkfocuscast = true,
				entity_id = info.id,
				special = false,
			},
			info = info
		};
	elseif (thingType == "item") then
		if (cacheForced and btn.info and type(btn.info.id) == "number") then
			info = btn.info;
		else
			info = _.GetItemInfoTable(thingId);
		end
		return {
			type = "item",
			typeName = info.name,
			attrs = {
				["*type1"] = "item",
				item = info.name,
				checkselfcast = true,
				checkfocuscast = true,
				entity_id = info.id,
				special = false,
			},
			info = info			
		}
	elseif (thingType == "macro") then
		info = _.GetMacroInfoTable(thingId);
		return {
			type = "macro",
			typeName = info.name,
			attrs = {
				["*type1"] = "macro",
				macro = info.name,
				checkselfcast = true,
				checkfocuscast = true,
				entity_id = info.id,
				special = false,
			},
			info = info				
		}
	elseif (thingType == "special-button") then
		local sb = A.SButton.GetButtonProto(thingId);
		return sb;
	end
	print("MISSING CASE", thingType, thingId);

end



-- A.Button.GetCursorInfoData = function()

-- 	local thingType, id = GetCursorInfo();
-- 	if (A.pickedUpButton) then
-- 		thingType = A.pickedUpButton.type;
-- 		id = A.pickedUpButton.typeName;
-- 	end
-- 	return A.Button.BuildAttributes(thingType, id);
-- end

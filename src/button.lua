local A, _, L, Cache = Tabu:Spread(...);
A.Button = {}

local SHM = A.Lib.SharedMedia;

local iconsPath = "Interface\\AddOns\\"..A.OriginalName.."\\Media\\Icons\\";
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
	local slotIndex = button.info.id;
	local macroName = button.info.name;

	if slotIndex and type(slotIndex) == "string" then
		macroName = slotIndex;
		slotIndex = GetMacroIndexByName(slotIndex);
	end

	if slotIndex == nil or type(slotIndex) ~= "number" then
		return;		
	end

	local count;
	local thingId = GetMacroSpell(slotIndex);

	local thingType = "Spell";
	local costType;
	if (not thingId) then
		local iname = GetMacroItem(slotIndex);
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
	if macroName then
		local command = "MACRO "..macroName;
		key = GetBindingKey(command);
		frame:SetButtonHotKey(key);
	end
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

	GetTBModel = function (self)
		return A.Button.ToModel(self.TBButtonId);
	end,

	SetReferences = function(frame, model)
		-- setting needed references
		-- common frame
		frame:SetFrameRef("common", A.COMMONFRAME);
		
		local popupFrame = model:GetPopupFrame() or A.COMMONFRAME;
		frame:SetFrameRef("popupFrame", popupFrame);
		--frame:SetFrameRef("popupFrameSbg", popupFrame.sbg or A.COMMONFRAME);
		
		local parentFrame = model:GetParentBarFrame();
		-- parent bar secure bg
		frame:SetFrameRef("parentBarSbg", parentFrame.sbg);

		local rootBarFrame = model:GetRootBarFrame();
		frame:SetFrameRef('rootBarFrame', rootBarFrame);

		local parentBarModel = model:GetParentBarModel();
		local popupNames = parentBarModel:GetParentPopupNamesAsString();
		frame:SetAttribute("parentPopupNames", popupNames);
	end,

	ShowContextMenu = function(btnFrame, clicked)
		if (A.Locked("showContextMenu")) then return end;
		if (not btnFrame.contextMenu) then
			btnFrame.contextMenu = A.Settings.GetButtonMenuFrame();
		end
		local btnModel = A.Button.ToModel(btnFrame.TBButtonId);
		local button = btnModel.item;
		local bar = btnModel.parentBar;
		UIDropDownMenu_Initialize(btnFrame.contextMenu, function(self,level)
			A.Settings.PopulateButtonMenu(self, button, bar, level);
		end, "MENU");
		ToggleDropDownMenu(1, nil, btnFrame.contextMenu, "cursor", 3, -3);
	end,

	AcceptNewThing = function(btnFrame) 

		if (A.Locked("acceptNewThing")) then return end;
		local newbutton = A.GetDragItem();
		ClearCursor();
		if newbutton then

			A.dragStop();

			local btnModel = A.Button.ToModel(btnFrame.TBButtonId);
			local item = btnModel:Pickup();
			local barModel = A.Button.ToModel(btnFrame.TBBarId);

			btnModel:Change(newbutton);
			barModel:TryExpand(btnModel);

			if (item) then
				A.dragStart(item);
			end

		end		
	end,

	SwapWithParent = function(btnFrame) 
		if (A.Locked("SwapWithParent click")) then return end;
		local btnModel = A.Button.ToModel(btnFrame.TBButtonId);
		btnModel:SwapWithParent(); 
	end,

	DragStartHandler = function(self, clickedbutton) 

		local buttonModel = A.Button.ToModel(self.TBButtonId);
		local button = buttonModel.item;

		_.print('drag start', A.Locked("onDragStart"));
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
	end,

	SetupMouseBehavior = function(frame, model)
		SecureHandlerWrapScript(frame, "OnEnter", frame, [=[
			local cmn = self:GetFrameRef("common");

			local rootBar = self:GetFrameRef('rootBarFrame');
			rootBar:SetAlpha(1);

			-- build parent popups hames hash
			local parentPopupNames = self:GetAttribute("parentPopupNames") or "";
			local ppn = newtable(strsplit(" ", parentPopupNames));
			local parentPopups = newtable();
			for i, parentPopupName in pairs(ppn) do
				parentPopups[parentPopupName] = true;
			end

			-- build opened popups table and hide foreign(not parent) popups
			local openedPopupNames = cmn:GetAttribute("openedPopups") or "";
			if openedPopupNames ~= "" then
				local opn = newtable(strsplit(" ", openedPopupNames));
				for i, openedPopupName in pairs(opn) do
					if not parentPopups[openedPopupName] then
						local openedPopup = cmn:GetFrameRef("popup_"..openedPopupName);
						openedPopup:Hide();
					end
				end
			end
			openedPopupNames = parentPopupNames or "";

			-- show this button Popup
			local popup = self:GetFrameRef("popupFrame");
			if popup and popup ~= cmn then
				local deleted = popup:GetAttribute("wasDeleted");
				if (not deleted) then
					popup:Show();

					if (openedPopupNames ~= "") then
						openedPopupNames = openedPopupNames .. " ";
					end
					openedPopupNames = openedPopupNames .. popup:GetName();
					
				end
			end

			-- update opened popup names cache
			cmn:SetAttribute("openedPopups", openedPopupNames);

			-- hide previous parentBarSbg and show new one
			local sbg = self:GetFrameRef("parentBarSbg");
			local scbgn = cmn:GetAttribute("currentSbgName");
			cmn:SetAttribute("currentSbgName", sbg:GetName());
			sbg:Show();

			if scbgn then
				local prevSbg = cmn:GetFrameRef("bar_sbg_"..scbgn);
				if prevSbg and prevSbg ~= sbg then
					prevSbg:Hide();
				end
			end

			-- -- show parent bar sbg		
			-- if (sbg) then 
			-- 	cmn:SetAttribute("currentSbgName", sbg:GetName());
			-- end;
			
			self:CallMethod("ShowButtonTooltip");
		]=]);

		SecureHandlerWrapScript(frame, "OnLeave", frame, [=[
			self:CallMethod("HideButtonTooltip");
		]=]);
	
		SecureHandlerWrapScript(frame, "OnClick", frame, [=[
			local common = self:GetFrameRef("common");
			local isDragging = common:GetAttribute("dragging");
			if (isDragging) then
				self:CallMethod("AcceptNewThing");
				return false;
			end
		]=]);
	end,

	ShowButtonPopup = function(frame)
		local model = frame:GetTBModel();
		local popupFrame = model:GetPopupFrame();
		if (popupFrame) then
			popupFrame:Show();
		end
	end,

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

		-- local f, h = frame.HotKey:GetFont();
		-- -- frame.hotKeyText:SetFont("Fonts\\ARIALN.ttf", 10, "THICK");
		-- frame.HotKey:SetTextColor(0,1,1,1);
		-- frame.HotKey:SetFont(f,h, "THICKOUTLINE");
		frame.HotKey:SetText(key);

	end,

	ShowButtonTooltip = function (self)

		local showShort, showFull;

		if InCombatLockdown() then
			showShort = IsShiftKeyDown();
			showFull = false;
		else
			showShort = true;
			showFull = IsShiftKeyDown();
		end


		if (not showShort and not showFull) then return end;

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

			if showFull then
				local name = self:GetAttribute("spell");
				link = _.GetSpellLink(id, name);
				GameTooltip:SetHyperlink(link);
			end

			if showShort then
				GameTooltip:AddLine(self:GetAttribute("spell"));
			end

			if showFull or showShort then
				GameTooltip:AddLine("|cff4080ffID: |cffffffff"..id.."|r");
			end

		elseif (atype == "item") then
			if showFull then
				link = select(2, GetItemInfo(id));
				GameTooltip:SetHyperlink(link);
			else
				return;
			end
		elseif (atype == "macro") then
			local macroName = self:GetAttribute("macro");
			local body = GetMacroBody(macroName);
			local lines = { strsplit("\n", body) }
			GameTooltip:AddLine("macro: " .. macroName);
			if showFull then
				GameTooltip:AddLine("------------");
				for _,line in pairs(lines) do
					GameTooltip:AddLine(line);
				end
			end
		end

		if (_.isValue(self.hotKeyAssigned and self.hotKeyAssigned ~= "")) then
			GameTooltip:AddLine("|cffff3000HotKey: |cffffffff"..self.hotKeyAssigned.."|r");
		end
		if (self.isNested) then
			GameTooltip:AddLine(L("SHIFT-RightButton for swap with parent button"));
		end

		if (_.isDebug()) then
			GameTooltip:AddLine("BUTTON ID: "..(self.TBButtonId or "_")..", BAR ID: "..(self.TBBarId or "_"));
		end

		GameTooltip:Show();
	end,

	SetNewRootBarReference = function(self)
		local model = A.Bar.ToModel(self.TBBarId);
		if (not model:IsRoot()) then return end;
		local rootFrame = model:GetBarFrame();
		A.COMMONFRAME:SetFrameRef("hoveredRootBar", rootFrame);
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


local function NormalizeMacros(item)

	local newone = A.Button.BuildAttributes("macro", item.typeName);

	if newone.typeName == nil or newone.typeName == "" then 
		return "clean";
	elseif (newone.typeName == item.typeName) then
		item.info.id = newone.info.id;
		item.info.name = newone.info.name;
	end

	-- local idType = type(item.info.id);
	-- local macroName, macroIndex, pass, isLocal;
	-- if item.info.id and idType == "number" then
	-- 	macroIndex = item.info.id;
	-- 	macroName, pass, pass, isLocal = GetMacroInfo(macroIndex);
	-- elseif item.info.id and idType == "string" then
	-- 	macroName = item.info.id;
	-- 	macroIndex = GetMacroIndexByName(item.info.id);
	-- end

	-- local res = {
	-- 	id = macroIndex,
	-- 	name = macroName,
	-- }

	-- if res.id == 0 then
	-- 	return "notfound";
	-- end

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

		else
			btn:SetupAction(button.attrs);
			btn:SetupIcon(button);
		end

	end,

	IsVisible = function (self)
		if (not self.isIndicator) then return true end;
		return self:CheckShowCondition();
	end,

	IsVisibleNow = function (self)
		local bf = self:GetButtonFrame();
		if not bf:IsShown() then return false end;
		local parentBarFrame = self:GetParentBarFrame();
		if not parentBarFrame:IsShown() then return false end;
		if parentBarFrame:GetAlpha() == 0 then return false end;
		local rootBarFrame = self:GetRootBarFrame();
		if rootBarFrame == parentBarFrame then return true end;
		if not rootBarFrame:IsShown() then return false end;
		if rootBarFrame:GetAlpha() == 0 then return false end;
		return true;
	end,

	CheckShowCondition = function(self)
		local btn = self.item;
		if (not btn.showCondition) then return true end
		if (btn.showCondition == "always") then return true end
		if (btn.showCondition == "never") then return false end

		if (btn.showCondition == "if not on cd") then
			local start, dur, enab = _.getCooldown(btn.type, btn.info.id);
			return start == nil or start == 0;			
		end
		if (btn.showCondition == "if on cd") then
			local start, dur, enab = _.getCooldown(btn.type, btn.info.id);
			return start and start > 0;
		end
	end,

	SetupFontStringFont = function(self, fs, optionsKey)
		local fnt, hght, flags = fs:GetFont();
		fnt = A.GetDefaultValue('button', optionsKey .. 'TextFont', self.item, SHM:Fetch("font", "Play-Bold"), fnt);
		hght = A.GetDefaultValue('button', optionsKey .. 'TextSize', self.item, hght);
		flags = flags or "THICKOUTLINE";
		fs:SetFont(fnt, hght, flags);
	end,

	UpdateButtonFrame = function (self)
		local button = self.item;
		if (not button) then return end;

		local frame = self:GetButtonFrame();		
		if (not frame) then return end;

		self:SetupFontStringFont(frame.HotKey, 'hotKey');
		frame.HotKey:SetTextColor(0,1,1,1);
		-- local fnt, hght = frame.HotKey:GetFont();
		-- fnt = A.GetDefaultValue('button', 'hotkeyTextFont', self.item, fnt);
		-- hght = A.GetDefaultValue('button', 'hotkeyTextSize', self.item, hght);
		-- frame.HotKey:SetFont(fnt,hght, "THICKOUTLINE");

		self:SetupFontStringFont(frame.Count, 'count');
		-- local fnt, hght, flags = frame.Count:GetFont();
		-- fnt = A.GetDefaultValue('button', 'countTextFont', self.item, fnt);
		-- hght = A.GetDefaultValue('button', 'countTextSize', self.item, hght);
		-- flags = flags or "THICKOUTLINE";
		-- frame.Count:SetFont(fnt, hght, flags);


		-- local showed = self:CheckShowCondition();

		-- if (not showed) then 
		-- 	frame:SetSize(1,1);
		-- 	return 
		-- else
		-- 	local bar = self:GetParentBarBar();
		-- 	local size = bar.buttonSize;
		-- 	frame:SetSize(size, size);
		-- end;

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

	UpdateButtonPosition = function (self)

		local barModel = self:GetParentBarModel();
		local bar = barModel.item;
		local frame = self:GetButtonFrame();
		local btn = self.item;

		local index = self.index;
			--context.index;
		local lineSize = barModel:GetOption('buttonsInLine', 12);
			--context.lineSize;

		-- local lineNumber = context.lineNumber;
		-- local lineIndex = context.lineIndex;

		local lineNumber = math.modf(index / lineSize);
		local lineIndex = math.fmod(index, lineSize);

		local bar = self:GetParentBarBar();
		local barPadding = barModel:GetOption('padding', 0);
		local barSpacing = barModel:GetOption('spacing', 0);

		local point, parent, relativePoint;
		local offsetX = 0;
		local offsetY = 0;
		local grow = A.Grows.Get(barModel:GetOption('grow','rightDown'));

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

		local buttonSize = barModel:GetOption('buttonSize', 36);		
		frame:SetSize(buttonSize, buttonSize);

		frame:ClearAllPoints();
		frame:SetPoint(point, parent, relativePoint, offsetX, offsetY);
	
	end,

	SetRefreshListeners = function(model)
		local frame = model:GetButtonFrame();
		for event, x in pairs(model.refreshOn) do
			frame:RegisterEvent(event);
		end
	end,

	UnsetRefreshListeners = function(model)
		local frame = model:GetButtonFrame();
		for event, x in pairs(model.refreshOn) do
			frame:UnregisterEvent(event);
		end
	end,

	SetupRefreshListeners = function(model)
		local frame = model:GetButtonFrame();

		model.refreshOn = {
			-- ["BAG_UPDATE"] = 2,
			-- ["BAG_UPDATE_COOLDOWN"] = 2,
			-- ["ACTIONBAR_UPDATE_COOLDOWN"] = 3,
			-- ["ACTIONBAR_UPDATE_USABLE"] = 3,
			-- ["SPELL_UPDATE_USABLE"] = 1,
			["UNIT_POWER_UPDATE"] = { 1, function(arg) return arg=="player" end },
			-- ["PLAYER_ALIVE"] = 3,
			-- ["PLAYER_UNGHOST"] = 3,
			-- ["PLAYER_DEAD"] = 3,
			-- ["PLAYER_LEVEL_UP"] = 3,
		}

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
				if not model:IsVisibleNow() then return end;
				model:UpdateButtonFrame();
			end
		end)
	end,

	NormalizeButtonItem = function(model)
		if model:IsEmpty() then return end;
		if model:IsMacros() then
			local result = NormalizeMacros(model.item);
			if result == "clean" then
				model:Clean();
			end
		end
	end,

	InitializeButton = function(self)
		if (self.builded) then return end;
		local btn = self.item;
		local mixData = A.Button.BuildAttributes(btn, true, 'Button: InitializeButton');
		if (type(mixData) == "table") then
			_.mixin(btn, mixData);
		end
	end,

	CreateButtonFrame = function(self)
		local parent = self:GetParentBarFrame();
		local button = self.item;
		local bar = self.parentBar;
		local barModel = A.Bar.ToModel(bar);

		local frame = CreateFrame("Button", _.buildFrameName(button.id), parent, "ActionButtonTemplate, SecureActionButtonTemplate, SecureHandlerEnterLeaveTemplate");
		self:SetButtonFrame(frame);
		local iconBorder = frame:CreateTexture("$parentIconBorder", "BACKGROUND", nil, 2);
		iconBorder:SetAllPoints();
		iconBorder:SetTexture(iconsPath .. "Border-64x64-classic");
		iconBorder:Hide();
		frame.icon.inconBorder = iconBorder;

		if (barModel.item.isNested) then
			frame.isNested = true;
			frame:SetAttribute("isNested", true);
		end
		frame.TBButtonId = button.id;
		frame.TBBarId = bar.id;

		if (button.hidden) then
			frame:Hide();
		end

		-- local size = barModel:GetOption('buttonSize', 36);		
		-- frame:SetSize(size, size);

		--local ntsize = size * 1.83333; --1.78378378;
		frame.NormalTexture:SetSize(.1, .1);
		frame.bgOverlay = _.createColorTexture(frame, .5, 0, 0, 0, "BORDER");

		_.mixin(frame, ButtonFrameMixin);

		frame:RegisterForClicks("AnyUp");
		frame:RegisterForDrag("LeftButton");
		frame:SetAttribute("type2", "ShowContextMenu");
		if (frame.isNested) then
			frame:SetAttribute("shift-type2", "SwapWithParent");
		end

		frame:SetScript("OnDragStart", frame.DragStartHandler);

		return frame;
	end,

	InitializeButtonFrame = function(self, context)

		if (self.builded) then return end;

		local bar = self.parentBar;
		local barModel = A.Bar.ToModel(bar);
		local buttonModel = self;
		local button = self.item;
		--local size = barModel:GetOption('buttonSize', 36);
			--bar.buttonSize;

		local parent = self:GetParentBarFrame();
		local frame = self:CreateButtonFrame();
		
		--frame:SetReferences(self);
		frame:SetupMouseBehavior(self);
		
			
		self:SetupRefreshListeners();
		self:SetRefreshListeners();

		if (not button.hidden) then
			frame:Show();
		end	

		self:SetupButtonFrameTheme();

		return true;
	end,

	SetupButtonFrameTheme = function(self)
		local frame = self:GetButtonFrame();
		local cls = self:GetParentOption("classicButtonLook", false);
		if (cls) then
			local texcoords = {0, 0, 0, 1, 1, 0, 1, 1};
			frame.icon:SetTexCoord(unpack(texcoords));
			local pt = frame:GetPushedTexture();
			pt:SetTexCoord(unpack(texcoords));
			local hlt = frame:GetHighlightTexture();
			hlt:SetTexCoord(unpack(texcoords));
		else
			local texcoords = self:GetParentOption("buttonIconTexCoord", {.08, .92, .08, .92});
			frame.icon:SetTexCoord(unpack(texcoords));
			local pt = frame:GetPushedTexture();
			pt:SetTexCoord(unpack(texcoords));

			local hlt = frame:GetHighlightTexture();
			hlt:ClearAllPoints();
			hlt:SetPoint("TOPLEFT", 0, 0);
			hlt:SetPoint("BOTTOMRIGHT", 0, 0);
			hlt:SetAllPoints();

			--hlt:SetSize(size, size);

			hlt:SetTexCoord(unpack(texcoords));
			--_.setFrameBorder(frame, 0, 0, 0, .8);
			
			-- local bg = _.createColorTexture(frame, 0, 0, 0, .1, "BACKGROUND");
			-- bg:SetDrawLayer("BACKGROUND", -1);

		end	

	end,

	SetButtonFrameReferences = function(self)
		local frame = self:GetButtonFrame();
		frame:SetReferences(self);
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

	GetRootBarFrame = function(self)
		local parent = self:GetParentBarModel();
		return parent:GetRootBarFrame();
	end,

	--#endregion
	IsMacros = function(self)
		return self.item.type == "macro";
	end,
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
		if (frame) then
			frame:Show();
		end
	end,
	Hide = function(self)
		local frame = self:GetButtonFrame();
		if (frame) then
			frame:Hide();
		end
	end,

	--#region Popup
	SetupButtonPopupBehavior  = function (self)

		if 1 == 1 then return end

		if (InCombatLockdown()) then return end;
		local buttonFrame = self:GetButtonFrame();
		local popupFrame = self:GetPopupFrame();

		if (popupFrame) then
			buttonFrame:SetFrameRef("popupFrame", popupFrame);
			buttonFrame:SetFrameRef("popupsbg", popupFrame.sbg);
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


		end
		if (_.isValue(button.type)) then
			local cloned = _.cloneTable(self.item, nil, "type", "typeName", "info");
			return cloned;
		end
	end,

	Change = function(self, newbutton)

		local button = self.item;
		_.mixin(button, newbutton);
		self:SetupButtonFrame();
		self:UpdateButtonFrame();		
	end,

	Clean = function(self, force)
		local button = self.item;
		if (not self:IsCleanAllowed(force)) then
			return;
		end
		button.type = nil;
		button.typeName = nil;
		button.attrs = { ["*type1"] = "", special = false };
		button.info = {
			icon = EMPTYSLOT
		};
		self:SetupButtonFrame();
		self:UpdateButtonFrame();	
	end,
	IsCleanAllowed = function(self, force)
		if (force == true) then return true end
		return self:GetParentOption("disableCleanupOnDrag") ~= true;
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

	end,

	GetParentOption = function(self, key, ...)
		local model = self:GetParentBarModel();
		return model:GetOption(key, ...);
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
	if (model.deleted or model.disabled) then
		return false, model, false;
	end

	-- local visible = model:IsVisible();
	-- if (not visible and model:IsShown()) then
	-- 	if (not InCombatLockdown()) then
	-- 		model:Hide();
	-- 	end
	-- 	return true, model, false;
	-- elseif (visible and model:IsHidden()) then
	-- 	if (not InCombatLockdown()) then
	-- 		model:Show();
	-- 	end
	-- end

	local barModel = model:GetParentBarModel();
	local buttonsInLine = barModel:GetOption('buttonsInLine', 12);
	local bar = barModel.item;
	local firstInLine = false;

	if (index ~= nil) then
		firstInLine = math.fmod(index, buttonsInLine) == 0;
		model.index = index;
	end

	model:NormalizeButtonItem();
	--return true, model, firstInLine;

	model:InitializeButton();
	if not model:InitializeButtonFrame() then
		model:SetupButtonFrameTheme();
	end

	model:UpdateButtonPosition();

	if (button.bar) then
		A.Bar.Build(button.bar);
	end

	model:SetupButtonFrame();
	if model:IsVisibleNow() then 		
		model:UpdateButtonFrame();
	end
	model:SetupButtonPopupBehavior();
	model:SetButtonFrameReferences();

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


A.Button.BuildAttributes = function(thingType, thingId, debug)

	local info;
	local isRealButton = type(thingType) == "table";
	local cacheForced;
	local btn;
	local btnInfo = {};
	if (isRealButton) then
		btn = thingType;
		cacheForced = thingId == true;
		thingId = thingType.typeName;
		thingType = thingType.type;
		btnInfo = btn.info;
	end
	if (isRealButton and not thingType) then
		return A.Button.Empty();
	elseif (thingType == "spell") then

		local spellId = isRealButton and btnInfo.id;

		if (not spellId) then
			spellId = select(2, GetSpellBookItemInfo(thingId, BOOKTYPE_SPELL));
		end

		if (type(spellId) == "number") then

			info = _.GetSpellInfoTable(spellId, true);

			if isRealButton and not info then
				info = _.GetSpellInfoTable(btnInfo.name);
			end

		elseif (isRealButton) then
			info = _.cloneTable(btnInfo);
		else
			info = {
				name = thingId
			}
		end

		if isRealButton and not info then
			return A.Button.Empty();
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

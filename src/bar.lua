local A, _, L, Cache = Tabu:Spread(...);
A.Bar = {}


local LEVELS_PER_BAR = 7;


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
		local sbg = CreateFrame("Frame", _.buildFrameName(barid.."SECBG"), frame, "SecureHandlerEnterLeaveTemplate, SecureHandlerShowHideTemplate");
		local size = 100;
		local frameLevel = self:GetFrameLevel() - 1;
		sbg:SetFrameLevel(frameLevel);
		--_.print('#', sbg:GetName(), frameLevel);
		frame.sbg = sbg;

		frame:SetFrameRef("sbg", sbg);

		sbg:SetPoint("TOPLEFT", frame, "TOPLEFT", -size, size);
		sbg:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", size, -size);
		--_.createColorTexture(sbg, 1,1,0,0.2);
		sbg:Hide();

		sbg:SetFrameRef("common", A.COMMONFRAME);
	
		A.COMMONFRAME:SetFrameRef("bar_sbg_"..sbg:GetName(), sbg);

		sbg.hidePopups = function()
			A.Popup.HideAll();
		end

		local model = A.Bar.ToModel(barid);
		-- local parentModel = model:GetParentBarModel();
		-- local indx = 1;
		-- while (parentModel) do
		-- 	local pbf = parentModel:GetBarFrame();
		-- 	if (pbf and pbf.sbg) then
		-- 		sbg:SetFrameRef('parent_sbg_'..indx, pbf.sbg);
		-- 		indx = indx + 1;
		-- 	end
		-- 	parentModel = parentModel:GetParentBarModel();
		-- end
		--local parentModel = self:GetParentBarModel();

		sbg:SetAttribute("_onenter", [=[
			self:SetAttribute("hide_reason", "selfHide");
			
			
			local cmn = self:GetFrameRef("common");
			local openedPopupNames = cmn:GetAttribute("openedPopups") or "";
			if openedPopupNames ~= "" then
				local opn = newtable(strsplit(" ", openedPopupNames));
				for i, openedPopupName in pairs(opn) do
					local openedPopup = cmn:GetFrameRef("popup_"..openedPopupName);
					openedPopup:Hide();
				end
			end

			cmn:SetAttribute("openedPopups", "");

			if (self:IsShown()) then
				self:SetAttribute("hide_reason", "selfHide");
				self:Hide();
			end

		]=]);

		if (model:IsRoot()) then
			sbg:SetFrameRef("barframe", frame);
			sbg:SetAttribute("_onhide", [=[
				local reason = self:GetAttribute("hide_reason") or "";
				self:SetAttribute("hide_reason", "");

				if (reason ~= "selfHide") then return end;

				local pb = self:GetFrameRef('barframe');
				local should = pb:GetAttribute("enterLeaveVisible");
				if (not should) then return end
				pb:SetAlpha(0);
			]=]);
			-- sbg:SetScript("OnHide", function(self) 
			-- 	--local pb = frame:GetFrameRef('parent_bar');
			-- 	local should = frame:GetAttribute("enterLeaveVisible");
			-- 	if (not should) then return end
			-- 	self:SetAlpha(0);
			-- end);
		else
			local rootBarFrame = model:GetRootBarFrame();
			sbg:SetFrameRef("rootBarFrame", rootBarFrame);
			sbg:SetAttribute("_onhide", [=[
				local reason = self:GetAttribute("hide_reason") or "";

				self:SetAttribute("hide_reason", "");

				if (reason ~= "selfHide") then return end;

				local pb = self:GetFrameRef('rootBarframe');
				local sbg = pb:GetFrameRef("sbg");
				sbg:Show();
				sbg:SetAttribute("hide_reason", "selfHide");

				sbg:Hide();

			]=])
		end
	end,
	SetupVisibilityBehavior = function(frame, model)

		-- show on mouseover
		frame:SetAttribute("_onenter", [=[
			local should = self:GetAttribute("enterLeaveVisible");
			if (not should) then return end
			self:SetAlpha(1);
		]=]);

		-- show on combat/peace
		frame:SetAttribute("_onstate-combat", [=[
			local incombat = self:GetAttribute("combatVisible");
			local inpeace = self:GetAttribute("peaceVisible");
			if (incombat == true and inpeace == true) then
				return;
			end
			if newstate == "combat" then
				if incombat == true then
					self:Show();
				elseif inpeace == true then
					self:Hide();
				end
			else
				if incombat == true then
					self:Hide();
				elseif inpeace == true then
					self:Show();
				end
			end
		]=]);
		RegisterStateDriver(frame, 'combat', '[combat] combat; peace');

	end,
	CreateDraggableFrame = function(frame, model)
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
}

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

			-- bar.grow = bar.grow or parentBar.grow;
			-- bar.attachSide = bar.attachSide or pgrow.dir[2]; 

			buttonsInLine = parentBar.buttonsInLine
			buttonSize = parentBar.buttonSize
			padding = parentBar.padding
			spacing = parentBar.spacing
			alignCenter = parentBar.alignCenter
		else
			-- bar.grow = bar.grow or defaultGrowId;
			-- bar.point = bar.point or "CENTER";
		end



		-- bar.buttonsInLine = bar.buttonsInLine or buttonsInLine;
		-- bar.buttonSize = bar.buttonSize or buttonSize;
		-- bar.padding = bar.padding or padding;
		-- bar.spacing = bar.spacing or spacing;
		-- bar.alignCenter = bar.alignCenter or alignCenter;
		
	end,

	IsActive = function(self)
		if (self.deleted or self.hidden) then
			return false;
		else
			return true;
		end
	end,
	IsRoot = function(self)
		return self.item.isNested ~= true;
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



	-- local barShowOns = {
	-- 	["always"] = 0, 
	-- 	["when mouse over"] = 1, 
	-- 	["when alt pressed"] = 2, 
	-- 	["when shift pressed"] = 4, 
	-- 	["when control pressed"] = 8, 
	-- 	["when in combat"] = 16,
	-- 	["when not in combat"] = 32,
	-- 	["never"] = -1
	-- }	

	SetupVisibility = function(self)
		local vis = self:GetOption('showConditions', 0);

		self.visibility = {};
		if (vis == -1) then 
			self.hidden = true;
			return;
		end;
		self.hidden = nil;
		if (vis == 0) then 
			return 
		end;

		if (bit.band(vis, 1) > 0) then
			self.visibility.mouseOver = true;
		else
			self.visibility.mouseOver = false;
		end

		if (bit.band(vis, 2) > 0) then
			self.visibility.alt = true;
		else
			self.visibility.alt = false;
		end

		if (bit.band(vis, 4)> 0) then
			self.visibility.shift = true;
		else
			self.visibility.shift = false;
		end		

		if (bit.band(vis, 8)> 0) then
			self.visibility.cntrl = true;
		else
			self.visibility.cntrl = false;
		end	

		if (bit.band(vis, 16)> 0) then
			self.visibility.inCombat = true;
		else
			self.visibility.inCombat = false;
		end	

		if (bit.band(vis, 32)> 0) then
			self.visibility.inPeace = true;
		else
			self.visibility.inPeace = false;
		end	

		if (self.visibility.inPeace or self.visibility.inCombat) then
			self.visibility.stateDriver = true;
		else
			self.visibility.stateDriver = false;
		end


	end,

	InitializeBar = function(self)
		--initialize visibility;
		self:SetupVisibility();
	end,

	SetupBarFrame = function(self, onOptionsChange)
		local isRootBar = self:IsRoot(); --self.item.isNested ~= true;
		if (not (isRootBar and onOptionsChange)) then return end

		local shouldHide;
		local shouldShow;
		local frame = self:GetBarFrame();
		local shown = frame:IsShown();
		local action;

		frame:SetAttribute("enterLeaveVisible", self.visibility.mouseOver);
		frame:SetAlpha(self.visibility.mouseOver and 0 or 1);
		-- if (self.visibility.mouseOver ~= nil) then
		-- 	frame:SetAlpha(self.visibility.mouseOver and 0 or 1);
		-- else
		-- end

		if (
			(self.visibility.inCombat == true and self.visibility.inPeace == true)
			or
			(self.visibility.inCombat == nil and self.visibility.inPeace == nil)
		) then
			frame:SetAttribute("combatVisible", true);
			frame:SetAttribute("peaceVisible", true);
			action = "show";
			-- not specified
		elseif self.visibility.inCombat == true then
			frame:SetAttribute("combatVisible", true);
			frame:SetAttribute("peaceVisible", false);
			action = "hide";
		elseif self.visibility.inPeace == true then
			frame:SetAttribute("combatVisible", false);
			frame:SetAttribute("peaceVisible", true);
			action = "show";
		end


		if (not InCombatLockdown()) then
			if (shown and (self.hidden or action == "hide")) then
				frame:Hide();
			elseif (not shown and not self.hidden and action == "show") then
				frame:Show();
			end
		end
	end,

	SetupChildButton = function(self, model, onOptionsChange)
		local parent = self:GetBarFrame();
		local frame = model:GetButtonFrame();
		frame:SetFrameRef('parentBar', parent);
		if (self:IsRoot()) then
			frame:SetFrameRef('rootBar', parent);
		end
	end,

	InitializeBarFrame = function (self)
		if (self.builded) then return end;
		local isRoot = self:IsRoot();
		local bar = self.item;
		local point = bar.point;
		local posX = bar.posX;
		local posY = bar.posY;
		local parentFrame = self:GetParentButtonFrame();
		local parentBarFrame = self:GetParentBarBarFrame();
		local frame = CreateFrame("Frame", _.buildFrameName(bar.id), parentFrame or UIParent, "SecureHandlerBaseTemplate, SecureHandlerEnterLeaveTemplate, SecureHandlerShowHideTemplate, SecureHandlerStateTemplate");	
		_.mixin(frame, BarFrameMixins, "InitBarFrame");
		self:SetBarFrame(frame);

		frame:EnableMouse(true);

		frame:SetSize(1, 1);
		frame.bg = _.createColorTexture(frame, 0,0,0, 0);

		frame:CreateSecureBg(bar.id);
		local parentPopupNames = self:GetParentPopupNamesAsString();
		frame:SetAttribute("parentPopupNames", parentPopupNames);
		frame:SetFrameRef("common", A.COMMONFRAME);

		if (isRoot) then
			frame:CreateDraggableFrame(self);
			frame:SetupVisibilityBehavior(self);
		else
			A.COMMONFRAME:SetFrameRef("popup_"..frame:GetName(), frame);
			--A.Models.StoreAdd("popups", frame, self.id);
			frame:Hide();
		end

		self:SetupBarFrame(true);

	end,

	SetupLook = function(self)
		--local bar = self.item;
		local frame = self:GetBarFrame();
		--local parent = self:GetParentBarBar();

		local bg = self:GetOption('background', { 0, 0, 0, 0 });
		--Tabu.print(bg);
		frame.bg:SetColorTexture(unpack(bg));

	end,

	UpdateBarPosition = function (self)
		local inCombat = InCombatLockdown();
		if (inCombat and not self.indicator) then
			return;
		end

		local bar = self.item;
		local frame = self:GetBarFrame();
		local point, offsetX, ofssetY, relativeToParent;
		local parentBar, parentButton;
		parentBar = self:GetParentBarBar();
		frame:ClearAllPoints();
	
		if (bar.isNested) then
			local parentBarModel = self:GetParentBarModel();
			local parentGrow = parentBarModel:GetOption('grow', 'rightDown');
			parentFrame = self:GetParentButtonFrame();

			local owngrowid = bar.grow;
			local growid = self:GetOption('grow', 'rightDown'); --bar.grow or "rightDown";

			local grow = A.Grows.Get(growid);
			local side = self:GetOption('attachSide', 'BOTTOM');
	
			if (growid ~= owngrowid) then
				--bar.grow = growid;
				if (not _.arrayHasValue(grow.dir, sid)) then
					side = grow.dir[2];
					-- bar.attachSide = grow.dir[1];
					-- side = bar.attachSide;
				end
			end
	
			--local center = bar.alignCenter;
			local offsetX = 0;
			local offsetY = 0;

			local parentPad = parentBarModel:GetOption('padding', 0);
			local popupPad = self:GetOption('padding', 0);

			local hg = A.Grows.hgrow(grow.dir);
			local ohg = A.Grows.oppositeSide(hg);
			local vg = A.Grows.vgrow(grow.dir);
			local ovg = A.Grows.oppositeSide(vg);
			local oppositeSide = A.Grows.oppositeSide(side);
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
			local shouldCenter = self:GetOption('anchorOnCenter', false);
			if (shouldCenter) then
				point = oppositeSide;
				relativeToParent = side;
				offsetX, offsetY = 0, 0;
			end
			--print("#", point, relativeToParent, growid);
			frame:SetPoint(point, parentFrame, relativeToParent, offsetX, offsetY);
			frame:SetFrameLevel(parentFrame:GetFrameLevel() + 1);
		else
			point = self:GetOption('point','CENTER');
			offsetX = self:GetOption('posX',0);
			offsetY = self:GetOption('posY',0);
			frame:SetPoint(point, offsetX, offsetY);
		end
	end,

	GetBarLinesAndItems = function (self)
		local bar = self.item;
		local btns = self:GetButtons(); --bar.buttons or {}
		local items = 0;
		local lastOne;
		for _, b in pairs(btns) do
			local buttonModel = A.Button.ToModel(b);
			if (buttonModel:IsActive()) then
				items = items + 1;
			end
			lastOne = buttonModel;
		end
		if (lastOne:IsHidden()) then
			items = items - 1;
		end
		local buttonsInLine = self:GetOption('buttonsInLine', 12);
		local lines = math.modf((items > 0 and items - 1 or 0) / buttonsInLine) + 1;
		if (items > buttonsInLine) then
			items = buttonsInLine
		elseif (items == 0) then
			items = 1
		end
		return lines, items;
	end,

	ResizeBar = function (self)
		local inCombat = InCombatLockdown();
		if (inCombat and not self.indicator) then
			return;
		end

		local bar = self.item;
		local lines, items = self:GetBarLinesAndItems();
		local padding = self:GetOption('padding',0);
		local spacing = self:GetOption('spacing',0);
		local width = items;
		local height = lines;
		local grow = A.Grows.Get(self:GetOption('grow', 'rightDown'));
		local rev = grow.axisReverted == true;
		if (rev) then
			width = lines;
			height = items;
		end
		local buttonSize = self:GetOption('buttonSize', 36);		
		width = width * buttonSize + padding*2 + (width - 1)*spacing;
		height = height * buttonSize + padding*2 + (height - 1)*spacing;
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

	GetParentPopupNamesAsString = function(self)
		if (self:IsRoot()) then return "" end;
		local parent = self:GetParentBarModel();
		if (not parent) then return "" end;
		local name = self:GetBarFrame():GetName();
		local names = parent:GetParentPopupNamesAsString();
		if (names ~= "") then
			names = names .. " ";
		end
		return names .. name;
	end,

	GetRootBarModel = function(self)
		if (self:IsRoot()) then
			return self;
		else
			local parent = self:GetParentBarModel();
			if not parent then return end;
			return parent:GetRootBarModel();
		end
	end,
	GetRootBarFrame = function(self)
		local model = self:GetRootBarModel();
		return model and model:GetBarFrame() or nil;
	end,

	--#endregion

	--#region Buttons
	IsNotAuto = function(self)
		return not self.item.automatic;
	end,
	IsAuto = function(self)
		return not self:IsNotAuto();
	end,

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
		if (self:IsNotAuto()) then
			return bar.buttons or {};
		end
		return self:GetAutomaticButtons();
	end,

	SetButtons = function(self, buttons)
		if (self:IsNotAuto()) then
			self.item.buttons = buttons;
		end
	end,

	BuildButtons = function (self, onOptionsChange)


		local bar = self.item;
		local btns = self:GetButtons();
		table.sort(btns, function(a,b) return (a.index or 1000) < (b.index or 1000) end);

		local index = 0;
		local realIndex = 0;
		self.buttonsCount = 0;
		local newbtns = {};
		self.lastButton = nil;
		self.lastLineFirstButton = nil;
		for _, button in pairs(btns) do
			realIndex = realIndex + 1;
			button.index = realIndex;
			local valid, btnModel, firstInLine = A.Button.Build(button, index);
			if (valid) then
				if (btnModel:IsVisible()) then
					if (self.lastButton and self.lastButton:IsActive()) then
						self.lastButton:Show();
					end
					self.lastButton = btnModel;
					if (firstInLine) then
						self.lastLineFirstButton = btnModel;
					end
					index = index + 1;
					self.buttonsCount = index;
				end
				table.insert(newbtns, button);
			end

			self:SetupChildButton(btnModel, onOptionsChange);

		end
		self:SetButtons(newbtns);
		

		-- fix stored bar data, should be removed in future
		if (self.lastButton) then
			self.lastButton.item.hidden = nil;
		end

		if (self.buttonsCount == 1) then
			self.lastButton:Show();
		elseif (self.buttonsCount > 1 and self.lastButton:IsEmpty() and not A.isDragging()) then
			self.lastButton:Hide();
		end
	end,

	AddButton = function (self, kind, raw)
		if (self:IsAuto()) then return end;

		local buttonsCount = self.buttonsCount;
		if (not self.item.buttons) then
			self.item.buttons = {}
			buttonsCount = 0;
		end
		local buttons = self.item.buttons;

		if (type(kind) == "table" or kind == nil) then
			raw = kind;
			kind = "add";
		end
		if (raw) then
			raw = A.Button.BuildAttributes(raw.type, raw.typeName, 'Bar:AddButton');
		end

		local newbtn;

		-- if (kind == "expand" or kind == "initial") then
		-- 	newbtn = A.Button.NewButton(self.item);
		-- 	table.insert(buttons, newbtn.item);			
		-- else
		if (kind == "add") then
			if (buttonsCount <= 1 or not self.lastButton:IsEmpty()) then
				newbtn = A.Button.NewButton(self.item);
				if (type(raw) == 'table') then
					_.mixin(newbtn.item, raw);
				end
				table.insert(buttons, newbtn.item);
			else
				if (raw) then
					self.lastButton:Change(raw);
				end
			end
		end
		newbtn = A.Button.NewButton(self.item);
		table.insert(buttons, newbtn.item);			

		if (kind == "expand" or kind == "add") then
			self:Rebuild();
		end
		
	end,

	AddSpecialButton = function(self, special)
		local raw = _.cloneTable(special.proto, nil, "type", "typeName");
		self:AddButton(raw);
	end,

	Rebuild = function(self, optionsChanged)
		A.Bar.Build(self.item, nil, optionsChanged);
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
		if (self.lastButton == btnModel and not btnModel:IsEmpty()) then
			self:AddButton("expand");
		end
	end,


	GetOption = function(self, key, def)
		local pb, parentBarValue = self:GetParentBarModel(), "";
		if (pb) then
			parentBarValue = pb:GetOption(key) or "";
		end
		local value = A.GetDefaultValue('bar', key, self.item, parentBarValue, def);

		return value;
	end,

	GetFirstAvailableButton = function(self)
		local start, dur, en;
		for x, button in ipairs(self.item.buttons) do
			if (button.type) then

				if (button.type == "item") then
					start, dur, en = GetItemCooldown(button.info.id)
				elseif (button.type == "spell") then
					start, dur, en = GetSpellCooldown(button.info.id)
				end

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
	end,



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

A.Bar.Build = function (bar, index, optionsChanged)

	if (not bar) then
		_.print("Bar.Build nil argument");
		return;
	end
	if (index ~= nil) then
		bar.index = index;
	end
	local model = A.Bar.ToModel(bar);

	if (not optionsChanged and (model.deleted or model.hidden or bar.disabled)) then
		return;
	end

	
	--model:SetBarDefaults();
	model:InitializeBar(optionsChanged);
	model:InitializeBarFrame();
	model:SetupBarFrame(optionsChanged);
	model:SetupLook();
	model:BuildButtons(optionsChanged);

	-- combat locked:
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
	local x = {
		bar = bar,
		model = model
	}

	if (model:IsNotAuto()) then
		model:AddButton("initial");
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


-- local initBarItemButtons = function(bar)
-- 	local requestSended;
-- 	if not bar.buttons then return end;
-- 	for x,button in pairs(bar.buttons) do
-- 		if (button.type == "item" or button.type == "Item") then
-- 			GetItemInfo(button.typeName);
-- 			requestSended = true;
-- 		end
-- 		if (button.bar) then
-- 			requestSended = requestSended or initBarItemButtons(button.bar);
-- 		end
-- 	end
-- 	return requestSended;
-- end

-- A.Bar.initializeItems = function()
-- 	local requestSended;
-- 	local bars = Cache().bars;
-- 	if (not bars) then return end;
-- 	for x, bar in pairs() do
-- 		requestSended = requestSended or initBarItemButtons(bar);
-- 	end
-- end

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

	if (1 == 1) then return end

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

local hideLastButton = function(button)
end
local markButtonAsLast = function(button)
	local frame = button:GetButtonFrame();
	if (frame) then
		frame:Show();
	end
end


local function showBarLastButton(bar)
	if (not bar) then return end
	local btns = bar.buttons or {};
	for _, btn in pairs(btns) do
		showBarLastButton(btn.bar)
	end
	local model = A.Bar.ToModel(bar);
	if (not model.lastButton) then return end
	model.lastButton:Show();
	model:ResizeBar();

	-- local btnModel = A.Button.ToModel(model.prevButton);
	-- local frame = btnModel:GetButtonFrame();
	-- if (frame) then
	-- 	frame:Show();
	-- 	model.prevButton.hidden = false;
	-- 	model:ResizeBar();
	-- end
end

local function hideBarLastButton(bar)
	if (not bar) then return end
	local btns = bar.buttons or {};
	for _, btn in pairs(btns) do
		hideBarLastButton(btn.bar)
	end
	local model =  A.Bar.ToModel(bar);
	if (model.lastButton and model.buttonsCount > 1 and model.lastButton:IsEmpty()) then
		model.lastButton:Hide();
		model:ResizeBar();
	end
	-- if (not model.prevButton or model.prevButton.type or model.buttonsCount <= 1) then return end
	-- local btnModel = A.Button.ToModel(model.prevButton);
	-- local frame = btnModel:GetButtonFrame();
	-- if (frame) then
	-- 	frame:Hide();
	-- 	model.prevButton.hidden = true;
	-- 	model:ResizeBar();
	-- end
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
	--if (InCombatLockdown()) then return end;
	local barModel = A.Bar.ToModel(bar);
	local btns = barModel:GetButtons();
	for x, button in pairs(btns) do
		local model = A.Button.ToModel(button);
		model:UpdateButtonFrame();
		if (button.bar) then
			RefreshBarButtons(button.bar);
		end
	end
end

local function RefreshButtons()
	local db = Cache().bars;
	for x, bar in pairs(db) do
		--A.Bar.Build(bar);
		RefreshBarButtons(bar);
	end

end

A.Bar.RefreshButtonsOn = function(events)
	for x, event in pairs(events) do
		A.Bus.On(event, RefreshButtons);
	end
end

A.Bar.Iterate = function(callback)
	local db = Cache().bars;
	for x, bar in pairs(db) do
		callback(bar);
	end
end
A.Bar.Disable = function(bar)
	bar.disabled = true;
end
A.Bar.Enable = function(bar)
	bar.disabled = false;
end

A.Bar.ShowAllHidden = function(seconds)
	if (type(seconds) ~= "number") then
		seconds = 10;
	end
	if (InCombatLockdown()) then 
		_.print("Not available in combat");
		return 
	end;
	A.Bar.Iterate(function(bar) 
		local model = A.Bar.ToModel(bar);
		if (not model.builded) then
			return;
		end
		local frame = model:GetBarFrame();
		if (not frame) then return end;
		local shown = frame:IsShown();
		local alpha = frame:GetAlpha();
		local visible = shown and alpha > 0;
		if (visible) then return end;

		if (not shown) then
			frame:Show();
		end
		if (alpha ~= 1) then
			frame:SetAlpha(1);
		end

		if (not frame.hideTimer) then
			frame.hideTimer = CreateFrame("Cooldown", nil, frame);
			frame.hideTimer:SetSize(24,24);
			frame.hideTimer:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, 0);
		--else
		end
		frame.hideTimer:Show();
		frame.hideTimer:SetCooldown(GetTime(), seconds);
		--_.deprint('# show cd');
		C_Timer.After(seconds, function() 
			if (not shown and not InCombatLockdown()) then
				frame.hideTimer:Hide();
				frame:Hide();
			end
			if (alpha ~= 1) then
				frame:SetAlpha(alpha);
			end
		end)
	end);
end


-- A.Bar.SpellBookTabSpellsButtons = function(barModel)
-- 	local bar = barModel.item;
-- 	local auto = bar.automatic;
-- 	local btns = {};
-- 	local offset = auto.offset;
-- 	local numSpells = auto.spellsCount;

-- 	for s = offset + 1, offset + numSpells do

-- 		local proto = A.Button.SpellButtonProto(s, BOOKTYPE_SPELL);
-- 		local btn = {
-- 			id = "SpellButton"..proto.info.id,
-- 			barId = bar.id,
-- 		}
-- 		_.mixin(btn, proto);

-- 		table.insert(btns, btn);
-- 	end

-- 	return btns;
-- end

-- A.Bar.SpellBookTabsButtons = function(barModel)
-- 	local btns = {};
-- 	for i = 1, MAX_SKILLLINE_TABS do
-- 		local name, texture, offset, spellsCount = GetSpellTabInfo(i);

-- 		if not name then
-- 		   break;
-- 		end
-- 		local btn = A.Button.Empty();
-- 		btn.id = "SpellBookTabButton"..offset;
-- 		btn.barId = barModel.item.id;
-- 		btn.info.icon = texture;
-- 		btn.bar = {
-- 			id = "SpellBookTabBar"..offset,
-- 			parentButtonId = btn.id,
-- 			isNested = true,
-- 			automatic = {
-- 				type = "SpellBookTab",
-- 				offset = offset,
-- 				spellsCount = spellsCount
-- 			}
-- 		}
-- 		table.insert(btns, btn);
-- 		-- for s = offset + 1, offset + numSpells do
-- 		--    local	spell, rank = GetSpellName(s, BOOKTYPE_SPELL);
		   
-- 		--    if rank then
-- 		-- 	   spell = spell.." "..rank;
-- 		--    end
		   
-- 		--    DEFAULT_CHAT_FRAME:AddMessage(name..": "..spell);
-- 		-- end
-- 	 end	

-- 	 return btns;
-- end

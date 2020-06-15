local A, _, L = Tabu:Spread(...);
A.Settings = {}
A.Settings.FontPath = "Fonts\\ARIALN.ttf";

local SIDES = { "LEFT", "TOP", "RIGHT", "BOTTOM" };
local POINTS = { "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT", "LEFT", "TOP", "RIGHT", "BOTTOM", "CENTER" };


local BARCFGFRAME;
local BUTTONMENUFRAME;

local function createEditFrameLabel(edit, label)
	edit.label = edit:CreateFontString(nil, "ARTWORK"); 
	edit.label:SetPoint("LEFT", 0, 0);
	edit.label:SetFont(A.Settings.FontPath, 16);
	edit.label:SetText(label);
end

local function NumberEditFrame(label, parent, context)
	local edit = CreateFrame("Frame", nil, parent, _.buildFrameName("ConfigControlTemplate"));
	edit:SetHeight(40);
	createEditFrameLabel(edit, label);

	edit.control = CreateFrame("EditBox", nil, edit, "InputBoxTemplate");
	edit.control:SetFont(A.Settings.FontPath, 16);
	edit.control:SetPoint("RIGHT", edit, "RIGHT", 0, 0);
	edit.control:SetSize(90, 30);
	edit.control:SetAutoFocus(false);

	edit.setControlValue = function(self, text)
		local val = tostring(text or "");
		if (context.beforeValueSet) then
			val = context.beforeValueSet(val);
		end
		edit.control:SetText(val);
		local settled = edit.control:GetText();
	end
	edit.getControlValue = function(self)
		local value = edit.control:GetNumber();
		if (not value) then
			return nil;
		end
		return value;
	end


	return edit;
end


local function DropDownSetValue(self, value, text)
	self._value = value;
	if (not text or text == "") then text = value end
	UIDropDownMenu_SetText(self, text);
end

local function CreateDropDown(parent, make)
	local control = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate");
	UIDropDownMenu_SetWidth(control, 145)
	control:SetSize(178, 30);
	control:SetPoint("RIGHT", parent, "RIGHT");	
	control.getValue = function(self) 
		return self._value;
	end
	control.setValue = function(self, value, text) 
		self._value = value;
		if (not text or text == "") then
			text = value;
		end
		UIDropDownMenu_SetText(self, text);
	end;
	make(control);
	return control;
end

local function makePointDropdown(control, shouldBeSkiped)
	local info;
	local func = function(self, arg1, arg2, checked)
		control:setValue(arg1);
	end
	control.setValue = DropDownSetValue;
	control.isValueEqual = function(self, arg)
		return self:getValue() == arg;
	end
	if (not shouldBeSkiped) then
		shouldBeSkiped = function() end;
	end
	control.initialize = function(self)
		for _, point in pairs(POINTS) do
			local skip = shouldBeSkiped(point);
			if (not skip) then
				info = UIDropDownMenu_CreateInfo();
				info.text = point;
				info.arg1 = point;
				info.func = func;
				info.checked = control:isValueEqual(point)
			end
			UIDropDownMenu_AddButton(info, 1);
		end
	end
end

local function PointEditFrame(label, parent, context)
	local edit = CreateFrame("Frame", nil, parent, _.buildFrameName("ConfigControlTemplate"));
	edit:SetHeight(40);
	createEditFrameLabel(edit, label);
	edit.control = CreateDropDown(edit, makePointDropdown);
	edit.getControlValue = function(self)
		return self.control:getValue();
	end
	edit.setControlValue = function(self, value, text)
		self.control:setValue(value, text);
	end
	return edit;
end

local function makeGrowAndSideDropdown(control, parent, context)
	local info;
	local func = function(self, arg1, arg2, checked)
		control:setValue(arg1, arg2, A.Grows.GrowLabel(arg1, arg2));
	end
	local isChecked = function(grow, side)
		local val = control:getValue()
		return val[1] == grow and val[2] == side;
	end
	control.initialize = function()
		local pbar = parent.barModel:GetParentBarBar();
		for i, side in pairs(SIDES) do
			info = UIDropDownMenu_CreateInfo()
			local text = "attach to "..side;
			info.text = text;

			info.isTitle = true;
			info.notCheckable = true;
			UIDropDownMenu_AddButton(info, 1);			

			for gid, grow in pairs(A.Grows.items) do
				if (_.arrayHasValue(grow.dir, side)) then

					info = UIDropDownMenu_CreateInfo()
					info.text = A.Grows.GrowLabel(gid);
					info.checked = isChecked(gid, side);
					info.arg1 = gid;
					info.arg2 = side;
					info.func = func;
					UIDropDownMenu_AddButton(info, 1);					
				end
			end
		end


	end
end

local function GrowAndSideEditFrame(label, parent, context)
	local edit = CreateFrame("Frame", nil, parent, _.buildFrameName("ConfigControlTemplate"));
	edit:SetHeight(40);
	createEditFrameLabel(edit, label);
	edit.control = CreateDropDown(edit, function(self) makeGrowAndSideDropdown(self, parent, context) end);
	edit.control.setValue = function(self, value1, value2, text) 
		self._value = { value1, value2 };
		if (not text or text == "") then
			text = A.Grows.GrowLabel(value1, value2);
		end
		UIDropDownMenu_SetText(self, text);
	end;
	edit.getControlValue = function(self)
		return self.control:getValue();
	end
	edit.setControlValue = function(self, val, text)
		self.control:setValue(val[1], val[2], text);
	end

	return edit;
end

local function makeGrowDropdown(control, parent, context)
	local info;
	local func = function(self, arg1, arg2, checked)
		control:setValue(arg1, A.Grows.GrowLabel(arg1));
	end
	local isChecked = function(id)
		return control:getValue() == id;
	end
	control.initialize = function()
		for id, data in pairs(A.Grows.items) do
			info = UIDropDownMenu_CreateInfo()
			local text = A.Grows.GrowLabel(id);
			info.text = text;
			info.arg1 = id;
			info.func = func;
			info.checked = isChecked(id)
			UIDropDownMenu_AddButton(info, 1);
		end
	end
end

local function GrowEditFrame(label, parent, context)
	local edit = CreateFrame("Frame", nil, parent, _.buildFrameName("ConfigControlTemplate"));
	edit:SetHeight(40);
	createEditFrameLabel(edit, label);
	edit.control = CreateDropDown(edit, function(self) makeGrowDropdown(self, parent, context) end);
	edit.getControlValue = function(self)
		return self.control:getValue();
	end
	edit.setControlValue = function(self, value)
		self.control:setValue(value, A.Grows.GrowLabel(value));
	end
	return edit;
end






local barConfigControls = {
	{
		group = "main",
		onlyRoot = true,
		key = "grow",
		label = "Bar grow",
		control = "grow"
	},
	{
		group = "main",
		onlyRoot = true,
		key = "point",
		label = "Bar point",
		control = "point"
	},
	{
		group = "main",
		onlyRoot = true,
		key = "posX",
		label = "Bar point offset horizontal",
		control = "number",
		beforeValueSet = function(value) return value == "" and "" or _.round(value, 3) end
	},
	{
		group = "main",
		onlyRoot = true,
		key = "posY",
		label = "Bar point offset vertical",
		control = "number",
		beforeValueSet = function(value) return value == "" and "" or _.round(value, 3) end
	},
	{
		group = "main",
		onlyNested = true,
		key = { "grow", "attachSide" },
		label = "Bar grow and side",
		control = "growAndSide"
	},
	{
		group = "main",		
		key = "buttonsInLine",
		label = "Bar buttons count in line",
		control = "number"
	},
	{
		group = "main",		
		key = "buttonSize",
		label = "Bar buttons size",
		control = "number"
	},
	{
		group = "main",		
		key = "padding",
		label = "Bar padding",
		control = "number"
	},	
	{
		group = "main",		
		key = "spacing",
		label = "Buttons spacing",
		control = "number"
	},	
}

local function getValueForControl(cntx, bar)
	if (type(cntx.key) == "table") then
		local res = {};
		for _, key in pairs(cntx.key) do
			local v = bar[key];
			table.insert(res, v);
		end
		return res;
	else
		return bar[cntx.key];
	end
end

local function buildConfigControlFrame(cfgFrame, context)
	
	local controlType = context.control;
	local controlFrame;

	local label = L(context.label);

	if (controlType == "number") then
		controlFrame = NumberEditFrame(label, cfgFrame, context);
		
	elseif (controlType == "point") then
		controlFrame = PointEditFrame(label, cfgFrame, context);
	elseif (controlType == "grow") then
		controlFrame = GrowEditFrame(label, cfgFrame, context);
	elseif (controlType == "growAndSide") then
		controlFrame = GrowAndSideEditFrame(label, cfgFrame, context);

	else
		return;	
	end

	if (not controlFrame) then return end;
	
	controlFrame.applyFormValue = function(self, previous)
		local cfg = self:GetParent();
		local bar = cfg.bar;
		self:Hide();
		if (self.context.onlyRoot and bar.isNested) then
			return;
		end
		if (self.context.onlyNested and not bar.isNested) then
			return;
		end

		self:SetWidth(cfg:GetWidth() - 20);
		self:ClearAllPoints();
		if (not previous) then
			self:SetPoint("TOPLEFT", 10, -10);
		else
			self:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -5);
		end

		
		local val = getValueForControl(self.context, cfg.bar);
		--print("## val", tostring(val));
		self:setControlValue(val);

		self:Show();
	end
	controlFrame.context = context;
	return controlFrame;
end





local function fillControlFrameValues(cntrl, result)
	if (not cntrl or not cntrl.controlFrame or not cntrl.controlFrame:IsShown()) then return end;
	local value = cntrl.controlFrame:getControlValue();
	if (type(cntrl.key) == "table") then
		if (type(value) ~= "table") then
			value = { value };
		end
		for ind, key in pairs(cntrl.key) do
			result[key] = value[ind];
		end
	else
		result[cntrl.key] = value;
	end
end


local BarConfigFrameMixin = {
	GetValue = function(self, type)
		local res = {}
		for _, cntrl in pairs(barConfigControls) do
			fillControlFrameValues(cntrl, res);
		end
		return res;
	end,
	AfterApplyValues = function(self)
		self.barModel:Rebuild();
	end,
	ApplyFormValues = function(self)
		local value = self:GetValue("main");
		for k,v in pairs(value) do
			self.bar[k] = v;
		end
		self:AfterApplyValues();
	end,
	InitForm = function(self, bar)
		self.bar = bar;
		self.barModel = A.Bar.ToModel(bar);
		self:UpdateFrameValues(); --applyValuesToConfigFrame(self);
	end,
	UpdateFrameValues = function(frame)
		local previousControlFrame;
		for index, control in pairs(barConfigControls) do
			if (not control.id) then
				control.id = "CfgProp_"..index;
			end
			if (not control.controlFrame) then
				control.controlFrame = buildConfigControlFrame(frame, control);
			end
			if (control.controlFrame) then
				control.controlFrame:applyFormValue(previousControlFrame);
				if (control.controlFrame:IsShown()) then
					previousControlFrame = control.controlFrame;
				end
			end
		end
	end
}





local function createBarConfigFrame()
	local frame = CreateFrame("Frame", nil, UIParent);

	frame:SetFrameLevel(UIParent:GetFrameLevel() + 100);
	frame:SetPoint("CENTER");
	frame:SetSize(348, 448);
	_.createColorTexture(frame, 0,0,0,1);

	frame:EnableMouse(true);
	frame:SetMovable(true);
	frame:RegisterForDrag("LeftButton");
	frame:SetScript("OnDragStart", function(self) self:StartMoving(); end);
	frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end);

	_.mixin(frame, BarConfigFrameMixin);


	local save = CreateFrame("Button", nil, frame, "OptionsButtonTemplate");
	save:SetText(L("Save Changes"));
	save:SetSize(150, 26);
	save:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 5, 5);
	save:SetScript("OnClick", function(self) 
		frame:ApplyFormValues();
	end);

	local close = CreateFrame("Button", nil, frame, "OptionsButtonTemplate");
	close:SetText(L("Close"));
	close:SetSize(90, 26);
	close:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -5, 5);
	close:SetScript("OnClick", function() frame:Hide() end);

	return frame;
end


local function getConfigFrame()
	if (not BARCFGFRAME) then
		BARCFGFRAME = createBarConfigFrame();
	end
	return BARCFGFRAME;
end

A.Settings.ShowBarSettings = function(bar)
	if (not bar) then return end
	local frame = getConfigFrame();
	frame:InitForm(bar);
	frame:Show();
end


A.Settings.GetButtonMenuFrame = function()
	if (not BUTTONMENUFRAME) then
		BUTTONMENUFRAME = CreateFrame("Frame", _.buildFrameName("ButtonDropDown"), UIParent, "UIDropDownMenuTemplate")
	end	
	return BUTTONMENUFRAME;
end

A.Settings.PopulateButtonMenu = function (self, button, bar)
	local info = UIDropDownMenu_CreateInfo()
	info.notCheckable = true;
	info.isTitle = true;
	info.text = L("Button options:");
	local barModel = A.Bar.ToModel(bar);
	local btnModel = A.Button.ToModel(button);
	local isPopupBar = bar.isNested == true;
	local popupModel = btnModel:GetPopupModel();
	UIDropDownMenu_AddButton(info);


	info = UIDropDownMenu_CreateInfo()
	info.notCheckable = true;
	if (not btnModel:HasPopup()) then
		info.text = L("Add popup action bar")
		info.func = function()
			btnModel:AddBar()
		end;
	else

		-- info = UIDropDownMenu_CreateInfo()
		-- info.notCheckable = false;
		-- info.text = L("Take first available")
		-- info.checked = btnModel.item.useFirstAvailable == true
		-- info.func = function() 
		-- 	btnModel.item.useFirstAvailable = not btnModel.item.useFirstAvailable;
		-- 	btnModel:Rebuild();
		-- end;
		-- UIDropDownMenu_AddButton(info);	
	

		info = UIDropDownMenu_CreateInfo()
		info.notCheckable = true;
		info.text = L("Delete popup action bar")
		info.func = function() 
			popupModel:Delete();
		end;
	end
	UIDropDownMenu_AddButton(info);	

	if (barModel.buttonsCount > 1) then
		info = UIDropDownMenu_CreateInfo()
		info.notCheckable = true;
		info.text = L("Delete this button")
		info.func = function() 
			btnModel:Delete();
		end;
		UIDropDownMenu_AddButton(info);	
	end

	info = UIDropDownMenu_CreateInfo()
	info.notCheckable = true;
	info.isTitle = true;
	info.text = L("Bar options:");
	UIDropDownMenu_AddButton(info);

	info = UIDropDownMenu_CreateInfo()
	info.notCheckable = true;
	info.text = L("Open bar settings");
	info.func = function() 
		if (A.Locked("BarSettings")) then return end;		
		A.Settings.ShowBarSettings(bar);
	end;
	UIDropDownMenu_AddButton(info);	

	if (not isPopupBar) then
		info = UIDropDownMenu_CreateInfo()
		info.notCheckable = true;
		if (barModel.unlocked) then
			info.text = L("Lock bar");
			info.func = function() 
				barModel:Lock();
			end;
		else
			info.text = L("Unlock bar")
			info.func = function() 
				barModel:Unlock();
			end;			
		end
		UIDropDownMenu_AddButton(info);	
	end

	info = UIDropDownMenu_CreateInfo()
	info.notCheckable = true;
	info.text = L("Add button")
	info.func = function() 
		barModel:AddButton();
	end;
	UIDropDownMenu_AddButton(info);	

	info = UIDropDownMenu_CreateInfo()
	info.notCheckable = true;
	info.text = L("Delete this bar")
	info.func = function() 
		barModel:Delete();
	end;
	UIDropDownMenu_AddButton(info);	

end



local function FSLine(frame, previous)
	local fs = frame:CreateFontString();
	fs:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -5);
	fs:SetWidth(frame:GetWidth() - 10);
	fs:SetJustifyH("LEFT");
	fs:SetJustifyV("MIDDLE");
	fs:SetFont("Fonts\\ARIALN.ttf", 12);
	return fs;
end

local function SubHeader(frame, previous)
	local fs = FSLine(frame, previous);
	fs:SetFont("Fonts\\ARIALN.ttf", 16);
	fs:SetTextColor(1,1,1,1);
	fs:SetHeight(20);
	return fs;
end

A.Settings.CreateInfoFrame = function (chatCommands)
	local frame = CreateFrame("Frame", nil, UIParent, "Tabu_DialogTemplate");
	local height = 0;
	frame:SetFrameStrata("DIALOG");
	frame:SetWidth(400);
	_.createColorTexture(frame, .15,.15,.15,.8);
	_.addFrameBorder(frame, 0,0,0, 1);
	frame:SetPoint("CENTER", 0, 0);

	local width = frame:GetWidth() - 10;
	local fs = frame:CreateFontString();
	fs:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, -5);
	fs:SetSize(width, 30);
	fs:SetFont("Fonts\\ARIALN.ttf", 24);
	fs:SetText(A.OriginalName);
	fs:SetTextColor(1,.5,0,1);
	fs:SetJustifyH("LEFT");
	fs:SetJustifyV("TOP");
	height = height + fs:GetHeight() + 5;

	fs = SubHeader(frame, fs);
	fs:SetText(L("Chat commands:"));
	height = height + fs:GetHeight() + 5;

	for x, text in ipairs(chatCommands) do
		fs = FSLine(frame, fs);
		fs:SetText(L(text));
		height = height + fs:GetHeight() + 5;
	end

	fs = SubHeader(frame, fs);
	fs:SetText(L("Management:"));
	height = height + fs:GetHeight() + 5;

	fs = FSLine(frame, fs);
	fs:SetText(L("Mouseover any action button on Tabu-Bars bar and click right button for opening context menu"));
	height = height + fs:GetHeight() + 5;

	local btn = CreateFrame("Button", nil, frame, "OptionsButtonTemplate")
	btn:SetText(L("Create bar"));
	btn:SetSize(120, 26);
	btn:SetPoint("TOPLEFT", fs, "BOTTOMLEFT", 0, -20);
	btn:SetScript("OnClick", function() A.Bar.NewBar(); end);
	height = height + btn:GetHeight() + 26;

	frame:SetHeight(height);	
	return frame;
end

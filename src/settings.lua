local A, _, L, Cache = Tabu:Spread(...);
A.Settings = {}
A.Settings.FontPath = "Fonts\\ARIALN.ttf";
local C = Tabu.Controls;
local SIDES = { "LEFT", "TOP", "RIGHT", "BOTTOM" };
local POINTS = { "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT", "LEFT", "TOP", "RIGHT", "BOTTOM", "CENTER" };


local BARCFGFRAME;
local BUTTONMENUFRAME;


local function makeGrowAndSideDropdown(control, parent, context)
	local info;
	control.GetValueText = function()
		local v = control:GetControlValue() or {};
		return A.Grows.GrowLabel(v[1], v[2]);
	end
	control.initialize = function()
		local entity = parent:GetEntity();
		local barModel = A.Bar.ToModel(entity);	
		local pbar = barModel:GetParentBarBar();

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
					info.arg1 = gid;
					info.arg2 = side;
					info.checked = control:IsValueEqual(gid, side);
					info.func = control.ClickHandler;
					UIDropDownMenu_AddButton(info, 1);					
				end
			end

		end


	end
end
local function GrowAndSideEditFrame(parent, context)
	local edit = C.CreateEditFrame(parent, context);
	edit.control = C.CreateDropdownControl(edit, function(self) makeGrowAndSideDropdown(self, parent, context) end);
	return edit;
end
C:SetControlBuilder("growAndSide", GrowAndSideEditFrame);


local function makeGrowDropdown(control, parent, context)
	local info;
	control.GetValueText = function(self)
		local v = self:GetControlValue();
		return A.Grows.GrowLabel(v);
	end
	control.initialize = function()
		for id, data in pairs(A.Grows.items) do
			info = UIDropDownMenu_CreateInfo()
			local text = A.Grows.GrowLabel(id);
			info.text = text;
			info.arg1 = id;
			info.func = control.ClickHandler;
			info.checked = control:IsValueEqual(id)
			UIDropDownMenu_AddButton(info, 1);
		end
	end
end
local function GrowEditFrame(parent, context)
	local edit = C.CreateEditFrame(parent, context);
	edit.control = C.CreateDropdownControl(edit, function(self) makeGrowDropdown(self, parent, context) end);
	return edit;
end
C:SetControlBuilder("grow", GrowEditFrame);



local barShowOns = {
	["always"] = 0, 
	["mouseover"] = 1, 
	--["when alt pressed"] = 2, 
	--["when shift pressed"] = 4, 
	--["when control pressed"] = 8, 
	["in combat"] = 16,
	["not in combat"] = 32,
	--["never"] = -1
}



local contextShouldSkip = function(self, bar)
	if (
		(self.onlyRoot and bar.isNested) 
		or
		(self.onlyNested and not bar.isNested)
	) then
		return true
	end
end

local barConfigControls = {
	{
		group = "main",
		onlyRoot = true,
		key = "showConditions",
		label = "Bar show conditions",
		control = "bitwisemask",
		sourceValues = _.localizeKeys(barShowOns),
		shouldSkip = contextShouldSkip,
	},	
	{
		group = "main",
		onlyRoot = true,
		key = "grow",
		label = "Bar grow",
		control = "grow",
		defaultValue = "rightDown",
		shouldSkip = contextShouldSkip,
	},
	{
		group = "main",
		onlyRoot = true,
		key = "point",
		label = "Bar point",
		control = "point",
		defaultValue = "CENTER",
		shouldSkip = contextShouldSkip,
	},
	{
		group = "main",
		onlyRoot = true,
		key = "posX",
		label = "Bar point offset horizontal",
		control = "number",
		beforeValueSet = function(value) return value == "" and "" or _.round(value, 3) end,
		shouldSkip = contextShouldSkip,
	},
	{
		group = "main",
		onlyRoot = true,
		key = "posY",
		label = "Bar point offset vertical",
		control = "number",
		beforeValueSet = function(value) return value == "" and "" or _.round(value, 3) end,
		shouldSkip = contextShouldSkip,
	},
	{
		group = "main",
		onlyNested = true,
		key = { "grow", "attachSide" },
		label = "Bar grow and side",
		control = "growAndSide",
		shouldSkip = contextShouldSkip,
		getEntityValue = function(entity)
			local model = A.Bar.ToModel(entity);
			local grow = model:GetOption('grow', 'rightDown');
			local attachSide = model:GetOption('attachSide', 'BOTTOM');
			return { grow, attachSide }
		end
	},
	{
		group = "main",	
		onlyNested = true,	
		key = "anchorOnCenter",
		label = "Bar should be centered",
		control = "boolean",
		shouldSkip = contextShouldSkip,
		--defaultValue = false,
	},
	{
		group = "main",		
		key = "classicButtonLook",
		label = "Use classic buttons look",
		control = "boolean",
		shouldSkip = contextShouldSkip,
		--defaultValue = false,
	},	
	{
		group = "main",		
		key = "buttonsInLine",
		label = "Bar buttons count in line",
		control = "number",
		shouldSkip = contextShouldSkip,
		--defaultValue = 12,
	},
	{
		group = "main",		
		key = "buttonSize",
		label = "Bar buttons size",
		control = "number",
		shouldSkip = contextShouldSkip,
		--defaultValue = 36,
	},
	{
		group = "main",		
		key = "padding",
		label = "Bar padding",
		control = "number",
		shouldSkip = contextShouldSkip,
	},	
	{
		group = "main",		
		key = "spacing",
		label = "Buttons spacing",
		control = "number",
		shouldSkip = contextShouldSkip,
	},	
	{
		group = "main",		
		key = "background",
		label = "Bar background color",
		control = "color",
		--beforeValueSet = function(value) return value or {0, 0, 0, 0} end,
		shouldSkip = contextShouldSkip,
	},
	{
		group = "main",		
		key = "disableCleanupOnDrag",
		label = "Disable buttons cleanup",
		control = "boolean",
		shouldSkip = contextShouldSkip,
	},	
}

C.RegisterSettings(A, "BARSETTINGS", {
	-- tabs = {
	-- 	{ group = "main", name = "This bar settings" },
	-- 	{ group = "defs", name = "All bars defaults" },
	-- },
	controls = barConfigControls,
	mixin = {
		BeforeApplyValues = function(self, value)
			return value;
		end,
		AfterApplyValues = function(self)
			A.Bar.ToModel(self:GetEntity()):Rebuild(true);
		end
	}
});

A.Settings.ShowBarSettings = function(bar, afterApply)
	C.ShowSettings(A, "BARSETTINGS", bar, afterApply);
	-- local frame = getConfigFrame();
	-- frame:InitForm(bar);
	-- frame:Show();
end


local function GetFontHash()
	local hash = A.Lib.SharedMedia:HashTable( A.Lib.SharedMedia.MediaType.FONT );
	local res = {};
	for label, value in pairs(hash) do
		res[value] = label;
	end
	return res;
end

local buttonSettings = {
	-- {
	-- 	group = "main",
	-- 	key = "showCondition",
	-- 	label = "Button show",
	-- 	control = "buttonShow",
	-- },
	{
		group = "main",
		key = "countTextFont",
		label = "Count text font",
		control = "font",
		sourceValues = GetFontHash
	},
	{
		group = "main",
		key = "countTextSize",
		label = "Count text size",
		control = "number",
		defaultValue = 14,
	},			
	{
		group = "main",
		key = "hotkeyTextFont",
		label = "HotKey text font",
		control = "font",
		sourceValues = GetFontHash
	},	
	{
		group = "main",
		key = "hotkeyTextSize",
		label = "HotKey text size",
		control = "number",
		defaultValue = 10
	},				
}

C.RegisterSettings(A, "BUTTONSETTINGS", {
	controls = buttonSettings,
	mixin = {
		AfterApplyValues = function(self)
			deprint("AFTER APPLY")
			local model = A.Button.ToModel(self:GetEntity());
			model:UpdateButtonFrame();
			--A.Bar.ToModel(self:GetEntity()):Rebuild();
		end
	}
});

local buttonShowOns = {
	"always", "if on cd", "if not on cd", "never"
}
local function makeButtonShowOn(control, parent, context)
	local info;
	control.initialize = function()
		for k, data in pairs(buttonShowOns) do
			info = UIDropDownMenu_CreateInfo()
			local text = data;
			info.text = text;
			info.arg1 = data;
			info.func = control.ClickHandler;
			info.checked = control:IsValueEqual(data)
			UIDropDownMenu_AddButton(info, 1);
		end
	end
end
C:SetControlBuilder("buttonShow", function(parent, context) 
	local edit = C.CreateEditFrame(parent, context);
	edit.control = C.CreateDropdownControl(edit, function(self) makeButtonShowOn(self, parent, context) end);
	return edit;
end);

A.Settings.ShowButtonSettings = function(button, afterApply)
	C.ShowSettings(A, "BUTTONSETTINGS", button, afterApply);
end

-- #region Confirmation dialogs

local confirmProto = {
	button1 = L("Yes"),
	button2 = L("No"),
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,  -- avoid some UI taint, see http://www.wowace.com/announcements/how-to-avoid-some-ui-taint/
}

local ButtonDeleteConfirm = A.Name .. "_ButtonDeleteConfirm";
StaticPopupDialogs[ButtonDeleteConfirm] = _.mixin({
	text = L("Do you want to get rid of this button?"),
}, confirmProto);

local BarDeleteConfirm = A.Name .. "_BarDeleteConfirm";
StaticPopupDialogs[BarDeleteConfirm] = _.mixin({
	text = L("Do you want to get rid of this action bar?"),
}, confirmProto);

local PopupBarDeleteConfirm = A.Name .. "_PopupBarDeleteConfirm";
StaticPopupDialogs[PopupBarDeleteConfirm] = _.mixin({
	text = L("Do you want to get rid of this button's popup bar?"),
}, confirmProto);

-- #endregion



--#region Button Popup Menu

A.Settings.GetButtonMenuFrame = function()
	if (not BUTTONMENUFRAME) then
		BUTTONMENUFRAME = CreateFrame("Frame", _.buildFrameName("ButtonDropDown"), UIParent, "UIDropDownMenuTemplate")
	end	
	return BUTTONMENUFRAME;
end


local function GetSpecialButtonMenuItems(btnModel, barModel, popupModel)
	local res = {
		{
			info = {
				notCheckable = true,
				text = L("Simple button"),
				func = function() 
					-- args: silent, mixWith, tryAddTwo
					barModel:AddButton();
				end				
			}	
		},
		{
			separator = true,
		},		
		-- {
		-- 	info = {
		-- 		notCheckable = true,
		-- 		isTitle = true,
		-- 		text = "--------------",			
		-- 	}	
		-- }		
	}

	local sbtns = A.SButton.GetButtons();
	for i, btn in pairs(sbtns) do
		--Tabu.print(btn);
		table.insert(res, {
			info = {
				notCheckable = true,
				text = L(btn.label),
				func = function() 
					barModel:AddSpecialButton(btn);
				end	
			}
		});
	end
	return res;
end

local GetButtonPopupMenu = function(btnModel, barModel, popupModel, level)
	local isPopup = barModel.item.isNested == true;
	local notPopup = isPopup ~= true;
	local res = {
		{
			info = {
				isTitle = true,
				notCheckable = true,
				text = L("Button options:")
			}
		},
		-- {
		-- 	info = {
		-- 		notCheckable = true,
		-- 		text = L("Open button settings"),
		-- 		func = function() 
		-- 			A.Settings.ShowButtonSettings(btnModel.item);
		-- 		end;				
		-- 	}
		-- },		
		{
			available = not btnModel:HasPopup(),
			info = {
				notCheckable = true,
				text = L("Add popup action bar"),
				func = function()
					btnModel:AddBar()
				end;
			}
		},
		{
			available = btnModel:HasPopup(),
			info = {
				notCheckable = true,
				text = L("Delete popup action bar"),
				func = function() 
					StaticPopupDialogs[PopupBarDeleteConfirm].OnAccept = function()
						popupModel:Delete();
					end
					StaticPopup_Show(PopupBarDeleteConfirm);
				end
			}
		},
		{
			available = btnModel.item.type ~= nil,
			info = {
				notCheckable = true,
				text = L("Clean this button"),
				func = function() 
					btnModel:Clean();
				end
			}
		},		
		{
			available = barModel.buttonsCount > 1,
			info = {
				notCheckable = true,
				text = L("Delete this button"),
				func = function() 
					StaticPopupDialogs[ButtonDeleteConfirm].OnAccept = function()
						btnModel:Delete();
					end
					StaticPopup_Show(ButtonDeleteConfirm);
				end
			}
		},
		{
			separator = true,
		},		
		{
			info = {
				notCheckable = true,
				isTitle = true,
				text = L("Bar options:")
			}
		},
		{
			id = "ADDBUTTON",
			info = {
				hasArrow = true,
				notCheckable = true,
				text = L("Add button"),
				value = {
					Level1_Key = "ADDBUTTON",
					Sublevel_Key = "SIMPLEBUTTON"
				}			
			},
			children = GetSpecialButtonMenuItems(btnModel, barModel, popupModel)

		},		
		{
			info = {
				notCheckable = true,
				text = L("Open bar settings"),
				func = function() 
					A.Settings.ShowBarSettings(barModel.item);
				end;				
			}
		},
		{
			available = notPopup and barModel.unlocked == true,
			info = {
				notCheckable = true,
				text = L("Lock bar");
				func = function() 
					barModel:Lock();
				end
			}
		},
		{
			available = notPopup and barModel.unlocked ~= true,
			info = {
				notCheckable = true,
				text = L("Unlock bar");
				func = function() 
					barModel:Unlock();
				end
			}
		},
		{
			info = {
				notCheckable = true,
				text = L("Delete this bar"),
				func = function() 
					StaticPopupDialogs[BarDeleteConfirm].OnAccept = function()
						barModel:Delete();
					end
					StaticPopup_Show(BarDeleteConfirm);					
				end
			}
		}
	}
	if (level == 1) then
		return res;
	elseif (level == 2) then
		local parentId = UIDROPDOWNMENU_MENU_VALUE["Level1_Key"];
		local found = _.findFirst(res, function(item) return item.id == parentId end);
		if (found) then
			return found.children;
		end
	end

	return {};

end

A.Settings.PopulateButtonMenu = function (self, button, bar, level)
	local barModel = A.Bar.ToModel(bar);
	local btnModel = A.Button.ToModel(button);
	local popupModel = btnModel:GetPopupModel();

	local buttons = GetButtonPopupMenu(btnModel, barModel, popupModel, level);

	local info;
	for i, item in ipairs(buttons) do
		if (item.available ~= false) then
			if (item.separator) then
				UIDropDownMenu_AddSeparator(level);
			else
				info = UIDropDownMenu_CreateInfo();
				_.mixin(info, item.info);
				UIDropDownMenu_AddButton(info, level);
			end
		end
	end

end



--#endregion


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
	local frame = CreateFrame("Frame", nil, UIParent, "TabuBars_DialogTemplate");
	local height = 0;
	frame:SetFrameStrata("DIALOG");
	frame:SetWidth(400);
	_.createColorTexture(frame, .15,.15,.15,.8);
	_.setFrameBorder(frame, 0, 0, 0, 1);
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

	local btns = {
		{
			text = L("Create bar"),
			onclick = function() A.Bar.NewBar(); end
		},
		{
			text = L("Bar defaults"),
			onclick = function() 
				A.Settings.ShowBarSettings(Cache().barDefaults, A.Bar.BuildAll);
			end
		},
		{
			text = L("Button defaults"),
			onclick = function() 				
				A.Settings.ShowButtonSettings(Cache().buttonDefaults, A.Bar.BuildAll);
			end
		}
	}
	local prevBtn;
	for x, iBtn in ipairs(btns) do
		local btn = CreateFrame("Button", nil, frame, "OptionsButtonTemplate")
		btn:SetText(iBtn.text);
		btn:SetSize(140, 26);
		btn:SetScript("OnClick", iBtn.onclick);
		if (not prevBtn) then
			btn:SetPoint("CENTER", fs, "BOTTOM", 0, -40);
			height = height + btn:GetHeight() + 40;
		else
			btn:SetPoint("CENTER", prevBtn, "BOTTOM", 0, -15);
			height = height + btn:GetHeight() + 14;
		end
		prevBtn = btn;
	end
	

	-- btn = CreateFrame("Button", nil, frame, "OptionsButtonTemplate")
	-- btn:SetText(L("Bar defaults"));
	-- btn:SetSize(120, 26);
	-- btn:SetPoint("TOPLEFT", btn, "TOPRIGHT", 10, 0);
	-- btn:SetScript("OnClick", function()  end);

	-- btn = CreateFrame("Button", nil, frame, "OptionsButtonTemplate")
	-- btn:SetText(L("Button defaults"));
	-- btn:SetSize(120, 26);
	-- btn:SetPoint("TOPLEFT", btn, "TOPRIGHT", 10, 0);
	-- btn:SetScript("OnClick", function()  end);


	--height = height + 26;


	frame:SetHeight(height);	
	return frame;
end

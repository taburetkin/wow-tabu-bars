local A, _, L, Cache = Tabu:Spread(...);
A.Indi = {}
local iconsPath = "Interface\\AddOns\\"..A.OriginalName.."\\Media\\Icons\\";


-- local CHECKS = {
-- 	cooldown = function(self, flag, conditionValue)
-- 		if not conditionValue then
-- 			return not flag;
-- 		end
-- 		return flag;
-- 	end,
-- 	unitPower = function(self, unit, power, flag, amount)
-- 		local value = UnitPower(unit, power);
-- 		if value >= amount then
-- 			return flag;
-- 		else
-- 			return not flag;
-- 		end
-- 	end
-- }

-- local CONDITIONS = {
-- 	cooldown = {
-- 		label = "Cooldown",
-- 		check = function (flag, conditionValue)
-- 			return CHECKS:cooldown()
-- 		end
-- 	},
-- 	playerMana = {
-- 		label = "Player mana amount",
-- 		check = function (flag, conditionValue)
-- 			return CHECKS:unitPower("player", SPELL_POWER_MANA, flag, conditionValue);
-- 		end
-- 	},
-- }

-- local __CONDITIONS = {
-- 	spell = {
-- 		cooldown = {},
-- 		range = {},
-- 		power = {},
-- 		reagents = {},
-- 		castCount = {}
-- 	},
-- 	item = {
-- 		cooldown = {},
-- 		range = {},
-- 		count = {},
-- 	},
-- 	buff = {
-- 		duration = {},
-- 		count = {},
-- 		presence = {},
-- 	},
-- 	debuff = {
-- 		duration = {},
-- 		count = {},
-- 		presence = {},
-- 	},
-- 	custom = {

-- 	},
-- }

local IndiFrameMixin = {
	SetIcon = function(self, texture) 
		if texture == nil then
			if self.icon:IsShown() then
				self.icon:Hide();
			end
			return;
		end

		self.icon:SetTexture(texture);
		if not self.icon:IsShown() then
			self.icon:Show();
		end
	end,
	SetLabel = function(self, text) 
		if text == nil then
			if self.label:IsShown() then
				self.label:Hide();
			end
			return;
		end
		text = text or "";
		self.label:SetText(text);
		if not self.label:IsShown() then
			self.label:ClearAllPoints();
			self.label:SetPoint("LEFT");
			self.label:SetJustifyH("LEFT");
			self.label:Show();
		end

	end,
	SetCount = function(self, text) 
		text = text or "";
		self.count:SetText(text);
	end,
	_setTimerFrame = function(self, frame, start, duration)
		start = start or 0;
		duration = duration or 0;
		frame:SetCooldown(start, duration);
		if (start > 0) then
			frame:Show();
		else
			frame:Hide();
		end
	end,
	SetCooldown = function(self, start, duration) 
		self:_setTimerFrame(self.cooldown, start, duration);
	end,
	SetDuration = function(self, start, duration) 
		self:_setTimerFrame(self.duration, start, duration);
	end,
	---------------
	UpdateCount = function(self, model)
		model = model or A.Indi.ToModel(self.TBButtonId);
		self:SetCount(model:GetEntityCount());
	end,
	UpdateLabel = function(self, model)
		model = model or A.Indi.ToModel(self.TBButtonId);
		local indiType = model:GetParentBarIndicatorType();
		if indiType == "icon" then
			self:SetLabel(nil);
		else
			self:SetLabel(model:GetEntityLabel());
		end
	end,
	UpdateCooldown = function(self, model)
		model = model or A.Indi.ToModel(self.TBButtonId);
		self:SetCooldown(model:GetEntityCooldown());
	end,
	UpdateDuration = function(self, model)
		model = model or A.Indi.ToModel(self.TBButtonId);
		self:SetDuration(model:GetEntityDuration());
	end,
	UpdateIcon = function(self, model)
		model = model or A.Indi.ToModel(self.TBButtonId);
		local indiType = model:GetParentBarIndicatorType();
		if indiType == "icon" then
			self:SetIcon(model:GetEntityIcon());
		else
			self:SetIcon(nil);
		end
	end,
	Update = function(self, model, onChange)
		if (model == true or model == false) then
			onChange = model;
			model = nil;
		end
		model = model or A.Indi.ToModel(self.TBButtonId);
		-- if onChange then
		-- end
		self:UpdateIcon(model);
		self:UpdateLabel(model);
		self:UpdateCooldown(model);
		self:UpdateDuration(model);
		self:UpdateCount(model);
	end,
	Refresh = function(self, model)
		model = model or A.Indi.ToModel(self.TBButtonId);
		self:Update(model);
	end,
	ApplyTemplate = function(self, model)
		model = model or A.Indi.ToModel(self.TBButtonId);
		local indiType = model:GetParentBarIndicatorType();		
		if indiType == "icon" then
			self:SetSize(40,40);
			self.icon:SetAllPoints();
			self.count:ClearAllPoints();
			self.count:SetPoint("BOTTOMRIGHT", -2, -2);
		elseif indiType == "bar" then
			self:SetHeight(20);
			self.count:ClearAllPoints();
			self.count:SetPoint("RIGHT", 0, -2);
		elseif indiType == "text" then
			self:SetHeight(20);
		end
	end,
	Setup = function(self, model)
		model = model or A.Indi.ToModel(self.TBButtonId);
		self:ApplyTemplate(model);
		self:Update(model, true);
	end,
}


local IndiMixin = {

	GetParentBarBar = function(self)
		return self.parentBar;
	end,

	GetParentBarModel = function(self) 
		local bar = self:GetParentBarBar();
		return A.IndiBar.ToModel(bar);
	end,

	GetParentBarFrame = function(self)
		local model = self:GetParentBarModel();
		return model and model:GetBarFrame();
	end,

	GetParentBarIndicatorType = function(self)
		local bar = self:GetParentBarBar();
		return bar.type;
	end,

	--#region
	GetIndicatorFrames = function(self)
		if not self.frames.indicators then
			self.frames.indicators = {};
		end
		return self.frames.indicators;
	end,
	GetIndicatorFrame = function (self, indicatorType)
		if not indicatorType then
			indicatorType = self:GetParentBarIndicatorType();
		end
		local frames = self:GetIndicatorFrames();
		return frames[indicatorType];
	end,

	SetIndicatorFrame = function (self, frame, indicatorType)
		indicatorType = indicatorType or self:GetParentBarIndicatorType();
		if not indicatorType then			
			error("SetIndicatorFrame fail, indicatorType not specified");
		end
		local frames = self:GetIndicatorFrames();
		frames[indicatorType] = frame;
	end,

	HideOtherIndicators = function(self)
		local current = self:GetParentBarIndicatorType();
		local frames = self:GetIndicatorFrames();
		for id, frame in pairs(frames) do
			if id ~= current then
				frame:Hide();
			end
		end
	end,

	CreateIndicatorFrame = function(self)
		local indi = self.item;
		local bar = self:GetParentBarBar();
		local parentFrame = self:GetParentBarFrame();

		local frame = CreateFrame("Frame", _.buildFrameName(indi.id), parentFrame);
		frame.TBButtonId = indi.id;
		frame.TBBarId = bar.id;
		self:SetIndicatorFrame(frame);

		_.mixin(frame, IndiFrameMixin);

		local icon = frame:CreateTexture("$parentIcon", "BACKGROUND", nil, 1);
		icon:SetAllPoints();

		local iconBorder = frame:CreateTexture("$parentIconBorder", "BACKGROUND", nil, 2);
		iconBorder:SetAllPoints();
		iconBorder:SetTexture(iconsPath .. "Border-64x64-classic");
		iconBorder:Hide();
		icon.inconBorder = iconBorder;

		frame.icon = icon;
		frame.icon:Hide();

		frame.label = frame:CreateFontString();
		frame.label:SetFont("Fonts\\ARIALN.ttf", 14, "THICKOUTLINE");
		frame.label:Hide();

		frame.count = frame:CreateFontString();
		frame.count:SetFont("Fonts\\ARIALN.ttf", 14, "THICKOUTLINE");
		frame.count:Hide();

		frame.cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate");
		frame.cooldown:Hide();

		frame.duration = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate");
		frame.duration:Hide();

		return frame;
	end,

	InitializeIndi = function(self)
		local indi = self.item;
		local indicator = self.item.indicator;
		if indi.type == "item" then
			indi.info = _.GetItemInfoTable(indi.typeName);
		elseif indi.type == "spell" or indi.type == "buff" or indi.type == "debuff" then
			indi.info = _.GetSpellInfoTable(indi.typeName);
		end
		if not indi.info then
			indi.info = {};
		end
	end,

	InitializeIndiFrame = function(self)
		local barType = self:GetParentBarIndicatorType();
		local frame = self:GetIndicatorFrame(barType);
		if not frame then
			frame = self:CreateIndicatorFrame(barType);
			frame:Setup(self);
			return frame, true;
		end	
		return frame;	
	end,

	GetConditions = function(self)
		local indicator = self.item.indicator or {};
		local checks = indicator.checks or {};
		return checks;
	end,

	IsConditionMet = function(self, condition)
		return A.IndiConditions.CheckCondition(self.item, unpack(condition));
	end,

	AreConditionsMet = function(self)
		local conditions = self:GetConditions();
		local count = 0;
		for _ind, condition in pairs(conditions) do
			count = count + 1;
			if not self:IsConditionMet(condition) then
				return false;
			end
		end
		return count >= 1;
	end,

	GetConditionsShow = function(self)
		local indicator = self.item.indicator or { show = true };
		return indicator.show == true;
	end,

	ShouldBeShown = function(self)
		local conditions = self:AreConditionsMet();
		local shouldShow = self:GetConditionsShow();
		local result = conditions and shouldShow or not shouldShow;
		return result;
	end,

	ShowOrHide = function(self)
		self:HideOtherIndicators();
		local shouldShow = self:ShouldBeShown();
		if shouldShow then
			self:Show();
		else
			self:Hide();
		end
	end,

	Show = function(self)
		local frame = self:GetIndicatorFrame();
		frame:Update();
		frame:Show();
	end,

	Hide = function(self)
		self:GetIndicatorFrame():Hide();
	end,
	--------

	GetEntityIcon = function(self)
		return self.item.info.icon;
	end,
	GetEntityLabel = function(self)
		return self.item.info.name;
	end,
	GetEntityCount = function(self)
		local indi = self.item;
		if indi.type == "item" then
			return GetItemCount(self.item.info.id);
		elseif indi.type == "spell" then
			-- local isKnown = IsKnownSpell(self.item.info.id)
			-- if not isKnown then return end
			return _.getSpellManaCount(self.item.info.id);
		elseif indi.type == "buff" or indi.type == "debuff" then
			local entityName = self.item.info.name;
			local unit = self.item.unit or "player"
			local filter = indi.type == "buff" and "HELPFUL" or "HARMFUL";
			return select(4, _.getUnitAura(unit, entityName, filter));
		end
	end,
	GetEntityCooldown = function(self)
		local indi = self.item;
		local start, duration;
		if indi.type == "item" then
			start, duration, enable = GetItemCooldown(self.item.info.id);
		elseif indi.type == "spell" then
			-- local isKnown = IsKnownSpell(self.item.info.id)
			-- if not isKnown then return end
			start, duration, enable = GetSpellCooldown(self.item.info.id);
		end
		_.print("#", indi.typeName, duration, duration and duration > 1.5);
		return start, duration
	end,
	GetEntityDuration = function(self)
		local indi = self.item;
		if indi.type ~= "buff" and indi.type ~= "debuff" then
			return;
		end
		local entityName = self.item.typeName;
		local unit = self.item.unit or "player"
		local filter = indi.type == "buff" and "HELPFUL" or "HARMFUL";
		local expires = select(6, _.getUnitAura(unit, entityName, filter));
		local now = GetTime();
		if not expires or expires == 0 or now > expires then
			return;
		end
		return now, expires - now;
	end,

}

A.Indi.Build = function(indi)
	local model = A.Indi.ToModel(indi);
	model:InitializeIndi();
	local frame, isnew = model:InitializeIndiFrame();
	if not isnew then
		frame:Refresh(model);
	end
	model:ShowOrHide();
	return model;
end

A.Indi.Refresh = function(item)
	local model = A.Indi.ToModel(item);
	model:ShowOrHide();	
end

A.Indi.ToModel = function(indi)
	if (indi == nil) then
		error("Indi.ToModel argument is nil")
		return;
	end	
	local parentBar;
	local model = A.Models.ToModel(indi, IndiMixin, "IndiToModel");
	if (model._initialized) then return model end
	
	indi = model.item;

	if (not indi.barId) then
		error("bar id missing for " .. indi.id);
	end
	
	parentBar = A.IndiBar.ToModel(indi.barId);
	if (not parentBar) then
		error("IndiBar not found: "..barId);
	end
	model.parentBar = parentBar.item;
	model._initialized = true;

	return model;

end


--[[

CountCheck:
  value: number
  compare: enum(equal, less, greater, lessOrEqual, greaterOrEqual)
  getValue: FUNC

spell:
	hasCooldown: yes/no (NO should check if spell in spellbook as well)
	reagentsCount: CountCheck
	manaCount: CountCheck

item:
	hasCooldown: yes/no (NO should check if item in bags as well)	
	count: CountCheck

buff:
	duration: CountCheck
	count: CountCheck (stacks)
	unit: enum[player|target|team] (team is experimental)

debuff:
	duration: CountCheck
	count: CountCheck (stacks)
	unit: enum[player|target|team] (team is experimental)


indicator:
	icon: FUNC texture,
	label: FUNC text,
	count: FUNC number
	cooldown: FUNC number, number,
	conditions: [],
	conditionAction: enum[show|hide]
	----
	ICON:
	  icon
	  count
	  cooldown
	TEXT:
	  label
	  count
	  cooldown
	BAR:
	  icon
	  label
	  count
	  cooldown


[
	{
		show = true
		checks = {
			{ "incombat", "=", true }
			{ "indungeon", "=", true }
			{ "inraidorgroup", "=", true }
			{ "castCount", "<", 3, 49000 }
			spellcastcount = { "<", 3, "spell", 49000 },
			cooldown = { "=", true, "spell", 49000 },
			cooldown = { "<", 10 }
		}
	}
]


--]]

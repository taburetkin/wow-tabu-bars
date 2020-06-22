local A, _, L = Tabu:Spread(...);

A.COMMONFRAME = CreateFrame("Frame", nil, UIParent, "SecureHandlerAttributeTemplate");

-- local F = [[Interface\AddOns\Tabu-Bars\]];
-- TabuBars.Fonts = {
-- 	ActionMan = F..[[Fonts\ActionMan.ttf]],
-- 	ContinuumMedium = F..[[Fonts\ContinuumMedium.ttf]],
-- 	DieDieDie = F..[[Fonts\DieDieDie.ttf]],
-- 	Expressway = F..[[Fonts\Expressway.ttf]],
-- 	Homespun = F..[[Fonts\Homespun.ttf]],
-- 	Invisible = F..[[Fonts\Invisible.ttf]],
-- 	PTSansNarrow = F..[[Fonts\PTSansNarrow.ttf]]
-- }



A.barsChangeDisabled = function()
	return InCombatLockdown();
	--return TabuBars.inCombat == true;
end

A.LockAnounce = function(type)
	_.print("Any changes not allowed while in combat", type);
end

A.Locked = function(type)
	if (A.barsChangeDisabled()) then
		A.LockAnounce(type);
		return true;
	end
	return false;
end

A.isDragging = function()
	return A.awaitingDrop == true;
end

local DRAGINFOFRAME;
local function getDraggingInfoFrame(btn)
	local fr;
	if (not DRAGINFOFRAME) then
		fr = _.createDialogFrame();
		--CreateFrame("Frame", nil, UIParent, "Tabu_DialogTemplate");
		fr:SetPoint("TOP", 0, -100);
		fr:SetSize(200, 60);

		fr:SetScript("OnHide", function(self) 
			if (A.isDragging()) then
				A.dragStop();
			end
		end)
		fr.icon = fr:CreateTexture(nil, "ARTWORK");
		fr.icon:SetPoint("LEFT", fr, 10, 0);
		fr.icon:SetSize(40, 40);
		fr.text = fr:CreateFontString(nil, "ARTWORK");
		fr.text:SetJustifyH("LEFT");
		fr.text:SetWidth(130);
		fr.text:SetFont("Fonts\\ARIALN.ttf", 12);
		fr.text:SetPoint("LEFT", 60, 0);
		fr.text:SetText(L("Dragging element"));
		DRAGINFOFRAME = fr;
	end

	if (btn) then
		local iconTexture = DRAGINFOFRAME.icon;
		if (type(btn.info.icon) == "function") then
			btn.info.icon(iconTexture);
		else
			iconTexture:SetTexture(btn.info.icon);
		end
	end

	return DRAGINFOFRAME;
end
A.GetDragItem = function()
	local thingType, id = GetCursorInfo();
	if (A.pickedUpButton) then
		thingType = A.pickedUpButton.type;
		id = A.pickedUpButton.typeName;
	end
	return A.Button.BuildAttributes(thingType, id);	
end

A.dragStart = function(btn, native)
	if (not btn) then
		A.nativeDragging = true;
		local thingType, id = GetCursorInfo();
		btn = A.Button.BuildAttributes(thingType, id);
	end
	A.nativeDragging = btn.type == "spell" or btn.type == "macro" or btn.type == "item";
	A.pickedUpButton = btn;
	local fr = getDraggingInfoFrame(btn);
	fr:Show();
	A.awaitingDrop = true;
	A.COMMONFRAME:SetAttribute("dragging", TabuBars.awaitingDrop);
	A.Bar.ShowLastButtons();
end

A.dragStop = function()
	A.awaitingDrop = false;
	A.pickedUpButton = nil;
	A.nativeDragging = nil;
	A.COMMONFRAME:SetAttribute("dragging", TabuBars.awaitingDrop);
	A.Bar.HideLastButtons();
	local fr = getDraggingInfoFrame();
	if (fr:IsShown()) then
		fr:Hide();
	end
	ClearCursor();
end


A.ClearCursor = function()
	A.dragStop();
	ClearCursor();
end

local defOptions = {
	bg = { 0, 0, 0, .8, "BACKGROUND" },
	border = { 0, 0, 0, 1 }
}
_.createDialogFrame = function(opts, frameType, frameName, frameParent, alsoInherits)

	local options = _.cloneTable(defOptions);
	_.mixin(options, opts or {});

	local inherits = "Tabu_DialogTemplate";
	if (alsoInherits) then
		inherits = inherits .. ", " .. alsoInherits;
	end
	frameType = frameType or "Frame";
	frameParent = frameParent or UIParent;

	local fr = CreateFrame(frameType, frameName, frameParent, inherits);
	if (options.bg) then
		_.createColorTexture(fr, unpack(options.bg));
	end
	if (options.border) then
		_.setFrameBorder(fr, unpack(options.border));
	end
	return fr;
end

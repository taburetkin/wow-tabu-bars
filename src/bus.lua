local A, _, L = Tabu:Spread(...);

-- local busFrame = CreateFrame("Frame", nil, UIParent);
-- local registeredEvents = {}

-- local function OnGlobalEvent(self, event, ...) 
-- 	local tmp = { ... };

-- 	local handlers = registeredEvents[event];

-- 	if (type(handlers) ~= "table") then return end;

-- 	for _, callback in pairs(handlers) do
-- 		if (type(callback) == "function") then
-- 			callback(...);
-- 		end
-- 	end
-- end
-- busFrame:SetScript("OnEvent", OnGlobalEvent);

-- local function registerEvent(event, cb)
	
-- 	if (type(cb) ~= "function") then return end;

-- 	local handlers = registeredEvents[event];
-- 	if (handlers == nil) then
-- 		busFrame:RegisterEvent(event);
-- 		handlers = {};
-- 		registeredEvents[event] = handlers;
-- 	end

-- 	table.insert(handlers, cb);
-- 	--print("#bus", event);
-- end

-- A.Bus = {
-- 	On = function (event, cb)
-- 		registerEvent(event, cb);
-- 	end
-- };

A.Bus.On("CURSOR_UPDATE", function(name)
	C_Timer.After(0.1, function() 
		if (A.barsChangeDisabled()) then return end;

		-- local cursorThing = GetCursorInfo();
		-- local remembered = A.pickedUpButton;
		-- local something = cursorThing or remembered;

		-- if (something and not A.isDragging()) then
		-- 	A.dragStart();
		-- elseif (not something and A.isDragging()) then
		-- 	A.dragStop();
		-- end

		local cursorThing = GetCursorInfo();

		-- drag from spellbook or macros pane
		if (cursorThing and not A.isDragging()) then
			A.dragStart();
			return;
		end

		-- drop somewhere in the middle when dragging from spellbok or macro pane
		if (not cursorThing and A.isDragging() and A.nativeDragging) then
			A.dragStop();
			return;
		end

	end)
end);



local itemsQueried = {};

-- A.Bus.OnItem = function(itemName, cb)
-- 	local handlers = itemsQueried[itemName];
-- 	if (not handlers) then
-- 		handlers = {}
-- 		itemsQueried[itemName] = handlers;
-- 	end
-- 	table.insert(handlers, cb);
-- 	print("# registered:", itemName);
-- end

-- A.Bus.On("GET_ITEM_INFO_RECEIVED", function(itemId, success) 
-- 	--print("?", itemId, success);
-- 	if (not success) then return end;
-- 	local tbl = _.GetItemInfoTable(itemId);	
-- 	print("# queried:", tbl and tbl.name);
-- 	if (not tbl or not tbl.name) then return end;	
-- 	local handlers = itemsQueried[tbl.name];
-- 	if (not handlers) then return end;
-- 	print("#REC:", itemId, success);
-- 	for x, cb in pairs(handlers) do
-- 		print(" -- ", tbl.name, "CBs");
-- 	 	cb(tbl);
-- 	end
-- end)

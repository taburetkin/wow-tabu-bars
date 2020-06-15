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

		local something = GetCursorInfo();

		if (something and not A.isDragging()) then
			A.dragStart();
		elseif (not something and A.isDragging()) then
			A.dragStop();
		end

	end)
end);



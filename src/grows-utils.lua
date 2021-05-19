local A, _, L = Tabu:Spread(...);

local GROWS = {
	leftDown = {
		dir = { "LEFT", "BOTTOM" },
		point = "TOPRIGHT", -- inv[0] and inv[1]
		relativePointFirst = "BOTTOMRIGHT", -- inv[0] amd [1]
		relativePoint = "TOPLEFT", -- [0] amd inv[1],
		-- sides = {
		-- 	"LEFT", "BOTTOM"
		-- }
	},
	leftUp = {
		dir = { "LEFT", "TOP" },
		point = "BOTTOMRIGHT",
		relativePointFirst = "TOPRIGHT",
		relativePoint = "BOTTOMLEFT"
	},
	rightDown = {
		dir = { "RIGHT", "BOTTOM" },
		point = "TOPLEFT",
		relativePointFirst = "BOTTOMLEFT",
		relativePoint = "TOPRIGHT"
	},
	rightUp = {
		dir = { "RIGHT", "TOP" },
		point = "BOTTOMLEFT",
		relativePointFirst = "TOPLEFT",
		relativePoint = "BOTTOMRIGHT"
	},
	upRight = {
		dir = { "TOP", "RIGHT" },
		point = "BOTTOMLEFT",
		relativePointFirst = "BOTTOMRIGHT",
		relativePoint = "TOPLEFT",
		axisReverted = true,
	},
	upLeft = {
		dir = { "TOP", "LEFT" },
		point = "BOTTOMRIGHT",
		relativePointFirst = "BOTTOMLEFT",
		relativePoint = "TOPRIGHT",
		axisReverted = true,
	},
	downRight = {
		dir = { "BOTTOM", "RIGHT" },
		point = "TOPLEFT",
		relativePointFirst = "TOPRIGHT",
		relativePoint = "BOTTOMLEFT",
		axisReverted = true,
	},
	downLeft = {
		dir = { "BOTTOM", "LEFT" },
		point = "TOPRIGHT",
		relativePointFirst = "TOPLEFT",
		relativePoint = "BOTTOMRIGHT",
		axisReverted = true,
	},
}

A.Grows = {
	items = GROWS,
	Get = function(id)
		return GROWS[id];
	end
}

A.Grows.GrowLabel =  function(id, arg)
	local gr = GROWS[id];
	local res =  gr.dir[1] .. " - " .. gr.dir[2];
	if (arg) then
		res = arg .. ", " .. res;
	end
	return res;
end

A.Grows.getAllowed = function (id)
	local sides = GROWS[id].dir;
	local res = {};
	for id, grow in pairs(GROWS) do
		if (_.arrayHasAny(grow.dir, sides)) then
			table.insert(res, id);
		end
	end
	return res;
end

A.Grows.hgrow = function (dir)
	if (dir[1] == "LEFT" or dir[1] == "RIGHT") then
		return dir[1];
	else
		return dir[2];
	end
end

A.Grows.vgrow = function (dir)
	if (dir[1] == "TOP" or dir[1] == "BOTTOM") then
		return dir[1];
	else
		return dir[2];
	end
end

A.Grows.isHorizontalSide = function (side)
	return side == "RIGHT" or side == "LEFT";
end

A.Grows.oppositeSide = function (side)
	if (side == "RIGHT") then
		return "LEFT";
	elseif (side == "LEFT") then
		return "RIGHT";
	elseif (side == "TOP") then
		return "BOTTOM";
	elseif (side == "BOTTOM") then
		return "TOP";
	end
end

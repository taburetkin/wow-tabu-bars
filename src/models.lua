local A, _, L = Tabu:Spread(...);
local models = {};
A.Models = {};

-- Initializing of model should be with table having filled id property.
-- { id = "something" } - ok
A.Models.ToModel = function(id, Mixin, debug)
	local item;
	if type(id) == "table" then
		item = id;
		id = item.id;
	end
	if not id then
		error("ToModel does not receive id. "..(debug or ""));
	end
	local model = models[id];
	if (not model) then
		if (not item) then
			_.print("ToModel fail. item argument is nil");
		end
		model = {
			id = id,
			item = item,
			frames = {},
		}
		_.mixin(model, Mixin, debug);
		models[id] = model;
	end
	return model;
end

A.Models.GetById = function(id)
	return models[id];
end

local stores = {};
local addToStore = function(self, item, id)
	if (not id) then
		id = item.id;
	end
	local exist = self.byId[id];
	if (not exist) then
		table.insert(self.items, item);
		local index = self.length + 1;
		self.length = index;
		self.byId[id] = {
			index = index,
			item = item
		}
		return index;
	else
		self.items[exist.index] = item;
		exist.item = item;
		return exist.index;
	end
end

A.Models.Store = function (key)
	local store = stores[key];
	if (not store) then
		store = A.Models.StoreCreate(key);
	end
	return store;
end

A.Models.StoreCreate = function(key)
	local store = {
		length = 0,
		items = {},
		byId = {},
	}
	store.Add = addToStore;
	stores[key] = store;
	return store;
end

A.Models.StoreAdd = function(key, item, id)
	local store = stores[key];
	if (not store) then
		store = A.Models.StoreCreate(key);
	end
	return store:Add(item, id);
end

A.Models.StoreItems = function (key)
	local store = stores[key];
	if (not store) then
		store = A.Models.StoreCreate(key);
	end
	return store.items;
end

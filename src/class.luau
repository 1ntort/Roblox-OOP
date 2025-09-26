local class = {
	main = nil;
	classes = {};
	unique = {
		none = newproxy();
		class = newproxy();
		mimic = newproxy();
		object = newproxy();
		raw = newproxy();
	}
}

local errors = {
	["not_found"] = `%s "%s" does not exist in %s "%s".`;
	["argument_expected"] = `Argument %s in "%s" does not contain a valid expected value.`;
	["invalid_argument"] = `Argument %s in "%s" has an invalid type. Expected %s, found %s.`;
	["invalid_modifier"] = `Invalid modifier specified when checking modifiers: "%s".`;
	["too_many_modifiers"] = `Too many modifiers specified when checking modifiers.`;
	["import_malformed"] = `Field %s of the importing table contains a malformed class: "%s".`;
	["import_unregistered"] = `Field %s of the importing table contains an unregistered class: "%s".`;
	["class_already_exists"] = `The class at "%s" already exists.`;
	["invalid_constructor"] = `Invalid constructor specified in class "%s".`;
	["modify_final"] = `%s "%s" is final.`;
	["access_private"] = `%s "%s" is private.`;
	["modify_constructor"] = `Attempt to modify the constructor of class "%s".`;
	["invalid_class"] = `Class "%s" does not exist.`;
	["import_already_exists"] = `Import "%s" ("%s") already exists in the environment.`;
	["import_not_found"] = `Import "%s" hasn't been imported yet.`;
	["main_already_exists"] = `The main class already exists.`;
	["main_not_found"] = `There is no main class.`;
}

function class.assert(input: any, code: string, ...: string)
	local message = assert(errors[code], `"{code}" is not a valid error code!`)
	if input == nil or input == false then
		local formatting = table.pack(...)
		for iteration, value in ipairs(formatting) do
			formatting[iteration] = tostring(value)
		end
		error(string.format(message, table.unpack(formatting)) .. ` ({code})`)
	end
	return input
end

function class.argumentCheck(...: { any | string })
	local name = debug.info(2, "n")
	for iteration, value in ipairs(table.pack(...)) do
		local input = value[1]
		local expected = value[2]
		
		class.assert(expected, "argument_expected", iteration, name)
		class.assert(typeof(expected) == "string", "argument_expected", iteration, name)
		local optional = if (string.sub(expected, -1, -1) == "?") then true else false
		if optional == true and input == nil then
			continue
		else
			expected = if (optional == true) then string.sub(expected, 1, -2) else expected
			local inputType = typeof(input)
			class.assert(expected == inputType, "invalid_argument", iteration, name, expected, inputType)
		end
	end
end

local modifiers = {"public", "private", "static", "final"}
function class.checkModifiers(isClass: boolean, input: string) class.argumentCheck({isClass, "boolean"}, {input, "string"})
	local final = {}
	
	local inputSplit = string.split(input, " ")
	local extends, name = false, false
	
	for iteration, argument in ipairs(inputSplit) do
		if table.find(modifiers, argument) then
			class.assert(final.name == nil, "invalid_modifier", argument)
			final[argument] = true
			continue
		elseif isClass == true then
			if extends == true then
				extends = false
				final.extends = argument
				continue
			elseif name == true then
				name = false
				final.name = argument
				continue
			elseif argument == "extends" then
				extends = true
				continue
			elseif argument == "class" then
				name = true
				continue
			elseif argument == "main" then
				final.main = true
				continue
			end
		end
		
		class.assert(final.name == nil, "invalid_modifier", argument)
		final.name = argument
	end
	
	return final
end

function class.constructor(name: string)
	local imported = getfenv(2)
	local unconstructed = class.assert(imported[name], "import_not_found", name)
	return unconstructed[name]
end

function class.import(importing: table) class.argumentCheck({importing, "table"})
	local final = getfenv(2)
	final["new"] = class.constructor
	
	for iteration, value in ipairs(importing) do
		local importString, name = value, nil
		if typeof(value) == "table" then
			importString = value[1]
			name = value[2]
		end
		
		local import = string.match(importString, "^%a%.?[A-z.]*$")
		class.assert(import, "import_malformed", iteration, importString)
		class.assert(class.classes[import], "import_unregistered", iteration, import)
		
		if name == nil then
			name = string.match(import, "[A-z]+$")
		end
		class.assert(final[name] == nil, "import_already_exists", import, name)
		final[name] = class.classes[import]
	end
	
	setfenv(2, final)
end

local function wrapConstructor(unconstructed: { any }, func: (any) -> nil) class.argumentCheck({unconstructed, "table"}, {func, "function"})
	local new = {
		class = unconstructed.class;
		name = unconstructed.name;
		
		modifiers = unconstructed.modifiers;
		
		map = unconstructed.map;
		public = unconstructed.public;
		private = unconstructed.private;
	}
	
	local newUserdata
	local mimicUserdata
	
	do
		local userdata = newproxy(true)
		local metatable = getmetatable(userdata)
		metatable.__metatable = class.unique.class

		function metatable:__index(index: string)
			if index == new.name then
				return new.constructor
			end

			local location = class.assert(new.map[index], "not_found", "Value", index, "class", new.class)
			local value = new[location][index].value
			if value == class.unique.none then
				return nil
			end

			if typeof(value) == "function" then
				return function(funcSelf, ...)
					if funcSelf == self then
						return value(newUserdata, ...)
					else
						return value(newUserdata, funcSelf, ...)
					end
				end
			end
			return value
		end

		function metatable:__newindex(index: string, value: any)
			class.assert(new.modifiers.final == nil, "modify_final", "Class", new.class)
			class.assert(index ~= new.name, "modify_constructor", new.class)

			local location = class.assert(new.map[index], "not_found", "Value", index, "class", new.class)

			local old = new[location][index]
			local oldModifiers = old.modifiers
			class.assert(oldModifiers.final == nil, "modify_final", "Value", index)
			old.value = value
		end

		newUserdata = userdata
	end

	do
		local userdata = newproxy(true)
		local metatable = getmetatable(userdata)
		metatable.__metatable = class.unique.mimic

		function metatable:__index(index: string)
			if index == new.name then
				return newUserdata[new.name]
			end

			local location = class.assert(new.map[index], "not_found", "Value", index, "class", new.class)
			class.assert(location == "public", "access_private", "Value", index)
			return newUserdata[index]
		end

		function metatable:__newindex(index: string, value: any)
			class.assert(index == new.name, "modify_constructor", new.class)

			local location = class.assert(new.map[index], "not_found", "Value", index, "class", new.class)
			class.assert(location == "public", "access_private", "Value", index)
			newUserdata[index] = value
		end

		mimicUserdata = userdata
	end
	
	return function(...)
		func(newUserdata, ...)
		return mimicUserdata
	end
end

function class.create(path: string, modifiers: { any }, contents: { any }, extendsPath: string?) class.argumentCheck({path, "string"}, {modifiers, "table"},  {contents, "table"}, {extendsPath, "string?"})
	class.assert(class.classes[path] == nil, "class_already_exists", path)
	if modifiers.private then
		error(`The "private" modifier on classes is not implemented yet.`)
	end
	
	local extends = if extendsPath ~= nil then class.assert(class.classes[extendsPath], "invalid_class", extendsPath)[class.unique.raw] else {}
	
	local new = {
		class = path;
		name = modifiers.name;
		
		constructor = nil;
		modifiers = modifiers;
		
		map = extends.map or {};
		public = extends.public or {};
		private = extends.private or {};
		static = extends.static or {
			map = {};
			public = {};
			private = {};
		};
	}
	
	local newUserdata
	local mimicUserdata
	
	for name, rawValue in pairs(contents) do
		if name == new.name then
			local value = rawValue.value
			class.assert(typeof(value) == "function", "invalid_constructor", name)
			
			new.constructor = wrapConstructor(new, value)
		end
		
		local valueModifiers = rawValue.modifiers
		local root = new
		if valueModifiers.static then
			root = root.static
		end
		
		if valueModifiers.private then
			root.private[name] = rawValue
			root.map[name] = "private"
		elseif valueModifiers.public then
			root.public[name] = rawValue
			root.map[name] = "public"
			
			root.map[name] = "public"
		end
	end
	
	do
		local userdata = newproxy(true)
		local metatable = getmetatable(userdata)
		metatable.__metatable = class.unique.class
		
		function metatable:__index(index: string)
			if index == class.unique.raw then
				return new
			end
			
			if index == new.name then
				return new.constructor
			end
			
			if index == class.unique.raw then
				return new
			end
			
			local location = class.assert(new.static.map[index], "not_found", "Static Value", index, "class", new.class)
			local value = new.static[location][index].value
			if value == class.unique.none then
				return nil
			end
			
			if typeof(value) == "function" then
				return function(funcSelf, ...)
					if funcSelf == self then
						return value(newUserdata, ...)
					else
						return value(newUserdata, funcSelf, ...)
					end
				end
			end
			return value
		end
		
		function metatable:__newindex(index: string, value: any)
			class.assert(new.modifiers.final == nil, "modify_final", "Class", new.class)
			class.assert(index ~= new.name, "modify_constructor", new.class)
			
			local location = class.assert(new.static.map[index], "not_found", "Static Value", index, "class", new.class)
			
			local old = new.static[location][index]
			local oldModifiers = old.modifiers
			class.assert(oldModifiers.final == nil, "modify_final", "Static Value", index)
			if value == nil then
				old.value = class.unique.none
			else
				old.value = value
			end
		end
		
		newUserdata = userdata
	end
	
	do
		local userdata = newproxy(true)
		local metatable = getmetatable(userdata)
		metatable.__metatable = class.unique.mimic

		function metatable:__index(index: string)
			if index == class.unique.raw then
				return new
			end
			
			if index == new.name then
				return newUserdata[new.name]
			end
			
			local location = class.assert(new.static.map[index], "not_found", "Static Value", index, "class", new.class)
			class.assert(location == "public", "access_private", "Static Value", index)
			return newUserdata[index]
		end

		function metatable:__newindex(index: string, value: any)
			class.assert(index == new.name, "modify_constructor", new.class)
			
			local location = class.assert(new.static.map[index], "not_found", "Static Value", index, "class", new.class)
			class.assert(location == "public", "access_private", "Static Value", index)
			newUserdata[index] = value
		end
		
		mimicUserdata = userdata
	end
	
	if modifiers.main then
		class.assert(class.main == nil, "main_already_exists")
		class.main = mimicUserdata
	end
	return mimicUserdata
end

function class.fromModule(path: string, module: ModuleScript) class.argumentCheck({path, "string"}, {module, "Instance"})
	local raw = require(module)
	local stringModifiers, contents = raw(class.import)
	local modifiers = class.checkModifiers(true, stringModifiers)
	
	local newContents = {}
	for rawModifiers, value in pairs(contents) do
		if typeof(rawModifiers) == "number" then
			local valueModifiers = class.checkModifiers(false, value)
			
			local newValue = {
				modifiers = valueModifiers;
				value = class.unique.none;
			}
			newContents[valueModifiers.name] = newValue
		else
		local valueModifiers = class.checkModifiers(false, rawModifiers)
		if value == nil then
			value = class.unique.none
		end
		
		local newValue = {
			modifiers = valueModifiers;
			value = value;
		}
		newContents[valueModifiers.name] = newValue
		end
	end
	
	local extends
	if modifiers.extends ~= nil then
		local env = getfenv(raw)
		extends = class.assert(env[modifiers.extends], "import_not_found", modifiers.extends)
	end
	
	local newPath = path .. "." .. modifiers.name
	return newPath, class.create(newPath, modifiers, newContents, extends)
end

function class.register(start: string, root: Instance) class.argumentCheck({root, "Instance"})
	if root:IsA("ModuleScript") then
		local newPath, newClass = class.fromModule(start, root)
		class.classes[newPath] = newClass
	end
	
	local newStart = start .. "." .. root.Name
	local toLoop = root:GetChildren()
	
	table.sort(toLoop, function(a, b)
		local aModuleScript = a:IsA("ModuleScript")
		local bModuleScript = b:IsA("ModuleScript")
		
		if aModuleScript == false and bModuleScript == true then
			return true
		end
		return false
	end)
	
	for _, instance in ipairs(toLoop) do
		class.register(newStart, instance)
	end
end

function class.init(name: string)
	class.assert(class.main, "main_not_found")
	class.main[name]()
end

return class

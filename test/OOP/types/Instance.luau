--!nolint
return function(env) env()
	
	return "public class Instance", {
		"private Object";
		["public static final Instance"] = function(self, className: string, existing: Instance?)
			if existing ~= nil then
				self.Object = existing
			else
				self.Object = Instance.new(className)
			end
		end,
		
		["private final GetObject"] = function(self)
			return self.Object
		end,
		
		["public final SetParent"] = function(self, parent: Instance | { any })
			if typeof(parent) == "Instance" then
				self.GetObject().Parent = parent
			else
				local parentObject = parent.GetObject()
				self.GetObject().Parent = parentObject
			end
			
			return self
		end,
		
		["public final SetName"] = function(self, name: string)
			self.GetObject().Name = name
			return self
		end,
		
		["public final AddChild"] = function(self, child: Instance | { any })
			if typeof(child) == "Instance" then
				child.Parent = self.GetObject()
			else
				local childObject = child.GetObject()
				childObject.Parent = self.GetObject()
			end
		end,
		
		["public final AddChildren"] = function(self, children: {Instance | { any }})
			local object = self.GetObject()
			for _, child in ipairs(children) do
				if typeof(child) == "Instance" then
					child.Parent = object
				else
					local childObject = child.GetObject()
					childObject.Parent = object
				end
			end
		end,
		
		["public final SetChild"] = function(self, child: Instance | { any })
			local object = self.GetObject()
			object:ClearAllChildren()
			
			if typeof(child) == "Instance" then
				child.Parent = object
			else
				local childObject = child.GetObject()
				childObject.Parent = object
			end
		end,
		
		["public final SetChildren"] = function(self, children: {Instance | { any }})
			local object = self.GetObject()
			object:ClearAllChildren()
			
			for _, child in ipairs(children) do
				if typeof(child) == "Instance" then
					child.Parent = object
				else
					local childObject = child.GetObject()
					childObject.Parent = object
				end
			end
		end,
	}
end

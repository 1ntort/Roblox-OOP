--!nolint
return function(env)
	env({
		"dev.tort.OOP.lib.String";
	})
	
	return "main public class Start", {
		"private Name";
		"private String";
		["public static final Start"] = function(self)
			local testString = "waddup"
			
			local test = new "String"
			self.String = new "String"(testString)
			print("JSON Result:", self.String.JSON())
			self.Name = testString
		end
	}
end

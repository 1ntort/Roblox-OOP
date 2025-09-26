return function(env)
	env({})

	return "public class String", {
		"private HttpService";
		"private Input";
		["public static final String"] = function(self, input: string)
			self.HttpService = game:GetService("HttpService")
			self.Input = input
		end;
		["public final JSON"] = function(self)
			return self.HttpService:JSONEncode({self.Input})
		end;
	}
end

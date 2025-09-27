--!nolint
return function(env) env({
	
	"dev.tort.OOP.types.Instance";
	
	})

	return "public class Player extends Instance", {
		["public static final DataStore"] = "plr-%s";
		["public static final Player"] = function(self, player: Player?)
			if player ~= nil then
				self.Object = player
			else
				self.Object = super("Folder").GetObject()
			end
		end,
		
		["public final GetUserId"] = function(self)
			return self.GetObject().UserId
		end,
		
		["public final Kick"] = function(self, message: string?)
			self.GetObject():Kick(message)
		end,
	}
end

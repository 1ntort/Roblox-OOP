--!nolint
return function(env) env({
	
	{"dev.tort.OOP.game.players.Player", "testCustomName"};
	
	})
	
	return "main public class Main", {
		["public static final Main"] = function(self)
			print("Started Main.")
			game:GetService("Players").PlayerAdded:Connect(self.HandlePlayer)
			for _, playerObject in pairs(game:GetService("Players"):GetPlayers()) do
				self.HandlePlayer(playerObject)
			end
		end;
		
		["private final HandlePlayer"] = function(playerObject: Player)
			local player = new "testCustomName"(plr)
			print("User ID:", player.GetUserId())
			print("Object:", player.Object)

			print("DataStore:", testCustomName.DataStore)
			testCustomName.DataStore = "test"

			task.wait(2)
			player:Kick("Get out!")
		end,
	}
end

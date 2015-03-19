
-- LANBroadcaster.lua

-- Implements the entire plugin in a single file





function Initialize(a_Plugin)
	local port = 25565
	local SettingsIni = cIniFile()
	if not(SettingsIni:ReadFile("settings.ini")) then
		LOGWARNING("LANBroadcaster: Could not read settings.ini! Using default port " .. port)
	else
		ini_port = SettingsIni:GetValue("Server", "Port")
		if (ini_port == "") then
			LOGWARNING("LANBroadcaster: Could not find port in settings.ini! Using default port " .. port)
		else
			port = ini_port
		end
	end
	
	-- Open the UDP endpoint:
	-- Not interested in any callbacks, we're just sending data
	local Endpoint = cNetwork:CreateUDPEndpoint(0, {})
	if not(Endpoint:IsOpen()) then
		LOGINFO("LANBroadcaster: Cannot open UDP port for broadcasting: " .. a_ErrorCode .. " (" .. a_ErrorMsg .. ")")
		return
	end
	Endpoint:EnableBroadcasts()
	
	-- We don't have a generic task scheduler yet (#1754), so piggyback on the first available world's scheduler:
	local IsScheduled = false
	local OnWorldInitialized = function (a_World)
		-- Check if scheduler already active:
		if (IsScheduled) then
			return
		end
		IsScheduled = true
		-- Schedule the broadcast
		local Server = cRoot:Get():GetServer()
		local DatagramData = "[MOTD]" .. Server:GetDescription() .. "[/MOTD][AD]" .. port .. "[/AD]"
		local Task  -- Must be defined before assigning, because the function refers to itself
		Task = function ()
			-- Send the datagram:
			Endpoint:Send(DatagramData, "224.0.2.60", 4445)
			-- Re-schedule the task:
			a_World:ScheduleTask(30, Task)
		end
		a_World:ScheduleTask(30, Task)
	end

	-- Initialize the scheduler in the first started world, or (if reloading the server) on the default world:
	cPluginManager.AddHook(cPluginManager.HOOK_WORLD_STARTED, OnWorldInitialized)
	local DefaultWorld = cRoot:Get():GetDefaultWorld()
	if (DefaultWorld ~= nil) then
		OnWorldInitialized(DefaultWorld)
	end

	return true
end






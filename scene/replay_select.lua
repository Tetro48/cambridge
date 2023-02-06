local ReplaySelectScene = Scene:extend()

ReplaySelectScene.title = "Replays"

local sha2 = require "libs.sha2"
local binser = require 'libs.binser'

local current_submenu = 0
local current_replay = 1

function ReplaySelectScene:new()
	-- fully reload custom modules
	initModules(true)
	
	if not loaded_replays then
		loadReplayList()
	end
	self.display_error = false
	if #replays == 0 then
		self.display_warning = true
		current_replay = 1
	else
		self.display_warning = false
	end

	self.menu_state = {
		submenu = current_submenu,
		replay = current_replay,
	}
	self.das = 0
	self.height_offset = 0
	self.auto_menu_offset = 0
	self.state_string = ""
	DiscordRPC:update({
		details = "In menus",
		state = "Choosing a replay",
		largeImageKey = "ingame-000"
	})
end


function ReplaySelectScene.nilCheck(input, default)
	if input == nil then
		return default
	end
	return input
end

local function demandFromChannel(channel_name)
	local load_from = love.thread.getChannel(channel_name):demand()
	if load_from then
		return load_from
	end
end
function ReplaySelectScene:update()
	switchBGM(nil) -- experimental
	
	if not loaded_replays then
		self.state_string = love.thread.getChannel('load_state'):peek()
		local replay = popFromChannel('replay')
		local load = love.thread.getChannel( 'loaded_replays' ):pop()
		while replay do
			local mode_name = replay.mode
			replays[#replays+1] = replay
			if dict_ref[mode_name] ~= nil and mode_name ~= "znil" then
				table.insert(replay_tree[dict_ref[mode_name] ], #replays)
			end
			table.insert(replay_tree[1], #replays)
			replay = popFromChannel('replay')
		end
		if load then
			loaded_replays = true
			local function padnum(d) return ("%03d%s"):format(#d, d) end
			table.sort(replay_tree, function(a,b)
			return tostring(a.name):gsub("%d+",padnum) < tostring(b.name):gsub("%d+",padnum) end)
			for key, submenu in pairs(replay_tree) do
				table.sort(submenu, function(a, b)
					return replays[a]["timestamp"] > replays[b]["timestamp"]
				end)
			end
			scene = ReplaySelectScene()
		end
		return -- It's there to avoid input response when loading.
	end
	if self.das_up or self.das_down or self.das_left or self.das_right then
		self.das = self.das + 1
	else
		self.das = 0
	end
	if self.menu_state.submenu > 0 then
		if #replay_tree[self.menu_state.submenu] == 0 then
			return
		end
	end
	if self.auto_menu_offset ~= 0 then
		self:changeOption(self.auto_menu_offset < 0 and -1 or 1)
		if self.auto_menu_offset > 0 then self.auto_menu_offset = self.auto_menu_offset - 1 end
		if self.auto_menu_offset < 0 then self.auto_menu_offset = self.auto_menu_offset + 1 end
	end
	if self.das >= 15 then
		local change = 0
		if self.das_up then
			change = -1
		elseif self.das_down then
			change = 1
		elseif self.das_left then
			change = -9
		elseif self.das_right then
			change = 9
		end
		self:changeOption(change)
		self.das = self.das - 4
	end

	DiscordRPC:update({
		details = "In menus",
		state = "Choosing a replay",
		largeImageKey = "ingame-000"
	})
end

function ReplaySelectScene:render()
	drawSizeIndependentImage(
		backgrounds[0],
		0, 0, 0,
		640, 480
	)
	
	self.height_offset = interpolateListPos(self.height_offset / 20, self.menu_state.replay) * 20

	-- Same graphic as mode select
	--love.graphics.draw(misc_graphics["select_mode"], 20, 40)

	love.graphics.setFont(font_3x5_4)
	if not loaded_replays then
		love.graphics.setFont(font_3x5_3)
		love.graphics.printf(
			"Loading replays... Please wait",
			80, 200, 480, "center"
		)
		love.graphics.printf(
			"Thread's current job:\n"..nilCheck(self.state_string, "nil"),
			0, 250, 640, "center"
		)
		return
	elseif self.menu_state.submenu > 0 then
		love.graphics.print("SELECT REPLAY", 20, 35)
		love.graphics.setFont(font_3x5_3)
		love.graphics.printf("MODE: "..replay_tree[self.menu_state.submenu].name, 300, 35, 320, "right")
	else
		love.graphics.print("SELECT MODE TO REPLAY", 20, 35)
	end

	if self.display_warning then
		love.graphics.setFont(font_3x5_3)
		love.graphics.printf(
			"You have no replays.",
			80, 200, 480, "center"
		)
		love.graphics.setFont(font_3x5_2)
		love.graphics.printf(
			"Come back to this menu after playing some games. " ..
			"Press any button to return to the main menu.",
			80, 250, 480, "center"
		)
		return
	elseif self.display_error then
		love.graphics.setFont(font_3x5_3)
		love.graphics.printf(
			"You are missing this mode or ruleset.",
			80, 200, 480, "center"
		)
		love.graphics.setFont(font_3x5_2)
		love.graphics.printf(
			"Come back after getting the proper mode or ruleset. " ..
			"Press any button to return to the main menu.",
			80, 250, 480, "center"
		)
		return
	end

	if not self.chosen_replay then
		love.graphics.setColor(1, 1, 1, 0.5)
		love.graphics.rectangle("fill", 3, 258 + (self.menu_state.replay * 20) - self.height_offset, 634, 22)
	end
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.setFont(font_3x5_2)
	if self.menu_state.submenu == 0 then
		for idx, branch in ipairs(replay_tree) do
			if(idx >= self.height_offset/20-10 and idx <= self.height_offset/20+10) then
				local b = CursorHighlight(0, (260 - self.height_offset) + 20 * idx, 640, 20)
				love.graphics.setColor(1,1,b,FadeoutAtEdges((-self.height_offset) + 20 * idx, 180, 20))
				love.graphics.printf(branch.name, 6, (260 - self.height_offset) + 20 * idx, 640, "left")	
			end
		end
	elseif self.chosen_replay then
		local pointer = replay_tree[self.menu_state.submenu][self.menu_state.replay]
		local replay = replays[pointer]
		if replay then
			local idx = 0
			love.graphics.setFont(font_3x5_4)
			love.graphics.printf("Mode: " .. replay["mode"], 0, 120, 640, "center")
			love.graphics.setFont(font_3x5_3)
			love.graphics.printf(os.date("Timestamp: %c", replay["timestamp"]), 0, 160, 640, "center")
			if replay.cambridge_version then
				idx = idx + 1.5
				love.graphics.setFont(font_3x5_2)
				love.graphics.printf("Cambridge version for this replay: "..replay.cambridge_version, 0, 190, 640, "center")
				if replay.cambridge_version ~= version then
					love.graphics.setFont(font_3x5_2)
					love.graphics.setColor(1, 0, 0)
					love.graphics.printf("Warning! The versions don't match!\nStuff may break, so, start at your own risk.", 0, 90, 640, "center")
					love.graphics.setColor(1, 1, 1)
				end
			end
			if replay.sha256_table then
				if config.visualsettings.debug_level > 2 then
					idx = idx + 2
					love.graphics.setFont(font_3x5_2)
					love.graphics.printf(("SHA256 replay checksums:\n   Mode: %s\nRuleset: %s"):format(replay.sha256_table.mode, replay.sha256_table.ruleset), 0, 140 + idx * 20, 640, "center")
				end
				if replay.sha256_table.mode ~= self.replay_sha_table.mode then
					idx = idx + 1
					love.graphics.setColor(1, 0, 0)
					love.graphics.printf("SHA256 checksum for mode doesn't match!", 0, 170 + idx * 20, 640, "center")
					idx = idx + 1
					love.graphics.setFont(font_3x5)
					love.graphics.printf(("Replay: %s\nMode:   %s"):format(replay.sha256_table.mode, self.replay_sha_table.mode), 0, 170 + idx * 20, 640, "center")
					love.graphics.setColor(1, 1, 1)
				end
				if replay.sha256_table.ruleset ~= self.replay_sha_table.ruleset then
					idx = idx + 2
					love.graphics.setColor(1, 0, 0)
					love.graphics.setFont(font_3x5_2)
					love.graphics.printf("SHA256 checksum for ruleset doesn't match!", 0, 170 + idx * 20, 640, "center")
					idx = idx + 1
					love.graphics.setFont(font_3x5)
					love.graphics.printf(("Replay: %s\nRuleset:%s"):format(replay.sha256_table.ruleset, self.replay_sha_table.ruleset), 0, 170 + idx * 20, 640, "center")
					love.graphics.setColor(1, 1, 1)
				end
			end
			if replay.highscore_data then
				love.graphics.setFont(font_3x5_2)
				love.graphics.printf("In-replay highscore data:", 0, 190 + idx * 20, 640, "center")
				for key, value in pairs(replay["highscore_data"]) do
					idx = idx + 0.8
					love.graphics.printf(key..": "..value, 0, 200 + idx * 20, 640, "center")
				end
				idx = idx - 1
			else
				love.graphics.setFont(font_3x5_3)
				love.graphics.printf("Legacy replay\nLevel: "..replay["level"], 0, 190, 640, "center")
			end
			love.graphics.setFont(font_3x5_2)
			love.graphics.printf("Enter or LMB or ".. config.input.keys.menu_decide ..": Start\nDel or Backspace or RMB or "..config.input.keys.menu_back..": Return", 0, 250 + idx * 20, 640, "center")
		end
	else
		if #replay_tree[self.menu_state.submenu] == 0 then
			love.graphics.setFont(font_3x5_2)
			love.graphics.printf(
				"This submenu doesn't contain replays of this mode. ",
				80, 250, 480, "center"
			)
			return
		end
		for idx, replay_idx in ipairs(replay_tree[self.menu_state.submenu]) do
			if(idx >= self.height_offset/20-10 and idx <= self.height_offset/20+10) then
				local replay = replays[replay_idx]
				local display_string
				if replay_tree[self.menu_state.submenu].name == "All" then
					display_string = os.date("%c", replay["timestamp"]).." - ".. replay["mode"].." - "..replay["ruleset"]
				else
					display_string = os.date("%c", replay["timestamp"]).." - "..replay["ruleset"]
				end
				if replay["level"] ~= nil then
					display_string = display_string.." - Level: "..replay["level"]
				end
				if replay["timer"] ~= nil then
					display_string = display_string.." - Time: "..formatTime(replay["timer"])
				end
				if #display_string > 78 then
					display_string = display_string:sub(1, 75) .. "..."
				end
				local b, g = CursorHighlight(0, (260 - self.height_offset) + 20 * idx, 640, 20), 1
				if not replay["highscore_data"] then
					g = 0.5
					b = 0.8
				end
				if replay["toolassisted"] then
					g = 0
					b = 0
				end
				love.graphics.setColor(1,g,b,FadeoutAtEdges((-self.height_offset) + 20 * idx, 180, 20))
				love.graphics.printf(display_string, 6, (260 - self.height_offset) + 20 * idx, 640, "left")
			end
		end
	end
end
local function recursionStringValueExtract(tbl, key_check)
	local result = {}
	for key, value in pairs(tbl) do
		if type(value) == "table" and (key_check == nil or value[key_check]) then
			local recursion_result = recursionStringValueExtract(value, key_check)
			for k2, v2 in pairs(recursion_result) do
				table.insert(result, v2)
			end
		elseif tostring(value) == "Object" then
			table.insert(result, value)
		end
	end
	return result
end

function ReplaySelectScene:startReplay()
	if self.menu_state.submenu == 0 then
		self.menu_state.submenu = self.menu_state.replay
		self.menu_state.replay = 1
		self.height_offset = 0
		playSE("main_decide")
		return
	elseif self.menu_state.submenu > 0 then
		if #replay_tree[self.menu_state.submenu] == 0 then
			self.menu_state.submenu = 0
			self.menu_state.replay = 1
			return
		end
	end
	current_submenu = self.menu_state.submenu
	current_replay = self.menu_state.replay
	-- Get game mode and ruleset
	local mode
	local rules
	local pointer = replay_tree[self.menu_state.submenu][self.menu_state.replay]
	for key, value in pairs(recursionStringValueExtract(game_modes, "is_directory")) do
		if value.name == replays[pointer]["mode"] then
			mode = value
			break
		end
	end
	for key, value in pairs(recursionStringValueExtract(rulesets, "is_directory")) do
		if value.name == replays[pointer]["ruleset"] then
			rules = value
			break
		end
	end
	if mode == nil or rules == nil then
		self.display_error = true
		return
	end

	if replays[pointer]["highscore_data"] and not self.chosen_replay then
		self.chosen_replay = true
		self.replay_sha_table = {mode = sha2.sha256(binser.serialize(mode)), ruleset = sha2.sha256(binser.serialize(rules))}
		playSE("main_decide")
		self.das_down = nil
		self.das_up = nil
		self.das_left = nil
		self.das_right = nil
		return
	end

	-- Same as mode decide
	playSE("mode_decide")

	-- TODO compare replay versions to current versions for Cambridge, ruleset, and mode
	scene = ReplayScene(
		deepcopy(replays[pointer]), --This has to be done to avoid serious glitches with it.
		mode,
		rules
	)
end


function ReplaySelectScene:onInputPress(e)
	if (self.display_warning or self.display_error) and e.input then
		scene = TitleScene()
	elseif e.type == "mouse" and loaded_replays then
		if e.button == 1 then
			if self.display_error or self.display_warning then
				scene = TitleScene()
				return
			end
			self.auto_menu_offset = math.floor((e.y - 260)/20)
			if self.auto_menu_offset == 0 or self.chosen_replay then
				self:startReplay()
			end
		end
		if e.button == 2 and self.chosen_replay then
			self.chosen_replay = false
		end
	elseif not loaded_replays then
		--does nothing.
	elseif e.type == "wheel" then
		if e.y ~= 0 then
			self:changeOption(-e.y)
		end
	elseif e.input == "menu_decide" or e.scancode == "return" then
		self:startReplay()
	elseif self.chosen_replay then
		if e.input == "menu_back" or e.scancode == "delete" or e.scancode == "backspace" then
			self.chosen_replay = false
		end
	elseif e.input == "up" or e.scancode == "up" then
		self:changeOption(-1)
		self.das_up = true
		self.das_down = nil
		self.das_left = nil
		self.das_right = nil
	elseif e.input == "down" or e.scancode == "down" then
		self:changeOption(1)
		self.das_down = true
		self.das_up = nil
		self.das_left = nil
		self.das_right = nil
	elseif e.input == "left" or e.scancode == "left" then
		self:changeOption(-9)
		self.das_left = true
		self.das_right = nil
		self.das_up = nil
		self.das_down = nil
	elseif e.input == "right" or e.scancode == "right" then
		self:changeOption(9)
		self.das_right = true
		self.das_left = nil
		self.das_up = nil
		self.das_down = nil
	elseif e.input == "menu_back" or e.scancode == "delete" or e.scancode == "backspace" then
		if self.menu_state.submenu ~= 0 then
			self.menu_state.submenu = 0
			self.menu_state.replay = 1
			return
		end
		scene = TitleScene()
	end
end

function ReplaySelectScene:onInputRelease(e)
	if e.input == "up" or e.scancode == "up" then
		self.das_up = nil
	elseif e.input == "down" or e.scancode == "down" then
		self.das_down = nil
	elseif e.input == "right" or e.scancode == "right" then
		self.das_right = nil
	elseif e.input == "left" or e.scancode == "left" then
		self.das_left = nil
	end
end

function ReplaySelectScene:changeOption(rel)
	local len
	if self.menu_state.submenu > 0 then
		if #replay_tree[self.menu_state.submenu] == 0 then
			return
		end
	end
	if self.menu_state.submenu == 0 then
		len = #replay_tree
	else
		len = #replay_tree[self.menu_state.submenu]
	end
	self.menu_state.replay = Mod1(self.menu_state.replay + rel, len)
	playSE("cursor")
end

return ReplaySelectScene

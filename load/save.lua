local binser = require 'libs.binser'

function loadSave()
	config = loadFromFile('config.sav')
	highscores = loadFromFile('highscores.sav')
end

function loadFromFile(filename)
	local file_data = love.filesystem.read(filename)
	if file_data == nil then
		--Gets backup just in case.
		file_data = love.filesystem.read(filename..".backup")
		-- if no backup
		if file_data == nil then
			return {} -- new object
		end
	else
		love.filesystem.write(filename..".backup", file_data) -- backup creation if sucessful
	end
	local save_data = binser.deserialize(file_data)
	if save_data == nil then
		return {} -- new object
	end
	return save_data[1]
end

local function updateInputConfig()
	if config.input.keys ~= nil then
		if config.input.keys.menu_decide == nil then
			local new_key_inputs = {}
			for key, value in pairs(config.input.keys) do
				new_key_inputs[value] = key
			end
			config.input.keys = new_key_inputs
		end
	end
	config.input.keys.mode_exit = config.input.keys.menu_back or "escape"
	if config.input.joysticks ~= nil then
		if config.input.joysticks.menu_decide ~= nil then
			local input_table = {}
			for key, binding in pairs(config.input.joysticks) do
				local joy_name = binding:sub(1, binding:find("-") - 1)
				local substring = binding:sub(binding:find("-") + 1, #binding)
				input_table[joy_name] = input_table[joy_name] or {}
				input_table[joy_name][key] = substring
			end
			config.input.joysticks = input_table
		else
			for name, joystick in pairs(config.input.joysticks) do
				local input_table = {}
				for k2, v2 in pairs(joystick.buttons) do
					local input_str = "buttons-"..k2
					input_table[v2] = input_str
				end
				for k2, v2 in pairs(joystick.axes) do
					for k3, v3 in pairs(v2) do
						local input_str = "axes-"..k2.."-"..k3
						input_table[v3] = input_str
					end
				end
				for k2, v2 in pairs(joystick.hats) do
					for k3, v3 in pairs(v2) do
						local input_str = "hat-"..k2.."-"..k3
						input_table[v3] = input_str
					end
				end
				config.input.joysticks[name] = input_table
			end
		end
	end
end

function initConfig()
	if not config.das then config.das = 10 end
	if not config.arr then config.arr = 2 end
	if not config.dcd then config.dcd = 0 end
	if not config.sfx_volume then config.sfx_volume = 0.5 end
	if not config.bgm_volume then config.bgm_volume = 0.5 end
	
	if config.fullscreen == nil then config.fullscreen = false end
	if config.secret == nil then config.secret = false end

	if not config.gamesettings then config.gamesettings = {} end
	for _, option in ipairs(GameConfigScene.options) do
		if not config.gamesettings[option[1]] then
			config.gamesettings[option[1]] = 1
		end
	end
	if not config.visualsettings then config.visualsettings = {} end
	for _, option in ipairs(VisualConfigScene.options) do
		if not config.visualsettings[option[1]] then
			config.visualsettings[option[1]] = 1
		end
	end
	if not config.audiosettings then config.audiosettings = {} end
	for _, option in ipairs(AudioConfigScene.options) do
		if not config.audiosettings[option[1]] then
			if option[3] ~= "options" then
				config.audiosettings[option[1]] = (option[6] - option[5]) / 2 + option[5]
			else
				config.audiosettings[option[1]] = 1
			end
			if option[10] and option[10] == "floor" then
				config.audiosettings[option[1]] = math.floor(config.audiosettings[option[1]])
			end
		end
	end

	config.sound_sources = config.audiosettings.sound_sources

	if not config.input then
		scene = TutorialKeybinder()
	else
		if config.input.keys then
			if config.input.joysticks == nil then
				config.input.joysticks = {}
			end
			if config.input.keys.menu_decide == nil or config.input.joysticks.menu_decide ~= nil then
				updateInputConfig()
			end
			--if it still fails
			if config.input.keys.menu_decide == nil then
				config.input.keys = nil
				scene = InputConfigScene()
			end
		end
		if config.current_mode then current_mode = config.current_mode end
		if config.current_ruleset then current_ruleset = config.current_ruleset end
		scene = TitleScene()
	end
end

function saveToFile(filename, data)
	local is_successful, message = love.filesystem.write(filename..".tmp", data) --temporary file.
	if not is_successful then
		error("Failed to save file: "..filename..". Error message: "..message)
	end
	love.filesystem.remove(filename..".tmp") --cleanup.
	love.filesystem.write(filename, data)
end

function saveConfig()
	saveToFile("config.sav", binser.serialize(config))
end

function saveHighscores()
	saveToFile(
		'highscores.sav', binser.serialize(highscores)
	)
end

local KeyConfigScene = Scene:extend()

KeyConfigScene.title = "Key Config"

require 'load.save'

local configurable_inputs = {
	"menu_decide",
	"menu_back",
	"left",
	"right",
	"up",
	"down",
	"rotate_left",
	"rotate_left2",
	"rotate_right",
	"rotate_right2",
	"rotate_180",
	"hold",
	"retry",
	"pause",
	"mode_exit",
	"frame_step",
	"generic_1",
	"generic_2",
	"generic_3",
	"generic_4",
}

local input_naming = {
	menu_decide = "Menu Decision",
	menu_back = "Menu Back",
	left = "Move Left",
	right = "Move Right",
	up = "Hard/Sonic Drop",
	down = "Soft/Sonic Drop",
	rotate_left = "Rotate CCW 1",
	rotate_left2 = "Rotate CCW 2",
	rotate_right = "Rotate CW 1",
	rotate_right2 = "Rotate CW 2",
	rotate_180 = "Rotate 180",
	hold = "Hold",
	retry = "Retry",
	pause = "Pause",
	mode_exit = "Exit Mode",
	frame_step = "Frame Step",
	generic_1 = "Generic 1",
	generic_2 = "Generic 2",
	generic_3 = "Generic 3",
	generic_4 = "Generic 4",
}

--A list of inputs that shouldn't have the same keybinds with the other.
local mutually_exclusive_inputs = {
	menu_decide = "menu_back",
	left = {"right", "up", "down"},
	right = {"left", "up", "down"},
	up = {"down", "left", "right"},
	down = {"left", "up", "right"},
}

function KeyConfigScene:mutexCheck(input, keybind)
	for key, value in pairs(mutually_exclusive_inputs) do
		if key == input then
			if type(value) == "table" then
				for k2, v2 in pairs(value) do
					if self.new_input[v2] == keybind then
						return true
					end
				end
			end
			if self.new_input[value] == keybind then
				return true
			end
		elseif value == input then
			if self.new_input[key] == keybind then
				return true
			end
		end
	end
	return false
end

local function newSetInputs()
	local set_inputs = {}
	for i, input in ipairs(configurable_inputs) do
		set_inputs[input] = false
	end
	return set_inputs
end

function KeyConfigScene:new()
	self.input_state = 1
	self.set_inputs = newSetInputs()
	self.new_input = {}

	if not config.input then config.input = {} end
	if config.input.keys then
		self.reconfiguration = true
		self.new_input = config.input.keys
		for input_name, key in pairs(config.input.keys) do
			self.set_inputs[input_name] = self:formatKey(key)
		end
	end

	self.safety_frames = 0

	DiscordRPC:update({
		details = "In settings",
		state = "Changing key config",
	})
end

function KeyConfigScene:update()
	self.safety_frames = self.safety_frames - 1
end

function KeyConfigScene:render()
	love.graphics.setColor(1, 1, 1, 1)
	drawBackground("options_input")

	love.graphics.setFont(font_3x5_2)
	for i, input in ipairs(configurable_inputs) do
		if i == self.input_state then
			love.graphics.setColor(1, 1, 0, 1)
		end
		love.graphics.printf(input_naming[input], 40, 50 + i * 18, 200, "left")
		love.graphics.setColor(1, 1, 1, 1)
		if self.set_inputs[input] then
			love.graphics.printf(self.set_inputs[input], 240, 50 + i * 18, 300, "left")
		end
	end
	local string_press_key = "Press key input for " .. input_naming[configurable_inputs[self.input_state]]
	if self.input_state > #configurable_inputs then
		love.graphics.print("Press enter to confirm, delete/backspace to retry" .. (config.input and ", escape to cancel" or ""))
		return
	elseif self.reconfiguration then
		if self.key_rebinding then
			love.graphics.printf(string_press_key .. ", tab to erase.", 0, 0, 640, "left")
		end
		love.graphics.printf("Press escape to exit while not rebinding. Auto-saves after you rebound a key.", 0, 20, 640, "left")
	else
		love.graphics.printf(string_press_key .. ", tab to skip.", 0, 0, 640, "left")
	end
	love.graphics.printf("Function keys (F1, F2, etc.), and tab can't be changed", 0, 40, 640, "left")
end

function KeyConfigScene:formatKey(key)
	if love.keyboard.getKeyFromScancode(key) == key then
		return "key ".. key
	else
		return "scancode " .. love.keyboard.getKeyFromScancode(key) .. ", key (" .. key .. ")"
	end
end

function KeyConfigScene:rebindKey(key)
	if key == nil then
		self.new_input[configurable_inputs[self.input_state]] = nil
		self.set_inputs[configurable_inputs[self.input_state]] = "erased"
		return true
	end
	if self:mutexCheck(configurable_inputs[self.input_state], key) then
		self.set_inputs[configurable_inputs[self.input_state]] = "<press an other key>"
		return false
	end
	self.set_inputs[configurable_inputs[self.input_state]] = self:formatKey(key)
	self.new_input[configurable_inputs[self.input_state]] = key
	return true
end

function KeyConfigScene:refreshInputStates()
	for input_name, key in pairs(self.new_input) do
		self.set_inputs[input_name] = self:formatKey(key)
	end
end

function KeyConfigScene:onInputPress(e)
	if self.safety_frames > 0 then
		return
	end
	self.safety_frames = 2
	if e.type == "key" then
		-- function keys, and tab are reserved and can't be remapped
		if self.reconfiguration then
			if self.key_rebinding then
				if e.scancode == "tab" then
					self:rebindKey(nil) --this is done by purpose
					self.key_rebinding = false
				else
					if self:rebindKey(e.scancode) then
						playSE("mode_decide")
						self.key_rebinding = false
					else
						playSE("erase", "single")
					end
				end
                config.input.keys = self.new_input
				saveConfig()
			else
				if e.scancode == "escape" then
					playSE("menu_cancel")
					scene = InputConfigScene()
				end
				if e.scancode == "up" then
					playSE("cursor")
					self.input_state = Mod1(self.input_state - 1, #configurable_inputs)
				elseif e.scancode == "down" then
					playSE("cursor")
					self.input_state = Mod1(self.input_state + 1, #configurable_inputs)
				elseif e.scancode == "return" then
					playSE("main_decide")
					self.set_inputs[configurable_inputs[self.input_state]] = "<press a key>"
					self.key_rebinding = true
				end
			end
		elseif self.input_state > #configurable_inputs then
			if e.scancode == "return" then
				-- save new input, then load next scene
				local had_config = config.input ~= nil
                if not config.input then config.input = {} end
                config.input.keys = self.new_input
				saveConfig()
				scene = had_config and InputConfigScene() or TitleScene()
			elseif e.scancode == "delete" or e.scancode == "backspace" then
				-- retry
				self.input_state = 1
				self.set_inputs = newSetInputs()
				self.new_input = {}
			end
		elseif e.scancode == "tab" then
			self.set_inputs[configurable_inputs[self.input_state]] = "skipped"
			self.input_state = self.input_state + 1
		-- all other keys can be configured
		elseif self:rebindKey(e.scancode) then
			self.input_state = self.input_state + 1
		else
			playSE("erase", "single")
		end
	end
end

return KeyConfigScene

local ConfigScene = Scene:extend()

ConfigScene.title = "Audio Settings"

require 'load.save'

ConfigScene.options = {
	-- this serves as reference to what the options' values mean i guess?
	-- Option types: slider, options
	-- Format if type is options:	{name in config, displayed name, type, description, options}
	-- Format if otherwise:			{name in config, displayed name, type, description, min, max, increase by, string format, sound effect name, rounding type}
	{"sfx_volume", "SFX Volume", "slider", nil, 0, 100, 5, "%02d%%", "cursor"},
	{"bgm_volume", "BGM Volume", "slider", nil, 0, 100, 5, "%02d%%", "cursor"},
	{"sound_sources", "Simult. SFX sources", "slider", "High values may result in high memory consumption, "..
	"though it allows multiples of the same sound effect to be played at once."..
	"\n(There's some exceptions, e.g. SFX added through modes/rulesets)", 1, 30, 1, "%0d", "cursor", "floor"}
}
local optioncount = #ConfigScene.options

function ConfigScene:new()
	-- load current config
	self.config = config.input
	self.highlight = 1
	self.option_pos_y = {}
	config.audiosettings.sfx_volume = config.sfx_volume * 100
	config.audiosettings.bgm_volume = config.bgm_volume * 100
	self.sliders = {
		sfx_volume = newSlider(320, 155, 480, config.sfx_volume*100, 0, 100, function(v) config.sfx_volume = v/100 config.audiosettings.sfx_volume = v end, {width=20, knob="circle", track="roundrect"}),
		bgm_volume = newSlider(320, 210, 480, config.bgm_volume*100, 0, 100, function(v) config.bgm_volume = v/100 config.audiosettings.bgm_volume = v end, {width=20, knob="circle", track="roundrect"}),
	}
	
	--#region Init option positions and sliders

	local y = 100
	for idx, option in ipairs(ConfigScene.options) do
		y = y + 20
		table.insert(self.option_pos_y, y)
		if option[3] == "slider" then
			y = y + 35
			if config.audiosettings[option[1]] == nil then
				config.audiosettings[option[1]] = (option[6] - option[5]) / 2 + option[5]
			end
			self.sliders[option[1]] = self.sliders[option[1]] or newSlider(320, y, 480, config.audiosettings[option[1]], option[5], option[6], function(v) config.audiosettings[option[1]] = math.floor(v) end, {width=20, knob="circle", track="roundrect"})
		end
	end
	--#endregion

	DiscordRPC:update({
		details = "In settings",
		state = "Changing audio settings",
	})
end

function ConfigScene:update()
	--#region Mouse
	local x, y = getScaledPos(love.mouse.getPosition())
	for i, slider in pairs(self.sliders) do
		slider:update(x, y)
	end
end

function ConfigScene:render()
	love.graphics.setColor(1, 1, 1, 1)
	drawBackground("options_game")

	love.graphics.setFont(font_3x5_4)
	love.graphics.print("AUDIO SETTINGS", 80, 40)
	local b = CursorHighlight(20, 40, 50, 30)
	love.graphics.setColor(1, 1, b, 1)
	love.graphics.printf("<-", 20, 40, 50, "center")
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.setFont(font_3x5_2)
	love.graphics.print("(THIS WILL NOT BE STORED IN REPLAYS)", 80, 80)

	love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.rectangle("fill", 25, self.option_pos_y[self.highlight] - 2, 190, 22)

	love.graphics.setFont(font_3x5_2)
	for i, option in ipairs(ConfigScene.options) do
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(option[2], 40, self.option_pos_y[i], 170, "left")
		if option[3] == "slider" then
			self:renderSlider(i, option)
		elseif option[3] == "options" then
			self:renderOptions(i, option)
		end
	end
	if self.options[self.highlight][4] then
		love.graphics.printf("Description: " .. self.options[self.highlight][4], 20, 400, 600, "left")
	end

	love.graphics.setColor(1, 1, 1, 0.75)
end

function ConfigScene:renderSlider(idx, option)
	self.sliders[option[1]]:draw()
	love.graphics.printf(string.format(option[8],self.sliders[option[1]]:getValue()), 160, self.option_pos_y[idx], 320, "center")
end

function ConfigScene:renderOptions(idx, option)
	for j, setting in ipairs(option[5]) do
		local b = CursorHighlight(100 + 110 * j, self.option_pos_y[idx], 100, 20)
		love.graphics.setColor(1, 1, b, config.audiosettings[option[1]] == j and 1 or 0.5)
		love.graphics.printf(setting, 100 + 110 * j, self.option_pos_y[idx], 100, "center")
	end
end

function ConfigScene:changeValue(by)
	local option = self.options[self.highlight]
	if option[3] == "slider" then
		local sld = self.sliders[option[1]]
		sld.value = math.max(0, math.min(sld.max, (sld:getValue() + by - sld.min))) / (sld.max - sld.min)
		local x, y = getScaledPos(love.mouse.getPosition())
		sld:update(x, y)
	end
	if option[3] == "options" then
        config.audiosettings[option[1]] = Mod1(config.audiosettings[option[1]]+by, #option[3])
	end
end

function ConfigScene:onInputPress(e)
	local option = self.options[self.highlight]
	if e.input == "menu_decide" or e.scancode == "return" or (e.type == "mouse" and e.button == 1 and e.x > 20 and e.y > 40 and e.x < 70 and e.y < 70) then
		if config.sound_sources ~= config.audiosettings.sound_sources then
			config.sound_sources = config.audiosettings.sound_sources
			--why is this necessary???
			generateSoundTable()
		end
		config.sfx_volume = config.audiosettings.sfx_volume / 100
		config.bgm_volume = config.audiosettings.bgm_volume / 100
		playSE("mode_decide")
		saveConfig()
		scene = SettingsScene()
	elseif e.input == "up" or e.scancode == "up" then
		playSE("cursor")
		self.highlight = Mod1(self.highlight-1, optioncount)
	elseif e.input == "down" or e.scancode == "down" then
		playSE("cursor")
		self.highlight = Mod1(self.highlight+1, optioncount)
	elseif e.input == "left" or e.scancode == "left" then
        self:changeValue(-option[7])
        playSE(option[9] or "cursor_lr")
	elseif e.input == "right" or e.scancode == "right" then
		self:changeValue(option[7])
        playSE(option[9] or "cursor_lr")
	elseif e.input == "menu_back" or e.scancode == "delete" or e.scancode == "backspace" then
		playSE("menu_cancel")
		loadSave()
		scene = SettingsScene()
	end
end

return ConfigScene

local ConfigScene = AbstractConfigScene:extend()

ConfigScene.title = "Audio Settings"
ConfigScene.config_type = "audiosettings"

require 'load.save'

---@type settings_config_option[]
ConfigScene.options = {
	-- this serves as reference to what the options' values mean i guess?
	-- Option types: slider, options
	-- Format if type is options:	{name in config, displayed name, type, description, options}
	-- Format if otherwise:			{name in config, displayed name, type, description, min, max, increase by, string format, sound effect name, rounding type}
	{
		config_name = "master_volume",
		display_name = "Master Volume",
		type = "slider",
		description = "This will affect all sound sources. ALL OF IT.",
		default = 100,
		min = 0,
		max = 100,
		increase_by = 5,
		format = "%d%%",
		sound_effect_name = "cursor",
		setter = function(v)
			love.audio.setVolume(v/100)
			config.master_volume = v/100
			config.audiosettings.master_volume = v
		end,
	},
	{
		config_name = "sfx_volume",
		display_name = "SFX Volume",
		type = "slider",
		default = 50,
		min = 0,
		max = 100,
		increase_by = 5,
		format = "%d%%",
		sound_effect_name = "cursor",
		setter = function(v)
			config.sfx_volume = v/100
			config.audiosettings.sfx_volume = v
		end,
	},
	{
		config_name = "bgm_volume",
		display_name = "BGM Volume",
		type = "slider",
		default = 50,
		min = 0,
		max = 100,
		increase_by = 5,
		format = "%d%%",
		sound_effect_name = "cursor",
		setter = function(v)
			config.bgm_volume = v/100
			config.audiosettings.bgm_volume = v
		end,
	},
	{
		config_name = "sound_sources",
		display_name = "Simult. SFX sources",
		type = "slider",
		description = "High values may result in high memory consumption, though it allows multiples of the same sound effect to be played at once." ..
		"\n(There's some exceptions, e.g. SFX added through modes/rulesets)",
		default = 10,
		min = 1,
		max = 30,
		increase_by = 1,
		format = "%0d",
		sound_effect_name = "cursor",
		setter = function(v)
			config.audiosettings.sound_sources = math.floor(v)
		end,
	}
}
local optioncount = #ConfigScene.options

function ConfigScene:new()
	self.spacing = 25
	ConfigScene.super.new(self)
	self.options_width = 170
	DiscordRPC:update({
		details = "In settings",
		state = "Changing audio settings",
	})
end

function ConfigScene:render()
	love.graphics.setColor(1, 1, 1, 1)
	drawBackground("options_game")

	love.graphics.setFont(font_8x11)
	love.graphics.print("AUDIO SETTINGS", 80, 43)
	local b = cursorHighlight(20, 40, 50, 30)
	love.graphics.setColor(1, 1, b, 1)
	love.graphics.printf("<-", font_3x5_4, 20, 40, 50, "center")
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.setFont(font_3x5_2)
	love.graphics.print("(THIS WILL NOT BE STORED IN REPLAYS)", 80, 80)

	self:renderSettings()
end

function ConfigScene:renderOptions(idx, option)
	for j, setting in ipairs(option.options) do
		local b = cursorHighlight(100 + 110 * j, self.option_pos_y[idx], 100, 20)
		love.graphics.setColor(1, 1, b, config.audiosettings[option.config_name] == j and 1 or 0.5)
		love.graphics.printf(setting, 100 + 110 * j, self.option_pos_y[idx], 100, "center")
	end
end

function ConfigScene:changeValue(by)
	local option = self.options[self.highlight]
	if option.type == "slider" then
		local sld = self.sliders[option.config_name]
		sld.value = math.max(0, math.min(sld.max, (sld:getValue() + by - sld.min))) / (sld.max - sld.min)
		local x, y = getScaledDimensions(love.mouse.getPosition())
		sld:update(x, y)
	end
	if option.type == "options" then
		config.audiosettings[option.config_name] = Mod1(config.audiosettings[option.config_name]+by, #option.type)
	end
end

function ConfigScene:onInputPress(e)
	local option = self.options[self.highlight]
	if e.input == "menu_decide" or (e.type == "mouse" and e.button == 1 and e.x > 20 and e.y > 40 and e.x < 70 and e.y < 70) then
		if config.sound_sources ~= config.audiosettings.sound_sources then
			config.sound_sources = config.audiosettings.sound_sources
			--why is this necessary???
			generateSoundTable()
		end
		playSE("mode_decide")
		saveConfig()
		scene = SettingsScene()
	elseif e.input == "menu_up" then
		self:changeHighlight(-1)
		self.das_up = true
	elseif e.input == "menu_down" then
		self:changeHighlight(1)
		self.das_down = true
	elseif e.input == "menu_left" then
		self:changeValue(-option.increase_by)
		playSE(option.sound_effect_name or "cursor_lr")
	elseif e.input == "menu_right" then
		self:changeValue(option.increase_by)
		playSE(option.sound_effect_name or "cursor_lr")
	elseif e.input == "menu_back" then
		playSE("menu_cancel")
		loadSave()
		love.audio.setVolume(config.master_volume)
		scene = SettingsScene()
	end
end

function ConfigScene:onInputRelease(e)
	if e.input == "menu_up" then
		self.das_up = false
	elseif e.input == "menu_down" then
		self.das_down = false
	end
end

return ConfigScene

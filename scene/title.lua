local TitleScene = Scene:extend()

TitleScene.title = "Title"
TitleScene.restart_message = false

local enter_pressed = false
local menu_frames = 0

local main_menu_screens = {
	ModeSelectScene,
	HighscoresScene,
	ReplaySelectScene,
	SettingsScene,
	CreditsScene,
	ExitScene,
}

local mainmenuidle = {
	"Idle",
	"On title screen",
	"On main menu screen",
	"Twiddling their thumbs",
	"Admiring the main menu's BG",
	"Waiting for spring to come",
	"Actually not playing",
	"Contemplating collecting stars",
	"Preparing to put the block!!",
	"Having a nap",
	"In menus",
	"Bottom text",
	"Trying to see all the funny rpc messages (maybe)",
	"Not not not playing",
	"AFK",
	"Preparing for their next game",
	"Who are those people on that boat?",
	"Welcome to Cambridge!",
	"who even reads these",
	"Made with love in LOVE!",
	"This is probably the longest RPC string out of every possible RPC string that can be displayed."
}

function TitleScene:new()
	self.main_menu_state = 1
	self.frames = 0
	self.snow_bg_opacity = 0
	self.y_offset = 0
	self.text = ""
	self.text_flag = false
	if config.visualsettings.mode_select_type == 1 then
		main_menu_screens[1] = ModeSelectScene
	else
		main_menu_screens[1] = RevModeSelectScene
	end
	DiscordRPC:update({
		details = "In menus",
		state = mainmenuidle[love.math.random(#mainmenuidle)],
		largeImageKey = "icon2",
		largeImageText = version
	})
end

function TitleScene:update()
	if self.text_flag then
		self.frames = self.frames + 1
		self.snow_bg_opacity = self.snow_bg_opacity + 0.01
	end
	if enter_pressed then
		menu_frames = menu_frames + 1
	end
	if self.frames < 125 then self.y_offset = self.frames
	elseif self.frames < 185 then self.y_offset = 125
	else self.y_offset = 310 - self.frames end
	local mouse_x, mouse_y = getScaledPos(love.mouse.getPosition())
	if not love.mouse.isDown(1) or left_clicked_before or menu_frames < 10 * #main_menu_screens then return end
	if mouse_x > 40 and mouse_x < 160 then
		if mouse_y > 300 and mouse_y < 300 + #main_menu_screens * 20 then
			self.main_menu_state = math.floor((mouse_y - 280) / 20)
			playSE("main_decide")
			scene = main_menu_screens[self.main_menu_state]()
		end
	end
end

local block_offsets = {
	{color = "M", x = 0, y = 0},
	{color = "G", x = 32, y = 0},
	{color = "Y", x = 64, y = 0},
	{color = "B", x = 0, y = 32},
	{color = "O", x = 0, y = 64},
	{color = "C", x = 32, y = 64},
	{color = "R", x = 64, y = 64}
}

function TitleScene:render()
	love.graphics.setFont(font_3x5_4)
	love.graphics.setColor(1, 1, 1, 1 - self.snow_bg_opacity)
	love.graphics.draw(
		backgrounds["title_no_icon"], -- title, title_night
		0, 0, 0,
		0.5, 0.5
	)

	if not enter_pressed then
		love.graphics.setFont(font_3x5_3)
		love.graphics.printf("Welcome To Cambridge: Flooding Edge!\n\n\n\n\nPress Enter or "..config.input.keys.menu_decide, 80, 240, 480, "center")
		love.graphics.setFont(font_3x5_2)
		love.graphics.printf("This particular fork has a lot of changes, so expect that there'd be a lot of bugs!\nReport bugs found here to Tetro48, in detail.", 120, 280, 400, "center")
	end
	local x, y
	if enter_pressed then
		x, y = 490, 192
	else
		x, y = 256, 140
	end
	for _, b in ipairs(block_offsets) do
		love.graphics.draw(
			blocks["2tie"][b.color],
			x + b.x, y + b.y, 0,
			2, 2
		)
	end

	--[[
	love.graphics.draw(
		misc_graphics["icon"],
		490, 192, 0,
		2, 2
	)
	]]
	--love.graphics.printf("Thanks for 1 year!", 430, 280, 160, "center")

	love.graphics.setFont(font_3x5_2)
	love.graphics.setColor(1, 1, 1, self.snow_bg_opacity)
	love.graphics.draw(
		backgrounds["snow"],
		0, 0, 0,
		0.5, 0.5
	)

	love.graphics.draw(
		misc_graphics["santa"],
		400, -205 + self.y_offset,
		0, 0.5, 0.5
	)
	love.graphics.print("Happy Holidays!", 320, -100 + self.y_offset)

	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.print(self.restart_message and "Restart Cambridge..." or "", 0, 0)

	if not enter_pressed then
		return
	end

	love.graphics.setColor(1, 1, 1, 0.5)
	love.graphics.rectangle("fill", math.min(20, -120 * self.main_menu_state + (menu_frames * 24) - 20), 278 + 20 * self.main_menu_state, 160, 22)

	love.graphics.setColor(1, 1, 1, 1)
	for i, screen in pairs(main_menu_screens) do
		local b = CursorHighlight(40,280 + 20 * i,120,20)
		love.graphics.setColor(1,1,b,1)
		love.graphics.printf(screen.title, math.min(40, -120 * i + (menu_frames * 24)), 280 + 20 * i, 120, "left")
	end
end

function TitleScene:changeOption(rel)
	local len = table.getn(main_menu_screens)
	self.main_menu_state = (self.main_menu_state + len + rel - 1) % len + 1
end

function TitleScene:onInputPress(e)
	if not enter_pressed then
		if e.scancode == "return" or e.scancode == "kpenter" or e.input == "menu_decide" then
			enter_pressed = true
			playSE("main_decide")
		end
		return
	end
	if e.input == "menu_decide" or e.scancode == "return" then
		playSE("main_decide")
		scene = main_menu_screens[self.main_menu_state]()
	elseif e.input == "up" or e.scancode == "up" then
		self:changeOption(-1)
		playSE("cursor")
	elseif e.input == "down" or e.scancode == "down" then
		self:changeOption(1)
		playSE("cursor")
	elseif e.input == "menu_back" or e.scancode == "backspace" or e.scancode == "delete" then
		love.event.quit()
	else
		self.text = self.text .. (e.scancode or "")
		if self.text == "ffffff" then
			self.text_flag = true
			DiscordRPC:update({
				largeImageKey = "snow"
			})
		end
	end
end

return TitleScene

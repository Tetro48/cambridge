local TitleScene = Scene:extend()

TitleScene.title = "Title"
TitleScene.restart_message = false

local menu_frames = 0

TitleScene.main_menu_screens = {
	ModeSelectScene,
	HighscoresScene,
	CreditsScene,
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
	self.love2d_major, self.love2d_minor, self.love2d_revision = love.getVersion()
	self.main_menu_state = 1
	self.snow_frames = 0
	self.snow_bg_opacity = 0
	self.y_offset = 0
	self.forced_by_timeout = false
	self.enter_pressed = not (config and config.input)
	self.press_enter_text = "INSERT CREDIT(s)"
	if game_credits > 0 then
		self.press_enter_text = "PUSH START BUTTON"
	end
	self.joystick_names = {}
	self.joystick_menu_decide_binds = {}
	self.text = ""
	self.text_flag = false
	if config.visualsettings.mode_select_type == 1 then
		TitleScene.main_menu_screens[1] = ModeSelectScene
	else
		TitleScene.main_menu_screens[1] = RevModeSelectScene
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
		self.snow_frames = self.snow_frames + 1
		self.snow_bg_opacity = self.snow_bg_opacity + 0.01
	end
	if self.enter_pressed and not self.forced_by_timeout then
		menu_frames = menu_frames + 1
		if menu_frames > 30 * 60 then
			self.forced_by_timeout = true
		end
	elseif self.enter_pressed then
		menu_frames = math.min(menu_frames - 1, #TitleScene.main_menu_screens * 24 + 30)
		if menu_frames <= 0 then
			scene = TitleScene.main_menu_screens[1]()
		end
	end
	if self.snow_frames < 125 then self.y_offset = self.snow_frames
	elseif self.snow_frames < 185 then self.y_offset = 125
	else self.y_offset = 310 - self.snow_frames end
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
	drawBackground("title_no_icon") -- title, title_night

	if not self.enter_pressed then
		love.graphics.setFont(font_3x5_3)
		love.graphics.printf("Welcome To Cambridge: The Open-Source Arcade Stacker!", 0, 240, 640, "center")
		if love.timer.getTime() % 2 <= 1.5 then
			love.graphics.printf(self.press_enter_text, 80, 360, 480, "center")
		end
		love.graphics.setFont(font_3x5_2)
		-- love.graphics.printf("This new version has a lot of changes, so expect that there'd be a lot of bugs!\nReport bugs and issues found here to cambridge-stacker repository, in detail.", 0, 280, 640, "center")
	end
	local x, y
	if self.enter_pressed then
		x, y = 490, 192
	else
		x, y = 272, 140
	end
	for _, b in ipairs(block_offsets) do
		drawSizeIndependentImage(
			blocks["2tie"][b.color],
			x + b.x, y + b.y, 0,
			32, 32
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
	drawBackground("snow")

	love.graphics.draw(
		misc_graphics["santa"],
		400, -205 + self.y_offset,
		0, 0.5, 0.5
	)
	love.graphics.print("Happy Holidays!", 320, -100 + self.y_offset)

	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.print(self.restart_message and "Restart Cambridge..." or "", 0, 0)

	if not self.enter_pressed then
		return
	end

	love.graphics.setColor(1, 1, 1, 0.5)
	love.graphics.rectangle("fill", math.min(20, -120 * self.main_menu_state + (menu_frames * 24) - 20), 278 + 20 * self.main_menu_state, 160, 22)

	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.printf(self.forced_by_timeout and "0" or
	                     tostring(math.max(0, 30 - math.floor(menu_frames / 60))), font_8x11, 40, 240, 120, "left")
	for i, screen in pairs(TitleScene.main_menu_screens) do
		local b = cursorHighlight(40,280 + 20 * i,120,20)
		love.graphics.setColor(1,1,b,1)
		love.graphics.printf(screen.title, math.min(40, -120 * i + (menu_frames * 24)), 280 + 20 * i, 120, "left")
	end
end

function TitleScene:changeOption(rel)
	local len = #TitleScene.main_menu_screens
	self.main_menu_state = (self.main_menu_state + len + rel - 1) % len + 1
end

function TitleScene:onInputPress(e)
	if not self.enter_pressed then
		if (e.scancode == "return" or e.scancode == "kpenter" or e.input == "menu_decide") and game_credits > 0 then
			scene = TitleScene.main_menu_screens[1]()
			playSE("main_decide")
		elseif e.input == "hold" and game_credits > 0 then
			scene = TitleScene.main_menu_screens[2]()
		elseif e.input == "rotate_180" and game_credits > 0 then
			scene = TitleScene.main_menu_screens[3]()
		end
		return
	end
	if e.type == "mouse" and menu_frames > 10 * #TitleScene.main_menu_screens then
		if e.x > 40 and e.x < 160 then
			if e.y > 300 and e.y < 300 + #TitleScene.main_menu_screens * 20 then
				self.main_menu_state = math.floor((e.y - 280) / 20)
				playSE("main_decide")
				scene = TitleScene.main_menu_screens[self.main_menu_state]()
			end
		end
	end
	if e.input == "menu_decide" then
		playSE("main_decide")
		scene = TitleScene.main_menu_screens[self.main_menu_state]()
	elseif e.input == "menu_up" then
		self:changeOption(-1)
		playSE("cursor")
	elseif e.input == "menu_down" then
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

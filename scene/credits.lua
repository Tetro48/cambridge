local CreditsScene = Scene:extend()

CreditsScene.title = "Credits"

function CreditsScene:new()
    self.frames = 0
    -- higher = faster
    self.scroll_speed = 1
    switchBGM("credit_roll", "gm3")

    DiscordRPC:update({
        details = "Watching the credits",
        state = "Thanks for playing the game!",
        largeImageKey = "ingame-1900",
    })
    self.credit_blocks = {
        {
            title = "Game Developers",
            "Oshisaure",
            "Joe Zeng",
        },
        {
            title = "Project Heads",
            "Mizu",
            "MarkGamed",
            "Hailey",
        },
        {
            title = "Notable Game Developers",
            "2Tie - TGMsim",
            "Axel Fox - Multimino",
            "Dr Ocelot - Tetra Legends",
            "Electra - ZTrix",
            "Felicity/nightmareci/kdex - Shiromino",
            "Mine - Tetra Online",
            "MrZ - Techmino",
            "Phoenix Flare - Master of Blocks",
            "RayRay26 - Spirit Drop",
            "Rin - Puzzle Trial",
            "sinefuse - stackfuse"
        },
        {
            title = "Flooding edge Maintainer",
            "Tetro48"
        },
        {
            title = "Special Thanks",
            "321MrHaatz",
            "Adventium",
            "AgentBasey",
            "Archina",
            "Aurora",
            "Caithness",
            "Cheez",
            "colour_thief",
            "Commando",
            "Cublex",
            "CylinderKnot",
            "eightsixfivezero",
            "EricICX",
            "Gesomaru",
            "gizmo4487",
            "JBroms",
            "Kirby703",
            "Kitaru",
            "M1ssing0",
            "MattMayuga",
            "MyPasswordIsWeak",
            "Nikki Karissa",
            "nim",
            "offwo",
            "Oliver",
            "Pineapple",
            "pokemonfan1937",
            "Pyra Neoxi",
            "RDST64",
            "RocketLanterns",
            "RustyFoxxo",
            "saphie",
            "Shelleloch",
            "Simon",
            "stratus",
            "Super302",
            "switchpalacecorner",
            "terpyderp",
            "Tetrian22",
            "Tetro48",
            "ThatCookie",
            "TimmSkiller",
            "Trixciel",
            "user74003",
            "ZaptorZap",
            "Zircean",
            "All other contributors and friends!",
            "The Absolute PLUS Discord",
            "Tetra Legends Discord",
            "Tetra Online Discord",
            "Multimino Discord",
            "Hard Drop Discord",
            "Rusty's Systemspace",
            "Cambridge Discord",
            "And to you, the player!"
        }
    }
    local y_calculation = 550
    for key, value in pairs(self.credit_blocks) do
        value.y = y_calculation
        y_calculation = y_calculation + (#value * 18) + 80
    end
    self.final_y = y_calculation + 120
end

function CreditsScene:update()
    self.frames = self.frames + self.scroll_speed
    if self.frames >= self.final_y + 150 then
        playSE("mode_decide")
        scene = TitleScene()
        switchBGM(nil)
    elseif self.frames >= self.final_y then
        fadeoutBGM(2)
    end
end

local alignment_table = {"right", "center", "left"}

local alignment_coordinates = {320, 160}

function CreditsScene:render()
    local offset = self.frames

    local credits_pos = config.visualsettings.credits_position

    local text_x = alignment_coordinates[credits_pos]

    local align = alignment_table[4-credits_pos]

    love.graphics.setColor(1, 1, 1, 1)
	drawBackground(19)

    love.graphics.setFont(font_3x5_4)
    love.graphics.printf("Cambridge Credits", text_x, 500 - offset, 320, align)
    love.graphics.printf("THANK YOU\nFOR PLAYING!", text_x, math.max(self.final_y - offset, 240), 320, align)
    love.graphics.printf("- Milla", text_x, math.max(self.final_y + 80 - offset, 320), 320, align)

    for index, block in ipairs(self.credit_blocks) do
        love.graphics.setFont(font_3x5_3)
        love.graphics.printf(block.title, text_x, block.y - offset, 320, align)
        love.graphics.setFont(font_3x5_2)
        for key, value in ipairs(block) do
            love.graphics.printf(value, text_x, block.y + 30 + key * 18 - offset, 320, align)
        end
    end
    -- love.graphics.print("Game Developers", 320, 550 - offset)
    -- love.graphics.print("Project Heads", 320, 640 - offset)
    -- love.graphics.print("Notable Game Developers", 320, 750 - offset)
    -- love.graphics.print("Flooding edge Maintainer", 320, 1000 - offset)
    -- love.graphics.print("Special Thanks", 320, 1070 - offset)

    -- love.graphics.print("Oshisaure\nJoe Zeng", 320, 590 - offset)
    -- love.graphics.print("Mizu\nMarkGamed\nHailey", 320, 680 - offset)
    -- love.graphics.print(
    --     "2Tie - TGMsim\nAxel Fox - Multimino\nDr Ocelot - Tetra Legends\n" ..
    --     "Electra - ZTrix\nFelicity/nightmareci/kdex - Shiromino\n" ..
    --     "Mine - Tetra Online\nMrZ - Techmino\n" ..
    --     "Phoenix Flare - Master of Blocks\nRayRay26 - Spirit Drop\n" ..
    --     "Rin - Puzzle Trial\nsinefuse - stackfuse",
    --     320, 790 - offset
    -- )
    -- love.graphics.print("Tetro48", 320, 1040 - offset)
    -- love.graphics.print(
    --     "321MrHaatz\nAdventium\nAgentBasey\nArchina\nAurora\n" ..
    --     "Caithness\nCheez\ncolour_thief\nCommando\nCublex\n" ..
    --     "CylinderKnot\neightsixfivezero\nEricICX\nGesomaru\n" ..
    --     "gizmo4487\nJBroms\nKirby703\nKitaru\n" ..
    --     "M1ssing0\nMattMayuga\nMyPasswordIsWeak\n" ..
    --     "Nikki Karissa\nnim\noffwo\nOliver\nPineapple\npokemonfan1937\n" ..
    --     "Pyra Neoxi\nRDST64\nRocketLanterns\nRustyFoxxo\n" ..
    --     "saphie\nShelleloch\nSimon\nstratus\nSuper302\n" ..
    --     "switchpalacecorner\nterpyderp\nTetrian22\nTetro48\nThatCookie\n" ..
    --     "TimmSkiller\nTrixciel\nuser74003\nZaptorZap\nZircean\n" ..
    --     "All other contributors and friends!\nThe Absolute PLUS Discord\n" ..
    --     "Tetra Legends Discord\nTetra Online Discord\nMultimino Discord\n" ..
    --     "Hard Drop Discord\nRusty's Systemspace\nCambridge Discord\n" ..
    --     "And to you, the player!",
    --     320, 1110 - offset
    -- )
end

function CreditsScene:onInputPress(e)
    if e.type == "mouse" and e.button == 1 then
        scene = TitleScene()
        switchBGM(nil)
    end
    if e.scancode == "space" then
        self.scroll_speed = 4
    end
    if e.input == "menu_decide" or e.scancode == "return" or
       e.input == "menu_back" or e.scancode == "delete" or e.scancode == "backspace" then
        scene = TitleScene()
        switchBGM(nil)
	end
end

function CreditsScene:onInputRelease(e)
    if e.scancode == "space" then
        self.scroll_speed = 1
    end
end

return CreditsScene

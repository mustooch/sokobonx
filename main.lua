function mid(min, v, max) return math.min(math.max(min, v), max) end

function love.load()
    
    love.graphics.setDefaultFilter("nearest")
    love.keyboard.setKeyRepeat(true)
    
    level = require "level"
    level:from_file("level.txt")
--    level:load_next()
    
    state = "game"
    
    spr = {}
    spr.texture = love.graphics.newImage("sprites.png")
    spr["#"] = {
        love.graphics.newQuad(16, 0, 16, 16, spr.texture),
        love.graphics.newQuad(32, 0, 16, 16, spr.texture),
        love.graphics.newQuad(48, 0, 16, 16, spr.texture)}    -- wall
    spr["$"] = love.graphics.newQuad(16, 16, 16, 16, spr.texture)   -- box
    spr[" "] = love.graphics.newQuad(0, 0, 16, 16, spr.texture)     -- floor
    spr["."] = love.graphics.newQuad(0, 16, 16, 16, spr.texture)    -- goal
    spr["@"] = love.graphics.newQuad(48, 32, 16, 16, spr.texture)   -- player on floor
    spr["*"] = love.graphics.newQuad(32, 16, 16, 16, spr.texture)   -- box on goal
    spr["+"] = love.graphics.newQuad(64, 32, 16, 16, spr.texture)   -- player on goal
    spr["-"] = {
        love.graphics.newQuad(0, 32, 16, 16, spr.texture),
        love.graphics.newQuad(16, 32, 16, 16, spr.texture)}  -- void
    spr.win = love.graphics.newImage("win.png")
    
    keymap = {w="up",a="left",s="down",d="right"}
end

function love.update()
    love.window.setTitle(level:get_level_title() or "")
end

function love.keypressed(key)
    if key == "escape" then love.event.push("quit") end
    
    if state == "game" then
        if key == "w" or key == "a" or key == "s" or key == "d" then
            key = keymap[key]
        end
        
        if key == "up" or key == "down" or key == "left" or key == "right" then
            level:move_player(key)
            state = level:check_win() or state
            
        elseif key == "space" or key == "rshift" then
            level:undo()
            
        elseif key == "r" then
            level:restart()
            
        elseif key == "l" then
            level:load_next()
            
        elseif key == "k" then
            level:load_previous()
            
        end
        
    elseif state == "win" then
        level:restart()
        state = "game"
        
    end
end

function love.draw()
    love.graphics.scale(level:get_scale())
    
    -- draw background
    for i = 0, 20 do
        for j = 0, 25 do
            love.graphics.draw(spr.texture, spr["-"][1], j*16, i*16)
        end
    end
    
    if state == "game" then
        level:draw_level()
    end
    
    if state == "win" then
        love.graphics.scale(1/level:get_scale())
        love.graphics.scale(4)
        love.graphics.draw(spr.win, 0, 0)
    end
end

function love.quit()
    level:close_file()
end


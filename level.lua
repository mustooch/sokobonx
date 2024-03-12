local level = {}

function level:from_string(string)
    self.text_string = string
    
    -- convert text to a grid
    self.grid = {}
    for line in string.gmatch(string, "(.-)\n") do
        local row = {}
        for char in string.gmatch(line, ".") do
            table.insert(row, char)
        end
        table.insert(self.grid, row)
    end
    self.hei, self.wid = #self.grid, #self.grid[1]
    
    -- find player position
    self.player = {}
    for i = 1, self.hei do
        for j = 1, self.wid do
            if self.grid[i][j] == "@" or self.grid[i][j] == "+" then
                self.player = {i = i, j = j}
            end
        end
    end
    
    self.title = ""
    
    -- sequence of moves for undo
    self.sequence = {}
    
    self.win = false
end

function level:load_file(name)
    self.file = io.open(name, "r")
end

function level:close_file()
    if self.file then
        self.file:close()
    end
end

--function level:from_file(name)
--    local file = io.open(name, "r")
--    local rows = {}
--    local longest = 0
    
--    for line in file:lines() do
--        longest = math.max(longest, #line)
--        table.insert(rows, line)
--    end
    
--    for i = 1, #rows do
--        rows[i] = rows[i] .. string.rep(" ", longest - #rows[i])
--    end
    
    
--    self:from_string(table.concat(rows, "\n") .. "\n")
--end

function level:load_next()
    
end

function level:load_previous()
    
end

function level:restart()
    self:from_string(self.text_string)
end

function level:get_level_title()
    return self.title
end


function level:get_scale()
    if level.wid <= 11 and level.hei <= 8 then
        return 4
    elseif level.wid <= 15 and level.hei <= 11 then
        return 3
    elseif level.wid <= 30 and level.hei <= 22 then
        return 2
    else
        return 1
    end
end

function level:draw_level()
    for i = 1, self.hei do
        for j = 1, self.wid do
            local char = self.grid[i][j]
            if char == "#" then
                love.graphics.draw(spr.texture,
                    spr[char][(5*i+2*j)%3 + 1], j*16, i*16)
            else
                love.graphics.draw(spr.texture, spr[char], j*16, i*16)
            end
        end
    end
end

function level:move_player(key)
    local pi, pj = self.player.i, self.player.j
    local from = self.grid[pi][pj]
    local dir = {
        up = {pi - 1, pj, pi - 2, pj},
        down = {pi + 1, pj, pi + 2, pj},
        left = {pi, pj - 1, pi, pj - 2},
        right = {pi, pj + 1, pi, pj + 2}
    }
    local to = self.grid[dir[key][1]][dir[key][2]]
    
    -- move character and boxes
    if to == " " or to == "." then
        -- no collision
        self.grid[dir[key][1]][dir[key][2]] = (to == " " and "@" or "+")
        self.grid[pi][pj] = (from == "@" and " " or ".")
        pi, pj = dir[key][1], dir[key][2]
        table.insert(self.sequence, "move-" .. key)
        
    elseif to == "$" or to == "*" then
        -- collides with box
        local boxTo = self.grid[dir[key][3]][dir[key][4]]
        if boxTo == " " or boxTo == "." then
            self.grid[dir[key][3]][dir[key][4]] = (boxTo == " " and "$" or "*")
            self.grid[dir[key][1]][dir[key][2]] = (to == "$" and "@" or "+")
            self.grid[pi][pj] = (from == "@" and " " or ".")
            pi, pj = dir[key][1], dir[key][2]
            table.insert(self.sequence, "push-" .. key)
        end
    end
    
    self.player.i, self.player.j = pi, pj
    
end

function level:undo()
    
    local last_move = table.remove(self.sequence)
    if last_move == nil then return end
    
    local from = self.grid[self.player.i][self.player.j] --! change var name
    
    if string.sub(last_move, 1, 4) == "move" then
        -- only player needs to move
        
        local undoDir = string.match(last_move, "%-(.*)")
        level:move_player(({up="down",down="up",right="left",left="right"})[undoDir])
        table.remove(self.sequence) -- pop last element added by the call above
        
        
    elseif string.sub(last_move, 1, 4) == "push" then
        -- player and box need to move
        
        -- first undo player
        local undoDir = string.match(last_move, "%-(.*)")
        level:move_player(({up="down",down="up",right="left",left="right"})[undoDir])
        table.remove(self.sequence) -- pop last element added by the call above
        
        -- then undo box
        if undoDir == "down" then
            -- push-down, need to go back up
            local boxi, boxj = self.player.i + 2, self.player.j
            self.grid[boxi - 1][boxj] = (from == "@" and "$" or "*")
            self.grid[boxi][boxj] = (self.grid[boxi][boxj] == "$" and " " or ".")
        elseif undoDir == "up" then
            -- push-up, need to go back down
            local boxi, boxj = self.player.i - 2, self.player.j
            self.grid[boxi + 1][boxj] = (from == "@" and "$" or "*")
            self.grid[boxi][boxj] = (self.grid[boxi][boxj] == "$" and " " or ".")
        elseif undoDir == "right" then
            -- push-right, need to go back left
            local boxi, boxj = self.player.i, self.player.j + 2
            self.grid[boxi][boxj - 1] = (from == "@" and "$" or "*")
            self.grid[boxi][boxj] = (self.grid[boxi][boxj] == "$" and " " or ".")
        elseif undoDir == "left" then
            -- push-left, need to go back right
            local boxi, boxj = self.player.i, self.player.j - 2
            self.grid[boxi][boxj + 1] = (from == "@" and "$" or "*")
            self.grid[boxi][boxj] = (self.grid[boxi][boxj] == "$" and " " or ".")
        end
    end
    
end

function level:check_win()
    local openGoals = 0
    for i = 1, self.hei do
        for j = 1, self.wid do
            if self.grid[i][j] == "." or self.grid[i][j] == "+" then
                openGoals = openGoals + 1
            end
        end
    end
    if openGoals == 0 then
        self.win = true
        state = "win" --! redundant
    end
end

return level

TXUI = require("/api/txui")

local menu = {}

local w, h = term.getSize()
local columnsPerPage = math.ceil(w / 50)
local rowHeight = 2
local rowsPerPage = math.floor((h - 4) / rowHeight)
local commandsPerPage = columnsPerPage * rowsPerPage
local commandWidth = math.floor((w - 2) / columnsPerPage)


local function getMenuCommands(path)
    if not fs.isDir(path) then
        error(path .. " is not a directory")
    end

    local commands = {}

    for i, filename in pairs(fs.list(path)) do
        local fullPath = "/" .. fs.combine(path, filename)
        local modulePath = string.match(fullPath, "^(.+)%.lua$")
        if not modulePath then
            error(fullPath .. " is not a valid command. Doesn't have the .lua extension")
        end

        commands[i] = require(modulePath)

        if type(commands[i]) ~= "table" then
            error(fullPath .. " is not a valid command.")
        elseif type(commands[i].execute) ~= "function" then
            error(fullPath .. " is missing the execute method")
        elseif type(commands[i].label) ~= "string" then
            error(fullPath .. " is missing the label attribute")
        end
    end

    return commands
end

function menu.open(title, path, returnButton, page)
    local commands = getMenuCommands(path)
    returnButton = returnButton == nil and true or false
    page = page or 0

    local w, h = term.getSize()
    local window = TXUI.Window:new({
        w = w,
        h = h,
        tlColor = colors.black,
        bgColor = colors.gray
    })

    TXUI.Controller:addWindow(window)

    window:setTitleLabel(TXUI.Label:new({
        text = " " .. title,
        textColor = colors.white,
        textAlign = "left",
    }))

    window:addComponent(TXUI.Button:new({
        y = 1,
        x = w - 1,
        w = 1,
        h = 1,
        text = "X",
        textColor = colors.red,
        bgColor = window.tlColor,
        textAlign = "left",
        action = function(self)
            self.parent:close()
        end
    }))

    local backButton = TXUI.Button:new({
        y = h - 1,
        x = 2,
        w = 7,
        h = 1,
        text = " < Back ",
        textColor = colors.white,
        activeTextColor = colors.white,
        bgColor = colors.red,
        activeBgColor = colors.red,
        textAlign = "left"
    })

    local nextButton = TXUI.Button:new({
        y = h - 1,
        x = w - 8,
        h = 1,
        w = 8,
        text = " Next > ",
        textColor = colors.white,
        activeTextColor = colors.white,
        bgColor = colors.green,
        activeBgColor = colors.green,
        textAlign = "right",
        action = function(self)
            self.parent:close()
        end
    })

    window:addComponent(backButton)
    window:addComponent(nextButton)

    local buttons = {}
    local exec

    for i, command in ipairs(commands) do
        local item = i % commandsPerPage
        local line = item % rowsPerPage

        local label = " " .. command.label .. " "
        local len = string.len(label)

        buttons[i] = TXUI.Button:new({
            y = 1 + line * rowHeight,
            x = 2,
            h = 1,
            w = len,
            text = label,
            textColor = colors.white,
            activeTextColor = colors.white,
            bgColor = colors.green,
            activeBgColor = colors.green,
            textAlign = "left",
            action = function(self)
                self.parent:close()
                exec = command.execute
            end
        })

        window:addComponent(buttons[i])
    end

    pcall(function()
        TXUI.Controller:startUpdateCycle()
    end)

    if exec then
        if exec() then
            menu.open(title, path, returnButton, page)
        end
    end
end

return menu

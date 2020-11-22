TXUI = require("/api/txui")

local menu = {}

local w, h = term.getSize()
local itemHeight = 2
local itemsPerPage = math.floor((h - 4) / itemHeight)

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

        local command = require(modulePath)

        if type(command) ~= "table" then
            error(fullPath .. " is not a valid command.")
        elseif type(command.execute) ~= "function" then
            error(fullPath .. " is missing the execute method")
        elseif type(command.label) ~= "string" then
            error(fullPath .. " is missing the label attribute")
        end

        if type(command.predicate) == "function" then
            if command.predicate() then
                table.insert(commands, command)
            end
        elseif command.predicate == nil or command.predicate then
            table.insert(commands, command)
        end
    end

    return commands
end

function menu.open(title, path, returnButton, page)
    local commands = getMenuCommands(path)
    local pages = math.ceil(#commands / itemsPerPage)
    returnButton = returnButton == nil and true or false
    page = page or 1

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
        textAlign = "left",
        action = function(self)
            if page > 1 then
                loadPage(page - 1)
            end
        end
    })

    local nextButton = TXUI.Button:new({
        y = h - 1,
        x = w - 8,
        h = 1,
        w = 8,
        text = " Next > ",
        textAlign = "right",
        action = function(self)
            if page < pages then
                loadPage(page + 1)
            end
        end
    })

    local pageLabel = TXUI.Label:new({
        y = h - 1,
        x = 4 + backButton.w,
        h = 1,
        w = w - 5 - nextButton.w - backButton.w,
        bgColor = colors.lightGray,
        textColor = colors.gray,
        textAlign = "center"
    })

    window:addComponent(backButton)
    window:addComponent(nextButton)
    window:addComponent(pageLabel)

    local buttons = {}
    local exec

    for i, command in ipairs(commands) do
        local item = (i - 1) % itemsPerPage
        local label = " " .. string.sub(command.label, 1, w - 4) .. " "
        local len = string.len(label)

        buttons[i] = TXUI.Button:new({
            y = 3 + item * itemHeight,
            x = 2,
            h = 1,
            w = len,
            text = label,
            textColor = colors.white,
            activeTextColor = colors.white,
            bgColor = colors.green,
            activeColor = colors.green,
            textAlign = "left",
            action = function(self)
                self.parent:close()
                exec = command.execute
            end
        })

        window:addComponent(buttons[i])
    end

    function loadPage(p)
        page = p
        for _, button in ipairs(buttons) do
            button.visible = false
        end
        for i = 1 + itemsPerPage * (page - 1), itemsPerPage * page do
            if buttons[i] then
                buttons[i].visible = true
            end
        end

        if page == 1 then
            backButton.textColor = colors.gray
            backButton.activeTextColor = colors.gray
            backButton.bgColor = colors.lightGray
            backButton.activeColor = colors.lightGray
        else
            backButton.textColor = colors.white
            backButton.activeTextColor = colors.white
            backButton.bgColor = colors.red
            backButton.activeColor = colors.red
        end
        if page == pages then
            nextButton.textColor = colors.gray
            nextButton.activeTextColor = colors.gray
            nextButton.bgColor = colors.lightGray
            nextButton.activeColor = colors.lightGray
        else
            nextButton.textColor = colors.white
            nextButton.activeTextColor = colors.white
            nextButton.bgColor = colors.green
            nextButton.activeColor = colors.green
        end

        pageLabel.text = "Page " .. page .. " of " .. pages

        window:draw()
    end

    loadPage(page)

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

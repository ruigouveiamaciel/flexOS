
TXUI = require("/api/txui")
github = require("/api/github")

local w, h = term.getSize()
local window = TXUI.Window:new({
    w = w,
    h = h,
    tlColor = colors.black,
    bgColor = colors.gray
})

TXUI.Controller:addWindow(window)

window:setTitleLabel(TXUI.Label:new({
    text = " System Update",
    textColor = colors.white,
    textAlign = "left",
}))

local statusLabel = TXUI.Label:new({
    x = 1,
    y = math.floor(h / 2 - 1) - 1,
    w = w,
    h = 3,
    text = "Checking for updates...",
    bgColor = window.bgColor,
    textColor = colors.white,
    vertCenter = true,
})

local updateButton = TXUI.Button:new({
    x = 4,
    y = math.ceil(h / 2 + 1),
    w = math.floor((w - 11) / 2),
    text = "Update",
    bgColor = colors.lightGray,
    activeColor = colors.lightGray,
    textColor = colors.gray,
    activeTextColor = colors.gray
})

local cancelButton = TXUI.Button:new({
    x = w - 3 - updateButton.w,
    y = updateButton.y,
    w = updateButton.w,
    h = updateButton.h,
    text = "Cancel",
    bgColor = colors.red,
    activeColor = colors.red,
    action = function()
        window:close()
    end
})



window:addComponent(statusLabel)
window:addComponent(cancelButton)
window:addComponent(updateButton)

parallel.waitForAny(function()
    TXUI.Controller:startUpdateCycle()
end, function()
    local status, updateAvailable, pull = pcall(github.fetch, "/repo", "ruigouveiamaciel", "gdocs")

    if status then
        if not updateAvailable then
            statusLabel.text = "System is up to date.\nClosing this window in 3 seconds..."
            cancelButton.text = "Close"
            window:draw()

            sleep(3)
            return
        end

        statusLabel.text = "Update available, do you want to update?\n"
        statusLabel.textColor = colors.lime
        updateButton.textColor = colors.white
        updateButton.activeTextColor = updateButton.textColor
        updateButton.bgColor = colors.green
        updateButton.activeBgColor = updateButton.bgColor
        updateButton.action = function()
            os.queueEvent("updater_answer")
        end

        window:draw()

        parallel.waitForAny(function()
            os.pullEvent("updater_answer")
        end, function()
            sleep(15)
        end)

        statusLabel.text = "Downloading updates...\n"
        statusLabel.textColor = colors.white
        updateButton.textColor = colors.gray
        updateButton.activeTextColor = updateButton.textColor
        updateButton.bgColor = colors.lightGray
        updateButton.activeBgColor = updateButton.bgColor
        window:draw()

        local pullStatus, pullErr = pcall(pull)

        if pullStatus then
            statusLabel.text = "Succesfully updated!\nRebooting in 3 seconds...\n"
            statusLabel.textColor = colors.lime
            cancelButton.text = "Reboot now"
            cancelButton.action = function()
                os.reboot()
            end
            window:draw()

            sleep(3)
            os.reboot()
        else
            pullErr = pullErr or "INVALID ERROR MESSAGE"
            statusLabel.textColor = colors.red
            statusLabel.text = "Failed to download updates!\n" .. updateErr
            window:draw()
            sleep(7)
        end
    else
        local err = updateAvailable or "INVALID ERROR MESSAGE"
        statusLabel.textColor = colors.red
        statusLabel.text = "Failed to fetch for updates!\n" .. err
        window:draw()
        sleep(7)
    end
end)

TXUI.Controller:exit()

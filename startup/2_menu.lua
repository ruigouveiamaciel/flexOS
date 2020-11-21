TXUI = require("/api/txui")

local w, h = term.getSize()
local window = TXUI.Window:new({
    w = w,
    h = h,
    tlColor = colors.black,
    bgColor = colors.gray
})

TXUI.Controller:addWindow(window)

window:setTitleLabel(TXUI.Label:new({
    text = " Main Menu",
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

parallel.waitForAny(function()
    TXUI.Controller:startUpdateCycle()
end)

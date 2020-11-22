
if not settings.get("system.autoupdate", true) then
    return
else
    settings.set("system.autoupdate", true)
end

shell.execute("/programs/update")

-- pastebin run ENPqkZ5H

local user = "ruigouveiamaciel"
local repo = "flexOS"
local ref = "master"
local path = "api/github.lua"

local function urlPath(path)
    local cleanPath = ""

    for dir in string.gmatch(path, "[^ ]+") do
        if cleanPath ~= "" then
            cleanPath = cleanPath .. "%20"
        end
        cleanPath = cleanPath .. dir
    end

    return cleanPath
end

local function getDownloadURL(user, repo, ref, path)
    ref = ref or "master"
    return "https://raw.githubusercontent.com/" .. user .. "/" .. repo .. "/" .. ref .."/" .. urlPath(path)
end

local request = http.get(getDownloadURL(user, repo, ref, path))
local code = request.readAll()
request.close()

local github = load(code)()
github.pull("/", user, repo, ref)
os.reboot()

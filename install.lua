local user = "ruigouveiamaciel"
local repo = "gdocs"
local ref = "master"
local path = "api/github.lua"

local function getDownloadURL(user, repo, ref, path)
    ref = ref or "master"
    return "https://raw.githubusercontent.com/" .. user .. "/" .. repo .. "/" .. ref .."/" .. path
end

local resquest = http.get(getDownloadURL(user, repo, ref, path))
local code = request.readAll()
request.close()

local github = load(code)
github.pull("/", user, repo, ref)

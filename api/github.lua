
local github = {}

local function getTreeURL(user, repo, ref)
    ref = ref or "master"
    return "https://api.github.com/repos/".. user .."/".. repo .."/git/trees/" .. ref .. "?recursive=true"
end

local function getDownloadURL(user, repo, ref, path)
    ref = ref or "master"
    return "https://raw.githubusercontent.com/" .. user .. "/" .. repo .. "/" .. ref .."/" .. path
end

local github_token = settings.get("github.token", nil)
local github_file = settings.get("github.file", ".githubapi")
local allowedExtensions = {
    ["txt"] = true,
    ["json"] = true,
    ["lua"] = true,
    [""] = true
}

local function getRequestHeaders()
    local headers = {}

    if github_token then
        headers["Authorization"] = "token " .. github_token
    end

    return headers
end

local requestHeaders = getRequestHeaders()

local function shouldIgnorePath(path, filter)
    local extension = string.gmatch(path, "%.(%w+)$")() or ""
    local allowed = filter or allowedExtensions

    if allowed[extension] then
        local filename = string.gmatch(path, "[^/]+$")() or ""

        return #string.gmatch(filename, "[^%.].*$")() ~= #filename
    end

    return true
end

local function request(url, json)
    if not http.checkURL(url) then
        error("Invalid URL: " .. url)
    end

    local req, err, errReq = http.get(url, requestHeaders)

    if req == nil then
        local httpCode = errReq.getResponseCode()
        local headers = errReq.getResponseHeaders()
        errReq.close()

        if httpCode == 403 then
            local resetTime = headers["X-Ratelimit-Reset"] or 0
            local epoch = math.floor(os.epoch("utc") / 1000)
            local waitTime = math.max(0, resetTime - epoch + 1)

            sleep(waitTime)
            return request(url)
        end

        error(string.upper(httpCode .. " " .. err))
    end


    local data = req.readAll()
    req.close()

    if json then
        data = textutils.unserializeJSON(data)
    end

    return data
end

local function getRemoteContents(user, repo, ref, filter)
    local treeURL = getTreeURL(user, repo, ref)
    local response = request(treeURL, true)
    local remote = {
        ["sha"] = response.sha,
        ["tree"] = {}
    }

    for _, item in ipairs(response.tree) do
        if not (shouldIgnorePath(item.path, filter) or item.type ~= "blob") then
            remote.tree[item.path] = {
                ["download"] = getDownloadURL(user, repo, remote.sha, item.path),
                ["sha"] = item.sha
            }
        end
    end

    return remote
end

local function getLocalContents(path)
    local computer = {
        ["tree"] = {}
    }

    path = fs.combine(path, github_file)
    if (fs.exists(path)) then
        local fd = fs.open(path, "r")
        computer = textutils.unserializeJSON(fd.readAll()) or computer
        fd.close()
    end

    return computer
end

local function compareContents(computer, remote)
    local different = computer.sha ~= remote.sha
    local delete, download = {}, {}

    for path, item in pairs(computer.tree) do
        local remoteItem = remote.tree[path]

        if not remoteItem then
            delete[path] = true
        end
    end

    for path, item in pairs(remote.tree) do
        local computerItem = computer.tree[path]
        if computerItem then
            if item.sha ~= computerItem.sha then
                delete[path] = true
                download[path] = item.download
            end
        else
            download[path] = item.download
        end
    end

    return different, delete, download
end

local function delete(path, notFirst)
    if path ~= nil then
        if fs.isDir(path) then
            if #fs.list(path) == 0 then
                fs.delete(path)
            else
                return
            end
        elseif fs.exists(path) then
            fs.delete(path)
        end

        local parent = string.match(path, "^(.*)/")
        delete(parent)
    end
end

local function downloadURL(path, url)
    local fd = fs.open(path, "w")
    fd.write(request(url))
    fd.close()
end

local function deleteAndDownload(path, delete, download)
    local deletions = {}
    for itemPath, _ in pairs(delete) do
        table.insert(deletions, function()
            delete(fs.combine(path, itemPath))
        end)
    end

    local downloads = {}
    for itemPath, url in pairs(download) do
        table.insert(downloads, function()
            downloadURL(fs.combine(path, itemPath), url)
        end)
    end

    if #deletions > 0 then
        parallel.waitForAll(unpack(deletions))
    end
    if #downloads > 0 then
        parallel.waitForAll(unpack(downloads))
    end
end

local function saveGithubFile(path, remote)
    for path, _ in pairs(remote.tree) do
        remote.tree[path].download = nil
    end

    local fd = fs.open(fs.combine(path, github_file), "w")
    fd.write(textutils.serialiseJSON(remote))
    fd.close()
end

function github.fetch(path, user, repo, ref, filter)
    local computer = getLocalContents(path)
    local remote = getRemoteContents(user, repo, ref, filter)
    local different, delete, download = compareContents(computer, remote)

    return different, function()
        deleteAndDownload(path, delete, download)
        saveGithubFile(path, remote)
    end
end

function github.pull(path, user, repo, ref, filter)
    local different, pull = github.fetch(path, user, repo, refs, filter)

    if different then
        pull()
    end
end

return github

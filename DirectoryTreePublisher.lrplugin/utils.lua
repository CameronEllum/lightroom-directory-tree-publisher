--[[
  Shared utility functions for DirectoryTreePublisher plugin

  This module can be used both within Lightroom (via require) and in
  standalone Lua tests.
]]

local Utils = {}

--[[
Ensures a path uses forward slashes.
]]
function Utils.normalizePath(p)
    return string.gsub(p, "\\", "/")
end

--[[
Ensures a path uses back slashes (for Windows API calls).
]]
function Utils.windowsPath(p)
    return string.gsub(p, "/", "\\")
end

--[[
Splits a string by a separator. If no separator is provided then splits on whitespace.
]]
function Utils.splitString(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        table.insert(t, str)
    end
    return t
end

--[[
Removes a prefix from a string if present.
]]
function Utils.deletePrefix(s, p)
    local t = (s:sub(0, #p) == p) and s:sub(#p + 1) or s
    return t
end

--[[
Returns the longest common root path among the given directory paths.

The longest common root is defined as the longest path prefix that is common
to all directories.

The directories are expected to be given as an array of path strings.

The function returns the longest common root path as a string.
Returns an empty string if no common root exists or if the input is empty.

Example:

local directories = {
  "D:/Photos/2023/January",
  "D:/Photos/2023/February",
  "D:/Photos/2024/March"
}

local commonRoot = longestCommonRoot(directories)
-- commonRoot is now "D:/Photos"

--]]
function Utils.longestCommonRoot(directories)
    if not directories or #directories == 0 then
        return ""
    end

    -- Normalize all paths to use forward slashes and split into components
    local allComponents = {}
    for i, d in ipairs(directories) do
        local normalized = Utils.normalizePath(d)
        allComponents[i] = Utils.splitString(normalized, "/")
    end

    -- Find the minimum number of components across all paths
    local minLength = #allComponents[1]
    for i = 2, #allComponents do
        if #allComponents[i] < minLength then
            minLength = #allComponents[i]
        end
    end

    -- Find common prefix by comparing components at each position
    local commonComponents = {}
    for pos = 1, minLength do
        local component = allComponents[1][pos]
        local allMatch = true

        for i = 2, #allComponents do
            if allComponents[i][pos] ~= component then
                allMatch = false
                break
            end
        end

        if allMatch then
            table.insert(commonComponents, component)
        else
            break
        end
    end

    -- Join the common components back into a path
    if #commonComponents == 0 then
        return ""
    end

    local result = table.concat(commonComponents, "/")

    -- Preserve leading slash for Unix-style absolute paths
    local firstPath = Utils.normalizePath(directories[1])
    if firstPath:sub(1, 1) == "/" then
        result = "/" .. result
    end

    return result
end

return Utils

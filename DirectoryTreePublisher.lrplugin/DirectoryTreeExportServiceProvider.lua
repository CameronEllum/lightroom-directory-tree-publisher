-- Lightroom SDK
local LrDialogs = import 'LrDialogs'
local LrFileUtils = import 'LrFileUtils'
local LrPathUtils = import 'LrPathUtils'
local LrView = import 'LrView'

-- Common shortcuts
local bind = LrView.bind

-- Look for the log at (e.g.) D:\Cameron\LrClassicLogs\DirectoryTreePublisher.log
require 'Logger'

-- ============================================================================--
local exportServiceProvider = {}
exportServiceProvider.small_icon = 'folder.png'
exportServiceProvider.publish_fallbackNameBinding = 'fullname'
exportServiceProvider.titleForGoToPublishedCollection = "disable"
exportServiceProvider.supportsCustomSortOrder = false
exportServiceProvider.supportsIncrementalPublish = 'only'
exportServiceProvider.hideSections = {'exportLocation'}
exportServiceProvider.allowFileFormats = {'JPEG'}
exportServiceProvider.allowColorSpaces = {'sRGB'}
exportServiceProvider.canExportVideo = false
exportServiceProvider.exportPresetFields = {{
  key = 'catalogRootDirectory',
  default = ""
}, {
  key = 'sourceRootDirectory',
  default = ""
}, {
  key = 'destinationRootDirectory',
  default = ""
}}

--[[
Add fields to the export dialog for source and target directories.
]]
function exportServiceProvider.sectionsForTopOfDialog(f, propertyTable)
  return { -- consider LrDialogs.runOpenPanel( args )
  {
    title = LOC "$$$/DirectoryTreePublisher/ExportDialog/Account=Directories",

    f:row{
      spacing = f:control_spacing(),
      f:static_text{
        title = "The destination root folder will replace the source root folder in the path.",
        alignment = 'left'
      }
    },

    -- This adds a text box accepting the directory where the published files
    -- will be written.
    f:row{
      spacing = f:control_spacing(),
      f:static_text{
        title = "Source root folder:",
        alignment = 'left'
      },
      f:edit_field{
        fill_horizontal = 1,
        value = bind 'sourceRootDirectory'
      }
    },
    f:row{
      spacing = f:control_spacing(),
      f:static_text{
        title = "Destination folder:",
        alignment = 'left'
      },
      f:edit_field{
        fill_horizontal = 1,
        value = bind 'destinationRootDirectory'
      }
    }

  }}
end

--[[
Splits a string by a separator. If no separator is provided then splits on whitespace.
]]
local function splitString(inputstr, sep)
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
local function longestCommonRoot(directories)
  if not directories or #directories == 0 then
    return ""
  end

  -- Normalize all paths to use forward slashes and split into components
  local allComponents = {}
  for i, d in ipairs(directories) do
    local normalized = normalizePath(d)
    allComponents[i] = splitString(normalized, "/")
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
  local firstPath = normalizePath(directories[1])
  if firstPath:sub(1, 1) == "/" then
    result = "/" .. result
  end

  return result
end

local function deletePrefix(s, p)
  local t = (s:sub(0, #p) == p) and s:sub(#p + 1) or s
  return t
end

--[[
Ensures a path uses forward slashes.
]]
local function normalizePath(p)
  return string.gsub(p, "\\", "/")
end

--[[
Ensures a path uses back slashes.
]]
local function windowsPath(p)
  return string.gsub(p, "/", "\\")
end

--[[
Publish a single rendition.
]]
local function publishPhoto(rendition, exportedPath, 
    sourceRootDirectory,destinationRootDirectory)
  Logger.trace("publishPhoto")

  local photo = rendition.photo

  -- This is the path of the file in the library
  local path = normalizePath(photo:getRawMetadata("path"))

  if photo:getRawMetadata("isVideo") then
    Logger.info("Skipping: " .. path)    
    return
  end

  Logger.info("Publishing: " .. path)

  -- The path in pathOrMessage is the (temporary) path of the exported
  -- image.
  local exportedPath = normalizePath(exportedPath)
  Logger.info("  Exported path   : " .. exportedPath)

  -- E.g., 'D:/Cameron/My Pictures/library/2013/PHOTO.DNG' becomes 
  -- 'library/20133/PHOTO.DNG'
  local relativePath = deletePrefix(path, sourceRootDirectory)
  Logger.info("  Relative path   : " .. relativePath)
  -- E.g., 'D:/Cameron/My Pictures/Highlights' + '/' 
  --  + 'library/2013/PHOTO.DNG'
  local destinationPath = destinationRootDirectory .. "/" .. relativePath
  -- E.g., 'D:/Cameron/My Pictures/Highlights/library/2013'
  destinationPath = normalizePath(LrPathUtils.parent(destinationPath))
  -- We want the JPEG photo name, not the original.
  -- E.g., 'D:/Cameron/My Pictures/Highlights/library/2013' + '/' + 'PHOTO.JPG'        
  destinationPath = destinationPath .. "/" .. LrPathUtils.leafName(exportedPath)
  Logger.info("  Destination path: " .. destinationPath)

  local r = LrFileUtils.createAllDirectories(
    LrPathUtils.parent(destinationPath))

  -- I'm not sure this is necessary
  if LrFileUtils.exists(destinationPath) then
    Logger.info("  File exists. Deleting." )
    local success = LrFileUtils.delete(destinationPath)
    if not success then
      Logger.error("  Deletion failed: " .. destinationPath )
    end
  end

  -- copy seems to be the only LrFileUtils method that needs windows paths 
  -- (on windows)
  local success, reason = LrFileUtils.copy(
    windowsPath(exportedPath), windowsPath(destinationPath))
  if not success then
    if reason then
      Logger.error("  Copy failed: " .. reason )
    else
      Logger.error("  Copy failed" )
    end
  end

  -- When done with the exported image, delete the (temporary) file. There
  -- is a cleanup step that happens later, but this will help manage space
  -- in the event of a large upload.
  LrFileUtils.delete(windowsPath(exportedPath))

  -- Record this ID with the photo so we know to replace instead of upload.
  -- For ID, we just use the destination path.
  rendition:recordPublishedPhotoId(destinationPath)
  rendition:recordPublishedPhotoUrl(destinationPath)
end


--[[
Main routine that does the publishing
]]
function exportServiceProvider.processRenderedPhotos(functionContext, exportContext)
  Logger.trace("processRenderedPhotos")
  Logger.info("============")

  local exportSession = exportContext.exportSession

  -- Make a local reference to the export parameters.
  local exportSettings = assert(exportContext.propertyTable)

  local sourceRootDirectory = normalizePath(exportSettings.sourceRootDirectory)
  Logger.info("Source directory: " .. sourceRootDirectory)
  local destinationRootDirectory = normalizePath(exportSettings.destinationRootDirectory)
  Logger.info("Export directory: " .. destinationRootDirectory)

  -- It would be nice to find the root automatically...
  -- local catalogFolders = {}
  -- for k, v in pairs(exportSession.catalog:getFolders()) do
  -- 	table.insert(catalogFolders,v:getPath())
  -- end
  -- longestCommonRoot(catalogFolders)

  -- Get the # of photos.
  local renditionsCount = exportSession:countRenditions()

  -- Set progress title.
  local progressScope = exportContext:configureProgress{
    title = renditionsCount > 1 and
      LOC("$$$/DirectoryTreePublisher/Publish/Progress=Publishing ^1 photos to directory tree", nPhotos) or
      LOC "$$$/DirectoryTreePublisher/Publish/Progress/One=Publishing one photo to directory tree"
  }

  -- Iterate through photo renditions.
  local photosetUrl
  for i, rendition in exportContext:renditions{
    stopIfCanceled = true
  } do
    progressScope:setPortionComplete((i - 1) / renditionsCount)

    -- local dir = photo.catalog:getPath()

    -- See if we previously uploaded this photo.
    if not rendition.wasSkipped then
      local success, pathOrMessage = rendition:waitForRender()

      -- Update progress scope again once we've got rendered photo.
      progressScope:setPortionComplete((i - 0.5) / renditionsCount)

      -- Check for cancellation again after photo has been rendered.
      if progressScope:isCanceled() then
        break
      end

      if not success then
        Logger.error("Render failed: " .. pathOrMessage)
      else
        publishPhoto(rendition, normalizePath(pathOrMessage),
          sourceRootDirectory, destinationRootDirectory)
      end

    else
      -- To get the skipped photo out of the to-republish bin.
      rendition:recordPublishedPhotoId(rendition.publishedPhotoId)
    end

  end

  progressScope:done()
end

function exportServiceProvider.deletePhotosFromPublishedCollection(publishSettings, arrayOfPhotoIds, deletedCallback)
  Logger.trace("deletePhotosFromPublishedCollection")
  for i, photoId in ipairs(arrayOfPhotoIds) do
    Logger.info("Deleted: " .. photoId)    
    local success, reason = LrFileUtils.moveToTrash( photoId )
    if not success then
      if reason then
        Logger.error("  MoveToTrash failed: " .. reason )
      else
        Logger.error("  MoveToTrash failed" )
      end
    end    
    deletedCallback( photoId )
  end
end

return exportServiceProvider

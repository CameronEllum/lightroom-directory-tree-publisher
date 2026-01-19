-- Lightroom SDK
local LrDialogs = import 'LrDialogs'
local LrFileUtils = import 'LrFileUtils'
local LrPathUtils = import 'LrPathUtils'
local LrView = import 'LrView'

-- Common shortcuts
local bind = LrView.bind

-- Look for the log at (e.g.) D:\Cameron\LrClassicLogs\DirectoryTreePublisher.log
require 'Logger'

-- Shared utility functions
local utils = require 'utils'

-- ============================================================================--
local exportServiceProvider = {}
exportServiceProvider.small_icon = 'folder.png'
exportServiceProvider.publish_fallbackNameBinding = 'fullname'
exportServiceProvider.titleForGoToPublishedCollection = "disable"
exportServiceProvider.supportsCustomSortOrder = false
exportServiceProvider.supportsIncrementalPublish = 'only'
exportServiceProvider.hideSections = { 'exportLocation' }
exportServiceProvider.allowFileFormats = { 'JPEG' }
exportServiceProvider.allowColorSpaces = { 'sRGB' }
exportServiceProvider.canExportVideo = false
exportServiceProvider.exportPresetFields = { {
  key = 'catalogRootDirectory',
  default = ""
}, {
  key = 'sourceRootDirectory',
  default = ""
}, {
  key = 'destinationRootDirectory',
  default = ""
} }

--[[
Add fields to the export dialog for source and target directories.
]]
function exportServiceProvider.sectionsForTopOfDialog(f, propertyTable)
  return {
    {
      title = LOC "$$$/DirectoryTreePublisher/ExportDialog/Account=Directories",

      f:row {
        spacing = f:control_spacing(),
        f:static_text {
          title = "The destination root folder will replace the source root folder in the path.",
          alignment = 'left'
        }
      },

      -- Source root folder with browse button
      f:row {
        spacing = f:control_spacing(),
        f:static_text {
          title = "Source root folder:",
          alignment = 'left',
          width = 120
        },
        f:edit_field {
          fill_horizontal = 1,
          value = bind 'sourceRootDirectory'
        },
        f:push_button {
          title = "Browse...",
          action = function()
            local result = LrDialogs.runOpenPanel {
              title = "Select Source Root Folder",
              canChooseFiles = false,
              canChooseDirectories = true,
              allowsMultipleSelection = false
            }
            if result and #result > 0 then
              propertyTable.sourceRootDirectory = result[1]
            end
          end
        }
      },

      -- Destination folder with browse button
      f:row {
        spacing = f:control_spacing(),
        f:static_text {
          title = "Destination folder:",
          alignment = 'left',
          width = 120
        },
        f:edit_field {
          fill_horizontal = 1,
          value = bind 'destinationRootDirectory'
        },
        f:push_button {
          title = "Browse...",
          action = function()
            local result = LrDialogs.runOpenPanel {
              title = "Select Destination Folder",
              canChooseFiles = false,
              canChooseDirectories = true,
              allowsMultipleSelection = false
            }
            if result and #result > 0 then
              propertyTable.destinationRootDirectory = result[1]
            end
          end
        }
      }

    } }
end

--[[
Publish a single rendition.
]]
local function publishPhoto(rendition, exportedPath,
                            sourceRootDirectory, destinationRootDirectory)
  Logger.trace("publishPhoto")

  local photo = rendition.photo

  -- This is the path of the file in the library
  local path = utils.normalizePath(photo:getRawMetadata("path"))

  if photo:getRawMetadata("isVideo") then
    Logger.info("Skipping: " .. path)
    return
  end

  Logger.info("Publishing: " .. path)

  -- The path in pathOrMessage is the (temporary) path of the exported
  -- image.
  local exportedPath = utils.normalizePath(exportedPath)
  Logger.info("  Exported path   : " .. exportedPath)

  -- E.g., 'D:/Cameron/My Pictures/library/2013/PHOTO.DNG' becomes
  -- 'library/20133/PHOTO.DNG'
  local relativePath = utils.deletePrefix(path, sourceRootDirectory)
  Logger.info("  Relative path   : " .. relativePath)
  -- E.g., 'D:/Cameron/My Pictures/Highlights' + '/'
  --  + 'library/2013/PHOTO.DNG'
  local destinationPath = destinationRootDirectory .. "/" .. relativePath
  -- E.g., 'D:/Cameron/My Pictures/Highlights/library/2013'
  destinationPath = utils.normalizePath(LrPathUtils.parent(destinationPath))
  -- We want the JPEG photo name, not the original.
  -- E.g., 'D:/Cameron/My Pictures/Highlights/library/2013' + '/' + 'PHOTO.JPG'
  destinationPath = destinationPath .. "/" .. LrPathUtils.leafName(exportedPath)
  Logger.info("  Destination path: " .. destinationPath)

  local r = LrFileUtils.createAllDirectories(
    LrPathUtils.parent(destinationPath))

  -- I'm not sure this is necessary
  if LrFileUtils.exists(destinationPath) then
    Logger.info("  File exists. Deleting.")
    local success = LrFileUtils.delete(destinationPath)
    if not success then
      Logger.error("  Deletion failed: " .. destinationPath)
    end
  end

  -- copy seems to be the only LrFileUtils method that needs windows paths
  -- (on windows)
  local success, reason = LrFileUtils.copy(
    utils.windowsPath(exportedPath), utils.windowsPath(destinationPath))
  if not success then
    if reason then
      Logger.error("  Copy failed: " .. reason)
    else
      Logger.error("  Copy failed")
    end
  end

  -- When done with the exported image, delete the (temporary) file. There
  -- is a cleanup step that happens later, but this will help manage space
  -- in the event of a large upload.
  LrFileUtils.delete(utils.windowsPath(exportedPath))

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

  local sourceRootDirectory = utils.normalizePath(exportSettings.sourceRootDirectory)
  Logger.info("Source directory: " .. sourceRootDirectory)
  local destinationRootDirectory = utils.normalizePath(exportSettings.destinationRootDirectory)
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
  local progressScope = exportContext:configureProgress {
    title = renditionsCount > 1 and
        LOC("$$$/DirectoryTreePublisher/Publish/Progress=Publishing ^1 photos to directory tree", renditionsCount) or
        LOC "$$$/DirectoryTreePublisher/Publish/Progress/One=Publishing one photo to directory tree"
  }

  -- Iterate through photo renditions.
  local photosetUrl
  for i, rendition in exportContext:renditions {
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
        publishPhoto(rendition, utils.normalizePath(pathOrMessage),
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
    local success, reason = LrFileUtils.moveToTrash(photoId)
    if not success then
      if reason then
        Logger.error("  MoveToTrash failed: " .. reason)
      else
        Logger.error("  MoveToTrash failed")
      end
    end
    deletedCallback(photoId)
  end
end

return exportServiceProvider

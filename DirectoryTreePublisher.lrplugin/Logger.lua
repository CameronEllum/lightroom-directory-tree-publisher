local logger = import 'LrLogger'('DirectoryTreePublisher')

logger:enable("logfile")

Logger = {}

-- Log levels
-- ALL:   0
-- TRACE: 1
-- INFO:  2
-- WARN:  3
-- ERROR: 4
Logger.level = 0

function Logger.trace(message)
  if Logger.level <= 1 then
    logger:trace(message)
  end
end

function Logger.info(message)
  if Logger.level <= 2 then
    logger:info(message)
  end
end

function Logger.warn(message)
  if Logger.level <= 3 then
    logger:warn(message)
  end
end

function Logger.error(message)
  if Logger.level <= 4 then
    logger:error(message)
  end
end

function Logger.logTable(name, value)
  if Logger.level <= 1 then
    if type(name) == "string" then
      logger:trace(name .. ":")
    end

    if type(value) == "table" then
      for i, j in pairs(value) do
        if type(value) == "string" then
          logger:trace(i .. " => " .. j)
        else
          Logger.logTable(i, j)
        end
      end
    else
      logger:trace(value)
    end
  end
end

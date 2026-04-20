-- "Screams" a message into a chatbox whenever specific entities are detected.

local YOUR_NAME = "fatboychummy"
local LOCATION_NAME = "Main Base"
local SCAN_RATE = 2.05 -- Depends on AP config.
local DETECTOR_RANGE = 16 -- Depends on AP config.

local envDetector = peripheral.find "environmentDetector" --[[@as EnvironmentDetector]]
if not envDetector then
  printError("No environment detector found.")
  return
end

local chatBox = peripheral.find "chatBox" --[[@as ChatBox]]
if not chatBox then
  printError("No chat box found.")
  return
end

---@class EnvironmentDetector
---@field scanEntities fun(range: number): Entity[]|nil, string?

---@class ChatBox
---@field sendMessage fun(message: string, prefix: string?, brackets: string?, bracketColor: string?, range: number?, utf8Support: boolean?): true|nil, string?
---@field sendMessageToPlayer fun(message: string, username: string, prefix: string?, brackets: string?, bracketColor: string?, range: number?, utf8Support: boolean?): true|nil, string?
---@field sendToastToPlayer fun(message: string, title: string, username: string, prefix: string?, brackets: string?, bracketColor: string?, range: number?, utf8Support: boolean?): true|nil, string?

---@class Entity
---@field canFreeze boolean
---@field health number
---@field id integer
---@field isGlowing boolean
---@field isInWall boolean
---@field maxHealth boolean
---@field name string
---@field tags string[]
---@field uuid string? I believe since this is a cracked server, some players may not have a uuid.
---@field x number OFFSET position.
---@field y number OFFSET position.
---@field z number OFFSET position.

---@class NameLookupEntry
---@field name string The actual entity name to display.
---@field resolution string? How to deal with the entity (e.g: hide, run, fight)
---@field possibleEntities string[]? A list of possible entities that could be represented by this name.
---@field resolutions table<string, string>? Map of name -> resolution, for cases where the same name can represent multiple entities.

---@type table<string, true>
local IGNORE_LIST = {
  ["Sheep"] = true,
  ["Cow"] = true,
  ["Pig"] = true,
  ["Chicken"] = true,
  ["Villager"] = true,
  ["Spider"] = true,
  ["Zombie"] = true,
  ["Skeleton"] = true,
  ["Creeper"] = true,
  ["Enderman"] = true,
  ["Witch"] = true,
  ["Wandering Trader"] = true,
  ["Parrot"] = true,
  ["Ocelot"] = true,
  ["Cat"] = true,
  ["Rabbit"] = true,
  ["Llama"] = true,
  ["Donkey"] = true,
}

---@type table<string, NameLookupEntry>
local NAME_LOOKUP = {
  ["???"] = {
    name = "The Entity",
    resolution = "Run away in a straight line. Tower up, but note it will hide below you."
  },
  ["??"] = {
    name = "Demon Fish",
    resolution = "Keep your distance.",
  },
  ["?"] = {
    name = "Unknown",
    resolution = "Find dug tunnel and fill it in after escaping.",
    possibleEntities = {
      "Someone",
      "Wanderer"
    },
    resolutions = {
      ["Someone"] = "Find dug tunnel and fill it in after escaping.",
      ["Wanderer"] = "Approach for a gift."
    }
  },
  ["no_one"] = {
    name = "No one",
    resolution = "Avoid direct contact."
  },
  ["The Spawn"] = {
    name = "The Spawn",
    resolution = "Block it or yourself in."
  },
  ["remember_me"] = {
    name = "Remember Me",
    resolution = "Kill it or run away."
  },
  ["H U N G E R"] = {
    name = "H U N G E R",
    resolution = "You're cooked."
  },
  ["Pillar"] = {
    name = "Pillar",
    resolution = "Avoid, do not look at."
  },
  ["Fate"] = {
    name = "Fate",
    resolution = "Block it or yourself in."
  },
  ["<o o o>"] = {
    name = "The Eyed",
    resolution = "Block it or yourself in.",
  },
  ["richyDUDE2001"] = {
    name = "The Hoarder",
    resolution = "Kill it. Attack before it puts on its armor."
  },
  ["Woodseeker"] = {
    name = "Woodseeker",
    resolution = "Hide in a 2 block tall area."
  },
  ["Skinless"] = {
    name = "Skinless",
    resolution = "Block yourself in."
  },
  ["666"] = {
    name = "Ethereal Demon",
    resolution = "Tower up 2+ blocks, use projectiles to force it to disappear."
  },
  ["t r e e"] = {
    name = "Wondertree",
    resolution = "Keep your distance."
  },
  ["f l e s h"] = {
    name = "Eyed Flesh",
    resolution = "Block it or yourself in."
  },
  ["0"] = {
    name = "Was Once",
    resolution = "Run to it and touch it if it begins harming you."
  },
  ["Helpless"] = {
    name = "Helpless",
    resolution = "Use projectiles to force it to explode early."
  },
  ["Carrier"] = {
    name = "Carrier",
    resolution = "Block it or yourself in."
  },
  ["Messenger"] = {
    name = "Messenger",
    resolution = "He brings a warning: A demon has spawned nearby."
  },
  ["Vessel"] = {
    name = "Vessel",
    resolution = "Do not look away, back away until you are a good distance away."
  },
  ["Siren"] = {
    name = "Siren",
    resolution = "Block it or yourself in."
  },
  ["ILoveBlocks4578"] = {
    name = "The Eyeless",
    resolution = "Treat it as you would a warden."
  },
  ["Sorrow"] = {
    name = "Sorrow",
    resolution = "Harmless."
  },
  ["<0>"] = {
    name = "Red Eye",
    resolution = "Back away, block its path, back away more."
  },
  ["<o>"] = {
    name = "The Eye",
    resolution = "Block it or yourself in."
  },
  ["I see you."] = {
    name = "Eye",
    resolution = "Harmless."
  },

  meta_duo = {
    name = "Imposter (sus)",
    resolution = "The real one is the one that isn't you."
  }
}

-- Someone's possible names.
-- It may also go by another player's name.
do
  local names = {
    "ServantOfThe3EyedDevil",
    "GODISDEAD",
    "youwillnotwakeup",
    "66666666",
    "imnotreal",
  }

  for _, name in ipairs(names) do
    NAME_LOOKUP[name] = {
      name = name,
      resolution = "Find dug tunnel and fill it in after escaping."
    }
  end
end

local DEFAULT_LOOKUP = {
  name = "%s (unknown)",
  resolution = "Unknown resolution."
}

local function shallow_copy(t)
  local copy = {}
  for k, v in pairs(t) do
    copy[k] = v
  end
  return copy
end

NAME_LOOKUP = setmetatable(NAME_LOOKUP, {
  __index = function(_, key)
    local t = shallow_copy(DEFAULT_LOOKUP)
    t.name = string.format(t.name, key)
    return t
  end
})


--- Scans, forcing to return a proper table.
---@return Entity[]
local function scan()
  return envDetector.scanEntities(DETECTOR_RANGE) or {}
end

---@param data NameLookupEntry
local function getResolutionString(data)
  if data.resolution then
    return data.resolution
  elseif data.possibleEntities and data.resolutions then
    local str = "Possible entities:\n"
    for _, entity in ipairs(data.possibleEntities) do
      local resolution = data.resolutions[entity] or "Unknown resolution."
      str = str .. string.format("- %s: %s\n", entity, resolution)
    end
    return str
  else
    return "Unknown resolution."
  end
end

---@param data NameLookupEntry
local function getNameString(data)
  return data.name
end

--- Notify the player via toast and chat.
---@param nameStr string
---@param resolutionStr string
local function notifyPlayer(nameStr, resolutionStr)
  repeat sleep() until chatBox.sendToastToPlayer(
    nameStr,
    LOCATION_NAME,
    YOUR_NAME,
    "-",
    "->"
  )

  repeat sleep() until chatBox.sendMessageToPlayer(
    resolutionStr,
    YOUR_NAME,
    LOCATION_NAME,
    "[]"
  )
end

--- Get information about an entity based on its name.
---@param entityName string
local function entityIsNear(entityName)
  local data = NAME_LOOKUP[entityName]
  local nameStr = getNameString(data)
  local resolutionStr = getResolutionString(data)

  return nameStr, resolutionStr
end

--- The last sent time of a given entity. Used to rate limit messages about the same entity.
---@type table<string, number>
local entityLastSent = {}

--- Filter out entities we don't care about.
---@param entities Entity[]
---@return Entity[] caredAbout The entities we care about.
local function entityFilter(entities)
  local caredAbout = {}
  local has_seen_ignored = false

  for _, entity in ipairs(entities) do
    if not IGNORE_LIST[entity.name] then
      if not entityLastSent[entity.name] then
        entityLastSent[entity.name] = 0
      end
      if entity.name == YOUR_NAME then
        if has_seen_ignored then
          if entityLastSent[YOUR_NAME] and os.epoch "utc" - entityLastSent[YOUR_NAME] > 10 * 1000 then
            table.insert(caredAbout, {name="meta_duo"})
            entityLastSent[YOUR_NAME] = os.epoch "utc"
          end
        end
        has_seen_ignored = true
      else
        if entityLastSent[entity.name] and os.epoch "utc" - entityLastSent[entity.name] > 10 * 1000 then
          table.insert(caredAbout, entity)
          entityLastSent[entity.name] = os.epoch "utc"
        end
      end
    end
  end

  return caredAbout
end

local function main()
  while true do
    local initial_tick_time = os.clock()
    local entities = entityFilter(scan())
    for _, entity in ipairs(entities) do
      local nameStr, resolutionStr = entityIsNear(entity.name)
      notifyPlayer(nameStr, resolutionStr)
    end
    local elapsed = os.clock() - initial_tick_time
    if elapsed < SCAN_RATE then
      sleep(SCAN_RATE - elapsed)
    end
  end
end

main()
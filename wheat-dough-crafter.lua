--- Crafts forever n ever

-- VALUES THE USER CAN CHANGE

local MODEM_SIDE = "front"
local INPUT_INV = "name of inventory here"
local OUTPUT_INV = "name of inventory here"

-- END OF USER VALUES

--#region initialization

-- Ensure we are running on a turtle.
if not turtle then
  error("This program must be run on a turtle!", 0)
end

if not turtle.craft then
  error("This turtle does not support crafting!", 0)
end

-- Collect the peripherals
local modem = peripheral.wrap(MODEM_SIDE)
local inv_in = peripheral.wrap(INPUT_INV)
local inv_out = peripheral.wrap(OUTPUT_INV)

-- Ensure the peripherals exist, and are the correct type
if not modem or not modem.getNameLocal then
  error("Wired modem not found!", 0)
end

if not inv_in or not peripheral.hasType(INPUT_INV, "inventory") then
  error("Input inventory was not found!", 0)
end

if not inv_out or not peripheral.hasType(OUTPUT_INV, "inventory") then
  error("Output inventory was not found!", 0)
end

-- Ensure the input/output chests are on the modem network
local modem_peripherals = modem.getNamesRemote()

--- Check if a peripheral is on the modem network
---@param name string
---@return boolean on_network
local function check_peripheral(name)
  for _, v in ipairs(modem_peripherals) do
    if v == name then
      return true
    end
  end

  return false
end

if not check_peripheral(INPUT_INV) then
  error("Input inventory is not on the modem network!", 0)
end

if not check_peripheral(OUTPUT_INV) then
  error("Output inventory is not on the modem network!", 0)
end

-- Get the turtle's name on the network
local t_name = modem.getNameLocal()

-- Ensure the turtle has a name
if not t_name then
  error("Turtle is not registered on the modem network!", 0)
end

--#endregion initialization

--#region utility

local tw, th = term.getSize()
local log_win = window.create(term.current(), 1, 5, tw, th - 3)

local function log(...)
  local old = term.redirect(log_win)

  print(...)

  term.redirect(old)
end

--- If the inventory has changed, this will be true.
local inv_dirty = true

---@class ItemDetail
---@field name string
---@field count integer

--- The last known inventory state.
---@type table<integer, ItemDetail> May contain holes
local last_inv = {}

--- Fetch the turtle's inventory.
--- @return table<integer, ItemDetail> inventory
local function fetch_inventory()
  log("FETCH INV")
  local list = {}

  for i = 1, 16 do
    list[i] = turtle.getItemDetail(i)
  end

  return list
end

--- Updates the turtle's inventory.
---@return table<integer, ItemDetail> inventory
local function update_inventory()
  if not inv_dirty then
    return last_inv
  end

  log("UPDATE INV")

  last_inv = fetch_inventory()
  inv_dirty = false

  return last_inv
end

local function deep_copy(v)
  if type(v) ~= "table" then
    return v
  end

  local copy = {}
  for k, v in pairs(v) do
    copy[k] = deep_copy(v)
  end

  return copy
end

---@type function[]
local func_queue = {function()end}

--- Inject a function into the parallel queue.
---@param f function
local function add_queue(f)
  table.insert(func_queue, f)
end

--- Run the queue of functions in parallel.
local function run_queue()
  if #func_queue == 0 then
    return
  end
  log("Running parallel queue")

  parallel.waitForAll(table.unpack(func_queue))
  func_queue = {function()end}
  inv_dirty = true

  log("Done")
end

--- Clean the inventory of any extra items.
local function clean_inventory()
  log("Cleaning out the inventory.")

  local items = update_inventory()

  for slot, item in pairs(items) do
    if slot == 1 then
      -- Slot 1 should be either a filled bucket or an empty bucket.
      if item and not item.name:find("bucket") then
        log("Non bucket in slot 1")
        add_queue(function()
          inv_out.pullItems(t_name, 1)
        end)
      end
    elseif slot == 2 or slot == 3 or slot == 5 then
      -- Slots 2,3,5 should be wheat.
      if item and item.name ~= "minecraft:wheat" then
        log("Non wheat in slot", slot)
        add_queue(function()
          inv_out.pullItems(t_name, slot)
        end)
      end
    else
      -- Other slots should be empty.
      if item then
        log("Non empty slot", slot)
        add_queue(function()
          inv_out.pullItems(t_name, slot)
        end)
      end
    end
  end

  run_queue()
end

--- Count the amount of wheat in the turtle's inventory.
---@return integer wheat_count
---@return table<integer, ItemDetail> items
local function count_wheat_self()
  local items = update_inventory()
  local wheat_count = 0

  for i = 2, 5 do
    if items[i] and items[i].name == "minecraft:wheat" then
      wheat_count = wheat_count + items[i].count
    end
  end

  return wheat_count, items
end

--- Count the amount of wheat in the input inventory.
---@return integer wheat_count
---@return table<integer, ItemDetail> items
local function count_wheat_in()
  local items = inv_in.list()
  local wheat_count = 0

  for _, item in pairs(items) do
    if item.name == "minecraft:wheat" then
      wheat_count = wheat_count + item.count
    end
  end

  return wheat_count, items
end

--- Get wheat in slots 2,3,4, and ensures it's equally distributed
local function get_wheat()
  -- Stage 1: Push wheat from the input inventory, in sets of 3.

  -- 1.1 : Check how many wheat we have in the input inventory, and our inventory.
  local wheat_in, in_items = count_wheat_in()
  local wheat_self, self_items = count_wheat_self()

  -- 1.1.1 : Calculate how much wheat we can split. We want a max of 32 wheat in each slot.
  local splittable = math.min(
    32 - math.ceil(wheat_self / 3),
    math.floor(wheat_in / 3)
  )

  if splittable <= 0 then
    log("No wheat to split")
    return
  end

  log("Ordering", splittable, "wheat to 2,3,5")

  local input_cache = deep_copy(in_items)

  -- 1.2 : Push wheat from the input inventory to the turtle.

  local function push_n_wheat(n, to_slot)
    log("Pushing", n, "wheat to slot", to_slot)
    local to_remove = {}

    for slot, item in pairs(input_cache) do
      if item.name == "minecraft:wheat" then
        local to_push = math.min(n, item.count)
        add_queue(function()
          inv_in.pushItems(t_name, slot, to_push, to_slot)
        end)

        n = n - to_push

        item.count = item.count - to_push

        if item.count == 0 then
          to_remove[slot] = true
        end

        if n <= 0 then
          break
        end
      end
    end

    for slot in pairs(to_remove) do
      input_cache[slot] = nil
    end
  end

  local max_wheat_self = math.max(
    self_items[2] and self_items[2].count or 0,
    self_items[3] and self_items[3].count or 0,
    self_items[5] and self_items[5].count or 0
  )


  -- Equalize the wheat in slots 2,3,5
  -- This may cause overflow, which is why we keep max 32 wheat in each slot.
  if self_items[2] and self_items[2].count < max_wheat_self then
    -- Push the difference.
    push_n_wheat(max_wheat_self - (self_items[2].count or 0), 2)
  end

  if self_items[3] and self_items[3].count < max_wheat_self then
    -- Push the difference.
    push_n_wheat(max_wheat_self - (self_items[3].count or 0), 3)
  end

  if self_items[5] and self_items[5].count < max_wheat_self then
    -- Push the difference.
    push_n_wheat(max_wheat_self - (self_items[5].count or 0), 5)
  end

  -- Push the requested amount of wheat to the turtle.
  push_n_wheat(splittable, 2)
  push_n_wheat(splittable, 3)
  push_n_wheat(splittable, 5)

  run_queue()
end

--- Collect water.
---@return boolean success
local function collect_water()
  -- Stage 1: Check if we have a bucket in slot 1, and if it's already water.
  local items = update_inventory()

  -- 1.1: Has bucket?
  if not items[1] or not items[1].name:find("bucket") then
    return false
  end

  -- 1.2: Is it water?
  if items[1].name == "minecraft:water_bucket" then
    return true
  end

  -- Stage 2: Ensure slot 1 is selected.
  turtle.select(1)

  -- Stage 2: Attempt to collect water
  if not turtle.placeDown() then
    return false
  end

  -- Has water now?
  return fetch_inventory()[1].name == "minecraft:water_bucket"
end

--- Check that we have a bucket, if we do, ensure it's in slot 1.
---@return boolean has_bucket
local function check_bucket()
  local items = fetch_inventory()

  for slot, item in pairs(items) do
    if item.name:find("bucket") then
      if slot == 1 then
        return true
      end

      -- Otherwise, we need to move it into slot 1.

      -- Find the first open slot in the turtle's inventory.
      local open_slot = nil
      for i = 2, 16 do
        if not items[i] then
          open_slot = i
          break
        end
      end

      if not open_slot then
        return false
      end

      -- And push whatever is in slot 1 to that slot.
      turtle.select(1)
      turtle.transferTo(open_slot)

      -- Then, move the bucket to slot 1.
      turtle.select(slot)
      turtle.transferTo(1)

      turtle.select(1)
      return true
    end
  end

  return false
end

--#endregion utility

--#region UI

--- Update the status line
---@param text string
---@param color integer?
local function update_status(text, color)
  term.setCursorPos(1, 1)
  term.clearLine()
  if color then
    term.setTextColor(color)
  end

  term.write(("Status: %s"):format(text))

  if color then
    term.setTextColor(colors.white)
  end
end

--- Update craft count line.
---@param count integer
local function update_craft_count(count)
  term.setCursorPos(1, 2)
  term.clearLine()
  term.write(("Crafted %d times (this session)."):format(count))
end

--- Update secondary line.
---@param text string
local function update_secondary(text)
  term.setCursorPos(1, 3)
  term.clearLine()
  term.write(text)
end

--- Displays a countdown.
---@param time integer
local function countdown(time)
  for i = time, 1, -1 do
    update_secondary(("Next in %d second%s"):format(i, i == 1 and "" or "s"))
    sleep(1)
  end
  update_secondary("")
end

--#endregion UI

local t_inv_timer

--- Parallel thread that watches for turtle_inventory events, and marks the inventory as dirty.
local function watch_inventory()
  while true do
    os.pullEvent("turtle_inventory")
    inv_dirty = true

    update_secondary("Inventory updated!")
    t_inv_timer = os.startTimer(0.5)
  end
end

--- Parallel thread which clears the secondary message after a turtle inventory notification.
local function clear_secondary()
  while true do
    local _, timer_id = os.pullEvent("timer")
    if timer_id == t_inv_timer then
      update_secondary("")
    end
  end
end

--- Crafts wheat dough on repeat.
local function craft_wheat_dough()
  term.clear()

  -- Draw the divider
  term.setCursorPos(1, 4)
  term.setBackgroundColor(colors.gray)
  term.clearLine()
  term.setBackgroundColor(colors.black)

  local craft_count = 0
  update_status("Starting")
  update_craft_count(craft_count)

  while true do
    -- Stage 1: Check that we have a bucket.
    update_status("Checking for bucket")
    while not check_bucket() do
      update_status("Requires bucket!", colors.red)
      os.pullEvent("turtle_inventory")
    end

    -- Stage 1: Clean the inventory
    update_status("Cleaning inventory")
    clean_inventory()

    -- Stage 2: Get wheat
    update_status("Getting wheat")
    get_wheat()

    -- Stage 3: Collect water
    update_status("Collecting water")
    local crafted = false
    if collect_water() then
      -- Stage 4: Craft dough
      update_status("Crafting dough")
      crafted = turtle.craft()
    end

    -- Stage 5: Sleep
    if crafted then
      update_status("Crafted!", colors.green)
      craft_count = craft_count + 1
      update_craft_count(craft_count)
      sleep()
    else
      -- If we didn't craft anything, sleep for a while.
      update_status("Sleeping", colors.blue)
      countdown(10)
    end
  end
end

-- Start the program
parallel.waitForAny(
  watch_inventory,
  clear_secondary,
  craft_wheat_dough
)

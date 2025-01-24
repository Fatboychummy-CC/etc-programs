--- Crafts forever n ever

-- VALUES THE USER CAN CHANGE

--- The side of the turtle the modem is on.
---  -> Be careful not to place the modem on the same 
---  -> side as the crafting table, as it will block
---  -> access to the modem.
---@type "front"|"back"|"top"|"bottom"|"left"|"right"
local MODEM_SIDE = "front"

--- The name of the input inventory on the wired modem network.
---@type string
local INPUT_INV = "name of inventory here"

--- The names of the output inventories on the wired modem network.
---  -> Note that there is also the option to use the `OUTPUT_TYPE` variable below.
---  -> Items are pulled in round-robin fashion for more than one output inventory.
---@type string[] A list of strings, separated by commas.
local OUTPUT_INVS = {
  "name of inventory here",
  "name of inventory here",
}

--- Whether or not to pull items to all inventories of a given type, rather than specific inventories.
---@type boolean yay or nay
local USE_OUTPUT_TYPE = false

--- If `USE_OUTPUT_TYPE` is true, this is the type of inventory to push items to.
---  -> Avoid using the same type of inventory here as the input inventory!
---@type string `minecraft:chest`, `minecraft:furnace`, etc.
local OUTPUT_TYPE = "minecraft:furnace"

--- The target slot to output items to.
---  -> If left `nil`, will pull to all slots.
---@type integer?
local OUTPUT_SLOT = nil

--- The `modid:name` of the water bucket.
---@type string
local WATER_BUCKET = "minecraft:water_bucket"

--- The `modid:name` of the empty bucket.
---@type string
local BUCKET = "minecraft:bucket"

--- The `modid:name` of wheat.
---@type string
local WHEAT = "minecraft:wheat"

--- The `modid:name` of wheat dough.
---@type string
local WHEAT_DOUGH = "farmersdelight:wheat_dough"

--- The maximum items per slot of the output item in the output inventory.
---@type integer
local MAX_ITEMS_PER_SLOT = 64

--- The slots of the given inventories that should be ignored when checking if space is available within the inventory.
---@type table<string, table<integer, true>>
local BAD_SLOTS = {
  ["minecraft:furnace"] = {[2]=true, [3]=true}, -- Slot 2: Fuel, Slot 3: Output
  ["minecraft:smoker"] = {[2]=true, [3]=true} -- Slot 2: Fuel, Slot 3: Output
}

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
local invs_out = {}

-- Ensure the peripherals exist, and are the correct type
if not modem or not modem.getNameLocal then
  error("Wired modem could not be wrapped!", 0)
end

if not inv_in or not peripheral.hasType(INPUT_INV, "inventory") then
  error("Input inventory could not be wrapped!", 0)
end

if USE_OUTPUT_TYPE then
  -- Like peripheral.find, but only operates on whatever is connected to the modem.
  for _, inv_name in ipairs(modem.getNamesRemote()) do
    if peripheral.hasType(inv_name, OUTPUT_TYPE) then
      table.insert(invs_out, peripheral.wrap(inv_name))
    end
  end
else
  for _, inv_name in ipairs(OUTPUT_INVS) do
    table.insert(invs_out, peripheral.wrap(inv_name))
  end
end

if #invs_out == 0 then
  error("No output inventories found!", 0)
end

for _, inv in ipairs(invs_out) do
  if not inv or not peripheral.hasType(inv, "inventory") then
    error(("Output inventory %s could not be wrapped!"):format(peripheral.getName(inv)), 0)
  end
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

local last_inv_index = 0
local n_invs = #invs_out

--- Round-robin pull items to the output inventories.
--- Requires context of the output inventories.
--- Should only be called if there are more than one output inventories.
---@param from_slot integer The slot to move items from in the turtle.
---@param count integer The amount of items that need to be moved.
---@return boolean success
local function round_robin_pull(from_slot, count)
  -- Stage 1: Get the context of all output inventories.
  local context = {}
  for i, inv in ipairs(invs_out) do
    context[i] = {}
    add_queue(function()
      context[i].list = inv.list()
    end)
    add_queue(function()
      context[i].size = inv.size()
    end)
  end

  run_queue()

  -- Stage 2: From the last_inv_index, find an inventory with space.
  local success = false
  for i = 1, n_invs do
    last_inv_index = (last_inv_index % n_invs) + 1
    local inv = context[last_inv_index].list

  if OUTPUT_SLOT then
      -- Count only the items in the output slot.
      if not inv[OUTPUT_SLOT] or inv[OUTPUT_SLOT].count < MAX_ITEMS_PER_SLOT then
        local c_inv_index = last_inv_index
        add_queue(function()
          invs_out[c_inv_index].pullItems(t_name, from_slot, nil, OUTPUT_SLOT)
        end)

        local moved = math.min(count, MAX_ITEMS_PER_SLOT - (inv[OUTPUT_SLOT] or {count=0}).count)

        count = count - moved

        -- If we haven't moved enough items yet, continue.
        if count <= 0 then
          -- Otherwise stop.
          success = true
          break
        end
      end
    else
      -- See if there's any space at all in the inventory.
      local item_space = 0
      local p_type = peripheral.getType(invs_out[last_inv_index])
      for i = 1, context[last_inv_index].size do
        if not BAD_SLOTS[p_type] or not BAD_SLOTS[p_type][i] then 
          if not inv[i] then
            item_space = item_space + MAX_ITEMS_PER_SLOT
          elseif inv[i].name == WHEAT_DOUGH then
            item_space = item_space + MAX_ITEMS_PER_SLOT - inv[i].count
          end
        end
      end

      if item_space > 0 then
        add_queue(function()
    invs_out[last_inv_index].pullItems(t_name, from_slot)
        end)

        local moved = math.min(count, item_space)

        count = count - moved

        -- If we haven't moved enough items yet, continue.
        if count <= 0 then
          -- Otherwise stop.
          success = true
          break
        end
      end
  end
end

  run_queue()

  return success
end



--- Clean the inventory of any extra items.
local function clean_inventory()
  log("Cleaning out the inventory.")

  local items = update_inventory()

  -- Stage 1: Move wheat dough to the output inventories.
  for slot, item in pairs(items) do
    if item.name == WHEAT_DOUGH then
      if n_invs == 1 then
      add_queue(function()
          invs_out[1].pullItems(t_name, slot)
      end)
      else
        round_robin_pull(slot, item.count)
      end
    end
  end

  -- Stage 2: Move anything that shouldn't be in the turtle back into the input inventory.
  for slot, item in pairs(items) do
    if item and item.name ~= WHEAT_DOUGH then
    if slot == 1 then
      -- Slot 1 should be either a filled bucket or an empty bucket.
      if item and item.name ~= WATER_BUCKET and item.name ~= BUCKET then
        add_queue(function()
          inv_in.pullItems(t_name, 1)
        end)
      end
    elseif slot == 2 or slot == 3 or slot == 5 then
      -- Slots 2,3,5 should be wheat.
      if item and item.name ~= WHEAT then
        add_queue(function()
          inv_in.pullItems(t_name, slot)
        end)
      end
    else
      -- Other slots should be empty.
      if item then
        add_queue(function()
          inv_in.pullItems(t_name, slot)
        end)
        end
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
    if items[i] and items[i].name == WHEAT then
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
    if item.name == WHEAT then
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
    log("No", WHEAT, "to split")
    return
  end

  log("Ordering", splittable, WHEAT, "to 2,3,5")

  local input_cache = deep_copy(in_items)

  -- 1.2 : Push wheat from the input inventory to the turtle.

  local function push_n_wheat(n, to_slot)
    log("Pushing", n, WHEAT, "to slot", to_slot)
    local to_remove = {}

    for slot, item in pairs(input_cache) do
      if item.name == WHEAT then
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
  if not items[1] or (items[1].name ~= BUCKET and items[1].name ~= WATER_BUCKET) then
    return false
  end

  -- 1.2: Is it water?
  if items[1].name == WATER_BUCKET then
    return true
  end

  -- Stage 2: Ensure slot 1 is selected.
  turtle.select(1)

  -- Stage 2: Attempt to collect water
  if not turtle.placeDown() then
    return false
  end

  -- Has water now?
  return fetch_inventory()[1].name == WATER_BUCKET
end

--- Check that we have a bucket, if we do, ensure it's in slot 1.
---@return boolean has_bucket
local function check_bucket()
  local items = fetch_inventory()

  for slot, item in pairs(items) do
    if item.name == BUCKET or item.name == WATER_BUCKET then
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
  term.setTextColor(colors.black)
  term.write(('\x8c'):rep(tw))
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
local ok, err = pcall(
  parallel.waitForAny,
  watch_inventory,
  clear_secondary,
  craft_wheat_dough
)

if not ok then
  term.clear()
  term.setCursorPos(1, 1)
  term.setTextColor(colors.red)
  error(err, 0)
end
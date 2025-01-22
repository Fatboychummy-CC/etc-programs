--- Crafts wheat dough forever n ever

-- VALUES THE USER CAN CHANGE

local MODEM_SIDE = "front"
local INPUT_INV = "name_of_inventory_here"
local OUTPUT_INV = "name_of_inventory_here"

-- END OF USER VALUES

--#region initialization

-- Ensure we are running on a turtle.
if not turtle then
  error("This program must be run on a turtle!", 0)
end

-- Collect the peripherals
local modem = peripheral.wrap(MODEM_SIDE)
local inv_in = peripheral.wrap(INPUT_INV)
local inv_out = peripheral.wrap(OUTPUT_INV)

-- Ensure the peripherals exist, and are the correct type
if not modem or not peripheral.hasType(MODEM_SIDE, "peripheral_hub") then
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

--- If the inventory has changed, this will be true.
local inv_dirty = true

---@class ItemDetail
---@field name string
---@field count integer

--- The last known inventory state.
---@type table<integer, ItemDetail> May contain holes
local last_inv = {}

--- Updates the turtle's inventory.
---@return table<integer, ItemDetail> inventory
local function update_inventory()
  if not inv_dirty then
    return last_inv
  end

  local list = {}

  for i = 1, 16 do
    list[i] = inv_in.getItemDetail(i)
  end

  last_inv = list
  inv_dirty = false

  return list
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
  parallel.waitForAll(table.unpack(func_queue))
  inv_dirty = true
end

--- Clean the inventory of any extra items.
local function clean_inventory()
  local items = update_inventory()

  for slot, item in pairs(items) do
    if slot == 1 then
      -- Slot 1 should be either a filled bucket or an empty bucket.
      if item and not item.name:find("bucket") then
        add_queue(function()
          inv_out.pullItems(t_name, 1)
        end)
      end
    elseif slot >= 2 or slot <= 4 then
      -- Slots 2-4 should be wheat.
      if item and item.name ~= "minecraft:wheat" then
        add_queue(function()
          inv_out.pullItems(t_name, slot)
        end)
      end
    else
      -- Other slots should be empty.
      if item then
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

  for i = 2, 4 do
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

  local input_cache = deep_copy(in_items)

  -- 1.2 : Push wheat from the input inventory to the turtle.

  local function push_n_wheat(n, to_slot)
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
      end
    end

    for slot in pairs(to_remove) do
      input_cache[slot] = nil
    end
  end

  for slot = 2, 4 do
    push_n_wheat(splittable, slot)
  end

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
  return update_inventory()[1].name == "minecraft:water_bucket"
end

--#endregion utility

--- Crafts wheat dough on repeat.
local function craft_wheat_dough()
  while true do
    -- Stage 1: Clean the inventory
    clean_inventory()

    -- Stage 2: Get wheat
    get_wheat()

    -- Stage 3: Collect water
    if not collect_water() then
      error("Failed to collect water!", 0)
    end

    -- Stage 4: Craft dough
    turtle.craft()
  end
end

-- Start the program
craft_wheat_dough()

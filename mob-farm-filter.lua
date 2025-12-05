--- Simple script to filter out any useless items.

local trashcan = peripheral.wrap("top") --[[@as ccTweaked.peripheral.Inventory]]
local inv = peripheral.wrap("right") --[[@as ccTweaked.peripheral.Inventory]]
local saved = peripheral.wrap("front") --[[@as ccTweaked.peripheral.Inventory]]

local parallelism_handler = require("parallelism_handler")
local ph = parallelism_handler()
ph.limit = 200

---@alias filter fun(detailed_item: table): boolean, string?

---@type table<string, filter>
local destroy_filters = {
  ["minecraft:bow"] = function(detailed_item)
    if not detailed_item.enchantments then
      return true, "Unenchanted bow"
    end

    return false
  end,

  ["artifacts:flame_pendant"] = function()
    return true
  end,

  ["artifacts:plastic_drinking_hat"] = function()
    return true
  end,

  ["minecraft:tipped_arrow"] = function()
    return true
  end,

  ["minecraft:feather"] = function()
    return true
  end,

  ["minecraft:glass_bottle"] = function()
    return true
  end,

  ["minecraft:iron_ingot"] = function()
    return true
  end,

  ["minecraft:stick"] = function()
    return true
  end,

  ["minecraft:string"] = function()
    return true
  end,
  ["supplementaries:quiver"] = function()
    return true
  end,
  ["minecraft:potato"] = function()
    return true
  end,
  ["minecraft:sugar"] = function()
    return true
  end,
  ["minecraft:chicken"] = function()
    return true
  end,
}

---@type table<string, filter>
local save_filters = {
  ["minecraft:bow"] = function(detailed_item)
    if detailed_item.enchantments then
      return true, "Enchanted bow"
    end

    return false
  end,

  ["bhc:red_heart"] = function()
    return true, "Red heart"
  end,
  ["apotheosis:gem"] = function()
    return true, "Apotheosis gem"
  end,
  ["minecraft:glowstone_dust"] = function()
    return true, "Glowstone dust"
  end,
  ["minecraft:gunpowder"] = function()
    return true, "Gunpowder"
  end,
  ["minecraft:spider_eye"] = function()
    return true, "Spider eye"
  end,
}


--- Checks if a given item is to be filtered out.
---@param slot integer The inventory slot number.
---@return boolean is_trash True if the item should be trashed, false otherwise.
local function destroy_item(slot)
  local detailed_item = inv.getItemDetail(slot)
  if not detailed_item then
    return false
  end

  local filter_fn = destroy_filters[detailed_item.name]
  local is_trash, reason = false, nil
  if filter_fn then
    is_trash, reason = filter_fn(detailed_item)
  end
  reason = reason or "No reason supplied"

  if is_trash then
    term.setTextColor(colors.red)
    print("--", detailed_item.name, slot)
    term.setTextColor(colors.yellow)
    print("  ->", reason)
    term.setTextColor(colors.white)
  end

  return is_trash
end



--- Checks if a given item is to be kept.
---@param slot integer The inventory slot number.
---@return boolean is_saved True if the item should be kept, false otherwise.
local function save_item(slot)
  local detailed_item = inv.getItemDetail(slot)
  if not detailed_item then
    return false
  end

  local filter_fn = save_filters[detailed_item.name]
  local is_saved, reason = false, nil
  if filter_fn then
    is_saved, reason = filter_fn(detailed_item)
  end
  reason = reason or "No reason supplied"

  if not is_saved then
    -- Check if it's enchanted
    if detailed_item.enchantments then
      is_saved = true
      reason = "Enchanted item"
    end
  end

  if is_saved then
    term.setTextColor(colors.green)
    print("++", detailed_item.name, slot)
    term.setTextColor(colors.cyan)
    print("  +>", reason)
    term.setTextColor(colors.white)
  end

  return is_saved
end



--- Remove a random item stack from the inventory.
local function remove_random_item(size)
  while true do
    local slot = math.random(1, size)
    local item = inv.getItemDetail(slot)
    if item then
      if save_item(slot) then
        inv.pushItems(peripheral.getName(saved), slot)
      else
        inv.pushItems(peripheral.getName(trashcan), slot)
        term.setTextColor(colors.orange)
        print("~~ Removed random item:", item.name, slot)
        term.setTextColor(colors.white)
        return
      end
    end
  end
end



--- Count the number of items in a list.
---@param list ccTweaked.peripheral.itemList The list of items.
---@return integer count The number of items in the list.
local function count_items(list)
  local count = 0

  for _ in pairs(list) do
    count = count + 1
  end

  return count
end



--- Handle an entire inventory.
---@param inv ccTweaked.peripheral.Inventory The inventory to handle.
local function handle_inventory(inv)
  local size = inv.size()
  local list = inv.list()

  for slot = 1, size do
    if list[slot] then
      ph:add_task(function()
        if destroy_item(slot) then
          inv.pushItems(peripheral.getName(trashcan), slot)
        end
      end)
      ph:add_task(function()
        if save_item(slot) then
          inv.pushItems(peripheral.getName(saved), slot)
        end
      end)
    end
  end

  ph:execute()

  -- Ensure at least 10% free space
  list = inv.list()
  local item_count = count_items(list)
  local free_slots = size - item_count
  local required_free = math.ceil(size * 0.1)
  if free_slots < required_free then
    for i = 1, required_free - free_slots do
      remove_random_item(size)
    end
  end
end



--- Wait 10 seconds, displaying the countdown.
local function wait(n)
  local _, y = term.getCursorPos()
  for i = n, 1, -1 do
    term.setCursorPos(1, y)
    term.clearLine()
    term.write(("%d"):format(i))
    os.sleep(1)
  end
  term.setCursorPos(1, y)
  term.clearLine()
end



--- Main loop
while true do
  handle_inventory(inv)
  wait(10)
end

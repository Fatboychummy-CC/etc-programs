--[[
  Automatic Knowledge Researcher by Fatboychummy

  This uses RFTools Dimensions' Knowledge Holder and Researcher to automatically
  research all the lost knowledge held in the Knowledge Holder (and replaces the
  learned knowledge into the Knowledge Holder).

  The researcher can hold a full 64 stack of one type of lost knowledge, but
  only holds a single lost knowledge in its output. Because of this, the system
  will follow the following pattern:
  1. Insert as many lost knowledge items as possible into the researcher as possible.
  2. Check if the researcher has a lost knowledge item in its output.
  3. If it does, move the lost knowledge item into the Knowledge Holder.
    3.a) If it doesn't, wait for the researcher to finish researching, then complete this step.
  4. Repeat until the researcher has no more unresearched lost knowledge items.
]]

-- Constant for lost knowledge item names
-- This should cover all the lost knowledge items (common, uncommon, rare, legendary)
local LOST_KNOWLEDGE_PATTERN = "rftoolsdim:.+_lost_knowledge"

-- Find the Knowledge Holder and Researcher
local knowledge_holder = peripheral.find("rftoolsdim:knowledge_holder") --[[@as Inventory]]
local researcher = peripheral.find("rftoolsdim:researcher") --[[@as Inventory]]

-- Check if the Knowledge Holder and Researcher were found
if knowledge_holder == nil then
  printError("Knowledge Holder not found!")
  return
end

if researcher == nil then
  printError("Researcher not found!")
  return
end

---@class KnowledgeItem
---@field name string The name of the item
---@field count integer The number of items in the stack
---@field slot integer The slot number of the item

--- Collect a list of all lost knowledge in the knowledge holder that does not have nbt data (i.e. not researched)
---@return table<integer, KnowledgeItem> knowledge A table of all lost knowledge items in the knowledge holder
local function collect_knowledge()
  local knowledge = {}

  local list = knowledge_holder.list()
  local count = 0

  -- Loop through all the slots in the knowledge holder
  for slot, item in pairs(list) do
    -- Check if the item is a lost knowledge item (it should all be, but I don't know if other items can be inserted into the knowledge holder)
    if item.name:match(LOST_KNOWLEDGE_PATTERN) then
      -- Check if the item has nbt data (i.e. has been researched)
      if not item.nbt then
        -- Add the item to the knowledge table
        table.insert(knowledge, {name = item.name, count = item.count, slot = slot})
        count = count + item.count
      end
    end
  end

  print(("Found %d lost knowledge items without nbt data."):format(count))

  return knowledge
end

--- Check if there is an item in the output slot of the researcher
---@return boolean has_item True if there is an item in the output slot, false otherwise
local function has_item_in_output()
  return not not researcher.list()[2]
end

--- Check if the researcher has any lost knowledge items in its input slot
---@return boolean has_item True if there is an item in the input slot, false otherwise
local function has_item_in_input()
  return not not researcher.list()[1]
end

--- Move the item in the output slot of the researcher into the knowledge holder
---@return boolean success True if the item was moved, false otherwise
local function move_item_into_knowledge_holder()
  -- Check if there is an item in the output slot
  if has_item_in_output() then
    -- Move the item into the knowledge holder
    if researcher.pushItems(peripheral.getName(knowledge_holder), 2, 1) > 0 then
      print("Moved researched lost knowledge item into the Knowledge Holder.")
      return true
    end
  end

  return false
end

--- Move the lost knowledge items into the researcher
---@return boolean complete True if the researcher has no more lost knowledge items, false otherwise
local function move_knowledge_into_researcher()
  -- Collect all the lost knowledge items in the knowledge holder
  local knowledge = collect_knowledge()

  local marked = {}

  -- Loop through all the lost knowledge items
  for index, item in ipairs(knowledge) do
    -- Attempt to move the item into the researcher.
    local pushed = knowledge_holder.pushItems(peripheral.getName(researcher), item.slot, item.count)
    item.count = item.count - pushed

    if pushed > 0 then
      print(("Moved %d lost knowledge items into the researcher."):format(pushed))
    end

    -- If the item was successfully moved, mark it for removal from the knowledge table
    if item.count == 0 then
      table.insert(marked, index, 1)
    end
  end

  -- Remove all the items that were successfully moved into the researcher
  for _, index in ipairs(marked) do
    table.remove(knowledge, index)
  end

  return #knowledge == 0
end

--- Wait for the researcher to finish researching
local function wait_for_researcher()
  local flag = true
  -- Loop until the researcher has no more lost knowledge items
  while not has_item_in_output() do
    if flag then
      flag = false
      print("Researcher is researching...")
    end
    -- Wait for the researcher to finish researching
    sleep(0.05)
  end
  print("Researcher has finished researching.")
end

--- Main function: Combine everything
local function main()
  -- Loop until the researcher has no more lost knowledge items
  local initial = true

  while true do
    local complete = move_knowledge_into_researcher()

    if initial and complete then
      error("There is nothing to research!", 0)
    end
    initial = false

    -- Wait for the researcher to finish researching
    wait_for_researcher()

    -- Move the item in the output slot into the knowledge holder
    if not move_item_into_knowledge_holder() then
      -- The Knowledge Holder is full, wait for the player to empty it.
      printError("Knowledge Holder is full. Please empty it.")
      while not move_item_into_knowledge_holder() do
        sleep(5)
      end
    end

    sleep(0.05)

    -- If no more items can be sent from the knowledge holder, and no more items exist in the researcher, then all lost knowledge items have been researched.
    if complete and not has_item_in_input() and not has_item_in_output() then
      print("All lost knowledge items have been researched.")
      break
    end
  end
end

main()

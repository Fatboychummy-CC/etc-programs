--- Launcher program to launch computers by their IDs.
---
--- Requires my catppuccin library.
--- https://github.com/Fatboychummy-CC/Libraries/blob/main/catppuccin.lua

--- Create a file named `computer_data.lua` in the same directory as this program, then add the following:
--- ```lua
--- return {
---  [computer_id] = "Computer Name",
---  -- ...
--- }
--- ```
--- Of course, replace 'computer_id' and "Computer Name" with your actual computer ID and name.
--- The program will then display these, and allow you to select them as a list.

---@module 'periphemu'

local catppuccin = require "catppuccin"
local pal = catppuccin.set_palette "mocha"

-- I just typed random names and hit tab when copilot suggested them.
-- "Random" enough :)
local random_names = {
  "Alpha", "Bravo", "Charlie", "Delta", "Echo", "Foxtrot",
  "Golf", "Hotel", "India", "Juliet", "Kilo", "Lima",
  "Mike", "November", "Oscar", "Papa", "Quebec", "Romeo",
  "Sierra", "Tango", "Uniform", "Victor", "Whiskey", "X-ray",
  "Yankee", "Zulu",

  "Alex", "Sam", "Jordan", "Taylor", "Morgan", "Casey",
  "Riley", "Jamie", "Cameron", "Drew", "Ashley", "Bailey",
  "Dakota", "Emerson", "Finley", "Harper", "Jason", "Kendall",

  "Fox", "Raven", "Wolf", "Bear", "Hawk", "Tiger",
  "Eagle", "Lion", "Shark", "Panther", "Cobra", "Viper",
  "Jaguar", "Cougar", "Mustang", "Falcon", "Dragon", "Phoenix",
  "Griffin",

  "Beacon", "Comet", "Nova", "Orbit", "Pulsar", "Quasar",
  "Rocket", "Satellite", "Starlight", "Sunbeam", "Meteor",
  "Nebula", "Cosmos", "Galaxy", "Asteroid", "Eclipse",

  "Luna", "Celestia", "Twilight", "Aurora", "Solstice",
  "Equinox", "Zephyr", "Borealis", "Horizon", "Nimbus",
  "Stratus",

  "Bit", "Byte", "Unsigned Integer", "Boolean", "Function", "Loop",
  "Array", "Table", "String", "Variable", "Constant", "Module",
  "Class", "Object", "Method", "Property", "Event", "Thread",

  "Quantum", "Neutron", "Proton", "Electron", "Photon", "Gluon",
  "Boson", "Lepton", "Hadron", "Fermion", "Quark", "Muon",
  "Neutrino", "Graviton",
}

term.setBackgroundColor(pal.base)
term.setTextColor(pal.text)
term.clear()
term.setCursorPos(1, 1)

term.setBackgroundColor(pal.overlay_0)
term.clearLine()
term.write(" Computer Launcher")

local function draw_box(x, y, width, height, t_override)
  local txt = (' '):rep(width)

  local term = t_override or term

  for i = 0, height - 1 do
    term.setCursorPos(x, y + i)
    term.write(txt)
  end
end

local w, h = term.getSize()

local sw, sh = w - 2, h - 3
term.setBackgroundColor(pal.surface_0)
draw_box(2, 3, sw, sh) -- Main box

local main_win = window.create(term.current(), 3, 4, sw - 2, sh - 2)
main_win.setBackgroundColor(pal.surface_0)
main_win.setTextColor(pal.text)
main_win.clear()

local selector = '>'
local selected = 1
local scroll_index = 0
local computer_data = require "computer_data" --[[@as table<integer, string>]]

---@type {id: number, name: string}[]
local selections = {}
for id, name in pairs(computer_data) do
  table.insert(selections, { id = id, name = name })
end

table.sort(selections, function(a, b) return a.id < b.id end)

local longest_id = 0
local function recalculate_longest_id()
  for _, entry in ipairs(selections) do
    local id_length = #tostring(entry.id)
    if id_length > longest_id then
      longest_id = id_length
    end
  end
end
recalculate_longest_id()


local function rewrite_data_file()
  -- Write the computer_data.lua file.
  local file, err = fs.open("computer_data.lua", "w")
  if not file then
    error("Failed to open computer_data.lua for writing: " .. err, 0)
  end
  file.write(
    "return " .. textutils.serialize(computer_data)
  )
  file.close()

  -- Most likely we've changed something, so recalculate longest_id.
  longest_id = 0
  recalculate_longest_id()
end


local mww, mwh = main_win.getSize()



--- Display a message in the main window for a set duration.
---@param color number The text color of the message.
---@param text string The message to display.
---@param duration number? The duration to display the message for. Defaults to 2 seconds.
local function message(color, text, duration)
  main_win.setBackgroundColor(pal.crust)
  main_win.setTextColor(color)

  main_win.setCursorPos(3, mwh - 2)
  main_win.write(text)

  sleep(duration or 2)
end



--- Display an input page in the main window, prompting the user for information.
---@param title string The title of the input page.
---@param right_title string Displayed right-aligned in yellow on the same line as the title.
---@param texts string[] The messages to display to the user.
---@param response_is_number false Whether or not the response must be a number.
---@param can_be_nil false Whether or not the response can be nil/empty. Only checked if `response_is_number` is true.
---@return string response The user's response.
---@overload fun(title: string, right_title: string, texts: string[], response_is_number: true, can_be_nil: true): number?
---@overload fun(title: string, right_title: string, texts: string[], response_is_number: false, can_be_nil: true): string?
---@overload fun(title: string, right_title: string, texts: string[], response_is_number: true, can_be_nil: false): number
local function input_page(title, right_title, texts, response_is_number, can_be_nil)
  sleep() -- clear the char event from the event queue.

  main_win.setBackgroundColor(pal.surface_1)
  main_win.setTextColor(pal.text)
  main_win.clear()
  main_win.setCursorPos(1, 1)
  main_win.setBackgroundColor(pal.overlay_1)
  main_win.clearLine()
  main_win.write(" " .. title)

  main_win.setCursorPos(mww - #right_title - 1, 1)
  main_win.setTextColor(pal.yellow)
  main_win.write(right_title)

  main_win.setTextColor(pal.text)
  main_win.setBackgroundColor(pal.surface_1)
  for i, text in ipairs(texts) do
    main_win.setCursorPos(2, 2 + i)
    main_win.write(text)
  end

  local ypos = mwh - 2
  main_win.setBackgroundColor(pal.crust)
  draw_box(2, ypos - 1, mww - 2, 3, main_win)
  local write_win = window.create(main_win, 3, ypos, mww - 4, 1)
  write_win.setBackgroundColor(pal.crust)
  write_win.setTextColor(pal.blue)
  write_win.clear()

  local old = term.redirect(write_win)

  local function write_message(color, message)
    write_win.clear()
    write_win.setCursorPos(1, 1)
    write_win.setTextColor(color)
    write_win.write(message)
    sleep(2)
    write_win.setTextColor(pal.blue)
  end

  local response
  while true do
    write_win.clear()
    write_win.setCursorPos(1, 1)
    local input = read()

    if response_is_number then
      if tonumber(input) then
        response = tonumber(input)
        break
      elseif input == "" and can_be_nil then
        response = nil
        break
      else
        message(pal.red, "Invalid input. Please enter a number.")
      end
    else
      response = input
      break
    end
  end

  term.redirect(old)

  return response
end



local function new_computer()
  local id
  repeat
    id = input_page(
      "New Computer Wizard",
      "1/2",
      {
        "Enter desired computer ID.",
        "Leave empty for a random ID."
      },
      true,
      true
    )

    if not id then
      repeat
        id = math.random(1, 65535)
      until not computer_data[id]
      message(pal.green, "Assigned random ID: " .. id)
    elseif computer_data[id] then
      message(pal.red, "ID already in use. Please choose another.")
    end
  until id and not computer_data[id]

  local name = input_page(
    "New Computer Wizard",
    "2/2",
    {
      "Enter desired computer name.",
      "Leave empty for a random name."
    },
    false,
    true
  )
  if name == "" then
    name = random_names[math.random(1, #random_names)]
    message(pal.green, "Assigned random name: " .. name)
  end

  computer_data[id] = name
  table.insert(selections, { id = id, name = name })
  table.sort(selections, function(a, b) return a.id < b.id end)

  rewrite_data_file()
end



local function select_computer()
  local selection = scroll_index + selected
  if selections[selection] then
    local id = selections[selection].id
    main_win.setBackgroundColor(pal.base)
    main_win.clear()
    main_win.setCursorPos(2, 2)

    if periphemu.create(id, "computer") then
      main_win.setTextColor(pal.blue)
      main_win.write("Launched computer with ID " .. id)
    else
      main_win.setTextColor(pal.red)
      main_win.write("Failed to launch computer with ID " .. id .. ".")
      main_win.setCursorPos(2, 4)
      main_win.write("Is that computer already running?")
    end

    sleep(3)
  end
end

local function edit_computer()
  local selection = scroll_index + selected
  if selections[selection] then
    local id = selections[selection].id

    local name = input_page(
      "Edit Computer",
      "",
      {
        ("Current name: %s"):format(computer_data[id]),
        "Enter new name for computer ID " .. id .. ".",
        "Leave empty to keep current name."
      },
      false,
      true
    )

    if name ~= "" then
      computer_data[id] = name
      for _, entry in ipairs(selections) do
        if entry.id == id then
          entry.name = name
          break
        end
      end
      message(pal.green, "Updated computer name.")
    end

    rewrite_data_file()
  end
end



local function remove_computer()
  local selection = scroll_index + selected
  if selections[selection] then
    local id = selections[selection].id

    local response = input_page(
      "Remove Computer",
      "",
      {
        "Are you sure you want to remove:",
        ("  ID: %d | Name: %s"):format(id, computer_data[id]),
        "",
        "Type 'YES' to confirm.",
        "Case sensitive."
      },
      false,
      true
    )

    if response == "YES" then
      computer_data[id] = nil
      table.remove(selections, selection)
      message(pal.green, "Removed computer.")
      rewrite_data_file()
    else
      message(pal.yellow, "Cancelled removal.")
    end
  end
end



local function refresh()
  main_win.setVisible(false) -- Stop updating the screen
  main_win.setBackgroundColor(pal.surface_0)
  main_win.clear()

  local to_display = {}
  for i = scroll_index + 1, mwh + scroll_index do
    if selections[i] then
      table.insert(to_display, selections[i])
    end
  end

  for i = 1, #to_display do
    local entry = to_display[i]
    main_win.setCursorPos(1, i)
    if i == selected then
      main_win.setTextColor(pal.yellow)
      main_win.write(selector .. ' ')
      main_win.setBackgroundColor(pal.mantle)
      main_win.setTextColor(pal.blue)
    else
      main_win.setBackgroundColor(pal.surface_0)
      main_win.setTextColor(pal.text)
      main_win.write('  ')
    end

    main_win.write(("[%%%ds] : %%s"):format(longest_id):format(entry.id, entry.name))
  end

  main_win.setVisible(true) -- Resume updating the screen

  --[[ Debug information
  term.setBackgroundColor(pal.base)
  term.setCursorPos(1, h)
  term.clearLine()
  term.setTextColor(pal.text)
  term.write(("Sel: %d | Scroll: %d | Total: %d"):format(selected, scroll_index, #selections))--]]
end

local keys_held = {}

local function modifiers()
  while true do
    local event, key = os.pullEvent()

    if event == "key_up" then
      keys_held[key] = nil
    elseif event == "key" then
      keys_held[key] = true
    end
  end
end

local function main()
  while true do
    refresh()
    local _, key = os.pullEvent("key")

    if key == keys.up or key == keys.w then
      if selected > 1 then
        selected = selected - 1
      elseif scroll_index > 0 then
        scroll_index = scroll_index - 1
      else
        -- At the top, rotate around.
        scroll_index = math.max(0, #selections - mwh)
        selected = math.min(mwh, #selections)
      end
    elseif key == keys.down or key == keys.s then
      if scroll_index + selected < #selections then
        if selected < mwh then
          selected = selected + 1
        else
          scroll_index = scroll_index + 1
        end
      else
        -- At the bottom, rotate around.
        scroll_index = 0
        selected = 1
      end
    elseif key == keys.enter or key == keys.space then
      select_computer()
    elseif key == keys.n and keys_held[keys.leftShift] then
      new_computer()
      selected = 1
      scroll_index = 0
    elseif key == keys.e and keys_held[keys.leftShift] then
      edit_computer()
    elseif key == keys.r and keys_held[keys.leftShift] then
      remove_computer()
      selected = 1
      scroll_index = 0
    elseif key == keys.q and keys_held[keys.leftShift] then
      break
    end
  end
end

parallel.waitForAny(main, modifiers)

catppuccin.reset_palette()

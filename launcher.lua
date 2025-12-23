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
local computer_data = require "computer_data"

local selections = {}
for id, name in pairs(computer_data) do
  table.insert(selections, { id = id, name = name })
end

table.sort(selections, function(a, b) return a.id < b.id end)

local longest_id = 0
for _, entry in ipairs(selections) do
  local id_length = #tostring(entry.id)
  if id_length > longest_id then
    longest_id = id_length
  end
end



local mww, mwh = main_win.getSize()



local function new_computer()
  sleep() -- clear the char event from the event queue.

  main_win.setBackgroundColor(pal.surface_1)
  main_win.setTextColor(pal.text)
  main_win.clear()
  main_win.setCursorPos(1, 1)
  main_win.setBackgroundColor(pal.overlay_1)
  main_win.clearLine()
  main_win.write(" New Computer Wizard")

  main_win.setCursorPos(mww - 3, 1)
  main_win.setTextColor(pal.yellow)
  main_win.write('1/2')
  main_win.setTextColor(pal.text)

  main_win.setBackgroundColor(pal.surface_1)
  main_win.setCursorPos(2, 3)
  main_win.write("Enter desired computer ID.")
  main_win.setCursorPos(2, 4)
  main_win.write("Leave empty for a random ID.")
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

  local id
  while true do
    write_win.clear()
    write_win.setCursorPos(1, 1)
    local input = read()

    if input == "" then
      repeat
        id = math.random(1, 65535)
      until not computer_data[id]

      write_message(pal.green, "Assigned random ID: " .. id)
    elseif tonumber(input) then
      id = tonumber(input)
    else
      write_message(pal.red, "Invalid ID. Please enter a number.")
    end

    if id then
      if computer_data[id] then
        write_message(pal.red, "ID already in use. Please choose another.")
      else
        break
      end
    end
  end
  ---@cast id -nil

  -- what even is code reuse anyways
  main_win.setBackgroundColor(pal.surface_1)
  main_win.setTextColor(pal.text)
  main_win.clear()
  main_win.setCursorPos(1, 1)
  main_win.setBackgroundColor(pal.overlay_1)
  main_win.clearLine()
  main_win.write(" New Computer Wizard")

  main_win.setCursorPos(mww - 3, 1)
  main_win.setTextColor(pal.yellow)
  main_win.write('2/2')
  main_win.setTextColor(pal.text)

  main_win.setBackgroundColor(pal.surface_1)
  main_win.setCursorPos(2, 3)
  main_win.write("Enter desired computer name.")
  main_win.setCursorPos(2, 4)
  main_win.write("Leave empty for a random name.")
  local ypos = mwh - 2
  main_win.setBackgroundColor(pal.crust)
  draw_box(2, ypos - 1, mww - 2, 3, main_win)

  local name
  while true do
    write_win.clear()
    write_win.setCursorPos(1, 1)
    local input = read()

    if input == "" then
      name = random_names[math.random(1, #random_names)]
      write_message(pal.green, "Assigned random name: " .. name)
    else
      name = input
    end

    if name then
      break
    end
  end

  term.redirect(old)

  computer_data[id] = name
  table.insert(selections, { id = id, name = name })
  table.sort(selections, function(a, b) return a.id < b.id end)

  -- Write the computer_data.lua file.
  local file, err = fs.open("computer_data.lua", "w")
  if not file then
    error("Failed to open computer_data.lua for writing: " .. err, 0)
  end
  file.write(
    "return " .. textutils.serialize(computer_data)
  )
  file.close()
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
  elseif key == keys.n then
    new_computer()
  elseif key == keys.q then
    break
  end
end

catppuccin.reset_palette()

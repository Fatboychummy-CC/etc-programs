--- Simple program to be used as an installer script. Copy to repos and insert what is needed.

local to_get = {
  "extern:filename.lua:https://url.url/", -- if you need an external url
  "paste:filename.lua:pastecode", -- to download from pastebin
  "L:filename.lua:filename_on_repo.lua", -- Shorthand to download from the Fatboychummy-CC/Libraries repository.
  "E:filename.lua:filename_on_repo.lua" -- Shorthand to download from the Fatboychummy-CC/etc-programs repository.
}
local program_name = ""
local pinestore_id = nil -- Set this to the ID of the pinestore project if you wish to note to pinestore that a download has occurred.

-- #########################################

local RAW_URL = "https://raw.githubusercontent.com/Fatboychummy-CC/Libraries/main/"
local PASTE_URL = "https://pastebin.com/raw/"
local PINESTORE_DOWNLOAD_ENDPOINT = "https://pinestore.cc/api/log/download"
local p_dir = ... or fs.getDir(shell.getRunningProgram())

local function print_warning(...)
  term.setTextColor(colors.orange)
  print(...)
  term.setTextColor(colors.white)
end

local function download_file(url, filename)
  print("Downloading", filename)
  local h_handle, err = http.get(url) --[[@as Response]]
  if h_handle then
    local data = h_handle.readAll()
    h_handle.close()

    local f_handle, err2 = fs.open(fs.combine(p_dir, filename), 'w') --[[@as WriteHandle]]
    if f_handle then
      f_handle.write(data)
      f_handle.close()
      print("Done.")
      return
    end
    printError(url)
    error(("Failed to write file: %s"):format(err2), 0)
  end
  printError(url)
  error(("Failed to connect: %s"):format(err), 0)
end

local function get(...)
  local remotes = table.pack(...)

  for i = 1, remotes.n do
    local remote = remotes[i]

    local extern_file, extern_url = remote:match("^extern:(.-):(.+)$")
    local paste_file, paste = remote:match("^paste:(.-):(.+)$")
    local local_file, remote_file = remote:match("^L:(.-):(.+)$")
    if not local_file then
      local_file, remote_file = remote:match("^E:(.-):(.+)$")
    end

    if extern_file then
      -- downlaod from external location
      download_file(extern_url, extern_file)
    elseif paste_file then
      -- download from pastebin
      local cb = ("%x"):format(math.random(0, 1000000))
      download_file(PASTE_URL .. textutils.urlEncode(paste) .. "?cb=" .. cb, paste_file)
    elseif local_file then
      -- download from main repository.
      download_file(RAW_URL .. remote_file, local_file)
    else
      error(("Could not determine information for '%s'"):format(remote), 0)
    end
  end
end

-- Installation is from the installer's directory.
if p_dir:match("^rom") then
  error("Attempting to install to the ROM. Please rerun but add arguments for install location (or run the installer script in the folder you wish to install to).", 0)
end

write(("Going to install to:\n  /%s\n\nIs this where you want it to be installed? (y/n): "):format(fs.combine(p_dir, "*")))

local key
repeat
  local _, _key = os.pullEvent("key")
  key = _key
until key == keys.y or key == keys.n

if key == keys.y then
  print("y")
  sleep()
  print(("Installing %s."):format(program_name))
  get(table.unpack(to_get))

  if type(pinestore_id) == "number" then
    local handle, err = http.post(
      PINESTORE_DOWNLOAD_ENDPOINT,
        textutils.serializeJSON({
          projectId = pinestore_id,
        })
    )
    if handle then
      local data = handle.readAll()
      handle.close()

      local success, response = pcall(textutils.unserializeJSON, data)
      if not success or not response then
        print_warning("Failed to parse response from pinestore.")
      end

      if response and not response.success then
        print_warning("Failed to note to pinestore that a download has occurred.")
        print_warning(response.message)
      end
    else
      print_warning("Failed to connect to pinestore.")
    end
  end
else
  print("n")
  sleep()
  error("Installation cancelled.", 0)
end
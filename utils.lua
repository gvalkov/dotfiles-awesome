local naughty = require('naughty')
local awful   = require('awful')
local gears   = require('gears')

local freedesktop = {}
local freedesktop_utils = require('freedesktop.utils')
local confdir = awful.util.getdir('config')

local util = {}

-- Check if awesome encountered an error during startup and fell back
-- to another config
function util.handle_startup_errors(awesome)
   if awesome.startup_errors then
      local fh = io.open(awful.util.getdir('config') .. '/error.log', 'w')
      naughty.notify({ preset = naughty.config.presets.critical,
                       title = "Oops, there were errors during startup!",
                       text = awesome.startup_errors })
      fh:write(awesome.startup_errors..'\n')
   end
end

-- Handle runtime errors after startup
function util.handle_runtime_errors(awesome)
   local in_error = false
   local fh = io.open(awful.util.getdir('config') .. '/error.log', 'w')
   awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true
        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = err })
        fh:write(err..'\n')
        in_error = false
    end)
end

function util.raise_and_focus(idx)
   awful.client.focus.byidx(idx)
   if client.focus then client.focus:raise() end
end

function util.spawn(cmd)
   return function ()
      awful.util.spawn(cmd)
   end
end

function util.loadfile(path)
   local f = assert(loadfile(path))
   return f()
end

function util.icon(name)
   return freedesktop_utils.lookup_icon({icon = name})
end

function util.set_wallpaper(path, screen)
    for s = 1, screen.count() do
        gears.wallpaper.maximized(path, s, true)
    end
end

function util.load_or_create_freedesktop_menu()
   local menu = confdir..'/.serialized-menu.lua'
   local script = confdir..'/libexec/create-freedesktop-menu.lua'

   local loadmenu = function ()
      local fn, err = loadstring(io.open(menu):read())
      if err then
         return nil
      else
         print('loaded freedesktop menu from: '..menu)
         return fn()
      end
   end

   local create = function ()
      os.execute(script..' > '..menu)
      print('serialized freedesktop menu to: '..menu)
      return loadmenu()
   end

   if awful.util.file_readable(menu) then
      local menu_t = loadmenu()
      if menu_t == nil then
         return create()
      else
         return menu_t
      end
   else
      return create()
   end
end

function util.split(s, sep)
   if sep == nil then
      sep = "%s"
   end

   local res = {}
   local i = 1
   for m in string.gmatch(s, '([^' .. sep ..  ']+)') do
      res[i] = m
      i = i + 1
   end
   return res
end

function util.list_firefox_profiles(ini)
   if ini == nil then
      ini = os.getenv('HOME')..'/.mozilla/firefox/profiles.ini'
   end

   local res = {}
   print(ini)
   if awful.util.file_readable(ini) then
      for line in io.lines(ini) do
         local _, _, name = line:find('^Name=(.*)')

         if name ~= nil then
            table.insert(res, name)
         end
      end
   end

   return res
end

function util.firefox_profiles_menu(ini)
   local profiles = util.list_firefox_profiles(ini)
   local menu = {}

   for n, name in ipairs(profiles) do
      local item = {name, 'firefox -P '..name, util.icon('firefox')}
      table.insert(menu, item)
   end

   return menu
end

function util.movetotag(i)
   if client.focus and tags[client.focus.screen][i] then
      awful.client.movetotag(tags[client.focus.screen][i])
   end
end

function util.viewonly(i)
   local screen = mouse.screen
   local t = tags[screen][i]

   if awful.tag.selected(screen) == t then
      awful.tag.history.restore()
      return
   end

   if t then
      awful.tag.viewonly(t)
   end
end

function util.viewtoggle(i)
   local screen = mouse.screen
   if tags[screen][i] then
       awful.tag.viewtoggle(tags[screen][i])
   end
end

function util.toggletag(i)
   if client.focus and tags[client.focus.screen][i] then
      awful.client.toggletag(tags[client.focus.screen][i])
   end
end

function util.hjklfocus_and_raise(direction)
   awful.client.focus.bydirection(direction)
   if client.focus then client.focus:raise() end
end

--- http://awesome.naquadah.org/wiki/Run_or_raise
-- Returns true if all pairs in table1 are present in table2
local function match(table1, table2)
   for k, v in pairs(table1) do
      if table2[k] ~= v and not table2[k]:find(v) then
         return false
      end
   end
   return true
end

--- Spawns cmd if no client can be found matching properties
-- If such a client can be found, pop to first tag where it is visible, and give it focus
-- @param cmd the command to execute
-- @param properties a table of properties to match against clients.  Possible entries: any properties of the client object
function util.run_or_raise(cmd, properties)
   local clients = client.get()
   local focused = awful.client.next(0)
   local findex = 0
   local matched_clients = {}
   local n = 0
   for i, c in pairs(clients) do
      --make an array of matched clients
      if match(properties, c) then
         n = n + 1
         matched_clients[n] = c
         if c == focused then
            findex = n
         end
      end
   end
   if n > 0 then
      local c = matched_clients[1]
      -- if the focused window matched switch focus to next in list
      if 0 < findex and findex < n then
         c = matched_clients[findex+1]
      end
      local ctags = c:tags()
      if #ctags == 0 then
         -- ctags is empty, show client on current tag
         local curtag = awful.tag.selected()
         awful.client.movetotag(curtag, c)
      else
         -- Otherwise, pop to first tag client is visible on
         awful.tag.viewonly(ctags[1])
      end
      -- And then focus the client
      client.focus = c
      c:raise()
      return
   end
   awful.util.spawn(cmd)
end

return util

-- awesome imports
awful = require('awful')
gears = require('gears')
rules = require('awful.rules')
wibox = require('wibox')
naughty = require('naughty')
menubar = require('menubar')
autofocus = require('awful.autofocus')
beautiful = require('beautiful')

-- vendor imports
hints = require('lib.hints')
scratch = require('scratch')

-- user imports
ezconfig = require('ezconfig')
sessionmenu = require('sessionmenu')
utils = require('utils')
user_layouts = require('layouts')

-- error handling
utils.handle_startup_errors(awesome)
utils.handle_runtime_errors(awesome)

-- theming
beautiful.init(awful.util.getdir('config') .. '/themes/mine/theme.lua')

-- hints
hints.charoder = 'jkluiopyhnmfdsatgvcewqzx1234567890'
hints.init()

-- globals
TERMINAL = 'gnome-terminal'
FILE_MANAGER = 'dolphin'
EDITOR_CMD = 'emacsclient -c'

previous_tag_layout = awful.layout.suit.tile

local layouts = {
   awful.layout.suit.tile,
   awful.layout.suit.tile.left,
   awful.layout.suit.tile.bottom,
   awful.layout.suit.tile.top,
   awful.layout.suit.fair,
   awful.layout.suit.fair.horizontal,
   awful.layout.suit.max,
   awful.layout.suit.max.fullscreen,
}

-- tags = {
--    [1] = awful.tag({ 1, 'a', 2, 3, 4, 5, 6, 7, 8, 9 }, 2, layouts[1]),
--    [2] = awful.tag({ '1:skype', '2:mail', '3:org', 4, 5, 6, 7, 8, 9 }, 1, layouts[1]),
-- }

-- awful.tag.setproperty(tags[1][12], 'mwfact', 0.13)
-- awful.tag.setproperty(tags[1][11], 'mwfact', 1-0.13)

tags = {}

for s = 1, screen.count() do
    tags[s] = awful.tag({ '1', '2', '3', '4', '5', '6', '7', '8', '9', 'F1', 'F2', 'F3', 'F4'}, s, layouts[1])
end

-- menus
awful.menu.menu_keys['back'] = {'BackSpace', 'Left'}
menus = {}

menus.awesome = {
   { 'manual', TERMINAL .. ' -e man awesome' },
   { '&edit config', EDITOR_CMD .. ' ' .. awesome.conffile },
   { '&restart', awesome.restart },
   { '&quit', awesome.quit }
}

menus.browsers = {
   { '&firefox', 'firefox', utils.icon('firefox') },
   { 'ff &private', 'firefox -private-window', utils.icon('firefox') },
   { 'ff p&rofile', utils.firefox_profiles_menu(), utils.icon('firefox') },
   { '&chromium', 'chromium', utils.icon('chromium') },
   { 'c&hrome', 'google-chrome', utils.icon('google-chrome') },
}

menus.main = awful.menu({
   items = { { '&browsers', menus.browsers },
             { '&awesome', menus.awesome, beautiful.awesome_icon },
             { '&session', sessionmenu.menu() },
             { 'open terminal', TERMINAL }
   }
})

menubar.utils.terminal = TERMINAL

-- widgets
widgets = {}

widgets.clock = awful.widget.textclock()
widgets.menu_launcher = awful.widget.launcher({
     image = beautiful.awesome_icon,
     menu = menus.main })

widgets.taglist = {}
widgets.taglist.buttons = ezconfig.btntable.join({
   [1] = awful.tag.viewonly,
   ['M-1'] = awful.client.movetotag,
   [3] = awful.tag.viewtoggle,
   ['M-3'] = awful.client.toggletag,
   [4] = function(t) awful.tag.viewnext(awful.tag.getscreen(t)) end,
   [5] = function(t) awful.tag.viewprev(awful.tag.getscreen(t)) end
})

widgets.taglist.new = function(s)
   return awful.widget.taglist(
      s, awful.widget.taglist.filter.all,
      widgets.taglist.buttons
   )
end

widgets.tasklist = {}
widgets.tasklist.buttons = ezconfig.btntable.join({
    [1] = function (c)
       if c == client.focus then
          c.minimized = true
       else
          -- Without this, the following
          -- :isvisible() makes no sense
          c.minimized = false
          if not c:isvisible() then
             awful.tag.viewonly(c:tags()[1])
          end
          -- This will also un-minimize
          -- the client, if needed
          client.focus = c
          c:raise()
       end
   end,
   [3] = function ()
      if instance then
         instance:hide()
         instance = nil
      else
         instance = awful.menu.clients({ width=250 })
      end
   end,
   [4] = {utils.raise_and_focus, 1},
   [5] = {utils.raise_and_focus, -1},
})

widgets.tasklist.new = function(s)
    return awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags,
                                 widgets.tasklist.buttons)
end

widgets.layoutbox = {}
widgets.layoutbox.new = function(s)
    local l = awful.widget.layoutbox(s)
    l:buttons(ezconfig.btntable.join({
         [1] = { awful.layout.inc, layouts, 1 },
         [3] = { awful.layout.inc, layouts, -1 },
         [4] = { awful.layout.inc, layouts, 1 },
         [5] = { awful.layout.inc, layouts, -1 }
    }))

   return l
end


widgets.prompts = {}
wiboxes = {}

for s = 1, screen.count() do
    widgets.prompts[s] = awful.widget.prompt()
    widgets.layoutbox[s] = widgets.layoutbox.new(s, layouts)
    widgets.taglist[s] = widgets.taglist.new(s)
    widgets.tasklist[s] = widgets.tasklist.new(s)
    wiboxes[s] = awful.wibox({ position = "top", screen = s })

    -- Widgets that are aligned to the left
    local left_layout = wibox.layout.fixed.horizontal()
    left_layout:add(widgets.menu_launcher)
    left_layout:add(widgets.taglist[s])
    left_layout:add(widgets.prompts[s])

    -- Widgets that are aligned to the right
    local right_layout = wibox.layout.fixed.horizontal()
    if s == 1 then right_layout:add(wibox.widget.systray()) end
    right_layout:add(widgets.clock)
    right_layout:add(widgets.layoutbox[s])

    -- Now bring it all together (with the tasklist in the middle)
    local layout = wibox.layout.align.horizontal()
    layout:set_left(left_layout)
    layout:set_middle(widgets.tasklist[s])
    layout:set_right(right_layout)

    wiboxes[s]:set_widget(layout)
end

-- compute the maximum number of digit we need, limited to 9
keynumber = 0
for s = 1, screen.count() do
   keynumber = math.min(9, math.max(#tags[s], keynumber))
end


-- mouse bindings for the root window
root.buttons(ezconfig.btntable.join({
   [3] = function () menus.main:toggle() end,
   [4] = awful.tag.viewnext,
   [5] = awful.tag.viewprev
}))

-- mouse buttons for clients
clientbuttons = ezconfig.btntable.join({
   ['1'] = function (c) client.focus = c; c:raise() end,
   ['M-1'] = awful.mouse.client.move,
   ['M-3'] = awful.mouse.client.resize})

-- mouse-only tab navigation
firefoxbuttons = ezconfig.btntable.join({
   ['C-9'] = function (c)
      root.fake_input('key_press', 37);   root.fake_input('key_press', 117)
      root.fake_input("key_release", 37); root.fake_input('key_release', 117)
      root.fake_input('key_press', 37)
   end,
   ['C-8'] = function (c)
      root.fake_input('key_press', 37);   root.fake_input('key_press', 112)
      root.fake_input("key_release", 37); root.fake_input('key_release', 112)
      root.fake_input('key_press', 37)
   end,
})

-- key bindings
globalkeys = ezconfig.keytable.join({
   -- navigation
   ['M-<Left>'] = awful.tag.viewprev,
   ['M-<Right>'] = awful.tag.viewnext,

   ['M-S-<Left>'] = function (c)
      local curidx = awful.tag.getidx()
      local screen_tags = tags[client.focus.screen]
      if curidx == 1 then
         awful.client.movetotag(screen_tags[#screen_tags])
      else
         awful.client.movetotag(screen_tags[curidx - 1])
      end
   end,

   ['M-S-<Right>'] = function (c)
      local curidx = awful.tag.getidx()
      local screen_tags = tags[client.focus.screen]
      if curidx == #screen_tags then
         awful.client.movetotag(screen_tags[1])
      else
         awful.client.movetotag(screen_tags[curidx + 1])
      end
   end,

   ['M-`'] = awful.tag.history.restore,
   ['M-j'] = {utils.raise_and_focus, 1},
   ['M-k'] = {utils.raise_and_focus, -1},
   ['M-,'] = hints.focus,

   -- layout
   ['M-S-j'] = {awful.client.swap.byidx, 1},
   ['M-S-k'] = {awful.client.swap.byidx, -1},
   ['M-C-j'] = {awful.screen.focus_relative, 1},
   ['M-C-k'] = {awful.screen.focus_relative, -1},
   ['M-u']   = awful.client.urgent.jumpto,
   ['M-<Tab>'] =
      function ()
         awful.client.focus.history.previous()
         if client.focus then client.focus:raise() end
      end,

   -- screens
   ['M-q'] = {awful.screen.focus, 1},
   ['M-S-q'] = function (c) awful.client.movetoscreen(c, 1) end,
   ['M-w'] = {awful.screen.focus, 2},
   ['M-S-w'] = function (c) awful.client.movetoscreen(c, 2) end,

   -- programs
   ['M-a'] = utils.spawn(TERMINAL),
   ['M-S-C-a'] = utils.spawn(TERMINAL .. ' --role gnome-terminal-floating'),
   ['M-f'] = utils.spawn('firefox'),
   ['M-t'] = utils.spawn(FILE_MANAGER),
   ['M-S-t'] = utils.spawn(TERMINAL .. ' -e ranger'),
   ['M-g'] = utils.spawn('gvim'),
   ['M-e'] = utils.spawn('emacsclient -c'),

   -- awesome actions
   ['M-C-S-q'] = awesome.quit,
   ['M-C-q'] = awesome.restart,
   ['M-m'] = function () menus.main:show() end,
   ['M-<Menu>'] = function () menus.main:show() end,

   -- scratchpads
   ['M-S-i'] = {scratch.drop, 'ipython-qt', 'top', 'center', 0.5, 1, false},
   ['M-S-a'] = {scratch.drop, TERMINAL, 'top', 'center', 0.5, 1, false},

   -- master windows, columns and ratios
   ['M-l'] =   {awful.tag.incmwfact, 0.05},
   ['M-h'] =   {awful.tag.incmwfact, -0.05},
   ['M-S-h'] = {awful.tag.incnmaster, 1},
   ['M-S-l'] = {awful.tag.incnmaster, -1},
   ['M-C-h'] = {awful.tag.incncol, 1},
   ['M-C-l'] = {awful.tag.incncol, -1},
   ['M-<space>'] = {awful.layout.inc, layouts, 1},
   ['M-S-<space>'] = {awful.layout.inc, layouts, -1},
   ['M-s'] = function ()
      if awful.layout.get() == awful.layout.suit.max.fullscreen then
         awful.layout.set(previous_tag_layout)
      else
         previous_tag_layout = awful.layout.get()
         awful.layout.set(awful.layout.suit.max.fullscreen)
      end
   end,
   ['M-C-n'] = awful.client.restore,

   -- prompts
   -- ['M-r'] = function () widgets.prompts[mouse.screen]:run() end,
   ['M-r'] = utils.spawn('rofi -show run'),
   ['M-x'] =
      function ()
         awful.prompt.run(
            {prompt = "Run Lua code: " },
            widgets.prompts[mouse.screen].widget,
            awful.util.eval, nil,
            awful.util.getdir("cache") .. "/history_eval")
      end,
})

-- client key bindings
clientkeys = ezconfig.keytable.join({
   ['M-b'] = function (c) c.fullscreen = not c.fullscreen end,
   ['M-c'] = function (c) c:kill() end,
   ['M-C-<space>'] = awful.client.floating.toggle,
   ['M-C-<Return>'] = function (c) c:swap(awful.client.getmaster()) end,
   ['M-o'] = awful.client.movetoscreen,
   ['M-z'] = function (c) c.ontop = not c.ontop end,
   ['M-n'] = function (c) c.minimized = true end,
   ['M-C-m'] =
      function (c)
         c.maximized_horizontal = not c.maximized_horizontal
         c.maximized_vertical   = not c.maximized_vertical
      end,
})


-- tag navigation keys
for i=1, keynumber do
   globalkeys = awful.util.table.join(globalkeys, ezconfig.keytable.join({
   ['M-#'..i+9] =  {utils.viewonly, i},
   ['M-C-#'..i+9] = {utils.viewtoggle, i},
   ['M-S-#'..i+9] = {utils.movetotag, i},
   ['M-C-S-#'..i+9] = {utils.toggletag, i},
   }))
end


-- custom tag navigation keys
globalkeys = awful.util.table.join(globalkeys, ezconfig.keytable.join({
   ['M-<F1>'] = {utils.viewonly, 10},
   ['M-<F2>'] = {utils.viewonly, 11},
   ['M-<F3>'] = {utils.viewonly, 12},
   ['M-<F4>'] = {utils.viewonly, 13},
   ['M-S-<F1>'] = {utils.movetotag, 10},
   ['M-S-<F2>'] = {utils.movetotag, 11},
   ['M-S-<F3>'] = {utils.movetotag, 12},
   ['M-S-<F4>'] = {utils.movetotag, 13},
   ['M-C-<F1>'] = {utils.viewtoggle, 10},
   ['M-C-<F2>'] = {utils.viewtoggle, 11},
   ['M-C-<F3>'] = {utils.viewtoggle, 12},
   ['M-C-<F4>'] = {utils.viewtoggle, 13},
}))

root.keys(globalkeys)

local classrules = {
   ['Steam']    = {floating = true},
   ['Qmlviewer']= {floating = true},
   ['MPlayer']  = {floating = true},
   ['pinentry'] = {floating = true},
   ['Firefox']    = {buttons = firefoxbuttons},
   ['VirtualBox'] = {tag = tags[1][9]},
   ['Emacs'] = {size_hints_honor = false},
}

rules.rules = {
   { rule = { },
     properties = {
        border_width = beautiful.border_width,
        border_color = beautiful.border_normal,
        maximized_vertical = false,
        maximized_horizontal = false,
        focus = awful.client.focus.filter,
        keys = clientkeys,
        buttons = clientbuttons }},

   { rule = { type = 'splash' },
     properties = { floating = true } },

   { rule = { type = 'notification' },
     properties = { floating = true } },

   { rule = { role = 'gnome-terminal-floating' },
     properties = { floating = true } },

   -- { rule = { type = 'desktop' },
   --   properties = { ontop = false, above = false, below = true, border_width = 0 } },
}

for cls, props in pairs(classrules) do
   rule = { rule = { class = cls },
            properties = props },
   table.insert(rules.rules, rule)
end

-- signal function to execute when a new client appears.
client.connect_signal("manage",
   function (c, startup)
      -- Enable sloppy focus
      c:connect_signal("mouse::enter",
         function(c)
            if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
               client.focus = c
            end
      end)

    if not startup then
       -- Set the windows at the slave,
       -- i.e. put it at the end of others instead of setting it master.
       -- awful.client.setslave(c)

       -- Put windows in a smart way, only if they do not set an initial position.
       if not c.size_hints.user_position and not c.size_hints.program_position then
          awful.placement.under_mouse(c)
          awful.placement.no_overlap(c)
          awful.placement.no_offscreen(c)
       end

    end
end)

client.connect_signal("focus",
    function(c)
       local tag = awful.tag.selected(mouse.screen)
       local count = 0
       for _ in pairs(tag:clients()) do count = count + 1 end

       local maximized = c.maximized_horizontal == true and c.maximized_vertical == true

       -- show window border only when maximized or when the only client on a tag
       if maximized or count == 1 then
          c.border_width = 0
          c.border_color = beautiful.border_normal
       else
          c.border_width = beautiful.border_width
          c.border_color = beautiful.border_focus
       end
end)


client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)


-- Autostart
awful.util.spawn_with_shell("xmodmap ~/.Xmodmap")

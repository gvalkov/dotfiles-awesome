-- awesome imports
awful = require('awful')
gears = require('gears')
rules = require('awful.rules')
wibox = require('wibox')
beautiful = require('beautiful')
naughty = require('naughty')
menubar = require('menubar')
autofocus = require('awful.autofocus')

-- vendor imports
freedesktop = {}
freedesktop.utils = require('freedesktop.utils')
freedesktop.menu = require('freedesktop.menu')

-- user imports
ezconfig = require('ezconfig')
sessionmenu = require('sessionmenu')
util = require('util')


-- error handling
util.handle_startup_errors(awesome)
util.handle_runtime_errors(awesome)

-- globals
terminal = 'gnome-terminal'
editor = os.getenv('EDITOR') or 'nano'
editor_cmd = terminal .. ' -e ' .. editor
modkey = 'Mod4' ; ezconfig.modkey = modkey
altkey = 'Mod1' ; ezconfig.altkey = altkey
confdir = awful.util.getdir('config')

-- theming
freedesktop.utils.icon_theme = 'gnome'
beautiful.init(confdir .. '/themes/mine/theme.lua')
if beautiful.wallpaper then util.set_wallpaper(beautiful.wallpaper, screen) end

-- notification settings
naughty.config.defaults.timeout = 5
naughty.config.defaults.screen = 1
naughty.config.defaults.position = 'bottom_right'
naughty.config.defaults.margin = 10
naughty.config.defaults.gap = 1
naughty.config.defaults.ontop = true
naughty.config.defaults.font = beautiful.font
naughty.config.defaults.icon = nil
naughty.config.defaults.icon_size = 256
naughty.config.defaults.border_color = beautiful.border_tooltip
naughty.config.defaults.border_width = 0
naughty.config.defaults.hover_timeout = nil
naughty.config.presets.critical.fg = beautiful.fg_urgent
naughty.config.presets.critical.bg = beautiful.bg_urgent
naughty.config.presets.critical.timeout = 40

local layouts = {
   -- awful.layout.suit.floating,
   awful.layout.suit.tile,
   -- awful.layout.suit.tile.left,
   -- awful.layout.suit.tile.bottom,
   -- awful.layout.suit.tile.top,
   awful.layout.suit.fair,
   -- awful.layout.suit.fair.horizontal,
   -- awful.layout.suit.spiral,
   -- awful.layout.suit.spiral.dwindle,
   awful.layout.suit.max,
   awful.layout.suit.max.fullscreen,
   -- awful.layout.suit.magnifier
}

-- tags = {
--    [1] = awful.tag({ 1, 'a', 2, 3, 4, 5, 6, 7, 8, 9 }, 2, layouts[1]),
--    [2] = awful.tag({ '1:skype', '2:mail', '3:org', 4, 5, 6, 7, 8, 9 }, 1, layouts[1]),
-- }

tags = {}

for s = 1, screen.count() do
    tags[s] = awful.tag({ 1, 2, 3, 'skype', 'mail', 'org', 7, 8, 'v' }, s, layouts[1])
end

awful.tag.setproperty(tags[1][4], 'mwfact', 0.13)

-- menus
awful.menu.menu_keys['back'] = {'BackSpace', 'Left'}
menus = {}

menus.freedesktop = util.load_or_create_freedesktop_menu()
menus.awesome = {
   { 'manual', terminal .. ' -e man awesome' },
   { 'edit config', editor_cmd .. ' ' .. awesome.conffile },
   { 'restart', awesome.restart },
   { 'quit', awesome.quit }
}
menus.browsers = {
   { 'firefox', 'firefox', util.icon('firefox') },
   { 'chrome', 'google-chrome', util.icon('google-chrome') },
}
menus.main = awful.menu({
   items = { { 'awesome', menus.awesome, beautiful.awesome_icon },
             { '&browsers', menus.browsers },
             { '&xdg', menus.freedesktop },
             { '&session', sessionmenu.menu },
             { 'open terminal', terminal }
   }
})

menubar.utils.terminal = terminal

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
   return awful.widget.taglist(s, awful.widget.taglist.filter.all,
                               widgets.taglist.buttons)
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
   [4] = {util.raise_and_focus, 1},
   [5] = {util.raise_and_focus, -1},
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
-- firefoxbuttons = awful.util.table.join(clientbuttons, firefoxbuttons)

-- key bindings
globalkeys = ezconfig.keytable.join({
   -- navigation
   ['M-<Left>'] = awful.tag.viewprev,
   ['M-<Right>'] = awful.tag.viewnext,
   ['M-`'] = awful.tag.history.restore,
   ['M-j'] = {util.raise_and_focus, 1},
   ['M-k'] = {util.raise_and_focus, -1},

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
   ['M-S-q'] = function (c) awful.client.movetoscreen(c, 2) end,
   ['M-w'] = {awful.screen.focus, 2},
   ['M-S-w'] = function (c) awful.client.movetoscreen(c, 1) end,
   
   -- programs
   ['M-a'] = util.spawn(terminal),
   ['M-f'] = util.spawn('firefox'),
   ['M-g'] = util.spawn('gvim'),
   ['M-e'] = util.spawn('emacsclient -c'),
   -- ['M-<Menu>'] = util.spawn('python3 /home/gv/source/wip/menus/menu.py'),
   ['M-<Menu>'] = util.spawn('qdbus org.desktoputils /Menus org.desktoputils.menu.showxy main-menu 500 700'),
   ['M-C-S-q'] = awesome.quit,
   ['M-C-q'] = awesome.restart,
   ['M-m'] = function () menus.main:show() end,
   
   -- resizing
   ['M-l'] =   {awful.tag.incmwfact, 0.05},
   ['M-h'] =   {awful.tag.incmwfact, -0.05},
   ['M-S-h'] = {awful.tag.incnmaster, 1},
   ['M-S-l'] = {awful.tag.incnmaster, -1},
   ['M-C-h'] = {awful.tag.incncol, 1},
   ['M-C-l'] = {awful.tag.incncol, -1},
   ['M-<space>'] = {awful.layout.inc, layouts, 1},
   ['M-S-<space>'] = {awful.layout.inc, layouts, -1},
   ['M-C-n'] = awful.client.restore,

   -- prompts
   -- ['M-r'] = function () widgets.prompts[mouse.screen]:run() end,
   ['M-p'] = menubar.show,
   ['M-x'] = 
      function ()
         awful.prompt.run(
            {prompt = "Run Lua code: " },
            prompts[mouse.screen].widget,
            awful.util.eval, nil,
            awful.util.getdir("cache") .. "/history_eval")
      end,

   ['M-r'] = util.spawn(table.concat({
    'dmenu-launch.py', 
    -- '-nb', "'#3F3F3F'", -- normal background color
    -- '-nf', "'#DCDCCC'", -- normal foreground color
    -- '-sb', "'#7F9F7F'", -- selected background color
    -- '-sf', "'#DCDCCC'", -- selected foreground color
    '-b'}, ' '))        -- at the bottom of the screen
})

-- client key bindings
clientkeys = ezconfig.keytable.join({
   ['M-f'] = function (c) c.fullscreen = not c.fullscreen end,
   ["M-c"] = function (c) c:kill() end,
   ["M-C-<space>"] = awful.client.floating.toggle,
   ["M-C-<Return>"] = function (c) c:swap(awful.client.getmaster()) end,
   ["M-o"] = awful.client.movetoscreen,
   ["M-t"] = function (c) c.ontop = not c.ontop end,
   ["M-n"] = function (c) c.minimized = true end,
   ["M-C-m"] = 
      function (c)
         c.maximized_horizontal = not c.maximized_horizontal
         c.maximized_vertical   = not c.maximized_vertical
      end,
})


-- tag navigation keys
for i=1, keynumber do
   globalkeys = awful.util.table.join(globalkeys, ezconfig.keytable.join({
   ['M-#'..i+9] = 
      function ()
         local screen = mouse.screen
         if tags[screen][i] then
            awful.tag.viewonly(tags[screen][i])
         end
      end,
   ['M-C-#'..i+9] =
      function ()
         local screen = mouse.screen
         if tags[screen][i] then
             awful.tag.viewtoggle(tags[screen][i])
         end
      end,
   ['M-S-#'..i+9] =
      function ()
        if client.focus and tags[client.focus.screen][i] then
           awful.client.movetotag(tags[client.focus.screen][i])
        end
      end,
   ['M-C-S-#'..i+9] = 
      function ()
         if client.focus and tags[client.focus.screen][i] then
            awful.client.toggletag(tags[client.focus.screen][i])
         end
      end
}))
end

root.keys(globalkeys)

local classrules = {
   ['MPlayer']  = {floating = true},
   ['pinentry'] = {floating = true},
   ['krunner']  = {floating = true},
   ['gimp']     = {floating = true},
   ['Plasma']   = {floating = true, border_width = 0},
   ['Plugin-container'] = {floating = true, border_width = 0},
   ['Claws-mail'] = {tag = tags[1][5]},
   ['xbmc.bin']   = {floating = true, border_width = 0},
   ['Firefox']    = {buttons = firefoxbuttons},
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

   { rule = { name = 'Menus' },
     properties = { floating = true } },

   { rule = { class = 'Skype', name = 'gvalkov.im - Skype™' },
     properties = { tag = tags[1][4] } },

   { rule = { class = 'Skype', role = 'ConversationsWindow' },
     properties = { tag = tags[1][4] },
     callback = awful.client.setslave },

   { rule = { class = 'Skype', name = 'File Transfers' },
     properties = { tag = tags[1][4] },
     callback = awful.client.setslave },

   { rule = { class = 'Emacs', name = 'Emacs-Org-Mode' },
     properties = { tag = tags[1][6] }, },
}

for cls, props in pairs(classrules) do
   rule = { rule = { class = cls },
            properties = props },
   table.insert(rules.rules, rule)
end

-- signal function to execute when a new client appears.
client.connect_signal("manage", function (c, startup)
    -- Enable sloppy focus
    c:connect_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)

    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        -- awful.client.setslave(c)

        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end

    local titlebars_enabled = false
    if titlebars_enabled and (c.type == "normal" or c.type == "dialog") then
        -- Widgets that are aligned to the left
        local left_layout = wibox.layout.fixed.horizontal()
        left_layout:add(awful.titlebar.widget.iconwidget(c))

        -- Widgets that are aligned to the right
        local right_layout = wibox.layout.fixed.horizontal()
        right_layout:add(awful.titlebar.widget.floatingbutton(c))
        right_layout:add(awful.titlebar.widget.maximizedbutton(c))
        right_layout:add(awful.titlebar.widget.stickybutton(c))
        right_layout:add(awful.titlebar.widget.ontopbutton(c))
        right_layout:add(awful.titlebar.widget.closebutton(c))

        -- The title goes in the middle
        local title = awful.titlebar.widget.titlewidget(c)
        title:buttons(awful.util.table.join(
                awful.button({ }, 1, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.move(c)
                end),
                awful.button({ }, 3, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.resize(c)
                end)
                ))

        -- Now bring it all together
        local layout = wibox.layout.align.horizontal()
        layout:set_left(left_layout)
        layout:set_right(right_layout)
        layout:set_middle(title)

        awful.titlebar(c):set_widget(layout)
    end
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)

-- autostart
awful.util.spawn_with_shell('pgrep -xf "systemd --user" || systemd --user')
awful.util.spawn_with_shell('sleep 1 && pgrep -xf "systemd --user" && systemctl --user start progs.target')

-- Local Variables:
-- mode: lua
-- lua-indent-level: 3
-- comment-column: 0
-- End:
-- compile-command: (format "awesome --config %s --check" buffer-file-name)

-- sessionmenu.lua --- an advanced session menu for awesome
--
-- Author: Georgi Valkov <georgi.t.valkov@gmail.com>
-- License: GPLv2 (same as awesome)
--
-- Requires:
--   dmenu or zenity
--   inotifywait (part of inotify-tools)
--   awesome-freedesktop
--
-- To enable the 'Next Boot' menu:
--   1) setfacl -m u:$USER:r /boot/grub2/grub.cfg
--   2) $USER ALL = NOPASSWD: /usr/sbin/grub2-reboot  #in /etc/sudoers
--
-- Usage:
--   ezconfig = require('sessionmenu')
--
--   mainmenu = awful.menu({
--     items = { { '&session', sessionmenu.menu() } }
--   }
--
--   Overwrite any of the following functions:
--     sessionmenu.ops.lock
--     sessionmenu.ops.logout
--     sessionmenu.ops.suspend
--     sessionmenu.ops.hibernate
--     sessionmenu.ops.restart
--     sessionmenu.ops.shutdown

awful = require('awful')
local freedesktop_utils = require('freedesktop.utils')


freedesktop_utils.icon_theme = 'Faenza'
sessionmenu = {}
sessionmenu.ops = {}

local system = awful.util.spawn_with_shell
local dmenu_cmd = ' dmenu -i -b '
local current_timer = nil
local command_timer = nil
local name2uuid = {}

-- keep a function:name mapping in sessionmenu.ops.names
setmetatable(sessionmenu.ops, {
   __newindex = function(t, key, value)
      if t.names == nil then
         rawset(t, 'names', {})
      end
      if type(value) == 'function' then
         t.names[value] = 'sessionmenu.ops.'..key
         rawset(t, key, value)
      end
   end
})

--
-- tailor the following functions to your needs
function sessionmenu.ops.lock ()
   -- system('xlock -mode blank')
   system('i3lock-wrapper')
end

function sessionmenu.ops.logout ()
   system('echo logout')
end

function sessionmenu.ops.suspend ()
   system('systemctl suspend')
end

function sessionmenu.ops.hibernate ()
   system('systemctl hibernate')
end

function sessionmenu.ops.restart ()
   system('sudo systemctl reboot')
end

function sessionmenu.ops.shutdown ()
   system('systemctl halt')
end

local iconcache = {}
local function icon(name)
   if iconcache[name] ~= nil then
      return iconcache[name]
   else
      iconcache[name] = freedesktop_utils.lookup_icon({icon = name})
      return iconcache[name]
   end
end

-- get the output of a command started with `awful.util.spawn_with_shell`
-- (this works by redirecting stdout to a file and blocking until it's
-- closed - if you know of a solution that integrates with awesome's
-- event loop, do share!)
local function check_output(cmd)
   local tmpfile = os.tmpname()
   cmd = string.format('%s > %s', cmd, tmpfile)

   awful.util.spawn_with_shell(cmd)
   os.execute('inotifywait -qq -e close ' .. tmpfile)

   local res = io.open(tmpfile, 'r'):read()
   os.remove(tmpfile)

   return res
end

-- call a function after a period of time
local function timed_call(sec, cb)
   return function ()
      if current_timer ~= nil then
         current_timer:stop()
      end

      local fn = function ()
         current_timer:stop()
         current_timer = nil
         cb()
      end

      current_timer = timer({timeout = sec})
      current_timer:connect_signal('timeout', fn)
      print(string.format('sessionmenu: timer started - %s - %s',
                          sec, sessionmenu.ops.names[cb]))
      current_timer:start()
   end
end

-- call a function after a user specified period of time (read from dmenu)
local function dmenu_timed_call(cb)
   return function ()
      local fn = function ()
         command_timer:stop()

         local cmd = string.format(
[=[
while /bin/true; do
    spec=$(echo "" | %s -p 'timespec:')
    [[ $? -ne 0 ]] && break
    n=${spec:0:$(( ${#spec} - 1 ))}
    period=${spec:$(( ${#spec} - 1 ))}

    [[ ! "$n" =~ ^[0-9]+$ ]] && continue
    [[ ! "$period" =~ ^[smhd]$ ]] && continue

    case "$period" in
        's') echo $(( $n * 1 )) ;;
        'm') echo $(( $n * 60 )) ;;
        'h') echo $(( $n * 3600 )) ;;
        'd') echo $(( $n * 86400 )) ;;
    esac
    break
done]=], dmenu_cmd)

         local seconds = check_output(cmd)
         if seconds ~= nil then
            timed_call(seconds, cb)()
         end
      end

      command_timer = timer({timeout = 0.1})
      command_timer:connect_signal('timeout', fn)
      command_timer:start()
   end
end

-- call a function once a process ends
local function waitpid_call(pid, cb)
   return function ()
      if current_timer ~= nil then
         current_timer:stop()
         current_timer = nil
      end

      local fn = function ()
         local fh = io.open('/proc/'..pid..'/cmdline')
         if fh ~= nil then
            fh:close()
         else
            current_timer:stop()
            current_timer = nil
            cb()
         end
      end

      current_timer = timer({timeout = 1.5})
      current_timer:connect_signal('timeout', fn)
      print(string.format('sessionmenu: waiting for pid %s - %s',
                          pid, sessionmenu.ops.names[cb]))
      current_timer:start()
   end
end

-- call a function once a process ends (read from dmenu)
local function dmenu_waitpid_call(cb)
   return function ()
      local fn = function ()
         if command_timer ~= nil then
            command_timer:stop()
         end

         local user = os.getenv('USER')
         local cmd = string.format(
            [[ps -u %s -o pid,cmd | tail -n +2 | %s -l 30 | awk '{print $1}']],
            user, dmenu_cmd)

         local pid = check_output(cmd)
         if pid ~= nil then
            waitpid_call(pid, cb)()
         end
      end

      command_timer = timer({timeout = 0.1})
      command_timer:connect_signal('timeout', fn)
      command_timer:start()
   end
end

local function cancel_pending_action()
   if current_timer ~= nil then
      current_timer:stop()
      current_timer = nil
      print('sessionmenu: pending actions canceled')
   else
      print('sessionmenu: no pending actions')
   end
end

local function generate_submenu(cb, nowlabel, nowicon)
   if nowlabel == nil then
      nowlabel = '&now'
   end

   return {
      { nowlabel, cb, nowicon },
      { '&after', {
           { '5 min', timed_call(300, cb) },
           { '15 min', timed_call(600, cb) },
           { '30 min', timed_call(1200, cb) },
           { '1 hour', timed_call(3600, cb) },
           { '2 hours', timed_call(7200, cb) },
           { '&specify', dmenu_timed_call(cb) },
                 }, icon('clock')},
      { '&wait for process', dmenu_waitpid_call(cb), icon('process-stop') }
          }
end

local function next_boot_submenu()
   local fh = io.open('/boot/grub2/grub.cfg')
   if fh ~= nil then
      fh:close()
   else
      return nil
   end

   local ret = {}
   local cmd =
      [[cat /boot/grub2/grub.cfg \
        | awk -F"'|'" '/menuentry / {print $2, ";", $(NF-1) }']]

   for line in io.popen(cmd):lines() do
      local _, _, name, uuid = string.find(line, '(.*) ; (.*)')
      name2uuid[name] = uuid
   end

   for name, uuid in pairs(name2uuid) do
      local cmd = 'sudo grub2-reboot %s && echo sessionmenu: next boot - "%s"'
      table.insert(ret, {name, function () os.execute(string.format(cmd, uuid, name)) end })
   end

   return ret
end

local function entry(label, iname, cb)
   return { label, generate_submenu(cb, label, icon(iname)), icon(iname) }
end


sessionmenu.menu = function()
   return {
      entry('&lock',      'system-lock-screen', sessionmenu.ops.lock),
      entry('l&ogout',    'system-log-out',     sessionmenu.ops.logout),
      entry('&suspend',   'system-suspend',     sessionmenu.ops.suspend),
      entry('h&ibernate', 'system-suspend-hibernate', sessionmenu.ops.hibernate),
      entry('&restart',   'system-restart',     sessionmenu.ops.restart),
      entry('s&hutdown',  'system-shutdown',    sessionmenu.ops.shutdown),
      { '', nil },
      { '&next boot', next_boot_submenu(), icon('next') },
      { '&cancel pending', cancel_pending_action, icon('stop') },
   }
end

return sessionmenu

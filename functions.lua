local awful = require("awful")
local naughty = require("naughty")

terminal = "x-terminal-emulator"
editor = os.getenv("EDITOR") or "editor"
editor_cmd = terminal .. " -e " .. editor
screenlock_cmd = os.getenv("SCREEN_LOCK_CMD") or "xsecurelock"

-- https://superuser.com/questions/556877/simultaneously-switch-tags-as-one-screen-in-multi-monitor-setup
function for_all_screens(perform)
   local current = awful.screen.focused()
   for i = 1, screen.count() do
      perform(screen[i])
   end
   awful.screen.focus(current)
   highlight_focused_screen()
   -- TODO: maybe here need to find the active client on this screen and then focus that
end

function mk_all_screens(perform)
   return function()
         for_all_screens(perform)
   end
end

function mk(func, arg)
   return function()
      func(arg)
   end
end

function spawn_notify(command, title)
   awful.spawn.easy_async(command, function(stdout, stderr, reason, exit_code)
                             if exit_code ~= 0 then
                                naughty.notify({title="Could not invoke "..title, text = stdout, timeout=0 })
                             end
   end)
end

function mk_spawn(command, title)
   return function()
      spawn_notify(command, title)
   end
end

lock_screen = mk_spawn(screenlock_cmd, "Lock Screen")
suspend_system = mk_spawn("systemctl suspend", "Suspend")
hybrid_sleep_system = mk_spawn("systemctl hybrid-sleep", "Hybrid Sleep")

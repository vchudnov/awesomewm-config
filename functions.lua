local gears = require("gears")
local awful = require("awful")
local naughty = require("naughty")
local wibox = require("wibox")

terminal = "x-terminal-emulator"
editor = os.getenv("EDITOR") or "editor"
editor_cmd = terminal .. " -e " .. editor
screenlock_cmd = os.getenv("SCREEN_LOCK_CMD") or "xsecurelock"
screenlock_shell = "${SCREEN_LOCK_CMD:-xsecurelock}" -- to be run via the shell 
bash_cmd = os.getenv("SHELL") or "/bin/bash"

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

-- need unquoted to work for run in terminal
function in_shell(cmd)
   return bash_cmd .. " -i +O expand_aliases -c " .. cmd
end

lock_screen = mk_spawn(in_shell(screenlock_shell, "Lock Screen"))
suspend_system = mk_spawn("systemctl suspend", "Suspend")
hybrid_sleep_system = mk_spawn("systemctl hybrid-sleep", "Hybrid Sleep")


quit_with_confirm = function()
   local confirmation = "zenity --question --no-wrap --title='Quit Session'  --text='Quit AwesomeWM?' --ok-label='Quit' --cancel-label='Return'"
   awful.spawn.easy_async(confirmation, function(stdout, stderr, reason, exit_code)
                             if exit_code == 0 then
				awesome.quit()
                             end
   end)
end

assert(loadfile(config_dir .. "/state.lua"))({config_dir=config_dir})

function set_wallpaper(s)
   -- Wallpaper
   if true then
      gears.wallpaper.set("#000000")
      local wallpaper = "/tmp/dark_forest.jpg"  -- http://3.bp.blogspot.com/-ehfHnFSTtiA/T5jXryJRgZI/AAAAAAAACSs/nmnSIyr4RZ4/s1600/dark_forest.jpg
      gears.wallpaper.maximized(wallpaper, s, true)
   else
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        -- If wallpaper is a function, call it with the screen
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        gears.wallpaper.maximized(wallpaper, s, true)
    end
   end
end

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", set_wallpaper)


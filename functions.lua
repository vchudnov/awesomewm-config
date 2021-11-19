local gears = require("gears")
local awful = require("awful")
local naughty = require("naughty")
local wibox = require("wibox")
local xresources = require("beautiful.xresources")

terminal = "x-terminal-emulator"
editor = os.getenv("EDITOR") or "editor"
editor_cmd = terminal .. " -e " .. editor
screenlock_cmd = os.getenv("SCREEN_LOCK_CMD") or "xsecurelock"
screenlock_shell = "${CMD_SCREEN_LOCK:-xsecurelock}" -- to be run via the shell
detect_screens_shell = "${CMD_DETECT_SCREENS:-~/.screenlayout/detect-screens.sh}"
laptop_screen_shell = "${CMD_LAPTOP_SCREEN:-~/.screenlayout/x-laptop.sh}"
bash_cmd = os.getenv("SHELL") or "/bin/bash"

-- https://superuser.com/questions/556877/simultaneously-switch-tags-as-one-screen-in-multi-monitor-setup
function for_all_screens(perform)
   local current = awful.screen.focused()

   -- Do the current screen last so that the window focus stays there
   -- when changing tags. I have not been able to find a more elegant
   -- way to achieve this.
   for i = 1, screen.count() do
      if current.index ~= i then
	 perform(screen[i])
      end
   end
   perform(screen[current.index])
   
   awful.screen.focus(current)
   highlight_focused_screen()
   -- TODO: maybe here need to find the active client on this screen and then focus that
end

-- direction should be one of "up", "down", "left", "right"
function move_focus(direction)
   awful.client.focus.bydirection(direction)
   if client.focus then client.focus:raise() end
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

function in_shell(cmd)
   -- Runs a command in the shell
   quote = "\""
   return bash_cmd .. " -i +O expand_aliases -c " .. quote .. cmd .. quote
end

lock_screen = mk_spawn(in_shell(screenlock_shell), "Lock Screen")
suspend_system = mk_spawn("systemctl suspend", "Suspend")
hybrid_sleep_system = mk_spawn("systemctl hybrid-sleep", "Hybrid Sleep")
detect_screens = mk_spawn(in_shell(detect_screens_shell), "Detect Screens")
laptop_screen = mk_spawn(in_shell(laptop_screen_shell), "Switch to laptop screen only")


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

function change_rc(new_file)
   local config_link = config_dir .. "/rc.lua"
   os.remove(config_link)
   os.execute("ln -s " .. new_file .. " " .. config_link)
end

function restarter_with(dst)
   return function()
      change_rc(dst)
      awesome.restart()
   end
end

local dpi = xresources.apply_dpi

function client_to_screen_menu()
   terms = {}
   for i, c in pairs(client.get()) do
      terms [i] =
	 {c.name,
	  function()
	     local screen = awful.screen.focused()
	     c:move_to_screen(screen)
	     c:move_to_tag(screen.selected_tag)
	     c.minimized = false
	     awful.placement.no_offscreen(c)
	  end,
	 c.icon}
   end
   awful.menu({items = terms,
	       theme = { width = dpi(300) }}):show()
end

function screen_to_client_menu()
   awful.menu.clients({theme = { width = dpi(300) }})
end

function battery_indicator()
   -- taken from https://askubuntu.com/a/645131
   local batterywidget = wibox.widget.textbox()
   batterywidget:set_text(" | Battery | ")
   local batterywidgettimer = timer({ timeout = 5 })
   -- TODO: Keep a list of all the battery widgets and iterate over
   -- them from a single timer, rather than having one per widget.
   batterywidgettimer:connect_signal("timeout",
				     function()
					fh = assert(io.popen("acpi | cut -d, -f 2,3 -", "r"))
					batterywidget:set_text(" |" .. fh:read("*l") .. " | ")
					fh:close()
				     end
   )
   batterywidgettimer:start()
   return batterywidget
end

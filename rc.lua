
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library

local menubar = require("menubar")
local hotkeys_popup = require("awful.hotkeys_popup").widget
-- Enable hotkeys help widget for VIM and other apps
-- when client with a matching name is opened:
require("awful.hotkeys_popup.keys")

-- Load Debian menu entries
local debian = require("debian.menu")

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "error in AwesomeWM",
                         text = tostring(err) })
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, font and wallpapers.
beautiful.init("/home/vchudnov/.config/awesome/theme.lua")
--beautiful.init(gears.filesystem.get_themes_dir() .. "default/theme.lua")

-- This is used later as the default terminal and editor to run.
terminal = "x-terminal-emulator"
editor = os.getenv("EDITOR") or "editor"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Info on modkeys: https://superuser.com/a/1255946
Alt="Mod1"

-- Table of layouts to cover with awful.layout.inc, order matters.
awful.layout.layouts = {
    awful.layout.suit.floating,
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
    -- awful.layout.suit.spiral,
    -- awful.layout.suit.spiral.dwindle,
    -- awful.layout.suit.max,
    awful.layout.suit.max.fullscreen,
    awful.layout.suit.magnifier,
    -- awful.layout.suit.corner.nw,
    -- awful.layout.suit.corner.ne,
    -- awful.layout.suit.corner.sw,
    -- awful.layout.suit.corner.se,
}
-- }}}

-- {{{ Helper functions
local function client_menu_toggle_fn()
    local instance = nil

    return function ()
        if instance and instance.wibox.visible then
            instance:hide()
            instance = nil
        else
            instance = awful.menu.clients({ theme = { width = 250 } })
        end
    end
end
-- }}}

-- {{{ Menu
-- Create a launcher widget and a main menu
myawesomemenu = {
   { "Hotkeys", function() return false, hotkeys_popup.show_help end},
   { "Manual", terminal .. " -e man awesome" },
   { "Edit config", editor_cmd .. " " .. awesome.conffile },
   { "Restart", awesome.restart },
   { "Quit", function() awesome.quit() end}
}

mymainmenu = awful.menu({ items = { { "Awesome", myawesomemenu, beautiful.awesome_icon },
                                    { "Debian", debian.menu.Debian_menu.Debian },
                                    { "Terminal", terminal }
                                  }
                        })

mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon,
                                     menu = mymainmenu })

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

-- Keyboard map indicator and switcher
mykeyboardlayout = awful.widget.keyboardlayout()

-- {{{ Wibar
-- Create a textclock widget
mytextclock = wibox.widget.textclock()

-- Create a wibox for each screen and add it
local taglist_buttons = gears.table.join(
                    awful.button({ }, 1, function(t) t:view_only() end),
                    awful.button({ modkey }, 1, function(t)
                                              if client.focus then
                                                  client.focus:move_to_tag(t)
                                              end
                                          end),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, function(t)
                                              if client.focus then
                                                  client.focus:toggle_tag(t)
                                              end
                                          end),
                    awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
                    awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
                )

local tasklist_buttons = gears.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  -- Without this, the following
                                                  -- :isvisible() makes no sense
                                                  c.minimized = false
                                                  if not c:isvisible() and c.first_tag then
                                                      c.first_tag:view_only()
                                                  end
                                                  -- This will also un-minimize
                                                  -- the client, if needed
                                                  client.focus = c
                                                  c:raise()
                                              end
                                          end),
                     awful.button({ }, 3, client_menu_toggle_fn()),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                          end))

local function set_wallpaper(s)
    -- Wallpaper
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        -- If wallpaper is a function, call it with the screen
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        gears.wallpaper.maximized(wallpaper, s, true)
    end
end

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", set_wallpaper)

dofile(os.getenv("HOME") .. "/.config/awesome/state.lua")

-- TODO: Would like a notification when screen focus changes so I can change the wibar background
--       In the meantime, can use this: https://stackoverflow.com/questions/47159096/awesomewm-widget-showing-focused-screen

awful.screen.connect_for_each_screen(function(s)
    -- Wallpaper
    set_wallpaper(s)

    -- Each screen has its own tag table.
    awful.tag(restore_tags(s,default_tags), s, awful.layout.layouts[1])

    -- Create a promptbox for each screen
    s.mypromptbox = awful.widget.prompt()
    -- Create an imagebox widget which will contain an icon indicating what layout we're using.
    -- We need one layoutbox per screen.
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(gears.table.join(
                           awful.button({ }, 1, function () awful.layout.inc( 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(-1) end),
                           awful.button({ }, 4, function () awful.layout.inc( 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(-1) end)))
    -- Create a taglist widget
    s.mytaglist = awful.widget.taglist(s, awful.widget.taglist.filter.all, taglist_buttons)

    -- Create a tasklist widget
    s.mytasklist = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, tasklist_buttons)

    -- Create the wibox
    s.mywibox = awful.wibar({ position = "top", screen = s })

    -- Add widgets to the wibox
    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        { -- Left widgets
            layout = wibox.layout.fixed.horizontal,
            mylauncher,
            s.mytaglist,
            -- s.mypromptbox,
        },
        -- s.mytasklist, -- Middle widget
	s.mypromptbox,
	-- The following is useful to see the task  list with the maximization indicators
	--   (see https://stackoverflow.com/a/43940683)
	-- { layout = wibox.layout.fixed.horizontal,
	--   s.mytasklist, -- Middle widget
	--   s.mypromptbox
	-- },
        { -- Right widgets
            layout = wibox.layout.fixed.horizontal,
            mykeyboardlayout,
            wibox.widget.systray(),
            mytextclock,
            s.mylayoutbox,
        },
    }
end)
-- }}}

-- {{{ Mouse bindings
root.buttons(gears.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

    -- Move all screens to previous/next tag
    -- https://superuser.com/questions/556877/simultaneously-switch-tags-as-one-screen-in-multi-monitor-setup
function for_all_screens(perform)
   local current = awful.screen.focused()
   for i = 1, screen.count() do
      perform(screen[i])
   end
   awful.screen.focus(current)
   highlight_focused_screen()
end

function view_previous_all_screens()
   for_all_screens(awful.tag.viewprev)
end

function view_next_all_screens()
   for_all_screens(awful.tag.viewnext)
end

-- {{{ Key bindings
globalkeys = gears.table.join(
    awful.key({ modkey,           }, "F1",     hotkeys_popup.show_help,   {description="show help", group="awesome"}),
    awful.key({ modkey, "Control" }, "Left",   awful.tag.viewprev,        {description = "view previous", group = "tag"}),
    awful.key({ modkey, "Control" }, "Right",  awful.tag.viewnext,        {description = "view next", group = "tag"}),

    awful.key({ modkey            }, "Left",   view_previous_all_screens, {description="view previous on all screens", group = "tag"}),
    awful.key({ modkey            }, "Right",  view_next_all_screens,     {description="view next on all screens", group = "tag"}),

    awful.key({ modkey,           }, "Escape", awful.tag.history.restore, {description = "go back", group = "tag"}),

    awful.key({ Alt }, "Tab",
        function ()
            awful.client.focus.byidx( 1)
        end,
        {description = "focus next by index", group = "client"}
    ),
    awful.key({ Alt, "Shift" }, "Tab",
        function ()
            awful.client.focus.byidx(-1)
        end,
        {description = "focus previous by index", group = "client"}
    ),
    awful.key({ modkey, "Control" }, "Tab", function () mymainmenu:show() end,
              {description = "show main menu", group = "awesome"}),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "Right", function () awful.client.swap.byidx(  1)    end,
              {description = "swap with next client by index", group = "client"}),
    awful.key({ modkey, "Shift"   }, "Left", function () awful.client.swap.byidx( -1)    end,
              {description = "swap with previous client by index", group = "client"}),
    awful.key({ modkey }, "Down", function () awful.screen.focus_relative( 1); highlight_focused_screen(); end,
              {description = "focus the next screen", group = "screen"}),
    awful.key({ modkey }, "Up", function () awful.screen.focus_relative(-1); highlight_focused_screen(); end,
              {description = "focus the previous screen", group = "screen"}),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto,
              {description = "jump to urgent client", group = "client"}),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end,
        {description = "go back", group = "client"}),

    awful.key({modkey, "Shift" }, "grave", save_tags,
       {description = "save tags to disk", group = "state"}),
    
    -- Rename tag
    -- https://superuser.com/a/1228715
    -- https://awesomewm.org/doc/api/classes/tag.html#
    awful.key({ modkey, "Control" }, "F2",
       function ()
	  local t = awful.screen.focused().selected_tag
	  if not t then return end
	  awful.prompt.run {
	     prompt       = "(THIS screen) rename current tag: ",
	     text         = t.name,
	     textbox      = awful.screen.focused().mypromptbox.widget,
	     exe_callback = function(new_name)
		if not new_name or #new_name == 0 then return end		
		t.name = new_name
		save_tags()
	     end
	  }
       end,
       {description = "rename tag, current screen", group = "state"}),
    awful.key({ modkey }, "F2",
       function ()
	  local old_t = awful.screen.focused().selected_tag
	  if not old_t then return end
	  local old_name = old_t.name
	  awful.prompt.run {
	     prompt       = "(ALL screens) rename current tag: ",
	     text         = old_name,
	     textbox      = awful.screen.focused().mypromptbox.widget,
	     exe_callback = function(new_name)
		if not new_name or #new_name == 0 then return end

		for s in screen do
		   local t = awful.tag.find_by_name(s, old_name)
		   if t then
		      t.name = new_name
		   end
		end
		save_tags()
	     end
	  }
       end,
       {description = "rename tag, all screens", group = "state"}),    
       
    -- Standard program
    awful.key({ modkey, "Control" }, "Return", function () awful.spawn(terminal) end,
              {description = "open a terminal", group = "launcher"}),
    awful.key({ modkey, "Control" }, "F5", awesome.restart,
              {description = "reload awesome", group = "awesome"}),
    awful.key({ modkey, "Control", Alt , "Shift"   }, "Escape", awesome.quit,
              {description = "quit awesome", group = "awesome"}),

    awful.key({ modkey      }, "equal",     function () awful.tag.incmwfact( 0.05)          end,
       {description = "increase master width factor", group = "layout"}),
    
    awful.key({ modkey,           }, "minus",     function () awful.tag.incmwfact(-0.05)          end,
       {description = "decrease master width factor", group = "layout"}),
    
    awful.key({ modkey, "Control"   }, "equal",     function () awful.tag.incnmaster( 1, nil, true) end,
       {description = "increase the number of master clients", group = "layout"}),
    awful.key({ modkey, "Control"   }, "minus",     function () awful.tag.incnmaster(-1, nil, true) end,
       {description = "decrease the number of master clients", group = "layout"}),
    
    awful.key({ modkey, "Control", "Shift" }, "equal",     function () awful.tag.incncol( 1, nil, true)    end,
              {description = "increase the number of columns", group = "layout"}),
    awful.key({ modkey, "Control", "Shift" }, "minus",     function () awful.tag.incncol(-1, nil, true)    end,
       {description = "decrease the number of columns", group = "layout"}),
    
    awful.key({ modkey }, "Next", function () awful.layout.inc( 1)                end,
              {description = "select next", group = "layout"}),
    awful.key({ modkey }, "Prior", function () awful.layout.inc(-1)                end,
              {description = "select previous", group = "layout"}),

    awful.key({ modkey, "Control" }, "n",
              function ()
                  local c = awful.client.restore()
                  -- Focus restored client
                  if c then
                      client.focus = c
                      c:raise()
                  end
              end,
              {description = "restore minimized", group = "client"}),

    -- Prompt
    awful.key({ modkey },            "Return",     function () awful.screen.focused().mypromptbox:run() end,
              {description = "run prompt", group = "launcher"}),

    awful.key({ modkey, Alt }, "Return",
              function ()
                  awful.prompt.run {
                    prompt       = "Run Lua code: ",
                    textbox      = awful.screen.focused().mypromptbox.widget,
                    exe_callback = awful.util.eval,
                    history_path = awful.util.get_cache_dir() .. "/history_eval"
                  }
              end,
              {description = "lua execute prompt", group = "awesome"}),
    
    -- Menubar
    awful.key({ modkey }, "F4", function() menubar.show() end,
       {description = "show the menubar", group = "launcher"}),

    -- System
    awful.key({ modkey }, "Scroll_Lock", function()  lock_screen() end,
       {description = "lock screen", group = "system"}),
    awful.key({ modkey, "Control" }, "Scroll_Lock", function()  lock_screen_settings() end,
       {description = "screen lock settings", group = "system"}),
    awful.key({ modkey }, "Pause", function()  save_tags(); save_all_clients(); lock_screen(); suspend_system() end,
       {description = "suspend system", group = "system"}),
    awful.key({ modkey, "Control" }, "Pause", function()  save_tags(); save_all_clients(); lock_screen(); hybrid_sleep_system() end,
       {description = "suspend+hibernate system", group = "system"})   
)

function lock_screen()
   awful.spawn.easy_async("xscreensaver-command -lock", function(stdout, stderr, reason, exit_code)
			     -- if exit_code ~= 0 then
				naughty.notify { title="Could not lock screen", text = stdout, timeout=0 }
			     -- end
   end)
end

function lock_screen_settings()
   awful.spawn("xscreensaver-demo -prefs")
end

function suspend_system()
   awful.spawn("systemctl suspend")
end

function hybrid_sleep_system()
   awful.spawn("systemctl hybrid-sleep")
end


clientkeys = gears.table.join(
    awful.key({ modkey }, "F11",
        function (c)
            c.fullscreen = not c.fullscreen
            c:raise()
        end,
        {description = "toggle fullscreen", group = "client"}),
    awful.key({ modkey, "Control", Alt   }, "Escape",      function (c) c:kill()                         end,
              {description = "close", group = "client"}),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ,
              {description = "toggle floating", group = "client"}),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end,
              {description = "move to master", group = "client"}),
    awful.key({ modkey, "Control" }, "Down",      function (c) c:move_to_screen()               end,
              {description = "move to screen", group = "client"}),
    awful.key({ modkey, "Control" }, "Up",      function (c) c.ontop = not c.ontop            end,
       {description = "toggle keep on top", group = "client"}),
    
    awful.key({ modkey, "Control" }, "F9",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end ,
        {description = "minimize", group = "client"}),
    
    awful.key({ modkey }, "F9",
        function (c)
            c.maximized = not c.maximized
            c:raise()
        end ,
        {description = "(un)maximize", group = "client"}),
    
    awful.key({ modkey }, "F10",
        function (c)
            c.maximized_vertical = not c.maximized_vertical
            c:raise()
        end ,
        {description = "(un)maximize vertically", group = "client"}),
    
    awful.key({ modkey }, "F12",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c:raise()
        end ,
        {description = "(un)maximize horizontally", group = "client"})
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it work on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = gears.table.join(globalkeys,
        -- View tag only.
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                        local screen = awful.screen.focused()
                        local tag = screen.tags[i]
                        if tag then
                           tag:view_only()
                        end
                  end,
                  {description = "(THIS screen) view tag #"..i, group = "tag"}),
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        for s in screen do
			   local tag = s.tags[i]
			   if tag then
			      tag:view_only()
			   end
			end
                  end,
                  {description = "(ALL screens) view tag #"..i, group = "tag"}),
        -- Toggle tag display.
        awful.key({ modkey, Alt, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = awful.screen.focused()
                      local tag = screen.tags[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end,
                  {description = "(THIS screen) toggle tag #" .. i, group = "tag"}),
        awful.key({ modkey, Alt }, "#" .. i + 9,
                  function ()
                      for s in screen do
			 local tag = s.tags[i]
			 if tag then
			    awful.tag.viewtoggle(tag)
			 end
		      end
                  end,
                  {description = "(ALL screens) toggle tag #" .. i, group = "tag"}),
        -- Move client to tag.
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:move_to_tag(tag)
                          end
                     end
                  end,
                  {description = "move focused client to tag #"..i, group = "tag"}),
        -- Toggle tag on focused client.
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:toggle_tag(tag)
                          end
                      end
                  end,
                  {description = "toggle focused client on tag #" .. i, group = "tag"})
    )
end

clientbuttons = gears.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     raise = true,
                     keys = clientkeys,
                     buttons = clientbuttons,
                     screen = awful.screen.preferred,
                     placement = awful.placement.no_overlap+awful.placement.no_offscreen
     }
    },

    -- Floating clients.
    { rule_any = {
        instance = {
          "DTA",  -- Firefox addon DownThemAll.
          "copyq",  -- Includes session name in class.
        },
        class = {
          "Arandr",
          "Gpick",
          "Kruler",
          "MessageWin",  -- kalarm.
          "Sxiv",
          "Wpa_gui",
          "pinentry",
          "veromix",
          "xtightvncviewer"},

        name = {
          "Event Tester",  -- xev.
        },
        role = {
          "AlarmWindow",  -- Thunderbird's calendar.
          "pop-up",       -- e.g. Google Chrome's (detached) Developer Tools.
        }
      }, properties = { floating = true }},

    -- Add titlebars to normal clients and dialogs
    { rule_any = {type = { "normal", "dialog" }
      }, properties = { titlebars_enabled = true }
    },

    -- Set Firefox to always map on the tag named "2" on screen 1.
    -- { rule = { class = "Firefox" },
    --   properties = { screen = 1, tag = "2" } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c)
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    -- if not awesome.startup then awful.client.setslave(c) end

    if awesome.startup and
      not c.size_hints.user_position
      and not c.size_hints.program_position then
        -- Prevent clients from being unreachable after screen count changes.
        awful.placement.no_offscreen(c)
    end
end)

-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal("request::titlebars", function(c)
    -- buttons for the titlebar
    local buttons = gears.table.join(
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
    )

    awful.titlebar(c) : setup {
        { -- Left
            awful.titlebar.widget.iconwidget(c),
            awful.titlebar.widget.closebutton(c),
            buttons = buttons,
            layout  = wibox.layout.fixed.horizontal
        },
        { -- Middle
            { -- Title
                align  = "center",
                widget = awful.titlebar.widget.titlewidget(c)
            },
            buttons = buttons,
            layout  = wibox.layout.flex.horizontal
        },
        { -- Right
            awful.titlebar.widget.floatingbutton (c),
            awful.titlebar.widget.maximizedbutton(c),
            awful.titlebar.widget.stickybutton   (c),
            awful.titlebar.widget.ontopbutton    (c),
            layout = wibox.layout.fixed.horizontal()
        },
        layout = wibox.layout.align.horizontal
    }
end)

-- Enable sloppy focus, so that focus follows mouse.
client.connect_signal("mouse::enter", function(c)
    if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
    and awful.client.focus.filter(c) then
       client.focus = c
    end
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus; highlight_focused_screen();  end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}



-- TODO: Fix switching from multiple monitor to single monitor: https://github.com/awesomeWM/awesome/issues/1382 https://github.com/awesomeWM/awesome/issues/2317
-- TODO: Auto-hide panel: https://stackoverflow.com/questions/43240234/awesome-wm-panel-autohide-wont-work
-- TODO: Save desktop list to data file: https://stackoverflow.com/questions/11201262/how-to-read-data-from-a-file-in-lua
-- TODO: Compose keys: https://unix.stackexchange.com/a/39080

-- Refs:
-- Keycode ref: https://stackoverflow.com/questions/10774582/what-is-the-name-of-fn-key-for-awesome-wmn `xmodmap -pke`
-- Clients: https://awesomewm.org/doc/api/classes/client.html
-- Tag: https://awesomewm.org/doc/api/classes/tag.html#
-- Screen: https://awesomewm.org/doc/api/classes/screen.html
-- Task list icons for window state: https://stackoverflow.com/questions/27475104/awesome-wm-what-do-the-icons-of-the-title-bar-mean and https://github.com/awesomeWM/awesome/blob/3cfb577387d52e898455a64344f73409bc6f481b/lib/awful/widget/tasklist.lua#L243
-- Debugging LUA in command line: https://stackoverflow.com/a/39057120
--   use awesome-client n=require("naughty")
-- Info on modkeys: https://superuser.com/a/1255946
--   run: xmodmap to see mappings
--   run: xev to see keypress events

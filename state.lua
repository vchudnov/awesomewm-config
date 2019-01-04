-- Utilities meant to be aded by rc.lua
local naughty = require("naughty")
local awful = require("awful")
local beautiful = require("beautiful")

dofile(config_dir .. "/table-save.lua")

default_tags = { "1:www", "2:lua", "3:plan", "4:gMain", "5:gWorklog", "6", "7", "8", "9:FB" }

local tag_file = config_dir .. "/saved.tag.txt"
function save_tags()
   naughty.notify({title="START saving tags", text="Here!", timeout=0})
   -- http://www.computercraft.info/forums2/index.php?/topic/10499-luahelp-how-to-save-a-table-to-file/
   local saved_tags = {}
   for s in screen do
      local tags_for_screen = {}
      for i, t in ipairs(s.tags) do
	 table.insert(tags_for_screen,t.name)
      end
      saved_tags[s.index] = tags_for_screen
   end
   err = table.save(saved_tags, tag_file)
   if err ~= nil then
      naughty.notify({title="error saving tags", text=err, timeout=0})
   end
end

function restore_tags(s)
   return restore_tags_with_defaults(s, default_tags)
end

-- FIXME: This does not work if the tag file does not already exist
function restore_tags_with_defaults(s, defaults)
   if s==nil then return defaults; end

   -- TODO: Add a timestamp so we can avoid reloading the file for every screen
   local saved_tags, err = table.load(tag_file)
   if err ~= nil then
      naughty.notify({title="error restoring tags", text=err, timeout=0})
      return defaults
   end
   if saved_tags == nil then
      return defaults
   end
   sdata = saved_tags[s.index]
   if sdata == nil then
      return defaults
   end
   return sdata
end

function show_all_clients()
   for _, c in ipairs(client.get()) do
      c.raise(c)
   end
end

function get_all_tags_for_client(c)
   local all_tags = c:tags()
   local all_tag_names = {}
   for _, t in ipairs(all_tags) do
      table.insert(all_tag_names, t.name)
   end
   return all_tag_names
end

local clients_file = config_dir .. "/saved.clients.txt"
function save_all_clients()
   local saved_clients = {}
   for _, c in ipairs(client.get()) do
      local sc = {}
      sc["window"] = c.window
      sc["name"] = c.name
      sc["screen"] = c.screen.index
      sc["tags"] = get_all_tags_for_client(c)
      saved_clients[c.window] = sc
   end
   err = table.save(saved_clients, clients_file)
   if err ~= nil then
      naughty.notify({title="error saving clients", text=err, timeout=0})
   end
end

local function screen_for_client(c, saved_clients, num_screens, default_screen)
   local window = c.window
   sc = saved_clients[window]
   if sc  == nil then
      return default_screen
   end
   if sc.name ~= c.name then
      return default_screen
   end
   s = sc["screen"]
   if s > num_screens then
      return default_screen
   end
   return s
end

function restore_all_clients()
   local saved_clients, err = table.load(clients_file)
   if err ~= nil then
      naughty.notify({title="error restoring clients", text=err, timeout=0})
      return
   end
   local to_restore = {}
   for s in screen do
      to_restore[s.index] = {}
      naughty.notify({title="Screen:", text=tostring(s), timeout=0})
   end
   
   for _, c in ipairs(client.get()) do
      local screen = screen_for_client(c, saved_clients, screen:count(), 1)
      table.insert(to_restore[screen], c)
   end

   for s in screen do
      s.all_clients = to_restore[s.index]
   end
end

function highlight_focused_screen()
   local fs = awful.screen.focused()
   if not fs then naughty.notify({text="no focused screen?"}) return end
   for s in screen do
      if s.index == fs.index then
	 s.mywibox.bg = beautiful.bg_focus
	 s.mywibox.border_width = 2
	 s.mywibox.border_color = beautiful.bg_focus
	 s.mypromptbox.prompt_bg = beautiful.bg_focus
      else
	 s.mywibox.border_width = 2
	 s.mywibox.border_color = beautiful.bg_normal
	 s.mywibox.bg = beautiful.bg_normal
	 s.mypromptbox.prompt_bg = beautiful.bg_normal
      end
      
   end
end

return save_tags, restore_tags, show_all_clients, save_all_cients

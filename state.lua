-- Utilities meant to be aded by rc.lua
local naughty = require("naughty")
local awful = require("awful")
local beautiful = require("beautiful")

dofile(config_dir .. "/table-save.lua")

default_tags = { "1:www", "2:lua", "3:plan", "4:gMain", "5:gWorklog", "6", "7", "8", "9:FB" }

local tag_file = config_dir .. "/saved.tag.txt"
function save_tags()
   -- naughty.notify({title="START saving tags", text="Here!", timeout=0})
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
   saved_clients["focused_screen"] = awful.screen.focused().index
   saved_clients["focused_tag"] = awful.screen.focused().selected_tag

   -- TODO: The layouts part doesn't quite work. For one, this only gets the layout in the current tag. Fix.
   local ly = {}
   for s in screen do
	 ly[s.index] = awful.layout.get(s)
   end
   saved_clients["layouts"] = ly
   
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
      awful.layout.set(saved_clients["layouts"][s.index])
      naughty.notify({title="Screen:", text=tostring(s), timeout=0})
   end
   
   for _, c in ipairs(client.get()) do
      local screen = screen_for_client(c, saved_clients, screen:count(), 1)
      c["screen"] = screen
      table.insert(to_restore[screen], c)
   end

   -- Do the focused screen last so that its clients retain focus
   local focused_screen = saved_clients["focused_screen"]
   for s in screen do
      if s.index ~= focused_screen then
	 s.all_clients = to_restore[s.index]
      end
   end
   screen[focused_screen].all_clients = to_restore[focused_screen]

   
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

--- 2020-01-12: https://stackoverflow.com/questions/42056795/awesomewm-how-to-prevent-migration-of-clients-when-screen-disconnected

function firstkey(t) -- sorry, not a Lua programmer...
for i, e in pairs(t) do
    return i
end
return nil
end

local function get_screen_id(s)
    return tostring(s.geometry.width) .. "x" .. tostring(s.geometry.height) .. "x" .. tostring(firstkey(s.outputs))
end

------ DOES NOT REALLY WORK WITH MY SETUP
-- function restore_screen_clients(s)
--    -- Check if existing tags belong to this new screen that's being added
--    local restored = false;
--    local all_tags = root.tags()
--    for i, t in pairs(all_tags) do
--       if get_screen_id(s) == t.screen_id then
-- 	 t.screen = s
-- 	 restored = true;
--       end
--    end

--    -- On restored screen, select a tag
--    -- If this screen is entirely brand new, then create tags for it
--    if restored then
--       s.tags[1].selected = true
--    -- else
--    --    -- Each screen has its own tag table.
--    --    awful.tag({ "1", "2", "3", "4", "5", "6", "7", "8", "9" }, s, awful.layout.layoutThens[1])

--    --    -- Assign the tag to this screen, to restore as the screen disconnects/connects
--    --    for k, v in pairs(s.tags) do
--    -- 	 v.screen_id = get_screen_id(s)
--    --    end
--    -- end
--    end
-- end

-- function move_orphaned_clients(t)
--     -- Screen has disconnected, re-assign orphan tags to a live screen

--     -- Find a live screen
--     local live_screen = nil;
--     for s in screen do
--         if s ~= t.screen then
--             live_screen = s;
--             break
--         end
--     end

--     -- Move the orphaned tag to the live screen
--     t.screen = live_screen
-- end   

return save_tags, restore_tags, show_all_clients, restore_all_clients, save_all_clients

local wibox = require("wibox")
local cairo = require("lgi").cairo
local naughty = require("naughty")
local timer = timer
local io = io
local string = string
local tostring = tostring
local tonumber = tonumber

module ("batterywidget2")

local batterywidget = wibox.widget.base.make_widget()
local batterywarning = {false, false}

local warnlimit = 30
local critlimit = 15
local info
local warning

local function getBatteryInfo()
   p1 = io.popen("acpi | cut -d: -f 2 | cut -d, -f 1 | sed 's|\ ||'")
   p2 = io.popen("acpi | cut -d: -f 2 | cut -d, -f 2 | sed 's|\ ||'")
   
   local state = p1:read("*l")
   local level = p2:read("*l")
   io.close(p1)
   io.close(p2)
   
   return level, state
end

batterywidget.fit = function(widget, width, height)
   return 30, 20
end

batterywidget.draw = function(widget, wbox, cr, width, height)

   local LevelStr, stateStr
   levelStr, stateStr = getBatteryInfo()

   local level = tonumber(string.sub(levelStr, 1, string.find(levelStr, "%%") - 1));

   local a = 0.8
   local w = width * a * 0.8
   local h = height * a * 0.8
   local x = (width - w) / 2
   local y = (height - h) / 2
   local lw = 2

   local c1 = {red = 1, green = 1, blue = 1}
   local c2 = {red = 1, green = 0.49, blue = 0.16}
   local c3 = {red = 1, green = 0, blue = 0}

   cr.line_width = lw

   if stateStr == "Charging" then
      cr:set_source_rgba(c2.red, c2.green, c2.blue, 1)
   elseif level > critlimit then
      cr:set_source_rgba(c1.red, c1.green, c1.blue, 1)
   else
      cr:set_source_rgba(c3.red, c3.green, c3.blue, 1)
   end

   cr:move_to(x, y); 
   cr:line_to(x, y + h)

   cr:line_to(x + w, y + h)
   cr:line_to(x + w, y + h - h / 3)
   cr:line_to(x + w + lw, y + h - h / 3)
   cr:line_to(x + w + lw, y + h - 2 * h / 3)
   cr:line_to(x + w, y + h - 2 * h / 3)
   cr:line_to(x + w, y)
   cr:line_to(x, y)
   cr:stroke()

   if level > warnlimit then 
      cr:set_source_rgba(0,1,0,1)
   elseif level > critlimit then
      cr:set_source_rgba(1,0.49,0.16,1)
   else
      cr:set_source_rgba(1,0,0,1)
   end
      
   cr:rectangle(x + lw, y + lw, (w - 2*lw) * level / 100, h - 2*lw)
   cr:fill()

   -- warnings at low levels
   if stateStr == "Charging" then
      batterywarning = {false, false}
      naughty.destroy(warning)
   else
      if level < critlimit and not batterywarning[2] then
	 warning = naughty.notify({text = "Warning: Battery Critical", timeout = 0, 
				   bg = "#FF0000", fg = "#FFFFFF"})
	 batterywarning[1] = true
	 batterywarning[2] = true

      elseif level < warnlimit and not batterywarning[1] then 
	 warning = naughty.notify({text = "Warning: Battery Low", timeout = 0, 
				   bg = "#FF6600", fg = "#FFFFFF" })
	 batterywarning[1] = true
      end
   end
   
end


batterywidget:connect_signal("mouse::enter", function() 
			    local level, state
			    level, state = getBatteryInfo()

			    local msg = level .. " (" .. state .. ")"
			    info = naughty.notify({text = msg,
						   timeout = 0,
			    })
			    
end)

batterywidget:connect_signal("mouse::leave", function()
				 naughty.destroy(info)
			     end)

local batterywidgettimer = timer({timeout = 3})
batterywidgettimer:connect_signal("timeout", function() batterywidget:emit_signal("widget::updated") end)
batterywidgettimer:start()




return batterywidget

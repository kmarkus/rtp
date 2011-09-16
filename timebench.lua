--- Create timing benchmarks in Lua.
-- This module permits creating timing benchmark functions.
-- @release Released dual BSD/LGPG.
-- @copyright Markus Klotzbuecher, Katholieke Universiteit Leuven, Belgium.

require("time")
require("rtp")

local rtp = rtp
local time = time
local error = error
local io = io
local math = math

module("timebench")

--- Create a timing measurement closure.
-- This function returns a function which will measure durations and
-- maintain simple statistics. The generated function accepts a
-- command argument. Legal values are:<br>
--    <code>'start'</code>	start a time measurement<br>
--    <code>'stop'</code>:	stop the time measurement and update the statistics<br>
--    <code>'cancel'</code>:	cancel a started time measurement. No change to statistics<br>
--    <code>'get'</code>:	returns a table of time statistics<br>
--    <code>'print'</code>:	print statistics<br>
--    <code>'clear'</code>:	clear statistics<br>
-- @param name string name to print in stats
-- @return benchmark closure function
function create_bench(name)
   local name = name or ""
   local stats = {}
   local dur_min, dur_max, total
   local active

   local function clear()
      stats.dur_min = { sec=math.huge, nsec=math.huge }
      stats.dur_max = { sec=0, nsec=0 }
      stats.total = { sec=0, nsec=0 }
      stats.cnt = 0

      -- shortcuts to speed up
      dur_min, dur_max, total = stats.dur_min, stats.dur_max, stats.total
      active = false
   end
   clear()

   local tstart = { sec=0, nsec=0 }
   local tend = { sec=0, nsec=0 }
   local dur = { sec=0, nsec=0 }

   return function (cmd)
	     if cmd == 'start' then
		if active then error("bench error: 'start' command while active!") end
		tstart.sec, tstart.nsec = rtp.clock.gettime('CLOCK_MONOTONIC')
   		active = true
   	     elseif cmd == 'stop' then
   		if not active then error("bench error: 'stop' command while inactive!") end
   		tend.sec, tend.nsec = rtp.clock.gettime('CLOCK_MONOTONIC')
   		active = false

   		-- update stats
   		stats.cnt = stats.cnt + 1
   		dur.sec, dur.nsec = time.sub(tend, tstart)
   		total.sec, total.nsec = time.add(total, dur)

   		if time.cmp(dur, dur_min) < 0 then
   		   dur_min.sec, dur_min.nsec = dur.sec, dur.nsec
   		end
   		if time.cmp(dur, dur_max) > 0 then
   		   dur_max.sec, dur_max.nsec = dur.sec, dur.nsec
   		end
	     elseif cmd == 'cancel' then
		tstart.sec, tstart.nsec = 0, 0
		active = false
   	     elseif cmd == 'get' then
   		return stats
   	     elseif cmd == 'print' then
   		local avg = {}
   		avg.sec, avg.nsec = time.div(total, stats.cnt)
   		io.stderr:write("Bench " .. name,
   				": cnt: " .. stats.cnt,
   				", max: " .. time.ts2str(dur_max),
   				", min: " .. time.ts2str(dur_min),
   				", avg: " .. time.ts2str(avg) .. "\n")
	     elseif cmd == 'clear' then
   		clear()
   	     end
   	  end
end

-- little lua garbage collection helper module
-- for timed collections depends on rtposix module

require("time")
require("rtposix")

local collectgarbage, time, rtposix, assert, math, io = collectgarbage, time, rtposix, assert, math, io

module("luagc")

function stop() collectgarbage("stop") end
function start() collectgarbage("restart") end
function set_pause(val) collectgarbage("setpause", val) end
function set_stepmul(val) collectgarbage("setstepmul", val) end
function mem_usage() return collectgarbage("count") end
function step() collectgarbage("step"); stop(); end
function full() collectgarbage("collect"); stop() end

--- step the gc at maximum for us
-- at least one run will be made
function step_max_us(us) error("unimplemented") end

function gcstat_tostring(s)
   return "type: " .. s.type .. ", duration: " .. time.ts2str(s.dur) ..
   ", collected: " .. s.mem0 - s.mem1 .. "kb" .. " (" .. s.mem0 .. "/" .. s.mem1 ..")"
end

--- perform a timed gc run
-- todo: needs update to new syntax!
-- @param type "collect" for full or "step" for incremental
-- @return gc statistics table
function timed_gc(type)
   local stat = {}
   local t0 = {}
   local t1 = {}

   stat.type = type
   stat.mem0 = mem_usage()

   t0 = rtposix.gettime("MONOTONIC")
   collectgarbage(type)

   -- collectgarbage automatically restars gc
   stop()

   t1 = rtposix.gettime("MONOTONIC")

   stat.mem1 = mem_usage()
   stat.dur = time.sub(t1,t0)

   return stat
end

---
-- create a garbage collection test closure which will perform and
-- collections and record the worst case timing behavior.
-- parameters:
-- 	call without arguments for performing a collection
--	'get_results' returns a timed_gc stats table
--	'print_results' does what it claims to
--
function create_bench(gctype)

   assert(gctype == 'collect' or gctype == 'step',
	  "create_bench: argument must be either 'collect' or 'step'")

   local stats = {}
   stats.dur_min = { sec=math.huge, nsec=math.huge }
   stats.dur_max = { sec=0, nsec=0 }
   stats.dur_avg = { sec=0, nsec=0 }
   stats.cnt = 0

   return function (cmd)
	     if cmd == 'get_results' then
		return stats
	     elseif cmd == 'print_results' then
		io.stderr:write("max: " .. time.ts2str(stats.dur_max),
				", min: " .. time.ts2str(stats.dur_min),
				", avg: " .. time.ts2str(time.div(stats.dur_avg, stats.cnt)) .. "\n")
	     else
		stats.cnt = stats.cnt+1
		local s = timed_gc(type)
		stats.dur_avg = time.add(stats.dur_avg, s.dur)

		if time.cmp(s.dur, stats.dur_min) < 0 then
		   stats.dur_min = s.dur
		end

		if time.cmp(s.dur, stats.dur_max) > 0 then
		   stats.dur_max = s.dur
		end
	     end
	  end
end

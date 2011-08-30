--- Garbage collection utility module.
--
-- For executing timed collections dependendency on rtp module.
--
-- @author Markus Klotzbuecher <markus.klotzbuecher@mech.kuleuven.be>
-- @copyright Markus Klotzbuecher, Katholieke Universiteit Leuven, Belgium.

require("time")
require("rtp")

local collectgarbage, time, rtp, assert, math, io = collectgarbage, time, rtp, assert, math, io

module("luagc")

--- Stop the garbage collector.
function stop() collectgarbage("stop") end

--- Start the garbage collector.
function start() collectgarbage("restart") end

--- Set the GC pause paramter.
function set_pause(val) collectgarbage("setpause", val) end

--- Set the GC mul paramter.
function set_stepmul(val) collectgarbage("setstepmul", val) end

--- Get current memory useage.
function mem_usage() return collectgarbage("count") end

--- Execute an incremental GC step.
function step() collectgarbage("step"); stop(); end

--- Execute a full GC collection.
function full() collectgarbage("collect"); stop() end

--- Step the gc at maximum for us microseconds.
-- at least one run will be made.
-- Not yet implemented.
function step_max_us(us) error("unimplemented") end

--- Pretty print gc statistics table.
function gcstat_tostring(s)
   return "type: " .. s.type .. ", duration: " .. time.ts2str(s.dur) ..
   ", collected: " .. s.mem0 - s.mem1 .. "kb" .. " (" .. s.mem0 .. "/" .. s.mem1 ..")"
end

--- Perform a timed gc run.
-- @param type <code>'collect'</code> for full or <code>'step'</code> for incremental
-- @return gc statistics table
function timed_gc(type)
   local stat = { dur={} }
   local dur = stat.dur
   local t0 = {}
   local t1 = {}

   stat.type = type
   stat.mem0 = mem_usage()

   t0.sec, t0.nsec = rtp.clock.gettime("CLOCK_MONOTONIC")
   collectgarbage(type)

   stop() -- collectgarbage automatically restars gc

   t1.sec, t1.nsec = rtp.clock.gettime("CLOCK_MONOTONIC")

   stat.mem1 = mem_usage()
   dur.sec, dur.nsec = time.sub(t1,t0)

   return stat
end

--- Create a gc benchmark closure.
-- This closure which will perform and collections and record the
-- worst case timing behavior. The function accepts the following
-- parameters: <br>
--	 without arguments for performing a collection <br>
--	<code>'get_results'</code> returns a timed_gc stats table <br>
--	<code>'print_results'</code> does what it claims to <br>
-- @param gctype type (<code>'collect'</code> or <code>'step'</code>) to perform when called without args.
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

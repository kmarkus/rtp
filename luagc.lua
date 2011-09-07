--- Garbage collection utility module.
--
-- For executing timed collections dependendency on rtp module.
--
-- @author Markus Klotzbuecher <markus.klotzbuecher@mech.kuleuven.be>
-- @copyright Markus Klotzbuecher, Katholieke Universiteit Leuven, Belgium.

require("time")
require("rtp")

local collectgarbage, time, rtp, assert, math, io, tostring =
   collectgarbage, time, rtp, assert, math, io, tostring

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

   local dur_min = { sec=math.huge, nsec=math.huge }
   local dur_max = { sec=0, nsec=0 }
   local dur_tot = { sec=0, nsec=0 }
   local cnt = 0

   return function (cmd)
	     if cmd == nil then
		cnt = cnt+1
		local cur = timed_gc(gctype)
		dur_tot.sec, dur_tot.nsec = time.add(dur_tot, cur.dur)

		if time.cmp(cur.dur, dur_min) < 0 then
		   dur_min.sec, dur_min.nsec = cur.dur.sec, cur.dur.nsec
		end

		if time.cmp(cur.dur, dur_max) > 0 then
		   dur_max.sec, dur_max.nsec = cur.dur.sec, cur.dur.nsec
		end
	     elseif cmd == 'get_results' then return { dur_min, dur_max, dur_tot, cnt }
	     elseif cmd == 'print_results' then
		local dur_avg = {}
		dur_avg.sec, dur_avg.nsec = time.div(dur_tot, cnt)
		io.stderr:write("gcstats - cnt: " .. tostring(cnt),
				", max: " .. time.ts2str(dur_max),
				", min: " .. time.ts2str(dur_min),
				", avg: " .. time.ts2str(dur_avg) .. "\n")
	     else
		error("create_bench/timed_gc: invalid command " .. tostring(cmd))
	     end
	  end
end

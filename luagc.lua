--
-- (C) 2010,2011 Markus Klotzbuecher, markus.klotzbuecher@mech.kuleuven.be,
-- Department of Mechanical Engineering, Katholieke Universiteit
-- Leuven, Belgium.
--
-- You may redistribute this software and/or modify it under either
-- the terms of the GNU Lesser General Public License version 2.1
-- (LGPLv2.1 <http://www.gnu.org/licenses/old-licenses/lgpl-2.1.html>)
-- or (at your discretion) of the Modified BSD License: Redistribution
-- and use in source and binary forms, with or without modification,
-- are permitted provided that the following conditions are met:
--    1. Redistributions of source code must retain the above copyright
--       notice, this list of conditions and the following disclaimer.
--    2. Redistributions in binary form must reproduce the above
--       copyright notice, this list of conditions and the following
--       disclaimer in the documentation and/or other materials provided
--       with the distribution.
--    3. The name of the author may not be used to endorse or promote
--       products derived from this software without specific prior
--       written permission.
--
-- THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS
-- OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
-- WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
-- ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
-- DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
-- DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
-- GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
-- WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
-- NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
-- SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--

--- Garbage collection utility module.
--
-- For executing timed collections dependendency on rtp module.
--
-- @author Markus Klotzbuecher <markus.klotzbuecher@mech.kuleuven.be>
-- @copyright Markus Klotzbuecher, Katholieke Universiteit Leuven, Belgium.

local time = require("time")
local rtp = require("rtp")

local M = {}

--- Stop the garbage collector.
function M.stop() collectgarbage("stop") end

--- Start the garbage collector.
function M.start() collectgarbage("restart") end

--- Set the GC pause paramter.
function M.set_pause(val) collectgarbage("setpause", val) end

--- Set the GC mul paramter.
function M.set_stepmul(val) collectgarbage("setstepmul", val) end

--- Get current memory useage.
function M.mem_usage() return collectgarbage("count") end

--- Execute an incremental GC step.
function M.step() collectgarbage("step"); M.stop(); end

--- Execute a full GC collection.
function M.full() collectgarbage("collect"); M.stop() end

--- Step the gc at maximum for us microseconds.
-- at least one run will be made.
-- Not yet implemented.
function M.step_max_us(us) error("unimplemented") end

--- Pretty print gc statistics table.
function M.gcstat_tostring(s)
   return "type: " .. s.type .. ", duration: " .. time.ts2str(s.dur) ..
   ", collected: " .. s.mem0 - s.mem1 .. "kb" .. " (" .. s.mem0 .. "/" .. s.mem1 ..")"
end

--- Perform a timed gc run.
-- @param type <code>'collect'</code> for full or <code>'step'</code> for incremental
-- @return gc statistics table
function M.timed_gc(type)
   local stat = { dur={} }
   local dur = stat.dur
   local t0 = {}
   local t1 = {}

   stat.type = type
   stat.mem0 = M.mem_usage()

   t0.sec, t0.nsec = rtp.clock.gettime("CLOCK_MONOTONIC")
   collectgarbage(type)

   M.stop() -- collectgarbage automatically restars gc

   t1.sec, t1.nsec = rtp.clock.gettime("CLOCK_MONOTONIC")

   stat.mem1 = M.mem_usage()
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
function M.create_bench(gctype)

   assert(gctype == 'collect' or gctype == 'step',
	  "create_bench: argument must be either 'collect' or 'step'")

   local dur_min = { sec=math.huge, nsec=math.huge }
   local dur_max = { sec=0, nsec=0 }
   local dur_tot = { sec=0, nsec=0 }
   local cnt = 0

   return function (cmd)
	     if cmd == nil then
		cnt = cnt+1
		local cur = M.timed_gc(gctype)
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

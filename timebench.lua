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

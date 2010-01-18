-- little lua garbage collection helper module
-- for timed collections depends on rtposix module

require("time")
require("rtposix")

local collectgarbage = collectgarbage
local time = time
local rtposix = rtposix

module("luagc")

function stop()
   collectgarbage("stop")
end

function start()
   collectgarbage("start")
end

function setpause(val)
   collectgarbage("setpause", val)
end

function setstepmul(val)
   collectgarbage("setstepmul", val)
end

function mem_usage()
   return collectgarbage("count")
end

function gcstat_tostring(s)
   return "type: " .. s.type .. ", duration: " .. time.ts2str(s.dur) ..
   ", collected: " .. s.mem0 - s.mem1 .. "kb" .. " (" .. s.mem0 .. "/" .. s.mem1 ..")"
end

-- perform a time gc run
-- type is "collect" for full or "step" for incremental
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

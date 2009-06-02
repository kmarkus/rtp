#!/usr/bin/lua
require("rtposix")

param = {}
param.tabnum = 1
param.tabsize = 1000000

function gen_garbage(num, tabsize)
   for n = 1,num do
      local t = {}
      for i = 1,tabsize do
	 table.insert(t,i)
      end
      t = {}
   end
end

-- helpers
function timersub(t1, t0)
   local res = {}
   if t1.sec == t0.sec then
      res.sec = 0
      res.nsec = t1.nsec - t0.nsec
   else
      res.sec = t1.sec - t0.sec
      res.nsec = t1.nsec + 1000000 - t0.sec
      
      if res.nsec >= 1000000 then
	 res.sec = res.sec + 1
	 res.nsec = res.nsec - 1000000
      end
   end
   return res
end

function timercmp(t1, t2)
   if(t1.sec > t2.sec) then
      return 1
   elseif (t1.sec < t2.sec) then
      return -1
   elseif (t1.nsec > t2.nsec) then
      return 1
   elseif (t1.nsec < t2.nsec) then
      return -1
   else
      return 0
   end
end

function tv2str(t)
   return t.sec .. "s" .." " .. t.nsec .. "ns"
end

function print_gcstat(s)
   print("type: " .. s.type .. ", duration: " .. tv2str(s.dur) .. ", collected: " .. s.mem0 - s.mem1 .. "kb" .. " (" .. s.mem0 .. "/" .. s.mem1 ..")")
end

-- perform a time gc run
-- type is "collect" for full or "step" for incremental
function timed_gc(type)
   local stat = {}
   local t0 = {}
   local t1 = {}

   stat.type = type
   stat.mem0 = collectgarbage("count")

   t0 = rtposix.gettime("MONOTONIC")
   collectgarbage(type)

   -- is automatically restarted
   collectgarbage("stop")
   t1 = rtposix.gettime("MONOTONIC")

   stat.mem1 = collectgarbage("count")
   stat.dur = timersub(t1,t0)

   return stat
end

function stop_gc()
   collectgarbage("stop")
   print("stopped GC")
end

function start_gc()
   print("starting GC")
   collectgarbage("start")
end


-- helper
function print_stats(s)
   print("max duration: " .. tv2str(s.dur_max), "min duration: " .. tv2str(s.dur_min))
end

-- initalize things
stats = {}
stats.dur_min = { sec=math.huge, nsec=math.huge }
stats.dur_max = { sec=0, nsec=0 }

stop_gc()
print("doing initial full collect")
print_gcstat(timed_gc("collect"))

for i = 1,math.huge do
   gen_garbage(param.tabnum, param.tabsize)
   s = timed_gc("step")
   
   if timercmp(s.dur, stats.dur_min) < 0 then
      stats.dur_min = s.dur
      print_stats(stats)
   end

   if timercmp(s.dur, stats.dur_max) > 0 then
      stats.dur_max = s.dur
      print_stats(stats)
   end

end

print("Statistics")
print_stats(stats)

print("doing final full collect")
print_gcstat(timed_gc("collect"))




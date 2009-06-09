#!/usr/bin/lua
require("rtposix")

param = {}
param.data_tabnum = 20
param.data_tabsize = 20
param.garbage_tabnum = 20
param.garbage_tabsize = 20

--param.type = "collect"
param.type = "step"

param.num_runs = math.huge
param.sleep_ns = 0

-- output data or not
param.quiet = false

-- generate num garbage tables of tabsize
function gen_garbage(num, tabsize)
   for n = 1,num do
      local t = {}
      for i = 1,tabsize do
	 table.insert(t,i)
      end
      t = {}
   end
end

-- generate num data tables of tabsize
data = {}
function gen_data(num, tabsize)
   for n = 1,num do
      local t = {}
      for i = 1,tabsize do
	 table.insert(t,i)
      end
      table.insert(data, t)
   end
end

-- helpers
function log(...)
   io.stderr:write(unpack(arg))
   io.stderr:write("\n")
end

function timersub(a, b)
   local res = {}
   res.sec = a.sec - b.sec
   res.nsec = a.nsec - b.nsec

   if res.nsec < 0 then
      res.sec = res.sec - 1
      res.nsec = res.nsec + 1000000000
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

function timespec2us(ts)
   return ts.sec * 1000000 + ts.nsec / 1000
end

function timespec2str(ts)
   return timespec2us(ts) .. "us"
end

function print_gcstat(s)
   log("type: " .. s.type .. ", duration: " .. timespec2str(s.dur) .. ", collected: " .. s.mem0 - s.mem1 .. "kb" .. " (" .. s.mem0 .. "/" .. s.mem1 ..")")
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

function gc_stop()
   collectgarbage("stop")
   log("stopped GC")
end

function gc_start()
   log("starting GC")
   collectgarbage("start")
end

function gc_setpause(val)
   print("setting gcpause to ", val)
   collectgarbage("setpause", val)
end

function gc_setstepmul(val)
   log("setting setstepmul to ", val)
   collectgarbage("setstepmul", val)
end
   

-- initalize things
stats = {}
stats.dur_min = { sec=math.huge, nsec=math.huge }
stats.dur_max = { sec=0, nsec=0 }

-- initalize data
gen_data(param.data_tabnum, param.garbage_tabsize)

rtposix.mlockall("MCL_BOTH")
rtposix.sched_setscheduler(0, "SCHED_FIFO", 99)

gc_stop()

log("doing initial full collect")
print_gcstat(timed_gc("collect"))


for i = 1,param.num_runs do
   
   gen_garbage(param.garbage_tabnum, param.garbage_tabsize)

   s = timed_gc(param.type)

   if timercmp(s.dur, stats.dur_min) < 0 then
      stats.dur_min = s.dur
   end

   if timercmp(s.dur, stats.dur_max) > 0 then
      stats.dur_max = s.dur
   end

   if not param.quiet then
      print(i .. ", " .. timespec2us(s.dur))
   end

   if i % 30000 == 0 then
      io.stderr:write("max duration: " .. timespec2str(stats.dur_max), ", min duration: " .. timespec2str(stats.dur_min) .."\n")
   end

   rtposix.nanosleep("MONOTONIC", "rel", 0, param.sleep_ns)
end

log("Statistics")
log("max duration: " .. timespec2str(stats.dur_max), " min duration: " .. timespec2str(stats.dur_min))

log("doing final full collect")
print_gcstat(timed_gc("collect"))




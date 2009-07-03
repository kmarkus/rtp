
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

function timeradd(a, b)
   local res = {}
   res.sec = a.sec + b.sec
   res.nsec = a.nsec + b.nsec

   if res.nsec >= 1000000000 then
      res.sec = res.sec + 1
      res.nsec = res.nsec - 1000000000
   end
   return res
end

function timerdiv(t, d)
   local res = {}
   res.sec = t.sec / d
   res.nsec = t.nsec / d
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

function do_test(num_runs, garbage_tabnum, garbage_tabsize, 
		 data_tabnum, data_tabsize, sleep_ns, type, quiet)

   -- initalize things
   local stats = {}
   stats.dur_min = { sec=math.huge, nsec=math.huge }
   stats.dur_max = { sec=0, nsec=0 }
   stats.dur_avg = { sec=0, nsec=0 }

   data = gen_data(data_tabnum, data_tabsize)

   for i = 1,num_runs do

      gen_garbage(garbage_tabnum, garbage_tabsize)
      
      s = timed_gc(type)
      
      stats.dur_avg = timeradd(stats.dur_avg, s.dur)

      if timercmp(s.dur, stats.dur_min) < 0 then
	 stats.dur_min = s.dur
      end

      if timercmp(s.dur, stats.dur_max) > 0 then
	 stats.dur_max = s.dur
      end

      if not quiet then
	 print(i .. ", " .. timespec2us(s.dur) .. ", " .. s.mem0 .. ", " .. s.mem1)
      end

      if i % 10000 == 0 then
	 io.stderr:write("max: " .. timespec2str(stats.dur_max), 
			 ", min: " .. timespec2str(stats.dur_min),
			 ", avg: " .. timespec2str(timerdiv(stats.dur_avg, i)) .. "\n")
      end
      rtposix.nanosleep("MONOTONIC", "rel", 0, sleep_ns)
   end
   return stats
end

function pp_table(t)
   if t == nil then
      print("nil table")
      return nil
   else
      for i,v in pairs(t) do
	 print(i,v)
      end
   end
end

-- execution starts here
require("rtposix")

if #arg < 8 then
   io.stderr:write("usage: " .. arg[0] .. " <num_runs> <garbage_tabsize> <garbage_tabnum> <data_tabsize> <data_tabnum> <sleep_ns> <type> <quiet>\n")
   return false
end

par = {}
par.num_runs = arg[1] or 100000
par.garbage_tabsize = arg[2] or 20
par.garbage_tabnum = arg[3] or 20
par.data_tabsize = arg[4] or 20
par.data_tabnum = arg[5] or 20
par.sleep_ns = arg[6] or 0
par.type = arg[7] or "step"
par.quiet = arg[8] == "true" or false

io.stderr:write("Parameters:\n")
for k,v in pairs(par) do
   log("\t", k, ": ", tostring(v))
end

rtposix.mlockall("MCL_BOTH")
rtposix.sched_setscheduler(0, "SCHED_FIFO", 99)

gc_stop()

io.stderr:write("running initial full collect: ") --log("doing initial full collect")
print_gcstat(timed_gc("collect"))

local stats = do_test(par.num_runs, par.garbage_tabsize, par.garbage_tabnum, par.data_tabsize, par.data_tabnum, par.sleep_ns, par.type, par.quiet)

io.stderr:write("running final full collect: ")
print_gcstat(timed_gc("collect"))

log("Statistics")
log("\tmax dur: ",  timespec2str(stats.dur_max))
log("\tmin dur: ",  timespec2str(stats.dur_min))
log("\tavg dur: ",  timespec2us(timerdiv(stats.dur_avg, par.num_runs)))

if par.quiet then
   print(timespec2us(stats.dur_max) .. ", " .. timespec2us(stats.dur_min) .. ", " .. timespec2us(timerdiv(stats.dur_avg, par.num_runs)))
end



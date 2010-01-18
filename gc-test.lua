require("rtposix")
require("luagc")
require("time")

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

      s = luagc.timed_gc(type)

      stats.dur_avg = time.add(stats.dur_avg, s.dur)

      if time.cmp(s.dur, stats.dur_min) < 0 then
	 stats.dur_min = s.dur
      end

      if time.cmp(s.dur, stats.dur_max) > 0 then
	 stats.dur_max = s.dur
      end

      if not quiet then
	 print(i .. ", " .. time.timespec2us(s.dur) .. ", " .. s.mem0 .. ", " .. s.mem1)
      end

      if i % 10000 == 0 then
	 io.stderr:write("max: " .. time.ts2str(stats.dur_max),
			 ", min: " .. time.ts2str(stats.dur_min),
			 ", avg: " .. time.ts2str(time.div(stats.dur_avg, i)) .. "\n")
      end
      rtposix.nanosleep("MONOTONIC", "rel", 0, sleep_ns)
   end
   return stats
end

function pp_table(t)
   assert(type(t) == 'table')
   table.foreach(t, print)
end

-- execution starts here


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

luagc.stop()

io.stderr:write("running initial full collect: ") --log("doing initial full collect")
luagc.gcstat_tostring(luagc.timed_gc("collect"))

local stats = do_test(par.num_runs,
		      par.garbage_tabsize,
		      par.garbage_tabnum,
		      par.data_tabsize,
		      par.data_tabnum,
		      par.sleep_ns,
		      par.type, par.quiet)

io.stderr:write("running final full collect: ")
luagc.gcstat_tostring(luagc.timed_gc("collect"))

log("Statistics")
log("\tmax dur: ",  time.ts2str(stats.dur_max))
log("\tmin dur: ",  time.ts2str(stats.dur_min))
log("\tavg dur: ",  time.ts2us(time.div(stats.dur_avg, par.num_runs)))

if par.quiet then
   print(time.ts2us(stats.dur_max) .. ", " .. time.ts2us(stats.dur_min) .. ", " .. time.ts2us(time.div(stats.dur_avg, par.num_runs)))
end

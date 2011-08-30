#!/usr/bin/env lua

require("rtp")
require("time")
require("timebench")
require("utils")

local version = 0.1
local header = "Lua cyclictest v".. tostring(version)

local csv = false
local verb = false
local prio = 80
local interval = 1000
local loops = 1000
local sched = 'SCHED_FIFO'

function usage()
   print(( [=[
%s
Usage:
    cyclictest <options>
	-p PRIO		realtime priority (default=80)
	-l LOOPS	number of loops (default=0 (endless))
	-i INTERVAL	interval between wakeups in us (default 1000)
	-v	 	enable verbose output
     ]=] ):format(header))
end

function round(num, idp)
   local mult = 10^(idp or 0)
   return math.floor(num * mult + 0.5) / mult
end

-- if verbose, log to stderr
function log(...)
   local outtab= {...}
   if verb then
      for k,v in pairs(outtab) do io.stderr:write(tostring(v)) end
      io.stderr:write('\n')
   end
end

-- setup command line options
function setup_opts(opts)
   if opts['-h'] then usage(); os.exit(0) end

   if opts['-v'] then
      if not verb then verb = true end
   end

   if opts['-l'] then
      loops = tonumber(opts['-l'][1])
      assert(type(loops) == 'number', "Invalid number of loops")
   end
   if loops == 0 then loops = math.huge end

   if opts['-p'] then
      prio = tonumber(opts['-p'][1])
   end
   assert(type(prio)=='number', "Invalid priority")
   assert((prio<=99 and prio>0), "Invalid real-time priority (0-99): " .. prio)

   if prio == 0 then sched = 'SCHED_OTHER' end

   if opts['-i'] then
      interval = tonumber(opts['-i'][1])
   end

   if opts['-csv'] then csv = true end
   assert(type(interval)=='number' and interval > 0 , "Invalid interval")
end

local opts = utils.proc_args(arg)
setup_opts(opts)

log(header)
log("   System:    ", rtp.sysinfo())
log("   Priority:  ", prio)
log("   Interval:  ", interval)
log("   Loops:     ", loops)
log("   Scheduler: ", sched)

-- mlockall
if not rtp.mlockall("MCL_BOTH") then error("mlockall failed.") end

-- sched_setscheduler
if not rtp.pthread.setschedparam(0, sched, prio) then
   error("sched_setscheduler failed!")
end

local intv = { sec=0, nsec=0 }
intv.sec, intv.nsec = time.normalize(0, interval*1000)

local tcur = { sec=0, nsec=0 }
local tnext = { sec=0, nsec=0 }
local diff = { sec=0, nsec=0 }
local dmin = { sec=math.huge, nsec=math.huge }
local dmax = { sec=0, nsec=0 }
local davg = { sec=0, nsec=0 }
local cnt = 0

-- fireup
tcur.sec, tcur.nsec = rtp.clock.gettime('CLOCK_MONOTONIC')
tnext.sec, tnext.nsec = time.add(tcur, intv)
rtp.clock.nanosleep('CLOCK_MONOTONIC', 'abs', tnext.sec, tnext.nsec)

while cnt < loops do
   tcur.sec, tcur.nsec = rtp.clock.gettime('CLOCK_MONOTONIC')
   diff.sec, diff.nsec = time.sub(tcur, tnext)

   if time.cmp(diff, dmin) == -1 then
      dmin.sec, dmin.nsec = diff.sec, diff.nsec
   end

   if time.cmp(diff, dmax) == 1 then
      dmax.sec, dmax.nsec = diff.sec, diff.nsec
   end

   davg.sec, davg.nsec = time.add(davg, diff)

   tnext.sec, tnext.nsec = time.add(tnext, intv)
   cnt=cnt+1
   rtp.clock.nanosleep('CLOCK_MONOTONIC', 'abs', tnext.sec, tnext.nsec)
end

local avg = {}
avg.sec, avg.nsec = time.div(davg, cnt)

log("intv: " .. time.ts2str(intv))
log("cnt: " .. tostring(cnt))
log("min: " .. time.ts2str(dmin))
log("max: " .. time.ts2str(dmax))
log("avg: " .. time.ts2str(avg))

if csv then
   print(('"p:%d (%s), i:%d, l:%d", %d, %d, %d'):format(prio, sched, interval,
							loops, round(time.ts2us(dmin)),
							round(time.ts2us(dmax)), round(time.ts2us(avg))))
end

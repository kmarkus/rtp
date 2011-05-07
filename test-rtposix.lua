#!/usr/bin/env lua

require("rtposix")
require("time")
require("timebench")

-- clock_getres
print("clock_getres: ", rtposix.clock_getres("CLOCK_REALTIME"))

-- sched_setscheduler
print("setting scheduler to SCHED_FIFO, prio=88")
rtposix.sched_setscheduler(0, 'SCHED_FIFO', 88)

local t0 = { sec=0, nsec=0 }
local t1 = { sec=0, nsec=0 }

-- gettime
print("gettime (sleeping 100ms)")
for i=1,5 do
   t0.sec, t0.nsec = rtposix.clock_gettime("CLOCK_MONOTONIC")
   rtposix.clock_nanosleep("CLOCK_REALTIME", "rel", 0, 100000000)
   t1.sec, t1.nsec = rtposix.clock_gettime("CLOCK_MONOTONIC")
   print("t0:" .. time.ts2us(t0), "t1:" .. time.ts2us(t1))
end

-- mlockall/munlockall

print("mlockall: ", rtposix.mlockall("MCL_BOTH"))

bench = timebench.create_bench()

print("creating bench for sleeping 100us")
for i=1,10000 do
   bench('start')
   rtposix.clock_nanosleep("CLOCK_REALTIME", "rel", 0, 100000)
   bench('stop')
end
bench('print')
bench('clear')

print("creating bench for sleeping 1ms")
for i=1,10000 do
   bench('start')
   rtposix.clock_nanosleep("CLOCK_REALTIME", "rel", 0, 1000000)
   bench('stop')
end
bench('print')

print("absolute clock_nanosleep for 1s")
sec, nsec = rtposix.clock_gettime("CLOCK_REALTIME")
rtposix.clock_nanosleep("CLOCK_REALTIME", 'abs', sec+1, nsec )

rtposix.sched_setscheduler(0, 'SCHED_OTHER', 0)
print("munlockall: ", rtposix.munlockall())
   



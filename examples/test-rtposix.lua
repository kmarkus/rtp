#!/usr/bin/env lua

local rtp = require("rtp")
local time = require("time")
local timebench = require("timebench")

-- mlockall/munlockall
print("mlockall: ", rtp.mlockall("MCL_BOTH"))

-- clock.getres
print("clock.getres: ", rtp.clock.getres("CLOCK_REALTIME"))

-- pthread.setschedparam
print("setting scheduler to SCHED_FIFO, prio=88")
rtp.pthread.setschedparam(0, 'SCHED_FIFO', 88)

local t0 = { sec=0, nsec=0 }
local t1 = { sec=0, nsec=0 }

-- gettime
print("gettime (sleeping 100ms)")
for i=1,5 do
   t0.sec, t0.nsec = rtp.clock.gettime("CLOCK_MONOTONIC")
   rtp.clock.nanosleep("CLOCK_REALTIME", "rel", 0, 100000000)
   t1.sec, t1.nsec = rtp.clock.gettime("CLOCK_MONOTONIC")
   print("t0:" .. time.ts2us(t0), "t1:" .. time.ts2us(t1))
end

bench = timebench.create_bench()

print("creating bench for sleeping 100us")
for i=1,10000 do
   bench('start')
   rtp.clock.nanosleep("CLOCK_REALTIME", "rel", 0, 100000)
   bench('stop')
end
bench('print')
bench('clear')

print("creating bench for sleeping 1ms")
for i=1,10000 do
   bench('start')
   rtp.clock.nanosleep("CLOCK_REALTIME", "rel", 0, 1000000)
   bench('stop')
end
bench('print')

print("absolute clock_nanosleep for 1s")
sec, nsec = rtp.clock.gettime("CLOCK_REALTIME")
rtp.clock.nanosleep("CLOCK_REALTIME", 'abs', sec+1, nsec )

rtp.pthread.setschedparam(0, 'SCHED_OTHER', 0)
print("munlockall: ", rtp.munlockall())
   



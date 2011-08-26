
--- minimal example to get a xenomai lua script up and running
-- only one mode switch will occur when the script is moved to the
-- primary domain. After that the loop runs in hard real-time.

require "rtp"


if not rtp.mlockall("MCL_BOTH") then 
   error("mlockall failed.") 
end

-- sched_setscheduler
if not rtp.pthread.setschedparam(0, 'SCHED_FIFO', 99) then
   error("sched_setscheduler failed!")
end

for i=1,5000 do
   rtp.clock.nanosleep('CLOCK_REALTIME', 'rel', 0, 1000000)
end





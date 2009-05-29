require("rtposix")
dofile("../mylib/misc.lua")

-- clock_getres
print("clock_getres")
pp_table(rtposix.getres("REALTIME"))

-- nanosleep
print("nanosleep")
sec=0
nsec=100000000
print("sleeing for sec=" .. sec .. ", nsec=" .. nsec .. ", retval=", rtposix.nanosleep("REALTIME", "rel", sec, nsec))

-- gettime
print("gettime (sleeping 100ms)")
for i=1,3 do
   t0 = rtposix.gettime("MONOTONIC")
   rtposix.nanosleep("REALTIME", "rel", sec, nsec)
   t1 = rtposix.gettime("MONOTONIC")
   print("t0: sec=" .. t0.sec .. ", nsec=" .. t0.nsec)
   print("t1: sec=" .. t1.sec .. ", nsec=" .. t1.nsec)
end

-- mlockall/munlockall

print("mlockall: ", rtposix.mlockall("MCL_CURRENT"))

t = {}
for i = 1,100 do
   table.insert(t, i)
end

print("munlockall: ", rtposix.munlockall())
   




require("rtposix")

sec=0
nsec=100000000

for i=1,10 do
   print("sleeing for sec=", sec, "nsec=", nsec, "retval=", rtposix.nanosleep("REALTIME", "rel", sec, nsec))
end

#!/usr/bin/lua

require("pthreads")

for i=1,10 do
   print("thread#:" .. i .. ", tid: ",  pthreads.spawn('print("hello world, my tid is",  self)'))
end

-- wait
pthreads.wait()
print("done!!")

#!/usr/bin/lua

require("pthreads")

threads = {}
for i=1,10 do
   -- tid = pthreads.spawn('print("hello world, my tid is",  self)')
   tid = pthreads.spawn('dofile("./pthreads-test2.lua")')
   print("thread#:" .. i .. ", tid: ", tid )
   table.insert(threads, tid)
end

-- wait

for i,v in ipairs(threads) do
   print("joining ", v)
   pthreads.join(v)
end

print("done!!")

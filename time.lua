-- sys/time.h like operations
--
-- take struct timespec tables with 'sec' and 'nsec' fields as input
--

module("time")

function sub(a, b)
   local res = {}
   res.sec = a.sec - b.sec
   res.nsec = a.nsec - b.nsec

   if res.nsec < 0 then
      res.sec = res.sec - 1
      res.nsec = res.nsec + 1000000000
   end
   return res
end

function add(a, b)
   local res = {}
   res.sec = a.sec + b.sec
   res.nsec = a.nsec + b.nsec

   if res.nsec >= 1000000000 then
      res.sec = res.sec + 1
      res.nsec = res.nsec - 1000000000
   end
   return res
end

function div(t, d)
   local res = {}
   res.sec = t.sec / d
   res.nsec = t.nsec / d
   return res
end

function cmp(t1, t2)
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

function ts2us(ts)
   return ts.sec * 1000000 + ts.nsec / 1000
end

function ts2str(ts)
   return ts2us(ts) .. "us"
end

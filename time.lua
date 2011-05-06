--- sys/time.h like operations
--
-- take struct timespec tables with 'sec' and 'nsec' fields as input
--

module("time")

--- Subtract a timespec from another and normalize
-- @param a timespec to subtract from
-- @param b timespec to subtract
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

--- Add a timespec from another and normalize
-- @param a timespec a
-- @param b timespec b
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

--- Divide a timespec inplace
-- @param t timespec to divide
-- @param d divisor
function div(t, d)
   local res = {}
   res.sec = t.sec / d
   res.nsec = t.nsec / d
   return res
end

--- Compare to timespecs
-- @result return 1 if t1 is greater than t2, -1 if t1 is less than t2 and 0 if t1 and t2 are equl
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

--- Convert timespec to microseconds
-- @param ts timespec
-- @result number of microseconds
function ts2us(ts)
   return ts.sec * 1000000 + ts.nsec / 1000
end

--- Convert a timespec to a string (in micro-seconds)
--- for pretty printing purposes
function ts2str(ts)
   return ts2us(ts) .. "us"
end

--- Various sys/time.h like operations.
-- Take struct timespec tables with 'sec' and 'nsec' fields as input
-- and return two values sec, nsec
-- @release Released under DualBSD/LGPG
-- @copyright Markus Klotzbuecher, Katholieke Universiteit Leuven, Belgium.

local math = math

module("time")

-- constants
local ns_per_s = 1000000000
local us_per_s = 1000000

--- Normalize time.
-- @param sec seconds
-- @param nsec nanoseconds
function normalize(sec, nsec)
   if sec > 0 and nsec > 0 then
      while nsec >= ns_per_s do
	 sec = sec + 1
	 nsec = nsec - ns_per_s
      end
   elseif sec > 0 and nsec < 0 then
      while nsec <= 0 do
	 sec = sec - 1
	 nsec = nsec + ns_per_s
      end
   elseif sec < 0 and nsec > 0 then
      while nsec > 0 do
	 sec = sec + 1
	 nsec = nsec - ns_per_s
      end
   elseif sec < 0 and nsec < 0 then
      while nsec <= -ns_per_s do
	 sec = sec - 1
	 nsec = nsec + ns_per_s
      end
   end
   return sec, nsec
end

--- Subtract a timespec from another and normalize
-- @param a timespec to subtract from
-- @param b timespec to subtract
function sub(a, b)
   local sec = a.sec - b.sec
   local nsec = a.nsec - b.nsec
   return normalize(sec, nsec)
end

--- Add a timespec from another and normalize
-- @param a timespec a
-- @param b timespec b
function add(a, b)
   local sec = a.sec + b.sec
   local nsec = a.nsec + b.nsec
   return normalize(sec, nsec)
end

--- Divide a timespec inplace
-- @param t timespec to divide
-- @param d divisor
function div(t, d)
   return normalize(t.sec / d, t.nsec / d)
end

--- Compare to timespecs
-- @result return 1 if t1 is greater than t2, -1 if t1 is less than t2 and 0 if t1 and t2 are equal
function cmp(t1, t2)
   if(t1.sec > t2.sec) then return 1
   elseif (t1.sec < t2.sec) then return -1
   elseif (t1.nsec > t2.nsec) then return 1
   elseif (t1.nsec < t2.nsec) then return -1
   else return 0 end
end

-- Return absolute timespec.
-- @param ts timespec
-- @return absolute sec
-- @return absolute nsec
function abs(ts)
   return math.abs(ts.sec), math.abs(ts.nsec)
end

--- Convert timespec to microseconds
-- @param ts timespec
-- @result number of microseconds
function ts2us(ts)
   return ts.sec * us_per_s + ts.nsec / 1000
end

--- Convert a timespec to a string (in micro-seconds)
--- for pretty printing purposes
function ts2str(ts)
   return ("%dus"):format(ts2us(ts))
end

--- Convert timespec to us
-- @param sec
-- @param nsec
-- @return time is us
function tous(sec, nsec)
   return sec * us_per_s + nsec / 1000
end

--- Convert timespec to us string
-- @param sec
-- @param nsec
-- @return time string
function tostr_us(sec, nsec)
   return ("%dus"):format(tous(sec, nsec))
end
require("rtposix")

print("TID: ", self)
print("sleeping for 5 sec")
for i=1,5 do
   io.write(i .. " ")
   rtposix.nanosleep("REALTIME", "rel", 1, 0)
end

-- this is just a sample
print("Actual APPLICATION file")
print("Memory heap: "..node.heap())
print("")
print("Status codes:")
for k, v in pairs(updFB) do
  print(k, v)
end
print("")
print("Going to sleep for 1 second")
node.dsleep(1000000)

shell.run("/usr/bin/easy-shell execute")

if fs.exists("/tmp") == true then
  fs.delete("/tmp")
end

if fs.isDir("/usr/startup") == true then
  local FileList = fs.list("/usr/startup")
  for _,file in ipairs(FileList) do
    shell.run("/usr/startup/"..file)
  end
end

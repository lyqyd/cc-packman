local versionNumber = 1.3
local unpack = unpack or table.unpack

os.unloadAPI("package")

local args = {...}

local opwords = {
	install = true,
	remove = true,
	update = true,
	list = true,
	search = true,
}

local argwords = {
	fetch = true,
	force = true,
	target = 1,
}

if #args < 1 or (not opwords[args[1]] and not argwords[args[1]]) then
	io.write("Usage:\n")
	io.write("packman [options] install <package name[s]>\n")
	io.write("packman [options] update <package name[s]>\n")
	io.write("packman [options] remove <package name[s]>\n")
	io.write("packman [options] list [pattern]\n")
	io.write("packman [options] search [pattern]\n")
	io.write("\n")
	io.write("Options:\n")
	io.write("fetch\n")
	io.write("    Update repository and package lists before performing operations (can be used without an operation)\n")
	io.write("force\n")
	io.write("    Force yes answers when manipulating packages\n")
	io.write("target <directory>\n")
	io.write("    Set root directory to install packages in\n")
	return
end

local mode = ""
local forced = false
local target = "/"
local fetch = false
local argState = nil
local argCount = 0
local operation = {options = {}, arguments = {}}

--lower all arguments
for i = 1, #args do
	args[i] = string.lower(args[i])
	if argState == nil and args[i] == "fetch" then fetch = true end
	if argState == nil and args[i] == "force" then forced = true end

	if argwords[args[i]] and type(argwords[args[i]]) == "number" then
		operation.options[args[i]] = {}
		argState = args[i]
		argCount = argwords[args[i]]
	elseif opwords[args[i]] then
		mode = args[i]
		argState = "arguments"
		argCount = 0
	elseif argState and argCount > 0 then
		--option arguments
		table.insert(operation.options[argState], args[i])
		argCount = argCount - 1
		if argCount == 0 then argState = nil end
	elseif argState == "arguments" then
		--operation arguments
		table.insert(operation.arguments, args[i])
	end
end

if operation.options.target then
	target = operation.options.target[1]
end

local function resetScreen()
	term.setTextColor(colors.white)
	term.setBackgroundColor(colors.black)
end

local printError, printWarning, printInformation

local function loadPackageAPI()
	if not package then if shell.resolveProgram("package") then os.loadAPI(shell.resolveProgram("package")) elseif fs.exists("usr/apis/package") then os.loadAPI("usr/apis/package") elseif not fetch then error("Could not load package API!") end end

	if package then
		function printError(errorText)
			if term.isColor() then term.setTextColor(colors.red) end
			io.write(errorText.."\n")
			term.setTextColor(colors.white)
			error()
		end

		package.printError = printError

		function printWarning(warningText)
			if term.isColor() then term.setTextColor(colors.yellow) end
			io.write(warningText.."\n")
			term.setTextColor(colors.white)
		end

		package.printWarning = printWarning

		function printInformation(infoText)
			if term.isColor() then term.setTextColor(colors.lime) end
			io.write(infoText.."\n")
			term.setTextColor(colors.white)
		end

		package.printInformation = printInformation

		resetScreen()
		io.write("Loading database...\n")
		package.installRoot = target
		package.load()
	end
end

loadPackageAPI()

local categoryList = {}
local categorySorted = {}

if fetch then
	local queue
	if package and not pack then
		queue = package.newTransactionQueue("main/packman")
	end
	io.write("Updating packman\n")
	local remoteHandle = http.get("https://raw.github.com/lyqyd/cc-packman/master/packman")
	if remoteHandle then
		if pack then
			pack.addFile(shell.getRunningProgram(), remoteHandle.readAll())
		elseif queue then
			queue:addFile(shell.getRunningProgram(), remoteHandle.readAll())
		else
			local fileHandle = io.open(shell.getRunningProgram(), "w")
			if fileHandle then
				fileHandle:write(remoteHandle.readAll())
				fileHandle:close()
			else
				printWarning("Could not write file "..shell.getRunningProgram())
			end
		end
		remoteHandle.close()
	else
		printWarning("Could not retrieve remote file.")
	end
	io.write("Updating package API\n")
	remoteHandle = http.get("https://raw.github.com/lyqyd/cc-packman/master/package")
	if remoteHandle then
		if pack then
			pack.makeDir("/usr/apis")
			pack.addFile("/usr/apis/package", remoteHandle.readAll())
		elseif queue then
			queue:makeDir("/usr/apis")
			queue:addFile("/usr/apis/package", remoteHandle.readAll())
		else
			if not fs.exists("/usr/apis") then fs.makeDir("/usr/apis") end
			local fileHandle = io.open("/usr/apis/package", "w")
			if fileHandle then
				fileHandle:write(remoteHandle.readAll())
				fileHandle:close()
			else
				printWarning("Could not write file /usr/apis/package")
			end
		end
		remoteHandle.close()
	else
		printWarning("Could not retrieve remote file.")
	end
	io.write("Fetching Repository List\n")
	remoteHandle = http.get("https://raw.github.com/lyqyd/cc-packman/master/repolist")
	if remoteHandle then
		if pack then
			pack.makeDir("/etc")
			pack.addFile("/etc/repolist", remoteHandle.readAll())
		elseif queue then
			queue:makeDir("/etc")
			queue:addFile("/etc/repolist", remoteHandle.readAll())
		else
			local fileHandle = io.open("/etc/repolist", "w")
			if fileHandle then
				fileHandle:write(remoteHandle.readAll())
				fileHandle:close()
			else
				printWarning("Could not write file /etc/repolist")
			end
		end
		remoteHandle.close()
	else
		printWarning("could not retrieve remote file.")
	end
	if fs.exists("/etc/repolist") then
		if pack then
			pack.makeDir("/etc/repositories")
		elseif queue then
			queue:makeDir("/etc/repositories")
		else
			if not fs.exists("/etc/repositories") then fs.makeDir("/etc/repositories") end
		end

		local handle = io.open("/etc/repolist", "r")
		if handle then
			for line in handle:lines() do
				local file, url = string.match(line, "^(%S*)%s*(.*)")
				if file and url then
					io.write("Fetching Repository: "..file.."\n")
					local remoteHandle = http.get(url)
					if remoteHandle then
						if pack then
							pack.addFile(fs.combine("/etc/repositories", file), remoteHandle.readAll())
						elseif queue then
							queue:addFile(fs.combine("/etc/repositories", file), remoteHandle.readAll())
						else
							local fileHandle = io.open(fs.combine("/etc/repositories", file), "w")
							if fileHandle then
								fileHandle:write(remoteHandle.readAll())
								fileHandle:close()
							else
								printWarning("Could not write file: "..fs.combine("/etc/repositories", file))
							end
						end
						remoteHandle.close()
					else
						printWarning("Could not retrieve remote file: "..file)
					end
				end
			end
		else
			printError("Failed to open repository list")
		end
	end

	if queue then
		queue:finish()
	end

	fetch = false

	if #mode > 0 then
		--reload package API.
		os.unloadAPI("package")
		loadPackageAPI()
	end
end

if #mode > 0 then
	for n, v in pairs(package.list) do
		if v.category then
			for category in pairs(v.category) do
				if not categoryList[category] then
					categoryList[category] = {[n] = true}
					table.insert(categorySorted, category)
				else
					categoryList[category][n] = true
				end
			end
		end
	end
	table.sort(categorySorted)

	--flesh out dependencies
	for pName, pData in pairs(package.list) do
		if pData.dependencies then
			pData.dependencies, errmsg = package.findDependencies(pName, {})
			if not pData.dependencies then
				--if dependencies could not be resolved, remove the package.
				printWarning("Could not resolve dependency on "..errmsg.." in package "..pName)
				package.list[pName] = nil
			end
		end
	end
end

local function lookupPackage(name, installedOnly)
	if package.list[name] and not package.list[name].dependencies then
		local options = {}
		if installedOnly and package.installed[name] then
			for name, pack in pairs(package.installed[name]) do
				table.insert(options, name)
			end
		elseif installedOnly then
			--using installedOnly, but no packages of that name are installed.
			return false
		else
			for name, pack in pairs(package.list[name]) do
				table.insert(options, name)
			end
		end
		if #options > 1 then
			io.write("Package "..name.." is ambiguous.\n")
			for i = 1, #options do
				write(tostring(i)..": "..options[i].."  ")
			end
			io.write("\n")
			io.write("Select option: \n")
			local selection = io.read()
			if tonumber(selection) and options[tonumber(selection)] then
				return options[tonumber(selection)].."/"..name
			end
		elseif #options == 1 then
			return options[1].."/"..name
		else
			return false
		end
	elseif package.list[name] then
		--since it must have a dependencies table, the name is already fully unique.
		return name
	else
		return false
	end
end

local function raw_package_operation(name, funcName)
	local pack = package.list[name]
	if not pack then return nil, "No such package" end
	local co = coroutine.create(function() return pack[funcName](pack, getfenv()) end)
	local event, filter, passback = {}
	while true do
		if (filter and (filter == event[1] or event[1] == "terminate")) or not filter then
			passback = {coroutine.resume(co, unpack(event))}
		end
		if passback[1] == false then printWarning(passback[2]) end
		if coroutine.status(co) == "dead" then return unpack(passback, 2) end
		filter = nil
		if passback and passback[1] and passback[2] then
			filter = passback[2]
		end
		event = {os.pullEventRaw()}
		if event[1] == "package_status" then
			if event[2] == "info" then
				printInformation(event[3])
			elseif event[2] == "warning" then
				printWarning(event[3])
			elseif event[2] == "error" then
				printError(event[3])
			end
		end
	end
end

local function install(name)
	return raw_package_operation(name, "install")
end

local function remove(name)
	return raw_package_operation(name, "remove")
end

local function upgrade(name)
	return raw_package_operation(name, "upgrade")
end

if mode == "install" then
	if #operation.arguments >= 1 then
		local installList = {}
		for packageNumber, packageName in ipairs(operation.arguments) do
			local result = lookupPackage(packageName)
			if not result then
				printWarning("Could not install package "..packageName..".")
			else
				for k,v in pairs(package.list[result].dependencies) do
					if not package.installed[k] then
						installList[k] = true
					else
						if k == result then
							printInformation("Package "..k.." already installed")
						else
							printInformation("Dependency "..k.." already installed")
						end
					end
				end
			end
		end
		local installString = ""
		for k, v in pairs(installList) do
			installString = installString..k.." "
		end
		if #installString > 0 then
			if not forced then
				io.write("The following packages will be installed: "..installString.."\n")
				io.write("Continue? (Y/n)\n")
				local input = io.read()
				if string.sub(input:lower(), 1, 1) == "n" then
					return true
				end
			end
			for packageName in pairs(installList) do
				if not install(packageName) then
					printWarning("Could not "..mode.." package "..packageName)
				end
			end
		end
	end
elseif mode == "update" then
	local updateList = {}
	local installList = {}
	if #operation.arguments >= 1 then
		for _, name in ipairs(operation.arguments) do
			local result = lookupPackage(name, true)
			if result then
				table.insert(updateList, result)
			end
		end
	else
		for k, v in pairs(package.installed) do
			if v.files then
				--filters out the disambiguation entries.
				table.insert(updateList, k)
				for name, info in pairs(package.list[k].dependencies) do
					if not package.installed[name] then
						installList[name] = true
					end
				end
			end
		end
	end
	local installString = ""
	for k, v in pairs(installList) do
		installString = installString..k.." "
	end
	if not forced then
		for i = #updateList, 1, -1 do
			if package.installed[updateList[i]].version == package.list[updateList[i]].version then
				table.remove(updateList, i)
			end
		end
	end
	if #updateList > 0 or #installString > 0 then
		local updateString = ""
		for i = 1, #updateList do
			updateString = updateString..updateList[i].." "
		end
		if not forced then
			io.write("The following packages will be updated: "..updateString.."\n")
			if #installString > 0 then
				io.write("The following packages will also be installed: "..installString.."\n")
			end
			io.write("Continue? (Y/n)\n")
			local input = io.read()
			if string.sub(input:lower(), 1, 1) == "n" then
				return true
			end
		end
		local failureCount = 0
		for packageName in pairs(installList) do
			if not install(packageName) then
				printWarning("Could not install package "..packageName)
			end
		end
		for _, packageName in pairs(updateList) do
			if not upgrade(packageName) then
				printWarning("Package "..packageName.." failed to update.")
				failureCount = failureCount + 1
			end
		end
		if failureCount > 0 then
			printWarning(failureCount.." packages failed to update.")
		else
			printInformation("Update complete!")
		end
	else
		io.write("Nothing to do!\n")
		return true
	end
elseif mode == "remove" then
	if #operation.arguments >= 1 then
		local packageList = {}
		for _, name in ipairs(operation.arguments) do
			local result = lookupPackage(name, true)
			if result then
				table.insert(packageList, result)
			end
		end
		dependeesList = {}
		--find packages which depend on the packages we are removing.
		for pName, pData in pairs(package.installed) do
			if pData.version then
				if not packageList[pName] then
					for dName in pairs(package.list[pName].dependencies) do
						for _, packName in pairs(packageList) do
							if packName == dName then
								dependeesList[pName] = true
								break
							end
						end
						if dependeesList[pName] then
							break
						end
					end
				end
			end
		end
		local removeString = ""
		local dependeesString = ""
		for i = 1, #packageList do
			removeString = removeString..packageList[i].." "
			if dependeesList[packageList[i]] then
				dependeesList[packageList[i]] = nil
			end
		end
		for dName in pairs(dependeesList) do
			dependeesString = dependeesString..dName.." "
		end
		if #removeString > 0 then
			if not forced then
				io.write("The following packages will be removed: "..removeString.."\n")
				if #dependeesString > 0 then
					io.write("The following packages will also be removed due to missing dependencies: "..dependeesString.."\n")
				end
				io.write("Continue? (y/N)\n")
				local input = io.read()
				if string.sub(input:lower(), 1, 1) ~= "y" then
					return true
				end
			end
			for pName in pairs(dependeesList) do
				printInformation("Removing "..pName)
				remove(pName)
			end
			for _, pName in pairs(packageList) do
				printInformation("Removing "..pName)
				remove(pName)
			end
		else
			io.write("Nothing to do!\n")
		end
	end
elseif mode == "list" then
	--list all installed packages
	local match = ".*"
	if #operation.arguments == 1 then
		--list with matching.
		match = operation.arguments[1]
	end
	for name, info in pairs(package.installed) do
		if info.version then
			if string.match(name, match) then
				io.write(name.." "..info.version.."\n")
			end
		end
	end
elseif mode == "search" then
	--search all available packages
	local match = ".*"
	if #operation.arguments == 1 then
		--search using a match
		match = operation.arguments[1]
	end
	for name, info in pairs(package.list) do
		if info.version then
			if string.match(name, match) then
				io.write((package.installed[name] and "I " or "A " )..name.." "..info.version.."\n")
			end
		end
	end
end

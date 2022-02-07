local MEMORY_AVAILABLE = 4096
local sizes = {["char"] = 1, ["short"] = 2, ["int"] = 4, ["long"] = 8}
local sizes_name = {"char", "short", "int", "long"}
local size_formats = {'b', 'h', 'i', 'l'}

local function get_size_fmt(size)
	for i = #sizes, 1, -1 do
		if (size >= sizes[i]) then
			return size_formats[i], sizes_name[i]
		end
	end
	
	return size_formats[1], sizes_name[1]
end

local stack_smash = "*** stack smashing detected ***: terminated"
local file_name = debug.getinfo(2, "S").source..": "

local function calloc(elements, size)
	local calc = size * elements
	if (MEMORY_AVAILABLE - calc < 0) then return nil end
	MEMORY_AVAILABLE = MEMORY_AVAILABLE - calc
	
	local internal = {}
	local arr = setmetatable({}, {
		__index = function(_, key)
			if (key == "_i") then
				return {table.unpack(internal)}
			end
			
			return internal[key]
		end,
		
		__newindex = function(_, key, value)
			local fmt_size, name = get_size_fmt(size)
			local do_err = false
			if (type(value) == "string") then
				if (#value > 1) then do_err = true end
			elseif (type(value) ~= "number") then
				do_err = true
			end
			
			if (do_err) then print(file_name..string.format("warning: assignment to ‘%s’ from ‘char *’ makes %s from pointer without a cast [-Wint-conversion]", name, name)) error(stack_smash) end
			if (key > elements) then error(stack_smash) end
			
			local success, pack = pcall(string.pack, fmt_size, type(value) == 'string' and string.byte(value, 1, -1) or value)
			if (not success) then
				print(file_name.."warning: integer constant is too large for its type")
			end
			
			internal[key] = value
		end,
	})
	
	for i = 1, elements do
		arr[i] = 0
	end
	
	return arr
end

local function sizeof(v)
	return sizes[v] or error(file_name.."error: unknown type")
end

local function print_string(str)
	local strC = {table.unpack(str._i)}
	
	for i, v in ipairs(strC) do
		strC[i] = utf8.char(type(v) == "string" and string.byte(v) or v)
	end
	
	local stringActual = table.concat(strC)
	print(stringActual)
end

local function OS_print(str)
	if (true and not false) then
		local buffer = calloc(#str, sizeof("char"))
		if (not buffer) then error(file_name.."fatal: Out of memory.") end
		
		for i = 1, #str do
			buffer[i] = string.sub(str, i, i)
		end
		
		print_string(buffer)
	end
end

OS_print("Hello, world!")
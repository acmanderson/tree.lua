require "lfs"

local SEPARATOR = '/'
local path = arg[1] or '.'

function string:split(sep)
    local sep, fields = sep or ":", {}
    local pattern = string.format("([^%s]+)", sep)
    self:gsub(pattern, function(c) fields[#fields+1] = c end)
    return fields
end

function string:mult(times)
	local string_mult = ''
	for i = 1, times do
		string_mult = string_mult..self
	end
	return string_mult
end

local function get_dirs_and_files(dir) 
    if string.sub(dir, -1) == "/" then
        dir=string.sub(dir, 1, -2)
    end

    local function yieldtree(dir)
        for entry in lfs.dir(dir) do
            if entry ~= "." and entry ~= ".." then
                entry=dir.."/"..entry
                local attr=lfs.attributes(entry)
                coroutine.yield(entry,attr)
                if attr.mode == "directory" then
                    yieldtree(entry)
                end
            end
        end
    end

    return coroutine.wrap(function() yieldtree(dir) end)
end

local function get_dir_tree()
    local master = {[path]={}}
    local current = master[path]
    for filename, attr in get_dirs_and_files(path) do
        for i, part in pairs((filename:gsub(path, '')):split(SEPARATOR)) do
            if not current[part] then
                current[part] = {}
            end
            current = current[part]
        end
        current = master[path]
    end
    return master
end

local function dump(t, indent)
    local t = t or get_dir_tree()
    local indent = indent or 0
    local names = {}

    for n,g in pairs(t) do
        table.insert(names,n)
    end
    table.sort(names)
    for i,n in pairs(names) do
        local v = t[n]
        local line_prefix = ''
        if indent > 0 then
        	local last_item_prefix = string.mult("┃   ", indent - 1).."┣"
        	if i == #names then last_item_prefix = string.mult("┃   ", indent - 1).."┗" end
        	line_prefix = last_item_prefix.."━"
        end
        print(line_prefix..tostring(n))
        dump(v, indent + 1)
    end
end

dump()
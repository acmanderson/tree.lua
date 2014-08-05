#!/usr/bin/env lua

require "lfs"

local SEPARATOR = '/'
local DEFAULT_INDENT = '   '
local VERTICAL_BAR = '┃'
local MIDDLE_CONNECTOR = "┣"
local ENDING_CONNECTOR = "┗"
local HORIZONTAL_CONNECTOR = "━━ "

local TREE_ARGS = {a=false}

local num_dirs = 0
local num_files = 0

local function get_arg_from_string(arg_string)
	return (arg_string:gsub('^%-*', ''))
end

local path
for i = 1, #arg do
	if not arg[i]:match('^%-') then
		path = arg[i]
	else
		local cli_arg = get_arg_from_string(arg[i])
		if TREE_ARGS[cli_arg] ~= nil then
			TREE_ARGS[cli_arg] = true
		end
	end
end
path = path or '.'

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
            	if not entry:match('^%.') or TREE_ARGS['a'] then
	                entry=dir.."/"..entry
	                local attr=lfs.attributes(entry)
	                coroutine.yield(entry,attr)
	                if attr.mode == "directory" then
	                	num_dirs = num_dirs + 1
	                    yieldtree(entry)
	                else
	                	num_files = num_files + 1
	                end
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
        for i, part in pairs((filename:gsub(path, '', 1)):split(SEPARATOR)) do
            if not current[part] then
                current[part] = {}
            end
            current = current[part]
        end
        current = master[path]
    end
    return master
end

local function get_line_tree_markers(markers_to_ignore, indent_level)
	local line_tree_markers = ''
	for i=1,indent_level do
		if not markers_to_ignore[i] then
			line_tree_markers = line_tree_markers..VERTICAL_BAR..DEFAULT_INDENT
		else
			line_tree_markers = line_tree_markers..' '..DEFAULT_INDENT
		end
	end
	return line_tree_markers
end

local function print_tree(t, indent_level, markers_to_ignore)
    local t = t or get_dir_tree()
    local indent_level = indent_level or 0
    local markers_to_ignore = markers_to_ignore or {}
    local names = {}

    for n,g in pairs(t) do
        table.insert(names,n)
    end

    table.sort(names)
    for i,n in pairs(names) do
        local v = t[n]
        local line_prefix = ''
        if indent_level > 0 then
        	local last_item_prefix = get_line_tree_markers(markers_to_ignore, indent_level - 1)..MIDDLE_CONNECTOR
        	if i == #names then 
        		last_item_prefix = get_line_tree_markers(markers_to_ignore, indent_level - 1)..ENDING_CONNECTOR
        		markers_to_ignore[indent_level] = true
        	end
        	line_prefix = last_item_prefix..HORIZONTAL_CONNECTOR
        end
        print(line_prefix..tostring(n))
        print_tree(v, indent_level + 1, markers_to_ignore)
        
    end
    markers_to_ignore[indent_level] = nil
end

print_tree()
print(string.format("\n%s directories, %s files", num_dirs, num_files))
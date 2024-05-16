local json = require("json/json")
local M = {}

local global_buf, global_win

local function open_window()
	global_buf = vim.api.nvim_create_buf(false, true)

	vim.api.nvim_buf_set_option(global_buf, "readonly", true)
	vim.api.nvim_buf_set_option(global_buf, "bufhidden", "")
	vim.api.nvim_buf_set_option(global_buf, "buftype", "nofile")

	-- Define key mapping to close the buffer with 'q'
	vim.api.nvim_buf_set_keymap(global_buf, "n", "q", "<Cmd>q<CR>", { noremap = true, silent = true })

	-- get dimensions
	local width = vim.api.nvim_get_option("columns")
	local height = vim.api.nvim_get_option("lines")

	-- calculate our floating window size
	local win_height = math.ceil(height * 0.8 - 4)
	local win_width = math.ceil(width * 0.8)

	-- and its starting position
	local row = math.ceil((height - win_height) / 2 - 1)
	local col = math.ceil((width - win_width) / 2)

	-- set some options
	local opts = {
		style = "minimal",
		relative = "editor",
		width = win_width,
		height = win_height,
		row = row,
		col = col,
	}

	global_win = vim.api.nvim_open_win(global_buf, true, opts)
	return global_win
end

local function is_array(table)
	if type(table) ~= "table" then
		return false
	end

	-- objects always return empty size
	if #table > 0 then
		return true
	end

	-- only object can have empty length with elements inside
	for _, _ in pairs(table) do
		return false
	end

	-- if no elements it can be array and not at same time
	return true
end

local function infer_json_schema(key, obj)
	local schema = {}

	if type(obj) == "table" then
		schema = {}
		schema["props"] = {}
		if is_array(obj) then
			schema["type"] = "array"
			if #obj > 0 then
				schema["props"] = infer_json_schema("props", obj[1])["props"]
			end
			return schema
		end

		schema["type"] = "object"
		for k, v in pairs(obj) do
			if type(v) == "table" then
				schema["props"][k] = infer_json_schema(k, v)
			else
				schema["props"][k] = type(v)
			end
		end
	else
		schema[key] = type(obj)
	end

	return schema
end

local function prettify_json(obj, indent_level)
	indent_level = indent_level or 0
	local indent_str = string.rep("  ", indent_level)
	local result = ""

	if type(obj) == "table" then
		local is_empty_table = next(obj) == nil

		if not is_empty_table then
			result = result .. "{\n"
			for key, value in pairs(obj) do
				result = result
					.. indent_str
					.. '  "'
					.. key
					.. '": '
					.. prettify_json(value, indent_level + 1)
					.. ",\n"
			end
			result = result .. indent_str .. "}"
		else
			result = "{}"
		end
	elseif type(obj) == "string" then
		result = result .. '"' .. obj .. '"'
	else
		result = result .. tostring(obj)
	end

	return result
end

local function update_view(content)
	vim.api.nvim_buf_set_option(global_buf, "modifiable", true)
	vim.api.nvim_buf_set_lines(global_buf, 0, -1, true, vim.split(content, "\n"))
	vim.api.nvim_buf_set_option(global_buf, "modifiable", false)
end

function M.setup(opts)
	-- TODO: Set opts

	vim.cmd("command! JSONViz lua require('jsonviz').jsonviz()")
	vim.keymap.set("n", "<leader>js", ":JSONViz<CR>", { desc = "Open JSONViz" })
end

function M.jsonviz()
	if vim.bo.filetype ~= "json" then
		return
	end

	-- Get the JSON content of the current buffer
	local json_content = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, true), "\n")
	local parsed_json = json.decode(json_content)

	-- Build the output
	local jsonrepr = prettify_json(infer_json_schema("/", parsed_json), 2)

	open_window()
	update_view(jsonrepr)
end

-- Return the module table
return M

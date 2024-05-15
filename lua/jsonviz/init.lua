local json = require("json/json")
local M = {}

local global_buf, global_win

local function create_or_open_file(path)
	local file_exists = vim.fn.filereadable(path) == 1

	-- If the file doesn't exist, create it
	if not file_exists then
		local file_handle, err = io.open(path, "w")
		if file_handle == nil then
			print("JsonViz: Error creating file:", err)
			return nil
		end
		file_handle:close()
	end

	local bufnr = vim.fn.bufadd(path)
	return bufnr
end

local function open_window(path, content)
	global_buf = create_or_open_file(path)
	if global_buf == nil then
		print("JsonViz: Error creating file")
		return
	end

	-- vim.api.nvim_buf_set_option(global_buf, "bufhidden", "wipe")
	vim.api.nvim_buf_set_option(global_buf, "bufhidden", "hide")
	vim.api.nvim_buf_set_option(global_buf, "readonly", true)

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

-- Function to build a text-based representation of the JSON structure
local function build_json_structure(json_obj, indent_level)
	local result = ""

	if type(json_obj) == "table" then
		-- If the JSON object is a table
		if #json_obj > 0 then
			-- Check if all children are leaves
			local all_leaves = true
			for _, value in ipairs(json_obj) do
				if type(value) == "table" then
					all_leaves = false
					break
				end
			end

			-- If all children are leaves, print "Array" and return
			if all_leaves then
				return string.rep("  ", indent_level) .. "Array\n"
			end
		end

		-- If it's an object, iterate over its keys
		for key, value in pairs(json_obj) do
			-- Indentation based on the current level
			local indent = string.rep("  ", indent_level)

			-- Add key to the result with proper indentation
			result = result .. indent .. key .. "\n"

			-- Recursively build the structure for the value (if it's a table)
			if type(value) == "table" then
				result = result .. build_json_structure(value, indent_level + 1)
			end
		end
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

	-- Define a command to trigger the JSON visualizer
	-- vim.cmd([[command! JSONViz :lua require('plugins.jsonviz').jsonviz()]])
	vim.cmd("command! JSONViz lua require('jsonviz').jsonviz()")
	vim.keymap.set("n", "<leader>js", ":JSONViz<CR>", { desc = "Open JSONViz" })
end

function M.jsonviz()
	if vim.bo.filetype ~= "json" then
		return
	end

	-- Get the current filename
	local filename = vim.api.nvim_buf_get_name(0)
	local jsonbufname = "/tmp/JSONViz-" .. vim.fn.sha256(filename)

	-- Get the JSON content of the current buffer
	local json_content = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, true), "\n")
	local parsed_json = json.decode(json_content)
	local jsonrepr = build_json_structure(parsed_json, 0)

	open_window(jsonbufname)
	update_view(jsonrepr)
end

-- Return the module table
return M

local json = require("../libs/json")

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

local function create_or_open_file(path)
  -- Check if the file exists
  local file_exists = vim.fn.filereadable(path) == 1

  -- If the file doesn't exist, create it
  if not file_exists then
    local file_handle, err = io.open(path, "w")
    if file_handle == nil then
      print("Error creating file:", err)
      return nil
    end
    file_handle:close()
  end

  local bufnr = vim.fn.bufadd(path)
  return bufnr
end

local function jsonviz()
  if vim.bo.filetype ~= "json" then
    return
  end

  -- Get the current filename
  local filename = vim.api.nvim_buf_get_name(0)
  local jsonbufname = "/tmp/JSONViz-" .. vim.fn.sha256(filename)

  -- Get the JSON content of the current buffer
  local json_content = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, true), "\n")
  local parsed_json = json.decode(json_content)

  -- Create/Open the file and get the buffer
  local buf = create_or_open_file(jsonbufname)

  if buf == nil then
    print("Error creating file")
    return
  end

  vim.api.nvim_buf_set_name(buf, jsonbufname)

  local jsonrepr = build_json_structure(parsed_json, 0)
  vim.api.nvim_buf_set_lines(buf, 0, -1, true, vim.split(jsonrepr, "\n"))
  -- vim.api.nvim_buf_set_lines(buf, 0, -1, true, { "asdfasdfasdf" })
  vim.api.nvim_buf_set_option(buf, "readonly", true)

  -- Open the buffer in a vertical split
  vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = 80,
    height = 50,
    col = 100,
    row = 0,
    style = "minimal",
  })
end

-- Define a command to trigger the JSON visualizer
vim.cmd([[command! JSONViz :lua require('plugins.jsonviz').jsonviz()]])

-- Return the module table
return {
  jsonviz = jsonviz,
}

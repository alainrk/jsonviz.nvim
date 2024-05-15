if 1 ~= vim.fn.has("nvim-0.9.0") then
	vim.api.nvim_err_writeln("JsonViz.nvim requires at least nvim-0.9.0.")
	return
end

if vim.g.loaded_jsonviz == 1 then
	return
end
vim.g.loaded_jsonviz = 1

-- vim.api.nvim_create_user_command("JsonViz", function(opts)
-- 	require("jsonviz").jsonviz(opts)
-- end)

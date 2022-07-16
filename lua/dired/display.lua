-- display the directory and its contents
local fs = require("dired.fs")
local ls = require("dired.ls")
local config = require("dired.config")
local nui_line = require("nui.line")
local nui_text = require("nui.text")
local utils = require("dired.utils")
local M = {}

-- fill the buffer with directory contents
-- buffer to be flushed in neovim buffer
M.buffer = {}
M.cursor_pos = {}

function M.clear()
    M.buffer = {}
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {})
end

function M.render(path)
    M.clear()
    M.display_dired_listing(path)
    M.flush_buffer()
end

function M.flush_buffer()
    local undolevels = vim.bo.undolevels
    vim.bo.undolevels = -1
    for i, line in ipairs(M.buffer) do
        line:render(0, -1, i)
    end
    vim.bo.undolevels = undolevels
    vim.bo.modified = false
    vim.api.nvim_win_set_cursor(0, M.cursor_pos)
    M.buffer = {}
end

function M.get_directory_listing(directory)
    local buffer_listing = {}
    local dir_files, error = ls.fs_entry.get_directory(directory, vim.g.dired_show_dot_dirs, vim.g.dired_show_hidden)
    local dir_size = dir_files.size
    local dir_size_str = utils.get_short_size(dir_size)
    local info1 = { nui_text(string.format("%s:", fs.get_simplified_path(directory))) }
    local info2 = { nui_text(string.format("total used in directory %s:", dir_size_str)) }
    local formatted_components, cursor_x = ls.fs_entry.format(dir_files)
    table.insert(buffer_listing, { component = nil, line = info1 })
    table.insert(buffer_listing, { component = nil, line = info2 })

    if #formatted_components > #buffer_listing then
        M.cursor_pos = { 5, cursor_x } -- first file after the dot dirs
    else
        M.cursor_pos = { 4, cursor_x } -- on the ".." directory
    end

    local listing = {}
    for _, comp in ipairs(formatted_components) do
        table.insert(listing, ls.get_colored_component_str(comp))
    end

    table.sort(listing, config.get_sort_order(vim.g.dired_sort_order))
    local buffer_listing = utils.concatenate_tables(buffer_listing, listing)
    return buffer_listing
end

function M.display_dired_listing(directory)
    local buffer_listings = {}
    local listing = M.get_directory_listing(directory)
    for _, tbl in ipairs(listing) do
        table.insert(buffer_listings, nui_line(tbl.line))
    end
    M.buffer = utils.concatenate_tables(M.buffer, buffer_listings)
end

function M.get_filename_from_listing(line)
    local splitted = utils.str_split(line, " ")
    return splitted[#splitted - 1]
end

return M

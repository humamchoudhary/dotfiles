-- lua/lang/sql.lua
-- Pick which database vim-dadbod-completion completes against.
--
-- Opening a .sql file directly (from telescope, say, rather than through
-- :DBUI) leaves b:db unset, so the completion source has nothing to resolve
-- and silently offers nothing. :DbSelect shows the connections you already
-- saved in :DBUI and sets one for the session.
--
-- No credentials live here. They stay in dadbod-ui's own connections file,
-- outside this repo; this only reads it to list names and set a URL.
--
-- vim-dadbod-completion resolves in this order
-- (autoload/vim_dadbod_completion.vim:378):
--   b:dbui_db_key_name -> $DATABASE_URL -> w:db / t:db / b:db / g:db
-- so a buffer opened via DBUI keeps using its own connection regardless.

local M = {}

-- dadbod-ui defaults to a literal ~/.local/share/db_ui (plugin/db_ui.vim:12),
-- NOT stdpath("data"), and honours g:db_ui_save_location when set.
local function connections_file()
	local dir = vim.g.db_ui_save_location or "~/.local/share/db_ui"
	return vim.fn.expand(dir) .. "/connections.json"
end

local function mask(url)
	if not url or url == "" then
		return "nil"
	end
	return (url:gsub("://([^:@/]+):[^@]*@", "://%1:***@"))
end

-- Saved connections, as an ordered { name, url } list.
function M.connections()
	local list = {}
	local ok, data = pcall(vim.fn.readfile, connections_file())
	if not ok or vim.tbl_isempty(data) then
		return list
	end
	local decoded_ok, decoded = pcall(vim.json.decode, table.concat(data, "\n"))
	if not decoded_ok or type(decoded) ~= "table" then
		return list
	end
	for _, conn in ipairs(decoded) do
		if conn.name and conn.url then
			list[#list + 1] = { name = conn.name, url = conn.url }
		end
	end
	return list
end

-- Menu over the saved connections; the chosen one becomes the session default.
function M.select()
	local list = M.connections()
	if vim.tbl_isempty(list) then
		vim.notify(
			"No saved connections in " .. connections_file() .. "\nAdd one with :DBUI first.",
			vim.log.levels.WARN
		)
		return
	end

	vim.ui.select(list, {
		prompt = "Database for SQL completion:",
		format_item = function(item)
			return string.format("%-28s %s", item.name, mask(item.url))
		end,
	}, function(choice)
		if not choice then
			return
		end
		vim.g.db = choice.url
		vim.notify("SQL completion -> " .. choice.name, vim.log.levels.INFO)
	end)
end

function M.info()
	local dbui = vim.b.dbui_db_key_name
	local active, from
	if dbui and dbui ~= "" then
		active, from = dbui, "b:dbui_db_key_name (opened via DBUI)"
	elseif vim.env.DATABASE_URL and vim.env.DATABASE_URL ~= "" then
		active, from = mask(vim.env.DATABASE_URL), "$DATABASE_URL"
	elseif vim.b.db then
		active, from = mask(vim.b.db), "b:db"
	elseif vim.g.db then
		active, from = mask(vim.g.db), "g:db (:DbSelect)"
	else
		active, from = "nil", "nothing set -- run :DbSelect"
	end
	vim.notify("SQL completion db: " .. active .. "\nsource: " .. from, vim.log.levels.INFO)
end


-- ── Cycling the kind of suggestion dadbod offers ─────────────────────────────
--
-- vim-dadbod-completion returns one flat list; it has no filter of its own.
-- Every item does carry a kind though -- its cmp source maps dadbod's internal
-- kinds to LSP ones (lua/vim_dadbod_completion.lua:37) -- so cmp's entry_filter
-- can narrow the list, and this cycles which kind is let through.

local kinds = vim.lsp.protocol.CompletionItemKind

-- Order of the cycle. `kind = nil` means "everything".
M.filters = {
	{ label = "all", kind = nil },
	{ label = "tables", kind = kinds.Class },
	{ label = "columns", kind = kinds.Field },
	{ label = "schemas", kind = kinds.Folder },
	{ label = "aliases", kind = kinds.Variable },
	{ label = "functions", kind = kinds.Function },
	{ label = "reserved words", kind = kinds.Keyword },
}

M.filter_index = 1

-- Passed to the vim-dadbod-completion source in lua/plugins/cmp.lua.
function M.entry_filter(entry)
	local want = M.filters[M.filter_index].kind
	if not want then
		return true
	end
	return entry:get_kind() == want
end

function M.cycle_filter(step)
	M.filter_index = ((M.filter_index - 1 + (step or 1)) % #M.filters) + 1
	local label = M.filters[M.filter_index].label
	vim.notify("dadbod suggestions: " .. label, vim.log.levels.INFO)

	-- Re-run completion so the menu reflects the new filter immediately.
	local ok, cmp = pcall(require, "cmp")
	if ok and cmp.visible() then
		cmp.complete()
	end
end

function M.set_filter(label)
	for i, f in ipairs(M.filters) do
		if f.label == label then
			M.filter_index = i
			vim.notify("dadbod suggestions: " .. label, vim.log.levels.INFO)
			return
		end
	end
	vim.notify("Unknown filter: " .. tostring(label), vim.log.levels.WARN)
end

function M.setup()
	-- Buffer-local on purpose: <C-l> must only mean "cycle suggestion kind"
	-- while you're completing in a SQL buffer, so it can't live in the global
	-- table in lua/config/keymaps.lua like everything else.
	vim.api.nvim_create_autocmd("FileType", {
		group = vim.api.nvim_create_augroup("UserSqlKindCycle", { clear = true }),
		pattern = { "sql", "mysql", "plsql" },
		callback = function(ev)
			vim.keymap.set("i", "<C-l>", function()
				M.cycle_filter(1)
			end, { buffer = ev.buf, desc = "dadbod: next suggestion kind" })
		end,
	})

	vim.api.nvim_create_user_command("DbSelect", M.select, {
		desc = "Pick the database vim-dadbod-completion uses",
	})
	vim.api.nvim_create_user_command("DbInfo", M.info, {
		desc = "Show which database SQL completion is using",
	})

	vim.api.nvim_create_user_command("DbKindNext", function()
		M.cycle_filter(1)
	end, { desc = "Next dadbod suggestion kind" })

	vim.api.nvim_create_user_command("DbKindPrev", function()
		M.cycle_filter(-1)
	end, { desc = "Previous dadbod suggestion kind" })

	vim.api.nvim_create_user_command("DbKind", function(cmd)
		M.set_filter(cmd.args)
	end, {
		nargs = 1,
		desc = "Set dadbod suggestion kind",
		complete = function()
			return vim.tbl_map(function(f)
				return f.label
			end, M.filters)
		end,
	})
end

return M

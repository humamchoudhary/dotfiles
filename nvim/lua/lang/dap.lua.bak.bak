-- lua/dap.lua
-- Debug adapter setup for Python, Go, Rust, C/C++ and JS/TS.
--
-- Mason puts its bin directory on vim.env.PATH, so the adapters below can be
-- referenced by bare command name once mason-tool-installer has fetched them.

local M = {}

local function mason_bin(name)
	return vim.fn.stdpath("data") .. "/mason/bin/" .. name
end

local function mason_pkg(name)
	return vim.fn.stdpath("data") .. "/mason/packages/" .. name
end

-- Prompt once per session for the binary to debug, remembering the answer so
-- repeated F5 runs don't re-ask.
local last_program = {}
local function pick_program()
	local cwd = vim.fn.getcwd()
	local co, is_main = coroutine.running()
	local default = last_program[cwd] or (cwd .. "/")
	local path = vim.fn.input("Path to executable: ", default, "file")
	if path == "" then
		return nil
	end
	last_program[cwd] = path
	if co and not is_main then
		return path
	end
	return path
end

function M.setup()
	local dap = require("dap")
	local dapui = require("dapui")

	dapui.setup({
		icons = { expanded = "▾", collapsed = "▸", current_frame = "▸" },
		layouts = {
			{
				elements = {
					{ id = "scopes", size = 0.35 },
					{ id = "breakpoints", size = 0.20 },
					{ id = "stacks", size = 0.25 },
					{ id = "watches", size = 0.20 },
				},
				size = 45,
				position = "left",
			},
			{
				elements = {
					{ id = "repl", size = 0.5 },
					{ id = "console", size = 0.5 },
				},
				size = 12,
				position = "bottom",
			},
		},
		floating = { border = "rounded" },
	})

	require("nvim-dap-virtual-text").setup({
		virt_text_pos = "eol",
		commented = true,
	})

	-- Open the UI when a session starts, close it when it ends.
	dap.listeners.after.event_initialized["dapui_config"] = function()
		dapui.open()
	end
	dap.listeners.before.event_terminated["dapui_config"] = function()
		dapui.close()
	end
	dap.listeners.before.event_exited["dapui_config"] = function()
		dapui.close()
	end

	vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticError", numhl = "" })
	vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "DiagnosticWarn", numhl = "" })
	vim.fn.sign_define("DapLogPoint", { text = "◈", texthl = "DiagnosticInfo", numhl = "" })
	vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DiagnosticOk", linehl = "Visual", numhl = "" })
	vim.fn.sign_define("DapBreakpointRejected", { text = "○", texthl = "DiagnosticHint", numhl = "" })

	-- ── Python ───────────────────────────────────────────────────────────────
	-- venv-selector sets VIRTUAL_ENV; dap-python honours it for the *debuggee*
	-- while debugpy itself runs from Mason's own interpreter.
	local debugpy_python = mason_pkg("debugpy") .. "/venv/bin/python"
	if vim.fn.executable(debugpy_python) == 1 then
		require("dap-python").setup(debugpy_python)
	else
		require("dap-python").setup("python3")
	end

	-- ── Go ───────────────────────────────────────────────────────────────────
	require("dap-go").setup({
		delve = { detached = vim.fn.has("win32") == 0 },
	})

	-- ── Rust / C / C++ (codelldb) ────────────────────────────────────────────
	dap.adapters.codelldb = {
		type = "server",
		port = "${port}",
		executable = {
			command = mason_bin("codelldb"),
			args = { "--port", "${port}" },
		},
	}

	local native_config = {
		{
			name = "Launch executable",
			type = "codelldb",
			request = "launch",
			program = pick_program,
			cwd = "${workspaceFolder}",
			stopOnEntry = false,
			args = {},
		},
		{
			name = "Attach to process",
			type = "codelldb",
			request = "attach",
			pid = require("dap.utils").pick_process,
			cwd = "${workspaceFolder}",
		},
	}

	dap.configurations.c = native_config
	dap.configurations.cpp = native_config
	-- rustaceanvim supplies richer Rust configurations (cargo-aware, with
	-- pretty-printers) when it's loaded; this is the manual fallback.
	dap.configurations.rust = native_config

	-- ── JavaScript / TypeScript (vscode-js-debug) ────────────────────────────
	for _, adapter in ipairs({ "pwa-node", "pwa-chrome" }) do
		dap.adapters[adapter] = {
			type = "server",
			host = "localhost",
			port = "${port}",
			executable = {
				command = mason_bin("js-debug-adapter"),
				args = { "${port}" },
			},
		}
	end

	local js_config = {
		{
			type = "pwa-node",
			request = "launch",
			name = "Launch current file",
			program = "${file}",
			cwd = "${workspaceFolder}",
			sourceMaps = true,
			protocol = "inspector",
			skipFiles = { "<node_internals>/**", "node_modules/**" },
		},
		{
			type = "pwa-node",
			request = "attach",
			name = "Attach to process",
			processId = require("dap.utils").pick_process,
			cwd = "${workspaceFolder}",
			sourceMaps = true,
			skipFiles = { "<node_internals>/**", "node_modules/**" },
		},
		{
			type = "pwa-chrome",
			request = "launch",
			name = "Launch Chrome against localhost:3000",
			url = "http://localhost:3000",
			webRoot = "${workspaceFolder}",
			sourceMaps = true,
		},
	}

	-- TypeScript sources need a runtime that can execute them directly.
	local ts_config = vim.deepcopy(js_config)
	ts_config[1].runtimeArgs = { "--import", "tsx" }
	ts_config[1].runtimeExecutable = "node"

	dap.configurations.javascript = js_config
	dap.configurations.javascriptreact = js_config
	dap.configurations.typescript = ts_config
	dap.configurations.typescriptreact = ts_config
end

return M

-- lua/lsp.lua
-- Language server configuration.
--
-- Neovim 0.12 + nvim-lspconfig's `lsp/` directory means every server already
-- ships a working default config. We only layer per-server settings on top with
-- vim.lsp.config() -- mason-lspconfig's automatic_enable does the vim.lsp.enable()
-- call for anything installed through Mason.

local M = {}

-- Servers Mason should keep installed. Names are lspconfig names.
M.servers = {
	"lua_ls", -- Lua
	"pyright", -- Python (types)
	"ruff", -- Python (lint + import sorting)
	"gopls", -- Go
	"ts_ls", -- JavaScript / TypeScript
	"eslint", -- JS/TS linting
	"clangd", -- C / C++ / ObjC
	"rust_analyzer", -- Rust (driven by rustaceanvim, see below)
	"html",
	"cssls",
	"jsonls",
	"yamlls",
	"taplo", -- TOML
	"marksman", -- Markdown
	"bashls",
	"dockerls",
	"docker_compose_language_service",
	"tailwindcss",
	"emmet_ls",
}

-- rustaceanvim owns the rust-analyzer client end to end (it starts it itself,
-- with extra commands lspconfig doesn't wire up). Letting mason-lspconfig also
-- enable it would give us two clients on every Rust buffer.
M.ignore_automatic_enable = { "rust_analyzer" }

local function capabilities()
	local caps = vim.lsp.protocol.make_client_capabilities()
	local ok, cmp_lsp = pcall(require, "cmp_nvim_lsp")
	if ok then
		caps = vim.tbl_deep_extend("force", caps, cmp_lsp.default_capabilities())
	end
	-- nvim-ufo asks the server for fold ranges instead of guessing from indent.
	caps.textDocument.foldingRange = {
		dynamicRegistration = false,
		lineFoldingOnly = true,
	}
	return caps
end

function M.setup()
	-- Applies to every server, including ones we don't configure explicitly.
	vim.lsp.config("*", {
		capabilities = capabilities(),
	})

	-- ── Lua ──────────────────────────────────────────────────────────────────
	vim.lsp.config("lua_ls", {
		settings = {
			Lua = {
				runtime = { version = "LuaJIT" },
				workspace = {
					checkThirdParty = false,
					library = vim.api.nvim_get_runtime_file("", true),
				},
				diagnostics = { globals = { "vim" } },
				hint = { enable = true, arrayIndex = "Disable" },
				telemetry = { enable = false },
			},
		},
	})

	-- ── Python ───────────────────────────────────────────────────────────────
	-- pyright does types; ruff does lint/format/imports. Turning off pyright's
	-- organizeImports keeps the two from fighting over the same code action.
	vim.lsp.config("pyright", {
		settings = {
			pyright = { disableOrganizeImports = true },
			python = {
				analysis = {
					typeCheckingMode = "basic",
					autoSearchPaths = true,
					useLibraryCodeForTypes = true,
					diagnosticMode = "openFilesOnly",
					inlayHints = {
						variableTypes = true,
						functionReturnTypes = true,
						callArgumentNames = true,
					},
				},
			},
		},
	})

	vim.lsp.config("ruff", {
		init_options = {
			settings = { lineLength = 88 },
		},
		on_attach = function(client)
			-- pyright is the authority on hover; ruff's version is thinner.
			client.server_capabilities.hoverProvider = false
		end,
	})

	-- ── Go ───────────────────────────────────────────────────────────────────
	vim.lsp.config("gopls", {
		settings = {
			gopls = {
				gofumpt = true,
				staticcheck = true,
				usePlaceholders = true,
				completeUnimported = true,
				semanticTokens = true,
				analyses = {
					unusedparams = true,
					unusedwrite = true,
					nilness = true,
					shadow = true,
					useany = true,
				},
				hints = {
					assignVariableTypes = true,
					compositeLiteralFields = true,
					compositeLiteralTypes = true,
					constantValues = true,
					functionTypeParameters = true,
					parameterNames = true,
					rangeVariableTypes = true,
				},
			},
		},
	})

	-- ── JavaScript / TypeScript ──────────────────────────────────────────────
	local ts_inlay_hints = {
		includeInlayParameterNameHints = "literal",
		includeInlayParameterNameHintsWhenArgumentMatchesName = false,
		includeInlayFunctionParameterTypeHints = true,
		includeInlayVariableTypeHints = false,
		includeInlayPropertyDeclarationTypeHints = true,
		includeInlayFunctionLikeReturnTypeHints = true,
		includeInlayEnumMemberValueHints = true,
	}

	vim.lsp.config("ts_ls", {
		settings = {
			typescript = {
				inlayHints = ts_inlay_hints,
				preferences = { importModuleSpecifier = "non-relative" },
			},
			javascript = { inlayHints = ts_inlay_hints },
		},
	})

	-- eslint exposes an EslintFixAll command; run it on save for JS/TS buffers
	-- so lint autofixes land without needing a separate formatter pass.
	vim.lsp.config("eslint", {
		settings = { workingDirectories = { mode = "auto" } },
	})

	-- ── C / C++ ──────────────────────────────────────────────────────────────
	vim.lsp.config("clangd", {
		cmd = {
			"clangd",
			"--background-index",
			"--clang-tidy",
			"--header-insertion=iwyu",
			"--completion-style=detailed",
			"--function-arg-placeholders",
			"--fallback-style=llvm",
		},
		init_options = {
			usePlaceholders = true,
			completeUnimported = true,
			clangdFileStatus = true,
		},
	})

	-- ── JSON / YAML (schemas from SchemaStore) ───────────────────────────────
	local has_schemastore, schemastore = pcall(require, "schemastore")

	vim.lsp.config("jsonls", {
		settings = {
			json = {
				schemas = has_schemastore and schemastore.json.schemas() or nil,
				validate = { enable = true },
			},
		},
	})

	vim.lsp.config("yamlls", {
		settings = {
			yaml = {
				schemaStore = { enable = false, url = "" },
				schemas = has_schemastore and schemastore.yaml.schemas() or nil,
				validate = true,
				keyOrdering = false,
			},
		},
	})

	-- ── Emmet ────────────────────────────────────────────────────────────────
	vim.lsp.config("emmet_ls", {
		filetypes = {
			"html",
			"htmldjango",
			"jinja",
			"css",
			"scss",
			"sass",
			"less",
			"javascriptreact",
			"typescriptreact",
			"vue",
			"svelte",
		},
	})

	-- ── Tailwind ─────────────────────────────────────────────────────────────
	vim.lsp.config("tailwindcss", {
		filetypes = {
			"html",
			"htmldjango",
			"jinja",
			"css",
			"scss",
			"javascript",
			"javascriptreact",
			"typescript",
			"typescriptreact",
			"vue",
			"svelte",
		},
	})

	M.on_attach()
end

-- Buffer-local behaviour that applies to whichever server attached.
function M.on_attach()
	vim.api.nvim_create_autocmd("LspAttach", {
		group = vim.api.nvim_create_augroup("UserLspAttach", { clear = true }),
		callback = function(ev)
			local client = vim.lsp.get_client_by_id(ev.data.client_id)
			if not client then
				return
			end

			vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"

			-- Inlay hints off by default (they're noisy while writing);
			-- <leader>vh toggles them per-buffer. See keymaps.lua.
			if client:supports_method("textDocument/inlayHint") then
				vim.lsp.inlay_hint.enable(false, { bufnr = ev.buf })
			end

			-- Underline other references to the symbol under the cursor.
			if client:supports_method("textDocument/documentHighlight") then
				local group = vim.api.nvim_create_augroup("UserLspHighlight" .. ev.buf, { clear = true })
				vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
					buffer = ev.buf,
					group = group,
					callback = vim.lsp.buf.document_highlight,
				})
				vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
					buffer = ev.buf,
					group = group,
					callback = vim.lsp.buf.clear_references,
				})
			end

			-- eslint's autofix is a server command, not a formatter, so conform
			-- can't run it. Wire it to BufWritePre for the buffers it owns.
			if client.name == "eslint" then
				vim.api.nvim_create_autocmd("BufWritePre", {
					buffer = ev.buf,
					command = "LspEslintFixAll",
				})
			end
		end,
	})
end

return M

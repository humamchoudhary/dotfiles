-- Theme palette — swap this table to change themes
local p = {
    bg      = "#020203",
    base    = "#0d0d0f",
    surface = "#131316",
    overlay = "#1a1a1f",
    border  = "#272730",
    subtext = "#6b6b78",
    text    = "#c8c8d4",
    bright  = "#f0f0f5",
    accent  = "#b57bee",
    muted   = "#7c4db0",
}





local M = {}

function M.apply()
    local hl = vim.api.nvim_set_hl

    -- Normal & background
    hl(0, "Normal", { fg = p.text, bg = p.bg })
    hl(0, "NormalNC", { fg = p.subtext, bg = p.bg })
    hl(0, "CursorLine", { bg = p.base })
    hl(0, "Visual", { bg = p.overlay })

    -- Line numbers
    hl(0, "LineNr", { fg = p.subtext, bg = p.bg })
    hl(0, "SignColumn", { fg = p.subtext, bg = p.bg })
    hl(0, "CursorLineNr", { fg = p.text, bg = p.base })

    -- Splits & borders
    hl(0, "VertSplit", { fg = p.border, bg = p.bg })
    hl(0, "FloatBorder", { fg = p.border, bg = p.bg })

    -- Floating windows
    hl(0, "NormalFloat", { fg = p.text, bg = p.base })

    -- Statusline
    hl(0, "StatusLine", { fg = p.text, bg = p.bg })
    hl(0, "StatusLineNC", { fg = p.subtext, bg = p.bg })

    -- Telescope
    hl(0, "TelescopeBorder", { fg = p.border, bg = p.bg })
    hl(0, "TelescopeNormal", { fg = p.text, bg = p.bg })
    hl(0, "TelescopePromptNormal", { fg = p.text, bg = p.base })
    hl(0, "TelescopePromptBorder", { fg = p.border, bg = p.base })
    hl(0, "TelescopePromptPrefix", { fg = p.accent, bg = p.base })
    hl(0, "TelescopeSelection", { fg = p.text, bg = p.overlay })
    hl(0, "TelescopeMatching", { fg = p.accent, bg = p.overlay })
    hl(0, "TelescopeResultsNormal", { fg = p.text, bg = p.bg })
    hl(0, "TelescopePreviewNormal", { fg = p.text, bg = p.bg })
    hl(0, "TelescopeResultsBorder", { fg = p.border, bg = p.bg })
    hl(0, "TelescopePreviewBorder", { fg = p.border, bg = p.bg })

    -- NvimTree
    hl(0, "NvimTreeNormal", { fg = p.text, bg = p.bg })
    hl(0, "NvimTreeNormalNC", { fg = p.subtext, bg = p.bg })
    hl(0, "NvimTreeFolderName", { fg = p.subtext })
    hl(0, "NvimTreeOpenedFolderName", { fg = p.text })
    hl(0, "NvimTreeFolderIcon", { fg = p.subtext })
    hl(0, "NvimTreeOpenedFolderIcon", { fg = p.subtext })
    hl(0, "NvimTreeFileName", { fg = p.text })
    hl(0, "NvimTreeExecFile", { fg = p.accent })
    hl(0, "NvimTreeRootFolder", { fg = p.bright, bold = true })
    hl(0, "NvimTreeIndentMarker", { fg = p.border })
    hl(0, "NvimTreeGitDirty", { fg = p.bright })
    hl(0, "NvimTreeGitNew", { fg = p.accent })
    hl(0, "NvimTreeGitDeleted", { fg = p.muted })
end

-- Lualine theme table (consumed by init.lua)
M.lualine_theme = {
    normal = {
        a = { fg = p.text, bg = p.bg },
        b = { fg = p.bright, bg = p.bg },
        c = { fg = p.subtext, bg = p.bg },
    },
    insert = { a = { fg = p.accent, bg = p.bg } },
    visual = { a = { fg = p.accent, bg = p.bg } },
    replace = { a = { fg = p.bright, bg = p.bg } },
}

return M

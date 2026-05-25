
-- Modern Professional Animations for Hyprland
-- Clean, smooth, and perform

-- ============================================================================
-- BEZIER CURVES
-- ============================================================================

-- Smooth, natural easing - recommended for most animations
hl.curve("smooth", { type = "bezier", points = { {0.25, 0.1}, {0.25, 1} } })

-- Quick, snappy easing for responsive feel
hl.curve("snappy", { type = "bezier", points = { {0.3, 0}, {0.7, 1} } })

-- Gentle, professional easing
hl.curve("gentle", { type = "bezier", points = { {0.16, 1}, {0.3, 1} } })

-- Standard easeInOut for balanced animations
hl.curve("easeInOut", { type = "bezier", points = { {0.65, 0}, {0.22, 1} } })

-- Spring physics - bouncy, natural motion
hl.curve("spring", { type = "spring", mass = 1, stiffness = 80, dampening = 20 })

-- Tight spring - quicker, less bounce
hl.curve("springTight", { type = "spring", mass = 1, stiffness = 100, dampening = 25 })

-- ============================================================================
-- GLOBAL SETTINGS
-- ============================================================================
hl.animation({ leaf = "global", enabled = true, speed = 1, bezier = "gentle" })

-- ============================================================================
-- WINDOW ANIMATIONS
-- ============================================================================
-- Window open - subtle pop with scale
hl.animation({ leaf = "windowsIn", enabled = true, speed = 3.5, bezier = "smooth", style = "popin 92%" })

-- Window close - quick fade out
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2.5, bezier = "smooth", style = "popin 92%" })

-- Window move/resize - responsive
hl.animation({ leaf = "windowsMove", enabled = true, speed = 1, bezier = "smooth" })

-- ============================================================================
-- FADE ANIMATIONS
-- ============================================================================
-- Window fade in/out
hl.animation({ leaf = "fadeIn", enabled = true, speed = 3.5, bezier = "smooth" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 2.5, bezier = "smooth" })

-- Active window transitions
hl.animation({ leaf = "fadeSwitch", enabled = true, speed = 2, bezier = "smooth" })
hl.animation({ leaf = "fadeShadow", enabled = true, speed = 2, bezier = "smooth" })
hl.animation({ leaf = "fadeDim", enabled = true, speed = 2, bezier = "smooth" })

-- Layer fades
hl.animation({ leaf = "fadeLayers", enabled = true, speed = 3, bezier = "smooth" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 3, bezier = "smooth" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 2.5, bezier = "smooth" })

-- Popup fades
hl.animation({ leaf = "fadePopups", enabled = true, speed = 2, bezier = "smooth" })
hl.animation({ leaf = "fadePopupsIn", enabled = true, speed = 2, bezier = "smooth" })
hl.animation({ leaf = "fadePopupsOut", enabled = true, speed = 1.5, bezier = "smooth" })

-- DPMS fade
hl.animation({ leaf = "fadeDpms", enabled = true, speed = 3, bezier = "gentle" })

-- ============================================================================
-- BORDER ANIMATIONS
-- ============================================================================
-- Border color transition - quick and responsive
hl.animation({ leaf = "border", enabled = true, speed = 0.7, bezier = "snappy" })

-- Border gradient angle - continuous loop
hl.animation({ leaf = "borderangle", enabled = true, speed = 3, bezier = "linear", style = "loop" })

-- ============================================================================
-- WORKSPACE ANIMATIONS
-- ============================================================================
-- Workspace switching - smooth slide with fade
hl.animation({ leaf = "workspaces", enabled = true, speed = 2, bezier = "smooth", style = "slidefade 15%" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 2, bezier = "smooth", style = "slidefade 15%" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 2, bezier = "smooth", style = "slidefade 15%" })

-- Special workspace - quicker transition
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 2, bezier = "smooth", style = "slidevert" })
hl.animation({ leaf = "specialWorkspaceIn", enabled = true, speed = 2, bezier = "smooth", style = "slidevert" })
hl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = 2, bezier = "smooth", style = "slidevert" })

-- ============================================================================
-- ZOOM ANIMATIONS
-- ============================================================================
hl.animation({ leaf = "zoomFactor", enabled = true, speed = 2, bezier = "gentle" })
hl.animation({ leaf = "monitorAdded", enabled = true, speed = 3, bezier = "gentle" })
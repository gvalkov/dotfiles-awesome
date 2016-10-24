require("awful.util")

theme = {}
theme.dir  = os.getenv("HOME") .. "/.config/awesome/themes/mine/"
theme.wallpaper = theme.dir .. "/background1.png"
theme.wallpaper_cmd = "xsetroot -solid '#2980B9'"

theme.font = "DejaVu 10"

theme.fg_normal = "#eeeeee"
theme.fg_focus  = "#ffffff"
theme.fg_urgent = "#ff0000"

theme.bg_normal = "#333333"
theme.bg_focus  = "#6F6F6F"
theme.bg_urgent = "#733339"

theme.border_width  = "2"
theme.border_normal = "#3F3F3F"
-- theme.border_focus  = "#F37B1D" -- orange
-- theme.border_focus  = "#5EB95E" -- green
theme.border_focus  = "#0E90D2" -- blue
-- theme.border_focus  = "#DD514C" -- red
theme.border_marked = "#CC9393"

-- Titlebars
theme.titlebar_bg_focus  = "#3F3F3F"
theme.titlebar_bg_normal = "#3F3F3F"

theme.tasklist_bg_focus = "#333333"

-- Widgets

-- Mouse finder
theme.mouse_finder_color = "#CC9393"

-- Tooltips
-- theme.tooltip_[font|opacity|fg_color|bg_color|border_width|border_color]
theme.tooltip_fg_normal = theme.fg_normal
theme.tooltip_bg_normal = theme.bg_normal
theme.tooltip_opacity = 10

-- Menu
theme.menu_width = 150
theme.menu_height = 24


-- Taglist icons
theme.taglist_squares_sel   = theme.dir .. "taglist/squarefz.png"
theme.taglist_squares_unsel = theme.dir .. "taglist/squareza.png"
--theme.taglist_squares_resize = "false"

-- Layout icons
theme.layout_tile          = theme.dir .. "layouts/tile.png"
theme.layout_tileleft      = theme.dir .. "layouts/tileleft.png"
theme.layout_tilebottom    = theme.dir .. "layouts/tilebottom.png"
theme.layout_tiletop       = theme.dir .. "layouts/tiletop.png"
theme.layout_fairv         = theme.dir .. "layouts/fairv.png"
theme.layout_fairh         = theme.dir .. "layouts/fairh.png"
theme.layout_spiral        = theme.dir .. "layouts/spiral.png"
theme.layout_dwindle       = theme.dir .. "layouts/dwindle.png"
theme.layout_max           = theme.dir .. "layouts/max.png"
theme.layout_fullscreen    = theme.dir .. "layouts/fullscreen.png"
theme.layout_magnifier     = theme.dir .. "layouts/magnifier.png"
theme.layout_floating      = theme.dir .. "layouts/floating.png"
theme.layout_termfair      = theme.dir .. "layouts/termfairw.png"
theme.layout_browse        = theme.dir .. "layouts/browsew.png"
theme.layout_gimp          = theme.dir .. "layouts/gimpw.png"
theme.layout_cascade       = theme.dir .. "layouts/cascadew.png"
theme.layout_cascadebrowse = theme.dir .. "layouts/cascadebrowsew.png"
theme.layout_centerwork    = theme.dir .. "layouts/centerworkw.png"


return theme

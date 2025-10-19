local colour = require("termplot.colour")
local Canvas = require("termplot.Canvas")
local utilities = require("termplot.utilities")

local record Figure
    __index: self
    __name: string

    width: integer
    height: integer

    top: integer
    bottom: integer
    left: integer
    right: integer

    title: string
    x_label: string
    y_label: string

    x_min: number | nil
    x_max: number | nil
    y_min: number | nil
    y_max: number | nil

    interface Series where self.kind
        enum Kind
            "line"
            "scatter"
            "bar"
            "heatmap"
        end

        kind: Kind
        label: string
        -- x_data: {number | string}
        -- y_data: {number}
        colour: colour.Colour
    end
    record Line is Series where self.kind == "line"
        x_data: {number}
        y_data: {number}
    end
    record Scatter is Series where self.kind == "scatter"
        x_data: {number}
        y_data: {number}
    end
    record Bar is Series where self.kind == "bar"
        labels: {string}
        values: {number}
        gap: number
    end
    record Heatmap is Series where self.kind == "heatmap"
        Z: {{number}}
        rows: integer
        cols: integer
    end
    series: {Series}

    axis_colour: colour.Colour
    grid_colour: colour.Colour
    colour_map: colour.ColourMap
    background_colour: colour.Colour | nil

    enum Domain
        "numeric"
        "categorical"
    end

    domain: Domain

    record HistogramDomain
        min: number
        max: number
        bins: integer
    end
    histogram_domain: HistogramDomain | nil

    record options
        interface Options
            colour: colour.Colour | nil
            label: string | nil
        end
        record Line is Options
            width: integer | nil
        end

        record Scatter is Options
            size: integer | nil
        end

        record Bar is Options
            gap: integer | nil
        end

        record Histogram is Options
            bins: integer | nil
        end
    end
end
Figure.__index = Figure
Figure.__name = "Figure"

local function env_int(name: string, def: integer): integer
    return tonumber(os.getenv(name) or "") as integer or def
end

function Figure:create(opts: Figure): Figure
    local termW = env_int("COLUMNS", 100)
    local termH = env_int("LINES",   30)

    local width  = opts.width  or math.max(50, math.min(termW - 2, 120))
    local height = opts.height or math.max(18, math.min(termH - 2, 40))

    local title  = opts.title  or ""
    local xlabel = opts.x_label or ""
    local ylabel = opts.y_label or ""

    -- margins in character cells
    local top    = opts.top    or (title ~= "" and 2 or 1)
    local bottom = opts.bottom or (xlabel ~= "" and 3 or 2)
    local right  = opts.right  or 2
    local left   = opts.left

    return setmetatable({
        width=width, height=height,
        top=top, bottom=bottom, right=right, left=left,
        title=title, x_label=xlabel, y_label=ylabel,
        series = opts.series or {},
        axis_colour = opts.axis_colour or { 170, 170, 170 },
        grid_colour = opts.grid_colour or { 90, 90, 90 },
        colour_map = opts.colour_map or "viridis",
        background_colour = opts.background_colour or nil, -- not painting background; terminals are faster without
        domain = opts.domain or "numeric",
        x_min = opts.x_min,
        x_max = opts.x_max,
        y_min = opts.y_min,
        y_max = opts.y_max,
    }, self as metatable<self>)
end

function Figure:line(x: {number}, y: {number}, opts?: Figure.options.Line): self
    if #x ~= #y then
        error("x and y data must have the same length")
    end
    opts = opts or {}

    local c: colour.Colour = opts.colour
    if c is nil then c = colour.SERIES_PALETTE[(#self.series % #colour.SERIES_PALETTE) + 1] end

    self.series[#self.series+1] = {
        kind = "line",
        label = opts.label,
        x_data = x,
        y_data = y,
        colour = c,
    } as Figure.Line

    return self
end

function Figure:scatter(x: {number}, y: {number}, opts?: Figure.options.Scatter): self
    if #x ~= #y then
        error("x and y data must have the same length")
    end
    opts = opts or {}

    local c: colour.Colour = opts.colour
    if c is nil then c = colour.SERIES_PALETTE[(#self.series % #colour.SERIES_PALETTE) + 1] end

    self.series[#self.series+1] = {
        kind = "scatter",
        label = opts.label,
        x_data = x,
        y_data = y,
        colour = c,
    } as Figure.Scatter

    return self
end

function Figure:bar(x: {string}, y: {number}, opts?: Figure.options.Bar): self
    if #x ~= #y then
        error("x and y data must have the same length")
    end
    opts = opts or {}

    local c: colour.Colour = opts.colour
    if c is nil then c = colour.SERIES_PALETTE[(#self.series % #colour.SERIES_PALETTE) + 1] end

    self.domain = "categorical"
    self.series[#self.series+1] = {
        kind = "bar",
        label = opts.label,
        labels = x,
        values = y,
        colour = c,
        gap = opts.gap or 0,
    } as Figure.Bar

    return self
end

function Figure:histogram(data: {number}, opts?: Figure.options.Histogram): self
    opts = opts or {}
    local bins = opts.bins or 20
    if bins < 1 then bins = 1 end
    -- compute min/max
    local min, max = math.huge, -math.huge
    for i = 1, #data do
        local v = data[i]
        if v < min then min = v end; if v > max then max = v end
    end
    if min == max then min, max = min - 0.5, max + 0.5 end
    local width = (max - min) / bins
    local counts = {}
    for i = 1, bins do counts[i] = 0 end
    for i = 1, #data do
        local idx = math.floor((data[i] - min) / width) + 1
        if idx < 1 then idx = 1 elseif idx > bins then idx = bins end
        counts[idx] = counts[idx] + 1
    end
    local labels: {string} = {}
    for i = 1, bins do labels[i as integer] = "" end
    self:bar(labels, counts, opts as Figure.options.Bar)
    self.histogram_domain = {
        min = min,
        max = max,
        bins = bins,
    }
    return self
end

function Figure:heatmap(Z: {{number}}, opts?: Figure.options.Options): self
    opts = opts or {}
    local rows = #Z
    local cols = (rows > 0 and #Z[1] or 0)
    if rows == 0 or cols == 0 then
        error("Z must be non-empty")
    end

    self.series[#self.series+1] = {
        kind = "heatmap",
        label = opts.label,
        x_data = {},
        y_data = {},
        colour = opts.colour or colour.SERIES_PALETTE[(#self.series % #colour.SERIES_PALETTE) + 1],
        Z = Z,
        rows = rows,
        cols = cols,
    } as Figure.Heatmap

    return self
end

function Figure:set_xlimit(a: integer, b: integer): self self.x_min, self.x_max = a, b; return self end
function Figure:set_ylimit(a: integer, b: integer): self self.y_min, self.y_max = a, b; return self end

local function series_bounds(series: {Figure.Series}): (number, number, number, number)
  local xmin, xmax = math.huge, -math.huge
  local ymin, ymax = math.huge, -math.huge
  for _, s in ipairs(series) do
    if s is Figure.Line or s is Figure.Scatter then
      for i = 1, #s.x_data do
        local x, y = s.x_data[i] as number, s.y_data[i]
        if x < xmin then xmin = x end
        if x > xmax then xmax = x end
        if y < ymin then ymin = y end
        if y > ymax then ymax = y end
      end
    elseif s is Figure.Bar then
      -- x is category index, y is value
      for i = 1, #s.values do
        local v = s.values[i]
        if v < ymin then ymin = v end
        if v > ymax then ymax = v end
      end
      xmin, xmax = 0.5, #s.values + 0.5
    elseif s is Figure.Heatmap then
      xmin, xmax = 0, s.cols
      ymin, ymax = 0, s.rows
    end
  end
  if xmin == math.huge then xmin, xmax, ymin, ymax = 0, 1, 0, 1 end
  if ymin == math.huge then ymin, ymax = 0, 1 end
  if ymin == ymax then ymin, ymax = ymin - 1, ymax + 1 end
  if xmin == xmax then xmin, xmax = xmin - 1, xmax + 1 end
  return xmin,xmax,ymin,ymax
end

local function draw_grid(canvas: Canvas, x_ticks_px: {integer}, y_ticks_py: {integer}, grid_colour: colour.Colour)
    for _, px in ipairs(x_ticks_px) do
        for py = 0, canvas.pixel_height - 1 do
          canvas:set_pixel(px, py, grid_colour)
        end
    end
    
    for _, py in ipairs(y_ticks_py) do
        for px = 0, canvas.pixel_width - 1 do
          canvas:set_pixel(px, py, grid_colour)
        end
    end
end

local type Function = function(number): integer
local function mapper(xmin: number, xmax: number, ymin: number, ymax: number, pw: integer, ph: integer): Function, Function
    local dx = (xmax - xmin)
    local dy = (ymax - ymin)
    local function fx(x: number): integer
        if dx == 0 then return 0 end
        local t = (x - xmin)/dx
        return math.floor(t * (pw-1) + 0.5)
    end
    local function fy(y: number): integer
        if dy == 0 then return 0 end
        local t = (y - ymin)/dy
        return math.floor(t * (ph-1) + 0.5)
    end
    return fx, fy
end

local function fmt_num(v: number): string
    if math.abs(v) >= 1e7 or (math.abs(v) > 0 and math.abs(v) < 1e-3) then
        return ("%0.3g"):format(v)
    else
        local s = ("%0.6f"):format(v)
        s = s:gsub("0+$",""):gsub("%.$","")
        return s
    end
end

function Figure:render(): string
    -- Plot area size (characters)
    local plot_cw = math.max(10, self.width)
    local plot_ch = math.max(6,  self.height)

    -- Axis ranges
    local xmin_opt, xmax_opt = self.x_min, self.x_max
    local ymin_opt, ymax_opt = self.y_min, self.y_max
    local xmin_fixed = xmin_opt ~= nil
    local xmax_fixed = xmax_opt ~= nil
    local ymin_fixed = ymin_opt ~= nil
    local ymax_fixed = ymax_opt ~= nil

    local xmin, xmax, ymin, ymax = xmin_opt, xmax_opt, ymin_opt, ymax_opt
    if not xmin or not xmax or not ymin or not ymax then
        local axmin, axmax, aymin, aymax = series_bounds(self.series)
        xmin = xmin or axmin
        xmax = xmax or axmax
        ymin = ymin or aymin
        ymax = ymax or aymax
    end
    xmin = xmin as number
    xmax = xmax as number
    ymin = ymin as number
    ymax = ymax as number

    -- Ticks
    local xn = 6
    local yn = 5
    local function trim_ticks(ticks: {number}, minv: number, maxv: number, clamp_min: boolean, clamp_max: boolean): {number}
        local res: {number} = {}
        for _, v in ipairs(ticks) do
            if (not clamp_min or v >= minv) and (not clamp_max or v <= maxv) then
                res[#res+1] = v
            end
        end
        if clamp_min then
            while #res > 0 and res[1] < minv do table.remove(res, 1) end
            if #res == 0 or res[1] > minv then
                table.insert(res, 1, minv)
            else
                res[1] = minv
            end
        end
        if clamp_max then
            while #res > 0 and res[#res] > maxv do res[#res] = nil end
            if #res == 0 or res[#res] < maxv then
                res[#res+1] = maxv
            else
                res[#res] = maxv
            end
        end
        return res
    end

    local x_ticks: {number}
    if self.domain == "categorical" then
        x_ticks = {}
    else
        x_ticks = trim_ticks(utilities.ticks(xmin, xmax, xn), xmin, xmax, xmin_fixed, xmax_fixed)
    end
    local y_ticks: {number} = trim_ticks(utilities.ticks(ymin, ymax, yn), ymin, ymax, ymin_fixed, ymax_fixed)

    -- Left margin to fit y labels
    local maxy = 0
    for _, v in ipairs(y_ticks) do
        local s = fmt_num(v)
        if #s > maxy then maxy = #s end
    end
    local left = self.left or (maxy + 3)  -- "label │ "
    local right = self.right

    -- Overall frame size
    local total_w = left + plot_cw + right

    -- Build canvas for plot area only
    local canvas: Canvas = Canvas:create(plot_cw, plot_ch)
    local fx, fy = mapper(xmin, xmax, ymin, ymax, canvas.pixel_width, canvas.pixel_height)

    -- Grid (pixel coords along major ticks)
    local x_ticks_px: {integer} = {}
    if self.domain ~= "categorical" then
        for _, x in ipairs(x_ticks) do
            x_ticks_px[#x_ticks_px+1] = fx(x)
        end
    else
        -- bars: grid at category centers (optional)
    end
    local y_ticks_py: {integer} = {}
    for _, y in ipairs(y_ticks) do
        y_ticks_py[#y_ticks_py+1] = fy(y)
    end
    draw_grid(canvas, x_ticks_px, y_ticks_py, self.grid_colour)

    -- Draw series
    for _, s in ipairs(self.series) do
        local col = s.colour

        if s is Figure.Line then
            for i = 1, #s.x_data - 1 do
                canvas:line(fx(s.x_data[i]), fy(s.y_data[i]), fx(s.x_data[i+1]), fy(s.y_data[i+1]), col)
            end
        elseif s is Figure.Scatter then
            for i = 1, #s.x_data do
                local px, py = fx(s.x_data[i]), fy(s.y_data[i])
                canvas:set_pixel(px, py, col)
            end
        elseif s is Figure.Bar then
            -- bars: category index on x in [0.5..N+0.5], value on y
            local N = #s.values
            local cat_w_char = math.max(1, math.floor(canvas.character_width / math.max(N, 1)))
            local gap = s.gap or 0.15
            local bar_w_px = math.max(1, math.floor(cat_w_char * 2 * (1 - gap)))
            for i = 1, N do
                -- center x of category i at x = i
                local x_center = fx(i)
                local half = math.floor(bar_w_px / 2)
                local px0, px1 = x_center - half, x_center + half
                local py0, py1 = fy(0), fy(s.values[i])
                canvas:rectangle(px0, math.min(py0, py1), px1, math.max(py0, py1), col, true)
            end
        elseif s is Figure.Heatmap then
            -- map cell centers to pixels; color via colormap
            local Z = s.Z
            local rows, cols = s.rows, s.cols
            -- vmin/vmax: compute bounds
            local vmin, vmax = math.huge, -math.huge
            for y = 1, rows do
                local row = Z[y]
                for x = 1, cols do
                    local v = row[x]
                    if v < vmin then vmin = v end
                    if v > vmax then vmax = v end
                end
            end
            if vmin == vmax then
                vmin, vmax = vmin - 1, vmax + 1
            end

            local cmap = self.colour_map or "viridis"
            for y = 1, rows do
                for x = 1, cols do
                    local v = Z[y][x]
                    local t = (v - vmin) / (vmax - vmin)
                    local heatcol = colour.colourmap_colour(cmap, t)
                    if heatcol then
                        local px = fx(x - 0.5)
                        local py = fy(y - 0.5)
                        -- fill a small block to make continuous
                        canvas:rectangle(px, py, px + 1, py + 1, heatcol, true)
                    end
                end
            end
        end
    end

    -- Render plot rows (strings), top->bottom
    local plot_rows = canvas:render_rows()

    -- Compose full frame lines with axes/labels
    local lines: {string} = {}

    -- Title (centered)
    if self.title ~= "" then
        local line = self.title
        if #line < total_w then
            local pad = math.floor((total_w - #line) / 2)
            line = string.rep(" ", pad) .. line
        end
        lines[#lines+1] = line
        -- pad remaining top-1 lines if any
        for _ = 2, self.top do
            lines[#lines+1] = ""
        end
    else
        for _ = 1, self.top do
            lines[#lines+1] = ""
        end
    end  -- Y tick rows mapping (char row index within plot area)
    local ytick_rows: {number: number} = {}
    for _, yv in ipairs(y_ticks) do
        local py = fy(yv)
        local row = math.floor((canvas.pixel_height - 1 - py) / 4) + 1
        ytick_rows[row] = yv
    end

    -- Left axis gutter width = left
    local axis_sgr = colour.colour_to_foreground(self.axis_colour)
    local gutter_pad = left - 2  -- space for "label "
    if gutter_pad < 0 then gutter_pad = 0 end

    -- Plot rows with y-axis and labels
    for r = 1, plot_ch do
        local label = ""
        local yv = ytick_rows[r]
        if yv ~= nil then
            local s = fmt_num(yv)
            if #s > gutter_pad then s = s:sub(1, gutter_pad) end
            label = string.rep(" ", gutter_pad - #s) .. s .. " " .. axis_sgr .. "│" .. colour.RESET .. " "
        else
            label = string.rep(" ", gutter_pad) .. " " .. axis_sgr .. "│" .. colour.RESET .. " "
        end
        lines[#lines+1] = label .. plot_rows[r]
    end

    -- Bottom axis line + x ticks
    local axis_line = string.rep(" ", gutter_pad) .. " " .. axis_sgr .. "└" .. string.rep("─", plot_cw) .. "┘" .. colour.RESET
    lines[#lines+1] = axis_line

    -- X tick labels (only for numeric domain)
    if self.domain ~= "categorical" then
        -- position labels under axis
        local tick_line = string.rep(" ", left)
        local taken: {number: boolean} = {}
        for _, xv in ipairs(x_ticks) do
            local px = fx(xv)
            local col_pos = math.min(plot_cw - 1, math.max(0, math.floor(px / 2)))
            local s = fmt_num(xv)
            local pos = left + col_pos - math.floor(#s / 2)
            if not taken[pos] then
                -- place s at position pos
                taken[pos] = true
                if pos < #tick_line then
                    -- replace substring
                    local pre = tick_line:sub(1, pos - 1)
                    local post = tick_line:sub(pos + #s)
                    tick_line = pre .. s .. post
                else
                    tick_line = tick_line .. string.rep(" ", pos - #tick_line) .. s
                end
            end
        end
        lines[#lines+1] = tick_line
    else
        -- Category ticks: evenly spaced markers
        local N = 0
        for _, s in ipairs(self.series) do
            if s is Figure.Bar then
                N = math.max(N, #s.values)
            end
        end
        if N > 0 then
            local tick_line = string.rep(" ", left)
            for i = 1, N do
                local px = fx(i)
                local col_pos = math.min(plot_cw - 1, math.max(0, math.floor(px / 2)))
                local pos = left + col_pos
                local marker = axis_sgr .. "┬" .. colour.RESET
                if pos < #tick_line then
                    tick_line = tick_line:sub(1, pos - 1) .. marker .. tick_line:sub(pos + 1)
                else
                    tick_line = tick_line .. string.rep(" ", pos - #tick_line) .. marker
                end
            end
            lines[#lines+1] = tick_line
        else
            lines[#lines+1] = ""
        end
    end

    -- X label
    if self.x_label ~= "" then
        local lab = self.x_label
        if #lab < total_w then
            local pad = math.floor((total_w - #lab) / 2)
            lab = string.rep(" ", pad) .. lab
        end
        lines[#lines+1] = lab
    end

    -- Legend (simple, one line, top-right above plot if title empty else after it)
    local legend_items: {string} = {}
    for _, s in ipairs(self.series) do
        if s.label then
            local col = s.colour
            local sgr = colour.colour_to_foreground(col)
            legend_items[#legend_items+1] = sgr .. "─" .. colour.RESET .. " " .. s.label
        end
    end
    if #legend_items > 0 then
        local legend = table.concat(legend_items, "   ")
        lines[#lines+1] = legend
    end

    return table.concat(lines, "\n")
end

function Figure:show(f?: FILE)
    f = f or io.stdout
    f:write(self:render(), "\n")
    f:flush()
end

return Figure

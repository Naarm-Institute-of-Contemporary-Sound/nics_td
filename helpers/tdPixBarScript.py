# me - this DAT
# scriptOp - the OP which is cooking

import math

def onSetupParameters(scriptOp):
    page = scriptOp.appendCustomPage('Custom')
    page.appendFloat('HeadX', label='Effect Speed')  # Controls speed
    page.appendInt('Gobo', label='Effect Type', min=0, max=7)  # Controls effect type (0-7)
    page.appendFloat('Timer', label='Timer', min=0.0, max=1.0)  # Modulates the effect
    return



PALETTE_DAT_NAME = '../rgbwTable'
PALETTE_HEADER_ALIASES = {
    'r': ('r', 'red'),
    'g': ('g', 'green'),
    'b': ('b', 'blue'),
    'w': ('w', 'white'),
}


def _cell_text(dat, row, col):
    try:
        value = dat[row, col]
    except Exception:
        return ''

    try:
        return str(value.val).strip()
    except AttributeError:
        return str(value).strip()


def _normalise_header(value):
    return value.lower().replace(' ', '').replace('_', '')


def _find_column(headers, aliases):
    for index, header in enumerate(headers):
        if header in aliases:
            return index
    return None


def _read_rgbw_palette(dat):
    try:
        row_count = dat.numRows
        col_count = dat.numCols
    except Exception:
        return None

    if row_count < 2 or col_count < 3:
        return None

    headers = [_normalise_header(_cell_text(dat, 0, col)) for col in range(col_count)]
    columns = {
        channel: _find_column(headers, aliases)
        for channel, aliases in PALETTE_HEADER_ALIASES.items()
    }

    if columns['r'] is None or columns['g'] is None or columns['b'] is None:
        return None

    palette = []
    for row in range(1, row_count):
        try:
            r = float(_cell_text(dat, row, columns['r']))
            g = float(_cell_text(dat, row, columns['g']))
            b = float(_cell_text(dat, row, columns['b']))
            w = float(_cell_text(dat, row, columns['w'])) if columns['w'] is not None else 0
        except Exception:
            continue
        palette.append((r, g, b, w))

    return palette or None


def _resolve_op(scriptOp, path):
    if not path:
        return None

    owners = [scriptOp]
    try:
        owners.append(scriptOp.parent())
    except Exception:
        pass

    for owner in owners:
        try:
            found = owner.op(path)
            if found is not None:
                return found
        except Exception:
            pass

    try:
        return op(path)
    except Exception:
        return None


def _external_palette(scriptOp):
    palette_dat = _resolve_op(scriptOp, PALETTE_DAT_NAME)
    return _read_rgbw_palette(palette_dat) if palette_dat is not None else None


def get_color(scriptOp, input_value: int):
    """
    Returns a single RGBW color mapped by spectrum based on an integer input (0-12).
    An external DAT with r/g/b/w headers overrides the default palette when present.
    Uses modulo so any input maps into the 12-color scale.

    Mapping (index -> colour -> note):
    0 deep red (F), 1 red (C), 2 orange (G), 3 yellow (D),
    4 green (A), 5 sky blue (E), 6 blue (B), 7 bright blue (F♯),
    8 violet/purple (C♯), 9 lilac (G♯), 10 flesh (D♯), 11 rose (A♯)
    """
    external = _external_palette(scriptOp)
    if external:
        return external[input_value % len(external)]

    colors = [
        (200, 0, 0, 0),      # deep red - F (more saturated, away from white)
        (255, 0, 0, 0),      # red - C
        (255, 100, 0, 0),    # orange - G (deeper orange for visibility)
        (255, 170, 0, 0),    # yellow - D (amber to avoid white-ish yellow)
        (0, 255, 0, 0),      # green - A
        (0, 200, 255, 0),    # sky blue - E (vivid cyan/sky)
        (0, 0, 255, 0),      # blue - B
        (0, 80, 255, 0),     # bright blue - F# (electric blue)
        (120, 0, 255, 0),    # violet/purple - C# (vivid violet)
        (200, 0, 200, 0),    # lilac - G# (strong magenta-lilac)
        (255, 80, 40, 0),    # flesh - D# (coral - more visible)
        (255, 0, 150, 0),    # rose - A# (hot pink)
    ]
    return colors[input_value % len(colors)]



def apply_effect(gobo, timer, index, headX, intensity=1.0):
    """
    Generates an effect based on the gobo mode (0-7), timer, and pixel index.
    """
    timer = (timer + index * 0.1 * headX) % 1.0  # Ensure looping within 0-1
    effects = [
        lambda t: (math.sin(t * 2 * math.pi) * 0.5 + 0.5) * intensity,  # Wave pulse in
        lambda t: (1 - math.sin(t * 2 * math.pi) * 0.5 - 0.5) * intensity,  # Wave pulse out
        lambda t: ((math.sin(t * 4 * math.pi) + 1) / 2) * intensity,  # Fast oscillation
        lambda t: 1 if (t % 1) > 0.5 else 0,  # Chasing effect
        lambda t: abs(math.sin(t * 4 * math.pi)) * intensity,  # Strobe effect
        lambda t: (1 - abs(math.sin(t * 4 * math.pi))) * intensity,  # Reverse strobe
        lambda t: ((math.cos(t * 4 * math.pi) + 1) / 2) * intensity,  # Smooth fade
        lambda t: intensity,  # Static full brightness
    ]
    return effects[gobo % len(effects)](timer)



def onCook(scriptOp):
    scriptOp.clear()
    inputOp = scriptOp.inputs[0]

    timerOp = op('timer1')

    if timerOp['running'] == 0:
        timerOp.par.start.pulse()

    col = inputOp['color']
    dim = float(inputOp['dimmer'])
    gobo = int(inputOp['gobo'])
    headX = float(inputOp['headX'])
    headY = float(inputOp['headY'])

    time = float(timerOp['timer_fraction'])

    chan_count = 7

    rv, gv, bv, wv = get_color(scriptOp, int(col))
    for i in range(0, chan_count):
        r = scriptOp.appendChan(f"r{i}")
        g = scriptOp.appendChan(f"g{i}")
        b = scriptOp.appendChan(f"b{i}")
        w = scriptOp.appendChan(f"w{i}")

        # effect_strength = apply_effect(gobo, time, i, headX, intensity=dim)
        #if i > headX*chan_count and i < headY*chan_count:
        #    effect_strength = 1.0
        #else:
        #    effect_strength = 0.0

        effect_strength = 1.0

        r[0] = rv * effect_strength
        g[0] = gv * effect_strength
        b[0] = bv * effect_strength
        w[0] = wv * effect_strength

    return

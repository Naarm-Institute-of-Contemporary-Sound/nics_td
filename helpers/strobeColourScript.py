# me - this DAT
# scriptOp - the OP which is cooking

# press 'Setup Parameters' in the OP to call this function to re-create the parameters.
def onSetupParameters(scriptOp):
	page = scriptOp.appendCustomPage('Custom')
	p = page.appendFloat('Valuea', label='Value A')
	# p = page.appendFloat('Valueb', label='Value B')
	return

# called whenever custom pulse parameter is pushed
def onPulse(par):
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
        (220, 0, 0, 0),      # deep red - F (darker, saturated)
        (255, 0, 0, 0),      # red - C
        (255, 90, 0, 0),     # orange - G (deeper orange)
        (255, 160, 0, 0),    # yellow - D (amber to avoid white-ish)
        (0, 255, 0, 0),      # green - A
        (0, 255, 120, 0),    # sky blue - E (greenish-cyan to separate from blues)
        (0, 0, 255, 0),      # blue - B (pure blue)
        (0, 100, 255, 0),    # bright blue - F# (azure, distinct from pure blue)
        (180, 0, 255, 0),    # violet/purple - C# (strong violet)
        (255, 0, 200, 0),    # lilac - G# (magenta-lilac, saturated)
        (255, 70, 30, 0),    # flesh - D# (coral, higher contrast)
        (255, 0, 160, 0),    # rose - A# (hot pink)
    ]
    return colors[input_value % len(colors)]



def onCook(scriptOp):
	scriptOp.clear()

	inputOp = scriptOp.inputs[0]

	# selIndex = int(scriptOp.name[-1])
	selIndex = 1

	inp = inputOp[0]

	rv, gv, bv, wv = get_color(scriptOp, int(inp))

	for i in range(0, 1):
		r = scriptOp.appendChan("r")
		g = scriptOp.appendChan("g")
		b = scriptOp.appendChan("b")
		w = scriptOp.appendChan("w")

		r[0] = rv
		g[0] = gv
		b[0] = bv
		w[0] = wv

	return

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


def get_color_pair(scriptOp, input_value: int):
	"""
	Returns a pair of RGBW colors for techno club lighting based on an integer input (0-7).
	An external DAT with r/g/b/w headers overrides the default palette when present.

	Args:
		input_value (int): An integer between 0 and 7.

	Returns:
		tuple: A pair of RGBW tuples.
	"""
	external = _external_palette(scriptOp)
	if external:
		color = external[input_value % len(external)]
		return (color, color)

	# Ensure input is within the allowed range
	if input_value < 0 or input_value > 7:
		raise ValueError("Input must be an integer between 0 and 7.")

	# Define color pairs as RGBW tuples
	rgbw_colors = [
		# Harmonious pairs: Same or very close shades for a unified effect.
		[(255, 0, 128, 0), (255, 0, 128, 0)],  # Neon pink
		[(0, 255, 200, 0), (0, 255, 200, 0)],  # Bright turquoise
		[(255, 215, 0, 0), (255, 215, 0, 0)],  # Electric gold

		# Contrasting pairs: High-energy complementary combinations for striking contrast.
		[(255, 69, 0, 0), (30, 144, 255, 0)],  # Orange-red and electric blue
		[(138, 43, 226, 0), (255, 215, 0, 0)],  # Electric violet and bright gold
		[(0, 255, 0, 0), (255, 0, 255, 0)],  # Acid green and magenta
		[(255, 0, 0, 0), (0, 255, 255, 0)],  # Red and cyan
		[(148, 0, 211, 0), (255, 165, 0, 0)],  # Deep violet and orange
	]

	return rgbw_colors[input_value]



def onCook(scriptOp):
	scriptOp.clear()

	inputOp = scriptOp.inputs[0]

	selIndex = int(scriptOp.name[-1])
	inp = inputOp[0]
	rv, gv, bv, wv = get_color_pair(scriptOp, int(inp))[selIndex % 2]


	for i in range(0, 3):
		r = scriptOp.appendChan("r")
		g = scriptOp.appendChan("g")
		b = scriptOp.appendChan("b")
		w = scriptOp.appendChan("w")

		r[0] = rv
		g[0] = gv
		b[0] = bv
		w[0] = wv

	return

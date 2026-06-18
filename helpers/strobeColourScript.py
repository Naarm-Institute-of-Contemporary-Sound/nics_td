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



def get_color(input_value: int):
    """
    Returns a single RGB color mapped by spectrum based on an integer input (0–12).
    Uses modulo so any input maps into the 12-color scale.

    Mapping (index -> colour -> note):
    0 deep red (F), 1 red (C), 2 orange (G), 3 yellow (D),
    4 green (A), 5 sky blue (E), 6 blue (B), 7 bright blue (F♯),
    8 violet/purple (C♯), 9 lilac (G♯), 10 flesh (D♯), 11 rose (A♯)
    """
    colors = [
        (220, 0, 0),      # deep red - F (darker, saturated)
        (255, 0, 0),      # red - C
        (255, 90, 0),     # orange - G (deeper orange)
        (255, 160, 0),    # yellow - D (amber to avoid white-ish)
        (0, 255, 0),      # green - A
        (0, 255, 120),    # sky blue - E (greenish-cyan to separate from blues)
        (0, 0, 255),      # blue - B (pure blue)
        (0, 100, 255),    # bright blue - F♯ (azure, distinct from pure blue)
        (180, 0, 255),    # violet/purple - C♯ (strong violet)
        (255, 0, 200),    # lilac - G♯ (magenta-lilac, saturated)
        (255, 70, 30),    # flesh - D♯ (coral, higher contrast)
        (255, 0, 160),    # rose - A♯ (hot pink)
    ]
    return colors[input_value % len(colors)]



def onCook(scriptOp):
	scriptOp.clear()

	inputOp = scriptOp.inputs[0]

	# selIndex = int(scriptOp.name[-1])
	selIndex = 1

	inp = inputOp[0]

	rv, gv, bv = get_color(int(inp))

	for i in range(0, 1):
		r = scriptOp.appendChan("r")
		g = scriptOp.appendChan("g")
		b = scriptOp.appendChan("b")
		w = scriptOp.appendChan("w")

		r[0] = rv
		g[0] = gv
		b[0] = bv

	return

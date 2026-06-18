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
        (200, 0, 0),      # deep red - F (more saturated, away from white)
        (255, 0, 0),      # red - C
        (255, 100, 0),    # orange - G (deeper orange for visibility)
        (255, 170, 0),    # yellow - D (amber to avoid white-ish yellow)
        (0, 255, 0),      # green - A
        (0, 200, 255),    # sky blue - E (vivid cyan/sky)
        (0, 0, 255),      # blue - B
        (0, 80, 255),     # bright blue - F♯ (electric blue)
        (120, 0, 255),    # violet/purple - C♯ (vivid violet)
        (200, 0, 200),    # lilac - G♯ (strong magenta-lilac)
        (255, 80, 40),    # flesh - D♯ (coral — more visible)
        (255, 0, 150),    # rose - A♯ (hot pink)
    ]
    return colors[input_value % len(colors)]



def onCook(scriptOp):
	scriptOp.clear()

	inputOp = scriptOp.inputs[0]

	selIndex = int(scriptOp.name[-1])

	inp = inputOp[0]

	rv, gv, bv = get_color(int(inp))

	for i in range(0, 3):
		r = scriptOp.appendChan("r")
		g = scriptOp.appendChan("g")
		b = scriptOp.appendChan("b")
		w = scriptOp.appendChan("w")

		r[0] = rv
		g[0] = gv
		b[0] = bv

	return

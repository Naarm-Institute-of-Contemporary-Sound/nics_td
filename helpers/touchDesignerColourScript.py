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


def get_color_pair(input_value: int):
	"""
	Returns a pair of colors for techno club lighting based on an integer input (0-7).

	Args:
		input_value (int): An integer between 0 and 7.

	Returns:
		tuple: A pair of RGB tuples.
	"""
	# Ensure input is within the allowed range
	if input_value < 0 or input_value > 7:
		raise ValueError("Input must be an integer between 0 and 7.")

	# Define color pairs as RGB tuples
	rgb_colors = [
		# Harmonious pairs: Same or very close shades for a unified effect.
		[(255, 0, 128), (255, 0, 128)],  # Neon pink
		[(0, 255, 200), (0, 255, 200)],  # Bright turquoise
		[(255, 215, 0), (255, 215, 0)],  # Electric gold

		# Contrasting pairs: High-energy complementary combinations for striking contrast.
		[(255, 69, 0), (30, 144, 255)],  # Orange-red and electric blue
		[(138, 43, 226), (255, 215, 0)],  # Electric violet and bright gold
		[(0, 255, 0), (255, 0, 255)],  # Acid green and magenta
		[(255, 0, 0), (0, 255, 255)],  # Red and cyan
		[(148, 0, 211), (255, 165, 0)],  # Deep violet and orange
	]

	return rgb_colors[input_value]



def onCook(scriptOp):
	scriptOp.clear()

	inputOp = scriptOp.inputs[0]

	selIndex = int(scriptOp.name[-1])


	for i in range(0, 3):
		r = scriptOp.appendChan("r")
		g = scriptOp.appendChan("g")
		b = scriptOp.appendChan("b")
		w = scriptOp.appendChan("w")

		inp = inputOp[0]

		rv, gv, bv = get_color_pair(int(inp))[selIndex]
		r[0] = rv
		g[0] = gv
		b[0] = bv

	return

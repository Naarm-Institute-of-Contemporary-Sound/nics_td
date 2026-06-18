# me - this DAT
# scriptOp - the OP which is cooking

import math

def onSetupParameters(scriptOp):
    page = scriptOp.appendCustomPage('Custom')
    page.appendFloat('HeadX', label='Effect Speed')  # Controls speed
    page.appendInt('Gobo', label='Effect Type', min=0, max=7)  # Controls effect type (0-7)
    page.appendFloat('Timer', label='Timer', min=0.0, max=1.0)  # Modulates the effect
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

    rv, gv, bv = get_color(int(col))
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
        w[0] = 0 #(rv + gv + bv) / 3 * effect_strength  # Use white channel dynamically

    return

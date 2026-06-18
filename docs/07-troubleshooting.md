# Troubleshooting

## Audio Upload Takes Too Long

Possible causes:

- The file is very long.
- The browser is under heavy load.
- Basic Pitch is processing many notes.

Try:

- Use a shorter excerpt.
- Close other browser tabs.

## Too Many Lighting Events

Try:

- Raise Basic Pitch cull.
- Narrow source ranges.
- Disable overlap for some groups.
- Clear timeline automation in busy sections.

## Live MIDI Preview Does Nothing

Check:

- Browser supports Web MIDI.
- Live note output is enabled.
- Correct output device is selected.
- TouchDesigner or the loopback receiver is listening to the same device.
- MIDI channel 1 is expected downstream.

## Stuck Notes or Bad Receiver State

Click Send all notes off in the live note output panel.

If the state is still bad:

- Stop Ableton transport.
- Restart TouchDesigner MIDI input.
- Disable and re-enable the loopback device.
- Use the venue blackout if lights remain unsafe.

## Exported MIDI Does Not Trigger Lights

Check:

- The MIDI file is on channel 1.
- Ableton routes MIDI to TouchDesigner.
- TouchDesigner is listening to the correct input.
- Notes are in the range `0-17`.
- Fixture groups are enabled.

## Lights Are Too Bright

Try:

- Lower brightness in MIDI control settings.
- Use TouchDesigner or DMX master brightness limits.
- Enable music listen brightness limiting if appropriate.

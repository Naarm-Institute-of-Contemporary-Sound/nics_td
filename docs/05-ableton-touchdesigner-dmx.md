# Ableton, TouchDesigner, and DMX Playback

## Export from the Web Tool

Export the lighting MIDI file from the browser.

## Import into Ableton


1. Open a new Ableton Project
2. Import the audio track.
3. Import the exported lighting MIDI.
4. Align both clips to bar/time `0`.
5. Route MIDI to the expected TouchDesigner input (defaults are LoopMIDI / IAC Driver 0)
6. When you play, you should see TouchDesigner / blender light up!
	1. If you don't see anything, go to Ableton preferences (Options (top bar)->Settings->MIDI 1 should be loopMIDI Port output, Control Surface should be TouchDesigner if it's an option in there)
7. Don't forget to save!

## TouchDesigner Receiver


1. Open the NICS TouchDesigner .toe file.
2. Open Dialogs->MIDI Mapper on the TouchDesigner top bar (Alt+d). 
	1. Confirm MIDI input device is the correct LoopBack interface, assigned to slot 1. 
	2. If it's not showing up, you may need to make sure your loopback is running and restart TouchDesigner, it often does not hot reload.
3. Confirm channel 1 is receiving notes in the MIDI Mapper when they are played
4. Confirm notes `0-17` trigger fixture groups.
5. Confirm CC controls are received.
6. Confirm fixture enables and phasor enables work.

## DMX Output


1. Confirm DMX interface.
2. Confirm fixture patch.
3. Start with low brightness.
4. Test one fixture group at a time.
5. Confirm blackout or emergency stop.

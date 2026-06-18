# Glossary

This glossary defines the terms used throughout the NICS MIDI Lighting Tool and Touch Designer setup

## Core Analysis Terms

### Offline Analysis

Offline analysis means the tool analyzes a whole audio or MIDI file before the show is played. The result is a prepared set of MIDI notes and control changes that can be inspected, edited, exported, and replayed later.

In this tool, offline analysis includes:

- Running Basic Pitch on an uploaded audio file.
- Reading notes from an uploaded MIDI file.
- Filtering low-confidence Basic Pitch notes.
- Mapping source notes into the NICS lighting note range.
- Exporting a finished `.mid` file.

Offline analysis is useful because it is repeatable. The same exported MIDI file should trigger the same lighting events every time.

### Online Analysis

Online analysis means a system listens or reacts while the song is playing. It does not need a precomputed note file. It can respond to the current sound, energy, or incoming signals in real time.

In the NICS lighting workflow, online analysis may include:

- TouchDesigner listening to live audio.
- A music-listen control limiting brightness from bass energy.
- Live visuals reaction to audio.

Online analysis is useful because it can react to performance changes, but it is less predictable than offline analysis.

### Key Difference

Offline analysis prepares lighting decisions before playback. Online analysis reacts during playback.

| Topic           | Offline analysis                                 | Online analysis                                                                            |
| --------------- | ------------------------------------------------ | ------------------------------------------------------------------------------------------ |
| When it happens | Before playback                                  | During playback                                                                            |
| Repeatability   | High                                             | Variable                                                                                   |
| Good for        | Composed cues, detailed editing, rehearsed shows | Live response, dynamic energy, improvised performance, each performance being different :) |
| Example         | Exported MIDI notes from this website            | TouchDesigner audio-reactive brightness                                                    |

## MIDI Terms

### MIDI

MIDI is a control protocol. It does not contain audio by itself. It contains messages such as note on, note off, pitch bend, channel pressure, and control change. It can run over wires, or live virtually in your computer.

### MIDI Note

A MIDI note is a numbered pitch event from `0` to `127`. In this tool, the exported lighting trigger notes are constrained to `0-17`.

### Note On / Note Off

Note on starts an event. Note off ends it. For lighting, each note on event turns a light on, note off turns the light off. Light brightness is subject to a max of whatever the dimmer CC channel is set to, see below.

### Control Change / CC

A control change message changes a parameter. In this workflow, CC messages can set brightness, colour, fixture enables, phasor enables, and visual parameters. In traditional MIDI setups, they can be used for pitch bend or other instrument parameters, they are independent from notes.

### Channel 1

The tool outputs on MIDI channel 1. Some software internally numbers that channel as `0`, but performers will usually see it as channel 1.

### Pitch Bend

Pitch bend is used here for moving head X positioning.

### Channel Pressure

Channel pressure is used here for moving head Y positioning.

### All Notes Off

All Notes Off is a panic-style MIDI message used to clear stuck notes. The browser preview panel also sends individual note-off messages for all notes when the panic button is pressed.

## Tool Terms

### Basic Pitch

Basic Pitch is Spotify's audio-to-MIDI model. This tool runs it in the browser to estimate note events from an uploaded audio file. The audio never leaves your device.

### Confidence Cull

The confidence cull slider removes low-confidence Basic Pitch detections. Raising it usually makes the lighting less busy.

### Downmap

Downmapping means taking source notes from an audio or MIDI file and remapping them into the small NICS lighting note range.

### Source Range

The selected range of notes from the original source that should feed a lighting fixture group.

### Target Notes

The low MIDI notes the NICS MIDI tool exports for lighting. The target range is `0-17`.

### Timeline

The visual preview of mapped lighting notes across time. The timeline also contains editable enable automation for fixture groups and phasors.

### Live Note Output

Browser MIDI preview mode. It sends the mapped notes out of the browser through Web MIDI which can go straight into Touch Designer for pre-vis without dragging into Ableton.

## Fixture and Lighting Terms

### Pixel Bars

Linear LED fixtures, 2 in total next to each other, each sub-divided into 4 equal sections for 8 total targets.

### Parcans

Wash-style lights. They use 2 target notes and can blend visually with pixel bars. These are a little slow to produce and dim, not very punchy.

### Small Moving Heads

Smaller moving head fixtures, 60W LEDs a pop. They use 4 target notes.

### Big Moving Heads

Beeeg moving head fixtures. They use 3 target notes as there are 3 of them on top of the NICS lockers and are especially affected by gobo and movement controls. Each one of these alone puts out as much light as every other light combined (except the strobe), they are more of an outdoor thing but I think it's very funny to have them in a 27sqm room, there are 3 more that are in for repair but will hopefully be making the NICS way too bright very soon.

### Strobe

Event Lighting 400W wash light, very bright, can strobe.

### DMX

DMX is the lighting control protocol used to send final fixture values to real lighting hardware, or can be sent over "ArtNet" to Blender virtual hardware. DMX is electrically RS485 at fixed baud / stop bits etc.

### TouchDesigner / TD

TouchDesigner is the visual and control environment that receives MIDI and turns it into fixture and visual behavior.

### Ableton

Ableton Live is used as the playback and arrangement environment for the exported MIDI and audio.

## Performance Terms

### Cue

A planned lighting event or section.

### Fixture Enable

A control that turns a group of fixtures on or off for part of the song.

### Phasor

A repeating automation source used for movement or parameter modulation.

### Gobo

Beam shape or pattern control on moving heads. Lower values tend to be tighter, higher values broader.

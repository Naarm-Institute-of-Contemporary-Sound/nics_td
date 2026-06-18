# System Overview

This document explains the overall workshop system.

## The Short Version

Participants use the web tool to create lighting MIDI from audio or MIDI. The result is exported and played back in Ableton. TouchDesigner receives the MIDI and controls visuals, lighting logic, and DMX output.

```text
Audio or MIDI file
  -> NICS MIDI Lighting Tool
  -> exported lighting MIDI
  -> Ableton playback
  -> TouchDesigner
  -> DMX / fixtures / visuals
```

## What the Web Tool Does

- Accepts audio files for Basic Pitch conversion.
- Accepts direct MIDI files.
- Maps source pitch ranges into NICS fixture-note groups.
- Lets participants edit fixture and phasor enable automation.
- Lets participants preview timing against audio.
- Exports a MIDI file designed for the NICS playback patch.

## What the Web Tool Does Not Do

- It does not output DMX directly.
- It does not replace Ableton or TouchDesigner.
- It does not guarantee that generated lighting will be safe or tasteful without human review.
- It does not know the physical room, audience sightlines, or fixture patch unless those are encoded in the downstream system.

## Target MIDI Note Map

| Fixture group | Notes | Count |
| --- | ---: | ---: |
| Strobe | `0` | 1 |
| Pixel bars | `1-8` | 8 |
| Small moving heads | `9-12` | 4 |
| Parcans | `13-14` | 2 |
| Big moving heads | `15-17` | 3 |

## Key Control Messages

| Control | MIDI message |
| --- | --- |
| Moving head X | Pitch bend |
| Moving head Y | Channel pressure |
| Brightness | `CC1` |
| Colour preset | `CC2` |
| Lag up | `CC3` |
| Lag down | `CC4` |
| Gobo | `CC5` |
| Fixture enables | `CC20-24` |
| Phasor enables | `CC10-12` |
| Head X phasor controls | `CC51-54` |
| Head Y phasor controls | `CC61-64` |
| Dimmer phasor controls | `CC71-74` |


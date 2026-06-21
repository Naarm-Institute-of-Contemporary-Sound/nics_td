# NICS Performance Stack
![NICS Stack Architecture](assets/diagram.png)
## Required Dependencies

### Blender (free) [![Blender](https://img.shields.io/badge/Blender-5.1-E87D0D?style=flat-square&logo=blender&logoColor=white)]()

#### App Install
Blender can be downloaded [here](https://www.blender.org/download/) (version >=4.2 required)

This addon is require [Blender DMX Addon](https://blenderdmx.eu/) (easy drag and drop install!)

#### Project File
Available here - [Blender project file]( https://drive.google.com/drive/u/3/folders/1sAy4BP1EEYKHOK9oG2kL2qmoLLUDh9_x)

---
### Touch Designer (free)  [![TouchDesigner](https://img.shields.io/badge/TouchDesigner-2025.32820-black?style=flat-square)]()

#### App Install
TouchDesigner (TD) can de downloaded [here](https://derivative.ca/download) (version >=2025.32820 required)

#### Project File
NICS TD project file is in this repo, which can be downloaded once off as a [zip file](https://github.com/Naarm-Institute-of-Contemporary-Sound/nics_td/archive/refs/heads/main.zip). 
Or if you're a Git enjoyer, it can be cloned with [ssh](git@github.com:Naarm-Institute-of-Contemporary-Sound/nics_td.git) or [https](https://github.com/Naarm-Institute-of-Contemporary-Sound/nics_td.git) (please feel free to push to a branch and make a PR)

The NICS TD project file relies on a few supporting files in the `helper/` directory, please keep the project file with this dir

---
### NICS MIDI Assignment Tool

#### App Install
This free online component can be accessed [here](https://naarm-institute-of-contemporary-sound.github.io/nics_midi_lighting_tool/)
#### Project File
Drag and drop in any audio file! This tool will help you to generate MIDI files that can be played back to Touch Designer and trigger lights

---
### Ableton / a DAW  [![Ableton|114](https://img.shields.io/badge/Ableton-Live%2012-yellow?style=flat-square&logo=abletonlive)]()

The lite version of Ableton will work fine here, it comes bundled with a lot of MIDI controllers for free, or can be purchased online for a few $ from sketchy websites. The full version of Ableton can be purchased from Ableton themselves. Alternatively there is a free trial downloadable [here](https://www.ableton.com/en/trial/) 

Other DAWs capable of outputting MIDI notes and MIDI CC should work fine here, but are not documented yet

---
## The Glue - MIDI + Audio Loopback (all free)

### MacOS
[IACDriver](https://support.apple.com/en-au/guide/audio-midi-setup/ams1013/mac)
[Blackhole](https://github.com/existentialaudio/blackhole#installation-instructions)
These drivers run in the background and don't need an open application
### Windows
[LoopMIDI](https://www.tobias-erichsen.de/software/loopmidi.html)
[Voicemeeter](https://vb-audio.com/Voicemeeter/)
Both these programs must be installed and running while in use
### Loopback Setup
- Ensure Ableton / your DAW is outputting audio to either Blackhole audio (MacOS) or Voicemeeter Input (Win) 
- Ensure Ableton / your DAW is outputting MIDI to your loopback device (IAC Driver 1 / Loop MIDI)
- Ensure Blackhole / Voicemeeter is outputting to your real speakers so you can hear it
- Ensure TouchDesigner is setup to receive MIDI
	-  Open Dialogs->MIDI Mapper on the TouchDesigner top bar (Alt+d). 
		1. Confirm MIDI input device is the correct LoopBack interface, assigned to slot 1. 
		2. If it's not showing up, you may need to make sure your loopback is running and restart TouchDesigner, it often does not hot reload.
- Ensure TouchDesigner is setup with the right audio loopback as input, zoom into the yellow area in the middle left of the file, there should be a blue box with a blue note, follow the instructions in that note to assign either Blackhole or Voicemeeter Out B1 as the input device

EEGJ
====

New Media Team Project for team Codename Riri, "Electroencephalogram Jockey," or EEGJ.

### Overview

*Image of Exhibit*

"EEGJ: An immersive audio/visual experience. Created using EEG technology to turn the rhythms of your heart and mind into music for the danceﬂoor! EEGJ puts you in the DJ booth, allowing you to create personal beats and visuals using data generated from your brain, heart, and hands."

EEGJ was on exhibit at the 2014 Imagine RIT event at the Rochester Institute of Technology. Brain data gathered from a user through a hacked [MindFlex](http://mindflexgames.com/) EEG headset is used to modulate the parameters of a unique, generative MIDI soundscape. Auxiliary pressure sensors are used to control audio filters as well. All user input is used to affect the visual display, which includes turntables, speakers, graphs, and even a Guitar Hero-esque game to guide users through the experience.

### Exhibit 

*Image of Exhibit Layout*

#### Complete List of Materials

* Three 7-foot wide projector screens
* Three projectors, 1024x768 resolution, 4:3 aspect ratio, appropriate cables
* Computer with 4 USB ports, sufficient CPU/memory, support for 3 displays
* A "hacked" MindFlex headset (and one Arduino Uno)
* Two pressure sensors (connected to an Arduino Uno)
* Appropriate audio setup

#### Space

EEGJ was made with Imagine RIT in mind as its one-time-only showcase. The exhibit was placed in a large classroom with plenty of free space and a 10 or 12 foot high ceiling. This allowed us to hang projector screens from the ceiling and bring the display closer to the entrance. The room got very dark without lights, which suited our projector-powered display very well. Speakers were placed around the room, connected to a surround sound system.

#### Display

At Imagine RIT EEGJ was projected across three 7-foot wide screens. The screens were hung from the ceiling, suspended by zipties and a foot of chain. The projectors were set at a resolution of 1024x768 and a 4:3 aspect ratio. They were placed between 10 to 12 feet away from the screen.

EEGJ does not scale with the size of its displays, it is fixed at 3072x768. The sketch is displayed in "fullscreen" mode; it drawn from the top-left corner of the display area without window chrome. Each section of the EEGJ sketch takes up an entire 1024x768 screen. 

#### Sensors and "The Chair"

The primary input device for EEGJ is the MindFlex headset. We ["hacked" the MindFlex](http://frontiernerds.com/brain-hack) and hooked it up to an Arduino Uno, using the [Arduino Brian](https://github.com/kitschpatrol/Brain) library to read the data from the MindFlex. The MindFlex was used to control the music, the visuals, and the game. More on how we use the data below.

The user sat in a chair on a platform in front of the three projector screens. The MindFlex was placed on their head. In addition to the MindFlex the chair included two [pressure sensors](https://www.adafruit.com/products/166), one mounted by each armrest, both connected to an Arduino through a breadboard. These were used to control additional audio filters, but did not have a direct impact on the music, visuals, or game.

#### Computer

The whole setup was powered by a team member's desktop computer: 3rd generation i7 processor, 16 GB of RAM, Nvidia GTX 660 graphics card. EEGJ in its current state takes up an average of 20% CPU and 2GB of RAM when running, so make sure your computer can accomodate. More importantly, make sure your graphics card supports 3 simultaneous displays. You will also need four free USB ports: one for a mouse, one for a keyboard, one for the MindFlex headset Adruino, and one for the pressure sensor Arduino.

#### Ableton Live Setup

In addition to running EEGJ, the computer was also running Ableton Live. A set was created with several instrument tracks, each one mapped to an instrument/channel. MIDI data was generated in Processing and sent to Ableton using a [virtual MIDI bus](https://www.ableton.com/en/articles/using-virtual-MIDI-buses-live/). Our set can be found here: *link to EEGJ set*

### Code 

#### Setup and Dependencies

Setting up the EEGJ program is relatively simple. All you need is Processing, the EEGJ sketch code, and a few contributed libraries:

* TheMidiBus: [http://www.smallbutdigital.com/themidibus.php](http://www.smallbutdigital.com/themidibus.php)
* Arduino (Firmata): [http://playground.arduino.cc/Interfacing/Processing](http://playground.arduino.cc/Interfacing/Processing)
* Ani: [http://www.looksgood.de/libraries/Ani/](http://www.looksgood.de/libraries/Ani/)

These contributed libraries can be installed manually or through the Processing IDE (under Sketch -> Import Library -> Add Library). Included in the code are several components made by the individual developers of EEGJ that can be used independently of this project, including: 
   
* RiriFramework: [https://github.com/codenameriri/riri-framework](https://github.com/codenameriri/riri-framework)    
* DataGen: [https://github.com/tconroy/Data-Gen](https://github.com/tconroy/Data-Gen)    

#### Usage and Configuration

To run EEGJ, just open the main sketch file (EEGJ.pde) in Processing and click the Run button. EEGJ will still run without the MindFlex or pressure sensors; it will fall back on data generated by DataGen. 

### Sources

* Processing Reference: [http://processing.org/reference/](http://processing.org/reference/)    
* Hacking the MindFlex: [http://frontiernerds.com/brain-hack](http://frontiernerds.com/brain-hack)    
* Virtual MIDI Buses: [https://www.ableton.com/en/articles/using-virtual-MIDI-buses-live/](https://www.ableton.com/en/articles/using-virtual-MIDI-buses-live/)    
* MIDI Mapping in Ableton: [https://www.ableton.com/en/articles/getting-started-3-setting-your-midi-controller/](https://www.ableton.com/en/articles/getting-started-3-setting-your-midi-controller/)    

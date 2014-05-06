EEGJ
====

New Media Team Project for team Codename Riri, "Electroencephalogram Jockey," or EEGJ.

### Overview

"EEGJ: An immersive audio/visual experience. Created using EEG technology to turn the rhythms of your heart and mind into music for the danceﬂoor! EEGJ puts you in the DJ booth, allowing you to create personal beats and visuals using data generated from your brain, heart, and hands."

EEGJ was on exhibit at the 2014 Imagine RIT event at the Rochester Institute of Technology. Brain data gathered from a user through a hacked [MindFlex](http://mindflexgames.com/) EEG headset is used to modulate the parameters of a unique, generative MIDI soundscape. Auxiliary pressure sensors are used to control audio filters as well. All user input is used to affect the visual display, which includes turntables, speakers, graphs, and even a Guitar Hero-esque game to guide users through the experience.

### Exhibit 

#### Space

EEGJ was made with Imagine RIT in mind as its one-time-only showcase. The exhibit was placed in a large classroom with plenty of free space and a 10 or 12 foot ceiling. The room got very dark without lights, which suited our projector-powered display. 

#### Hardware and Materials

The whole setup was powered by a team member's desktop computer: 3rd generation i7 processor, 16 GB of RAM, Nvidia GTX 660 graphics card (supports 3 monitors)

#### Sensors



#### Ableton Live Setup



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

import themidibus.*;
import processing.serial.*;
import org.firmata.*;
import cc.arduino.*;
import de.looksgood.ani.*;
import java.util.Map;

/*
*	Instance Vars
*/

// Sketch props
int WIDTH = 3072;
int HEIGHT = 768;
int WIDGET_HEIGHT = 40;
boolean playing;
boolean DEBUG = false;
int FRAME_RATE = 30;

// Colors
color neutralColor = color(255,220,46);
color relaxColor = color(16,255,160);
color veryRelaxColor = color(13,255,234);
color focusColor = color(240,133,46);
color veryFocusColor = color(155,34,184);
color otherColor = color(133,0,192);

// MidiBus + instruments
MidiBus mb;
int channel1, channel2, channel3, channel4, channel5, channel6;
RiriSequence kick, perc1, perc2, bass, synth1, synth2;

// Data + levels
int HISTORY_LENGTH = 8;
int BASE_LEVEL_STEP = 4;
int MAX_FOCUS = 100;
int MAX_RELAX = -100;
int MAX_BPM = 100;
int MIN_BPM = 50;
int pulse, bpm, grain;
int focusRelaxLevel, level;
//IntList pulseHist, levelHist;
IntList levelHist;

// Timekeeping
int BEATS_PER_MEASURE = 4;
int MEASURES_PER_PHASE = 8;
int PHASES_PER_SONG = 4;
int DELAY_THRESHOLD = 100;
int beat, measure, phase, mils, lastMils, delay, delayA, delayB;

// Music + scales
int SCORE_EASING_STEPS = 5;
int score_easing = SCORE_EASING_STEPS;
int score_effect_val = 0;
int PITCH_C = 60;
int PITCH_F = 65;
int PITCH_G = 67;
int[] SCALE = {0, 3, 5, 7, 8};
float[] BEATS = {1, .5, .25, .125};
int pitch;

// Filters
int highPassFilterVal, lowPassFilterVal;

// MindFlex (Serial)
//int MINDFLEX_PORT = 0;
String MINDFLEX_PORT = "COM3";
int START_PACKET = 3;
int LEVEL_STEP = 4;
Serial mindFlex;
PrintWriter output;
int packetCount, globalMax;

// DataGen - Tom
HashMap<String,Integer> inputSettings;
DataGenerator dummyDataGenerator;
boolean useDummyData;

// Brain Level Graphs - Ben
RiriGraph relaxGraph, focusGraph;
PImage relaxGraphBG, focusGraphBG;

// Speakers - Brennan
RiriSpeaker relaxSpeaker1, relaxSpeaker2, focusSpeaker1, focusSpeaker2;
PImage relaxSpeakerBG, focusSpeakerBG;

// Records - Mia
//int RECORD_ARDUINO_PORT = 1;
String RECORD_ARDUINO_PORT = "COM5";
int RELAX_RECORD_PIN = 0;
int FOCUS_RECORD_PIN = 2;
Arduino recordArduino;
boolean recordArduinoOn;
RiriRecord relaxRecord, focusRecord;
float relaxRecordData, focusRecordData;
color relaxRecordColor, focusRecordColor, recordBackgroundColor;

// Widgets - Brennan
String WIDGET_DIR = "widgets/";
int KNOB_SIZE = 120;
int KNOB_Y = 650;
PShape knob_blue, knob_green, knob_orange, knob_pink, knobtrack_white, knobtrack_dark;
PShape brain, dot_green, dot_dark, jellybean_dark, jellybean_pink;
PImage knob_yellow_image;
SVGWidget relaxKnob1, relaxKnob2, relaxKnob3, relaxKnob4, focusKnob1, focusKnob2, focusKnob3, focusKnob4;
SVGWidget brainGood, brainBad, brainWidget;
ImageWidget grainKnob;

// Stage - Tom
ScrollingStage myStage;

/*
*	Sketch Setup
*/

void init() {
	if (DEBUG != true) {
	  	frame.removeNotify();
	 	frame.setUndecorated(true);
	  	frame.addNotify();
	}
	super.init(); 
}

void setup() {
	// Sketch setup
	size(WIDTH, HEIGHT);
	background(0);
	frameRate(FRAME_RATE);
	smooth();
	Ani.init(this);
	playing = false;
	// MidiBus setup
	MidiBus.list();
	mb = new MidiBus(this, -1, "Virtual MIDI Bus");
	mb.sendTimestamps();
	channel1 = 0;
	channel2 = 1;
	channel3 = 2;
	channel4 = 3;
	channel5 = 4;
	channel6 = 5;
	// Data setup
	pulse = 80;
	bpm = pulse;
	//pulseHist = new IntList();
	focusRelaxLevel = 0;
	level = 0;
	levelHist = new IntList();
	grain = 0;
	// Time setup
	delay = 0;
	mils = millis();
	lastMils = mils;
	beat = 0; 
	measure = 0;
	phase = 1;
	// Filter setup
	highPassFilterVal = 0;
	lowPassFilterVal = 127;
	// DataGen setup
	inputSettings = new HashMap<String,Integer>();
	useDummyData = false;
	// MindFlex setup
	packetCount = 0;
	globalMax = 0;
	println("Serial:");
	for (int i = 0; i < Serial.list().length; i++) {
	    println("[" + i + "] " + Serial.list()[i]);
	}
	try {
		//mindFlex = new Serial(this, Serial.list()[MINDFLEX_PORT], 9600);
		mindFlex = new Serial(this, MINDFLEX_PORT, 9600);
		mindFlex.bufferUntil(10);
		String date = day() + "_" + month() + "_" + year();
  		String time = "" + hour() + minute() + second();
		output = createWriter("brain_data/brain_data_out_"+date+"_"+time+".txt");
	}
	catch (Exception e) {
		println("MindFlex Serial Exception: " + e.getMessage());
		useDummyData = true;
	}
	// Stage
	myStage = new ScrollingStage(WIDTH/2, KNOB_Y/2, WIDTH/3, HEIGHT);
	//thread("drawStageStuff");
	// Graph setup
  	relaxGraphBG = loadImage("relax_gradient2.png");
  	focusGraphBG = loadImage("focus_gradient2.png");
  	relaxGraph = new RiriGraph(4*(WIDTH/6), 0, WIDTH/6, HEIGHT/2, relaxGraphBG, 0);
  	focusGraph = new RiriGraph(WIDTH/6, 0, WIDTH/6, HEIGHT/2, focusGraphBG, 1);
  	// Speaker setup
  	relaxSpeakerBG = loadImage("relax_radial.png");
  	focusSpeakerBG = loadImage("focus_radial.png");
  	relaxSpeaker1 = new RiriSpeaker(WIDTH - 250 - 120, HEIGHT/4 - 150, 250, 250, relaxSpeakerBG);
  	relaxSpeaker2 = new RiriSpeaker(WIDTH - 350 - 75, 3*(HEIGHT/4) - 200, 350, 350, relaxSpeakerBG);
  	focusSpeaker1 = new RiriSpeaker(120, HEIGHT/4 - 150, 250, 250, focusSpeakerBG);
  	focusSpeaker2 = new RiriSpeaker(75, 3*(HEIGHT/4) - 200, 350, 350, focusSpeakerBG);
  	// Record setup
  	relaxRecordData = 0;
  	focusRecordData = 0;
	try{
		recordArduinoOn = true;
	    //recordArduino = new Arduino(this, Arduino.list()[RECORD_ARDUINO_PORT], 57600); 
	    recordArduino = new Arduino(this, RECORD_ARDUINO_PORT, 57600); 
	}
	catch(Exception e){
		println("Sensor Arduino Exception: "+e.getMessage());
	    recordArduinoOn = false;
	    //useDummyData = true;
	}
	relaxRecord = new RiriRecord(relaxRecordData, recordArduinoOn, 28, HEIGHT/2 - 50, 3*(WIDTH/4) + 25, 3*(HEIGHT/4), true);
	focusRecord = new RiriRecord(focusRecordData, recordArduinoOn, 28, HEIGHT/2 - 50, WIDTH/4 - 25, 3*(HEIGHT/4), false);
	// Initialize DataGen
	inputSettings.put("brainwave", 1000);
	inputSettings.put("pressure", 200);
    dummyDataGenerator = new DataGenerator(inputSettings);
    // Widgets
	knobtrack_white = loadShape(WIDGET_DIR+"knobtrack_white.svg");
	knobtrack_dark = loadShape(WIDGET_DIR+"knobtrack_dark.svg");
	knob_yellow_image = loadImage(WIDGET_DIR+"knob_yellow2.png");
	knob_blue = loadShape(WIDGET_DIR+"knob_blue.svg");
	knob_green = loadShape(WIDGET_DIR+"knob_green.svg");
	knob_orange = loadShape(WIDGET_DIR+"knob_orange.svg");
	knob_pink = loadShape(WIDGET_DIR+"knob_pink.svg");
	brain = loadShape(WIDGET_DIR+"brain.svg");
	dot_green = loadShape(WIDGET_DIR+"dot_green.svg");
	dot_dark = loadShape(WIDGET_DIR+"dot_dark.svg");
	jellybean_pink = loadShape(WIDGET_DIR+"jellybean_pink.svg");
	jellybean_dark = loadShape(WIDGET_DIR+"jellybean_dark.svg");
	relaxKnob1 = new SVGWidget(16*(WIDTH/30) + 10, KNOB_Y, KNOB_SIZE, KNOB_SIZE, knob_green);
	relaxKnob2 = new SVGWidget(17*(WIDTH/30) + 10, KNOB_Y, KNOB_SIZE, KNOB_SIZE, knob_green);
	relaxKnob3 = new SVGWidget(18*(WIDTH/30) + 10, KNOB_Y, KNOB_SIZE, KNOB_SIZE, knob_blue);
	relaxKnob4 = new SVGWidget(19*(WIDTH/30) + 10, KNOB_Y, KNOB_SIZE, KNOB_SIZE, knob_blue);
	focusKnob1 = new SVGWidget(10*(WIDTH/30) - 10, KNOB_Y, KNOB_SIZE, KNOB_SIZE, knob_pink);
	focusKnob2 = new SVGWidget(11*(WIDTH/30) - 10, KNOB_Y, KNOB_SIZE, KNOB_SIZE, knob_pink);
	focusKnob3 = new SVGWidget(12*(WIDTH/30) - 10, KNOB_Y, KNOB_SIZE, KNOB_SIZE, knob_orange);
	focusKnob4 = new SVGWidget(13*(WIDTH/30) - 10, KNOB_Y, KNOB_SIZE, KNOB_SIZE, knob_orange);
	grainKnob = new ImageWidget(14*(WIDTH/30) + 5, KNOB_Y + 20, KNOB_SIZE - 30, KNOB_SIZE - 30, knob_yellow_image);
	relaxKnob1.rotation(-90);
	relaxKnob2.rotation(-90);
	relaxKnob3.rotation(-90);
	relaxKnob4.rotation(-90);
	focusKnob1.rotation(-90);
	focusKnob2.rotation(-90);
	focusKnob3.rotation(-90);
	focusKnob4.rotation(-90);
	grainKnob.rotation(-90);
	brainWidget = new SVGWidget(15*(WIDTH/30) + 15, KNOB_Y, KNOB_SIZE, KNOB_SIZE, brain);
	brainGood = new SVGWidget(15*(WIDTH/30) - KNOB_SIZE/2 + 20, KNOB_Y - KNOB_SIZE/5, KNOB_SIZE, KNOB_SIZE, dot_green);
	brainBad = new SVGWidget(15*(WIDTH/30) - KNOB_SIZE/2 + 20, KNOB_Y + KNOB_SIZE/8, KNOB_SIZE, KNOB_SIZE, jellybean_dark);
}

/*
*	Draw Loop
*/

void draw() {
	delayA = millis();
	if (frameCount == 1 && DEBUG != true) {
	    frame.setLocation(0,0); 
	}
	background(0);
  	// Draw the stage
  	myStage.update();
  	myStage.draw();
  	// Stage
  	if (!DEBUG) {
	  	fill(0);
	  	noStroke();
	  	rect(0, 0, WIDTH/3, HEIGHT);
	  	rect(2*(WIDTH/3), 0, WIDTH/3, HEIGHT);
  	}
  	if (myStage.doneLoading) {
  		// Graphs
	  	relaxGraph.draw();
	  	focusGraph.draw();
	  	// Speakers
	  	relaxSpeaker1.draw();
	  	relaxSpeaker2.draw();
	  	focusSpeaker1.draw();
	  	focusSpeaker2.draw();
	  	// Records
		if (recordArduinoOn) {
		    relaxRecordData = recordArduino.analogRead(RELAX_RECORD_PIN);
		    focusRecordData = recordArduino.analogRead(FOCUS_RECORD_PIN); 
		}
		else {
		    relaxRecordData = (Float.parseFloat(dummyDataGenerator.getInput("pressure")));
		    focusRecordData = (Float.parseFloat(dummyDataGenerator.getInput("pressure"))); 
		}
		relaxRecord.dataValue = relaxRecordData;
	 	focusRecord.dataValue = focusRecordData;
		relaxRecord.draw();
		focusRecord.draw();
		if (!recordArduinoOn) {
			noStroke();
			fill(otherColor);
		    ellipse(relaxRecord.xPos - relaxRecord.recordWidth/2, relaxRecord.yPos - relaxRecord.recordHeight/2, 20, 20);
		    ellipse(focusRecord.xPos + focusRecord.recordWidth/2, focusRecord.yPos + focusRecord.recordHeight/2, 20, 20);
		}
		// Widgets
		for (int i = 0; i < 4; i++) {
			shape(knobtrack_dark, (16+i)*(WIDTH/30) + 10, KNOB_Y, KNOB_SIZE, KNOB_SIZE);
		}
		relaxKnob1.draw();
		relaxKnob2.draw();
		relaxKnob3.draw();
		relaxKnob4.draw();
		for (int i = 0; i < 4; i++) {
			shape(knobtrack_dark, (10+i)*(WIDTH/30) - 10, KNOB_Y, KNOB_SIZE, KNOB_SIZE);
		}
		focusKnob1.draw();
		focusKnob2.draw();
		focusKnob3.draw();
		focusKnob4.draw();
		shape(knobtrack_white, 14*(WIDTH/30) - 20, KNOB_Y - 5, KNOB_SIZE + 20, KNOB_SIZE + 20);
		grainKnob.draw();
		brainWidget.draw();
		if (useDummyData) {
			brainGood.setShape(dot_dark);
			brainBad.setShape(jellybean_pink);
		}
		else {
			brainGood.setShape(dot_green);
			brainBad.setShape(jellybean_dark);
		}
		brainGood.draw();
		brainBad.draw();
  	}
	delayB = millis();
	// Music
	if (playing) {
		// Music
		playMusic(delayB - delayA);
		// Filters
		if (recordArduinoOn) {
			highPassFilterVal = (int) map(relaxRecordData, 0, 1023, 127, 0);
			lowPassFilterVal = (int) map(focusRecordData, 0, 1023, 127, 0); 
		}
		RiriMessage highPassFilterMsg = new RiriMessage(176, 0, 102, highPassFilterVal);
    	highPassFilterMsg.send();
    	RiriMessage lowPassFilterMsg = new RiriMessage(176, 0, 103, lowPassFilterVal);
    	lowPassFilterMsg.send();
    	// Score effect
    	if (score_easing < SCORE_EASING_STEPS) {
    		score_effect_val += (120 / SCORE_EASING_STEPS);
    		score_easing++;
    	}
    	else {
    		score_effect_val -= 2;
    		if (score_effect_val < 0) {
    			score_effect_val = 0;
    		}
    	}
    	RiriMessage effectMsg = new RiriMessage(176, 0, 106, score_effect_val);
    	effectMsg.send();
	}
	// DEBUG
	if (DEBUG) {
		textAlign(LEFT);
		textSize(10);
		noStroke();
		fill(0, 0, 0, 125);
		rect(0, 0, WIDTH/6, HEIGHT/5);
		fill(255);
		text("focusRelaxLevel: " + focusRelaxLevel, 0, 20);
		text("level: " + level, 0, 40);
		text("grain: " + grain, 0, 60);
		text("pulse: " + pulse, 0, 80);
		text("bpm: " + bpm, 0, 100);
		text("useDummyData: " + useDummyData, 0, 120);
		text("recordArduinoOn: " + recordArduinoOn, 0, 140);
		text("beat: " + beat, 200, 20);
		text("measure: " + measure, 200, 40);
		text("phase: " + phase, 200, 60);
		text("highPass: "+highPassFilterVal, 200, 100);
		text("lowPass: "+lowPassFilterVal, 200, 120);
		noFill();
		stroke(255, 0, 0);
		strokeWeight(3);
		rect(0, 0, WIDTH/3, HEIGHT);
		rect(WIDTH/3, 0, WIDTH/3, HEIGHT);
		rect(2*(WIDTH/3), 0, WIDTH/3, HEIGHT);
		noStroke();
	}
}

/*
*	Music Playing
*/

void startEEGJ() {
	if (myStage.doneLoading) {
		playing = true;
		RiriMessage msg = new RiriMessage(176, 0, 104, 127);
	    msg.send();
		setupMusic();
		startMusic();
	}
}

void stopEEGJ() {
	if (myStage.doneLoading) {
		myStage.setActiveHitzone(0);
		myStage.activeNote = 0;
		relaxKnob1.rotation(-90);
		relaxKnob2.rotation(-90);
		relaxKnob3.rotation(-90);
		relaxKnob4.rotation(-90);
		focusKnob1.rotation(-90);
		focusKnob2.rotation(-90);
		focusKnob3.rotation(-90);
		focusKnob4.rotation(-90);
		grainKnob.rotation(-90);
		stopMusic();
		//RiriMessage msg = new RiriMessage(176, 0, 105, 127); 
		RiriMessage msg = new RiriMessage(176, 0, 104, 0); 
	    msg.send();
	    RiriMessage msg2 = new RiriMessage(176, 0, 106, 0);
		msg2.send();
		playing = false;
	}
}

void setupMusic() {
	// Reset song position
	beat = 0;
	measure = 0;
	phase = 1;
	pitch = PITCH_C;
	// Setup the instruments
	createInstruments();
	createKickMeasure();
	createRestMeasure(perc1);
	createRestMeasure(perc2);
	createRestMeasure(bass);
	createRestMeasure(synth1);
	createRestMeasure(synth2);
}

void startMusic() {
	kick.start();
	perc1.start();
	perc2.start();
	bass.start();
	synth1.start();
	synth2.start();
}

void playMusic(int drawDelay) {
	// Get current time
	mils = millis();
	// Beat Change
	if (mils > lastMils + beatsToNanos(1)/1000 - delay - drawDelay) {
		int milsA = mils;
		// Update values
		updateLevelHistory();
		//updateBpmHistory();
		// Update graphs and speakers
		if (level <= 0) {
			relaxGraph.setMarkerX((int) map(level, 0, -100, 0, relaxGraph.graphWidth));
			relaxSpeaker1.setSpeakerSize((int) map(level, 0, -100, 0, relaxSpeaker1.graphWidth/1.1));
			relaxSpeaker2.setSpeakerSize((int) map(level, 0, -100, 0, relaxSpeaker2.graphWidth/1.1));
		}
		else if (level >= 0) {
			focusGraph.setMarkerX((int) map(level, 0, 100, 0, focusGraph.graphWidth));
			focusSpeaker1.setSpeakerSize((int) map(level, 0, 100, 0, focusSpeaker1.graphWidth/1.1));
			focusSpeaker2.setSpeakerSize((int) map(level, 0, 100, 0, focusSpeaker2.graphWidth/1.1));
		}
		// Update the Active Hit Zone
		if (level >= 60) {
			myStage.setActiveHitzone(1);
		}
		else if (level < 60 && level >= 20) {
			myStage.setActiveHitzone(2);
		}
		else if (level < 20 && level >= -20) {
			myStage.setActiveHitzone(3);
		}
		else if (level < -20 && level > -60) {
			myStage.setActiveHitzone(4);
		}
		else {
			myStage.setActiveHitzone(5);
		}
		// Game stuff
		if (myStage.activeNote == 0) {
			int notePos = 0;
			if (myStage.activeHitzone == 5) {
				notePos = myStage.activeHitzone + round(random(-1, 0));
			}
			else if (myStage.activeHitzone == 1) {
				notePos = myStage.activeHitzone + round(random(0, 1));
			}
			else {
				notePos = myStage.activeHitzone + round(random(-1, 1));
			}
			myStage.spawnNote(notePos);
		}
		else {
			myStage.incrementNote(1);
		}
		// Music stuff
		if (beat == BEATS_PER_MEASURE) {
			beat = 1;
			// Measure Change
			if (measure == MEASURES_PER_PHASE) {
				measure = 1;
				if (phase == PHASES_PER_SONG) {
					// We're done!
					stopEEGJ();
				}
				else {
					phase++;
				}
			}
			else if (measure == MEASURES_PER_PHASE - 1) {
				// Prepare for the next phase
				setPhaseKey();
				measure++;
			}
			else {
				measure++;
			}
		}
		else if (beat == BEATS_PER_MEASURE - 1) {
			// Prepare the next measure
			setMeasureLevelAndGrain();
			setMeasureBPM();
			if (measure == MEASURES_PER_PHASE) {
				resetInstruments();
			}
			createMeasure();
			if (useDummyData) {
				String input = dummyDataGenerator.getInput("brainwave");
				calculateFocusRelaxLevel(input);
			}
			beat++;
		}
		else {
			beat++;
		}
		// Update the time
		lastMils = millis();
		int milsB = millis();
		//println("\tB: "+milsB);
		delay += milsB - milsA;
		//delay = milsB - milsA;
		println("DELAY: "+delay);
		if (delay > DELAY_THRESHOLD) delay = 10;
	}
}

void stopMusic() {
	// Stop all instruments
	kick.quit();
	perc1.quit();
	perc2.quit();
	bass.quit();
	synth1.quit();
	synth2.quit();
}

/*
*	Instruments
*/

void createInstruments() {
	kick = new RiriSequence(channel1);
	perc1 = new RiriSequence(channel2);
	perc2 = new RiriSequence(channel3);
	bass = new RiriSequence(channel4);
	synth1 = new RiriSequence(channel5);
	synth2 = new RiriSequence(channel6);
}

void resetInstruments() {
	stopMusic();
	createInstruments();
	kick.addRest(beatsToNanos(1));
	perc1.addRest(beatsToNanos(1));
	perc2.addRest(beatsToNanos(1));
	bass.addRest(beatsToNanos(1));
	synth1.addRest(beatsToNanos(1));
	synth2.addRest(beatsToNanos(1));
	startMusic();
}

void createMeasure() {
	createKickMeasure();
	createPerc1Measure();
	createPerc2Measure();
	createBassMeasure();
	createSynth1Measure();
	createSynth2Measure();
}

void createRestMeasure(RiriSequence seq) {
	seq.addRest(beatsToNanos(BEATS_PER_MEASURE));
}

void createKickMeasure() { // Bass drum
	// Play a repeated riff
	kick.addNote(36, 120, beatsToNanos(.5));
	kick.addNote(36, 120, beatsToNanos(.5));
	kick.addRest(beatsToNanos(.5));
	kick.addNote(36, 120, beatsToNanos(.5));
	kick.addRest(beatsToNanos(.5));
	kick.addNote(36, 120, beatsToNanos(.5));
	kick.addNote(36, 120, beatsToNanos(.25));
	kick.addNote(36, 120, beatsToNanos(.75));
}

void createPerc1Measure() { // Clap & Hi-hat
	int close = 42;
	int open = 46;
	int clap = 39;
	// Only play if focus is active
	if (level >= 0) {
		// Grain 1 = clap every other beat
		if (grain == 1) {
			perc1.addRest(beatsToNanos(1));
			perc1.addNote(clap, 120, beatsToNanos(1));
			perc1.addRest(beatsToNanos(1));
			perc1.addNote(clap, 120, beatsToNanos(1));
		}
		// Grain 2 = 2 claps
		else if (grain == 2) {
			perc1.addRest(beatsToNanos(1));
			perc1.addNote(clap, 120, beatsToNanos(.75));
			perc1.addNote(clap, 120, beatsToNanos(.25));
			perc1.addRest(beatsToNanos(1));
			perc1.addNote(clap, 120, beatsToNanos(.75));
			perc1.addNote(clap, 120, beatsToNanos(.25));
		}
		// Grain 3 = claps and hi-hat
		else if (grain == 3) {
			perc1.addNote(close, 120, beatsToNanos(.25));
			perc1.addNote(close, 80, beatsToNanos(.25));
			perc1.addNote(close, 80, beatsToNanos(.25));
			perc1.addNote(close, 80, beatsToNanos(.25));
			perc1.addNote(clap, 120, beatsToNanos(.25));
			perc1.addNote(close, 80, beatsToNanos(.25));
			perc1.addNote(close, 80, beatsToNanos(.25));
			perc1.addNote(clap, 120, beatsToNanos(.25));
			perc1.addNote(close, 120, beatsToNanos(.25));
			perc1.addNote(close, 80, beatsToNanos(.25));
			perc1.addNote(close, 80, beatsToNanos(.25));
			perc1.addNote(close, 80, beatsToNanos(.25));
			perc1.addNote(clap, 120, beatsToNanos(.25));
			perc1.addNote(close, 80, beatsToNanos(.25));
			perc1.addNote(close, 80, beatsToNanos(.25));
			perc1.addNote(clap, 120, beatsToNanos(.25));
		}
		// Grain 0 = rest
		else {
			createRestMeasure(perc1);
		}
	}
	else {
		createRestMeasure(perc1);
	}
}

void createPerc2Measure() { // Woodblock
	// Always play
	perc2.addRest(beatsToNanos(1));
	perc2.addNote(40, 120, beatsToNanos(1));
	perc2.addRest(beatsToNanos(1));
	perc2.addNote(40, 120, beatsToNanos(1));
}

void createBassMeasure() { // Bass
	// Determine how to play
	int g = (level >= 0) ? grain : 0;
	int velocity = (level >= 0) ? 80 + 10*grain : 80 - 10*grain;
	// Play randomized half-notes
	if (g == 0 || g == 1) {
		// Random notes for now
		for (int i = 0; i < 2; i++) {
			int p1 = pitch + SCALE[(int) random(0, SCALE.length)] - 24;
			bass.addNote(p1, 80, beatsToNanos(2));
		}
	}
	// Play a motif (random notes followed by root pitch)
	else {
		// Random notes for now
		for (int i = 0; i < 2; i++) {
			int p1 = pitch + SCALE[(int) random(0, SCALE.length)] - 24;
			bass.addNote(p1, 80, beatsToNanos(.75));
		}
		bass.addNote(pitch + SCALE[0] - 24, 80, beatsToNanos(2.5));
	}
}

void createSynth1Measure() { // Arp
	// Play if relax is active
	if (level <= 0) {
		// Grain 0 = random quarter notes
		if (grain == 0) {
			float interval = BEATS[grain];
			for (int i = 0; i < BEATS_PER_MEASURE - 1; i++) {
				int p1 = pitch + SCALE[(int) random(0, SCALE.length)];
				synth1.addNote(p1, 80, beatsToNanos(interval));
			}
			synth1.addNote(pitch, 80, beatsToNanos(interval));
		}  
		// Grain 1 = I and V arpeggiation
		else if (grain == 1) {
			float interval = BEATS[grain];
			int[] notes = {SCALE[0], SCALE[3], SCALE[0]+12, SCALE[3]};
			for (int i = 0; i < BEATS_PER_MEASURE/interval; i++) {
				int num = i%notes.length;
				synth1.addNote(pitch + notes[num], 80, beatsToNanos(interval));
			}
		}
		// Grain 2 = I, iii, and V arpeggiation
		else  if (grain == 2) {
			float interval = BEATS[1];
			int[] notes = {SCALE[0], SCALE[1], SCALE[3], SCALE[1], SCALE[3], SCALE[0]+12, SCALE[1]+12, SCALE[0]+12};
			for (int i = 0; i < BEATS_PER_MEASURE/interval; i++) {
				int num = i%notes.length;
				synth1.addNote(pitch + notes[num], 80, beatsToNanos(interval));
			}
		}
		// Grain 3 = I, iii, and V arpeggiation, faster
		else {
			float interval = BEATS[2];
			int[] notes = {SCALE[0], SCALE[1], SCALE[3], SCALE[1], SCALE[3], SCALE[0]+12, SCALE[1]+12, SCALE[0]+12};
			for (int i = 0; i < BEATS_PER_MEASURE/interval; i++) {
				int num = i%notes.length;
				synth1.addNote(pitch + notes[num], 80, beatsToNanos(interval));
			}
		}
	}
	else {
		createRestMeasure(synth1);
	}
}

void createSynth2Measure() { // Pad
	// Determine the interval
	float interval = (level <= 0) ? BEATS[grain] : BEATS[0];
	int velocity = (level <= 0) ? 80 + 10*grain : 80 - 20*grain;
	// Play a number of chords based on the interval
	for (int i = 0; i < (BEATS_PER_MEASURE/interval) / BEATS_PER_MEASURE; i++) {
		int p1 = pitch - 12;
		int p2 = pitch + SCALE[(int) random(1, SCALE.length)] - 12;
		RiriChord c1 = new RiriChord(channel6);
		c1.addNote(p1, velocity, beatsToNanos(interval*BEATS_PER_MEASURE));
		c1.addNote(p2, velocity, beatsToNanos(interval*BEATS_PER_MEASURE));
		synth2.addChord(c1);
	}
}

/*
*	Keyboard Input
*/
void keyPressed() {
	// Play/stop
	if (key == ' ') {
		if (!playing) startEEGJ();
		else stopEEGJ();
	}
	// Focus/relax
	if (keyCode == LEFT) {
		addRelax();
	}
	if (keyCode == RIGHT) {
		addFocus();
	}
	// Pulse
	if (keyCode == UP) {
		pulse += 3;
	}
	if (keyCode == DOWN) {
		pulse -= 3;
	}
	// Filters
	if (key == 'q') {
		highPassFilterVal += 5;
		if (highPassFilterVal > 127) highPassFilterVal = 127;
	}
	if (key == 'a') {
		highPassFilterVal -= 5;
		if (highPassFilterVal < 0) highPassFilterVal = 0;
	}
	if (key == 'w') {
		lowPassFilterVal += 5;
		if (lowPassFilterVal > 127) lowPassFilterVal = 127;
	}
	if (key == 's') {
		lowPassFilterVal -= 5;
		if (lowPassFilterVal < 0) lowPassFilterVal = 0;
	}
	// MIDI control setup
	if (key == 'z') { //  High Pass
		RiriMessage msg = new RiriMessage(176, 0, 102, 0);
    	msg.send();
	}
	if (key == 'x') { // Low Pass
		RiriMessage msg = new RiriMessage(176, 0, 103, 127);
    	msg.send();
	}
	if (key == 'c') { // Record
		RiriMessage msg = new RiriMessage(176, 0, 104, 0);
    	msg.send();
	}
	if (key == 'v') { // Stop
		RiriMessage msg = new RiriMessage(176, 0, 105, 0); 
    	msg.send();
	}
	if (key == 'b') { // Score Effect
		RiriMessage msg = new RiriMessage(176, 0, 106, 0);
		msg.send();
	}
	// DEBUG
	if (key == '0') {
		println("1/4: "+beatsToNanos(1));
		println("1/8: "+beatsToNanos(.5));
		println("1/16: "+beatsToNanos(.25));
		println("1/32: "+beatsToNanos(.125));
	}
}

/*
*	Utilities
*/

int beatsToNanos(float BEATS){
  // (one second split into single BEATS) * # needed
  float convertedNumber = (60000000 / bpm) * BEATS;
  return round(convertedNumber);
}

float grainToBeat() {
	return BEATS[grain];
}

float grainToMils() {
	return beatsToNanos(grainToBeat());
}

void addFocus() {
	focusRelaxLevel += (BASE_LEVEL_STEP - grain);
	if (focusRelaxLevel > MAX_FOCUS) focusRelaxLevel = MAX_FOCUS;
}

void addRelax() {
	focusRelaxLevel -= (BASE_LEVEL_STEP - grain);
	if (focusRelaxLevel < MAX_RELAX) focusRelaxLevel = MAX_RELAX;
}

void updateLevelHistory() {
	if (levelHist.size() == 4) {
		levelHist.remove(0);
	}
	levelHist.append(focusRelaxLevel);
}

/*
void updateBpmHistory() {
	if (pulseHist.size() == 4) {
		pulseHist.remove(0);
	}
	pulseHist.append(pulse);
}

void setMeasureBPM() {
	// Get the average BPM
	float val = 0; 
	for (int i = 0; i < pulseHist.size(); i++) {
		val += pulseHist.get(i);
	}
	val = val/pulseHist.size();
	bpm = (int) val;
}
*/

void setMeasureBPM() {
	if (level < -20) {
		bpm = (int) map(level, -20, -100, 80, 65);
	}
	else if (level > 20) {
		bpm = (int) map(level, 20, 100, 80, 95);
	}
	else {
		bpm = 80;
	}
}

void setMeasureLevelAndGrain() {
	// Get the average focusRelaxLevel
	float val = 0;
	for (int i = 0; i < levelHist.size(); i++) {
		val += levelHist.get(i);
	}
	val = val/levelHist.size();
	// Set level
	level = (int) val;
	// Set grain
	val = abs(val);
	if (val < 20) {
		grain = 0;
	}
	else if (val >= 20 && val < 50) {
		grain = 1;
	}
	else if (val >= 50 && val < 80) {
		grain = 2;
	}
	else if (val >= 80) {
		grain = 3;
	}
	else {
		grain = 0; // Iunno
	}
	grainKnob.rotation((int) map(grain, 0, 3, -90, 90));
}

void setPhaseKey() {
	int p = phase + 1;
	if (p == PHASES_PER_SONG - 2) {
		pitch = PITCH_F;
	}
	else if (p == PHASES_PER_SONG - 1) {
		pitch = PITCH_G;
	}
	else {
		pitch = PITCH_C;
	}
}

/*
*	MindFlex serial event
*/

void serialEvent(Serial p) {
	// Read in the data
	String input;
	try {
		input = p.readString().trim();
		//print("Received string over serial: ");
		//println(input);
		output.println(input);
	}
	catch (Exception e) {
		input = dummyDataGenerator.getInput("brainwave");
		useDummyData = true;
	}
	calculateFocusRelaxLevel(input);
}

void calculateFocusRelaxLevel(String input) {
	// Parse the data
	boolean goodRead = false;
	if (input.indexOf("ERROR:") != -1 || input.length() == 0) {
		//println("bad");
		goodRead = false;
	}
	else {
		//println("good");
		goodRead = true;
	}
	if (goodRead) {
		String[] brainData = input.split(",");
		int[] intData = new int[brainData.length];
		if (brainData.length > 8) {
			packetCount++;
			if (packetCount > START_PACKET) {
				for (int i = 0; i < brainData.length; i++) {
					String strVal = brainData[i].trim();
					int intVal = Integer.parseInt(strVal);
					// 0 THE DATA WHEN SIGNAL SUCKS
					if ((Integer.parseInt(brainData[0]) == 200) && (i > 2)) {
			          	intVal = 0;
			        }
			        intData[i] = intVal;
				}
			}
		}

		// Format the data
		int connection = intData[0];
		println("CONNECTION: "+connection);
		int min = -1; 
		int max = -1;
		for (int i = 3; i < intData.length; i++) {
			if (max < 0 || intData[i] > max) {
				max = intData[i];
				if (max > globalMax) {
					globalMax = max;
				}
			}
			if (min < 0 || intData[i] < min) {
				min = intData[i];
			}
		}
		//println("MIN " + min + " MAX " + max);

		// Rotate the knobs
		/*relaxKnob1.rotation((int) map(intData[3], min, max, -90, 90));
		relaxKnob2.rotation((int) map(intData[4], min, max, -90, 90));
		relaxKnob3.rotation((int) map(intData[5], min, max, -90, 90));
		relaxKnob4.rotation((int) map(intData[6], min, max, -90, 90));
		focusKnob4.rotation((int) map(intData[7], min, max, -90, 90));
		focusKnob3.rotation((int) map(intData[8], min, max, -90, 90));
		focusKnob2.rotation((int) map(intData[9], min, max, -90, 90));
		focusKnob1.rotation((int) map(intData[10], min, max, -90, 90));*/
		if (playing) {
			relaxKnob1.rotation((int) map(intData[3], 0, globalMax, -90, 90));
			relaxKnob2.rotation((int) map(intData[4], 0, globalMax, -90, 90));
			relaxKnob3.rotation((int) map(intData[5], 0, globalMax, -90, 90));
			relaxKnob4.rotation((int) map(intData[6], 0, globalMax, -90, 90));
			focusKnob4.rotation((int) map(intData[7], 0, globalMax, -90, 90));
			focusKnob3.rotation((int) map(intData[8], 0, globalMax, -90, 90));
			focusKnob2.rotation((int) map(intData[9], 0, globalMax, -90, 90));
			focusKnob1.rotation((int) map(intData[10], 0, globalMax, -90, 90));
		}

		// Interpret the data
		int[] tmp = new int[intData.length - 3];
		for (int i = 3; i < intData.length; i++) {
			//tmp[i-3] = (int) map(intData[i], min, max, 0, 100);
			tmp[i-3] = (int) map(intData[i], 0, globalMax, 0, 100);
		}
		int focusVal = 0;
		int relaxVal = 0;
		float newLevel = 0;
		for (int i = 1; i < tmp.length; i++) {
			if (i < tmp.length/2) {
				relaxVal += tmp[i];
			}
			else {
				focusVal += tmp[i];
			}
		}
		focusVal = (int) (focusVal / 4);
		relaxVal = (int) (relaxVal / 3);


		// Set the brain level
		newLevel = focusVal - relaxVal;
		// METHOD 1: Set focusRelaxLevel to the difference of focus and relax
		// focusRelaxLevel = (int) newLevel;
		// METHOD 2: Adjust focusRelaxLevel based on a fraction of the difference of focus and relax
		//focusRelaxLevel += (int) (newLevel / 4);
		//focusRelaxLevel += (int) newLevel;
		// METHOD 3: Adjust focusRelaxLevel based on "direction" of mental activity
		// and adjust by the current grain
		if (newLevel >= 0) {
			focusRelaxLevel += (focusRelaxLevel >= 0) ? (LEVEL_STEP - grain) : LEVEL_STEP;
		}
		else if (newLevel <= -1) {
			focusRelaxLevel -= (focusRelaxLevel < 0) ? (LEVEL_STEP - grain) : LEVEL_STEP;
		}
		if (focusRelaxLevel > MAX_FOCUS) {
			focusRelaxLevel = MAX_FOCUS;
		}
		else if (focusRelaxLevel < MAX_RELAX) {
			focusRelaxLevel = MAX_RELAX;
		}
		//newLevel = map(focusVal - relaxVal, 0, 100, -100, 100);
		//println("NEW LEVEL: "+newLevel);
		println("FOCUS: "+focusVal+", RELAX: "+relaxVal+", NEW LEVEL: "+newLevel);
	}
	else {
		// Do something
	}
}

void drawStageStuff() {
	while (true) {
		myStage.update();
		myStage.draw();
		delay(1000/FRAME_RATE);
	}
}
import themidibus.*;
import processing.serial.*;
import org.firmata.*;
import cc.arduino.*;
import java.util.Map;

/*
*	Instance Vars
*/

// Sketch props
int WIDTH = 1024;
int HEIGHT = 768;
boolean playing;

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
IntList pulseHist, levelHist;

// Timekeeping
int BEATS_PER_MEASURE = 4;
int MEASURES_PER_PHASE = 8;
int PHASES_PER_SONG = 4;
int DELAY_THRESHOLD = 20;
int beat, measure, phase, mils, lastMils, delay;

// Music + scales
int PITCH_C = 60;
int PITCH_F = 65;
int PITCH_G = 67;
int[] SCALE = {0, 3, 5, 7, 8};
float[] BEATS = {1, .5, .25, .125};
int pitch;

// Filters
int highPassFilterVal, lowPassFilterVal;

// MindFlex (Serial)
int MINDFLEX_PORT = 0;
int START_PACKET = 3;
int LEVEL_STEP = 4;
Serial mindFlex;
PrintWriter output;
int packetCount, globalMax;

// DataGen 
HashMap<String,Integer> inputSettings;
DataGenerator dummyDataGenerator;
boolean useDummyData;

/*
*	Sketch Setup
*/

void setup() {
	// Sketch setup
	size(WIDTH, HEIGHT);
	background(0);
	frameRate(60);
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
	pulseHist = new IntList();
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
	// MindFlex setup
	packetCount = 0;
	globalMax = 0;
	println("Serial:");
	for (int i = 0; i < Serial.list().length; i++) {
	    println("[" + i + "] " + Serial.list()[i]);
	}
	try {
		mindFlex = new Serial(this, Serial.list()[MINDFLEX_PORT], 9600);
		mindFlex.bufferUntil(10);
		String date = day() + "_" + month() + "_" + year();
  		String time = "" + hour() + minute() + second();
		output = createWriter("brain_data/brain_data_out_"+date+"_"+time+".txt");
	}
	catch (Exception e) {
		useDummyData = true;
	}
	// DataGen setup
	inputSettings = new HashMap<String,Integer>();
	useDummyData = false;
}

/*
*	Draw Loop
*/

void draw() {
	background(0);
	if (playing) {
		// Music
		playMusic();
		// Filters
		RiriMessage highPassFilterMsg = new RiriMessage(176, 0, 102, highPassFilterVal);
    	highPassFilterMsg.send();
    	RiriMessage lowPassFilterMsg = new RiriMessage(176, 0, 103, lowPassFilterVal);
    	lowPassFilterMsg.send();
	}
	// DEBUG
	text("focusRelaxLevel: " + focusRelaxLevel, 0, 20);
	text("level: " + level, 0, 40);
	text("grain: " + grain, 0, 60);
	text("pulse: " + pulse, 0, 80);
	text("bpm: " + bpm, 0, 100);
	text("useDummyData: " + useDummyData, 0, 120);
	text("beat: " + beat, WIDTH/2, 20);
	text("measure: " + measure, WIDTH/2, 40);
	text("phase: " + phase, WIDTH/2, 60);
	text("highPass: "+highPassFilterVal, WIDTH/2, 100);
	text("lowPass: "+lowPassFilterVal, WIDTH/2, 120);
}

/*
*	Music Playing
*/

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
	// Start all instruments
	startMusic();
}

void startMusic() {
	kick.start();
	perc1.start();
	perc2.start();
	bass.start();
	synth1.start();
	synth2.start();
}

void playMusic() {
	// Get current time
	mils = millis();
	// Beat Change
	if (mils > lastMils + beatsToNanos(1)/1000 - delay) {
		int milsA = mils;
		//println("\tA: "+milsA);
		updateLevelHistory();
		updateBpmHistory();
		if (beat == BEATS_PER_MEASURE) {
			beat = 1;
			// Measure Change
			if (measure == MEASURES_PER_PHASE) {
				measure = 1;
				if (phase == PHASES_PER_SONG) {
					// We're done!
					stopMusic();
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
		println("DELAY: "+delay);
		if (delay > DELAY_THRESHOLD) delay = 0;
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
		playing = !playing;
		if (playing) setupMusic();
		else stopMusic();
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
	// Filter setup
	if (key == 'z') {
		RiriMessage msg = new RiriMessage(176, 0, 102, 0);
    	msg.send();
	}
	if (key == 'x') {
		RiriMessage msg = new RiriMessage(176, 0, 103, 127);
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

		int[] tmp = new int[intData.length - 3];
		for (int i = 3; i < intData.length; i++) {
			//tmp[i-3] = (int) map(intData[i], min, max, 0, 100);
			tmp[i-3] = (int) map(intData[i], 0, globalMax, 0, 100);
		}

		// Interpret the data
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
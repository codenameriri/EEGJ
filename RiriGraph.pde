class RiriGraph {

	// Constants
	private int SETTLE_RATE = 5;
	private int EASING_STEPS = 5;
	private int INTERVAL = 750;
	private int RIGHT = 0;
	private int LEFT = 1;
	private int RECT_OVERLAYS = 8;
	
	// Colors
	public PImage background = null;
	
	// Graph positions and size
	public int xPos, yPos, graphWidth, graphHeight, direction;
	
	// Marker positions
	public int markerX;
	private int oldX, newX;
	
	// Timekeeping
	private int lastMillis, easing;

	public RiriGraph() {
		background(0);
		// Variable initialization
		background = null;
		xPos = 0;
		yPos = 0;
		graphWidth = 0;
		graphHeight = 0;
		markerX = 0;
		oldX = 0;
		newX = 0;
		lastMillis = 0;
		easing = EASING_STEPS;
		direction = RIGHT;
	}

	public RiriGraph(int aX, int aY, int aW, int aH, PImage bgFile, int aD) {
		background(0);
		// Image setup
		background = bgFile;
		xPos = aX;
		yPos = aY;
		graphWidth = aW;
		graphHeight = aH;
		markerX = 0;
		oldX = 0;
		newX = 0;
		lastMillis = 0;
		easing = EASING_STEPS;
		direction = (aD == LEFT || aD == RIGHT) ? aD : RIGHT;
	}
	
	public void draw() {
		rectMode(CORNER);
		imageMode(CORNER);
		fill(0,0,0);
		noStroke();
		rect(xPos, yPos, graphWidth, graphHeight);
		// Gradient background
		image(background, xPos, yPos, graphWidth, graphHeight);
		// Determine the value of the graph
		// Rise
		if (easing < EASING_STEPS) {
			markerX += (int) ((newX - oldX) / EASING_STEPS);
			easing++;
		}
		// Settle
		else {
			markerX -= SETTLE_RATE;
			if (markerX < 0) {
				markerX = 0;	
			}	
		}
		// Marker and overlays
		noStroke();
		int rectW = (graphWidth/RECT_OVERLAYS) / 3;
		if (direction == RIGHT) {
			fill(0,0,0);
			rect(xPos + markerX, yPos, graphWidth - markerX, graphHeight);
			for (int i = 1; i < RECT_OVERLAYS; i++) {
				int rectX = (graphWidth/RECT_OVERLAYS) * i;
				fill(0,0,0);
				rect(xPos + rectX - rectW, yPos, rectW, graphHeight);
			}
		}
		else {
			fill(0,0,0);
			rect(xPos, yPos, graphWidth - markerX, graphHeight);
			for (int i = 1; i < RECT_OVERLAYS; i++) {
				int rectX = (graphWidth/RECT_OVERLAYS) * i;
				fill(0,0,0);
				rect(xPos + rectX, yPos, rectW, graphHeight);
			}
		}
	}

	public void setMarkerX(int x) {
		newX = x;
		if (newX > markerX) {
			oldX = markerX;
			easing = 0;	
		}
	}
}
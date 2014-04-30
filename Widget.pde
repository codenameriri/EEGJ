/*
*	Base Widget Class
*/
class Widget {
	// Widget x position, y position, width, and height
	public int xPos, yPos, widgetWidth, widgetHeight;
	// Rotation (in radians)
	protected float rotation = 0;

	// Constructor
	public Widget(int x, int y, int w, int h) {
		xPos = x;
		yPos = y;
		widgetWidth = w;
		widgetHeight = h;
	}

	// Draw
	public void draw() {
		// Override this
	}

	// Set the rotation
	public void rotation(int d) {
		rotation = radians(d);
	}
}

/* Widget using SVGs and PShapes
* Non rotating // Static
*/

class SVGWidget extends Widget {
	// Widget's shape
	private PShape shape;

	// Constructor
	public SVGWidget(int x, int y, int w, int h, PShape s) {
		// Set position and size
		super(x, y, w, h);
		// Set the shape
		shape = s;
	}

	// Draw
	public void draw() {
		// Push matrix to avoid conflicts
		pushMatrix();
		// Set draw modes
		rectMode(CENTER);
		shapeMode(CENTER);
		// Calculate the center
		int centerX = xPos + widgetWidth/2;
		int centerY = yPos + widgetHeight/2;
		// Translate to the center point
		translate(centerX, centerY);
		// Rotate the widget
		rotate(rotation);
		// Draw the widget
		// fill(0);
		// stroke(255);
		// rect(0, 0, widgetWidth, widgetHeight);
		shape(shape, 0, 0, widgetWidth, widgetHeight);
		// Pop matrix to reset
		rectMode(CORNER);
		shapeMode(CORNER);
		popMatrix();
	}

	public void setShape(PShape s) {
		shape = s;
	}
}

/*
*	Widget using PNGs and PImages
*/

class ImageWidget extends Widget {
	// Widget's image
	private PImage image;

	// Constructor
	public ImageWidget(int x, int y, int w, int h, PImage i) {
		// Set position and size
		super(x, y, w, h);
		// Set the image
		image = i;
	}

	// Draw
	public void draw() {
		// Push matrix to avoid conflicts
		pushMatrix();
		// Set draw modes
		rectMode(CENTER);
		imageMode(CENTER);
		// Calculate the center
		int centerX = xPos + widgetWidth/2;
		int centerY = yPos + widgetHeight/2;
		// Translate to the center point
		translate(centerX, centerY);
		// Rotate the widget
		rotate(rotation);
		// Draw the widget
		/*fill(0);
		stroke(255);
		rect(0, 0, widgetWidth, widgetHeight);*/
		image(image, 0, 0, widgetWidth, widgetHeight);
		// Pop matrix to reset
		rectMode(CORNER);
		imageMode(CORNER);
		popMatrix();
	}

	public void setImage(PImage i) {
		image = i;
	}
}

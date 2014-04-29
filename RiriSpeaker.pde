class RiriSpeaker {
  
//Constants
private int INTERVAL =1000;
private int EASING_STEPS = 5;
private int SETTLE_RATE = 4;
private float angle = 0;
private int centerX;
private int centerY;


//Colors
private PImage background = null;

//Graph Positions and size
public int xPos, yPos, graphWidth, graphHeight;

//Marker Positions
public int radius;
private int oldX, newX;

//Timekeeping
private int lastMillis, easing;


public RiriSpeaker()
{
  background(0);
  //Variable initialization
  background = null;
  xPos = 0;
  yPos = 0;
  graphWidth = 0;
  graphHeight = 0;
  lastMillis = 0;
  oldX = 0;
  newX = 0;
  radius = 0;
  easing = EASING_STEPS;


}

public RiriSpeaker(int aX, int aY, int aW, int aH, PImage bgFile)
{
  background(0);
  background = bgFile;
  xPos = aX;
  yPos = aY;
  graphWidth = aW;
  graphHeight = aH;
  lastMillis = 0;
  oldX = 0;
  newX = 0;
  radius = 0;
  easing = EASING_STEPS;
}


public void draw() 
{
  smooth();
  fill(0);
  noStroke();
  // Black background
  rect(xPos, yPos, graphWidth, graphHeight);
  // Calculate the center of the speaker
  centerX = xPos + graphWidth /2;
  centerY = yPos + graphHeight /2;
  // Draw the outer circles
  stroke(255);
  strokeWeight(3);
  fill(0);
  ellipse(centerX, centerY, graphWidth, graphHeight);
  fill(25);
  ellipse(centerX, centerY, graphWidth/1.1, graphHeight/1.1);
  // Draw the speaker "core"
  imageMode(CENTER);
  image(background,centerX, centerY, radius, radius);
  // Draw the other circles
  noFill();
  strokeWeight(1);
  ellipse(centerX, centerY, graphWidth/1.4, graphHeight/1.4);
  ellipse(centerX, centerY, graphWidth/1.6, graphHeight/1.6);
  ellipse(centerX, centerY, graphWidth/1.8, graphHeight/1.8);
  ellipse(centerX, centerY, graphWidth/2, graphHeight/2);
  ellipse(centerX, centerY, graphWidth/2.3, graphHeight/2.3);
  ellipse(centerX, centerY, graphWidth/2.6, graphHeight/2.6);
  ellipse(centerX, centerY, graphWidth/2.9, graphHeight/2.9);
  ellipse(centerX, centerY, graphWidth/3.2, graphHeight/3.2);
  ellipse(centerX, centerY, graphWidth/3.6, graphHeight/3.6);
  ellipse(centerX, centerY, graphWidth/4.2, graphHeight/4.2);
  strokeWeight(3);
  fill(0);
  ellipse(centerX, centerY, graphWidth/5, graphHeight/5);
  // Frills
  fill(255);
  noStroke();
  ellipse(xPos + graphWidth/2, yPos + graphHeight/42, graphWidth/42, graphHeight/42);
  ellipse(xPos + graphWidth/42, yPos + graphHeight/2, graphWidth/42, graphHeight/42);
  ellipse(xPos + graphWidth - graphWidth/42, yPos + graphHeight/2, graphWidth/42, graphHeight/42);
  ellipse(xPos + graphWidth/2, yPos + graphHeight - graphHeight/42, graphWidth/42, graphHeight/42);
  
  //Rise
  if(easing < EASING_STEPS)
  {
    radius += (int) ((newX-oldX)/ EASING_STEPS);
    easing++;
  }
  //Settle
  else
  {
    radius -= SETTLE_RATE;
    if (radius < 0)
    {
      radius = 0; 
    }
  }

 imageMode(CORNER);
}

public void setSpeakerSize(int x) {
  newX = x;
  if(newX > radius)
  {
    easing = 0;
    oldX = radius;
  }
}

}

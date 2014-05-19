class RiriRecord{
  
  float dataValue, minData, maxData;         // Sensors/generated data, and its min/max values 
  Boolean sensorData;                        // If the data is coming from the sensor or not
  int numPts;                                // Number of curveVertex points to create a circle
  float angle;                               // For finding where to place the curveVertex points
  PVector[] points;                          // Stores the scratch wave's points  
  float recordWidth, recordHeight;           // Record's dimentions, the width is proportional to the height
  float xPos, yPos;                          // Record's center
  float minRadius, maxRadius, radius;        // Radius for the scratch wave
  color waveColor, bgColor;                  // Color of the scratch wave, and background 

  color FOCUS_COLOR = color(240,13,252); 
  color RELAX_COLOR = color(17,224,245); 
  color BG_COLOR = color(30);
    
    
  /*-----------------------------------------------------
   *   _dataValue     - the value from the sensor or genrated data  
   *   _sensorData    - true/false if the data is coming from a sensor
   *   _numPts        - the more points the more its going to look jagged 
   *                    use 28 or higher
   *   _recordHeight  - looks better if the height is 225 or higher
   *   _xPos, yPos    - record's position point 
   *   _waveColor     - color(17,224,245) or color(240,13,252)
   *   _bgColor       - the Background color of the main sketch 
  --------------------------------------------------------*/
  public RiriRecord(float _dataValue, boolean _sensorData, int _numPts, float _recordHeight, float _xPos, float _yPos, boolean _type){ 
    dataValue = _dataValue;
    sensorData = _sensorData;   
    
    numPts = _numPts;
    points = new PVector[numPts];
    angle = TWO_PI/numPts;
    
    recordHeight = _recordHeight;
    recordWidth = recordHeight * 1.42;    
    
    minRadius = recordHeight * 0.12; 
    maxRadius = recordHeight * 0.19;
        
    xPos = _xPos;
    yPos = _yPos;
    
    // Set the color for the wave lines, and the background 
    if (_type == true)
      waveColor = RELAX_COLOR;
    else 
      waveColor = FOCUS_COLOR;
    bgColor = BG_COLOR;

    // Set the min/maxData values depending on the data value 
    // coming in if its from a sensor/generated 
    if( !sensorData ){
      minData = 0;
      maxData = 100;
      //println("Fake data");
    }
    else if( sensorData ){
      minData = 0;
      maxData = 1023;
      //println("Sensor Data");  
    }

  }//END Record
  
  
  
  public void draw(){
    smooth();
    pushMatrix();   
    translate(xPos, yPos);
   
    drawDisk(); 
    setPoints();
                
    // For changing the stroke color for the wave
    stroke(waveColor);
    strokeWeight(2); 
    noFill();
    beginShape();
    for(int i = 0; i < numPts; i++){  
      // The first control point and the start point of the curve use the same point
      // therefore we need to repeat the curveVertex() using the same point
      if(i == 0 ){
        curveVertex(points[i].x, points[i].y);
      }
      curveVertex(points[i].x, points[i].y);
      // The last point of curve and the last control point use the same point
      if(i == numPts-1){
        // In this case, the last point will be the same as the starting point b/c it needs to form a circle
        curveVertex(points[0].x, points[0].y);
        curveVertex(points[0].x, points[0].y);
      }
    }
    endShape(CLOSE);
    popMatrix();
    
  }//END draw
  
  
  
  void setPoints(){
    // For each numPts assign a coordinate point, store it in a PVector array
    for(int n = 0; n < numPts; n++){  
      
      // Return a dataValue thats corresponds to the scratch wave's radius range 
      radius = map(dataValue, minData, maxData, minRadius, maxRadius);
      
      // Slightly change the radius of the wave, if dataValue is at some range         
      if(dataValue == 0 ){
        radius += random(1);
      }
      // Range: 0-25%
      if( dataValue > 0 && dataValue < (maxData*0.25) ){ 
        radius += random(1,4);
      }
      // Range: 25-50%
      else if( dataValue > (maxData*0.25) && dataValue < (maxData*0.5) ){ 
        radius += random(4,12);
      }
      // Range: 50-75%
      else if( dataValue > (maxData*0.5) && dataValue < (maxData*0.75) ){ 
        radius += random(12,20);
      }
      // Range: 75-100%
      else if( dataValue > (maxData*0.75) && dataValue <= maxData){
        radius += random(20,32);
      }
      
      // Create points with the new radius and at a diffrent angle     
      float xPt = (radius * 1.45) * cos(angle * n);
      float yPt = radius * sin(angle * n);
      points[n] = new PVector(xPt, yPt);
     }
  
  }// END setPoints
  
  
  
  // Draws the disk in the background
  void drawDisk(){    
    strokeWeight(3);
    stroke(17,224,245);
    // Disk
    fill(17,224,245);
    ellipse(0, (recordHeight * 0.01), recordWidth, recordHeight); 
    fill(0);
    ellipse(0, 0, recordWidth, recordHeight);

    // Inner hole
    noStroke();
    float innerH = recordHeight * 0.05;
    float innerW = recordWidth * 0.05;
    float innerH2 = recordHeight * 0.25;
    float innerW2 = recordWidth * 0.25;
    translate(0, -(innerH*.5)); 
    fill(200);
    ellipse(0, 0, innerW2, innerH2);
    fill(bgColor);   // Has to be the same color as the background  
    ellipse(0, 0, innerW, innerH);
  }//END drawDisk() 
  
}//END Record
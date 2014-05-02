class Feedback{

  float xPos, yPos;        // Text's position
  String type;             // Text's type
  float easing;            // Easing for the Text
  float scale;             // Scaling the text
  float currentAlpha;      // Changing opacity of the Text

  PImage[] textImages = new PImage[7];    // Array to hold all the images
  String[] fileNames = {"RELAX_GURU", "FOCUS_MASTER", "THE_EEGJ", "AWESOME", "CRAZY", "GREAT", "SWEET"};

  PImage image;            // Seleted image from the textImages array
  float imageW, imageH;    // Selected image's size
  int imageIndex;          // Image Text's index

  /*------------------------------------------------------
  *  _type           -  "relax", "focus", "random"
  *  _xPox, _yPos    -  position for placing the Image Text
  --------------------------------------------------------*/
  public Feedback(String _type, float _xPos, float _yPos){
    type = _type;
    xPos = _xPos;
    yPos = _yPos;

    // Store the loaded text images in the PImage array
    for(int i =0; i < fileNames.length; i++){
      textImages[i] = loadImage("textImages/" + fileNames[i] + ".png");
    }

    // Determine the text index according to the type
    if(type.equals("relax")){
      imageIndex = 0;
    }else if(type.equals("focus")){
      imageIndex = 1;
    }else if(type.equals("random")){
      imageIndex = int(random(2,7));
    }
    image = textImages[imageIndex];
    imageW = image.width/8;
    imageH = image.height/8;

    easing = 0.10;
    currentAlpha = 255;
  }

  public void draw(){
    smooth();
    pushMatrix();
    translate(xPos, yPos);

    // for changing the opacity of the text
    float targetAlpha = 0;
    float dA = targetAlpha - currentAlpha;

    // for changing the y position of the text
    float targetY = height/15;
    float dY = targetY - yPos;
    if( yPos < targetY ){
      yPos += dY * easing;

      // for changing the scale of the text
      if(scale < 5){
        scale += easing;
      }
      if( yPos > (targetY * 0.95) ){
        currentAlpha += dA * 0.25;
      }
     }
     tint(255, currentAlpha);
     scale(scale);
     Ani.to(this, 1, "yPos", yPos, Ani.SINE_IN);

     imageMode(CENTER);
     image(image, 0, yPos, imageW, imageH);
     popMatrix();
     tint(255, 255);
  }//END draw()

}

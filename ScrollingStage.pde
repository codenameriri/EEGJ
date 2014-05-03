/*
 * @author      Tom Conroy
 * @version     1.0
 * @since       1.0
 */

class ScrollingStage {

  /*********************
   * Object Properties *
   ********************/

  // Mia's text stuff
  int imageIndex;
  Feedback textFeed;
  boolean showSuccessTxt;

  // CONSTANTS
  final String GRID_DIR       = "grid/";
  final String VIGNETTE_DIR   = "vignette/";
  final String STAGE_DIR      = "stage/";
  final String FOCAL_DIR      = "focal/";
  final String NOTES_DIR      = "notes/";
  final String HITZONE_DIR    = "hitzone/";
  final String MISC_DIR       = "misc/";
  final int BG_Y_PADDING      = -100;
  final int FOCAL_Y_PADDING   = 150;
  final int GRID_Y_PADDING    = -100;
  final int GRID_H_PADDING    = 200;
  final int SEQ_Y_PADDING     = -100;
  final int SEQ_H_PADDING     = 200;
  final int NOTE_FRAME_COUNT  = 9;

  // PUBLIC
  float x;
  float y;
  float w;
  float h;
  int starCount;
  int currentNoteFrame;
  int activeNote;
  int score;
  PImage stageBG;
  PImage focal;
  PImage focusVignette;
  PImage relaxVignette;
  PImage[] hitzoneSequence;
  PImage[] stageSequence;
  PImage[] gridSequence;
  PImage[] col1Sequence;
  PImage[] col2Sequence;
  PImage[] col3Sequence;
  PImage[] col4Sequence;
  PImage[] col5Sequence;
  Star[] starCollection;
  boolean doneLoading;

  // PRIVATE
  private LoaderThread loader;
  private PImage logoImage;
  private PFont gothamBold;
  private PFont gothamThin;
  private int activeHitzone;
  private int stageIndex;
  private int gridIndex;
  private int activeVignette;

  // settings for the 2 vignette
  private int focusVignAlpha;
  private int relaxVignAlpha;
  private int focusAlphaMax;
  private int relaxAlphaMax;


  /*********************
   * Object Constructor *
   ********************/

  ScrollingStage( float xLoc, float yLoc, float imgWidth, float imgHeight ){
    println("class::ScrollingStage insance created.");

    // setup initial stage properties.
    logoImage        = loadImage( MISC_DIR+"logo.png" );
    gothamBold       = createFont("fonts/Gotham-Bold.ttf", 48, false);
    gothamThin       = createFont("fonts/Gotham-Thin.ttf", 48, false);
    loader           = new LoaderThread(this);
    x                = xLoc;
    y                = yLoc;
    w                = imgWidth;
    h                = imgHeight;
    doneLoading      = false;
    showSuccessTxt   = false;
    starCount        = 500; //500;
    currentNoteFrame = -1;
    activeNote       = 0;
    activeHitzone    = 0;
    activeVignette   = 0;
    stageIndex       = 0;
    gridIndex        = 0;
    score            = 0;

    // start the asset loader.
    loader.start();
  }


  /*********************
   * Setup Methods     *
   ********************/

  void finishedLoading( boolean loadedStatus ){
    doneLoading = loadedStatus;
  }

  /*********************
   * Draw Methods      *
   ********************/

  void draw(){
    if( this.doneLoading == false ){
      drawLoadingScreen(); // show loading screen
    }else{
      drawStageElements(); // done loading, draw the stage elements
    }
  } // end draw();

  void drawStageElements(){
    imageMode(CENTER);
    drawStageBackground();
    drawStageStars();
    drawStageForeground();
    drawStageGrid();
    drawStageNotes();
    drawStageHitzone();
    drawStageFocal();
    drawStageVignette();
    imageMode(CORNER);
    if( showSuccessTxt ){
      textFeed.draw();
    }
    drawScoreText();
  }

  void drawLoadingScreen(){
    imageMode(CENTER);
    textAlign(CENTER);
    image( logoImage, this.x , this.y, this.w/2, this.h/2 );
    textFont(gothamBold, 26);
    text("SETTING UP, PLEASE WAIT...", this.x, this.y -this.h/4);
    textFont(gothamBold, 18);
    text( loader.statusText, this.x, this.y + this.h/4 );
    imageMode(CORNER);
  }

  void drawStageBackground(){
    tint(255,230);
    image( stageBG, this.x, this.y+BG_Y_PADDING, this.w, this.h );
    tint(255,255);
  }

  void drawStageStars(){
    for(Star i:starCollection){
      i.draw();
    }
  }

  void drawStageVignette(){
    imageMode(CORNER);
    tint(255, focusVignAlpha);
    image(focusVignette, this.x - this.w/2, 0, this.w, this.h);
    tint(255, relaxVignAlpha); 
    image(relaxVignette, this.x - this.w/2, 0, this.w, this.h);
    tint(255,255);
    imageMode(CENTER);
  }

  void drawStageForeground(){
    image(stageSequence[stageIndex], this.x, this.y, this.w, this.h);
  }

  void drawStageGrid(){
    image(gridSequence[gridIndex],
            this.x, this.y+GRID_Y_PADDING, this.w, this.h+GRID_H_PADDING);
  }

  void drawStageNotes(){
    // draw the active note frame
    float xVal = this.x;
    float yVal = this.y + SEQ_Y_PADDING;
    float wVal = this.w;
    float hVal = this.h + SEQ_H_PADDING;

    switch (activeNote) {
      case 1: image(col1Sequence[currentNoteFrame],xVal,yVal,wVal,hVal); break;
      case 2: image(col2Sequence[currentNoteFrame],xVal,yVal,wVal,hVal); break;
      case 3: image(col3Sequence[currentNoteFrame],xVal,yVal,wVal,hVal); break;
      case 4: image(col4Sequence[currentNoteFrame],xVal,yVal,wVal,hVal); break;
      case 5: image(col5Sequence[currentNoteFrame],xVal,yVal,wVal,hVal); break;
      case 0: default: break;
    }

  } // end drawStageNotes();

  void drawStageHitzone(){
    // draw the hitzone
    if( activeHitzone > 0 ){
      image(hitzoneSequence[activeHitzone-1], this.x, this.y+GRID_Y_PADDING, this.w, this.h+GRID_H_PADDING);
    }
  }

  void drawStageFocal(){
    image(focal, this.x, 100, this.w, this.h);
  }

  void drawScoreText(){
    String scoreStr = String.format("%04d", score);
    textFont(gothamBold, 30);
    textAlign(RIGHT);
    fill(255, 255, 255);
    text("SCORE", this.x + this.w/2-10, 30);
    textAlign(RIGHT);
    textFont(gothamThin, 35);
    text(scoreStr, this.x + this.w/2-10, 60);
  }


  /*********************
   * Update Methods    *
   ********************/

  void update(){
    if( this.doneLoading == true ){
      updateStage();
      updateGrid();
      updateStars();
      updateVignette();
    }
  }

  void updateStars(){
    // update all our stars
    for( Star i:starCollection ){
      i.update();
    }
  }

  void updateStage(){
    // increment stage animation sequence
    if( stageIndex >= stageSequence.length-1 ){
      stageIndex = 0;
    }else{
      stageIndex++;
    }
  }

  void updateGrid(){
    // increment grid animation sequence
    if( gridIndex >= gridSequence.length-1 ){
      gridIndex = 0;
    }else{
      gridIndex++;
    }
  }

  void updateVignette(){
    // calculate the maxAlpha value for each vignette, based on active hitzone.
    switch (activeHitzone) {
      case 1:
        // max focused
        focusAlphaMax = 255;
        relaxAlphaMax = 0;
      break;
      case 2:
        // 80% focused, 20% relaxed
        focusAlphaMax = 204;
        relaxAlphaMax = 51;
      break;
      case 3:
        // 10% focused, 10% relaxed
        focusAlphaMax = 25;
        relaxAlphaMax = 25;
      break;
      case 4:
      // 80% relaxed, 20% focused
        focusAlphaMax = 51;
        relaxAlphaMax = 204;
      break;
      case 5:
        // maxed relaxed
        focusAlphaMax = 0;
        relaxAlphaMax = 255;
      break;
      case 0:
      default:
        focusAlphaMax = 0;
        relaxAlphaMax = 0;
      break;
    }
    // increment vignetteAlpha for each, up or down, depending on active hitzone
    if( focusVignAlpha < focusAlphaMax ){
      focusVignAlpha += 2;
    }else{
      focusVignAlpha -= 4;
    }

    if(relaxVignAlpha < relaxAlphaMax){
      relaxVignAlpha += 4;
    }else{
      relaxVignAlpha -= 6;
    }
  }



  /*********************
   * Note Methods      *
   ********************/

  // spawns a note in colNum (1-5)
  void spawnNote(int colNum){
    activeNote       = colNum;
    currentNoteFrame = 0;
  }

  // increment note animation by numToInc
  void incrementNote( int numToInc ){
    currentNoteFrame += numToInc;
    if( currentNoteFrame > NOTE_FRAME_COUNT){
      calcScore(activeNote);
      terminateNote();
    }
  }

  // disables the active note (kill method)
  void terminateNote(){
    currentNoteFrame = -1;
    activeNote       = 0;
  }

  // called when note reaches end of its column
  void calcScore(int completedNote){
    if( notesMatchHitzone() ){
      score_easing = 0;
      incrementScore(completedNote);
      String textType;
      switch( completedNote ){
        case 1:  textType = "focus";  break;
        case 5:  textType = "relax";  break;
        default: textType = "random"; break;
      }
      textFeed       = new Feedback(textType, this.x, -25);
      showSuccessTxt = true;
    }else{
      println("Missed!");
    }
  }

  // returns true if the hitzone and note matched, false if they didn't.
  boolean notesMatchHitzone(){
    boolean retbool = false;
    if( this.activeNote == this.activeHitzone ){
      retbool = true;
    }
    return retbool;
  }

  // increments the score. 150 points for focused or relaxed, 100 for inbetween
  void incrementScore(int completedNote){
    int retPt;
    switch (completedNote) {
      case 1:
      case 5:
      retPt = 150;
      break;
      default:
      retPt = 100;
    }
    score += retPt;
  }


  /*********************
   * Hitzone Methods  *
   ********************/
   // sets the active hitzone (1-5)
   void setActiveHitzone(int colNum){
    if( colNum > -1 && colNum < 6 ){
        this.activeHitzone = colNum;
    }
   }



  /*********************
   * Vignette Methods  *
   ********************/

   void setActiveVignette(int which) {
    if( which == 1 || which == 2 || which == 0 ){
      activeVignette = which;
    }
   }

}
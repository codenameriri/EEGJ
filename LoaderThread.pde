class LoaderThread extends Thread {
  // THREAD SETTINGS
  ScrollingStage parent;
  boolean active;
  boolean loadingCompleted;
  int resourceIndex;
  String statusText;

  // IMAGE CONSTANTS
  final int GRID_FRAME_CNT    = 10;
  final int HITZONE_FRAME_CNT = 5;
  final int STAGE_FRAME_CNT   = 6;
  final int COLSEQ_FRAME_CNT  = 10;
  final String EXTN            = ".png";
  final String GRID_DIR       = "grid/";
  final String VIGNETTE_DIR   = "vignette/";
  final String STAGE_DIR      = "stage/";
  final String FOCAL_DIR      = "focal/";
  final String NOTES_DIR      = "notes/";
  final String HITZONE_DIR    = "hitzone/";


  // IMAGE VARIABLES
  PImage[] stageSequence;
  PImage[] gridSequence;
  PImage[] col1Sequence;
  PImage[] col2Sequence;
  PImage[] col3Sequence;
  PImage[] col4Sequence;
  PImage[] col5Sequence;
  PImage[] hitzoneSequence;
  PImage stageBG;
  PImage focal;
  PImage focusVignette;
  PImage relaxVignette;

  // COLLECTIONS
  Star[] starCollection;

  LoaderThread( ScrollingStage p ){
    parent           = p;
    active           = false;
    loadingCompleted = false;
    resourceIndex    = 0;
    statusText       = "Initializing..";
  }

  void start(){
    println("LoaderThread::start();");
    statusText = "Loader running...";
    active = true;
    super.start();
  }

  void run(){
    while( true ){
      if( active ){
        println("LoaderThread::current resource index: " + resourceIndex);
        loadResources(resourceIndex);
        resourceIndex++;
      }else{
        println("LoaderThread::Loading completed!");
        statusText = "All assets loaded successfully.";
        parent.finishedLoading(true);
        break;
      }
    }
  }



  void loadResources( int whichResource ){
    println("LoaderThread::loadResources()");
    int parentW = round(parent.w);
    int parentH = round(parent.h);
    int gridH   = round(parent.h+parent.GRID_H_PADDING);
    int seqH    = round(parent.h+parent.SEQ_H_PADDING);

    switch (whichResource) {
      // load the stage sequence
      case 0:
        statusText = "Loading stage sequence...";
        stageSequence = new PImage[STAGE_FRAME_CNT];
        for( int ss=0; ss<stageSequence.length; ss++ ){
          stageSequence[ss] = loadImage(STAGE_DIR+"stage"+ss+EXTN);
          stageSequence[ss].resize( parentW, parentH );
        }
      break;
      // load the grid sequence
      case 1:
        statusText = "Loading grid sequence...";
        gridSequence = new PImage[GRID_FRAME_CNT];
        for( int gs=0; gs<gridSequence.length; gs++ ){
          gridSequence[gs] = loadImage(GRID_DIR+"grid"+gs+EXTN);
          gridSequence[gs].resize(parentW, gridH);
        }
      break;
      // load the col1 sequence
      case 2:
        statusText = "Loading column 1 note sequences...";
        col1Sequence = new PImage[COLSEQ_FRAME_CNT];
        for( int c1s=0; c1s<col1Sequence.length; c1s++ ){
          col1Sequence[c1s] = loadImage(NOTES_DIR+"col_1/notes_"+c1s+EXTN);
          col1Sequence[c1s].resize(parentW, seqH);
        }
      break;
      // load the col2 sequence
      case 3:
        statusText = "Loading column 2 note sequences...";
        col2Sequence = new PImage[COLSEQ_FRAME_CNT];
        for( int c2s=0; c2s<col2Sequence.length; c2s++ ){
          col2Sequence[c2s] = loadImage(NOTES_DIR+"col_2/notes_"+c2s+EXTN);
          col2Sequence[c2s].resize(parentW, seqH);
        }
      break;
      // load the col3 sequence
      case 4:
        statusText = "Loading column 3 note sequences...";
        col3Sequence = new PImage[COLSEQ_FRAME_CNT];
        for( int c3s=0; c3s<col3Sequence.length; c3s++ ){
          col3Sequence[c3s] = loadImage(NOTES_DIR+"col_3/notes_"+c3s+EXTN);
          col3Sequence[c3s].resize(parentW, seqH);
        }
      break;
      // load the col4 sequence
      case 5:
        statusText = "Loading column 4 note sequences...";
        col4Sequence = new PImage[COLSEQ_FRAME_CNT];
        for( int c4s=0; c4s<col4Sequence.length; c4s++ ){
          col4Sequence[c4s] = loadImage(NOTES_DIR+"col_4/notes_"+c4s+EXTN);
          col4Sequence[c4s].resize(parentW, seqH);
        }
      break;
      // load the col5 sequence
      case 6:
        statusText = "Loading column 5 note sequences...";
        col5Sequence = new PImage[COLSEQ_FRAME_CNT];
        for( int c5s=0; c5s<col5Sequence.length; c5s++ ){
          col5Sequence[c5s] = loadImage(NOTES_DIR+"col_5/notes_"+c5s+EXTN);
          col5Sequence[c5s].resize(parentW, seqH);
        }
      break;
      // load the hitzone sequence
      case 7:
        statusText = "Loading note hitzones...";
        hitzoneSequence = new PImage[HITZONE_FRAME_CNT];
        for( int hs=0; hs<hitzoneSequence.length; hs++ ){
          hitzoneSequence[hs] = loadImage(HITZONE_DIR+"hitzone"+hs+EXTN);
          hitzoneSequence[hs].resize(parentW, seqH);
        }
      break;
      // load the stage background
      case 8:
        statusText = "Loading background elements...";
        stageBG = loadImage(STAGE_DIR+"bg"+EXTN);
        stageBG.resize(parentW, parentH);
      break;
      // load the focal point
      case 9:
        statusText = "Loading focal..";
        focal = loadImage(FOCAL_DIR+"focal_point_black"+EXTN);
        focal.resize(parentW, parentH);
      break;
      // load the focus vignette
      case 10:
        statusText = "Loading vignette (focus)...";
        focusVignette = loadImage(VIGNETTE_DIR+"focus_vignette"+EXTN);
        // TODO: focusVignette.resize();
      break;

      // load the relaxed vignette
      case 11:
        statusText = "Loading vignette (relaxed)...";
        relaxVignette = loadImage(VIGNETTE_DIR+"relax_vignette"+EXTN);
        // TODO: relaxVignette.resize();
      break;

      // generate the star objects
      case 12:
        statusText = "Generating starfield...";
        starCollection = new Star[parent.starCount];
        for( int sc=0; sc<starCollection.length; sc++ ){
          statusText = "Generating Star #: " + sc;
          starCollection[sc] = new Star();
        }
      break;

      // pass the images off to the parent
      case 13:
        statusText = "Handing off assets to stage...";
        handOff();
      break;

      // past 12? finish the thread. :)
      default:
      println("LoaderThread::loadResources() - final resource loaded");
      statusText = "Resource load complete.";
      quit();
      break;
    }
  }


  // hands off the loaded image referenes to the parent stage
  void handOff(){
    println("LoaderThread::handoff()");
    parent.stageSequence   = this.stageSequence;
    parent.gridSequence    = this.gridSequence;
    parent.col1Sequence    = this.col1Sequence;
    parent.col2Sequence    = this.col2Sequence;
    parent.col3Sequence    = this.col3Sequence;
    parent.col4Sequence    = this.col4Sequence;
    parent.col5Sequence    = this.col5Sequence;
    parent.hitzoneSequence = this.hitzoneSequence;
    parent.stageBG         = this.stageBG;
    parent.focal           = this.focal;
    parent.focusVignette   = this.focusVignette;
    parent.relaxVignette   = this.relaxVignette;
    parent.starCollection  = this.starCollection;
  }



  boolean isActive(){
    return active;
  }



  void quit(){
    println("LoaderThread::quit()");
    active = false;
    interrupt();
  }


}
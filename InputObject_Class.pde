/**
 * @author    Thomas Conroy <tdc5536@rit.edu>
 * @version   1.0
 * @since     2014-03-10
 */
public class InputObject extends Thread {
  /********************
    PROPERTIES
  ********************/
  // gvars
  String type;          // input type / thread name
  int tickRate;         // the rate to tick at
  int elapsedTime;      // time since last tick
  String lastTickValue; // the value returned in the last tick 

  // thread vars
  boolean running;      // == true if thread is running 

  // flex / pressure
  int fp_seedValue;
  int xSig;
  int fp_currentVal;
  
  // pulse
  int pu_currentVal;
  int pu_seedValue;

  // brainwave
  StringList bw_refinedLines = new StringList();
  int bw_currentLine = 0;

  /********************
    CONSTRUCTOR
  ********************/
  InputObject(String type, int tickRate){
    
    // setup properties
    this.running     = false; // disable thread running by default
    this.type        = type;
    this.tickRate    = tickRate;
    this.elapsedTime = millis();
    
    if( this.type == "flex" || this.type == "pressure" ){
      fp_seedValue = round(random(0,100)); // set random starting point 
    } 
    
    if(this.type == "brainwave"){
      // load brainwave data
      String[] allLines = loadStrings("brainwaveData.txt");
      // remove dead data
      for(int i=0; i<allLines.length; i++){
        if( !(allLines[i].length() < 20) && (allLines[i].indexOf("ERROR:") == -1) ){
          bw_refinedLines.append(allLines[i]);
        }
      }
    }
    
    if( this.type == "pulse" ){
      // set seed value for pulserate (starting pulse value)
      pu_seedValue = round(random(75,80));

    }

  }


  /***********************
    THREAD METHODS
   **********************/
  // override start method
  void start(){
    // enable running bool
    running = true;

    // start the thread
    super.start();
  }

  // run method, triggered by start()
  void run(){
    while(running){
      // do whatever we want to do this tick
      if( this.type == "flex" || this.type == "pressure" ){
        fp_currentVal = this.randomWalk(fp_currentVal, "fp");
      }
      
      if( this.type == "brainwave" ){
        bw_currentLine += 1;
        if( bw_currentLine >= bw_refinedLines.size() ){
            // reset
            bw_currentLine = 0;
        }else{
          bw_currentLine += 1;
        }
      }
      
      if( this.type == "pulse" ){
        pu_currentVal = this.randomWalk(pu_currentVal, "pu");
      }

      // wait for next tick
      try {
        sleep((long)(tickRate));
      } catch (Exception e) {
        
      }
    }
    println(this.type + " Thread is done.");
  }

  // method to quit the thread
  void quit() {
    println("Quitting thread..");
    this.running = false; // terminate the loop
    interrupt();
  }
  
 /*********************
    CUSTOM METHODS
 *********************/
 // updates data on tick 
 void updateData(){
    //
  }
  
  // retrieve current data
  String getData(){ 

    // update the data first
    this.updateData();

    // the string we're returning
    String returnStr = "";
    
    if( this.type == "pressure" || this.type == "flex" ){
      returnStr = Integer.toString(fp_currentVal);
    }
    
    if( this.type == "brainwave" ){
      returnStr = bw_refinedLines.get(bw_currentLine);
    }
    
    if( this.type == "pulse" ){
      returnStr = Integer.toString(pu_currentVal);
    }
    
    return returnStr;
  }






  // generates a trended value between 0 and 100 
  // ( for flex and pressure sensors )
  private int randomWalk(int seedVal, String sensorType ){
    
    if( sensorType == "pu" ){
      xSig = seedVal +  (int)random(-2,2);
      if(xSig < 60)       {xSig = 60;}
      else if(xSig > 80) {xSig = 80;}
      else               {seedVal = xSig;}
    }

    if( sensorType == "fp" ){
      xSig = seedVal +  (int)random(-10,10);
      if(xSig < 0)        {xSig = 0;}
      else if(xSig > 100) {xSig = 100;}
      else                {seedVal = xSig;}
    }


    return xSig;
  }

}
/**
 * @author    Thomas Conroy <tdc5536@rit.edu>
 * @version   1.0
 * @since     2014-03-10
 */
class DataGenerator{
  /********************
    PROPERTIES
  ********************/
  HashMap<String, InputObject> inputMap;
  
  /********************
    CONSTRUCTOR
  ********************/
  DataGenerator(HashMap<String,Integer> inputSettings) {
    
    // instantiate the inputMap (where we store the input objects)
    inputMap = new HashMap<String, InputObject>();
    
    // create the input objects using data from inputSettings, saving them to the inputMap for mater reference
    for( Map.Entry input : inputSettings.entrySet() ){
      InputObject tmpObj = new InputObject( (String)input.getKey(), (Integer)input.getValue() );
      inputMap.put((String)input.getKey(), tmpObj);
    }

    // then, start all the input threads
    toggleAll("on");
    
  }
  
  /*********************
    CUSTOM METHODS
  *********************/
  /**
   * calls update method on all input threads the generator controls.
   *
   * @param     none
   * @return    void
   */    
  void updateAllInputs(){
    // loop through all the input objects, and execute their update method.
    for(Map.Entry inp : inputMap.entrySet()){
      inputMap.get(inp.getKey()).updateData();
    }
  }

  /**
   * starts or stops all input threads.
   *
   * @param     String setting : "start", "stop"
   * @return    void
   */   
  void toggleAll(String setting){
    for( Map.Entry inp : inputMap.entrySet() ){
      if( setting == "on" ){
        inputMap.get(inp.getKey()).start();
      }
      if( setting == "off" ){
        inputMap.get(inp.getKey()).quit();
      }
    }
  }

  /**
   * starts or stops specific input thread.
   *
   * @param     String    type    : "flex", "pressure", "brainwave", "pulse"
   * @param     String    setting : "start" or "stop"
   * @return    void
   */    
  void toggleSpecific(String type, String setting){
    for( Map.Entry inp : inputMap.entrySet() ){
      // only act on the specified inputMaker
      if( inputMap.get(inp.getKey()).type == type ){
        if( setting == "start" ){
          inputMap.get(inp.getKey()).start();
        }
        else if( setting == "stop" ){
          inputMap.get(inp.getKey()).quit();
        }
      }
    }
  }

  /**
   * returns current tick value of specified input. 
   *
   * @param     String    type    : "flex", "pressure", "brainwave", "pulse"
   * @return    String    datastr : current value of tick (in string form, may need to convert to int/float)
   */    
  String getInput(String type){
    if( type != null && inputMap.get(type) != null ){
      
      String datastr = new String();
      datastr        = inputMap.get(type).getData();
      
      return datastr;
    }else{
      return null;
    }
  }
  
}
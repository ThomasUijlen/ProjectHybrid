import processing.video.*;

Capture cam;

void setup() {
  //fullScreen();
  size(640, 480);
  //size(960, 540);

  String[] cameras = Capture.list();
  
  if (cameras.length == 0) {
    println("There are no cameras available for capture.");
    exit();
  } else {
    println("Available cameras:");
    for (int i = 0; i < cameras.length; i++) {
      println(cameras[i]);
    }
    
    // The camera can be initialized directly using an 
    // element from the array returned by list():
    cam = new Capture(this, cameras[1]);
    cam.start();
  }      
}

boolean clicked = false;
void draw() {
  if (cam.available() == true) {
    cam.read();
  }
  image(cam, 0, 0);
  
  int millis = millis();
  if (mousePressed && (mouseButton == LEFT)) {
    if(clicked) return;
    clicked = true;
    save("Images/"+str(millis)+".jpg");
  } else {
    clicked = false;
  }
}

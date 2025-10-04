
import processing.serial.*;
import controlP5.*;

Serial myPort;
boolean connected = false;

ControlP5 cp5;
DropdownList portList, baudList;
Button connectBtn;

String angle="";
String distance="";
String data="";
int iAngle, iDistance;
float pixsDistance;

PFont orcFont;

// Khai báo mảng baudrates
int[] baudRates = {9600, 115200};


void setup() {
  size (1250, 650);
  smooth();

  cp5 = new ControlP5(this);

  // danh sách COM port
  portList = cp5.addDropdownList("COM Port")
                .setPosition(20, 20)
                .setSize(200, 200);
  String[] ports = Serial.list();
  for (int i = 0; i < ports.length; i++) {
    portList.addItem(ports[i], i);
  }

  // baud rate list
  baudList = cp5.addDropdownList("Baud Rate")
                .setPosition(240, 20)
                .setSize(150, 100);
  baudList.addItem("9600", 9600);
  baudList.addItem("115200", 115200);

  // nút connect
  connectBtn = cp5.addButton("Connect")
                  .setPosition(410, 20)
                  .setSize(100, 30);

  orcFont = createFont("Consolas", 20); // đổi font để chắc chắn có
}

void draw() {
  fill(0, 30);
  noStroke();
  rect(0, 0, width, height);

  fill(98,245,31);
  textFont(orcFont);

  if (!connected) {
    fill(0,255,0);
    text("Chọn COM + Baud rồi bấm Connect", 20, height - 30);
    return;
  }
  
  if (connected && myPort.available() > 0) {
    String raw = myPort.readString();
    if (raw != null) {
      println("DEBUG RAW: " + raw);
    }
  }

  drawRadar();
  drawLine();
  drawObject();
  drawText();
}

void serialEvent(Serial myPort) {
  String packet = myPort.readStringUntil('\n');   // đọc tới  '\n'
  if (packet != null) {
    packet = packet.replaceAll("[^0-9,]", "");  // giữ lại chỉ số và dấu phẩy
    println("CLEAN: " + packet);

    int idx = packet.indexOf(",");
    if (idx > 0) {
      String a = packet.substring(0, idx);
      String d = packet.substring(idx+1);

      try {
        iAngle = Integer.parseInt(a);
        iDistance = Integer.parseInt(d);
        println("✓ Góc=" + iAngle + " | Khoảng cách=" + iDistance);
      } catch(Exception e) {
        println(" Parse fail: '" + packet + "'");
      }
    }
  }
}



//---------------- vẽ radar ----------------
void drawRadar() {
  pushMatrix();
  translate(width/2, height-height*0.074);
  noFill();
  strokeWeight(2);
  stroke(98,245,31);

  arc(0,0,(width-width*0.0625),(width-width*0.0625),PI,TWO_PI);
  arc(0,0,(width-width*0.27),(width-width*0.27),PI,TWO_PI);
  arc(0,0,(width-width*0.479),(width-width*0.479),PI,TWO_PI);
  arc(0,0,(width-width*0.687),(width-width*0.687),PI,TWO_PI);

  line(-width/2,0,width/2,0);
  line(0,0,(-width/2)*cos(radians(30)),(-width/2)*sin(radians(30)));
  line(0,0,(-width/2)*cos(radians(60)),(-width/2)*sin(radians(60)));
  line(0,0,(-width/2)*cos(radians(90)),(-width/2)*sin(radians(90)));
  line(0,0,(-width/2)*cos(radians(120)),(-width/2)*sin(radians(120)));
  line(0,0,(-width/2)*cos(radians(150)),(-width/2)*sin(radians(150)));
  popMatrix();
}

void drawObject() {
  pushMatrix();
  translate(width/2, height-height*0.074);
  strokeWeight(9);
  stroke(255,10,10);

  pixsDistance = iDistance * ((height-height*0.1666)*0.025);

  if(iDistance < 40) { // range limit
    line(pixsDistance*cos(radians(iAngle)), -pixsDistance*sin(radians(iAngle)),
         (width-width*0.505)*cos(radians(iAngle)), -(width-width*0.505)*sin(radians(iAngle)));
  }
  popMatrix();
}

void drawLine() {
  pushMatrix();
  strokeWeight(9);
  stroke(30,250,60);
  translate(width/2, height-height*0.074);
  line(0,0,(height-height*0.12)*cos(radians(iAngle)), -(height-height*0.12)*sin(radians(iAngle)));
  popMatrix();
}

void drawText() {
  pushMatrix();
  fill(0,0,0);
  noStroke();
  rect(0, height-height*0.0648, width, height);
  fill(98,245,31);
  textSize(20);
  text("Angle: " + iAngle + "°", 50, height-20);
  text("Distance: " + iDistance + " cm", 250, height-20);
  popMatrix();
}

//---------------- Kết nối ----------------
void Connect() {
  if (connected) {
    myPort.stop();
    connected = false;
    println("Đã ngắt kết nối.");
    return;
  }

  int portIndex = int(portList.getValue());
  int baudIndex = int(baudList.getValue());
  int baudRate = baudRates[baudIndex];         // map sang giá trị thật
  if (portIndex >= 0 && baudRate > 0) {
    try {
      myPort = new Serial(this, Serial.list()[portIndex], baudRate);
      myPort.bufferUntil('\n');   // CHUẨN theo dữ liệu ESP32 gửi
      connected = true;
      println("DEBUG baudList value = " + baudList.getValue());
      println("✅ Kết nối " + Serial.list()[portIndex] + " @ " + baudRate);
    } catch (Exception e) {
      println("❌ Không mở được cổng " + Serial.list()[portIndex]);
      connected = false;
    }
  }
}

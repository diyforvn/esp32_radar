#include <ESP32Servo.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SH110X.h>

#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define OLED_RESET    -1
Adafruit_SH1106G display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

Servo myServo;
const int trigPin = 25;   //  Trig HC-SR04
const int echoPin = 27;   //  Echo HC-SR04
const int servoPin = 19;  // servo SG90

long duration;
int distance;

int angle = 0;
bool dir = true;  // direct

// Đọc khoảng cách (cm)
long readDistanceCM() {
  digitalWrite(trigPin, LOW);
  delayMicroseconds(2);
  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);
  duration = pulseIn(echoPin, HIGH, 20000); // timeout 20ms ~ 3.4m
  long d = duration * 0.034 / 2;
  return d;
}

// Vẽ radar trên OLED
void drawRadar(int angle, int distance) {
  display.clearDisplay();

  // Tâm radar
  int cx = SCREEN_WIDTH / 2;
  int cy = SCREEN_HEIGHT - 1; // đáy màn hình

  // Tầm quét tối đa 30cm
  float maxDist = 30.0;
  int maxR = 60; // bán kính pixel
  float scale = maxR / maxDist;

  // Vẽ vòng tròn chia 10cm, 20cm, 30cm
  for (int d = 10; d <= maxDist; d += 10) {
    int r = d * scale;
    display.drawCircle(cx, cy, r, SH110X_WHITE);
  }

  // Góc hiện tại (rad)
  float rad = radians(angle);
  int x_end = cx + cos(rad) * maxR;
  int y_end = cy - sin(rad) * maxR;

  // Nếu có vật cản trong tầm
  if (distance > 0 && distance <= maxDist) {
    int rx = cx + cos(rad) * distance * scale;
    int ry = cy - sin(rad) * distance * scale;

    // Vẽ tia sáng từ tâm -> vật
    display.drawLine(cx, cy, rx, ry, SH110X_WHITE);

    // Vẽ bóng mờ sau vật (nét đứt)
    for (int i = 0; i < 10; i++) {
      int bx1 = rx + (x_end - rx) * i / 10;
      int by1 = ry + (y_end - ry) * i / 10;
      int bx2 = rx + (x_end - rx) * (i + 0.5) / 10;
      int by2 = ry + (y_end - ry) * (i + 0.5) / 10;
      display.drawLine(bx1, by1, bx2, by2, SH110X_WHITE);
    }

    // Vẽ vật thể
    display.fillCircle(rx, ry, 3, SH110X_WHITE);

  } else {
    // Không có vật → vẽ tia sáng trọn vẹn
    display.drawLine(cx, cy, x_end, y_end, SH110X_WHITE);
  }

  display.display();
}

void setup() {
  Serial.begin(115200);
  myServo.attach(servoPin);
  pinMode(trigPin, OUTPUT);
  pinMode(echoPin, INPUT);

  if (!display.begin(0x3c, true)) {
    Serial.println("OLED init failed");
    for (;;);
  }
  display.clearDisplay();
  display.setTextSize(1);
}

void loop() {
  // Điều khiển servo
  myServo.write(angle);
  delay(20);

  // Đọc khoảng cách
  distance = readDistanceCM();

  // Xuất dữ liệu cho PC
  Serial.print(angle);
  Serial.print(",");
  Serial.println(distance);

  // Vẽ radar trên OLED
  drawRadar(angle, distance);

  // Đổi hướng quét
  if (dir) {
    angle++;
    if (angle >= 180) dir = false;
  } else {
    angle--;
    if (angle <= 0) dir = true;
  }
}

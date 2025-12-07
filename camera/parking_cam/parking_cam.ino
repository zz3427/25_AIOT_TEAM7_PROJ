#include "esp_camera.h"
#include <WiFi.h>
#include <HTTPClient.h>


// ===== 1. WiFi settings =====
// const char* ssid     = "SpectrumSetup-36AC";
// const char* password = "entirefarmer768";

const char* ssid     = "Columbia University";
const char* password = "";

// Change this to development backend URL
String serverUrl = "http://10.206.110.154:8080/api/camera/upload?camera_id=cam-001";

#define CAMERA_MODEL_AI_THINKER
#include "camera_pins.h"   // comes from ESP32 camera examples

#define FLASH_LED_PIN 4   // AI-Thinker board uses GPIO 4 for the flash LED

// ===== 2. Connect to WiFi =====
void connectToWiFi() {
  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);
  Serial.println("Connecting to WiFi...");

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("\nWiFi connected!");
  Serial.print("IP address: ");
  Serial.println(WiFi.localIP());
}

// ===== 3. Initialize camera =====
bool initCamera() {
  camera_config_t config;
  config.ledc_channel = LEDC_CHANNEL_0;
  config.ledc_timer   = LEDC_TIMER_0;
  config.pin_d0       = Y2_GPIO_NUM;
  config.pin_d1       = Y3_GPIO_NUM;
  config.pin_d2       = Y4_GPIO_NUM;
  config.pin_d3       = Y5_GPIO_NUM;
  config.pin_d4       = Y6_GPIO_NUM;
  config.pin_d5       = Y7_GPIO_NUM;
  config.pin_d6       = Y8_GPIO_NUM;
  config.pin_d7       = Y9_GPIO_NUM;
  config.pin_xclk     = XCLK_GPIO_NUM;
  config.pin_pclk     = PCLK_GPIO_NUM;
  config.pin_vsync    = VSYNC_GPIO_NUM;
  config.pin_href     = HREF_GPIO_NUM;
  config.pin_sscb_sda = SIOD_GPIO_NUM;
  config.pin_sscb_scl = SIOC_GPIO_NUM;
  config.pin_pwdn     = PWDN_GPIO_NUM;
  config.pin_reset    = RESET_GPIO_NUM;
  config.xclk_freq_hz = 20000000;
  config.pixel_format = PIXFORMAT_JPEG;

  // choose a reasonable frame size
  config.frame_size   = FRAMESIZE_VGA;  // 640x480
  config.jpeg_quality = 15;             // lower = better quality, bigger size
  config.fb_count     = 1;

  esp_err_t err = esp_camera_init(&config);
  if (err != ESP_OK) {
    Serial.printf("Camera init failed with error 0x%x\n", err);
    return false;
  }

  Serial.println("Camera init success!");
  return true;
}

// ===== 4. Capture and upload one frame =====
void captureAndUpload() {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("WiFi not connected, reconnecting...");
    connectToWiFi();
  }

  // // 🔦 TURN ON FLASH BEFORE TAKING PICTURE
  // digitalWrite(FLASH_LED_PIN, HIGH);
  // delay(150);  // small warm-up for camera exposure

  camera_fb_t *fb = esp_camera_fb_get();

  // // 🔦 TURN FLASH OFF AFTER CAPTURE
  // digitalWrite(FLASH_LED_PIN, LOW);

  if (!fb) {
    Serial.println("Camera capture failed");
    return;
  }

  Serial.print("Captured image, size = ");
  Serial.print(fb->len);
  Serial.println(" bytes");

  Serial.print("Posting to: ");
  Serial.println(serverUrl);

  HTTPClient http;
  http.begin(serverUrl);
  http.addHeader("Content-Type", "image/jpeg");

  int httpCode = http.POST(fb->buf, fb->len);

  if (httpCode > 0) {
    Serial.printf("HTTP POST code: %d\n", httpCode);
    String payload = http.getString();
    Serial.println("Response:");
    Serial.println(payload);
  } else {
    Serial.printf("HTTP POST failed: %s\n",
                  http.errorToString(httpCode).c_str());
  }

  http.end();
  esp_camera_fb_return(fb);
}

// ===== 5. Arduino setup/loop =====
void setup() {
  pinMode(FLASH_LED_PIN, OUTPUT);
  digitalWrite(FLASH_LED_PIN, LOW);  // flash off

  Serial.begin(115200);
  delay(2000);
  Serial.println("\nBooting parking camera...");

  connectToWiFi();

  if (!initCamera()) {
    Serial.println("Camera init failed, restarting in 5 seconds...");
    delay(5000);
    ESP.restart();
  }
}

void loop() {
  Serial.println("\nTaking picture and uploading...");
  captureAndUpload();
  delay(5000);  // every 10 seconds (tune this later)
}

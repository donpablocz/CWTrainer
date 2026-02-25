// CW TRAINER - Arduino kód - SE ZVUKEM

#include <Wire.h>
#include <LiquidCrystal_I2C.h>

LiquidCrystal_I2C lcd(0x27, 16, 2);

// Piny
const int MORSE_OUT = 13;
const int MORSE_IN_STRAIGHT = 2;
const int PADDLE_DOT = 2;
const int PADDLE_DASH = 3;
const int PADDLE_DOT_OUT = 13;
const int PADDLE_DASH_OUT = 12;
const int AUDIO_OUT = 10;

// Zvuk
const int TONE_FREQ = 550; // Hz

// Typ klíče
const int KEY_STRAIGHT = 0;
const int KEY_PADDLE = 1;
int keyType = KEY_STRAIGHT;

// Morse timing
int wpm = 15;
int dotLength = 1200 / wpm;

// Morse tabulka
const char* morseTable[] = {
  ".-", "-...", "-.-.", "-..", ".", "..-.", "--.", "....", "..", ".---",
  "-.-", ".-..", "--", "-.", "---", ".--.", "--.-", ".-.", "...", "-",
  "..-", "...-", ".--", "-..-", "-.--", "--..",
  "-----", ".----", "..---", "...--", "....-", ".....", "-....", "--...", "---..", "----.",
  "..--..", ".-.-.-", "--..--", "-..-."
};

// Dekódování vstupu - klasický klíč
String currentMorse = "";
String decodedText = "";
unsigned long keyDownTime = 0;
unsigned long keyUpTime = 0;
bool lastKeyState = false;

// Iambic keyer pro dvoupadlový klíč
int keyerMode = 0;
unsigned long keyerTimer = 0;
bool dotMemory = false;
bool dashMemory = false;
unsigned long lastCharTime = 0;

void setup() {
  Serial.begin(9600);
  
  pinMode(MORSE_OUT, OUTPUT);
  pinMode(PADDLE_DOT_OUT, OUTPUT);
  pinMode(PADDLE_DASH_OUT, OUTPUT);
  pinMode(AUDIO_OUT, OUTPUT);
  pinMode(MORSE_IN_STRAIGHT, INPUT_PULLUP);
  pinMode(PADDLE_DOT, INPUT_PULLUP);
  pinMode(PADDLE_DASH, INPUT_PULLUP);
  
  lcd.init();
  lcd.backlight();
  lcd.setCursor(0, 0);
  lcd.print("CW TRAINER");
  lcd.setCursor(0, 1);
  lcd.print("Klasicky klic");
  
  digitalWrite(MORSE_OUT, LOW);
  digitalWrite(PADDLE_DOT_OUT, LOW);
  digitalWrite(PADDLE_DASH_OUT, LOW);
}

void loop() {
  if (Serial.available()) {
    String command = Serial.readStringUntil('\n');
    command.trim();
    
    if (command.startsWith("KEYTYPE:")) {
      keyType = command.substring(8).toInt();
      lcd.clear();
      lcd.print("CW TRAINER");
      lcd.setCursor(0, 1);
      if (keyType == KEY_PADDLE) {
        lcd.print("Dvoupadlovy");
      } else {
        lcd.print("Klasicky");
      }
      Serial.println("OK:KEYTYPE");
    }
    else if (command.startsWith("WPM:")) {
      wpm = command.substring(4).toInt();
      if (wpm < 5) wpm = 5;
      if (wpm > 40) wpm = 40;
      dotLength = 1200 / wpm;
      lcd.clear();
      lcd.print("WPM: ");
      lcd.print(wpm);
      Serial.println("OK:WPM");
    }
    else if (command.startsWith("TX:")) {
      String text = command.substring(3);
      text.toUpperCase();
      lcd.clear();
      lcd.setCursor(0, 0);
      lcd.print("TX:");
      lcd.setCursor(0, 1);
      lcd.print(text.substring(0, 16));
      sendMorse(text);
      Serial.println("OK:TX");
    }
    else if (command == "CLEAR") {
      clearBuffers();
      Serial.println("OK:CLEAR");
    }
  }
  
  if (keyType == KEY_STRAIGHT) {
    decodeStraightKey();
  } else {
    decodePaddleKey();
  }
}

void sendMorse(String text) {
  for (int i = 0; i < text.length(); i++) {
    char c = text.charAt(i);
    
    if (c == ' ') {
      delay(dotLength * 7);
    }
    else {
      const char* morse = charToMorse(c);
      if (morse != NULL) {
        sendMorseChar(morse);
        delay(dotLength * 3);
      }
    }
  }
  
  delay(500);
  clearBuffers();
}

void sendMorseChar(const char* morse) {
  for (int i = 0; morse[i] != '\0'; i++) {
    if (keyType == KEY_PADDLE) {
      if (morse[i] == '.') {
        digitalWrite(PADDLE_DOT_OUT, HIGH);
        tone(AUDIO_OUT, TONE_FREQ);
        delay(dotLength);
        digitalWrite(PADDLE_DOT_OUT, LOW);
        noTone(AUDIO_OUT);
      } else if (morse[i] == '-') {
        digitalWrite(PADDLE_DASH_OUT, HIGH);
        tone(AUDIO_OUT, TONE_FREQ);
        delay(dotLength * 3);
        digitalWrite(PADDLE_DASH_OUT, LOW);
        noTone(AUDIO_OUT);
      }
    } else {
      digitalWrite(MORSE_OUT, HIGH);
      tone(AUDIO_OUT, TONE_FREQ);
      if (morse[i] == '.') {
        delay(dotLength);
      } else if (morse[i] == '-') {
        delay(dotLength * 3);
      }
      digitalWrite(MORSE_OUT, LOW);
      noTone(AUDIO_OUT);
    }
    delay(dotLength);
  }
}

void clearBuffers() {
  currentMorse = "";
  decodedText = "";
  keyUpTime = 0;
  keyDownTime = 0;
  lastKeyState = false;
  keyerMode = 0;
  dotMemory = false;
  dashMemory = false;
  lastCharTime = 0;
  lcd.setCursor(0, 1);
  lcd.print("                ");
}

const char* charToMorse(char c) {
  if (c >= 'A' && c <= 'Z') return morseTable[c - 'A'];
  if (c >= '0' && c <= '9') return morseTable[26 + (c - '0')];
  if (c == '?') return morseTable[36];
  if (c == '.') return morseTable[37];
  if (c == ',') return morseTable[38];
  if (c == '/') return morseTable[39];
  return NULL;
}

char morseToChar(String morse) {
  for (int i = 0; i < 26; i++) {
    if (morse == morseTable[i]) return 'A' + i;
  }
  for (int i = 0; i < 10; i++) {
    if (morse == morseTable[26 + i]) return '0' + i;
  }
  if (morse == morseTable[36]) return '?';
  if (morse == morseTable[37]) return '.';
  if (morse == morseTable[38]) return ',';
  if (morse == morseTable[39]) return '/';
  return '?';
}

void decodeStraightKey() {
  bool currentKey = !digitalRead(MORSE_IN_STRAIGHT);
  unsigned long now = millis();
  
  digitalWrite(MORSE_OUT, currentKey ? HIGH : LOW);
  
  // Zvukový výstup
  if (currentKey) {
    tone(AUDIO_OUT, TONE_FREQ);
  } else {
    noTone(AUDIO_OUT);
  }
  
  if (currentKey && !lastKeyState) {
    keyDownTime = now;
    
    if (keyUpTime > 0 && currentMorse.length() > 0) {
      unsigned long gap = now - keyUpTime;
      
      if (gap > dotLength * 2.5) {
        char decoded = morseToChar(currentMorse);
        decodedText += decoded;
        currentMorse = "";
        updateLCD();
        
        Serial.print("CHAR:");
        Serial.println(decoded);
      }
    }
  }
  else if (!currentKey && lastKeyState) {
    keyUpTime = now;
    unsigned long duration = now - keyDownTime;
    
    if (duration > dotLength * 1.5) {
      currentMorse += '-';
    } else if (duration > dotLength * 0.3) {
      currentMorse += '.';
    }
  }
  
  if (!currentKey && keyUpTime > 0 && currentMorse.length() > 0) {
    if (now - keyUpTime > dotLength * 3.5) {
      char decoded = morseToChar(currentMorse);
      decodedText += decoded;
      currentMorse = "";
      updateLCD();
      
      Serial.print("CHAR:");
      Serial.println(decoded);
      
      keyUpTime = 0;
    }
  }
  
  lastKeyState = currentKey;
}

void decodePaddleKey() {
  unsigned long now = millis();
  
  bool dotPressed = !digitalRead(PADDLE_DOT);
  bool dashPressed = !digitalRead(PADDLE_DASH);
  
  // Vysílání přímo na piny - průběžně
  digitalWrite(PADDLE_DOT_OUT, dotPressed ? HIGH : LOW);
  digitalWrite(PADDLE_DASH_OUT, dashPressed ? HIGH : LOW);
  
  // Zvukový výstup podle vnitřního generátoru
  bool shouldBeep = false;
  if (keyerMode == 1) {
    // DOT mode - pípat během prvního dotLength
    if (now - keyerTimer < dotLength) {
      shouldBeep = true;
    }
  }
  else if (keyerMode == 2) {
    // DASH mode - pípat během prvních dotLength * 3
    if (now - keyerTimer < dotLength * 3) {
      shouldBeep = true;
    }
  }
  
  if (shouldBeep) {
    tone(AUDIO_OUT, TONE_FREQ);
  } else {
    noTone(AUDIO_OUT);
  }
  
  // Iambic keyer logika pro dekódování
  if (keyerMode == 0) {
    if (dotPressed) {
      keyerMode = 1;
      keyerTimer = now;
      currentMorse += '.';
      lastCharTime = now;
    }
    else if (dashPressed) {
      keyerMode = 2;
      keyerTimer = now;
      currentMorse += '-';
      lastCharTime = now;
    }
  }
  else if (keyerMode == 1) {
    if (dashPressed) dashMemory = true;
    
    if (now - keyerTimer >= dotLength) {
      if (now - keyerTimer >= dotLength * 2) {
        if (dashMemory && dashPressed) {
          keyerMode = 2;
          dashMemory = false;
          keyerTimer = now;
          currentMorse += '-';
          lastCharTime = now;
        }
        else if (dotPressed) {
          keyerMode = 1;
          keyerTimer = now;
          currentMorse += '.';
          lastCharTime = now;
        }
        else {
          keyerMode = 0;
        }
      }
    }
  }
  else if (keyerMode == 2) {
    if (dotPressed) dotMemory = true;
    
    if (now - keyerTimer >= dotLength * 3) {
      if (now - keyerTimer >= dotLength * 4) {
        if (dotMemory && dotPressed) {
          keyerMode = 1;
          dotMemory = false;
          keyerTimer = now;
          currentMorse += '.';
          lastCharTime = now;
        }
        else if (dashPressed) {
          keyerMode = 2;
          keyerTimer = now;
          currentMorse += '-';
          lastCharTime = now;
        }
        else {
          keyerMode = 0;
        }
      }
    }
  }
  
  // Timeout - dokončení znaku
  if (keyerMode == 0 && currentMorse.length() > 0) {
    if (now - lastCharTime > dotLength * 3.5) {
      char decoded = morseToChar(currentMorse);
      decodedText += decoded;
      currentMorse = "";
      updateLCD();
      
      Serial.print("CHAR:");
      Serial.println(decoded);
      
      lastCharTime = 0;
    }
  }
}

void updateLCD() {
  lcd.setCursor(0, 1);
  String display = decodedText;
  if (display.length() > 16) {
    display = display.substring(display.length() - 16);
  }
  lcd.print("                ");
  lcd.setCursor(0, 1);
  lcd.print(display);
}
// CW TRAINER - Processing kód - S INFO OBRAZOVKOU
import javax.swing.JOptionPane;
import processing.serial.*;

Serial arduino;

// Režimy
final int MODE_MENU = 0;
final int MODE_TRANSMIT = 1;
final int MODE_TRAINER = 2;
final int MODE_INFO = 3;
int currentMode = MODE_MENU;

// Typ klíče
final int KEY_STRAIGHT = 0;
final int KEY_PADDLE = 1;
int keyType = KEY_STRAIGHT;

// UI
String inputText = "";
String statusText = "Vyberte režim";
String lastSent = "";
String receivedText = "";

// Trainer
String currentCallsign = "";
int score = 0;
int attempts = 0;
boolean waitingForAnswer = false;
boolean hideCallsign = false;

// WPM
int wpm = 15;

// Memory buttony
String[] memoryTexts = {"CQ CQ CQ", "73", "QRS", "599"};
int editingMemory = -1;
String editBuffer = "";

// Prefixy
String[] prefixes = {

  // ===== EVROPA =====
  "OK",   // Česká republika
  "OL",   // Česká republika
  "OE",   // Rakousko
  "DL",   // Německo
  "OM",   // Slovensko
  "SP",   // Polsko
  "F",    // Francie
  "G",    // Velká Británie
  "I",    // Itálie
  "EA",   // Španělsko
  "CT",   // Portugalsko
  "PA",   // Nizozemsko
  "ON",   // Belgie
  "LX",   // Lucembursko
  "HB",   // Švýcarsko
  "9A",   // Chorvatsko
  "S5",   // Slovinsko
  "LZ",   // Bulharsko
  "YO",   // Rumunsko
  "HA",   // Maďarsko
  "OH",   // Finsko
  "SM",   // Švédsko
  "LA",   // Norsko
  "OZ",   // Dánsko
  "EI",   // Irsko
  "SV",   // Řecko
  "TF",   // Island
  "UA",   // Ukrajina

  // ===== SEVERNÍ AMERIKA =====
  "K",    // USA
  "W",    // USA
  "N",    // USA
  "VE",   // Kanada
  "XE",   // Mexiko
  "TI",   // Kostarika
  "HI",   // Dominikánská republika
  "CU",   // Kuba

  // ===== JIŽNÍ AMERIKA =====
  "PY",   // Brazílie
  "LU",   // Argentina
  "CX",   // Uruguay
  "YV",   // Venezuela
  "CE",   // Chile
  "OA",   // Peru
  "HC",   // Ekvádor
  "HK",   // Kolumbie

  // ===== ASIE =====F
  "JA",   // Japonsko
  "HL",   // Jižní Korea
  "BY",   // Čína
  "HS",   // Thajsko
  "DU",   // Filipíny
  "4X",   // Izrael
  "A6",   // SAE
  "A7",   // Katar
  "HZ",   // Saúdská Arábie

  // ===== AFRIKA =====
  "ZS",   // Jižní Afrika
  "CN",   // Maroko
  "5B",   // Kypr
  "5N",   // Nigérie
  "ET",   // Etiopie
  "7X",   // Alžírsko
  "SU",   // Egypt
  "9J",   // Zambie

  // ===== OCEÁNIE =====
  "VK",   // Austrálie
  "ZL",   // Nový Zéland
  "YB",   // Indonésie
  "DU",   // Filipíny
  "T2",   // Tuvalu
  

};

// Barvy
color bgColor = color(20, 25, 20);
color textColor = color(50, 255, 100);
color dimColor = color(30, 100, 50);
color accentColor = color(255, 180, 50);
color errorColor = color(255, 80, 80);

PFont mainFont;
PImage logo;

boolean portSelected = false;

void setup() {
  size(800, 600);
  
  mainFont = createFont("Consolas", 18);
  textFont(mainFont);
  
  // Načtení loga
  try {
    logo = loadImage("logo_cwtrainer.png");
    logo.resize(700, 0);
  } catch (Exception e) {
    println("Logo nenalezeno");
  }
  
  imageMode(CENTER);
}


void selectSerialPort() {
  
  String[] ports = Serial.list();
  
  if (ports.length == 0) {
    JOptionPane.showMessageDialog(null, 
      "Nenalezen žádný COM port!", 
      "Chyba", 
      JOptionPane.ERROR_MESSAGE);
    exit();
    return;
  }
  
  String selected = (String) JOptionPane.showInputDialog(
    null,
    "Vyberte COM port:",
    "CW Trainer - Výběr portu",
    JOptionPane.QUESTION_MESSAGE,
    null,
    ports,
    ports[0]
  );
  
  if (selected == null) {
    exit();
    return;
  }
  
  try {
    arduino = new Serial(this, selected, 9600);
    delay(2500);
    arduino.bufferUntil('\n');
    statusText = "Připojeno: " + selected;
  } 
  catch (Exception e) {
    JOptionPane.showMessageDialog(null, 
      "Chyba připojení k: " + selected, 
      "Chyba", 
      JOptionPane.ERROR_MESSAGE);
    exit();
  }
}

void draw() {
  if (!portSelected) {
    // Zobrazení úvodní obrazovky
    background(bgColor);
    if (logo != null) {
      image(logo, width/2, height/2);
    }
    fill(textColor);
    textAlign(CENTER, CENTER);
    textSize(16);
    text("Načítání...", width/2, height/2 + 155);
    
    // Po pár snímcích zavolat výběr portu
    if (frameCount == 20) {
      selectSerialPort();
      portSelected = true;
    }
  } else {
    // Normální provoz
    background(bgColor);
    
    drawHeader();
    
    switch (currentMode) {
      case MODE_MENU:
        drawMenu();
        break;
      case MODE_TRANSMIT:
        drawTransmit();
        break;
      case MODE_TRAINER:
        drawTrainer();
        break;
      case MODE_INFO:
        drawInfo();
        break;
    }
    
    drawStatusBar();
  }
}

void drawHeader() {
  fill(accentColor);
  textSize(32);
  textAlign(CENTER, TOP);
  text("CW TRAINER", width/2, 20);
  
  fill(textColor);
  textSize(16);
  textAlign(RIGHT, TOP);
  text("WPM: " + wpm + " (↑/↓)", width - 20, 20);
  
  stroke(dimColor);
  strokeWeight(2);
  line(50, 70, width - 50, 70);
}

void drawMenu() {
  textAlign(CENTER, CENTER);
  
  // Výběr typu klíče
  fill(dimColor);
  textSize(18);
  text("Typ klíče:", width/2, 120);
  
  float keyBtnW = 180;
  float keyBtnH = 60;
  float keyBtnY = 160;
  
  // Button - KLASICKÝ KLÍČ
  float straightX = width/2 - keyBtnW - 20;
  boolean hoverStraight = mouseX > straightX && mouseX < straightX + keyBtnW && 
                          mouseY > keyBtnY && mouseY < keyBtnY + keyBtnH;
  
  fill(
  keyType == KEY_STRAIGHT ? color(40,60,40) :
  hoverStraight ? color(40,50,40) :
  color(30,40,30)
  );

  stroke(
  keyType == KEY_STRAIGHT ? accentColor :
  hoverStraight ? accentColor :
  textColor
  );

  strokeWeight(keyType == KEY_STRAIGHT ? 3 : 2);
  
  
  
  rect(straightX, keyBtnY, keyBtnW, keyBtnH, 8);
  
  fill(keyType == KEY_STRAIGHT ? accentColor : textColor);
  textSize(20);
  text("KLASICKÝ", straightX + keyBtnW/2, keyBtnY + keyBtnH/2);
  
  // Button - DVOUPÁDLOVÝ KLÍČ
  float paddleX = width/2 + 20;
  boolean hoverPaddle = mouseX > paddleX && mouseX < paddleX + keyBtnW && 
                        mouseY > keyBtnY && mouseY < keyBtnY + keyBtnH;
  
  fill(
  keyType == KEY_PADDLE ? color(40,60,40) :
  hoverPaddle ? color(40,50,40) :
  color(30,40,30)
  );

  stroke(
  keyType == KEY_PADDLE ? accentColor :
  hoverPaddle ? accentColor :
  textColor
  );

  strokeWeight(keyType == KEY_PADDLE ? 3 : 2);
  
  
  rect(paddleX, keyBtnY, keyBtnW, keyBtnH, 8);
  
  fill(keyType == KEY_PADDLE ? accentColor : textColor);
  textSize(20);
  text("DVOUPÁDLOVÝ", paddleX + keyBtnW/2, keyBtnY + keyBtnH/2);
  
  // Hlavní menu buttony
  float btnW = 300;
  float btnH = 100;
  
  // Button 1 - VYSÍLÁNÍ
  float btn1X = width/2 - btnW/2;
  float btn1Y = 280;
  
  boolean hover1 = mouseX > btn1X && mouseX < btn1X + btnW && 
                   mouseY > btn1Y && mouseY < btn1Y + btnH;
  
  fill(hover1 ? color(40, 60, 40) : color(30, 40, 30));
  stroke(hover1 ? accentColor : textColor);
  strokeWeight(3);
  rect(btn1X, btn1Y, btnW, btnH, 10);
  
  fill(textColor);
  textSize(26);
  text("VYSÍLÁNÍ", btn1X + btnW/2, btn1Y + btnH/2 - 12);
  fill(dimColor);
  textSize(14);
  text("Odeslání textu", btn1X + btnW/2, btn1Y + btnH/2 + 18);
  
  // Button 2 - TRAINER
  float btn2X = width/2 - btnW/2;
  float btn2Y = 410;
  
  boolean hover2 = mouseX > btn2X && mouseX < btn2X + btnW && 
                   mouseY > btn2Y && mouseY < btn2Y + btnH;
  
  fill(hover2 ? color(40, 60, 40) : color(30, 40, 30));
  stroke(hover2 ? accentColor : textColor);
  strokeWeight(3);
  rect(btn2X, btn2Y, btnW, btnH, 10);
  
  fill(textColor);
  textSize(26);
  text("TRAINER", btn2X + btnW/2, btn2Y + btnH/2 - 12);
  fill(dimColor);
  textSize(14);
  text("Trénink příjmu", btn2X + btnW/2, btn2Y + btnH/2 + 18);
  
  // Button INFO
  float infoBtnW = 100;
  float infoBtnH = 50;
  float infoBtnX = width - infoBtnW - 20;
  float infoBtnY = height - infoBtnH - 60;
  
  boolean hoverInfo = mouseX > infoBtnX && mouseX < infoBtnX + infoBtnW && 
                      mouseY > infoBtnY && mouseY < infoBtnY + infoBtnH;
  
  fill(hoverInfo ? color(40, 60, 40) : color(30, 40, 30));
  stroke(hoverInfo ? accentColor : textColor);
  strokeWeight(2);
  rect(infoBtnX, infoBtnY, infoBtnW, infoBtnH, 8);
  
  fill(textColor);
  textSize(18);
  text("INFO", infoBtnX + infoBtnW/2, infoBtnY + infoBtnH/2);
}

void drawInfo() {
  textAlign(CENTER, CENTER);
  
  // Logo
  if (logo != null) {  
    logo.resize(355, 0);
    image(logo, width/2 , 220);
  }
  
  
  // Autor
  fill(textColor);
  textSize(22);
  text("Autor: Pavel Březina - OK1BRE - pavel.brez@gmail.com", width/2, 90);
  // Popis
  fill(textColor);
  textSize(16);
  textAlign(CENTER, CENTER);
  String popis = "CW Trainer je aplikace pro výuku a trénink\n" +
                 "morse kódu (CW). Podporuje klasický i dvoupádlový\n" +
                 "klíč s nastavitelnou rychlostí WPM.\n\n" +
                 "Režim VYSÍLÁNÍ umožňuje odesílat text\n" +
                 "a používat paměťová tlačítka.\n\n" +
                 "Režim TRAINER trénuje příjem pomocí\n" +
                 "generovaných volacích značek.\n"+
                 "73 - OK1BRE";
  
  text(popis, width/2, 430);
  
  // Návrat
  fill(dimColor);
  textSize(18);
  textAlign(CENTER, CENTER);
  text("ESC = zpět do menu", width/2, height - 60);
}

void drawTransmit() {
  textAlign(LEFT, TOP);
  textSize(20);
  
  fill(dimColor);
  text("Napište text a stiskněte ENTER:", 50, 100);
  
  fill(dimColor);
  textSize(14);
  text("ESC = menu", 700, 530);
  
  if (editingMemory == -1) {
    fill(30, 40, 30);
    stroke(textColor);
    strokeWeight(2);
    rect(50, 140, width - 100, 50, 5);
    
    fill(textColor);
    textSize(22);
    String displayInput = inputText + (frameCount % 60 < 30 ? "_" : "");
    text(displayInput, 60, 155);
  } else {
      fill(40, 35, 25);
      stroke(accentColor);
      strokeWeight(3);
      rect(50, 140, width - 100, 50, 5);
    
      fill(accentColor);
      textSize(22);
      String displayInput = editBuffer + (frameCount % 60 < 30 ? "_" : "");
      text("M" + (editingMemory + 1) + ": " + displayInput, 60, 155);
    }
  
  // Memory buttony
  fill(dimColor);
  textSize(16);
  text("Memory buttony -- levé tlačítko = vyslat | pravé tlačítko = edituj:", 50, 220);
  
  for (int i = 0; i < 4; i++) {
    float btnX = 50 + (i % 2) * 360;
    float btnY = 260 + (i / 2) * 80;
    float btnW = 330;
    float btnH = 60;
    
    boolean hover = mouseX > btnX && mouseX < btnX + btnW && 
                    mouseY > btnY && mouseY < btnY + btnH;
    
    fill(hover ? color(40, 50, 40) : color(30, 40, 30));
    stroke(editingMemory == i ? accentColor : textColor);
    strokeWeight(editingMemory == i ? 3 : 2);
    rect(btnX, btnY, btnW, btnH, 5);
    
    fill(textColor);
    textSize(14);
    textAlign(LEFT, CENTER);
    text("M" + (i + 1), btnX + 15, btnY + btnH/2 - 10);
    
    fill(editingMemory == i ? accentColor : textColor);
    textSize(18);
    text(memoryTexts[i], btnX + 15, btnY + btnH/2 + 12);
  }
  
  textAlign(LEFT, TOP);
  fill(dimColor);
  textSize(16);
  text("Naposledy odesláno:", 50, 420);
  fill(accentColor);
  textSize(20);
  text(lastSent, 50, 450);
  
  fill(dimColor);
  textSize(16);
  text("Přijato z klíče:", 50, 490);
  fill(textColor);
  textSize(20);
  text(receivedText, 50, 520);
}

void drawTrainer() {
  textAlign(CENTER, CENTER);
  
  fill(accentColor);
  textSize(18);
  textAlign(LEFT, TOP);
  text("Skóre: " + score + " / " + attempts, 50, 100);
  
  textAlign(CENTER, CENTER);
  fill(dimColor);
  textSize(16);
  text("Aktuální volačka:", width/2, 180);
  
  fill(textColor);
  textSize(48);
  if (hideCallsign) {
    text("XXXXXX", width/2, 240);
  } else {
    text(formatForDisplay(currentCallsign), width/2, 240);
  }
    
  if (waitingForAnswer) {
    fill(accentColor);
    textSize(20);
    text(">>> ...čekám na vaši odpověď... <<<", width/2, 320);
  }
  
  fill(dimColor);
  textSize(16);
  text("Vaše odpověď:", width/2, 380);
  
  fill(textColor);
  textSize(32);
  text(receivedText, width/2, 430);
  
  fill(dimColor);
  textSize(14);
  text("SPACE = nová volačka | R = opakovat | ESC = menu", width/2, 520);
 
   // Tlačítko UKÁZAT / SCHOVAT
  float btnW = 200;
  float btnH = 50;
  float btnX = width/2 - btnW/2;
  float btnY = 85;

  boolean hover = mouseX > btnX && mouseX < btnX + btnW &&
                  mouseY > btnY && mouseY < btnY + btnH;
  
  fill(hover ? color(40, 60, 40) : color(30, 40, 30));
  stroke(hover ? accentColor : textColor);
  strokeWeight(3);
  rect(btnX, btnY, btnW, btnH, 8);

  fill(textColor);
  textSize(18);
  textAlign(CENTER, CENTER);
  text(hideCallsign ? "UKÁZAT" : "SCHOVAT", btnX + btnW/2, btnY + btnH/2); 
}

  String formatForDisplay(String cs) {
    if (cs.endsWith("QRP")) {
      return cs.substring(0, cs.length() - 3) + " QRP";
    }
    return cs;
  }

void drawStatusBar() {
  fill(30, 35, 30);
  noStroke();
  rect(0, height - 40, width, 40);
  
  fill(textColor);
  textSize(14);
  textAlign(LEFT, CENTER);
  
  String displayStatus = statusText;

  if (currentMode == MODE_TRAINER && hideCallsign) {
    displayStatus = displayStatus.replace(currentCallsign, "XXXXXX");
  }

  text(displayStatus, 20, height - 20);
  
  textAlign(CENTER, CENTER);
  String keyTypeText = keyType == KEY_STRAIGHT ? "KLASICKÝ KLÍČ" : "DVOUPÁDLOVÝ KLÍČ";
  fill(accentColor);
  text(keyTypeText, 550, height - 20);
  
  textAlign(RIGHT, CENTER);
  String modeText = "";
  switch (currentMode) {
    case MODE_MENU: modeText = "MENU"; break;
    case MODE_TRANSMIT: modeText = "VYSÍLÁNÍ"; break;
    case MODE_TRAINER: modeText = "TRAINER"; break;
    case MODE_INFO: modeText = "INFO"; break;
  }
  fill(textColor);
  text("Režim: " + modeText, width - 20, height - 20);
}

void mousePressed() {
  if (currentMode == MODE_MENU) {
    float keyBtnW = 180;
    float keyBtnH = 60;
    float keyBtnY = 160;
    
    // Výběr typu klíče - KLASICKÝ
    float straightX = width/2 - keyBtnW - 20;
    if (mouseX > straightX && mouseX < straightX + keyBtnW && 
        mouseY > keyBtnY && mouseY < keyBtnY + keyBtnH) {
      keyType = KEY_STRAIGHT;
      sendCommand("KEYTYPE:" + keyType);
      statusText = "Nastaven klasický klíč";
    }
    
    // Výběr typu klíče - DVOUPÁDLOVÝ
    float paddleX = width/2 + 20;
    if (mouseX > paddleX && mouseX < paddleX + keyBtnW && 
        mouseY > keyBtnY && mouseY < keyBtnY + keyBtnH) {
      keyType = KEY_PADDLE;
      sendCommand("KEYTYPE:" + keyType);
      statusText = "Nastaven dvoupádlový klíč";
    }
    
    float btnW = 300;
    float btnH = 100;
    
    // Button 1 - VYSÍLÁNÍ
    float btn1X = width/2 - btnW/2;
    float btn1Y = 280;
    
    if (mouseX > btn1X && mouseX < btn1X + btnW && 
        mouseY > btn1Y && mouseY < btn1Y + btnH) {
      currentMode = MODE_TRANSMIT;
      inputText = "";
      receivedText = "";
      sendCommand("CLEAR");
      editingMemory = -1;
      statusText = "Režim vysílání";
      return;
    }
    
    // Button 2 - TRAINER
    float btn2X = width/2 - btnW/2;
    float btn2Y = 410;
    
    if (mouseX > btn2X && mouseX < btn2X + btnW && 
        mouseY > btn2Y && mouseY < btn2Y + btnH) {
      currentMode = MODE_TRAINER;
      score = 0;
      attempts = 0;
      receivedText = "";
      generateCallsign();
      statusText = "Režim trainer";
      return;
    }
    
    // Button INFO
    float infoBtnW = 100;
    float infoBtnH = 50;
    float infoBtnX = width - infoBtnW - 20;
    float infoBtnY = height - infoBtnH - 60;
    
    if (mouseX > infoBtnX && mouseX < infoBtnX + infoBtnW && 
        mouseY > infoBtnY && mouseY < infoBtnY + infoBtnH) {
      currentMode = MODE_INFO;
      statusText = "O programu";
      return;
    }
  }
  
  if (currentMode == MODE_TRANSMIT) {
    for (int i = 0; i < 4; i++) {
      float btnX = 50 + (i % 2) * 360;
      float btnY = 260 + (i / 2) * 80;
      float btnW = 330;
      float btnH = 60;
      
      if (mouseX > btnX && mouseX < btnX + btnW && 
          mouseY > btnY && mouseY < btnY + btnH) {
        
        if (mouseButton == RIGHT) {
          editingMemory = i;
          editBuffer = memoryTexts[i];
          statusText = "Editace M" + (i + 1) + " - ENTER = uložit, ESC = zrušit";
        } else {
          if (editingMemory == -1) {
            sendCommand("TX:" + memoryTexts[i].toUpperCase());
            lastSent = memoryTexts[i].toUpperCase();
            statusText = "Odesílám M" + (i + 1) + ": " + lastSent;
          }
        }
      }
    }
  }
  
  if (currentMode == MODE_TRAINER) {
    float btnW = 200;
    float btnH = 50;
    float btnX = width/2 - btnW/2;
    float btnY = 85;

    if (mouseX > btnX && mouseX < btnX + btnW &&
        mouseY > btnY && mouseY < btnY + btnH) {
      hideCallsign = !hideCallsign;
    }
  } 
}

void keyPressed() {
  if (keyCode == UP) {
    wpm = min(40, wpm + 1);
    sendCommand("WPM:" + wpm);
    return;
  }
  if (keyCode == DOWN) {
    wpm = max(5, wpm - 1);
    sendCommand("WPM:" + wpm);
    return;
  }
  
  if (keyCode == ESC) {
    key = 0;
    if (currentMode == MODE_INFO) {
      currentMode = MODE_MENU;
      statusText = "Hlavní menu";
      return;
    }
    if (editingMemory != -1) {
      editingMemory = -1;
      editBuffer = "";
      statusText = "Editace zrušena";
    } else {
      currentMode = MODE_MENU;
      inputText = "";
      receivedText = "";
      statusText = "Hlavní menu";
    }
    return;
  }
  
  if (currentMode == MODE_TRANSMIT) {
    if (editingMemory != -1) {
      if (key == ENTER || key == RETURN) {
        memoryTexts[editingMemory] = editBuffer;
        statusText = "M" + (editingMemory + 1) + " uloženo: " + editBuffer;
        editingMemory = -1;
        editBuffer = "";
      }
      else if (key == BACKSPACE) {
        if (editBuffer.length() > 0) {
          editBuffer = editBuffer.substring(0, editBuffer.length() - 1);
        }
      }
      else if (key >= ' ' && key <= '~') {
        editBuffer += key;
      }
    } else {
      if (key == ENTER || key == RETURN) {
        if (inputText.length() > 0) {
          sendCommand("TX:" + inputText.toUpperCase());
          lastSent = inputText.toUpperCase();
          statusText = "Odesílám: " + lastSent;
          inputText = "";
        }
      }
      else if (key == BACKSPACE) {
        if (inputText.length() > 0) {
          inputText = inputText.substring(0, inputText.length() - 1);
        }
      }
      else if (key >= ' ' && key <= '~') {
        inputText += key;
      }
    }
    return;
  }
  
  if (currentMode == MODE_TRAINER) {
    if (key == ' ' && waitingForAnswer == true) {
      waitingForAnswer = false;
      generateCallsign();
    }
    if (key == 'r' || key == 'R') {
      waitingForAnswer = false;
      String txCall = currentCallsign;
      if (txCall.endsWith("QRP")) {
          txCall = txCall.substring(0, txCall.length() - 3) + " QRP";
      }
      sendCommand("TX:" + txCall);
      statusText = "Opakuji: " + currentCallsign;
    }
    return;
  }
}

void generateCallsign() {
  waitingForAnswer = false;
  String prefix = prefixes[int(random(prefixes.length))];
  int num = int(random(10));
  String suffix = "";
  for (int i = 0; i < 3; i++) {
    suffix += char('A' + int(random(26)));
  }
  
  String baseCallsign = prefix + num + suffix;
  
  // Náhodné přidání /P, /M nebo zahraniční volání
  float rand = random(100);
  
  if (rand < 8) {
    // 8% šance na zahraniční volání (vždy s /P)
    String foreignPrefix;
    do {
      foreignPrefix = prefixes[int(random(prefixes.length))];
    } while (foreignPrefix.equals(prefix)); // Ochrana proti stejnému prefixu
    currentCallsign = foreignPrefix + "/" + baseCallsign + "/P";
  }
  else if (rand < 25) {
    // 17% šance na /P, /M nebo /QRP
    float suffixRand = random(1);
    if (suffixRand < 0.3) {
      currentCallsign = baseCallsign + "/P";
    } else if (suffixRand < 0.6) {
      currentCallsign = baseCallsign + "/M";
    } else {
      currentCallsign = baseCallsign + "QRP";
    }
  }
  else {
    // 75% běžná volačka
    currentCallsign = baseCallsign;
  }
  
  receivedText = "";
  
  sendCommand("CLEAR");
  delay(100);
  waitingForAnswer = false;

  String txCall = currentCallsign;

  // pokud končí QRP, vlož mezeru před něj
  if (txCall.endsWith("QRP")) {
    txCall = txCall.substring(0, txCall.length() - 3) + " QRP";
  }

  sendCommand("TX:" + txCall);

  statusText = "Vysílám: " + txCall;
  }

void checkAnswerLive() {
  String answer = receivedText.trim().toUpperCase();
  String expected = currentCallsign.toUpperCase();
  
  if (!expected.startsWith(answer)) {
    attempts++;
    statusText = "✗ CHYBA! Očekáváno: " + expected + " | Přijato: " + answer;
    waitingForAnswer = false;
    receivedText = "";
    sendCommand("CLEAR");
    delay(2000);
    // TX s mezerou pro Arduino, interní vyhodnocení beze změny
    String txCall = currentCallsign;
    if (txCall.endsWith("QRP")) {
      txCall = txCall.substring(0, txCall.length()-3) + " QRP";
    }
    sendCommand("TX:" + txCall);
  }
  else if (answer.equals(expected)) {
    score++;
    attempts++;
    statusText = "✓ SPRÁVNĚ! " + answer + " | Skóre: " + score + "/" + attempts;
    waitingForAnswer = false;
    
    if (hideCallsign == true) {
         hideCallsign = false;
         delay (2000);
         hideCallsign = true;
     } else {
        delay(2000);
        hideCallsign = false;
      }   
     
    receivedText = "";
    generateCallsign();
  }
}

void sendCommand(String cmd) {
  if (arduino != null) {
    arduino.write(cmd + "\n");
    println(">>> " + cmd);
  }
}

void serialEvent(Serial port) {
  String data = port.readStringUntil('\n');
  if (data != null) {
    data = data.trim();
    println("<<< " + data);
    
    if (data.startsWith("CHAR:")) {
      String newChar = data.substring(5);
      receivedText += newChar;
      
      if (currentMode == MODE_TRANSMIT && receivedText.length() > 15) {
        receivedText = "";
        sendCommand("CLEAR");
      }
      
      if (currentMode == MODE_TRAINER && waitingForAnswer) {
        checkAnswerLive();
      }
    }
    else if (data.startsWith("OK:")) {
      String cmd = data.substring(3);
      if (cmd.equals("TX")) {
        statusText = "Odesláno!";
        receivedText = "";
        waitingForAnswer = true;
      }
    }
  }
}

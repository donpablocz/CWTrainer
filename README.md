  OK1BRE CW TRAINER

  Author: OK1BRE Version: 1.0 Description: Morse CW Trainer for radio amateurs and enthusiasts :)

  ---------
  1. INTRODUCTION
  ---------

  OK1BRE CW Trainer is an application created in Processing, designed for training
  Morse code (CW) using a real key connected to an Arduino device.

  The program allows:
  - Text transmission
  - Reception training
  - Memory buttons
  - WPM settings
  - Key type selection
  - Success statistics
  - Connection to a station

  -------------
  2. HARDWARE
  -------------

  Required components:
  - Arduino (Uno / Nano)
  - 2x 1Kohm resistor
  - 2x NPN transistor (BC548)
  - Morse key (straight key or paddle)
  - Speaker / buzzer
  - USB cable
  - 2x16 character LCD (not required)


  --------------
  3. INSTALLATION
  --------------

  1)  Install Arduino IDE
  - Connect the CW key to the input pins (2,3,GND)
  - Connect a small speaker to output pin 10 (pin 10, GND)
  - behind the transistors on pins 12, 13, and GND, you can connect a radio station to the KEY input, see diagram (not necessary)
  - you can connect LCD_I2C 2x16 lines to the I2C bus (not necessary, used for debugging:)
  - Add the WIRE.H and LiquidCrystal_I2C.H libraries to the Arduino IDE
  - Open the CWTRAINER.INO file in the Arduino IDE
  - Upload the firmware to the Arduino
  - Leave the Arduino connected to the PC.

  2) Install Processing (version 3 or 4)
  - Create a new folder, e.g.: CWTRAINER :)
  - Copy the LOGO_CWTRAINER.PNG and CWTRAINER.PDE files to this folder
  - Open the CWTRAINER.PDE file in Processing 4
  - Select File/Save
  - Run or compile the cwtrainer.exe version (place logo_cwtrainer.png in the folder with the .exe file)

  3) After launching
  - Select the COM port where your Arduino is connected. 
  - (Be careful not to open the port with another program, such as Arduino IDE. I recommend closing everything else :)


  --------------------
  4. PROGRAM MODES
  ----- ---------------

  MENU

  The main screen allows you to select a mode:

  -   TRANSMIT
  -   TRAINER
  -   INFO

  --------------------------------- ---------------------------
  TRANSMIT

  The program allows you to transmit a message entered using the keyboard,
  keys, or by selecting preset messages.

  Preset messages can be edited using the right mouse button
  and sent using the left mouse button.

  Display of characters transmitted by the key.

  Connection to the radio station is possible via the KEY station input. In the diagram a 
  BC548 transistor is used as the switching element. For complete separation it can be replaced for example with an optocoupler.
  The key selection must be set on the station.
  The program then transmits the specified message.
  
  WPM setting using the up/down arrows
  ESC - return to menu

  Connection to the transmitting station is at the user's own risk.
  The author is not responsible for any damage to the device.    

  ------------------------------------------------------------
  TRAINER

  The program generates a random call sign and automatically transmits it at the set speed (WPM).
  The operator's task is to correctly receive the call sign and then send it back using the key.

  Evaluation takes place character by character.

  The decoder does not evaluate spaces between characters or words as errors.
  Only the rhythm and correct structure of the currently transmitted character are evaluated 
  (the ratio of dots and dashes and their timing according to the set WPM).
  The recognition of dots and dashes is based on the length of the key press relative to the currently set WPM speed.

  If a character is transmitted incorrectly (incorrect rhythm or structure), reception is immediately interrupted and the original 
  generated call sign is retransmitted for repetition.

  Functions:

  SPACE – new call sign

  R – repeat call sign

  ESC – return to menu

  HIDE / SHOW button:
  Hides the call sign (XXXXXX) for realistic training without visual cues.
  
  ---------------
  5. RECOMMENDATIONS
  ---------------

  -   Use a real key to develop good habits.
  -   Train without visual cues.
  -   Gradually increase your WPM.
  -   Focus on the rhythm, not on individual dots and dashes.

  ---------------
  6. TECHNICAL NOTES
  ---------------

  - The program communicates with Arduino via a serial port (USB).
  - Arduino generates the tone and ensures station keying.
  - Processing provides the graphical interface and training logic.

  ------------
  7. LICENSE
  ------------

  The project was created as a practical aid for teaching and
  is open to further development.

  ------------------------------------------------------------------------

  OK1BRE --.../...-- :)) 

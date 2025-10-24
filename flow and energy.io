#define BLYNK_PRINT Serial

#define BLYNK_TEMPLATE_ID "TMPL3rQIg6Xpq"
#define BLYNK_TEMPLATE_NAME "EnergySaver"
#define BLYNK_AUTH_TOKEN "YgVBQ9U8QkyoZ4jsPX7CTFqf52GCik_a"


#include <WiFi.h>
#include <WiFiClient.h>
#include <BlynkSimpleEsp32.h>

volatile int flowPulseCount = 0;
int flowPin = 2; // Signal pin connected to GPIO2
float calibrationFactor = 450.0; // 450 pulses = 1 litre (approx)

float flowRate;
unsigned int flowMilliLitres;
unsigned long totalMilliLitres;
unsigned long oldTime = 0;

void IRAM_ATTR pulseCounter() {
  flowPulseCount++;
}



int sensorTA12 = 35; // Analog input pin that sensor is attached to

float nVPP;   // Voltage measured across resistor
float nCurrThruResistorPP; // Peak Current Measured Through Resistor
float nCurrThruResistorRMS; // RMS current through Resistor
float nCurrentThruWire;     // Actual RMS current in Wire



// Your WiFi credentials.
// Set password to "" for open networks.
char ssid[] = "Shemasri's phone";
char pass[] = "123456789";
#define s1 4
#define s2 5
int forward=1;
int backward=1;
void setup()
{
  // Debug console
  Serial.begin(9600);
pinMode(s1,OUTPUT);
pinMode(s2,OUTPUT);
digitalWrite(s1,1);
digitalWrite(s2,1);
pinMode(flowPin, INPUT_PULLUP);
  attachInterrupt(digitalPinToInterrupt(flowPin), pulseCounter, FALLING);
  Serial.println("Flow Sensor Test Started...");
  Blynk.begin(BLYNK_AUTH_TOKEN, ssid, pass);
}

BLYNK_CONNECTED(){
  Blynk.syncVirtual(V2);
  Blynk.syncVirtual(V3);
}
BLYNK_WRITE(V2){
  forward=param.asInt();
  Serial.print(forward);
}
BLYNK_WRITE(V3){
  backward=param.asInt();
  Serial.print(backward);
}
void loop()
{
  if(forward==0){
    digitalWrite(s1,0);
    Serial.println("s1 on");
  }
  if(forward==1){
    digitalWrite(s1,1);
    Serial.println("s1 off");
  }
   if(backward==0){
    digitalWrite(s2,0);
    Serial.println("s2 on");
  }
  if(backward==1){
    digitalWrite(s2,1);
    Serial.println("s2 off");
  }
///////////////////////////////////////////////////////////////////////////////////////////////////////
 nVPP = getVPP();
   
   /*
   Use Ohms law to calculate current across resistor
   and express in mA
   */
   
   nCurrThruResistorPP = (nVPP/200.0) * 1000.0;
   
   /*
   Use Formula for SINE wave to convert
   to RMS
   */
   
   nCurrThruResistorRMS = nCurrThruResistorPP * 0.707;
   
   /*
   Current Transformer Ratio is 1000:1...
   
   Therefore current through 200 ohm resistor
   is multiplied by 1000 to get input current
   */
   
///flow ///
if ((millis() - oldTime) > 1000) { // Every 1 second
    detachInterrupt(flowPin);

    flowRate = ((1000.0 / (millis() - oldTime)) * flowPulseCount) / calibrationFactor;
    oldTime = millis();

    flowMilliLitres = (flowRate / 60) * 1000;
    totalMilliLitres += flowMilliLitres;

    Serial.print("Flow rate: ");
    Serial.print(flowRate);
    Serial.print(" L/min | Total: ");
    Serial.print(totalMilliLitres );
    Serial.println(" L");

    flowPulseCount = 0;
    attachInterrupt(digitalPinToInterrupt(flowPin), pulseCounter, FALLING);

    Blynk.virtualWrite(V1,totalMilliLitres);

  }


//end flow///
   nCurrentThruWire = nCurrThruResistorRMS * 1000;

   
   Serial.print("Volts Peak : ");
   Serial.println(nVPP,3);
 
   
   Serial.print("Current Through Resistor (Peak) : ");
   Serial.print(nCurrThruResistorPP,3);
   Serial.println(" mA Peak to Peak");
   
   Serial.print("Current Through Resistor (RMS) : ");
   Serial.print(nCurrThruResistorRMS,3);
   Serial.println(" mA RMS");
   
   Serial.print("Current Through Wire : ");
   Serial.print(nCurrentThruWire,3);
   Serial.println(" mA RMS");
   
   Serial.println();
//float y = (m*nCurrentThruWire)+c;



if(totalMilliLitres>50)

{
 Blynk.logEvent("alert","water flow high");

}
 
 
     if(nCurrentThruWire>1800)

   {
   
    Blynk.virtualWrite(V0,nCurrThruResistorRMS);
    //Blynk.virtualWrite(V1,(nCurrentThruWire));
    Blynk.logEvent("alert","high current ALERT");
 
    }
    else
    {
      //Blynk.virtualWrite(V1,(nCurrentThruWire));
      Blynk.virtualWrite(V0,nCurrThruResistorRMS);

      }















































  Blynk.run();
}
float getVPP()
{
  float result;
  int readValue;             //value read from the sensor
  int maxValue = 0;          // store max value here
   uint32_t start_time = millis();
   while((millis()-start_time) < 1000) //sample for 1 Sec
   {
       readValue = analogRead(sensorTA12);
       // see if you have a new maxValue
       if (readValue > maxValue)
       {
           /*record the maximum sensor value*/
           maxValue = readValue;
       }
   }
   // Convert the digital data to a voltage
   result = (maxValue * 5.0)/1024.0;
  Serial.println(maxValue);
   return result;
}

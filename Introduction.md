Connecting Arduino Prototyping board to Adobe AIR through an AIR Native Extension.  Available for Windows and MacOSX.

# AIR Native Extensions #
AIR Native Extensions, or ANEs are compiled code that includes both Native code (specific code for Windows, Mac, or one of the many mobile platforms) and ActionScript code that allows developers to extend the feature set that is available in AIR or the Flash Player.

This ANE exposes the Serial port that is created by the Arduino Uno, Arduino LilyPad, Arduino Mega, Arduino Duemilanove and various other Arduino Compatibles.  It can also be used with any device that communicates via a serial port (COM port).

## Background ##
The ArduinoConnector mimics the _flash.net.Socket_ class that is internal to the Flex Framework.  It was chosen to mimic this class because many of the more popular Arduino projects target the Socket class because they use serProxy to transport the data to the serial port.

## Use ##
Instruct your IDE to include the ANE that you downloaded from the Downloads tab.  In Flash Builder 4.6+, right click on your project, go to the Flash Builder Path properties, click on the Native Extensions tab, and add the ANE.

Next, add a new ArduinoConnector instance.  You will need to pass the COM port that the Arduino is connected to, along with the baud rate to the `connect()` function (as3Glue uses 57600,  most Arduino samples use 9600).  You can get a list of valid COM ports for your operating system by taking in the `getComPorts()` array.  Also, add a function that will "dispose" or clean up the connection when you are finished (if you do not do this, the AIR runtime may crash when your app closes).
```
public var arduino:ArduinoConnector;
			
public function initApp():void
{
	arduino = new ArduinoConnector();
        arduino.connect("COM10",9600);
}

protected function closeApp(event:Event):void
{
	arduino.dispose();				
}
```

### Reading Data ###
When ArduinoConnector gets data from the serial port, it will fire an event that has the "socketData" signature.  When the event is fired, you can check the `bytesAvailable` variable to see how much data is in the buffer, and you can use one of the following functions to get data :
  * public function readBytesAsArray():Array
  * public function readBytesAsString():String
  * public function readBytesAsByteArray():ByteArray
  * public function readByte():uint
The buffer mirrors the UART, and holds at most 4046 bytes (4k) worth of data.  All the above functions will clear the buffer, with the exception of readByte(), which will only return the top byte from the buffer (FIFO order).

### Sending Data ###
Before sending data, make sure the port was successfully opened by checking the 'portOpen' variable.  If the port is not open, the write functions will fail and return false.  You can use the following functions to send data to the serial port :
  * public function writeByte(byte:uint):Boolean
  * public function writeString(stringToSend:String):Boolean
  * public function writeBytes(bytesToSend:ByteArray):Boolean
The functions will return TRUE if the data was successfully sent, and FALSE if there was an error sending the data.  The data is sent in another thread, but is virtually synchronous.  There is no send buffer, so there is no need to 'flush' the data.

## Using with as3Glue ##
as3Glue is the most popular library for people to deal with Arduinos.  It allows the developer to load the Firmata code onto their Arduino and control all the pins using AS3 rather than the embedded C that the Arduino uses natively.

Download either the SWC or Source Code from the Downloads section of this project for a patched version of as3Glue.  This patched version has the exact same interfaces as v20, with a notable exception of the constructor.  When you instantiate a new "Arduino" object, replace the IP address and port with the COM port and baud rate.  For example :

`public var myArduino:Arduino = new Arduino("COM10", 57600);`

You can find out more about as3Glue at http://code.google.com/p/as3Glue
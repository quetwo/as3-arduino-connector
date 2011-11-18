/*
* Version: MPL 1.1
*
* The contents of this file are subject to the Mozilla Public License Version
* 1.1 (the "License"); you may not use this file except in compliance with
* the License. You may obtain a copy of the License at
* http://www.mozilla.org/MPL/
*
* Software distributed under the License is distributed on an "AS IS" basis,
* WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
* for the specific language governing rights and limitations under the
* License.
*
* The Original Code is ArduinoConnector.as
*
* The Initial Developer of the Original Code is Nicholas Kwiatkowski.
* Portions created by the Initial Developer are Copyright (C) 2011
* the Initial Developer. All Rights Reserved.
*
*/

package com.quetwo.Arduino
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.StatusEvent;
	import flash.external.ExtensionContext;
	import flash.utils.ByteArray;
	
	[Event(name=GOT_DATA, type="com.quetwo.Arduino.ArduinoConnectorEvent")]
	public class ArduinoConnector extends EventDispatcher
	{
		
		public  const GOT_DATA:String = "eventGotData";
		private var   _ExtensionContext:ExtensionContext;
		private var   _comPort:Number;
		private var   _baud:Number;
		private var   _portOpen:Boolean = false;
		
		/**
		 * 
		 * The ArduinoConnector Constructor
		 * This is where you set the communications port and other settings.  If there is an issue opening up the communications port the portOpen property
		 * will be false.  You should check this before attempting to communicate with the Arduino.
		 * 
		 * @param comPort This is the communications port that the Arduino is connected to.  Call getComPorts() to get a valid list for this OS
		 * @param baud    This is the baud rate that the Arduino is connected at. 57600 is the default for the Firmata sketch.
		 * 
		 */
		public function ArduinoConnector(comPort:String, baud:Number=57600, target:IEventDispatcher=null)
		{
			var createComPortResult:Boolean;
			
			trace("[ArduinoConnector] Initalizing ANE...");
			_comPort = convertCOMString(comPort);
			_baud = baud;
			_ExtensionContext = ExtensionContext.createExtensionContext("com.quetwo.Arduino.ArduinoConnector", null);
			_ExtensionContext.addEventListener(StatusEvent.STATUS, gotEvent);
			createComPortResult = _ExtensionContext.call("setupPort", int(_comPort), int(_baud)) as Boolean;
			trace("[ArduinoConnector] Open COM Port", _comPort.toString(), "=",createComPortResult);
			_portOpen = createComPortResult;
		}
				
		/**
		 * 
		 * This will return if this ANE is supported on this platform. 
		 *  
		 * @return TRUE if the ANE is supported on this platform.  FALSE if the ANE is not supported.
		 * 
		 */
		public function isSupported():Boolean
		{
			return _ExtensionContext.call("isSupported"); 
		}
		
		/**
		 *
		 * This will return if the communication port has been initalized and is ready for use.
		 *  
		 * @return TRUE if the COM port is open and ready for use.  FALSE if there was a problem initalizing it.
		 * 
		 */
		public function get portOpen():Boolean
		{
			return _portOpen;
		}
		
		/**
		 *
		 * This funciton will return an array that represents what is in the buffer.  Additionally, calling this function will clear
		 * the serial buffer.
		 *  
		 * @return An Array that represents the bits in the buffer.  Each character in the buffer is its own array element
		 * 
		 */
		public function readBytesAsArray():Array
		{
			if (!_portOpen)
			{
				trace("[ArduinoConnector] COM Port is not open failure");
				return new Array();
			}
			return _ExtensionContext.call("getBytesAsArray") as Array;
		}
		
		/**
		 * 
		 * This function will return a string representation of what is in the serial buffer.  Additionally, calling this function will
		 * clear the serial buffer.
		 *  
		 * @return A String that represents the bits in the buffer.  Non-printable characters may not be represented. 
		 * 
		 */
		public function readBytesAsString():String
		{
			if (!_portOpen)
			{
				trace("[ArduinoConnector] COM Port is not open failure");
				return '';
			}
			return _ExtensionContext.call("getBytesAsString") as String;
		}
		
		/**
		 * 
		 * This function will return a ByteArray representation of what is in the serial buffer.  Additionally, calling this function will
		 * clear the serial buffer.  
		 *  
		 * @return A ByteArray that represents the bits in the buffer. 
		 * 
		 */
		public function readBytesAsByteArray():ByteArray
		{
			if (!_portOpen)
			{
				trace("[ArduinoConnector] COM Port is not open failure");
				return new ByteArray();
			}
			var ba:ByteArray = new ByteArray();
			_ExtensionContext.call("getBytesAsByteArray", ba);
			ba.position = 0;
			return ba;
		}

		
		/**
		 *
		 * This function will send the provided String to the serial port.  
		 *  
		 * @param stringToSend  The String that you wish to send to the Serial Port.
		 * @return  TRUE if the send was successful.  FALSE if there was an error sending the data.
		 * 
		 */
		public function sendString(stringToSend:String):Boolean
		{
			if (!_portOpen)
			{
				trace("[ArduinoConnector] COM Port is not open failure");
				return false;
			}
			return _ExtensionContext.call("sendString", stringToSend);
		}
		
		/**
		 *
		 * This function will send the contents of a ByteArray to the serial port.
		 *  
		 * @param bytesToSend  The ByteArray that you plan on sending to the serial port.  The position will be rewinded to 0.
		 * @return  TRUE if the send was successful.  FALSE if there was an error sending the data.
		 * 
		 */
		public function sendBytes(bytesToSend:ByteArray):Boolean
		{
			if (!_portOpen)
			{
				trace("[ArduinoConnector] COM Port is not open failure");
				return false;
			}
			bytesToSend.position = 0;
			return _ExtensionContext.call("sendByteArray", bytesToSend);
		}
		
		
		/**
		 *
		 * Call this function to close the COM port and clean up the ANE.  This MUST be called before the AIR application closes, 
		 * or the Operating System may throw an error.  If the COM port is not cleaned up properly, it may be locked from use of
		 * other applications.  Please, just run this before you exit your AIR app, or kittens may die. 
		 * 
		 */
		public function dispose():void
		{
			trace("[ArduinoConnector] Unloading ANE...");
			_ExtensionContext.dispose();
		}
		
		/**
		 * @private
		 * 
		 * This is the event that is fired by the DLL when there is new data in the buffer.
		 *  
		 * @param event Event Payload.
		 * 
		 */
		private function gotEvent(event:StatusEvent):void
		{
			trace("[ArduinoConnector] New data is in the buffer");
			var e:ArduinoConnectorEvent = new ArduinoConnectorEvent(GOT_DATA);
			dispatchEvent(e);
		}
		
		// **********************************************************************************
		//
		// BELOW IS WINDOWS SPECIFIC CODE.  YOU WILL NEED TO BUILD A LIB FOR OTHER PLATFORMS
		//
		// **********************************************************************************
		
		// What are void COM Port Numbers in Windows?  1->16.
		
		/**
		 *
		 * This function will return an array of valid COM ports for this operating system.  It will not necessarly provide valid
		 * COM ports for this machine, but what is valid for the OS in general.
		 *  
		 * @return An array of Strings containing the COM port names.
		 * 
		 */
		public function getComPorts():Array
		{
			var validComPorts:Array = new Array();
			validComPorts.push("COM1");
			validComPorts.push("COM2");
			validComPorts.push("COM3");
			validComPorts.push("COM4");
			validComPorts.push("COM5");
			validComPorts.push("COM6");
			validComPorts.push("COM7");
			validComPorts.push("COM8");
			validComPorts.push("COM9");
			validComPorts.push("COM10");
			validComPorts.push("COM11");
			validComPorts.push("COM12");
			validComPorts.push("COM13");
			validComPorts.push("COM14");
			validComPorts.push("COM15");
			validComPorts.push("COM16");
			return validComPorts;
		}
		
		// Find the COM port as a string that people know, and turn it into the file handler number
		// COM1 =0,  COM3 = 2, etc.
		private function convertCOMString(comString:String):Number
		{
			var myPort:Number = Number(comString.slice(3));
			return --myPort;
		}
		
	}
}
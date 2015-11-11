/**
 *
 * AXL Library
 * Copyright 2014-2015 Denis Aleksandrowicz. All Rights Reserved.
 *
 * This program is free software. You can redistribute and/or modify it
 * in accordance with the terms of the accompanying license agreement.
 *
 */
package axl.utils
{
	
	/**
	 * Setting properies in this class distributes it
	 * to <code>Ldr</code> and <code>ConnectPHP</code> classes
	 * to keep all in sync.
	 */
	public class NetworkSettings
	{
		private static var uAppRemoteAddresses:Array;
		private static var uGatewayPath:String;


		private static var uUpdateRequestObjectFactory:Function;
		public static var openConnectionTimeout:int;
		
		public static var smartStickToSuccess:Boolean;
		private static var uConfigPath:String;
		private static var addressIndex:int = 0;
		private static var numAddresses:int;
		
		private static var uInputProcessor:Function;
		private static var uOutputProcessor:Function;
		
		/** Defines default number of miliseconds after which request is being canceled if no server response is there. 
		 * <br>After timeout<code>onComplete</code> is executed with an Error of <code>errorID=10</code> as an argument.
		 *  @default 5000*/
		public static var defaultTimeout:int = 5000;
		
		/** 
		 * Sets the general address for the app. E.g. "http://yourapp.com" <br>
		 * Based on this, other elements are being formed:
		 * <ul><li>
		 *  <code>appRemoteAddress + gatewayPath</code> 
		 * - main address for ConncectPHP class to make POST requests to</li>
		 * <li><code>appRemoteAddress + configPath</code> - app config - file loaded, parsed 
		 * and assigned to U.CONFIG as a very first element of the app (Flow class flow) </li>
		 * <li>Its being added to <code>Ldr.defaultPathPrefixes</code> if standard Flow class is used</li></ul>
		 * <br><br>Approach of passing an array of addresses follows general concept of alternative directories.
		 * For more information about it see Ldr.load method description
		 * @param v - array of String(s)
		 * @see ConnectPHP
		 * @see Ldr#load
		*/
		public static function get appRemoteAddresses():Array {	return uAppRemoteAddresses	}
		public static function set appRemoteAddresses(v:Array):void
		{
			uAppRemoteAddresses = v;
		}
		
		/** Setup your default gateway address here. e.g.: <code>/gateway.php</code> and it
		 * will be sufixed to <code>appRemoteAddress</code> in oreder to form full address for ConnectPHP class.
		 * <br>Particular request can have different address - just pass it as an argument in <code>ConnectPHP.send^</code> methods. 
		 * @see NetworkSettings#appRemoteAddresses
		 * @see ConnectPHP#sendData */
		public static function get gatewayPath():String	{ return uGatewayPath }
		public static function set gatewayPath(value:String):void { uGatewayPath = value }
		
		/** If config path is set, there will be an attempt to load it and parse config as 
		 * a first flows asynchronous operation, before file loading. <br>Aside from fact,
		 * that loaded config will be available as <code>U.CONFIG</code>, parsing config reads
		 * five main properties: 
		 * <ul>
		 * <li><code>files</code> - files specified in config will be added to flow load list.</li>
		 * <li><code>date</code> - indicates when config/files has been updated last time. This is to be set manually.</li>
		 * <li><code>gatway</code> - updates remote gateway address - updates default ConnectPHP address</li>
		 * <li><code>remote</code> - updates remote app address used for Ldr and ConnectPHP classes fields</li>
		 * </ul>
		 * value will be updated and config will get re-saved on disc (air) if flow's update point is there.
		 * If it's not set, flow goes to next step which is files loading.
		 * it should be either full path or (preferable) sub-path similar to <code>/assets/config.cfg</code>
		 * as loading process usues <code>Ldr.defaultPathPrefixes</code> and behaviors.*/
		public static function get configPath():String	{ return uConfigPath }
		public static function set configPath(value:String):void { uConfigPath = value }
		
		
		/** (AIR) When config is loaded, flow can check for updates by sending post request to <code>appRemoteGateway
		 * </code> using <code>ConnectPHP.sendData</code> method. This function should return data argument (POST content).
		 * Returned object will be JSON.stringify and POST as 'update' variable. Response will be parsed, looking for json string.
		 * If response contains variable <code>files</code>, these files will be attempted to download and overwrite
		 * existing ones along with loading remaining. If no function is set, no launch update check will be mande.
		 * @see configPath
		 * @see Ldr#load
		 * @see ConnectPHP */
		public static function get filesUpdateRequestObjectFactory():Function { return uUpdateRequestObjectFactory }
		public static function set filesUpdateRequestObjectFactory(v:Function):void { uUpdateRequestObjectFactory = v }
		
		/** Default value for ConnectPHP.decryption @see axl.utils.ConnectPHP.decryption */
		public static function get inputProcessor():Function { return uInputProcessor }
		public static function set inputProcessor(v:Function):void { uInputProcessor = v }
		/** Default value for ConnectPHP.encryption @see axl.utils.ConnectPHP.encryption */
		public static function get outputProcessor():Function 	{ return uOutputProcessor }
		public static function set outputProcessor(v:Function):void { uOutputProcessor = v }
		
		public static function availableGatewayAddress(previousFailed:Boolean=false):String
		{
			if(!previousFailed)
				return appRemoteAddresses[addressIndex] + gatewayPath;
			else
			{
				if(++addressIndex >= numAddresses)
				{
					addressIndex = 0;
					return null;
				} else {
					return appRemoteAddresses[addressIndex] + gatewayPath;
				}
			}
		}
		
	}
}
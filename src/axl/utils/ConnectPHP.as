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
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.SharedObject;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	/**
	 * Quick and light class to communicate with your backend/server. 
	 * For most of the cases all you need is to use <code>sendData</code> method and <code>destroy</code> once you're done.
	 * <br><br>It also provides extra options like controlled order of requests (queue) and storing unsent requests on disc,
	 * but make sure you're understand its behaviour first (especially callbacks executions), 
	 * as improper use may cause lot of issues.
	 * @see #sendData
	 * @see #queueMember
	 * @see #storeUnsent
	 */
	public class ConnectPHP
	{
		private static var stored:SharedObject;
		private static var queue:Array = [];
		private static var cookieReaded:Boolean;
		private static var cookieAvailable:Boolean;
		private static var IS_BUSY:Boolean;
		private var urlreq:URLRequest = new URLRequest();
		private var loader:URLLoader = new URLLoader();
		private var urlvars:URLVariables;
		private var _onComplete:Function;
		private var _onProgress:Function;
		private var currentObject:Object;
		private var storeObject:Object;
		private var httpStatus:int;
		
		/** Clears currently queued elements @see #queueMember @see #storeUnsent */
		public static function clearQueue():void { queue.length = 0 }
		/** Clears unsent request stored on disc @see #queueMember @see #storeUnsent */
		public static function clearStored():void 
		{ 
			if(cookieAvailable)
			{
				stored.data.r.length  =0;
				try { stored.flush() } 
				catch(e:*) { U.log('[PHP][Unsent] flush error', e) }
			}
		}
		/** Clears both queued and stored requests @see #queueMember @see #storeUnsent */
		public static function clearUnsent():void
		{
			clearQueue();
			clearStored();
		}
		public  static var globalTimeout:int;
		
		/** Long responses can eat your log output. Limit it to *any* int to output only first *any* chars of it @default 200*/
		public static var limitLogResponeses:int = 200;
		
		/** Function to process output (json parsed string) with. Must return <code>String</code>
		 * If<code>null</code> then <code>NetworkSettings.inputProcessor</code> will be used. If both are <code>null</code>
		 * then plain jsoned string will be sent.<br><code>sendRaw</code> does not use encryption/decryption*/
		public var encryption:Function;
		/** Function to process input/response data with.
		 * If <code>null</code> then <code>NetworkSettings.inputProcessor</code> will be used. If both are <code>null</code>
		 * then plain response or JSON parsed plain response will be passed to <code>onComplete</code>
		 * <br><code>sendRaw</code> does not use encryption/decryption*/
		public var decryption:Function;
		
		/** Defines request specific number of miliseconds after which request is being canceled if no server response is there.
		 * <br>After timeout <code>onComplete</code> is executed with Error of <code>errorID=10</code> as an argument.<br>
		 * This applies to OPEN time, not entire loading/sending process. @default NetworkSettings.defaultTimeout */
		public var timeout:int;
		private var requestTimeout:uint;
		
		/** Name of the group variable that parsed objects will be assigned to. 
		 * <br>It would be your <code>$_POST['variable'] = yourJsonStringifiedData</code>
		 * This is equivalent of constructor passed <code>variable</code>.*/
		public var requestVariable:String;
		private var storedChecked:Boolean;
		
		/** Allows you to store your <code>sendData</code> request(s) that sending has failed (error, timeout, no connection).
		 * <br>All <code>sendData</code> method executions with <code>queueMember=true</code>
		 * are followed by attempt of sending any unsent requests first. Requests are stored on users disc as a <code>SharedObject</code>, so
		 * they will be processed even if app has been terminated and run again.
		 * <br>Use it when it is more important to notify your server than to retrieve its response, as
		 * stored (unsent) requests will execute its callbacks only within current app launch. 
		 * <br> Also, pay high attention to your callbacks, as stored unsent can be executed multiple times: few with errors
		 * (does not remove call from queue, unless you <code>destroy</code> object manually) 
		 * and then (e.g: connection comes back) another one with right response (removes it automatically).
		 * <br><b>Go</b>: statistics, feedback, send user settings. 
		 * <br><b>No go</b>: login, receive server settings.
		 * <br>Number of unsent requests available to store is limited to according to ActionScript
		 * <code>SharedObject</code> class rules.
		 * <br>Use <code>ConnectPHP.clearUnsent()</code> to remove all unsent requests. @default <code>false</code> 
		 * @see #queueMember @default false */
		public var storeUnsent:Boolean=false;
		/** Determines if call is queued and will be executed <b>after</b> currently proceeding/unsent calls (<code>true</code>
		 * triggers the queue). 
		 * <b>or</b> it's 'frivolous' mode (<code>false</code>) - attempt of POST request is made right after calling
		 *  <code>sendData</code>  
		 *  <br>Not a queueMember call can also be stored if <code>storeUnsent=true</code> <b>but</b> it will 
		 * become queue member on next app launch this way (if this was unsuccessful). Be careful and:
		 * @see #storeUnsent  @default false */
		public var queueMember:Boolean=false;
		
		
		public function ConnectPHP(variable:String='data') { requestVariable = variable }
		
		// ------------------------------------------ REGULAR  REQUESTS ---------------------------------- //	
		
		/** Sends binary POST request to <code>defaultAddress</code> or <code>address</code>. Upload files this way to 
		 * your prepared backend receiver.
		 * @param content binary data e.g.: encoded JPG or MP3. Preferably <code>ByteArray</code>
		 * @param onComplete function - must accept one argument: server response <code>Object</code> (JSON strings are parsed autumatically) or <code>Error</code> 
		 * if request was unsuccessful. Asign your own <code>onProgress</code> if you need to.
		 * @param GETParameters - parameters to attach to address. Object will be JSON.parse and encrypyted if specified, attached to 
		 * address as <code>variable</code> specified in constructor. e.g: <code>http://domain.com/receiver.php?<i>data</i>=<i>jsonParsedAndEncrypytedString</i></code>
		 * @param address - address to send POST request to. <code>defaultAddress</code> will be used if ommited*/
		public function sendRaw(content:Object,onComplete:Function=null, GETParameters:Object=null,address:String=null):void
		{
			_onComplete = onComplete || _onComplete;
			address = address || NetworkSettings.availableGatewayAddress();
			
			var parameters:String;
			if(GETParameters)
			{
				parameters = JSON.stringify(GETParameters);
				if(encryption is Function)
					parameters = encryption(parameters);
			}
			address += ((parameters!=null) ? ('?' + requestVariable + '=' + parameters) : '');
			
			urlreq.method = URLRequestMethod.POST;
			urlreq.contentType = "application/octet-stream";
			urlreq.data = content;
			urlreq.url=address;
			loader.dataFormat= URLLoaderDataFormat.BINARY;
			addListeners(loader);
			send();
			U.log("PHP>SEND_RAW_DATA>", urlreq.url);
		}
		
		/** Sends POST or GET request to <code>defaultAddress</code> or <code>address</code>.
		 * @param urlVarObject - object will be <code>JSON.stringify</code>, processed with <code>encryption</code> if specified
		 * and sent to <code>address</code> as <code>variable</code> specified in constructor. If urlVarObject is null - makes it GET request
		 * @param onComplete - function to execute once request is complete. 
		 * Should accept one argument: loaded data <code>Object</code> (JSON strings are parsed autumatically) or <code>Error</code> 
		 * if request was unsuccessful.
		 * @param address - address to send POST request to. <code>defaultAddress</code> will be used if ommited
		 * @param onProgress - Function which should accept two parameters:
		 * <ul><li><code>int - bytesLoaded</code></li>
		 * <li><code>int - bytesTotal </code></li></ul>*/
		public function sendData(urlVarObject:Object, onComplete:Function, address:String=null, onProgress:Function=null):void
		{	
			_onComplete = onComplete || _onComplete;
			_onProgress = onProgress || _onProgress;
			encryption = encryption || NetworkSettings.outputProcessor;
			decryption = decryption || NetworkSettings.inputProcessor;
			address = address || NetworkSettings.availableGatewayAddress();
			timeout = timeout || globalTimeout || NetworkSettings.defaultTimeout;
			
			var jsoned:String;
			var encrypted:String
			if(urlVarObject != null)
			{
				urlreq.method = URLRequestMethod.POST;
				loader.dataFormat = URLLoaderDataFormat.TEXT;
				jsoned = JSON.stringify(urlVarObject);
				encrypted = (encryption != null) ? encryption(jsoned) : jsoned; 
			}
			else
			{
				urlreq.method = URLRequestMethod.GET;
			}
				storeObject = { 
				v : requestVariable, 
				a : address, 
				c : encrypted, 
				t : timeout, 
				oc : _onComplete, 
				op : _onProgress,
				s : storeUnsent 
			};
			if(!cookieReaded) readCooke();
			addToCookie(storeObject); // it does check for store preferences
			
			if(!queueMember) //frivolous call
			{
				currentObject = storeObject;	
				sendCurrent();
			}
			else 
			{
				addQueueElement(storeObject);
				runQueue();
			}
		}
		
		public function sendFromPredefined(uloader:URLLoader, ureq:URLRequest, onComplete:Function, onProgress:Function=null):void
		{
			
			this.loader = uloader;
			this.urlreq = ureq;
			
			_onComplete = onComplete || _onComplete;
			_onProgress = onProgress || _onProgress;
			encryption = encryption || NetworkSettings.outputProcessor;
			decryption = decryption || NetworkSettings.inputProcessor;
			timeout = timeout || NetworkSettings.defaultTimeout;
			
			storeObject = { 
				v : null, 
				a : urlreq.url, 
				c : urlreq.data, 
				t : timeout, 
				oc : _onComplete, 
				op : _onProgress,
				s : false 
			};
			
			currentObject = storeObject;	
			addListeners(loader);
			if(timeout>0)
				requestTimeout = setTimeout(timeoutPassed, timeout);
			U.log("[PHP][Send]>>>>>>>>>>",uloader, '[timeout:', timeout + 'ms]\n');
			send();
		}
		
		private function completeHandler(e:Object):void 
		{
			U.log("[PHP][Complete]<<<<<<<<< response",urlreq.url);
			removeListeners(loader);
			clearTimeout(requestTimeout);
			if(e is Error)
			{
				U.log("[PHP][Complete]ERROR. next callback is null?\n", currentObject.c == null);
				IS_BUSY =false;
				if(currentObject.oc is Function)
					currentObject.oc(e);
				else 
					if(_onComplete is Function) _onComplete(e) 
				return;
			}
			
			U.log("[PHP][Complete] response is ", String(URLLoader(e.target).data).length , 'long');
			var decrypted:String = (decryption is Function) ? decryption(URLLoader(e.target).data) : URLLoader(e.target).data;
			var unjsoned:* = null;
			var i:int =decrypted.indexOf('['), j:int = decrypted.indexOf('{');
			var jsonIndex:int = -1;
			if(i>-1||j>-1)
				jsonIndex = (i>-1&&i<j) ? i : j;
			U.log("[PHP][Complete]decrypted:\n", decrypted.substr(0, limitLogResponeses) 
				+ (decrypted.length > limitLogResponeses ? '[...]' : ''),'jsonIndex:', jsonIndex);
			if(jsonIndex < 0)
			{
				if(currentObject.oc is Function)
					currentObject.oc(decrypted); // not a json response
			}
			else	
			{
				U.log('[PHP][Complete]type recognition: JSON');
				try { unjsoned = JSON.parse(decrypted.substr(jsonIndex)) }
				catch(e:Object)
				{
					U.log('[PHP][Complete] JSON PARSE ERROR, returning raw\n');
					currentObject.oc(decrypted);
				}
				if((unjsoned != null) && currentObject.oc != null)
					currentObject.oc(unjsoned);
				
			}
			removeFromCookie(currentObject);
			if(queueMember)
			{
				removeQueueElement(currentObject);
				nextElement();
			}
		}
		
		// ------------------------------------------ QUEUE PROCESS ---------------------------------- //
		private function readCooke():void
		{
			cookieReaded = true;
			try { 
				stored = SharedObject.getLocal('unsent');
				if(stored.data.r != null && stored.data.r is Array)
					queue = stored.data.r.concat();
				else
					stored.data.r = [];
				stored.flush();
				cookieAvailable = true;
			}
			catch(e:*) {cookieAvailable = false};
		}
		
		private function addQueueElement(obj:Object):void
		{
			queue.push(obj);
			U.log('[PHP][Queue][Add] queue:', queue.length);
		}
		
		private function addToCookie(obj:Object):void
		{
			if(cookieAvailable && (obj.s == true))
			{
				if(!(stored.data.r is Array))
					stored.data.r = [];
				stored.data.r.push(obj);
				try { stored.flush() } 
				catch(e:*) { U.log('[PHP][Unsent] flush error', e) }
			}
		}
		
		private function removeQueueElement(obj:Object):void
		{
			if(obj == null) return;
			var i:int = queue.indexOf(obj);
			if(i > -1) queue.splice(i,1);
			obj.v = obj.a = obj.t = obj.oc = obj.op = null;
			U.log('[PHP][Queue][Remove] queue:', queue.length);
		}
		
		private function removeFromCookie(obj:Object):void
		{
			if(cookieAvailable)
			{
				var i:int = stored.data.r.indexOf(obj);
				if(i>-1) stored.data.r.splice(i,1);
				try { stored.flush() } 
				catch(e:*) { U.log('[PHP][Unsent] flush error', e) }
			}
		}
		
		private function runQueue():void
		{
			if(IS_BUSY)
				U.log("[PHP][Queue] busy:", queue.length-1, 'requests ahead!');
			else
			{
				IS_BUSY = true;
				nextElement();
			}
		}
		
		private function nextElement():void
		{
			U.log("[PHP][Queue] Next element. remaining: ", queue.length);
			if(queue.length < 1)
			{
				IS_BUSY = false;
				return;
			}
			currentObject = queue[0];
			sendCurrent();
		}
		
		// ------------------------------------------ REQUESTS COMMON ---------------------------------- //
		private function sendCurrent():void
		{
			if(currentObject.c != null)
			{
				urlvars = new URLVariables();
				urlvars[currentObject.v] = currentObject.c;
				urlreq.data = urlvars;
			}
			
			urlreq.url = currentObject.a;
			addListeners(loader);
			if(currentObject.t>0)
				requestTimeout = setTimeout(timeoutPassed, currentObject.t);
			U.log("[PHP][Send]>>>>>>>>>>",urlreq.url, '[timeout:', currentObject.t + 'ms]\n'+currentObject.c);
			send();
		}
		
		private function send():void {	loader.load(urlreq) }
		private function timeoutPassed():void
		{
			U.log("[PHP][TIMEOUT]");
			cancel();
			onError(new Error("TIMEOUT- no response in " + timeout + 'ms',10));
		}
		
		private function openHandler(e:Event):void	{ clearTimeout(requestTimeout) }
		private function onError(e:Error):void
		{
			U.log("[PHP][Error]",e);
			clearTimeout(requestTimeout);
			var alternativeAddress:String = NetworkSettings.availableGatewayAddress(true);
			if(alternativeAddress != null)
			{
				if(currentObject.t>0)
					requestTimeout = setTimeout(timeoutPassed, currentObject.t);
				urlreq.url = alternativeAddress;
				U.log("[PHP][Send]>>>>>>>>>>",urlreq.url, '[timeout:', currentObject.t + 'ms]\n'+currentObject.c);
				send();
			} else {
				completeHandler(e);
			}
		}
		private function securityErrorHandler(e:SecurityErrorEvent):void { onError(new Error(e,11)) }
		private function ioErrorHandler(e:IOErrorEvent):void { onError(new Error(e,11)) }
		
		private function progressHandler(e:ProgressEvent):void {
			if(currentObject.op is Function) currentObject.op(e.bytesLoaded, e.bytesTotal)
		}
		private function httpStatusHandler(event:HTTPStatusEvent):void {
			httpStatus = event.status;
			U.log("[PHP] httpStatusHandler: " + httpStatus);
		}
		
		private function addListeners(dispatcher:IEventDispatcher):void 
		{
			dispatcher.addEventListener(Event.COMPLETE, completeHandler);
			dispatcher.addEventListener(Event.OPEN, openHandler);
			dispatcher.addEventListener(ProgressEvent.PROGRESS, progressHandler);
			dispatcher.addEventListener(HTTPStatusEvent.HTTP_STATUS, httpStatusHandler);
			dispatcher.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
			dispatcher.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
		}
		
		private function removeListeners(dispatcher:IEventDispatcher):void
		{
			dispatcher.removeEventListener(Event.COMPLETE, completeHandler);
			dispatcher.removeEventListener(Event.OPEN, openHandler);
			dispatcher.removeEventListener(ProgressEvent.PROGRESS, progressHandler);
			dispatcher.removeEventListener(HTTPStatusEvent.HTTP_STATUS, httpStatusHandler);
			dispatcher.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
			dispatcher.removeEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
		}
		
		/** Attemps to stop proceeding request. you can still use <code>send^</code> methods after cancel. */
		public function cancel():void
		{
			if(loader != null)
				try { loader.close() } catch(e:*) {};
			removeFromCookie(storeObject);
			removeQueueElement(storeObject);
			storeObject = null;		
		}
		
		public function get lastHttpStatus():int { return httpStatus }

		/** Removes internal and external listeners, removes it from queue and storage,
		 * clears loaded/sent data. It uses <code>cancel</code> too.
		 * Make sure you don't need loader data anymore.
		 * <br>All <code>send^</code> calls on this instance will throw an error once destroyed. Use <code>cancel</code>
		 * if you want to reuse this object.  @see #cancel 
		 * @param clearLoaderData determines if loader data should be cleared*/
		public function destroy(clearLoaderData:Boolean=false):void
		{
			_onComplete = _onProgress = null;
			cancel();
			urlvars = null;
			urlreq = null;
			if(loader != null)
			{
				removeListeners(loader);
				if(clearLoaderData && loader.data)
				{
					if(loader.dataFormat == URLLoaderDataFormat.BINARY)
						loader.data.clear();
					else loader.data = null;
				}
			}
			loader = null;
		}
	}
}
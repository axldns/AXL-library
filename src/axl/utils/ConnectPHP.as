package axl.utils 
{
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	
	public class ConnectPHP
	{
		/**Default function to process input/response with <b>if</b> particular instance's <code>decrypyion</code>
		 * property is not set.*/
		public static var defaultEncryption:Function;
		/**Default function to process output (json parsed string) with <b>if</b> particular instance's <code>encrypyion</code>
		 * property is not set. Must return <code>String</code>.*/
		public static var defaultDecryption:Function;
		
		/** Setup your API gateway address here. e.g.: <code>http://domain.com/gateway.php</code> for general requests.
		 * Particular request can have different address - just pass it as an argument in <code>send^</code> methods. */
		public static var defaultAddress:String;
		
		/** Long responses can eat your log output. Limit it to *any* int to output only first *any* chars of it
		 * @default 200*/
		public static var limitLogResponeses:int = 200;
		
		
		/** Defines default number of miliseconds after which request is being canceled if no server response is there. 
		 * <br>This does not apply to <code>sendRaw</code> method.
		 * <br>After timeout<code>onComplete</code> is executed with Error of <code>errorID=10</code> as an argument. @default 10000*/
		public static var defaultTimeout:int = 10000;
		
		private var urlvars:URLVariables = new URLVariables();
		private var urlreq:URLRequest = new URLRequest();
		private var loader:URLLoader = new URLLoader();
		
		private var orig_data:Object;
		
		private var _storeUnsuccessful:Boolean =true;
		private var _retryQueuedOnSuccess:Boolean=true;
		
		
		/** Function to execute once request is complete (after calling <code>send^</code> method.
		 * This is equivalent of <code>send^</code> methods <code>onComplete</code> arguments. */
		private var _onComplete:Function;
		
		/** Function which should accept two parameters:
		 * <ul><li><code>int - bytesLoaded</code></li>
		 * <li><code>int - bytesTotal </code></li></ul>
		 * Can be assigned anytime during loading/sending proccess. */
		public var onProgress:Function;
		
		/** Function to process output (json parsed string) with. Must return <code>String</code>
		 * If<code>null</code> then <code>defaultEncryption</code> will be used. If both are <code>null</code>
		 * then plain jsoned string will be sent.<br><code>sendRaw</code> does not use encryption/decryption*/
		public var encryption:Function;
		/** Function to process input/response data with. </code>
		 * If <code>null</code> then <code>defaultDecryption</code> will be used. If both are <code>null</code>
		 * then plain response or JSON parsed plain response will be passed to <code>onComplete</code>
		 * <br><code>sendRaw</code> does not use encryption/decryption*/
		public var decryption:Function;
		
		/** Defines request specific number of miliseconds after which request is being canceled if no server response is there.
		 * * <br>This does not apply to <code>sendRaw</code> method.
		 * <br>After timeout <code>onComplete</code> is executed with Error of <code>errorID=10</code> as an argument. @default 10000 */
		public var timeout:int;
		private var requestTimeout:uint;
		
		/** Name of the group variable that parsed objects will be assign to. 
		 * <br>It would be your <code>$_POST['variable'] = yourJsonStringifiedData</code>
		 * This is equivalent of constructor passed <code>variable</code>.*/
		public var requestVariable:String;

		public function ConnectPHP(variable:String='data') { requestVariable = variable }
		
		/** Sends binary POST request to <code>defaultAddress</code> or <code>address</code>. Upload files this way to 
		 * your prepared backend receiver.
		 * @param content - binary data e.g.: encoded JPG or MP3. Preferably <code>ByteArray</code>
		 * Should accept one argument: server response <code>Object</code> (JSON strings are parsed autumatically) or <code>Error</code> 
		 * if request was unsuccessful. Asign your own <code>onProgress</code> if you need to.
		 * @param GETParameters - parameters to attach to address. Object will be JSON.parse and encrypyted if specified, attached to 
		 * address as <code>variable</code> specified in constructor. e.g: <code>http://domain.com/receiver.php?<i>data</i>=<i>jsonParsedAndEncrypytedString</i></code>
		 * @param address - address to send POST request to. <code>defaultAddress</code> will be used if ommited*/
		public function sendRaw(content:Object,onComplete:Function=null, GETParameters:Object=null,address:String=null):void
		{
			_onComplete = onComplete || _onComplete;
			address = address || defaultAddress;
			
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
			
			this.addListeners(loader, completeHandler);
			send();
			U.log("PHP>SEND_RAW_DATA>", urlreq.url);
		}
		
		private function send():void {	loader.load(urlreq) }
		
		/** Sends POST request to <code>defaultAddress</code> or <code>address</code>.
		 * @param urlVarObject - object will be <code>JSON.stringify</code>, processed with <code>encryption</code> if specified
		 * and sent to <code>address</code> as <code>variable</code> specified in constructor.
		 * @param onComplete - function to execute once request is complete. 
		 * Should accept one argument: loaded data <code>Object</code> (JSON strings are parsed autumatically) or <code>Error</code> 
		 * if request was unsuccessful.
		 * @param address - address to send POST request to. <code>defaultAddress</code> will be used if ommited*/
		public function sendData(urlVarObject:Object, onComplete:Function, address:String=null):void
		{			
			orig_data = urlVarObject;
			
			_onComplete = onComplete || _onComplete;
			encryption = encryption || defaultEncryption;
			decryption = decryption || defaultDecryption;
			address = address || defaultAddress;
			timeout = timeout || defaultTimeout;
	
			var jsoned:String = JSON.stringify(urlVarObject);
			
			var encrypted:String = (encryption is Function) ? encryption(jsoned) : jsoned;
			
			urlvars[requestVariable] = encrypted; 
			urlreq.url = address;
			urlreq.method = URLRequestMethod.POST;
			urlreq.data = urlvars;
			loader.dataFormat = URLLoaderDataFormat.TEXT;
			
			this.addListeners(loader, completeHandler);
			if(timeout>0)
				requestTimeout = flash.utils.setTimeout(timeoutPassed, timeout);
			send();	
			U.log("[PHP] >>>>>>>>>>", urlreq.url, '\n', jsoned);
			jsoned = null;
			encrypted = null;
		}
		
		private function completeHandler(e:Event):void 
		{
			removeListeners(loader, completeHandler);
			clearTimeout(requestTimeout);
			
			U.log("[PHP] response is ", String(URLLoader(e.target).data).length , 'long');
			var decrypted:String = (decryption is Function) ? decryption(URLLoader(e.target).data) : URLLoader(e.target).data;
			var unjsoned:* = null;
			var jsonIndx:int = -1;
			var i:int =decrypted.indexOf('['), j:int = decrypted.indexOf('{');
			if(i > -1) jsonIndx = i;
			if((j > -1) && (j < jsonIndx)) jsonIndx = j;
			
			U.log("[PHP] <<<<<<<<<<", urlreq.url, '\n', decrypted.substr(0, limitLogResponeses) 
				+ (decrypted.length > limitLogResponeses ? '[...]' : ''));
			if(jsonIndx < 0)
			{
				if(_onComplete is Function)
					_onComplete(decrypted); // not a json response
			}
			else	
			{
				try { unjsoned = JSON.parse(decrypted.substr(jsonIndx)) }
				catch(e:Object)
				{
					U.log('JSON PARSE ERROR, returning raw\n',decrypted);
					_onComplete(decrypted);
				}
				if((unjsoned != null) && _onComplete is Function)
					_onComplete(unjsoned);
			}
			unjsoned = null;
			decrypted = null;
			_onComplete = null;
			e = null;
		}
		
		private function timeoutPassed():void
		{
			U.log("[PHP][TIMEOUT]");
			cancel();
			_onComplete(new Error("TIMEOUT- no response in " + timeout + 'ms',10));
		}
		
		/** Attemps to stop proceeding request */
		public function cancel():void
		{
			if(loader != null)
			{
				U.log('[PHP][Cancel]');
				try { loader.close() } 
				catch(e:*) {};
			}
		}
		
		private function onError(e:Error):void{
			clearTimeout(requestTimeout);
			if(_onComplete is Function) _onComplete(e)
		}
		private function securityErrorHandler(e:SecurityErrorEvent):void { onError(new Error(e,11)) }
		private function ioErrorHandler(e:IOErrorEvent):void { onError(new Error(e,11)) }
		
		private function progressHandler(e:ProgressEvent):void {
			if(onProgress is Function) onProgress(e.bytesLoaded, e.bytesTotal)
		}
		private function httpStatusHandler(event:HTTPStatusEvent):void {
			U.log("[PHP] httpStatusHandler: " + event);
		}
		
		public function addListeners(dispatcher:IEventDispatcher, complete:Function, progress:Function=null):void 
		{
			dispatcher.addEventListener(Event.COMPLETE, complete);
			(progress is Function) ? dispatcher.addEventListener(ProgressEvent.PROGRESS, progress) : null;
			dispatcher.addEventListener(HTTPStatusEvent.HTTP_STATUS, httpStatusHandler);
			dispatcher.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
			dispatcher.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
		}
		public function removeListeners(dispatcher:IEventDispatcher, complete:Function, progress:Function=null):void
		{
			dispatcher.removeEventListener(Event.COMPLETE, complete);
			(progress is Function) ? dispatcher.removeEventListener(ProgressEvent.PROGRESS, progress) :null;
			dispatcher.removeEventListener(HTTPStatusEvent.HTTP_STATUS, httpStatusHandler);
			dispatcher.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
			dispatcher.removeEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
		}

		/** Removes internal and external listeners, clears loaded/sent data. It uses <code>cancel</code> too.
		 * Make sure you don't need loader data anymore. */
		public function destroy():void
		{
			cancel();
			removeListeners(loader, completeHandler);
			urlvars = null;
			urlreq = null;
			if(loader && loader.data)
			{
				if(loader.dataFormat == URLLoaderDataFormat.BINARY)
					loader.data.clear();
				else loader.data = null;
			}
			loader = null;
			_onComplete = null;
		}
	}
}
package  axl.utils
{
	/**
	 * [axldns free coding 2015]
	 */
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.media.Sound;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.system.ImageDecodingPolicy;
	import flash.system.LoaderContext;
	import flash.utils.ByteArray;
	
	/**
	 * Core assets loader. Supports loading queues (arrays of paths). Keeps all objects. Access it via getMe();
	 */
	public class Ldr
	{
		
		public static const reg_SMARTEXT:RegExp = /(.*\/)(\w+)[.](\w*\z)/i;
		
		private static var objects:Object = {};
		private static var loaders:Object = {};
		private static var mQueue:Array = [];
		private static var alterQueue:Vector.<Function> = new Vector.<Function>();
		
	
		private static var _context:LoaderContext;
		private static var mCheckPolicyFile:Boolean;
		private static var IS_LOADING:Boolean;
	
		private static function get context():LoaderContext
		{
			if(!_context)
				_context = new LoaderContext(true, flash.system.ApplicationDomain.currentDomain);
			return _context;
		}
		
		/**
		 * returns current number of paths to load in queue
		 */
		public static function numQueue():int { return mQueue.length }
		
		/**
		 * tells you if any loading is in progress
		 */
		public static function get isLoading():Boolean 	{ return IS_LOADING || isNextQueueScheduled }
		
		/**
		 * If queue is loading array of paths synchroniously <code>loadQueueSynchro</code> and you call loadQueueSynchro once again with another array
		 * new array will be queued in separate queue. this tells you if there are any queues apart from current
		 */
		public static function get isNextQueueScheduled():Boolean {	return alterQueue.length > 0 }
		
		/**
		 * Main function to get resource reference.<br>
		 * Returns null / undefined if asset is not loaded or data as follows if loaded:<br>
		 * <ul>
		 * <li>flash.disply.DisplayObject / Bitmap for jpg, jpeg, png, gif</li>
		 * <li>flash.media.Sound for mp3</li>
		 * <li> ByteArray / UTF for any binary (xml, json, txt, atf, etc..)
		 * <ul>
		 * @param v : resource full name with extension but without address. 
		 * <br> Resource names are formed based on path you <code>addToQueue</code> 
		 * or passed directly to <code>loadQueueSynchro</code> array
		 * 
		 */
		public static function getme(v:String):Object
		{
			return objects[v];
		}
		/**
		 * adds path to load to current queue if does not exist
		 */
		public static function addToQueue(url:String):void
		{
			if(mQueue.indexOf(url) < 0)
				mQueue.push(url);
		}
		/**
		 * removes path to load from current queue if exists
		 */
		public static function removeFromQueue(url:String):void
		{
			var i:int = mQueue.indexOf(url);
			if(i > -1)
				mQueue.splice(i,1);
		}
		
		
		public static function loadQueueSynchro(vs:Array=null, onComplete:Function=null, individualComplete:Function=null,onProgress:Function=null):void
		{
			if(IS_LOADING)
			{
				alterQueue.push( function():void { loadQueueSynchro(vs,onComplete,individualComplete,onProgress) });
				return;
			}
			
			var extension:String;
			var url:String;
			var fulln:String;
			var shortn:String;
			var urlLoader:URLLoader;
			var loaderInfo:LoaderInfo;
			var numElements:int;
			if(vs)
				mQueue = mQueue.concat(vs);
			
			IS_LOADING = true;
			
			nextElement();
			function nextElement():void
			{
				numElements = mQueue.length;
				if(numElements < 1)
				{
					IS_LOADING = false;
					if(onComplete is Function)
						onComplete();
					if(isNextQueueScheduled)
						alterQueue.shift()();
					return;
				}
				url = mQueue.pop();
				
				extension	= url.replace(Ldr.reg_SMARTEXT, '$3');
				shortn		= url.replace(Ldr.reg_SMARTEXT, '$2');
				fulln 		= shortn + '.' + extension;
				if(objects[fulln] || loaders[fulln])
				{
					log("OBJECT ALREADY EXISTS: " + fulln + ' / ' + objects[fulln] + ' / ' +  loaders[fulln]);
					nextElement();
					return;
				}
				
				urlLoader = new URLLoader();
				loaders[fulln] = urlLoader;
				urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
				urlLoader.addEventListener(IOErrorEvent.IO_ERROR, onIoError);
				urlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
				urlLoader.addEventListener(HTTPStatusEvent.HTTP_STATUS, onHttpResponseStatus);
				urlLoader.addEventListener(ProgressEvent.PROGRESS, onLoadProgress);
				urlLoader.addEventListener(Event.COMPLETE, onUrlLoaderComplete);
				urlLoader.load(new URLRequest(url));
				
				function onIoError(event:IOErrorEvent):void
				{
					log("IO error: " + event.text);
					complete(null);
				}
				
				function onSecurityError(event:SecurityErrorEvent):void
				{
					log("security error: " + event.text);
					complete(null);
				}
				
				function onHttpResponseStatus(event:HTTPStatusEvent):void
				{
					if (extension == null)
					{
						var headers:Array = event["responseHeaders"];
						var contentType:String = getHttpHeader(headers, "Content-Type");
						
						if (contentType && /(audio|image)\//.exec(contentType))
							extension = contentType.split("/").pop();
					}
				}
				
				function onLoadProgress(event:ProgressEvent):void
				{
					if (onProgress != null && event.bytesTotal > 0)
						onProgress(event.bytesLoaded / event.bytesTotal, mQueue.length, fulln);
				}
				
				function onUrlLoaderComplete(event:Object):void //////////////////////////////////////////////////// URL COMPLETE
				{
					var bytes:ByteArray = transformData(urlLoader.data as ByteArray, url);
					var sound:Sound;
					
					switch (extension.toLowerCase())
					{
						case "mpeg":
						case "mp3":
							sound = new Sound();
							sound.loadCompressedDataFromByteArray(bytes, bytes.length);
							bytes.clear();
							complete(sound);
							break;
						case "jpg":
						case "jpeg":
						case "png":
						case "gif":
							var loaderContext:LoaderContext = new LoaderContext(mCheckPolicyFile);
							var loader:Loader = new Loader();
							loaderContext.imageDecodingPolicy = ImageDecodingPolicy.ON_LOAD;
							loaderInfo = loader.contentLoaderInfo;
							loaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onIoError);
							loaderInfo.addEventListener(Event.COMPLETE, onLoaderComplete);
							loader.loadBytes(bytes, loaderContext);
							break;
						default: // any XML / JSON / binary data 
							complete(bytes);
							break;
					}
				}
				
				function onLoaderComplete(event:Object):void
				{
					urlLoader.data.clear();
					complete(event.target.content);
				}
				
				function complete(asset:Object):void
				{
					// clean up event listeners
					objects[fulln] = asset;
					delete loaders[fulln];
					if (urlLoader)
					{
						urlLoader.removeEventListener(IOErrorEvent.IO_ERROR, onIoError);
						urlLoader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
						urlLoader.removeEventListener(HTTPStatusEvent.HTTP_STATUS, onHttpResponseStatus);
						urlLoader.removeEventListener(ProgressEvent.PROGRESS, onLoadProgress);
						urlLoader.removeEventListener(Event.COMPLETE, onUrlLoaderComplete);
					}
					
					if (loaderInfo)
					{
						loaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onIoError);
						loaderInfo.removeEventListener(Event.COMPLETE, onLoaderComplete);
						
					}
					
					if(individualComplete is Function)
						individualComplete(fulln);
					nextElement();
				}
			}
		}
		/** This method is called when raw byte data has been loaded from an URL or a file.
		 *  Override it to process the downloaded data in some way (e.g. decompression) or
		 *  to cache it on disk. */
		protected static function transformData(data:ByteArray, url:String):ByteArray
		{
			return data;
		}
		private static function getHttpHeader(headers:Array, headerName:String):String
		{
			if (headers)
			{
				for each (var header:Object in headers)
				if (header.name == headerName) return header.value;
			}
			return null;
		}
		
		private static function log(v:String):void
		{
			U.bin.trrace("LDR:", v);
		}
		
		
		/**
		 * Loads specific file upon request. It's being queued if loader is busy and will dispatch onComplete as soon as its ready to.
		 * 
		 * @param path : path to file
		 * @param onComplete : function which accepts one parameter. 1: Loaded object.
		 * @param onProgress (optional): function which acctpts 1 param. 1: Number(0-1)
		 */
		public static function load(path:String, onComplete:Function, onProgress:Function=null):void
		{
			Ldr.loadQueueSynchro([path],null,completer,(onProgress is Function) ? translateProgress : null);
			function translateProgress(single:Number, all:Number, nam:String):void
			{
				onProgress(single);
			}
			
			function completer(aname:String):void
			{
				onComplete(Ldr.getme(aname));
			}
		}
	}
	
}
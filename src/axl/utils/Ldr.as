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
	import flash.system.ImageDecodingPolicy;
	import flash.system.LoaderContext;
	import flash.utils.ByteArray;
	import flash.utils.getDefinitionByName;
	
	/**
	 * Core assets loader. Supports loading queues (arrays of paths) and alternative directories. Keeps all objects. Access it via getMe();
	 */
	public class Ldr
	{
		private static var objects:Object = {};
		private static var loaders:Object = {};
		private static var mQueue:Array = [];
		private static var alterQueue:Vector.<Function> = new Vector.<Function>();
		
		private static var IS_LOADING:Boolean;
		
		private static var _context:LoaderContext;
		private static var mCheckPolicyFile:Boolean;
		public static function get checkPolicyFile():Boolean { return mCheckPolicyFile; }
		public static function set checkPolicyFile(value:Boolean):void { mCheckPolicyFile = value }
		
		private static var locationPrefixes:Vector.<String> = new Vector.<String>();
		/**
		 * Alternative directories allow you to lookup for files to load in any number of directories in a single call.
		 *<br><br>
		 * Set up your alternativeDirPrefixes like <code>[File.applicationStorageDirectory,  File.applicationDirectory, "http://domain.com/app"]</code>
		 * to load <strong>/assets/example.file</strong> first from storage, if does not exist - check in <strong>app:/assets/example.fle</strong>, 
		 * if it's not there - try <strong>http://domain.com/app/example.file</strong>
		 * Highly recommended to unshift <code><i>root</i>.loaderInfo.url.substr(0,<i>root</i>.loaderInfo.url.lastIndexOf('/')</code> for web apps.
		 * <br>NOT THERE YET:
		 * <br>Combine it with <code>Ldr.loadBehaviours</code> to save (http|ftp) loaded files to <code>Ldr.saveDirectory</code> (AIR only)
		 * or to disable alternative directories checking at all. Unshift empty string to check original request first.
		 */
		public static function  get alternativeDirPrefixes():Vector.<String> { return locationPrefixes }
		
		/** @see Ldr # alternativeDirPrefixes() */
		public static function alternativeDirPrefixPush(path:String):void 
		{ 
			if(locationPrefixes.indexOf(path) < 0)
				locationPrefixes.push(path);
		}
		
		/** @see Ldr # alternativeDirPrefixes() */
		public static function alternativeDirPrefixUnshift(path:String):void 
		{ 
			if(locationPrefixes.indexOf(path) < 0)
				locationPrefixes.unshift(path);
		}
		
		/** @see Ldr # alternativeDirPrefixes() */
		public static function removeAlternativeDirPrefix(path:String):void
		{
			var i:int = locationPrefixes.indexOf(path);
			if(i > -1) locationPrefixes.splice(i,1);
		}
		
		/** returns current number of paths to load in <u>current</u>queue */
		public static function numQueue():int { return mQueue.length }
		
		 /** tells you if any loading is in progress */
		public static function get isLoading():Boolean 	{ return IS_LOADING || isNextQueueScheduled }
		
		/**
		 * If Loader is busy with loading something (file, list of files),  and you request to load something else before it finishes - your request is queued
		 * in separate queue. this tells you how many queues is queued apart from current queue
		 */
		public static function get isNextQueueScheduled():int {	return alterQueue.length }
		
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
		 */
		public static function getme(v:String):Object { return objects[v] }
		
		/** adds path to load to current queue if does not exist */
		public static function addToQueue(url:String):void
		{
			if(mQueue.indexOf(url) < 0)
				mQueue.push(url);
		}
		
		/**  removes path to load from current queue if exists */
		public static function removeFromQueue(url:String):void
		{
			var i:int = mQueue.indexOf(url);
			if(i > -1)
				mQueue.splice(i,1);
		}
		
		/**
		 * Loads all assets (unlike Starling assets manager) synchroniously from array of paths.
		 *
		 * @param array : array of paths (subpaths),
		 * @param onComplete : function of 0 arguments, dispatched once all elements are loaded
		 * @param onQueueProgress : function of  1 argument - name of asset available
		 * @return if busy with other loading - index on which this request is queued
		 */
		public static function loadQueueSynchro(pathsList:Array=null, onComplete:Function=null, individualComplete:Function=null,onProgress:Function=null):*
		{
			if(IS_LOADING)
				return alterQueue.push(function():void { loadQueueSynchro(pathsList,onComplete,individualComplete,onProgress) });
			
			var extension:String;
			var url:String;
			var fullname:String;
			var urlLoader:URLLoader;
			var loaderInfo:LoaderInfo;
			var numElements:int;
			var listeners:Array;
			var alternativePathIndex:int=-1;
			var numAlternativePaths:int = locationPrefixes.length;
			var originalUrl:String;
			var urlRequest:URLRequest;
			
			if(pathsList)
				mQueue = mQueue.concat(pathsList);
			
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
				
				if(alternativePathIndex < 0)
				{
					originalUrl = url.substr(0);
					var i:int = originalUrl.lastIndexOf("/") +1;
					var j:int = originalUrl.lastIndexOf("\\")+1;
					var k:int = originalUrl.lastIndexOf(".") +1;
					
					extension	= originalUrl.slice(k);
					fullname 	= originalUrl.slice(i>j?i:j);
				}
				
				if(objects[fullname] || loaders[fullname])
				{
					log("OBJECT ALREADY EXISTS: " + fullname + ' / ' + objects[fullname] + ' / ' +  loaders[fullname]);
					return nextElement();
				}
				urlLoader = new URLLoader();
				urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
				loaders[fullname] = urlLoader;
				
				listeners = [urlLoader, onError, onError, onHttpResponseStatus, onLoadProgress, onUrlLoaderComplete];
				addListeners.apply(null, listeners);
				
				urlRequest = new URLRequest(url);
				urlLoader.load(urlRequest);
				
				function onError(e:Event):void
				{
					log("error: " + e.toString());
					if(++alternativePathIndex < numAlternativePaths)
					{
						log('trying alternative [' +alternativePathIndex + '] : ' +  Ldr.locationPrefixes[alternativePathIndex]);
						var newPath:String =  getAlternativePath(Ldr.locationPrefixes[alternativePathIndex], originalUrl);
						mQueue.push(newPath);
						bothLoadersComplete(null,false);
					}
					else
					{
						log("no more alternatives");
						bothLoadersComplete(null);
					}
				}
				
				function onHttpResponseStatus(e:HTTPStatusEvent):void
				{
					if (extension == null)
					{
						var headers:Array = e["responseHeaders"];
						var contentType:String = getHttpHeader(headers, "Content-Type");
						
						if (contentType && /(audio|image)\//.exec(contentType))
							extension = contentType.split("/").pop();
					}
				}
				
				function onLoadProgress(e:ProgressEvent):void
				{
					if (onProgress is Function && e.bytesTotal > 0)
						onProgress(e.bytesLoaded / e.bytesTotal, mQueue.length, fullname);
				}
				
				function onUrlLoaderComplete(e:Object):void //////////////////////////////////////////////////// URL COMPLETE
				{
					var bytes:ByteArray = transformData(urlLoader.data as ByteArray, url);
					switch (extension.toLowerCase())
					{
						case "mpeg":
						case "mp3":
							bothLoadersComplete(instantiateSound(bytes));
							break;
						case "jpg":
						case "jpeg":
						case "png":
						case "gif":
							loaderInfo = instantiateImage(bytes, onError, onLoaderComplete);
							break;
						default: // any XML / JSON / binary data 
							bothLoadersComplete(bytes);
							break;
					}
				}
				
				function onLoaderComplete(event:Object):void
				{
					urlLoader.data.clear();
					bothLoadersComplete(event.target.content);
				}
				
				function bothLoadersComplete(asset:Object, resetAlternativePath:Boolean=true):void
				{
					objects[fullname] = asset;
					delete loaders[fullname];
					
					if (urlLoader)
						removeListeners.apply(null, listeners);
					
					if (loaderInfo)
					{
						loaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onError);
						loaderInfo.removeEventListener(Event.COMPLETE, onLoaderComplete);
					}
					
					if(resetAlternativePath)
						alternativePathIndex = -1;
					if(individualComplete is Function)
						individualComplete(fullname);
					nextElement();
				}
			}
		}
		
		private static function getAlternativePath(prefix:String, originalUrl:String):String
		{
			var out:String= '';
			if(U.ISWEB || prefix.match(/^(http|ftp)/i))
				return prefix + originalUrl;
			try {
				var FileClass:Object = flash.utils.getDefinitionByName('flash.filesystem::File');
				// workaround for inconsistency of traversing up directories. FP takes working dir, AIR doesn't
				var initPath:String = prefix.match(/^(\.\.|$)/i) ?  FileClass.applicationDirectory.nativePath + '/' + prefix : prefix
				var f:Object = new FileClass(initPath);
				out = f.resolvePath(f.nativePath + originalUrl).nativePath;
			}
			catch(e:Error) { 
				trace(e);
				out = prefix + originalUrl;
			}
			return out;
		}
		
		private static function instantiateImage(bytes:ByteArray, onIoError:Function, onLoaderComplete:Function):LoaderInfo
		{
			var loader:Loader = new Loader();
			
			var loaderInfo:LoaderInfo = loader.contentLoaderInfo;
				loaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onIoError);
				loaderInfo.addEventListener(Event.COMPLETE, onLoaderComplete);
				
				loader.loadBytes(bytes, context);
			return loaderInfo;
		}
		
		private static function instantiateSound(bytes:ByteArray):Sound
		{
			var sound:Sound = new Sound();
				sound.loadCompressedDataFromByteArray(bytes, bytes.length);
			bytes.clear();
			return sound;
		}
		
		private static function addListeners(urlLoader:URLLoader, onIoError:Function, onSecurityError:Function, 
											 onHttpResponseStatus:Function, onLoadProgress:Function, onUrlLoaderComplete:Function):void
		{
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR, onIoError);
			urlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
			urlLoader.addEventListener(HTTPStatusEvent.HTTP_STATUS, onHttpResponseStatus);
			urlLoader.addEventListener(ProgressEvent.PROGRESS, onLoadProgress);
			urlLoader.addEventListener(Event.COMPLETE, onUrlLoaderComplete);
		}
		private static function removeListeners(urlLoader:URLLoader, onIoError:Function, onSecurityError:Function, 
												onHttpResponseStatus:Function, onLoadProgress:Function, onUrlLoaderComplete:Function):void
		{
			urlLoader.removeEventListener(IOErrorEvent.IO_ERROR, onIoError);
			urlLoader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
			urlLoader.removeEventListener(HTTPStatusEvent.HTTP_STATUS, onHttpResponseStatus);
			urlLoader.removeEventListener(ProgressEvent.PROGRESS, onLoadProgress);
			urlLoader.removeEventListener(Event.COMPLETE, onUrlLoaderComplete);
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
		
		private static function log(v:String):void { U.bin.trrace("LDR:", v) }
		
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
			function translateProgress(single:Number, all:Number, nam:String):void { onProgress(single) }
			function completer(aname:String):void {	onComplete(Ldr.getme(aname)) }
		}
		
		private static function get context():LoaderContext
		{
			if(!_context)
				_context = new LoaderContext(checkPolicyFile);
			_context.imageDecodingPolicy = ImageDecodingPolicy.ON_LOAD;
			return _context;
		}
	}
}
package  axl.utils
{
	/**
	 * [axldns free coding 2015]
	 */
	import flash.display.Bitmap;
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
	import flash.utils.getDefinitionByName;
	
	/**
	 * Core assets loader. Supports loading queues (arrays of paths) and alternative directories. Keeps all objects. Access it via getMe();
	 * other differences to starling: supports alternative paths: '../../'
	 */
	public class Ldr
	{
		private static var fileInterfaceAvailable:Boolean =  ApplicationDomain.currentDomain.hasDefinition('flash.filesystem::File');
		private static var FileClass:Class = fileInterfaceAvailable ? getDefinitionByName('flash.filesystem::File') as Class : null;
		private static var FileStreamClass:Class = fileInterfaceAvailable ? getDefinitionByName('flash.filesystem::FileStream') as Class : null;
		
		private static var objects:Object = {};
		private static var urlLoaders:Object = {};
		private static var loaders:Object = {};
		
		private static var mQueue:Array = [];
		private static var alterQueue:Vector.<Function> = new Vector.<Function>();
		
		private static var IS_LOADING:Boolean;
		
		private static var _context:LoaderContext;
		private static var checkPolicyFile:Boolean;
		
		private static var locationPrefixes:Array = [];
		
		/**
		 * (AIR only)
		 * 
		 *  @default  FileClass.applicationStorageDirectory
		 * 
		 *  @see Ldr#loadQueueSynchro
		 *  @see Ldr#defaultOverwriteBehaviour
		 */
		public static var defaultStoreDirectory:Object = fileInterfaceAvailable ? FileClass.applicationStorageDirectory : null;
		
		/**
		 * (AIR only)
		 * Defines what files to overwrite if path where the file was loaded from is different to store directory.
		 * <br>This behaviour can be overriden by specifing appropriate load argument (see <i>load</i> 
		 * and <i>loadQueueSynchro</i> desc). 
		 * <ul>
		 * <li><u>all</u> - all conflict files will be overwritten</li>
		 * <li><u>none</u>, <u>null</u> or incorrect values - no overwriting at all</li> 
		 * <li><u>networkOnly</u> - only files loaded from paths starting like <i>http*</i> or <i>ftp*</i> will be overwritten</li>
		 * <li><u>olderThan_<i>unixTimestamp</i></u></li> -e.g. to overwrite only files older than midday 1 APR 2015 use <code>olderThan_1427889600</code>
		 * <li><u><code>Array/Vector/Directory</code></u></li> - only contents present in specified list of paths, list of files, specified directory
		 * will get owerwritten</li>
		 * <li><u>customFilter</u> - <code>function(existingFile:File):Boolean</code> let you decide for every particular file
		 * true - overrwrite, false - dont. Performance is on you in this case
		 * </ul>
		 * 
		 * @default networkOnly
		 * 
		 * @see Ldr#loadQueueSynchro
		 */
		public static var defaultOverwriteBehaviour:Object = 'networkOnly';
		
		
		/**
		 * defaultPathPrefixes allow you to look up for files to load in any number of directories in a single call.
		 * <b>Every</b> load call is prefixed but prefix can also be an empty string.
		 * <br>This behaviour can be overriden by specifing appropriate load argument (see load and loadQueueSynchro desc). 
		 *<br><br>
		 * Mixing <i>File</i> class constatns and domain addresses can set a nice flow with easily updateable set of assets and fallbacks.
		 * <br>
		 * <code>
		 * defaultPathPrefixes[0] = File.applicationStorageDirectory;<br>
		 * defaultPathPrefixes[1] = "http://domain.com/app";<br>
		 * defaultPathPrefixes[2] = File.applicationDirectory.nativePath;<br>
		 * <br>
		 * Ldr.load("/assets/example.file",onComplete);
		 * </code>
		 * <br>to check 
		 * <br><strong>app-storage:/assets/example.file</strong> onError:
		 * <br><strong>http://domain.com/app/assets/example.file</strong> onError
		 * <br><strong>app:/assets/example.fle</strong> onError : onComplete(null);
		 * <br><br>Highly recommended to push
		 * <br><code><i>root</i>.loaderInfo.url.substr(0,<i>root</i>.loaderInfo.url.lastIndexOf('/')</code>
		 * <br>for web apps.
		 * <br>relative paths are allowed with standard ActionsScirpt rules.
		 * @see Ldr#loadQueueSynchro */
		public static function  get defaultPathPrefixes():Array { return locationPrefixes }
		
		/** returns number of object to load in <u>current</u> queue */
		public static function numQueued():int { return mQueue.length }
		
		/** returns number of queues excluding current one */
		public static function numQueues():int { return alterQueue.length }
		
		/** tells you if any loading is in progress */
		public static function get isLoading():Boolean 	{ return IS_LOADING || numQueues.length > 0 }
		
		
		/**
		 * Main function to get resource reference.<br>
		 * 
		 * <ul>
		 * <li>flash.disply.DisplayObject / Bitmap for jpg, jpeg, png, gif</li>
		 * <li>flash.media.Sound for mp3</li>
		 * <li> String / ByteArray / UTF for any binary (xml, json, txt, atf, etc..)
		 * <ul>
		 * @param v : filename with extension but without subpath. 
		 * <br> Resource names are formed based on path you <code>addToQueue</code> 
		 * or passed directly to <code>loadQueueSynchro</code> array
		 * @return null / undefined if asset is not loaded or data as above if loaded:<br>
		 * 
		 * @see Ldr#loadQueueSynchro
		 * @see Ldr#defaultPathPrefixes
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
		 * Loads all assets <strong>synchroniously</strong> from array of paths or subpaths,
		 * checks for alternative directories, stores loaded files to directories (AIR only).
		 * It does not allow to load same asset twice. Use <code>Ldr.unload</code> to remove previously loaded files.
		 *
		 * @param array : array  of paths or subpaths e.g. : assets/images/a.jpg or http://abc.de/fg.hi
		 * @param onComplete : function to execute once queue is done. this suppose to execute always, 
		 * regardles of issues with particular asssets
		 * @param individualComplete : <code>function(loadedAssetName:String)</code> this function may not be executed if particular asset fails to laod
		 * @param onProgress : <code>function(percentageOfCurrentAsset:Number, numAssetsRemainingCurrentQueue:int, 
		 * currentAssetName:String)</code>
		 * @param pathPrefixes: Vector or array of Strings(preffered) or File class instances pointing to directories.
		 * <br> final requests are formed as pathPrefixes[x] + pathList[y]
		 * <ul><li><i>null</i> will use pathList[y] only</li>
		 * <li><i>:default</i> uses <u>Ldr.defaultPathPrefixes</u></li></ul>
		 * @param storeDirectory: (AIR) <i>:default</i> uses <u>Ldr.defaultStoreDirectory</u>, <i>null</i> disables storing, any other tries to resolve path and store loaded asset accordingly
		 * @param overwriteExistingFiles (AIR) 'networkOnly' || 'all' || 'none' || 'olderThan_<i>unixTimestamp</i>' || Array/Vector of subpaths or File instances
		 * <br><i>:default</i> uses  <u>Ldr.defaultOverwriteBehaviour</u>
		 * @return if busy with other loading - index on which this request is queued
		 * 
		 * @see Ldr#defaultPathPrefixes
		 * @see Ldr#defaultStoreDirectory
		 * @see Ldr#defaultOverwriteBehaviour
		 */
		public static function loadQueueSynchro(pathsList:Array=null, onComplete:Function=null, individualComplete:Function=null
												,onProgress:Function=null, pathPrefixes:Object=":default", storeDirectory:Object=":default",
												 overwriteExistingFiles:Object=":default"):*
		{
			if(IS_LOADING)
				return alterQueue.push(function():void { loadQueueSynchro(pathsList,onComplete,individualComplete,onProgress) });
			
			var originalPath:String;
			var concatenatedPath:String;
			var filename:String;
			var extension:String;
			var subpath:String;
			var prefix:String;
			
			var prefixes:Object = (pathPrefixes == ':default' ? Ldr.defaultPathPrefixes : pathPrefixes);
			if(fileInterfaceAvailable)
			{
				var storePath:Object = (storeDirectory == ':default' ? Ldr.defaultStoreDirectory : storeDirectory);
				var overwrite:Object = (overwriteExistingFiles == ":default" ? Ldr.defaultOverwriteBehaviour : overwriteExistingFiles);
			}
			
			var numElements:int;
			var listeners:Array;
			
			var prefixIndex:int=0;
			var numPrefixes:int = prefixes.length;
			
			var urlRequest:URLRequest;
			var urlLoader:URLLoader;
			var loaderInfo:LoaderInfo;
			
			if(!prefixes || (prefixes.length < 1)) prefixes = [""];
			
			if(pathsList)
				mQueue = mQueue.concat(pathsList);
			
			IS_LOADING = true;
			
			nextElement();
			
			function nextElement():void
			{
				// validate end of queue
				numElements = mQueue.length;
				if(numElements < 1)
				{
					IS_LOADING = false;
					if(onComplete is Function)
						onComplete();
					if(alterQueue.length >0)
						alterQueue.shift()();
					return;
				}
				
				// validate prefix and subpath
				prefix = validatePrefix(prefixes[prefixIndex]);
				subpath =  validateSubpath(mQueue.pop());
				if(!prefix || !subpath)
					return nextElement();
				
				// get initial details
				if(!originalPath)
				{
					originalPath = subpath.substr();
					var i:int = originalPath.lastIndexOf("/") +1;
					var j:int = originalPath.lastIndexOf("\\")+1;
					var k:int = originalPath.lastIndexOf(".") +1;
					
					extension	= originalPath.slice(k);
					filename 	= originalPath.slice(i>j?i:j);
				}
				
				//validate already existing elements
				if(objects[filename] || urlLoaders[filename] || loaders[filename])
				{
					U.bin.trrace("OBJECT ALREADY EXISTS:",filename,'/',objects[filename],'/', urlLoaders[filename],'/', loaders[filename]);
					return nextElement();
				}
				
				//merge prefix & subpath
				concatenatedPath = getConcatenatedPath(prefix, originalPath);
				
				
				//setup loaders and load
				urlLoader = new URLLoader();
				urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
				urlLoaders[filename] = urlLoader;
				
				listeners = [urlLoader, onError, onError, onHttpResponseStatus, onLoadProgress, onUrlLoaderComplete];
				addListeners.apply(null, listeners);
				
				urlRequest = new URLRequest(concatenatedPath);
				urlLoader.load(urlRequest);
				// end of nextElement flow - waiting for eventDispatchers
				
				function onError(e:Event):void
				{
					bothLoadersComplete(null);
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
						onProgress(e.bytesLoaded / e.bytesTotal, mQueue.length, filename);
				}
				
				function onUrlLoaderComplete(e:Object):void
				{
					var bytes:ByteArray = transformData(urlLoader.data as ByteArray, concatenatedPath);
					saveIfRequested(bytes);
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
					loaders[filename] = loaderInfo.loader;
					bothLoadersComplete(event.target.content);
				}
				
				function bothLoadersComplete(asset:Object):void
				{
					objects[filename] = asset;
					delete urlLoaders[filename];
					
					if(urlLoader)
						removeListeners.apply(null, listeners);
					
					if(loaderInfo)
					{
						loaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onError);
						loaderInfo.removeEventListener(Event.COMPLETE, onLoaderComplete);
					}
					
					U.bin.trrace('['+prefixIndex+']', asset ? 'loaded:' : 'fail:',  urlRequest.url);
					
					if((asset == null) && (++prefixIndex < numPrefixes))
						mQueue.push(originalPath);
					else
					{
						prefixIndex=0;
						originalPath = null;
						if(individualComplete is Function)
							individualComplete(filename);
					}
					return nextElement();
				}
			}
		
			function validatePrefix(p:Object):String
			{
				if(p is String) return p as String;
				if(p && p.hasOwnProperty('nativePath')) return p.nativePath as String;
				if(++prefixIndex < numPrefixes) return validatePrefix(prefixes[prefixIndex]);
				else return null;
			}
			
			
			function saveIfRequested(data:ByteArray):void
			{
				if(storePath && Ldr.fileInterfaceAvailable)
				{
					var storePrefix:String = validatePrefix(storePath);
					try{
						var f:Object = new FileClass(getConcatenatedPath(storePrefix, originalPath));
						trace("resolved path:", f.url);
						var fr:Object = new FileStreamClass();
						fr.open(f, 'write');
						fr.writeBytes(data);
						fr.close();
						fr = null;
						f = null;
						U.bin.trrace("saved", storePrefix, originalPath);
						
					} catch (e:*) {U.bin.trrace("save failed",storePrefix, originalPath) }
				}
			}
		}
		
		private static function  validateSubpath(p:Object):String
		{
			if(p is String) return p as String;
			if(p && p.hasOwnProperty('nativePath')) return p.nativePath as String;
			else return null;
		}
		
		private static function getConcatenatedPath(prefix:String, originalUrl:String):String
		{
			if(prefix.match( /(\/$|\\$)/) && originalUrl.match(/(^\/|^\\)/))
				prefix = prefix.substr(0,-1);
			if(!fileInterfaceAvailable || U.ISWEB || prefix.match(/^(http:|https:|ftp:|ftps:)/i))
				return prefix + originalUrl;
			else
			{
				// workaround for inconsistency of traversing up directories. FP takes working dir, AIR doesn't
				var initPath:String = prefix.match(/^(\.\.|$)/i) ?  FileClass.applicationDirectory.nativePath + '/' + prefix : prefix
					trace('init path', initPath);
				try {
					var f:Object = new FileClass(initPath) 
					initPath = f.resolvePath(f.nativePath + originalUrl).nativePath;
					f = null;
				}
				catch (e:*) { U.bin.trrace(prefix + originalUrl, e), initPath = prefix + originalUrl}
				return initPath;
			}
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
				{
					trace("HEADER", header.name, header.value);
					if (header.name == headerName) return header.value;
				}
			}
			return null;
		}
		
		private static function log(v:String):void { U.bin.trrace("LDR:", v) }
		
		/**
		 * Loads specific file upon request. Provides translation of loadQueueSynchro in following way:
		 * <ul>
		 * <li><i>onComplete</i> is executed with loaded object instead of name only</li>
		 * <li>onProgress (if specified) is executed with percentage only</li>
		 * </ul>
		 * @param path : path/subpath to file
		 * @param onComplete : <code>function(loadedObject:Object=null)</code>
		 * @param onProgress : <code>function(percentage:Number:0-1)</code>
		 * @param pathPrefixes: vector or array of prefixes to concat individual path with
		 * <i>*default</i> uses <u>Ldr.alternativeDirPrefixes</u>
		 * @param storeDirectory: (AIR) <i>*default uses</i> <u>Ldr.defaultStoreDirectory</u>, <i>null</i> disables storing, any other tries to resolve path and store loaded asset accordingly
		 * @see Ldr#loadQueueSynchro
		 * @see Ldr#defaultPathPrefixes
		 * @see Ldr#defaultStoreDirectory
		 */
		public static function load(path:String, onComplete:Function, onProgress:Function=null,
									pathPrefixes:Object='*default', storeDirectory:String="*default"):*
		{	
			Ldr.loadQueueSynchro([path],null,completer,(onProgress is Function) ? translateProgress : null, pathPrefixes,storeDirectory );
			function translateProgress(single:Number, all:Number, nam:String):void { onProgress(single) }
			function completer(aname:String):void {	onComplete(Ldr.getme(aname)) }
		}
		
		/**
		 * Unloads / clears / disposes loaded data, removes display objects from display list
		 * <br> It won't affect sub-instantiated elements (XMLs, Textures, JSON parsed objects) but will make them 
		 * unavailable to restore (e.g. Starling.handleLostContext)
		 */
		public static function unload(filename:String):void
		{
			var o:Object= objects[filename];
			var l:Loader = loaders[filename];
			var u:URLLoader = urlLoaders[filename];
			if(o)
			{
				if(o.hasOwnProperty('parent') && o.parent)
					o.parent.removeChild(o);
				if(o is Bitmap && o.bitmapData)
				{
					o.bitmapData.dispose();
					o.bitmapData = null;
				}
				try { o.close() } catch (e:*) {}
			}
			if(l)
			{
				if(l.hasOwnProperty('parent') && l.parent)
					l.parent.removeChild(l);
				if(l.loaderInfo)
					l.loaderInfo.bytes.clear();
				l.unload();
				l.unloadAndStop();
			}
			if(u && u.data)
				u.data.clear();
			
			o =null, l = null,u = null;
			objects[filename] = null;
			loaders[filename] = null;
			urlLoaders[filename] = null;
			delete urlLoaders[filename];
			delete loaders[filename];
			delete objects[filename];
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
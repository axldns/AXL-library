/**
 *
 * AXL Library
 * Copyright 2014-2016 Denis Aleksandrowicz. All Rights Reserved.
 *
 * This program is free software. You can redistribute and/or modify it
 * in accordance with the terms of the accompanying license agreement.
 *
 */
package  axl.utils
{
	import flash.display.Bitmap;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.UncaughtErrorEvent;
	import flash.media.Sound;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.system.Capabilities;
	import flash.system.ImageDecodingPolicy;
	import flash.system.LoaderContext;
	import flash.utils.ByteArray;
	import flash.utils.clearTimeout;
	import flash.utils.getDefinitionByName;
	import flash.utils.getTimer;
	import flash.utils.setTimeout;
	
	/**
	 * This class represents each <b> queue </b> (not a single asset)
	 */
	public class Req extends EventDispatcher {
		
		public static const fileInterfaceAvailable:Boolean =  ApplicationDomain.currentDomain.hasDefinition('flash.filesystem::File');
		public static const FileClass:Class = fileInterfaceAvailable ? getDefinitionByName('flash.filesystem::File') as Class : null;
		public static const FileStreamClass:Class = fileInterfaceAvailable ? getDefinitionByName('flash.filesystem::FileStream') as Class : null;
		public static const codeLoadAllowed:Boolean = !Capabilities.os.match(/(android|ios)/i);
		private static const networkRegexp:RegExp = /^(http:|https:|ftp:|ftps:)/i;
		
		private static function log(...args):void { if(verbose is Function) verbose.apply(null,args) }
		public static var verbose:Function;
		
		public static var networkOverPrefixes:Boolean = true;
		private static var _numAllRemaining:int=0; // ++ every item added, -- every item loaded and/or skipped. 0 on all queues done
		private static var _numAllQueued:int=0; //  ++ every item queued. 0 on all queues done
		private static var _numAllLoaded:int=0; // ++ every item loaded, -- every item successfully loaded. 0 on all queues done
		private static var _numAllSkipped:int=0; // ++ every item load hard fail, 0 on all queues done
		private var numCurrentRemaining:int =0; // as above but appplying to current queue
		private var numCurrentQueued:int=0; // as above but appplying to current queue
		private var numCurrentLoaded:int=0; // as above but appplying to current queue
		private var numCurrentSkipped:int=0; // as above but appplying to current queue
		
		public static function allQueuesDone():void { _numAllQueued = _numAllRemaining = _numAllLoaded = _numAllSkipped = 0}
		public static function get numAllRemaining():int { return _numAllRemaining}
		public static function get numAllQueued():int { return _numAllQueued }
		public static function get numAllLoaded():int { return _numAllLoaded }
		public static function get numAllSkipped():int { return _numAllSkipped }
		
		public function currentQueueDone():void { numCurrentQueued = numCurrentLoaded = numCurrentRemaining= numCurrentSkipped = 0}
		public function get numLoaded():int { return numCurrentLoaded }
		public function get numRemaining():int { return numCurrentRemaining }
		public function get numQueued():int { return numCurrentQueued }
		public function get numSkipped():int { return numCurrentSkipped }
		
		private var prefixList:Vector.<String> = new Vector.<String>();
		private var prefix:String;
		private var prefixIndex:int=0;
		private var numPrefixes:int;
		
		private var pathList:Vector.<String> = new Vector.<String>();
		private var originalPath:String;
		private var concatenatedPath:String;
		private var subpath:String;
		private var filename:String;
		private var extension:String;
		
		private var loadBehaviorCustom:Function;
		private var downloadOnly:Boolean;
		
		private var storingBehaviorRegexp:RegExp;
		private var storingBehaviorNumber:Number;
		private var storeFilter:Function;
		private var storePrefix:String;
		
		public var urlRequest:URLRequest;
		public var urlLoader:URLLoader;
		public var loaderInfo:LoaderInfo;
		
		public var onComplete:Function;
		public var individualComplete:Function;
		public var onProgress:Function;
		
		public var isLoading:Boolean;
		private var isPaused:Boolean;
		
		public var timeOut:int = 5000;
		private var requestTimeOutID:int;
		
		private var benchmarkTimer:int;
		private var loadFilter:Function;
		
		public var _context:LoaderContext;
		
		private var eventComplete:Event = new Event(Event.COMPLETE);
		private var eventProgress:Event = new Event(Event.CHANGE);
		private var eventCancel:Event = new Event(Event.CANCEL);
		public var id:Number;
		public var separateDomain:Boolean;
		private var tname:String = '[Ldr][Queue]';
		
		public function Req()
		{
			urlLoader = new URLLoader();
			urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
			addListeners();
			urlRequest = new URLRequest();
		}
		public function destroy():void
		{
			currentQueueDone();
			isLoading = false;
			isPaused = false;
			if(urlLoader != null)
				removeListeners();
			urlLoader = null;
			urlRequest = null;
			loaderInfo = null;
			_context = null;
			eventComplete = eventProgress = null;
			onComplete = individualComplete = onProgress = storeFilter = loadFilter =  loadBehaviorCustom = null;
			storePrefix = extension = filename = originalPath = concatenatedPath = null;
			storingBehaviorRegexp = null;
			pathList = prefixList = null;
			clearTimeout(this.requestTimeOutID);
		}
		
		// ----------------------------------------------- START OF INIT SETUP -----------------------------------------------//
		public function addPaths(v:Object):int
		{
			var flatList:Vector.<String> = new Vector.<String>();
			flatList = getFlatList(v, flatList);
			var i:int, j:int, l:int = pathList.length;
			counters(-l);
			for(i=0,j= flatList.length; i<j; i++)
				if(pathList.indexOf(flatList[i]) < 0)
					pathList[l++] = flatList[i];
			flatList.length = 0;
			flatList = null;
			counters(l);
			log(tname+" added to queue.", Ldr.state);
			return l;
		}
		
		public function removePaths(v:Object):int
		{
			var flatList:Vector.<String> = new Vector.<String>();
			flatList = getFlatList(v, flatList);
			var i:int, k:int, l:int = pathList.length;
			counters(-l);
			for(i= flatList.length; i-->0;) {
				k = pathList.indexOf(flatList[i]);
				if(k>-1)
					pathList.splice(k,1);
			}
			flatList.length = 0;
			flatList = null;
			l = pathList.length;
			counters(l);
			log(tname+" removed from queue.");
			return l;
		}
		
		public function addPrefixes(v:Object):int
		{
			var flatList:Vector.<String> = new Vector.<String>();
			flatList = getFlatList(v, flatList,false);
			var i:int, j:int, k:int, l:int = prefixList.length;
			for(i=0,j= flatList.length; i<j; i++)
				if(prefixList.indexOf(flatList[i]) < 0)
					prefixList[l++] = flatList[i];
			flatList.length = 0;
			flatList = null;
			numPrefixes = prefixList.length;
			return numPrefixes;
		}
		
		public function set loadBehavior(v:Object):void
		{
			if(v == Ldr.behaviours.loadSkip)
				loadFilter = loadSkip;
			else if(v == Ldr.behaviours.loadOverwrite)
				loadFilter = loadOverwrite;
			else if(v == Ldr.behaviours.downloadOnly)
			{
				downloadOnly = true;
				loadFilter = loadDownload;
			}
			else if(v is Function && v.length == 1)
			{
				loadBehaviorCustom = v as Function;
				loadFilter = loadCustom;
			}
		}
		
		public function set storeDirectory(v:Object):void
		{
			if(!fileInterfaceAvailable) storePrefix = null;
			if(v is String){
				try { 
					var f:Object = new FileClass(v);
					storePrefix = f.isDirectory ? f.url : null;
				}
				catch(e:ArgumentError) { storePrefix = null }
				f = null;
			}
			else if(v is FileClass && v.isDirectory) storePrefix = v.url;
			else storePrefix = null;
		}
		
		public function set storingBehavior(v:Object):void
		{
			if(v is Date) v = v.time;
			if(v is Number) 
			{
				storingBehaviorNumber = v.time;
				storeFilter = filter_date;
			}
			else if((v is Function) && (v.length == 2))	storeFilter = v as Function;
			else if(v is RegExp) 
			{
				storingBehaviorRegexp = v as RegExp;
				storeFilter = filter_regexp;
			}
			else storeFilter = null;
		}
		
		// -------------helpers---------------------------------- INIT SETUP
		private function counters(v:int):void
		{
			numCurrentRemaining +=v;
			numCurrentQueued += v;
			_numAllRemaining += v;
			_numAllQueued += v;
		}
		
		public static function getFlatList(v:Object, ar:Vector.<String>,filesLookUp:Boolean=true):Vector.<String>
		{
			var i:int = ar.length;
			if(v is String) ar[i] = String(v);
			else if (fileInterfaceAvailable && (v is FileClass))
			{
				if(filesLookUp) processFilesRecurse(v, ar); // paths
				else if(v.isDirectory) ar[i] = v.url; // prefixes 
			}
			else if (v is XML || v is XMLList) processXml(XML(v), ar);
			else if(v is Array || v is Vector.<String> /*|| v is Vector.<FileClass> */|| v is Vector.<XML> || v is Vector.<XMLList>)
				for(var j:int = 0, k:int = v.length;  j < k; j++)
					ar = ar.concat(getFlatList(v[j], new Vector.<String>(),filesLookUp));
			return ar;
		}
		
		private static function processFilesRecurse(f:Object, flat:Vector.<String>):void
		{
			if(f.isDirectory)
			{
				var v:Array = f.getDirectoryListing();
				while(v.length)
					processFilesRecurse(v.pop(),flat);
				v = null;
			} else { flat.push(f.url) }
			f = null;
		}
		
		private static function processXml(node:XML, flat:Vector.<String>, addition:String=''):void
		{
			var nodefiles:XMLList = node.files;
			for( var i:int = 0, j:int = nodefiles.length(); i<j; i++)
				processXml(XML(nodefiles[i]), flat, addition + String(nodefiles[i].@dir));
			nodefiles = node.file;
			for(i = 0, j = nodefiles.length(); i<j; i++)
				flat.push(addition + nodefiles[i].toString());
		}
		
		// ----------------------------------------------- END OF INIT SETUP -----------------------------------------------//
		
		// ----------------------------------------------- QUEUE PROCESSES -----------------------------------------------//
		
		public function load():void
		{
			log(tname+" start. state:\n", Ldr.state);
			isLoading = true;
			isPaused = false;
			nextElement();
		}
		
		public function pause():Number { isPaused = true; return id }
		public function resume():Number { if(isPaused){load()}; return id }
		
		private function element_skipped():void
		{
			numCurrentSkipped++;
			_numAllSkipped++;
			log(tname+"["+filename+"] SKIPPED:("+ String(getTimer()- benchmarkTimer)+"ms):");
			element_complete();
		}
		
		private function element_loaded():void
		{
			numCurrentLoaded++;
			_numAllLoaded++;
			log(tname+"["+filename+"] LOADED!:("+ String(getTimer()- benchmarkTimer)+"ms):", urlRequest.url);
			element_complete();
		}
		
		private function element_complete():void
		{
			prefixIndex=0;
			originalPath = null;
			_numAllRemaining--;
			numCurrentRemaining--;
			if(individualComplete is Function)
				individualComplete(filename);
			if(!eventProgress) // this is in case individualComplete DESTROYS this request
				return;
			dispatchEvent(eventProgress);
			nextElement();
		}
		
		private function nextElement():void
		{
			// validate end of queue
			numCurrentRemaining = pathList.length;
			if(numCurrentRemaining < 1)
				return finalize();
			if(!isLoading || isPaused)
				return
			benchmarkTimer = getTimer();
			prefix = validatedPrefix;
			subpath = pathList.pop();
			
			if(!(prefix is String) || !(subpath is String))
				return nextElement();
			
			if(!originalPath)
				getSubpathDetails();		
			
			if(!conflictsResolved)
				return element_skipped();
			
			concatenatedPath = getConcatenatedPath(prefix, originalPath);
			//setup loaders and load
			urlRequest.url = concatenatedPath;
			log(tname+"["+filename+"] loading:("+ String(getTimer()- benchmarkTimer)+'ms):', urlRequest.url);
			this.requestTimeOutID = setTimeout(requestTimePassed, this.timeOut);
			urlLoader.load(urlRequest);
		}
		
		private function requestTimePassed():void
		{
			log("[Ldr][RequestTimeout]", concatenatedPath);
			if(urlLoader)
			{
				urlLoader.close();
				urlLoader.dispatchEvent(eventCancel);
			}
		}
		
		public function saveIfRequested(data:ByteArray, savingPath:String, validateSameDirs:Boolean=true):void
		{
			if((storePrefix != null) && fileInterfaceAvailable && storeFilter != null)
			{
				var f:Object;
				var path:String = getConcatenatedPath(storePrefix, savingPath);
				log(tname+"["+filename+"][Save] saving:", path);
				//resolving file locating
				try{ f= new FileClass(path) } 
				catch (e:ArgumentError) { log(tname+"["+filename+"][Save] incorrect path. null file:",path,e) }
				
				//validation and filters
				if(validateSameDirs)
				{
					try { f = baseValidation(storeFilter(f, urlRequest.url), urlRequest.url) }
					catch(e:*) { f = null, log(tname+"["+filename+"][Save][filter] error:", e) }
					if(f == null)
						return log(tname+"["+filename+"][Save] Storing criteria doesn't match, abort");
				}
				
				//writing to disc
				var fr:Object = new FileStreamClass();
				try{ 
					fr.open(f, 'write'); // openAsync doesn't fire COMPLETE in write mode so can't stick to where remove async listeners  
					fr.writeBytes(data);
					fr.close();
					fr = null;
					log(tname+"["+filename+"][Save] SAVED:", f.exists,':', f.nativePath, '['+ String(data.length / 1024) + 'kb]');
				} catch (e:Error) { log(tname+"["+filename+"][Save] FAIL: cant save as:",f.url,'\n',e) }
				f = null;
			}
		}
		
		private function finalize():void
		{
			isLoading = false;
			isPaused = false;
			removeListeners()
			urlLoader = null;
			urlRequest = null;
			this.dispatchEvent(eventComplete ? eventComplete :  new Event(Event.COMPLETE));
		}
		
		// -------events----------------------------- QUEUE PROCESSES
		
		private function onError(e:Event):void
		{
			log(tname+"["+filename+"][Error]:("+ String(getTimer()- benchmarkTimer)+"ms):", e);
			clearTimeout(this.requestTimeOutID);
			bothLoadersComplete(null);
		}
		protected function onCancel(e:Event):void
		{
			clearTimeout(this.requestTimeOutID);
			onError(e);
		}
		
		protected function onOpen(event:Event):void
		{
			clearTimeout(this.requestTimeOutID);
		}
		
		private function onLoadProgress(e:ProgressEvent):void
		{
			if(e.bytesTotal > 0)
				onProgress(e.bytesLoaded / e.bytesTotal, filename);
		}
		
		private function onHttpResponseStatus(e:HTTPStatusEvent):void
		{
			if(extension == null)
			{
				var headers:Array = e["responseHeaders"];
				var contentType:String = getHttpHeader(headers, "Content-Type");
				if(contentType && /(audio|image)\//.exec(contentType))
					extension = contentType.split("/").pop();
			}
		}
		
		private function onUrlLoaderComplete(e:Object):void
		{
			log(tname+"["+filename+"] instantiation..("+ String(getTimer()- benchmarkTimer)+"ms)");
			var bytes:ByteArray = urlLoader.data;
			if(bytes) saveIfRequested(bytes, originalPath);
			else return bothLoadersComplete(null);
			if(downloadOnly)
			{
				bytes.clear();
				return element_loaded();
			}
			switch (extension.toLowerCase())
			{
				case "mpeg":
				case "mp3":
					bothLoadersComplete(instantiateSound(bytes));
					bytes.clear();
					break;
				case "jpg":
				case "jpeg":
				case "png":
				case "gif":
					loaderInfo = instantiateImage(urlLoader.data, onError, onLoaderComplete);
					break;
				case "swf":
					try { loaderInfo = instantiateImage(urlLoader.data, onError, onLoaderComplete) }
					catch(e:Error) { log(e), bothLoadersComplete(bytes) }
					break;
				case 'xml':
					try { obj = XML(bytes) } 
					catch(e:Error) { log(e) }
					if(obj != null) bytes.clear();
					else obj = bytes;
					bothLoadersComplete(obj);
					break
				case "csv":
				case "txt":
					obj = bytes.readUTFBytes(bytes.length);
					bothLoadersComplete(obj);
					break;
				default: 
					try { var obj:Object = tryAutodetect(bytes)}
					catch(e:Error) { log(e)}
					if(obj != null) bytes.clear();
					else obj = bytes;
					bothLoadersComplete(obj);
					break;
			}
		}
		
		private function onLoaderComplete(event:Object):void
		{
			urlLoader.data.clear();
			Ldr.loaders[filename] = loaderInfo.loader;
			Ldr.loaderInfos[filename] = loaderInfo;
			bothLoadersComplete(event.target.content);
		}
		
		private function bothLoadersComplete(asset:Object):void
		{
			
			var url:String = urlRequest.url;
			if(loaderInfo)
			{
				loaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onError);
				loaderInfo.removeEventListener(Event.COMPLETE, onLoaderComplete);
				loaderInfo.uncaughtErrorEvents.removeEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, handleUncaughtErrors);
			}
			if((asset == null) && (++prefixIndex < numPrefixes))
			{
				pathList.push(originalPath);
				log(tname+"["+filename+"] soft fail:", url, 
					'\n[Ldr][Queue]['+filename+"] Trying alternative dir:("+ String(getTimer()- benchmarkTimer)+"ms):", validatedPrefix);
				nextElement();
			}
			else if(asset != null)
			{
				if(asset is Bitmap)
					asset.smoothing = true;
				Ldr.objects[filename] = asset;
				element_loaded();
			}
			else element_skipped();
		}
		
		// -------helpers----------------------------- QUEUE PROCESSES
		
		private function getSubpathDetails():void
		{
			originalPath = subpath.substr();
			var i:int = originalPath.lastIndexOf("/") +1;
			var j:int = originalPath.lastIndexOf("\\")+1;
			var k:int = originalPath.lastIndexOf(".") +1;
			
			extension	= originalPath.substr(k);
			filename 	= originalPath.substr(i>j?i:j);
		}
		
		private function get validatedPrefix():String
		{
			if(prefixList.length < 1)
			{
				prefixList[0] = '';
				numPrefixes = prefixList.length;
			}
			if(prefixIndex < numPrefixes) return prefixList[prefixIndex];
			else return null;
		}
		
		private function getConcatenatedPath(prefix:String, originalUrl:String):String
		{
			if(prefix.length < 1) return originalUrl;
			if(networkOverPrefixes && originalUrl.match(networkRegexp))
			{
				prefixIndex =numPrefixes;
				return originalUrl;
			}
			if(fileInterfaceAvailable && !prefix.match(networkRegexp))
			{ 
				// workaround for inconsistency in traversing up directories on windows. 
				// FP takes working dir, AIR doesn't.
				if(prefix.match(/^(\.){1,2}/i))
					prefix = FileClass.applicationDirectory.nativePath + FileClass.separator + prefix;
				
				resolveJoints();
				
				var cp:String = prefix + originalUrl; 
				try {
					var f:Object = new FileClass(cp) ;
					f.resolvePath('.');
					//return f.url.substr(0, f.url.indexOf('\%3F')); //ON MAC LOCAL RESOURCES URL REQUESTS WITH QUERY STRINGS CAUSE IOERROR
					return f.url;
				} catch (e:*) { log(tname+"["+filename+"] can not resolve path:",prefix + originalUrl, e, 'trying as URLloader')
				} finally { f = null }
			}
			else
			{
				resolveJoints();
			}
			//fixes concat two styles an doubles. all go to "/" since this is default url style, ios supports that, windows can resolve
			function resolveJoints():void
			{
				var joint:String = prefix.substr(-1) + originalUrl.charAt(0);
				if(joint == '//' || joint == '\\')
					prefix = prefix.substr(0,-1);
				else if(joint.match(/(\\|\/)/i))
				{
					//all good
				}
				else
				{
					if(prefix.match(/\\/) || originalUrl.match(/\\/))
						prefix += '\\'.substr(1);
					else
						prefix += '/';
				}
			}
			return String(prefix + originalUrl).replace(/\\/gi, "/");
		}
		
		private function get conflictsResolved():Boolean
		{
			if(Ldr.objects[filename] || Ldr.loaders[filename])
				return loadFilter();
			else return true;
		}
		
		private function filter_date(file:Object, url:String):Object { 
			if(!file.exists) return file;
			return (file.modificationDate.time < storingBehaviorNumber) ? file : null
		}
		private function filter_regexp(file:Object, url:String):Object {
			return url.match(storingBehaviorRegexp) ? file : null;
		}
		
		private function loadDownload():Boolean { return true }
		private function loadSkip():Boolean { return false }
		private function loadOverwrite():Boolean
		{
			Ldr.unload(filename);
			return true;
		}
		private function loadCustom():Boolean {
			try { filename = loadBehaviorCustom(filename) }
			catch(e:*) { filename = null}
			if(filename == null)
				return false;
			else if(Ldr.objects[filename] || Ldr.loaders[filename])
			{
				Ldr.unload(filename);
				return true;
			}
			else return true;
		}
		
		private function tryAutodetect(ba:ByteArray):Object
		{
			var len:int = ba.length;
			if(len < 3) return null;
			var f3:String="";
			for(var i:int= 0;i < 3; i++)
				f3 += String.fromCharCode(ba[i]);
			if(f3 == 'ID3')	return instantiateSound(ba);
			else if(f3.charAt(0).match(/(\{|\[)/)) return JSON.parse(ba.readUTFBytes(len));
			else if(f3.charAt(0) == '<') return new XML(ba.readUTFBytes(len));
			else return null;
		}
		
		private function instantiateImage(bytes:ByteArray, onIoError:Function, onLoaderComplete:Function):LoaderInfo
		{
			var loader:Loader = new Loader();
			var loaderInfo:LoaderInfo = loader.contentLoaderInfo;
			loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, handleUncaughtErrors);
			loaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onIoError);
			loaderInfo.addEventListener(Event.COMPLETE, onLoaderComplete);
			loader.loadBytes(bytes, context);
			return loaderInfo;
		}
		
		protected function handleUncaughtErrors(e:UncaughtErrorEvent):void
		{
			U.log(tname+'[uncaught error]',  e.error, e.error ? Error(e.error).message : '');
			if(e.error is Error)
				U.log(Error(e.error).getStackTrace());
			onError(e);
		}
		
		private function instantiateSound(bytes:ByteArray):Sound
		{
			var sound:Sound = new Sound();
			sound.loadCompressedDataFromByteArray(bytes, bytes.length);
			bytes.clear();
			return sound;
		}
		
		private function baseValidation(file:Object, url:String):Object
		{
			if(!(file is FileClass) || file.isDirectory){
				Ldr.log(tname+"["+filename+"][Save][criteria] file is not File");
				return null;
			}
			else if(file.url == url){
				Ldr.log(tname+"["+filename+"][Save][criteria] store and load directiries are equal");
				return null;
			}
			return file;
		}
		
		private function getHttpHeader(headers:Array, headerName:String):String
		{
			if (headers)
				for each (var header:Object in headers)
				if (header.name == headerName) return header.value;
			return null;
		}
		
		private function addListeners():void
		{
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR, onError);
			urlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onError);
			urlLoader.addEventListener(HTTPStatusEvent.HTTP_STATUS, onHttpResponseStatus);
			urlLoader.addEventListener(Event.CANCEL, onCancel);
			urlLoader.addEventListener(Event.OPEN, onOpen);
			urlLoader.addEventListener(Event.COMPLETE, onUrlLoaderComplete);
			if(onProgress is Function)
				urlLoader.addEventListener(ProgressEvent.PROGRESS, onLoadProgress);
		}
		
		private  function removeListeners():void
		{
			urlLoader.removeEventListener(IOErrorEvent.IO_ERROR, onError);
			urlLoader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onError);
			urlLoader.removeEventListener(HTTPStatusEvent.HTTP_STATUS, onHttpResponseStatus);
			urlLoader.removeEventListener(Event.COMPLETE, onUrlLoaderComplete);
			if(urlLoader.hasEventListener(ProgressEvent.PROGRESS))
				urlLoader.removeEventListener(ProgressEvent.PROGRESS, onLoadProgress);
		}
		
		private function get context():LoaderContext
		{
			if(!_context)
				_context = new LoaderContext(Ldr.policyFileCheck, separateDomain ? new ApplicationDomain(null) : null);
			else
				U.log('[Req]Context already exist');
			if(_context.hasOwnProperty('imageDecodingPolicy'))
				_context.imageDecodingPolicy = ImageDecodingPolicy.ON_LOAD;
			if(_context.hasOwnProperty('allowCodeImport'))
				_context.allowCodeImport = true;// codeLoadAllowed;
			return _context;
		}
	}
}

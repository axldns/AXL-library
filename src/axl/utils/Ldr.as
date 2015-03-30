import flash.display.Loader;
import flash.display.LoaderInfo;
import flash.events.Event;
import flash.events.EventDispatcher;
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

import axl.utils.Ldr;

internal class Req extends EventDispatcher {
	
	public static var fileInterfaceAvailable:Boolean =  ApplicationDomain.currentDomain.hasDefinition('flash.filesystem::File');
	public static var FileClass:Class = fileInterfaceAvailable ? getDefinitionByName('flash.filesystem::File') as Class : null;
	public static var FileStreamClass:Class = fileInterfaceAvailable ? getDefinitionByName('flash.filesystem::FileStream') as Class : null;
	
	
	public static var loaders:Object;
	public static var urlLoaders:Object;
	public static var objects:Object;
	public static var verbose:Function;
	private static function log(...args):void { if(verbose is Function) verbose.apply(null,args) }
	
	private static var numAllElements:int=0; // all queues remaining
	private static var numAllOriginal:int=0; // all queus original
	private var numElements:int =0; // current queue remaining
	private var numOriginal:int=0; // current queue total
	
	public var prefix:String;
	public var prefixIndex:int=0;
	private var uprefixes:Object;
	public var numPrefixes:int;
	
	public var originalPath:String;
	public var concatenatedPath:String;
	public var filename:String;
	public var extension:String;
	public var subpath:String;
	
	public var storePath:Object;
	public var overwrite:Object
	
	private var listeners:Array;
	
	public var urlRequest:URLRequest;
	public var urlLoader:URLLoader;
	public var loaderInfo:LoaderInfo;
	public var onComplete:Function;
	public var individualComplete:Function;
	public var onProgress:Function;
	private var pathList:Vector.<String> = new Vector.<String>();
	
	public var isLoading:Boolean;
	public var isDone:Boolean;
	
	private var eventComplete:Event = new Event(Event.COMPLETE);
	
	public function Req()
	{
		
	}
	
	public static function get numAllRemaining():int { return numAllElements}
	public static function get numAllQueued():int { return numAllOriginal }
	public static  function allQueuesDone():void { numAllOriginal =  numAllElements = 0}
	
	public function get numRemaining():int { return numElements }
	public function get numQueued():int { return numOriginal }

	/**
	 * array or vector or xml. translates to strings
	 */
	public function addPaths(v:Object):int
	{
		
		var flatList:Vector.<String> = new Vector.<String>();
			flatList = getFlatList(v, flatList);
		var i:int, j:int, l:int = pathList.length;
		numOriginal -=l;  		// this get null out while Req is done
		numAllElements -= l; 	// this get substracted onBothLoadersComplete
		numAllOriginal -= l;	// this get substracted while all queues are done by Ldr class
		trace("FLATLIST", flatList);
		for(i=0,j= flatList.length; i<j; i++)
			if(pathList.indexOf(flatList[i]) < 0)
				pathList.push(flatList[i]);
		flatList.length = 0;
		flatList = null;
		trace("PATHLIST", pathList);
		l = pathList.length;
		numOriginal +=l;
		numAllElements += l;
		numAllOriginal += l;
		return l;
	}
	
	public function removePaths(v:Object):int
	{
		
		var flatList:Vector.<String> = new Vector.<String>();
		flatList = getFlatList(v, flatList);
		var i:int, j:int, k:int, l:int = pathList.length;
		numOriginal -=l;
		numAllElements -= l;
		numAllOriginal -= l;
		for(i=0,j= flatList.length; i<j; i++) {
			k = pathList.indexOf(flatList[i]);
			if(k>-1)
				pathList.splice(k,1);}
		flatList.length = 0;
		flatList = null;
		l = pathList.length;
		numOriginal +=l;
		numAllElements += l;
		numAllOriginal += l;
		return l;
	}
	
	private function getFlatList(v:Object, ar:Vector.<String>):Vector.<String>
	{
		var i:int = ar.length;
		if(v is String) ar[i] = v;
		else if (v.hasOwnProperty('nativePath')) ar[i] = v.nativePath;
		else if (v is XML || v is XMLList) processXml(XML(v), ar);
		else if(v is Array || v is Vector.<FileClass> || v is Vector.<String> || v is Vector.<XML> || v is Vector.<XMLList>)
			for(var j:int = 0, k:int = v.length;  j < k; j++)
				ar = ar.concat(getFlatList(v[j], new Vector.<String>()));
		return ar;
	}
	
	private function processXml(node:XML, flat:Vector.<String>, addition:String=''):void
	{
		var nodefiles:XMLList = node.files;
		var subAddition:String = addition +  String(nodefiles.@dir)
		for( var i:int = 0, j:int = nodefiles.length(); i<j; i++)
			processXml(XML(nodefiles[i]), flat, subAddition);
		nodefiles = node.file;
		for(i = 0, j = nodefiles.length(); i<j; i++)
			flat.push(addition + nodefiles[i].toString());
	}
	
	public function get prefixes():Object { return uprefixes }
	
	public function set prefixes(value:Object):void
	{
		uprefixes = value;
		if(!prefixes || (prefixes.length < 1))
			prefixes = [""];
		numPrefixes = prefixes.length;
	}
	
	private function validatePrefix(p:Object):String
	{
		if(p is String) return p as String;
		if(p && p.hasOwnProperty('nativePath')) return p.nativePath as String;
		if(++prefixIndex < numPrefixes) return validatePrefix(prefixes[prefixIndex]);
		else return null;
	}
	
	public function stop():void { pathList = null }
	
	public function load():void
	{
		isLoading = true
		if(pathList != null)
			nextElement();
		else
			finalize();
	}
	
	private function finalize():void
	{
		isLoading = false;
		isDone = true;
		numOriginal = 0;
		this.dispatchEvent(eventComplete);
	}
	
	private function nextElement():Boolean
	{
		// validate end of queue
		numElements = pathList.length;
		log("nextelement", Req.numAllRemaining, '/', numAllOriginal);
		if(numElements < 1)
			return finalize();
		if(!isLoading) // can be paused
			return false
		
		// strips nativePath from files. from now on we deal with strings only
		prefix = validatePrefix(prefixes[prefixIndex]);
		subpath = pathList.pop();
		
		//can ommit incorect data since we've validated prefix existence
		// at set prefixes. subpath should throw an error or log message at least though
		if(!(prefix is String) || !(subpath is String))
			return nextElement();
		
		// get initial details. originalPath is nulled out in 
		// onBothloadersComplete if there are no more alternative prefixes
		if(!originalPath)
			getSubpathDetails();		
		
		//validate already existing elements - this should be up to user if he wants to unload current contents !
		if(objects[filename] || urlLoaders[filename] || loaders[filename])
		{
			log(this,"OBJECT ALREADY EXISTS:",filename,'/',objects[filename],'/', urlLoaders[filename],'/', loaders[filename]);
			return nextElement();
		}
		
		//merge prefix & subpath
		concatenatedPath = getConcatenatedPath(prefix, originalPath);
		
		log('setup loader for', concatenatedPath);
		//setup loaders and load
		urlLoader = new URLLoader();
		urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
		urlLoaders[filename] = urlLoader;
		
		listeners = [urlLoader, onError, onError, onHttpResponseStatus, onLoadProgress, onUrlLoaderComplete];
		addListeners.apply(null, listeners);
		urlRequest = new URLRequest(concatenatedPath);
		urlLoader.load(urlRequest);
		// end of nextElement flow - waiting for eventDispatchers
		return true
	}
	
	private function getSubpathDetails():void
	{
		originalPath = subpath.substr();
		var i:int = originalPath.lastIndexOf("/") +1;
		var j:int = originalPath.lastIndexOf("\\")+1;
		var k:int = originalPath.lastIndexOf(".") +1;
		
		extension	= originalPath.slice(k);
		filename 	= originalPath.slice(i>j?i:j);
	}	
	
	private function onUrlLoaderComplete(e:Object):void
	{
		log('first loader complete', e != null);
		var bytes:ByteArray = urlLoader.data as ByteArray;
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
			case 'xml':
				bothLoadersComplete(XML(bytes));
				break
			case 'json':
				bothLoadersComplete(JSON.parse(bytes.readUTF()))
				break;
			default: // any other remains untouched, atf is here too
				bothLoadersComplete(bytes);
				break;
		}
	}
	
	private function bothLoadersComplete(asset:Object):Boolean // check if it does not crash because of type returning
	{
		log('adding..', filename);
		objects[filename] = asset;
		delete urlLoaders[filename];
		// do not delete loaders!
		if(urlLoader)
			removeListeners.apply(null, listeners);
		
		if(loaderInfo)
		{
			loaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onError);
			loaderInfo.removeEventListener(Event.COMPLETE, onLoaderComplete);
		}
		
		trace('['+prefixIndex+']', asset ? 'loaded:' : 'fail:',  urlRequest.url);
		
		if((asset == null) && (++prefixIndex < numPrefixes))
			pathList.push(originalPath);
		else
		{
			prefixIndex=0;
			originalPath = null;
			numAllElements--;
			if(individualComplete is Function)
				individualComplete(filename);
		}
		return nextElement();
	}
	
	
	private function saveIfRequested(data:ByteArray):void
	{
		if(storePath && FileClass)
		{
			var storePrefix:String = validatePrefix(storePath);
			var sameDirectory:Boolean;
			try{
				log('saving async', originalPath);
				var f:Object = new FileClass(getConcatenatedPath(storePrefix, originalPath));
				sameDirectory = (f.nativePath == concatenatedPath);
				if(sameDirectory)
					return log("Load and Store directory are equal, abort");
				var fr:Object = new FileStreamClass();
					fr.addEventListener(Event.COMPLETE, fropen);
					fr.openAsync(f, 'write');
				
				function fropen(e:Event):void {
					fr.removeEventListener(Event.COMPLETE, fropen);
					fr.writeBytes(data);
					fr.close();
					fr = null;
					f = null;
					log("saved", storePrefix, originalPath,  data ? data.length / 1024 : 0, 'kb');
				}
			} catch (e:*) {
				log("save failed",storePrefix, originalPath,e, data ? data.length / 1024 : 0, 'kb')
			}
		}
	}
	private function onHttpResponseStatus(e:HTTPStatusEvent):void
	{
		if (extension == null)
		{
			var headers:Array = e["responseHeaders"];
			var contentType:String = getHttpHeader(headers, "Content-Type");
			
			if (contentType && /(audio|image)\//.exec(contentType))
				extension = contentType.split("/").pop();
		}
	}
	
	private function onLoadProgress(e:ProgressEvent):void
	{
		if (onProgress is Function && e.bytesTotal > 0)
			onProgress(e.bytesLoaded / e.bytesTotal, numOriginal - numElements, numOriginal, filename);
	}
	
	
	private function onLoaderComplete(event:Object):void
	{
		urlLoader.data.clear();
		loaders[filename] = loaderInfo.loader;
		bothLoadersComplete(event.target.content);
	}
	
	private function onError(e:Event):void
	{
		bothLoadersComplete(null);
	}
	
	private function getConcatenatedPath(prefix:String, originalUrl:String):String
	{
		if(prefix.match( /(\/$|\\$)/) && originalUrl.match(/(^\/|^\\)/))
			prefix = prefix.substr(0,-1);
		if((FileClass == null) || prefix.match(/^(http:|https:|ftp:|ftps:)/i))
			return prefix + originalUrl;
		else
		{
			// workaround for inconsistency of traversing up directories. FP takes working dir, AIR doesn't
			var initPath:String = prefix.match(/^(\.\.)/i) ?  FileClass.applicationDirectory.nativePath + '/' + prefix : prefix
			try {
				var f:Object = new FileClass(initPath) 
				initPath = f.resolvePath(f.nativePath + originalUrl).nativePath;
				f = null;
			}
			catch (e:*) { log(prefix + originalUrl, e), initPath = prefix + originalUrl}
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
	
	private  function getHttpHeader(headers:Array, headerName:String):String
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
	
	private static var _context:LoaderContext;
	private static function get context():LoaderContext
	{
		if(!_context)
			_context = new LoaderContext(Ldr.policyFileCheck);
		_context.imageDecodingPolicy = ImageDecodingPolicy.ON_LOAD;
		return _context;
	}
	
	public function destroy():void
	{
		// TODO Auto Generated method stub
	}
}
package  axl.utils
{
	/**
	 * [axldns free coding 2015]
	 */
	import flash.display.Bitmap;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.media.Sound;
	import flash.net.URLLoader;
	
	/**
	 * <h1>Singletone files loader </h1>
	 * It 
	 * <ul>
	 * <li>loads files from local and remote directories - supports relative paths on both (general rules apply)</li>
	 * <li>looks up for user defined alternative directories (if file not found) in user defined order</li>
	 * <li>stores to hdd (AIR) on various conditions, including date comparison, file-directory-extension filters, user defined filters.</li>
	 * <li>Supports multi queues with various and mixed types of addressing (arrays, vectors with/or File class instances, strings of paths and sub-paths</li>
	 * <li>provides detailed info about progress and full controll on loading process (pause, stop, resume, queues/files re-index)</li>
	 * <li>processes commonly known data to expose usable forms (images, sounds, xmls, json) but leaves the rest un-touched.</li>
	 * </ul>
	 * <br>All that within one line of code, more ! with just one function! That's it. Don't need to learn anything else. Easily accesible without instantiation, 
	 * anywhere in your code just like <code>Ldr.load()</code> 
	 * <br><br>
	 * <h2>Singleton asset manager</h2>
	 * All objects are also super simple to access with just one command, anywhere from the code just like <code>Ldr.getMe()</code> 
	 * This Ldr assumes you know what you're doing, and if you're dealing with files, you want to call 'file.txt' rather than 'file'.
	 * <br> You can load and get file.png, file.jpg, file.atf, file.xml, file.txt and call them all whenever you like without worrying of anything else. 
	 * <br>Properly set up, even three lines of code can make a robust solution for assets update managed fully server side (mobile apps).
	 * <br>Full controll on loading process (pause, stop, resume, queues re-index) error handling, verbose mode
	 * 
	 *
	 */
	public class Ldr
	{
	
		
		private static var objects:Object = {};
		private static var urlLoaders:Object = {};
		private static var loaders:Object = {};
		
		Req.loaders = loaders;
		Req.objects = objects;
		Req.urlLoaders = urlLoaders;
		
		private static var requests:Vector.<Req> = new Vector.<Req>();
		//private static var requests:Array = [];
		
		private static var IS_LOADING:Boolean;
		
		public static var policyFileCheck:Boolean;
		
		private static var locationPrefixes:Array = [];
		
		/**
		 * (AIR only)
		 * 
		 *  @default  File.applicationStorageDirectory
		 * 
		 *  @see Ldr#load
		 *  @see Ldr#defaultOverwriteBehaviour
		 */
		public static var defaultStoreDirectory:Object = Req.fileInterfaceAvailable ? Req.FileClass.applicationStorageDirectory : null;
		
		/**
		 * (AIR only)
		 * Defines what files to overwrite if path where the file was loaded from is different to store directory.
		 * <br>This behaviour can be overriden by specifing appropriate load argument (see <i>load</i> 
		 * and <i>load</i> desc). 
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
		 * @see Ldr#load
		 */
		public static var defaultOverwriteBehaviour:Object = 'networkOnly';
		
		
		/**
		 * defaultPathPrefixes allow you to look up for files to load in any number of directories in a single call.
		 * <b>Every</b> load call is prefixed but prefix can also be an empty string.
		 * <br>This behaviour can be overriden by specifing appropriate load argument (see load and load desc). 
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
		 * @see Ldr#load */
		public static function  get defaultPathPrefixes():Array { return locationPrefixes }
		
		/** tells you if any loading is in progress */
		public static function get isLoading():Boolean 	{ return IS_LOADING }
		
		/** returns remaining number of object to load in <u>current</u> queue */
		public static function get numCurrentRemaining():int { return (numQueues > 0) ? requests[0].numRemaining : 0 }
		
		/** returns number of paths which has been originally scheduled to load (takes add- and remove- toCurrentQueue into account)*/
		public static function get numCurrentQueued():int { return (numQueues > 0) ? requests[0].numQueued : 0}
		
		/** returns number of queues including current one */
		public static function get numQueues():int { return requests.length }
		
		/** returns number of all remainig elements in all queues including current one. */
		public static function get numTotalRemaining():int { return Req.numAllRemaining }
		
		/** returns number of all originally queued elements in all queues. includes current queue
		 * and already loaded files within session (from the moment there were no queues at all). Gets back to 0 once all queues are done. */
		public static function get numTotalQueued():int { return Req.numAllQueued}
		
		
		/** 
		 * adds path, file or list to load to current queue. 
		 * This is not preffered method for adding elelments to queue since <code>Ldr.load</code> accepts arrays, vectors, xmls. 
		 * <br>Use <i>addToCurrentQueue</i> when you need to inject to current. However,
		 * If current queue does not exist, this method creates one, and waits for <code>Ldr.load(null,..your args)</code> once you're done with adding,
		 * but <b>BEWARE</b>: Every later call to Ldr.load with specified pathList will be hold (queued) and won't start until you finalize this one 
		 * with <code>Ldr.load(null,..your args)</code>
		 * @return number of elements addded
		 * 
		 * @see Ldr#load
		 */
		public static function addToCurrentQueue(resourceOrList:Object):int
		{
			if(numQueues > 0)
				return requests[0].addPaths(resourceOrList);
			else
			{
				requests.push(new Req());
				return requests[0].addPaths(resourceOrList);
			}
		}
		
		/**  removes path, file or list to remove from current queue. 
		 @return number of elements removed*/
		public static function removeFromCurrentQueue(resourceOrList:Object):int
		{
			return isLoading ? requests[0].removePaths(resourceOrList) : 0;
		}
		
		
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
		 * or passed directly to <code>load</code> array
		 * @return null / undefined if asset is not loaded or data as above if loaded:<br>
		 * 
		 * @see Ldr#load
		 * @see Ldr#defaultPathPrefixes
		 */
		public static function getme(v:String):Object { return objects[v] || getmeFromPath(v) }
		public static function getmeFromPath(v:String):Object
		{
			var i:int = v.lastIndexOf('/')+1, j:int = v.lastIndexOf('\\')+1;
			return objects[v.substr(i>j?i:j)];
		}
		
		public static function getBitmap(v:String):Bitmap { return getme(v) as Bitmap }
		public static function getXML(v:String):XML { return getme(v) as XML }
		public static function getJSON(v:String):Object { return getme(v) }
		public static function getSound(v:String):Sound { return getme(v) as Sound }
			
		/**
		 * Loads all assets <strong>synchroniously</strong> from array of paths or subpaths,
		 * checks for alternative directories, stores loaded files to directories (AIR only).
		 * It does not allow to load same asset twice. Use <code>Ldr.unload</code> to remove previously loaded files.
		 *
		 * @param resources :  basic types [string, file, xml] or list types: [array, vector,xmllist] of basic types. 
		 * <br>Simple elements must always point to path/subpath file with an extension. eg.: <code> ["/assets/images/a.jpg", "http://abc.de/fg.hi"]</code> 
		 * <br> Resources can be mixed together and embed to the reasonable level of depth - lists are parsed recursively.
		 * <br>(air)Can read File class instances
		 * <br> XML nodes may be of two names: files and file. files attribute <i>dir</i> will be prefixed to every value of file node inside it.
		 * <pre>
		 * < files dir="/assets">
		 * 	< file>/sounds/one.mp3< /file>
		 *  	< files dir="images">
		 * 		< file>two.png< /file>
		 * 		< file>two.jpg< /file>
		 * 	< /files>
		 * < /files>
		 * < file>/config/workflow/init.xml< /file>
		 * </pre>
		 * This would queue:
		 * <br>/assets/sounds/one.mp3
		 * <br>/asset/images/two.png
		 * <br>/assets/images/two.jpg
		 * <br>/config/workflow/init.xml
		 * @param onComplete : function to execute once queue is done. this suppose to execute always, 
		 * regardles of issues with particular asssets. Exception is calling Ldr.load with null for <u>resources</u> parameter while no queue is awaiting to start. 
		 * @param individualComplete : <code>function(loadedAssetName:String)</code> this function may not be executed if particular asset fails to laod
		 * @param onProgress : function which should accept four arguments:
		 * <ul>
		 * <li><i>Number</i> - bytesLoaded / bytesTotal of current asset
		 * <li><i>int</i> - number of already loaded assets
		 * <li><i>int</i> - total number assets in current queue
		 * <li><i>String</i> - processed file name
		 * </ul>
		 * To get info of all queues query Ldr.numQueues, Ldr.numTotalQueued, Ldr.numTotalRemaining whenever you need it. 
		 * Probably on individualComplete would be right moment to do so
		 * @param pathPrefixes: Vector or array of Strings(preffered) or File class instances pointing to directories.
		 * <br> final requests are formed as pathPrefixes[x] + pathList[y]
		 * <ul><li><i>null</i> will use pathList[y] only</li>
		 * <li><i>:default</i> uses <u>Ldr.defaultPathPrefixes</u></li></ul>
		 * @param storeDirectory: (AIR) <i>:default</i> uses <u>Ldr.defaultStoreDirectory</u>, <i>null</i> disables storing, any other tries to resolve path and store loaded asset accordingly
		 * @param overwriteExistingFiles (AIR) 'networkOnly' || 'all' || 'none' || 'olderThan_<i>unixTimestamp</i>' || Array/Vector of subpaths or File instances
		 * <br><i>:default</i> uses  <u>Ldr.defaultOverwriteBehaviour</u>
		 * @return index of the queue this request has been placed on. -1 if pathList is empty and and tere are no queues to process
		 * 
		 * @see Ldr#defaultPathPrefixes
		 * @see Ldr#defaultStoreDirectory
		 * @see Ldr#defaultOverwriteBehaviour
		 */
		public static function load(resources:Object=null, onComplete:Function=null, individualComplete:Function=null
												,onProgress:Function=null, pathPrefixes:Object=":default", storeDirectory:Object=":default",
												 overwriteExistingFiles:Object=":default"):int
		{
			Req.verbose = trace;
			var req:Req, id:int = 0;
			if(resources == null)
			{
				if((requests.length < 1))
					return -1;
				else if(requests[0].isLoading)
					return 0;
				else
					req = requests[0];
			}
			else
			{
				req = new Req();
				id = requests.push(req)-1;
			}
			
				req.prefixes = (pathPrefixes == ':default' ? Ldr.defaultPathPrefixes : pathPrefixes);
			if(Req.fileInterfaceAvailable)
			{
				req.storePath = (storeDirectory == ':default' ? Ldr.defaultStoreDirectory : storeDirectory);
				req.overwrite = (overwriteExistingFiles == ":default" ? Ldr.defaultOverwriteBehaviour : overwriteExistingFiles);
			}
				req.onComplete = onComplete;
				req.individualComplete = individualComplete;
				req.onProgress = onProgress;
				
				req.addPaths(resources);
				
			if(!IS_LOADING)
			{
				req.addEventListener(flash.events.Event.COMPLETE, completeHandler);
				req.load();
			}
			IS_LOADING = true;
			return id;
			function completeHandler(e:Event):void
			{
				var rComplete:Function = req.onComplete;
				requests.splice(id,1);
				req.removeEventListener(flash.events.Event.COMPLETE, completeHandler);
				req.destroy();
				IS_LOADING = (numQueues > 0);
				if(IS_LOADING)
				{
					req = requests[0];
					id = 0;
					req.addEventListener(flash.events.Event.COMPLETE, completeHandler);
					req.load();
				}
				else
				{
					Req.allQueuesDone();
					req = null;
				}
				if(rComplete is Function)
					rComplete();
				rComplete=null;
			}		
		}
		private static function log(v:String):void { U.bin.trrace("LDR:", v) }
		
	
		
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
		
	}
}

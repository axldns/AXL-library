internal class Behaviors 
{
	public const loadOverwrite:int=0;
	public const loadSkip:int=1;
	public const downloadOnly:int=2;
	public function Behaviors(){}
}
package  axl.utils
{
	import flash.display.Bitmap;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.media.Sound;
	import flash.system.System;
	import flash.utils.ByteArray;
	
	/**
	 * <h1>Singletone files loader </h1>
	 * It easily allows you to load/unload/save files, instantiate AS3 Objects out of file contents, keep your server and app files in sync.
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
	 * <br>Full controll on loading process (pause, resume, queues re-index) error handling, verbose mode
	 * 
	 * <br><br> XML may contain two types of nodes: files and file. file nodes should hold only filename or sub-path. files nodes should be a list of file nodes. files also can have 
	 * an attribute <code>dir</code> Such an attribute will be a prefix to all its sub-nodes.
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
	 * 
	 */
	public class Ldr
	{
		private static var externalProgressListeners:Vector.<Function> = new Vector.<Function>();

		public static function get loaders():Object	{return uloaders}
		public static function get loaderInfos():Object	{return linfos}
		public static function get objects():Object {return uobjects}

		public static function log(...args):void { if(_verbose is Function) _verbose.apply(null,args) }
		public static function set verbose(func:Function):void { _verbose = func = Req.verbose = func }
		private static var _verbose:Function;
		public static const defaultValue:String = ":default";
		
		public static const behaviours:Behaviors = new Behaviors();
		private static var uobjects:Object = {};
		private static var uloaders:Object = {};
		private static var linfos:Object = {};
		private static var requests:Vector.<Req> = new Vector.<Req>();
		public static var displayStateBreakDown:Boolean;
		
		private static var IS_LOADING:Boolean;
		public static var policyFileCheck:Boolean;
		
		/** Indicates weather app has flash.filesystem.File class accessible */
		public static function get fileInterfaceAvailable():Boolean { return Req.fileInterfaceAvailable }
		public static function get FileClass():Class { return Req.FileClass }
		/**
		 * (AIR only)<br>
		 Defines default value if <code>storeDirectory</code> argument of method <code>Ldr.load</code> is ommited.
		 * @default File.applicationStorageDirectory;
		 * @see Ldr#load */
		public static var defaultStoreDirectory:Object = Req.fileInterfaceAvailable ? Req.FileClass.applicationStorageDirectory : null;
		
		/**
		 * (AIR only)<br>
		 Defines default value if <code>storingBehavior</code> argument of method <code>Ldr.load</code> is ommited.
		 * @default ''
		 * @see Ldr#load */
		public static var defaultStoringBehavior:Object = '';
		
		
		/** Defines default value if <code>pathPrefixes</code> argument of method <code>Ldr.load</code> is ommited.
		 * @default ['']
		 * @see Ldr#load */
		public static var defaultPathPrefixes:Object = [];
		
		 /***Defines default value if <code>loadBehavior</code> argument of method <code>Ldr.load</code> is ommited.
		 *	@default Ldr.behaviours.loadSkip (1)
		 *  @see Ldr#load*/
		public static var defaultLoadBehavior:Object = 1;//Ldr.behaviours.loadSkip;
		
		/** <code>true</code>: If element's subpath matches <code>/^(http:|https:|ftp:|ftps:)/i</code>
		 * Ldr will try to load subpath only.
		 * <br><code>false</code>: regular Behavior where url = prefix[i] + subpath[j]
		 * <br>default: <code>true</code> * */
		public static function set networkOverPrefixes(v:Boolean):void { Req.networkOverPrefixes }
		public static function get networkOverPrefixes():Boolean { return Req.networkOverPrefixes }
		
		/** tells you if any loading is in progress */
		public static function get isLoading():Boolean 	{ return (numQueues > 0) &&  requests[0].isLoading }
		
		/** returns number of queues including current one */
		public static function get numQueues():int { return requests.length }
		
		/** returns number of elelements remained to load within current queue. 0 if there is no current queue */
		public static function get numCurrentRemaining():int { return (numQueues > 0) ? requests[0].numRemaining : 0}
		
		/** returns number of elements that has been originally scheduled to load. 0 if there is no current queue */
		public static function get numCurrentQueued():int { return (numQueues > 0) ? requests[0].numQueued : 0}
		
		/** returns number of successfully loaded elements in current queue. 0 if there is no current queue */
		public static function get numCurrentLoaded():int { return (numQueues > 0) ? requests[0].numLoaded : 0}
		
		/** returns number of elements that failed to load within current queue. 0 if there is no current queue */
		public static function get numCurrentSkipped():int { return (numQueues > 0) ? requests[0].numSkipped : 0}
		
		/** returns number of all remainig elements in all queues. Rolls back to 0 when all queues are done*/
		public static function get numAllRemaining():int { return Req.numAllRemaining }
		
		/** returns number of all originally queued elements in all queues. Rolls back to 0 once all queues are done. */
		public static function get numAllQueued():int { return Req.numAllQueued }
		
		/** returns number of all successfully loaded elements in all queues.  Rolls back to 0 once all queues are done. */
		public static function get numAllLoaded():int { return Req.numAllLoaded }
		
		/** returns number of all elements that failed to load within all queues. Rolls back to 0 once all queues are done. */
		public static function get numAllSkipped():int { return Req.numAllSkipped }
		
		
		public static function addExternalProgressListener(v:Function):Boolean
		{
			var unique:Boolean = externalProgressListeners.indexOf(v) < 0;
			if(unique) externalProgressListeners.push(v);
			return unique;
		}
		public static function removeExternalProgressListener(v:Function):Boolean
		{
			var exists:int = externalProgressListeners.indexOf(v);
			if(exists > -1) externalProgressListeners.splice(exists,1);
			return (exists > -1);
		}
		
		/** 
		 * adds path, file or list to load to current queue. 
		 * This is not preffered method for adding elelments to queue since <code>Ldr.load</code> accepts arrays, vectors, xmls. 
		 * <br>Use <i>addToCurrentQueue</i> when you need to inject to current. However,
		 * If current queue does not exist, this method creates one, and waits for <code>Ldr.load(null,..your args)</code> once you're done with adding,
		 * but <b>BEWARE</b>: Every later call to Ldr.load with specified pathList will be hold (queued) and won't start until you finalize this one 
		 * with <code>Ldr.load(null,..your args)</code>
		 * @return new queue length
		 * @see Ldr#load */
		public static function addToCurrentQueue(resourceOrList:Object):int
		{
			if(numQueues > 0) return requests[0].addPaths(resourceOrList);
			else
			{
				requests.push(new Req());
				return requests[0].addPaths(resourceOrList);
			}
		}
		
		/**  removes path, file or list to remove from current queue. 
		 @return new queue length*/
		public static function removeFromCurrentQueue(resourceOrList:Object):int
		{
			return isLoading ? requests[0].removePaths(resourceOrList) : 0;
		}
				
		/** @param v - Object name e.g. 'image.txt' @return <code>Object</code> 
		 * or <code>null</code> if name doesn't match any loaded object */
		public static function getAny(v:String):Object { return objects[v] || getmeFromPath(v) }
		private static function getmeFromPath(v:String):Object {
			var i:int = v.lastIndexOf('/')+1, j:int = v.lastIndexOf('\\')+1;
			return objects[v.substr(i>j?i:j)];
		}
		
		/** @param v - ByteArray name e.g. 'image.atf' @return <code>ByteArray</code> 
		 * or <code>null</code> if name doesn't match any loaded object */
		public static function getByteArray(v:String):ByteArray { return getAny(v) as ByteArray }
		
		/** @param v - name of Bitmap e.g. 'image.jpg' @return <code>Bitmap</code> 
		 * or <code>null</code> if name doesn't match any loaded object */
		public static function getBitmap(v:String):Bitmap { return getAny(v) as Bitmap }
		
		/** Use it when you're re-using bitmap. Unlike getBitmap - this creates
		 * new object in memory(!), leaving original untouched. 
		 * @param v - name of Bitmap e.g. 'image.jpg' @return <code>Bitmap</code> 
		 * or <code>null</code> if name doesn't match any loaded object */
		public static function getBitmapCopy(v:String):Bitmap { 
			var b:Bitmap =  getAny(v) as Bitmap;
			if(b != null)
				return new Bitmap(b.bitmapData, 'auto', true)
			return null;
		}
		
		/** @param v - name of XML e.g. 'image.xml' @return <code>XML</code> 
		 * or <code>null</code> if name doesn't match any loaded object */
		public static function getXML(v:String):XML { return getAny(v) as XML }
		
		/** @param v - name of sound e.g. 'image.mp3' @return <code>Sound</code> 
		 * or <code>null</code> if name doesn't match any loaded object */
		public static function getSound(v:String):Sound { return getAny(v) as Sound }
		
		/** @param regexp - all objects matching regexp will be returned. e.g. /./ would return all objects
		 * @param target - array to put matching objects into, one will be created if omitted 
		 * @param onlyTypes - Array of class names to filter your results [Bitmap, XML] would return
		 * only Bitmaps and XML objects that are matching your regexp 
		 * @return array of objects that are matching your <code>regexp</code> and <code>onlyTypes</code> filter*/
		public static function getMatching(regexp:RegExp,target:Array=null, onlyTypes:Array=null):Array
		{
			target = target || [];
			var ti:int = target.length;
			for (var s:String in objects)
				if(s.match(regexp))
					target[ti++] = objects[s];
			if(onlyTypes is Array)
				while(ti-->0)
					for(var i:int = onlyTypes.length; i>0; i--)
						if(!(target[ti] is onlyTypes[i]))
							target.splice(ti++,1);
			return target;
		}
		
		/** @param regexp - all objects names matching regexp will be returned. 
		 * e.g. /./ would return all loaded content names
		 * @param target - vector to put names into. one will ve created if omitted
		 * @return <code>Vector.String</code> of object's names matching your <code>regexp</code>*/
		public static function getNames(regexp:RegExp=null,target:Vector.<String>=null):Vector.<String>
		{
			target = target || new Vector.<String>();
			var ti:int = target.length;
			for (var s:String in objects)
				if(s.match(regexp))
					target[ti++] = s;
			return target;
		}
			
		/**
		 * Loads all elements/files one by one from array of paths, subpaths or single url.
		 * Checks for alternative directories, stores loaded files to directories (AIR only).
		 * It controlls loading same asset twice. Use <code>Ldr.unload</code> to
		 * remove previously loaded and instantiated files.
		 *
		 * @param resources : Basic types: <code>String, File, XML, XMLList</code> 
		 * or collections: <code>Array, Vector</code> of basic types. 
		 * <br>Basic elements must always point to file with an extension exposed. 
		 * eg.: <code> ["/assets/images/a.jpg", "http://abc.de/fg.hi"]</code> 
		 * Exception is the File class instance; If it points to directory, whole directory will be scanned recursively and every
		 * file found will be added to queue. 
		 * <br> Resources can be mixed together and nest to the reasonable level of depth - lists are parsed recursively too!
		 * Check class description to see examples including XML patterns.
		 * 
		 * @param onComplete : function to execute once queue is done. this suppose to execute always, 
		 * regardles of issues with particular asssets. Exception is calling <code>Ldr.load(null, ..anyArgs)</code>
		 * while queue is already loading. This prevents before overwriting listeners and/or dispatching 
		 * when actually not done. 
		 * 
		 * @param individualComplete : <code>function(loadedAssetName:String)</code> this function 
		 * may not be executed if loader can't resolve either prefix  or path to resource, 
		 * but it is executed if loading failes - 
		 * <code>Ldr.getAny(loadedAssetName)</code> would return <code>null</code> in this case.
		 * As long as you pass correct resource types, function should always get executed.
		 * <br>individualComplete function will get executed only once for one item, 
		 * regardless of how many prefixes has been checked for it before.
		 * 
		 * @param onProgress : function which should accept two arguments:
		 * <ul>
		 * 	<li><code>Number</code> - bytesLoaded / bytesTotal of current asset
		 * 	<li><code>String</code> - name of currently loaded element
		 * </ul>
		 * To get detailed info of queue(s) status, whenever you need it query <code>Ldr.num^</code> getters
		 * Don't worry - there are no calculations on query time - values are being updated only when queue(s) status changes.
		 * 
		 * @param pathPrefixes: These values will be prefixes for <code>resources</code> defined elemements.
		 * <br>Consieder it as a member of simplified equasion where
		 * <br><code>singleElementUrl = pathPrefixes[i] + resources[j]</code>
		 * <br><i>Double joints</i> like "//" or "\\" or even missing separators should get fixed automatically.
		 * 	<br>If loading fails, pathPrefixes index will keep increassing until a) element will get loaded <b>or</b> 
		 * b) pathPrefixes index will reach maximum value.
		 * <br>In both cases pathPrefix index will roll back to 0 for the next element. 
		 * Process applies to every queued item, therefore use your pathPrefixes wisely.
		 * <ul>
		 * 	<li><code>resource</code> -  Object is parsed simmilar way as <code>resources</code> argument is but: 
		 * 		<br><b>1</b> pathPrefixes must not point to files (directories only)
		 * 		<br><b>2</b> directories are not scanned recursively (simple hook)
		 * 	<li><code>null</code> will match pathList only (empty prefix adds itself)</li>
		 * 	<li><code>Ldr.defaultValue</code> uses <u>Ldr.defaultPathPrefixes</u></li>
		 * </ul>
		 * 
		 * @param loadBehaviour:
		 * <ul>
		 * <li><code>Ldr.behaviors.loadOverwrite</code> - any previously loaded elements of the same name as particular element
		 * (requested to load) will be unloaded and removed from memory. All loaded elements will be instantiated.
		 * <li><code>Ldr.behaviors.loadSkip</code> - any previously loaded elements of the same name 
		 * will cause to <b>skip</b> loading queue element. onIndividualComplete will get executed, counters updated,
		 * queue will continue as usual.</li>
		 * <li><code>Ldr.downloadOnly</code> (AIR) - none of loaded elements will be instantiated. 
		 * Saving files on disc will proceed according to storingBehavior</li>
		 * <li><code>function(colidingFilename:String):String</code></li> - custom filter allows <u>you</u> to define what to do
		 * 		<u>if</u> name of element requested to load colides with already loaded resources.
		 * 		<br>return <code>null</code> to <b>skip</b> loading the file.
		 * 		<br>return <code>String</code> to assign either new or the same name. Any name colision  after this point will cause 
		 * to unload existing resource and new will take its place.</li>
		 * <li><code>Ldr.defaultValue</code> will use <u>Ldr.defaultLoadBehavior</u></li>
		 * </ul>
		 * 
		 *  @param storingBehavior (AIR):
		 * 	<ul>
		 * <li><code>Ldr.Behaviors.default</code> will perform using <u>Ldr.defaultStoringBehavior</u> values.
		 * 	<li><code>RegExp</code> particular resource will be stored in <code>storeDirectory</code>
		 *  	if its URL matches your your RegExp. Good scenario to store network updated files only by 
		 * 		passing <code>/^(http:|https:|ftp:|ftps:)/i</code> or to filter storing by extensions. 
		 * 		<br>Pass /./ to store/overwrite all files from this queue.
		 * 		<br>Define storeDirectory as <code>null</code> to disable storing files from this queue.
		 *  <li><code>Date</code> or <code>Number</code> where number is unix timestamp. This stores files if 
		 *		<br> a) file does not exist in storeDirectory yet
		 *		<br> b) your date is greater than existing file modification date.</li>
		 * 	<li><code>function(existing:File, loadedFrom:String):File</code> - 
		 * 		<br>This function would be called for every element loaded from address different to storeDirectory. 
		 * 		This allows <u>you</u> to decide if (and where) file should get saved/overwritten. 
		 * 		By dispatch time you're receiving an empty pointer to directory resolved according to 
		 * 		<code>storeDirectory + resource[i]</code> (sub path) 
		 * 		File existance, contents and address are not being verified and may be result of any activty 
		 * 		but you may want to use them as your criteria. 
		 * 		<br>Closure excepts a pointer to file in any storable directory as an output. 
		 * 		<br><code>null</code> or incorrect values will withold this file from storing. Performance is on you in this case.
		 * </ul>
		 * @param storeDirectory (AIR): 
		 * Defines where to store loaded files if <code>storingBehavior</code> allows to do so.
		 *  If value can't be interpreted as storable directory - no storring will happen, regardless of storingBehavior assigned. E.g.:<br>
		 * 	 <code>
		 * 	Ldr.load("/assets/image.png",null,null,null,"http://domain.com",File.applicationStorageDirectory,/./);
		 * 	</code>
		 * <br>would load: http://domain.com/assets/image.png
		 * <br>would save: app-storage:/assets/image.png
		 * <ul>
		 * 	<li><code>Ldr.defaultValue</code> uses <u>Ldr.defaultStoreDirectory</u></li>
		 * 	<li><code>String</code> tries to resolve path
		 * 	<li><code>File</code> tries to resolve path
		 * 	<li><code>null</code> and/or other incorrect values - disables storing</li>
		 * </ul> 
		 * @param timeOutMS: Defines time (ms) after which particular element request will move to the next
		 * path prefix (if specifed) or to the next element in queue IF server does not response at all.
		 * If your server is down, response may not come immediately but after browser defined timeout or (AIR) urlRequest.idleTimeout value.
		 * Use this parameter to shorten your response awaiting time. This limits OPEN time, not loading time.
		 * 
		 * @return 
		 * <ul>
		 * <li><code>-2</code> if there are no resources specified and no queues to start</li>
		 * <li><code>-1</code> if there are no resources specified and queue is already started</li>
		 * <li><code><i>ID</i></code> of the queue</li></ul>*/
		public static function load(resources:Object=null, onComplete:Function=null, individualComplete:Function=null
												,onProgress:Function=null, pathPrefixes:Object=Ldr.defaultValue, 
												 loadBehavior:Object=Ldr.defaultValue, storingBehavior:Object=Ldr.defaultValue,
												 storeDirectory:Object=Ldr.defaultValue, timeOutMS:int=0):int
		{
			log("[Ldr] request load.");
			var req:Req;
			var len:int = requests.length;
			if(resources == null)
			{
				if(len < 1) return (onComplete is Function) ? onComplete() : -2;
				else if(requests[0].isLoading) return -1; // do not overwrite current callbacks
				else req = requests[0]; // created with addToQueue
			}
			else
			{
				req = new Req();
				req.id = new Date().time + len;
				requests[len] = req;
			}
			
				req.loadBehavior = (loadBehavior == Ldr.defaultValue ? Ldr.defaultLoadBehavior :  loadBehavior)
			if(Req.fileInterfaceAvailable)
			{
				req.storeDirectory = (storeDirectory == Ldr.defaultValue ? Ldr.defaultStoreDirectory : storeDirectory);
				req.storingBehavior = (storingBehavior == Ldr.defaultValue ? Ldr.defaultStoringBehavior : storingBehavior);
			}
				req.onComplete = onComplete;
				req.individualComplete = individualComplete;
				req.onProgress = onProgress;
				
				req.addPaths(resources);
				req.addPrefixes((pathPrefixes == Ldr.defaultValue ? Ldr.defaultPathPrefixes : pathPrefixes));
				req.timeOut = (timeOutMS > 0) ? timeOutMS : NetworkSettings.defaultTimeout;
			if(!IS_LOADING)
			{
				IS_LOADING = true;
				U.log("[Ldr][LISTENERS ADD]");
				req.addEventListener(Event.COMPLETE, completeHandler);
				req.addEventListener(Event.CHANGE, progressHandler);
				req.load();
			}
			return req.id;
		}
		
		protected static function progressHandler(e:Event):void
		{
			var i:int = externalProgressListeners.length;
			while(i-->0)
				externalProgressListeners[i]();
		}
		
		protected static function completeHandler(e:Event):void
		{
			reqComplete(e.target as Req);
		}
		
		private static function reqComplete(req:Req, dispatchComplete:Boolean=true):void
		{
			var st:String = state;
			var index:int = requests.indexOf(req);
			if(index > -1)
				requests.splice(index,1);
			req.removeEventListener(Event.COMPLETE, completeHandler);
			req.removeEventListener(Event.CHANGE, progressHandler);
			if(dispatchComplete && (req.onComplete != null))
				req.onComplete();
			req.destroy();
			IS_LOADING = (numQueues > 0);
			if(IS_LOADING)
			{
				log("[Ldr] current queue finished with state:");//, st, '\ntimer:', getTimer()-startTime, 'ms');
				req = requests[0];
				req.addEventListener(Event.COMPLETE, completeHandler);
				req.addEventListener(Event.CHANGE, progressHandler);
				req.load();
			}
			else
			{
				Req.allQueuesDone();
				req = null;
				log("[Ldr] all queues finished. state:", st);//, '\ntimer:', getTimer()-startTime, 'ms');
			}
			
			st = null;
		}
		
		
		/** pauses current queue and returns its ID or -1 if there is nothing to pause */
		public static function pauseCurrent():Number
		{
			log('[Ldr][PAUSE] state:', state);
			if(numQueues > 0) { return requests[0].pause()}
			else return -1;
		}
		
		/** un-pauses current queue
		 * @return <code>-1</code> there are no queues or queueID otherwise */
		public static function resumeCurrent():Number
		{
			if(numQueues > 0) {	return requests[0].resume()}
			else return -1;
		}
		
		/** if queueID is valid: removes current queue from queues queue and starts next one in order (if available)
		 * @return <code>-1</code> if queueID is not valid or <code>queueID</code> of removed queue otherwise */
		public static function removeCurrent(executeOnComplete:Boolean=false):Number
		{
			if(numQueues > 0)
			{
				var id:Number = requests[0].pause();
				reqComplete(requests[0], executeOnComplete);
				return id;
			} else return -1;
		}
		
		/** if queueID is valid: removes specific queue from queues queue. If it's current queue - starts next one in order.
		 * @return <code>-1</code> if queueID is not valid or <code>queueID</code> of removed queue otherwise */
		public static function removeQueueById(queueID:Number):Number
		{
			if(numQueues > 0)
			{
				var req:Req;
				var qi:int= requests.length;
				for(;qi-->0;)
					if(requests[qi].id == queueID)
						break;
				if(qi > 0)
				{
					req = requests[qi];
					req.removeEventListener(Event.COMPLETE, completeHandler);
					req.destroy();
					req.currentQueueDone();
					requests.splice(qi,1);
					return queueID;
				} 
				else if(qi == 0) { return removeCurrent(false) }
				else return -1;
			} else return -1;
		}
		
		/** if queueID is valid: pauses current queue and starts the one of queueID. 
		 * @return <code>false</code> if queueID is not valid, <code>true</code> otherwise */
		public static function makeCurrent(queueID:Number):Boolean
		{
			if(numQueues > 0)
			{
				var qi:int= requests.length;
				for(;qi-->0;)
					if(requests[qi].id == queueID)
						break;
				if(qi > 0)
				{
					requests[0].pause();
					requests.unshift(requests.splice(qi,1));
					requests[0].load();
					return true;
				}
				else if(qi == 0) return true;
				else return false
			} else return false;
		}
		
		/** returns current queue id or -1 if there are no queues */
		public static function get currentQueueID():Number { return (numQueues > 0) ? requests[0].id : -1 }
		
		/** returns info with counters of all queues and current queue */
		public static function get state():String
		{
			if(!displayStateBreakDown) return '';
			var s:String = String('-' + 
			'\n isLoading:' + isLoading + 
			'\n numQueues:' + numQueues + 
			'\n numAllQueued:' +  numAllQueued + 
			'\n numAllRemaining:' + numAllRemaining + 
			'\n numAllLoaded:' + numAllLoaded +
			'\n numAllSkipped:' + numAllSkipped +
			'\n numCurrentQueued:' + numCurrentQueued +  
			'\n numCurrentRemaining:' +  numCurrentRemaining + 
			'\n numCurrentLoaded:' + numCurrentLoaded +
			'\n numCurrentSkipped:' + numCurrentSkipped +
			'\n timestamp:' +  new Date().time + '\n-'
			);
			return s;
		}
		
		/**(AIR) Saves single file to storeDirectory + / subpath
		 * @param <code>subpath</code> e.g. "/assets/cfg.xml"
		 * @param <code>data</code> contents of the file. Preferably <code>ByteArray</code>
		 * however <code>String</code>and <code>XML</code> objects will be convertedto BA automatically. */
		public static function save(subpath:String, data:Object, storeDirectory:Object=Ldr.defaultValue):void
		{
			var ba:ByteArray;
			if(!(data is ByteArray))
			{
				ba = new ByteArray();
				if(data is String) ba.writeUTFBytes(data as String);
				else if(data is XML || data is XMLList) ba.writeUTFBytes(XML(data));
			} else ba = data as ByteArray
			var req:Req = new Req();
				req.storeDirectory = (storeDirectory == Ldr.defaultValue ? Ldr.defaultStoreDirectory : storeDirectory);
				req.storingBehavior = /./;
				req.saveIfRequested(ba, subpath,false);
				req.destroy();
				req = null;
		}
		
		/** Unloads / clears / disposes loaded data, removes display objects from display list
		 * <br> It won't affect sub-instantiated elements (XMLs, Textures, JSON parsed objects) but will make them 
		 * unavailable to restore (e.g. Starling.handleLostContext)*/
		public static function unload(resource:Object):void
		{
			var flatList:Vector.<String>= new Vector.<String>();
			Req.getFlatList(resource, flatList);
			while(flatList.length)
				unloadSingle(flatList.pop().replace(/(^.*)(\\|\/)(.+)/, "$3"));
			flatList = null;
		}
		
		private static function unloadSingle(filename:String):void
		{
			var o:Object = objects[filename];
			var l:Loader =loaders[filename];
			var found:Boolean;
			if(o is Object)
			{
				if(o.hasOwnProperty('parent') && o.parent != null && !(o.parent is Loader))
					o.parent.removeChild(o);
				if(o is Bitmap && o.bitmapData)
				{
					o.bitmapData.dispose();
					o.bitmapData = null;
				} 
				else if (o is ByteArray)
					ByteArray(o).clear();
				else if (o is XML)
					flash.system.System.disposeXML(o as XML)
				try { o.close() } catch (e:*) {}
				found = true;
			}
			if(l is Loader)
			{
				if(l.hasOwnProperty('parent') && l.parent)
					l.parent.removeChild(l);
				if(l.loaderInfo)
					l.loaderInfo.bytes.clear();
				l.unload();
				l.unloadAndStop();
				found = true;
			}
			o =null, l = null;
			objects[filename] = null;
			loaders[filename] = null;
			linfos[filename]= null;
			delete loaders[filename];
			delete objects[filename];
			delete linfos[filename];
			log('[Ldr][Unload]['+filename+'] ' + (found ? 'UNLOADED!' : 'not found..'));
		}
		
		public static function unloadAll():void
		{
			for(var s:String in objects)
				unloadSingle(s);
		}
	}
}

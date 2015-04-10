package axl.utils
{
	/**
	 * [axldns free coding 2015]
	 */
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.IBitmapDrawable;
	import flash.display.Stage;
	import flash.display.StageAlign;
	import flash.display.StageDisplayState;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.media.SoundMixer;
	import flash.system.Capabilities;
	
	import axl.ui.IprogBar;
	import axl.ui.Messages;
	

	/**
	 * Geometric utilty, handy tool, stage setter, quick refference. 
	 * Use <code>init</code> to init app flow: 
	 * <ul>
	 * <li> display splash</li> 
	 * <li>	set-up your stage and geometry</li>
	 * <li> load config</li>
	 * <li> load assets (with progress bar)</li>
	 * <li> instantiate starling
	 * <li> clean up and execute onInited </li>
	 */
	
	public class U
	{
		/** indicate tracings and bin agent instantiation*/
		public static var DEBUG:Boolean = true;
		/**
		 * indicates if stage is in full screen interactive mode or not<br>
		 * indicates if <code>U.REC</code> is based on <i>stage.fullScreen*W/H*</i> or <i>stage.stage*W/H*</i>
		 * <br>According to on playerType.match: <i> /^(StandAlone|ActiveX|PlugIn)/i </i>
		 */
		public static function get ISWEB():Boolean { return isWeb }
		private static var isWeb:Boolean = (Capabilities.playerType.match(/^(StandAlone|ActiveX|PlugIn)/i) != null);
		/**
		 * USE IT BEFORE INIT. CHANGES AFTER WON'T APPLY
		 */
		public static var onInited:Function;
		/**
		 * USE IT BEFORE INIT. CHANGES AFTER WON'T APPLY.
		 * Pass a path to well formated xml (pattern) to load your config. If you omite it, none of the assets will be loaded at launch,
		 * and Config class wont be instantiated
		 */
		private static var rec:Rectangle;
		private static var uSTG:flash.display.Stage;
		private static var flashRoot:DisplayObjectContainer;

		private static var udesignedForWidth:Number;
		private static var udesignedForHeight:Number;
		private static var uscalarX:Number;
		private static var uscalarY:Number;
		private static var uscalar:Number;
		
		private static var uscalarXreversed:Number;
		private static var uscalarYreversed:Number;
		private static var uscalarReversed:Number;
		
		private static var bsplash:DisplayObject;
		public static var progressBar:IprogBar;
		
		private static var ubin:BinAgent;
		private static var uconfig:XML;
		public static var configArguments:Array
		
		public static function get CONFIG():XML { return uconfig }
		
		/*** returns bin agent reference. Read BinAgent class description to see what it does */
		public static function get bin():BinAgent{ return ubin	}
		
		/** reference to values passed in <code>U.init</code> method. does affects on scallars only */
		public static function get designedForHeight():Number {	return udesignedForHeight }
		
		/** reference to values passed in <code>U.init</code> method. does affects on scallars only */
		public static function get designedForWidth():Number { return udesignedForWidth	}

		/** reference to flash display stage */
		public static function get STG():flash.display.Stage { return uSTG	}
		
		
		/** returns value of ... scalarX. See scalarX and Y defs*/
		public static function get scalar():Number	{ return uscalar }
		
		/**
		 * scalarY tells how much different current stage width is to values of designedFor.
		 *<br> othher words : REC.height / designedForHeight;
		 */
		public static function get scalarY():Number { return uscalarY }
		
		/**
		 * scalarY tells how much different current stage height is to values of designedFor.
		 *<br> othher words : REC.width / designedForWidth; 
		 */
		public static function get scalarX():Number { return uscalarX }
		
		/** returns value of ... scalarXreversed*/
		public static function get scalarReversed():Number	{ return uscalarReversed }
		
		/**
		 * scalarY tells how much different current stage width is to values of designedFor.
		 *<br> othher words :  designedForHeight / REC.height;
		 */
		public static function get scalarYreversed():Number { return uscalarYreversed }
		
		/**
		 * scalarY tells how much different current stage height is to values of designedFor.
		 *<br> othher words :  designedForWidth / REC.width; 
		 */
		public static function get scalarXreversed():Number { return uscalarXreversed }

		/**
		 * STAGE RECTANGLE utility.
		 * <br>Reffer e.g. <br>Utils.U.REC.bottom</br> or pass this to align functions like <code>U.center</code>, <code>U.align</code> or matrix transformations
		 */
		public static function get REC():Rectangle { return rec }
				
		
		/** Displays or hides flash stage splash if both splash and stage are instantiated. Messages are not covered by splash*/
		public static function set splash(v:Boolean):void
		{
			if(STG && bsplash)
			{
				if(v && !STG.contains(bsplash))
				{
					if(!Messages.areDisplayed)
						STG.addChild(bsplash);
					else
						STG.addChildAt(bsplash, STG.numChildren-1);
				}
				else if(!v && bsplash.parent)
					bsplash.parent.removeChild(bsplash)
			}
		}
		
		/**sets or replaces current stage splash object*/
		public static function set splashObject(v:DisplayObject):void
		{
			resolveSize(v, U.REC,true);
			center(v, U.REC);
			if(bsplash.parent)
			{
				bsplash.parent.removeChild(bsplash);
				bsplash = v;
				STG.addChild(bsplash);
			}
			else
				bsplash = v;
		}
		
		/**
		 * @param Inside: indicates whether to include coords of static (mov and static share the same coord space) or not (treat movable as a child of static)
		 * @param movable: any object which contains x,y,width,height
		 * @param static: any object which contains x,y,width,height
		 */
		public static function center(movable:Object, static:Object, inside:Boolean=true):void
		{
			movable.x = (static.width - movable.width) / 2 + (inside ? 0 : static.x );
			movable.y = (static.height - movable.height) / 2 + (inside ? 0 :  static.y);
		} 
		/**
		 * @param hor: left || center || right
		 * @param ver: bottom || center || top
		 * @param *Inside: indicates whether to include coords of static (mov and static share the same coord space) or not (treat movable as a child of static)
		 * @param movable: any object which contains x,y,width,height
		 * @param static: any object which contains x,y,width,height
		 */
		public static function align(movable:Object, static:Object, hor:String='center', ver:String='center', horizontalInside:Boolean=true, verticalInside:Boolean=true):void
		{
			switch (ver)
			{
				case "top":
					movable.y = verticalInside ? static.y : static.y - movable.height;
					break;
				case "center":
					movable.y = ((verticalInside ? 0 : static.y) + ((static.height - movable.height) / 2));
					break;
				case "bottom":
					movable.y = (verticalInside ? (static.y + static.height - movable.height) :  (static.y + static.height));
					break;
				
			}
			switch (hor)
			{
				case "left":
					movable.x = horizontalInside ? static.x : (static.x - movable.width);
					break;
				case "center":
					movable.x = ((horizontalInside ? 0 : static.x ) + ((static.width - movable.width) / 2));
					break;
				case "right":
					movable.x = (horizontalInside ? (static.x + static.width - movable.width) : (static.x + static.width));
					break;
			}
		}
		
		/**
		 * distributes all children of the container (according to their indexes) and returns container dimension
		 * @param cont: any display object container (either flash or starling)
		 * @param gap: value to add between each children
		 * @param horizontal: direction of distribution. function will return container.width if true and container.height if false
		 * @param offset: start value of first children (lives space at start)
		 * 
		 */
		public static function distribute(cont:Object, gap:Number, horizontal:Boolean=true, offset:Number=0):Number
		{
			var mod:Object = { a : horizontal ? 'x' : 'y', d : horizontal ? 'width' : 'height'}
			var ob:Object;
			var i:int =-1;
			var c:int = cont.numChildren;
			var totalSize:Number = offset;
			
			while(++i<c)
			{
				ob = cont.getChildAt(i);
				ob[mod.a] = totalSize;
				totalSize += ob[mod.d] + gap;
			}
			mod = null;
			ob = null;
			cont = null;
			return totalSize - gap;
		}
		
		public static function distributePattern(cont:Object, gap:Object=0, horizontal:Boolean=true, offset:Number=0, scaleGapAndOffset:Boolean=false):Number
		{
			var patternLength:int = 0;
			var numObjects:int = 0;
			var mod:Object = { a : horizontal ? 'x' : 'y', d : horizontal ? 'width' : 'height'}
			if(cont.hasOwnProperty("numChildren"))
			{
				numObjects =  cont.numChildren;
				getObject = getChild;
			}
			else // if(cont.hasOwnProperty('sort')) - does not work. neither vectors nor array return true for sort,push,pop,concat,etc.
			{
				numObjects = cont.length;
				getObject = getElement;
			}
			if(!isNaN(Number(gap)))
				getGap = getNumber;
			else // (gap.hasOwnProperty("sort")) as above
			{
				getGap = getGapPattern;
				patternLength = gap.length;
			}
			var ob:Object;
			var index:int =-1;
			var totalSize:Number = offset * (scaleGapAndOffset ? U.scalar : 1);
			
			if(scaleGapAndOffset)
			{
				while(++index<numObjects)
				{
					ob = getObject(index);
					ob[mod.a] = totalSize;
					totalSize += ob[mod.d] + (getGap(index) * U.scalar);
				}
			}
			else
			{
				while(++index<numObjects)
				{
					ob = getObject(index);
					ob[mod.a] = totalSize;
					totalSize += ob[mod.d] + getGap(index);
				}
			}
			
			mod = null;
			ob = null; 
			cont = null;
			getObject = null;
			
			var getObject:Function;
			function getChild(i:int):Object { return cont.getChildAt(i) }
			function getElement(i:int):Object { return cont[i] }
			
			var getGap:Function;
			function getNumber(i:int):Number { return Number(gap) }
			function getGapPattern(i:int):Number { return gap[i%patternLength] }
			return totalSize - (getGap(index-1)* (scaleGapAndOffset ? U.scalar : 1));
		}
		/**
		 * Resolves size of <code>movable</code> by comparing its aspect ratio to <code>static</code> aspect ratio TO FIT STATIC object dimensions.
		 * @param movable: object to resize (any type of object which consist properties of <code>width & height</code>)
		 * @param static: object to fit <code>movable</code> into. static object wont be resized. (<b>any</b> type of object which consist properties of <code>width & height</code>)
		 * @param outsidefit: if <code>true</code> movable is <strong>inscribed</strong> into static. if <code>false</code> movable is <strong>circumscribed around</strong> static
		 */
		public static function resolveSize(movable:Object, static:Object,outsidefit:Boolean=false):void
		{
			var r:Number = (movable.width / movable.height) ;
			if(r > (static.width / static.height))
			{
				if(outsidefit)
				{
					movable.height = static.height;
					movable.width = movable.height * r;
				}
				else
				{
					movable.width = static.width;
					movable.height = movable.width / r;
				}
			}
			else
			{
				if(outsidefit)
				{
					movable.width = static.width;
					movable.height = movable.width / r;
				}
				else
				{
					movable.height = static.height;
					movable.width = movable.height * r;
				}
			}
		}
		/**
		 * Copies properties FROM RIGHT to LEFT if left has right property availavble
		 * @param onlyProperies: allows to filter copying publicly available right fields. Copies only specified in array if both got them available
		 * @param left: object to change
		 * @param right: object to copy values from
		 */
		public static function copyProperties(left:Object, right:Object, onlyProperties:Array=null):void
		{
			if((left == null) || right == null)
				return;
			var s:String='';
			if(onlyProperties)
			{
				var i:int = onlyProperties.length;
				while(i-->0)
				{
					s = onlyProperties[i];
					if(left.hasOwnProperty(s) && right.hasOwnProperty(s))
						left[s] = right[s];
				}
			}
			else
				for(s in right)
					if(left.hasOwnProperty(s))
						left[s] = right[s];
		}
		
		public static function getBitmaDatapSlice(source:Bitmap, clip:Rectangle):BitmapData
		{
			if(source == null || clip == null) return null;
			else
			{
				var m:Matrix = new Matrix(1,0,0,1,-clip.x, -clip.y)
				var s:BitmapData = new BitmapData(clip.width, clip.height, true, 0x000000);
					s.draw(source,m,null,null,clip,true);
					m = null;
				return s;
			}
		}
		
		public static function getBitmapSlice(source:Bitmap, clip:Rectangle):Bitmap
		{
			return new Bitmap(getBitmaDatapSlice(source, clip));
		}
		
		/**
		 * Draws any flash.display.DisplayObject (including containers) to bitmap data
		 * @param source: flash display object
		 */
		public static function flashToBitmapData(source:Object):BitmapData
		{
			var bmd:BitmapData = new BitmapData(Math.ceil(source.width), Math.ceil(source.height), true, 0x00000000);
				bmd.draw(IBitmapDrawable(source));
			return bmd;
		}
		
		
		/**
		 * Instantiates whole app flow and executes onInited function if defined. See class description to inspect the flow
		 * @param rootInstance: your main flash display class instance
		 * @param designedForWid/Hei affect on scalar values. Useful when you Do design in e.g. photoshop, all contents got predefined wid
		 * and hei. in different scales, many times all you want to do is apply U.scalar to the object
		 * @param starlingRootClass: Starling class which will be instantiated as soon as: stage is ready AND settings are loaded AND assets are loaded
		 * @param splashObj: Flash display object which will cover whole stage (circumscribed) ON app launch until starling.events.Event.rootCreated is dispatched AND whenever you set <code>U.splash = true</code>
		 * @param progBar: flash display object it requires is <code>setProgress(0-1)</code> and <code>destroy()</code> which will be called once starling.events.Event.rootCreated is dispatched. <code>Use Utils.ProgressBar</code> for basic flash drawn progress bar 
		 */
		public static function init(rootInstance:DisplayObjectContainer, designedForWid:Number, designedForHei:Number, splashObj:DisplayObject=null):void
		{
			flashRoot = rootInstance;
			bsplash = splashObj;
			if(bsplash)
				flashRoot.addChild(bsplash);
			
			if(DEBUG)
			{
				ubin = new BinAgent(flashRoot,DEBUG);
				Ldr.verbose = trace;
			}
			
			udesignedForWidth = designedForWid;
			udesignedForHeight = designedForHei;
			
			SoundMixer.audioPlaybackMode  = 'media';
			
			if(flashRoot.stage == null)
				flashRoot.addEventListener(flash.events.Event.ADDED_TO_STAGE, stageCreated);
			else
				stageCreated();
		}
		
		protected static function stageCreated(event:flash.events.Event=null):void
		{
			log('--STAGE CREATED--');
			if(flashRoot.hasEventListener(flash.events.Event.ADDED_TO_STAGE))
				flashRoot.removeEventListener(flash.events.Event.ADDED_TO_STAGE, stageCreated);
			
			setStageProperties(flashRoot.stage);
			setGeometry(udesignedForWidth, udesignedForHeight);
			Easing.init(STG);
			if(configArguments)
			{
				configArguments[1] = configLoaded;
				loadConfig();
			}
			else
				if(onInited is Function)
					onInited();
		}
		protected static function loadConfig():void { Ldr.load.apply(null,configArguments) }
		private static function configLoaded():void
		{
			uconfig = Ldr.getXML(configArguments[0]);
			if(uconfig is XML)
			{
				log('--CONFIG LOADED--');
				if(progressBar)
				{
					U.STG.addChild(progressBar as DisplayObject);
					Ldr.load(CONFIG, initAssetsLoaded, progress);
				}
				else
					Ldr.load(CONFIG, initAssetsLoaded); // loads files
			} 
			else Messages.msg("Can't load config file :( Tap to try againg", loadConfig);
		}
		
		private static function progress(an:String):void{
			progressBar.setProgress(Ldr.numCurrentLoaded / Ldr.numCurrentQueued);
		}
		
		private static function initAssetsLoaded():void
		{
			log('--ASSETS LOADED--');
			if(progressBar)
			{
				if(DisplayObject(progressBar).parent)
					DisplayObject(progressBar).parent.removeChild(DisplayObject(progressBar))
				progressBar.destroy();
			}
			progressBar = null;
			if(onInited is Function)
				onInited();
		}
		
		private static function setGeometry(designedForWid:Number, designedForHei:Number):void
		{
			udesignedForWidth = designedForWid;
			udesignedForHeight = designedForHei;
			if(ISWEB)
				rec = new Rectangle(0,0, STG.stageWidth, STG.stageHeight);
			else
				rec = new Rectangle(0,0, STG.fullScreenWidth, STG.fullScreenHeight);
			
			uscalarX = rec.width / designedForWidth;
			uscalarY = rec.height / designedForHeight;
			uscalar = scalarX;
			
			uscalarXreversed =  designedForWidth / rec.width;
			uscalarYreversed = designedForHeight / rec.height;
			uscalarReversed = uscalarXreversed;
			
			if(bsplash)
			{
				resolveSize(U.bsplash, U.REC,true);
				center(U.bsplash, U.REC);
				splash = true
			}
			bin.resize(rec.width);
		}		
		
		private static function setStageProperties(stage:flash.display.Stage):void
		{
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			if(!ISWEB)
				stage.displayState = StageDisplayState.FULL_SCREEN_INTERACTIVE;
			uSTG = stage;
		}
		
		public static function log(...args):void
		{
			if(bin)
				bin.trrace.apply(null,args);
			else
				trace.apply(null,args);
		}
	}
}
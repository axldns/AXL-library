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
	import flash.system.Capabilities;
	
	import axl.ui.Messages;
	import axl.utils.binAgent.BinAgent;
	/**
	 * Geometric utilty, handy tool, stage setter, quick refference. 
	 */
	public class U
	{
		private static var ver:Number = 0.9;
		public static function get version():Number { return ver}
		
		Ldr.verbose = log;
		/** indicate tracings and bin agent instantiation*/
		public static var DEBUG:Boolean = true;
		public static var autoStageManaement:Boolean=true;
		
		/**indicates if stage is in full screen interactive mode or not<br>
		 * indicates if <code>U.REC</code> is based on stage.fullScreen*W/H* or stage.stage*W/H*
		 * <br>According to on playerType.match: /^(StandAlone|ActiveX|PlugIn)/i */
		public static var onStageAvailable:Function;
		public static var onResize:Function;
		public static function get ISWEB():Boolean { return isWeb }
		private static var isWeb:Boolean = (Capabilities.playerType.match(/^(StandAlone|ActiveX|PlugIn)/i) != null);
		
		private static var rec:Rectangle=new Rectangle(0,0,1,1);
		private static var uSTG:Stage;
		private static var flashRoot:DisplayObjectContainer;

		private static var udesignedForWidth:Number;
		private static var udesignedForHeight:Number;
		private static var uscalarX:Number;
		private static var uscalarY:Number;
		private static var uscalar:Number;
		
		private static var uscalarXreversed:Number;
		private static var uscalarYreversed:Number;
		private static var uscalarReversed:Number;
		
		private static var uSplash:DisplayObject;
		
		private static var ubin:BinAgent;
		private static var uconfig:Object;
		public static var fullScreen:Boolean;
		
		
		public static function get CONFIG():Object { return uconfig }
		public static function set CONFIG(v:Object):void { uconfig = v}
		
		/*** returns bin agent reference. Read BinAgent class description to see what it does */
		public static function get bin():BinAgent{ return ubin	}
		
		
		/** reference to values passed in <code>U.init</code> method. does affects on scallars only */
		public static function get designedForHeight():Number {	return udesignedForHeight }
		
		/** reference to values passed in <code>U.init</code> method. does affects on scallars only */
		public static function get designedForWidth():Number { return udesignedForWidth	}

		/** reference to flash display stage */
		public static function get STG():flash.display.Stage { return uSTG }
		
		/** returns value of ... scalarX. See scalarX and Y defs*/
		public static function get scalar():Number	{ return uscalar }
		
		/**scalarY tells how much different current stage width is to values of designedFor.
		 *<br> othher words : REC.height / designedForHeight;*/
		public static function get scalarY():Number { return uscalarY }
		
		 /**scalarY tells how much different current stage height is to values of designedFor.
		 *<br> othher words : REC.width / designedForWidth;  */
		public static function get scalarX():Number { return uscalarX }
		
		/** returns value of ... scalarXreversed*/
		public static function get scalarReversed():Number	{ return uscalarReversed }
		
		/** scalarY tells how much different current stage width is to values of designedFor.
		 *<br> othher words :  designedForHeight / REC.height;*/
		public static function get scalarYreversed():Number { return uscalarYreversed }
		
		/** scalarY tells how much different current stage height is to values of designedFor.
		 *<br> othher words :  designedForWidth / REC.width; */
		public static function get scalarXreversed():Number { return uscalarXreversed }

		/** STAGE RECTANGLE utility.
		 * <br>Reffer e.g. <br>Utils.U.REC.bottom</br> or pass this to align functions
		 * like <code>U.center</code>, <code>U.align</code> or matrix transformations  */
		public static function get REC():Rectangle { return rec }
		
		/** Displays semi dialog pop-up message on top of the screen. Message disappears on first focus change / tap / click.
		 * To adjust layout use Messages class. @see axl.ui.Messages */
		public static function msg(message:String, onOutsideTap:Function=null, onInsideTap:Function=null):void {
			Messages.msg(message, onOutsideTap, onInsideTap);
		}
		
		/** @param movable: any object which contains x,y,width,height
		 *  @param static: any object which contains x,y,width,height
		 *  @param Inside: indicates whether to include coords of static 
		 * (mov and static share the same coord space) or not (treat movable as a child of static) */
		public static function center(movable:Object, static:Object, inside:Boolean=true):void
		{
			movable.x = (static.width - movable.width >> 1);
			movable.y = (static.height - movable.height >> 1);
			if(!inside)
			{
				movable.x += static.x
				movable.y += static.y
			}
		} 
		/**
		 * @param movable: any object which contains x,y,width,height | target
		 * @param static: any object which contains x,y,width,height | source
		 * @param hor: left || center || right
		 * @param ver: bottom || center || top
		 * @param *Inside: indicates whether to include coords of static (mov and static share the same coord space) or not (treat movable as a child of static)
		 */
		public static function align(movable:Object, static:Object, hor:String='center', 
									 ver:String='center', horizontalInside:Boolean=true, verticalInside:Boolean=true):void
		{
			switch (ver)
			{
				case "top":
					movable.y = verticalInside ? static.y : static.y - movable.height;
					break;
				case "center":
					movable.y = ((verticalInside ? 0 : static.y) + (static.height - movable.height>>1));
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
					movable.x = ((horizontalInside ? 0 : static.x ) + (static.width - movable.width>>1));
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
		/** Distributes container members based on their width, height and gap between them.<br>
		 * Container member can be any object which has x,y,width,height properites.
		 * Container itself can be any vector, array or other enum, OR object with methods numChildren and getchildAt. 
		 * Members are being distributed accodring to their indexes.
		 * @param cont - enum or DisplayObjectContainer
		 * @param gap - Number or enum of Numbers. If e.g. gap=[50,100]: m1-m2 gap:50, m2-m3g:100, m3-m4:50, etc.
		 * @param offset, member0 initial value.
		 * @param scaleGapAndOffset - more as a reminder here but fully working. It uses U.scalar value
		 */
		public static function distributePattern(cont:Object, gap:Object=0, horizontal:Boolean=true, 
												 offset:Number=0, scaleGapAndOffset:Boolean=false):Number
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
		 * @param movable: object to resize (any type of object which consist properties of <code>width and height</code>)
		 * @param static: object to fit <code>movable</code> into. static object wont be resized. (<b>any</b> type of object which 
		 * consist properties of <code>width and height</code>)
		 * @param outsidefit: if <code>true</code> movable is <strong>inscribed</strong> into static. if <code>false</code> movable 
		 * is <strong>circumscribed around</strong> static
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
		 * Asigns properties FROM RIGHT to LEFT if left has right property availavble
		 * @param onlyProperies: allows to filter asignment of publicly available right fields. Copies only specified in array if both got them available
		 * @param left: object to change (target)
		 * @param right: object to copy values from (source)
		 */
		public static function asignProperties(left:Object, right:Object, onlyProperties:Array=null):void
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
		
		/** Draws any flash.display.DisplayObject to BitmapData*/
		public static function getBitmapData(source:Object):BitmapData
		{
			if(source == null)
				return null;
			var bmd:BitmapData = new BitmapData(Math.ceil(source.width), Math.ceil(source.height), true, 0x00000000);
			bmd.draw(IBitmapDrawable(source));
			return bmd;
		}
		
		/** Draws any flash.display.DisplayObject to BitmapData*/
		public static function getBitmap(source:Object):Bitmap
		{
			var bmd:BitmapData = new BitmapData(Math.ceil(source.width), Math.ceil(source.height), true, 0x00000000);
			bmd.draw(IBitmapDrawable(source));
			return new Bitmap(bmd, 'auto', true);;
		}
		/** Draws any flash.display.DisplayObject to BitmapData @param clip - limits source to
		 * specific slice - any object that has x,y,width,height*/
		public static function getBitmaDatapSlice(source:IBitmapDrawable, clip:Object):BitmapData
		{
			if(source == null || clip == null) return null;
			var rec:Rectangle = clip as Rectangle;
			if(rec == null)
			{
				rec = new Rectangle();
				rec.setTo(clip.x, clip.y, clip.width, clip.height);
			}
			var m:Matrix = new Matrix(1,0,0,1,-rec.x, -rec.y)
			var s:BitmapData = new BitmapData(rec.width, rec.height, true, 0x000000);
				s.draw(source,m,null,null,rec,true);
				m = null;
				rec = null;
				clip = null;
			return s;
		}
		/** Draws any flash.display.DisplayObject to BitmapData and returns it wrapped into Bitmap
		 *  @param clip - limits source to  specific slice - any object that has x,y,width,height*/
		public static function getBitmapSlice(source:IBitmapDrawable, clip:Object):Bitmap {
			return new Bitmap(getBitmaDatapSlice(source, clip));
		}
		
		/** Draws any flash.display.DisplayObject to BitmapData to fit specific area (toFit) and centers return bitmap within that area*/
		public function getBitmapFit(source:DisplayObject, toFit:Object):Bitmap
		{
				var ascale:Number = 1;
				var bitmap:Bitmap = new Bitmap(null,'auto',true);
				var bMatrix:Matrix = new Matrix();
				var skel:Rectangle = new Rectangle();
				
				skel.setTo(0,0,source.width, source.height);
				resolveSize(source, toFit);
				ascale = skel.width / source.width;
				bMatrix.scale(ascale, ascale);
				
				bitmap.bitmapData = new BitmapData(source.width * ascale + 2, source.height * ascale + 2,true, 0x00000000);
				bitmap.bitmapData.draw(source as DisplayObject,bMatrix,null,null,null,true);
				bitmap.x =  toFit.width - bitmap.width >>1;
				bitmap.y = toFit.height - bitmap.height >> 1;
				return bitmap;
		}
		
		/** Displays or hides flash stage splash if both splash and stage are instantiated.
		 *  Messages are being displayed underneath splash*/
		public static function get splash():Boolean { return uSplash != null && uSplash.parent != null }
		public static function set splash(v:Boolean):void
		{
			if(uSplash == null) return;
			if(v == false)
			{
				if(uSplash.parent != null)
					uSplash.parent.removeChild(uSplash);
			}//yes
			else if(STG != null)
			{
				if(Messages.areDisplayed)
					STG.addChildAt(uSplash, STG.numChildren-1);
				else
					STG.addChild(uSplash);
			} 
			else if(flashRoot != null)
				STG.addChild(uSplash);
		}
		
		/**sets or replaces current stage splash object*/
		public static function get splashObject():DisplayObject { return uSplash }
		public static function set splashObject(v:DisplayObject):void
		{
			if(uSplash == v) return;
			if(v == null)
				splash = false;
			else if(uSplash != null && uSplash.parent != null) 
			{
				uSplash.parent.removeChild(uSplash);
				uSplash = v;
				splash = true;
			}
			uSplash = v;
		}
		
		
		/**
		 * Instantiates whole app and runs the flow if supplied. If you're using Starling, 
		 * you probably want to use <code>S.init</code> instead - don't call both as S.init already does call this one.<br><br>
		 * In your project root class call e.g. <code>U.init(this,1024,768)</code> to take advantage of automatization.
		 * If you do not call init, following elements would have to be set up manually in order to be able to use of it:
		 * <ul>
		 * <li><code>AO.stage</code> - animation engine motor</li>
		 * <li><code>U.REC.setTo</code> - as it will remain 0,0,1,1</li>
		 * </ul>
		 * and following elements will still remain unavailable:
		 * <ul>
		 * <li>all scalar^ values</li> - used in some geometric functions of this class.
		 * <li><code>U.splash</code></li>
		 * <li><code>Flow.progressBar</code></li>
		 * <li><code>U.msg</code> as well as <code>Messages.msg</code></li>
		 * </ul>
		 * @param rootInstance: your main flash display class instance. In your top display class use <code>this</code> keyword
		 * @param designedForWid/Hei - these compared to the actual stage dimensions are used to calculate scalar^ values.
		 * @param onReady: function to execute once everything is done (stage available / flow is complete) 
		 * @param flow: flow to execute before onReady. see <code>Flow</code> class description. Flow instance
		 * will not be destroyed by this method, this should be handled by flow instantiator.
		 */
		public static function init(rootInstance:DisplayObjectContainer, designedForWidth:Number, 
									designedForHeight:Number, onReady:Function=null, flow:Flow=null):void
		{
			flashRoot = rootInstance;
			if(uSplash)
				flashRoot.addChild(uSplash);
			
			if(DEBUG)
				ubin = ((BinAgent.instance != null) ? BinAgent.instance : new BinAgent(flashRoot));
			
			udesignedForWidth = designedForWidth;
			udesignedForHeight = designedForHeight;
			
			if(flashRoot.stage == null)
				flashRoot.addEventListener(Event.ADDED_TO_STAGE, stageAvailable);
			else
				stageAvailable();
			
			function stageAvailable(event:Event=null):void
			{
				log('[U] stage available');
				if(flashRoot.hasEventListener(Event.ADDED_TO_STAGE))
					flashRoot.removeEventListener(Event.ADDED_TO_STAGE, stageAvailable);
				uSTG = flashRoot.stage;
				STG.addEventListener(Event.RESIZE, setGeometry);
				AO.stage = STG;
				setStageProperties();
				setGeometry();
				if(bin != null) bin.resize(rec.width);
				if(onStageAvailable != null)
					onStageAvailable();
				if(flow != null)
				{
					flow.addEventListener(Event.COMPLETE, flowComplete);
					flow.start();
				}
				else
					flowComplete();
			}
			
			function flowComplete(e:Event=null):void
			{
				if(flow != null)
					flow.removeEventListener(Event.COMPLETE, flowComplete);
				if(onReady is Function)
					onReady();
			}
		}
	
		private static function setGeometry(e:Event=null):void
		{
			if(!fullScreen)
			{
				rec.width = STG.stageWidth;
				rec.height = STG.stageHeight;
				//fp 11+
				//rec.setTo(0,0, STG.stageWidth, STG.stageHeight);
			}
			else
			{
				rec.width = STG.fullScreenWidth;
				rec.height = STG.fullScreenHeight;
				//fp 11+
				//rec.setTo(0,0, STG.fullScreenWidth, STG.fullScreenHeight);
			}
			
			uscalarX = rec.width / designedForWidth;
			uscalarY = rec.height / designedForHeight;
			uscalar = scalarX;
			
			uscalarXreversed =  designedForWidth / rec.width;
			uscalarYreversed = designedForHeight / rec.height;
			uscalarReversed = uscalarXreversed;
			selfResize();
		}		
		
		private static function selfResize():void
		{
			if(uSplash != null)
			{
				U.resolveSize(uSplash, U.REC, true);
				U.center(uSplash, U.rec);
			}
			if(U.bin)
				bin.resize(U.rec.width);
			Messages.resize();
			if(onResize != null)
				onResize();
		}
		
		private static function setStageProperties():void
		{
			if(autoStageManaement==false)
				return
			uSTG.align = StageAlign.TOP_LEFT;
			uSTG.scaleMode = StageScaleMode.NO_SCALE;
			if(fullScreen)
				uSTG.displayState = StageDisplayState.FULL_SCREEN_INTERACTIVE;
			uSTG = uSTG;
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
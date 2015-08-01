package axl.ui.controllers
{
	/**
	 * [axldns free coding 2015]
	 */
	
	import flash.display.DisplayObject;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import axl.utils.AO;
	import axl.utils.U;
	
	public class BoundBox  extends EventDispatcher
	{
		public static const inscribed:String = 'inscribed';
		public static const described:String = 'described';
		public static const edges:String = 'edges';
		public static const top:String = 'top';
		public static const bottom:String = 'bottom';
		public static const middles:String = 'middles';
		
		private var mapf:Array = [minMaxInscribed, minMaxDescribed, minMaxChain, minMaxTop, minMaxBottom, minMaxMiddles];
		private var mapn:Array = [inscribed, described, edges, top, bottom, middles];
		
		private var eventChange:Event = new Event(Event.CHANGE);
		private var bnd:DisplayObject;
		private var bx:DisplayObject;
		
		private var rstatic:Rectangle = new Rectangle();
		private var rmovable:Rectangle= new Rectangle();
		private var boxStart:Point = new Point();
		private var inBox:Point = new Point();
		private var startMouse:Point = new Point();
		private var min:Point = new Point();
		private var max:Point = new Point();
		
		private var modH:Object = { a : 'x' , d : 'width'};
		private var modV:Object = { a : 'y', d : 'height'};
		private var mods:Object = { x : modH, y: modV };
		private var mmax:Object = { x : minMaxInscribed, y : minMaxInscribed };
		private var behIdx:Object = { x : 0, y : 0 };
		private var percentage:Object = { x : 0, y : 0 };
		
		/** determines if any horizontal movement of any methods and events is applied */
		public var horizontal:Boolean;
		/** determines if any horizontal movement of any methods and events is applied */
		public var vertical:Boolean;
		private var down:Boolean;
		
		private var ao:Object = { x  : null, y : null };
		private var aop:Object = { x : {x:0}, y : {y:0}};
		private var animTime:Number=0;
		private var boxStage:Stage;
		
		/**
		 * <h3>Decorator style coordinates controller</h3>
		 *  Allows to controll coordinates of two display objects against each other: <code>box</code> and <code>bound</code> 
		 * according to <code>horizontalBehavior</code> and <code>verticalBehavior</code> rules.
		 * Usefull for UI elements like sliders, scrollbars, toggle switches, scrollable text areas, panning areas etc.
		 * <h3>Events dispatching rules</h3>
		 * 1. Manual updates such as movementHor, movementVer, set percentageHor, percentageVer are not dispatching Event.CHANGE
		 * since you can dispatch it yourself.<br>
		 * 2. Mouse-triggered changes dispatch Event.CHANGE 
		 * @see #horizontalBehavior @see #verticalBehavior @see #box @see #bound */
		public function BoundBox()
		{
			super();
			ao.x = new AO(null, animTime, { x : 0 });
			ao.y = new AO(null, animTime, { y : 0 });
		}
		
		private function minMaxInscribed(mod:Object):void
		{
			min[mod.a] = rstatic[mod.a];
			max[mod.a] = rstatic[mod.a] + rstatic[mod.d] - rmovable[mod.d];
		}
		
		private function minMaxDescribed(mod:Object):void
		{
			min[mod.a] =  rstatic[mod.a] + rstatic[mod.d] - rmovable[mod.d];
			max[mod.a] = rstatic[mod.a];
		}
		
		private function minMaxChain(mod:Object):void
		{
			min[mod.a] = rstatic[mod.a] - rmovable[mod.d];
			max[mod.a] = rstatic[mod.a] + rstatic[mod.d];
		}
		
		private function minMaxTop(mod:Object):void
		{
			min[mod.a] = rstatic[mod.a] - rmovable[mod.d];
			max[mod.a] = rstatic[mod.a];
		}
		
		private function minMaxBottom(mod:Object):void
		{
			min[mod.a] = rstatic[mod.a] + rstatic[mod.d] - rmovable[mod.d];
			max[mod.a] = rstatic[mod.a] + rstatic[mod.d];
		}
		private function minMaxMiddles(mod:Object):void
		{
			min[mod.a] = rstatic[mod.a] - rmovable[mod.d]/2;
			max[mod.a] = rstatic[mod.a] + rstatic[mod.d] - rmovable[mod.d]/2;
		}
		
		private function calculateMinMax(mod:Object):void
		{
			mmax[mod.a](mod);
		}
	
		private function setPercentage(v:Number, mod:Object):Number
		{
			var a:String = mod.a;
			updateFrames();
			rmovable[a] = min[a] + (max[a] - min[a]) * v;
			validateAndUpdate(a);
			return percentage.a;
		}
		
		private function updateFrames():void
		{
			if(bx != null)
				rmovable.setTo(bx.x, bx.y, bx.width, bx.height);
			if(bnd != null)
				rstatic.setTo(bnd.x, bnd.y, bnd.width, bnd.height);
		}
	
		private function validateAndUpdate(a:String):void
		{
			if(box == null)
				throw new Error("Undefined box - can't move anything");
			calculateMinMax(mods[a]);
			if(rmovable[a] < min[a])
				rmovable[a] = min[a];
			if(rmovable[a] > max[a])
				rmovable[a] = max[a];
			if(box[a] == rmovable[a])
				return;
			updatePercentage(a);
			if(animTime > 0)
			{
				var aoo:AO = ao[a];
				aoo.subject = box;
				aoo.cycles = 1;
				aoo.nSeconds = animTime;
				aop[a][a] = rmovable[a];
				aoo.nProperties = aop[a];
				aoo.restart(0,true);
			}
			else
				box[a] = rmovable[a];
		}
		
		private function updatePercentage(axle:String):void
		{
			percentage[axle] = (rmovable[axle]-min[axle]) / (max[axle] - min[axle]);
		}

		private function addListeners(bx:DisplayObject):void
		{
			if(boxStage == null)
			{
				if(box.stage != null)
					boxOnStage();
				else
					box.addEventListener(Event.ADDED_TO_STAGE, boxOnStage);
			}
		}
		
		protected function boxOnStage(e:Event=null):void
		{
			if(boxStage == null)
			{
				bx.addEventListener(MouseEvent.MOUSE_DOWN, md);
				bx.addEventListener(Event.REMOVED_FROM_STAGE, boxOffStage);
			}
			boxStage = box.stage;
		}
		
		protected function boxOffStage(event:Event):void
		{
			finishMovement();
		}
		
		protected function finishMovement():void
		{
			boxStage.removeEventListener(MouseEvent.MOUSE_MOVE, mmove);
			down = false
		}
		
		protected function md(e:MouseEvent):void
		{
			bx.stage.addEventListener(MouseEvent.MOUSE_MOVE, mmove);
			boxStart.x = bx.x;
			boxStart.y = bx.y;
			startMouse.x = U.STG.mouseX;
			startMouse.y = U.STG.mouseY;
			inBox.x = bx.mouseX;
			inBox.y = bx.mouseY;
			down = true;
		}
		
		private function movement(delta:Number, mod:Object):void
		{
			updateFrames();
			rmovable[mod.a] += delta;
			validateAndUpdate(mod.a);
		}
		
		private function mmove(e:MouseEvent):void
		{
			if(e.buttonDown && down)
			{
				updateFrames();
				if(horizontal)
					updateAbsolute(modH, boxStart.x + (U.STG.mouseX - startMouse.x));					
				if(vertical)
					updateAbsolute(modV, boxStart.y + (U.STG.mouseY - startMouse.y));			
				this.dispatchEvent(eventChange);
			}
			else
			{
				finishMovement();
			}
		}
		
		private function updateAbsolute(mod:Object, val:Number):void
		{
			var a:String = mod.a;
			rmovable[a] = val;
			validateAndUpdate(a);
		}
		
		private function removeListeners(bx:DisplayObject):void
		{
			bx.removeEventListener(flash.events.MouseEvent.MOUSE_DOWN, md);
		}
		
		private function setBehavior(v:String, axle:String):void
		{
			var i:int = mapn.indexOf(v); 
			if(i>-1)
				behIdx[axle] = i;
			mmax[axle] = mapf[behIdx[axle]];
		}
		
		// -------------------------------- PUBLIC API ---------------------------------- //
		
		/** object which limits area where <code>box</code> can be moved around according to <code>horizontalBehavior</code> 
		 * and <code>verticalBehavior</code> rules. @see #horizontalBehavior @see #verticalBehavior @see #box */
		public function get bound():DisplayObject {	return bnd }
		public function set bound(v:DisplayObject):void
		{
			bnd = v;
			refresh();
		}
		/** object to move within <code>bound</code> area according according to <code>horizontalBehavior</code> 
		 * and <code>verticalBehavior</code> rules. listeners for dragging are  added automatically.
		 *  @see #horizontalBehavior @see #verticalBehavior @see #bound */
		public function get box():DisplayObject	{ return bx }
		public function set box(v:DisplayObject):void
		{
			if(bx != null)
				removeListeners(bx)
			bx = v;
			if(bx != null)
				addListeners(bx);
			refresh();
		}
		
		/** 
		 * Use BoundBox static properties or text values to pick one of bounding behavior for particular axle.
		 * <br>Samples bellow are describing vertical behavior but they apply exactly the same way to horizontalBehavior
		 * where: top = left, bottom = right
		 * <br><br>
		 * <ul>
		 * <li> "inscribed" - box top can't go higher than bounds top, box bottom cant go lower than bounds bottom (slider) </li>
		 * <li> "described" - both box top can go higher and bottom can go lower but not at the same  time (textfield)
		 * <br> if box if smaller dimension than bounds - no movement is made. </li>
		 * <li> "chain" - box bottom is limited by bounds top, box top is limited by bounds bottom </li>
		 * <li> "top" - box top can't go lower than bounds top, box bottom cant go higher than bunds top bottom </li>
		 * <li> "bottom" box top can't go lower than bounds bottom, box bottom cant go higher than bounds bottom </li>
		 * </ul>
		 * default: "inscribed"
		 * */
		public function get verticalBehavior():String	{ return mapn[behIdx.y] }
		public function set verticalBehavior(v:String):void	{ setBehavior(v, modV.a)}
		
		/** @see #verticalBehavior */
		public function get horizontalBehavior():String	{ return mapn[behIdx.x] }
		public function set horizontalBehavior(v:String):void { setBehavior(v, modH.a) }
		
		
		/** Re-checks <code>box</code> position within <code>bound</code> according to <code>horizontalBehavior</code> 
		 * and <code>verticalBehavior</code> rules. @see #horizontalBehavior @see #verticalBehavior @see #box @see #bound */
		public function refresh():void
		{
			if(box == null || bnd == null)
				return;
			if(horizontal)
				movementHor(0);
			if(vertical)
				movementVer(0);
		}
		
		/** Attempts to move box by delta, still follows <code>horizontalBehavior</code> rule @see #horizontalBehavior */
		public function movementVer(delta:Number):void  { movement(delta, modV) }
		/** Attempts to move box by delta, still follows <code>verticalBehavior</code> rule @see #verticalBehavior */
		public function movementHor(delta:Number):void { movement(delta, modH) }
		
		/** determines horizontal position of the <code>box</code> between its minX and maxX values @see #minX @see #maxX */
		public function get percentageHorizontal():Number { return percentage.x }
		public function set percentageHorizontal(v:Number):void { setPercentage(v, modH) }
		
		/** determines vertical position of the <code>box</code> between its minY and maxY values  @see #minY @see #maxY */
		public function set percentageVertical(v:Number):void { setPercentage(v, modV) }
		public function get percentageVertical():Number { return percentage.y }
		
		/** movement can be smoothed by optimized animation. @default 0 */
		public function get animationTime():Number { return animTime }
		public function set animationTime(v:Number):void { animTime = v }
		
		
		/** Minimum x value which box can take to follow <code>horizontalBehavior</code> defined rule. @see #horizontalBehavior */
		public function get minX():Number { return min.x };
		/** maximum x value which box can take to follow <code>horizontalBehavior</code> defined rule @see #horizontalBehavior */
		public function get maxX():Number { return max.x };
		/** minimum y value which box can take to follow <code>verticalBehavior</code> defined rule @see #verticalBehavior */
		public function get minY():Number { return min.y };
		/** maximum y value which box can take to follow <code>verticalBehavior</code> defined rule @see #verticalBehavior */
		public function get maxY():Number { return max.y };
		
		public function dispatchChange():void
		{
			this.dispatchEvent(eventChange);
		}
	}
}
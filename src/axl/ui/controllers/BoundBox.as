/**
 *
 * AXL Library
 * Copyright 2014-2016 Denis Aleksandrowicz. All Rights Reserved.
 *
 * This program is free software. You can redistribute and/or modify it
 * in accordance with the terms of the accompanying license agreement.
 *
 */
package axl.ui.controllers
{
	import flash.display.DisplayObject;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import axl.utils.AO;
	import axl.utils.Easings;
	
	public class BoundBox  extends EventDispatcher
	{
		public static const inscribed:String = 'inscribed';
		public static const described:String = 'described';
		public static const edges:String = 'edges';
		public static const top:String = 'top';
		public static const bottom:String = 'bottom';
		public static const middles:String = 'middles';
		
		public static const version:String = '1.0';
		private static var eventChange:Event = new Event(Event.CHANGE);
		
		private var mapf:Array = [minMaxInscribed, minMaxDescribed, minMaxChain, minMaxTop, minMaxBottom, minMaxMiddles];
		private var mapn:Array = [inscribed, described, edges, top, bottom, middles];
		
		private var bnd:DisplayObject;
		private var bx:DisplayObject;
		private var boxStage:Stage;
		private var boundStage:Stage;
		
		private var rstatic:Rectangle = new Rectangle();
		private var rmovable:Rectangle= new Rectangle();
		private var boxStart:Point = new Point();
		private var startMouse:Point = new Point();
		private var min:Point = new Point();
		private var max:Point = new Point();
		
		private var modH:Object = { a : 'x' , d : 'width'};
		private var modV:Object = { a : 'y', d : 'height'};
		private var mods:Object = { x : modH, y: modV };
		private var mmax:Object = { x : minMaxInscribed, y : minMaxInscribed };
		private var behIdx:Object = { x : 0, y : 0 };
		private var percentage:Object = { x : 0, y : 0 };
		private var ao:Object = { x  : null, y : null, xy : null };
		private var aop:Object = { x : {x:0}, y : {y:0}, xy : {x:0,y:0}};
		
		private var cGloToLo:Point;
		private var animTime:Number=0;
		
		private var inited:Boolean;
		private var easingFunc:Function;
		private var xChangesArgument:Object;
		
		private var boxMouseDown:Boolean;
		private var xtouchyBound:Boolean=true;
		private var boundMouseDown:Boolean;
		
		/** Determines if box can be moved horizontally */
		public var horizontal:Boolean;
		/** Determines if box can be moved vertically */
		public var vertical:Boolean;
		
		/** Top level of controll for 
		 * <ul><li>Dispatching <code>Event.CHANGE</code> by this controller</li>
		 * <li>Executeing <code>onChange</code> function (if defined)</li>
		 * @see #onChange */
		public var changeNotifications:Boolean = true;
		/**This property applies only if <code>changeNotifications = true</code><br> 
		 * If true - change event and callback are processed every movement<br>
		 * If false - change event and callback are processed only after mouse up and on animation
		 * complete if animationTime is defined @see #changeNotifications @see #animationTime */
		public var liveChanges:Boolean=false;
		/** Function to execute when <code>box</code> position changes 
		 * @see #changeNotifications @see #liveChanges*/
		public var onChange:Function;
		/** Determines if dragging box is eased with animation */
		public var omitDraggingAnimation:Boolean=true;
		
		
		/** Easing function for animation curves. Applie it on BoundBox instance by setting easing property.
		 * @see #animationTime @see #easing */
		public static function get easgings():Easings { return AO.easing }
		/**
		 * <h3>Decorator style coordinates controller</h3>
		 *  Allows to controll coordinates of two display objects against each other: <code>box</code> and <code>bound</code> 
		 * according to <code>horizontalBehavior</code> and <code>verticalBehavior</code> rules.
		 * Usefull for UI elements like sliders, scrollbars, toggle switches, scrollable text areas, panning areas etc.
		 * @see #horizontalBehavior @see #verticalBehavior @see #box @see #bound */
		public function BoundBox()
		{
			super();
			easingFunc = BoundBox.easgings.easeOutQuart;
			cGloToLo = new Point();
		}
		//---------------------------------------- PRIVATE API -----------------------------------//
		// ----------- POSITION VALIDATION --------------//
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
		
		private function normalizeMovable(a:String):void
		{
			if(rmovable[a] < min[a])
				rmovable[a] = min[a];
			if(rmovable[a] > max[a])
				rmovable[a] = max[a];
		}
		
		private function updatePercentage(axle:String):void
		{
			percentage[axle] = (box[axle]-min[axle]) / (max[axle] - min[axle]);
		}
		
		private function setBehavior(v:String, axle:String):void
		{
			var i:int = mapn.indexOf(v); 
			if(i>-1)
				behIdx[axle] = i;
			mmax[axle] = mapf[behIdx[axle]];
		}
		// ----------- MECHANIC FLOW  --------------//
		private function updateFrames():void
		{
			if(bx != null)
			{
				rmovable.x = bx.x;
				rmovable.y = bx.y;
				rmovable.width = bx.width;
				rmovable.height = bx.height;
				//fp 11+
				//rmovable.setTo(bx.x, bx.y, bx.width, bx.height);
			}
			if(bnd != null)
			{
				rstatic.x = bnd.x;
				rstatic.y = bnd.y;
				rstatic.width = bnd.width;
				rstatic.height = bnd.height;
				//fp 11+
				//rstatic.setTo(bnd.x, bnd.y, bnd.width, bnd.height);
			}
		}
	
		private function validateAndUpdate(a:String,omitAnimation:Boolean=false,changesArgument:Object=null):void
		{
			if(box == null)
				return;
			calculateMinMax(mods[a]);
			normalizeMovable(a);
			if(box[a] == rmovable[a])
				return;
			if(animTime > 0 && !omitAnimation)
				setupAO(changesArgument);
			else
			{
				box[a] = rmovable[a];
				if(changesArgument)
					changeNotify(a,null,changesArgument);
			}
		}
		
		private function validUpdateCommon(omitAnimation:Boolean,changesArgument:Object=null):void
		{
			calculateMinMax(mods.x);
			calculateMinMax(mods.y);
			normalizeMovable('x');
			normalizeMovable('y');
			if(box.x == rmovable.x && box.y == rmovable.y)
				return;
			if(animTime > 0 && !omitAnimation)
				setupAO(changesArgument);
			else
			{
				box.x = rmovable.x;
				box.y = rmovable.y;
				if(changesArgument)
					changeNotify('x','y',changesArgument);
			}
		}
		
		private function changeNotify(axis:String,axis2:String=null,changesArgument:Object=null):void
		{
			if(axis2!=null)
			{
				updatePercentage('x');
				updatePercentage('y');
			}
			else
				updatePercentage(axis);
			if(!changeNotifications)
				return;
			dispatchChange(changesArgument);
			if(onChange != null)
				changesArgument ? onChange(changesArgument) : onChange();
		}
		//------------------ MOVEMENT ------------------- //
		private function setPercentage(v:Number, mod:Object,omitAnimation:Boolean=false,changesArgument:Object=null):void
		{
			var a:String = mod.a;
			updateFrames();
			rmovable[a] = min[a] + (max[a] - min[a]) * v;
			validateAndUpdate(a,omitAnimation,changesArgument);
		}
		
		private function updateAbsolute(mod:Object, val:Number):void
		{
			var a:String = mod.a;
			rmovable[a] = val;
			validateAndUpdate(a);
		}
		
		private function deltaMovement(delta:Number, mod:Object,omitAnimation:Boolean=false,changesArgument:Object=null):void
		{
			updateFrames();
			rmovable[mod.a] += delta;
			validateAndUpdate(mod.a,omitAnimation,changesArgument);
		}
		
		private function updateBoxToMousePosition(changesArgument:Object):void
		{
			cGloToLo.setTo(boxStage.mouseX, boxStage.mouseY);
			cGloToLo = bx.parent.globalToLocal(cGloToLo);
			
			var tbx:Number = cGloToLo.x - startMouse.x;
			var tby:Number = cGloToLo.y - startMouse.y;
			
			if(horizontal && vertical)
				absoluteCommon(tbx,tby,omitDraggingAnimation,changesArgument);
			else if(horizontal)
				absoluteHor(tbx,omitDraggingAnimation,changesArgument);
			else if(vertical)
				absoluteVer(tby,omitDraggingAnimation,changesArgument);
		}
		
		private function executeCommon(omitAnimation:Boolean, changesArgument:Object):void
		{
			if(horizontal && vertical)
				validUpdateCommon(omitAnimation,changesArgument);
			else if (horizontal)
				validateAndUpdate('x',omitAnimation,changesArgument);
			else if(vertical)
				validateAndUpdate('y',omitAnimation,changesArgument);
		}

		
		private function finishBoundMovement():void
		{
			if(!boundMouseDown)
				return;
			boundMouseDown = false;
			boundStage.removeEventListener(MouseEvent.MOUSE_MOVE, onBoundMouseMove);
			boundStage.removeEventListener(MouseEvent.MOUSE_UP, onBoundMouseUp);
			changeNotify('x','y');
		}
		
		protected function finishBoxMovement():void
		{
			if(!boxMouseDown)
				return;
			boxMouseDown =false;
			boxStage.removeEventListener(MouseEvent.MOUSE_MOVE, onBoxMouseMove);
			boxStage.removeEventListener(MouseEvent.MOUSE_UP, onBoxMouseUp);
			changeNotify('x','y');
		}
		
		//------------------------------------- EVENT HANDLERS ---------------------------------- //
		//------------ADD LISTENERS----------//
		private function addBoxListeners():void
		{
			if(boxStage == null)
			{
				if(box.stage != null)
					boxOnStage();
				else
					box.addEventListener(Event.ADDED_TO_STAGE, boxOnStage);
			}
		}
		
		private function addBoundListeners():void
		{
			if(boundStage == null)
			{
				if(bound.stage != null)
					boundOnStage();
				else
					bound.addEventListener(Event.ADDED_TO_STAGE, boundOnStage);
			}
		}
		//------------REMOVE LISTENERS----------//
		private function removeBoxListeners():void
		{
			box.removeEventListener(flash.events.MouseEvent.MOUSE_DOWN, onBoxMouseDown);
			boxStage.removeEventListener(MouseEvent.MOUSE_MOVE, onBoxMouseMove);
			boxStage.removeEventListener(MouseEvent.MOUSE_UP, onBoxMouseUp);
		}
		
		private function removeBoundListeners():void
		{
			bound.removeEventListener(flash.events.MouseEvent.MOUSE_DOWN, onBoundMouseDown);
			boundStage.removeEventListener(MouseEvent.MOUSE_MOVE, onBoundMouseMove);
			boundStage.removeEventListener(MouseEvent.MOUSE_UP, onBoundMouseUp);
		}
		//--------------STAGE------------//
		protected function boxOnStage(e:Event=null):void
		{
			if(boxStage == null)
			{
				bx.addEventListener(MouseEvent.MOUSE_DOWN, onBoxMouseDown);
				bx.addEventListener(Event.REMOVED_FROM_STAGE, boxOffStage);
			}
			boxStage = box.stage;
		}
		
		protected function boundOnStage(e:Event=null):void
		{
			if(boundStage == null)
			{
				bound.addEventListener(MouseEvent.MOUSE_DOWN, onBoundMouseDown);
				bound.addEventListener(Event.REMOVED_FROM_STAGE, boundOffStage);
			}
			boundStage = bound.stage;
		}
		
		protected function boxOffStage(e:Event):void
		{
			finishBoxMovement();
		}
		
		protected function boundOffStage(e:Event):void
		{
			finishBoundMovement();
		}
		//--------------MOUSE DOWN------------//
		protected function onBoxMouseDown(e:MouseEvent):void
		{
			if(boundMouseDown)
				return;
			killAnimations();
			bx.stage.addEventListener(MouseEvent.MOUSE_MOVE, onBoxMouseMove);
			bx.stage.addEventListener(MouseEvent.MOUSE_UP, onBoxMouseUp);
			boxStart.x = bx.x;
			boxStart.y = bx.y;
			startMouse.x = bx.mouseX * bx.scaleX;
			startMouse.y = bx.mouseY * bx.scaleY;
			boxMouseDown = true;
		}
		
		protected function onBoundMouseDown(e:MouseEvent):void
		{
			if(!bx)
				return
			killAnimations();
			boundStage.addEventListener(MouseEvent.MOUSE_MOVE, onBoundMouseMove);
			boundStage.addEventListener(MouseEvent.MOUSE_UP, onBoundMouseUp);
			boundMouseDown = true;
			startMouse.x = bx.width/2;
			startMouse.y = bx.height/2;
			updateBoxToMousePosition(liveChanges);
			if(box is IEventDispatcher)
				box.dispatchEvent(e);
		}
		//--------------MOUSE MOVE------------//
		protected function onBoxMouseMove(e:MouseEvent):void
		{
			if(e.buttonDown && boxMouseDown && !boundMouseDown)
				updateBoxToMousePosition(liveChanges);
			else
				finishBoxMovement();
		}
		
		protected function onBoundMouseMove(e:MouseEvent):void
		{
			if(e.buttonDown && boundMouseDown)
				updateBoxToMousePosition(liveChanges);
			else
				finishBoundMovement();
		}
		//--------------MOUSE UP------------//
		protected function onBoxMouseUp(e:MouseEvent):void
		{
			finishBoxMovement();
		}
		
		protected function onBoundMouseUp(e:MouseEvent):void
		{
			finishBoundMovement();
		}
		
		//---- ANIMATION SETUP
		private function setupAO(changesArgument:Object):void
		{
			var axisArray:Array;
			var aoo:AO;
			
			//target coords
			if(horizontal && vertical)
			{
				if(ao.xy == null)
					ao.xy = new AO(box,animTime,{});
				aoo = ao.xy;
				aop.xy.x = rmovable.x;
				aop.xy.y = rmovable.y;
				aoo.nProperties = aop.xy;
				axisArray = ['x','y',changesArgument];
			}
			else if(horizontal)
			{
				if(ao.x == null)
					ao.x = new AO(box,animTime,{});
				aoo =  ao.x;
				aop.x.x = rmovable.x;
				aoo.nProperties = aop.x;
				axisArray = ['x',null,changesArgument];
			}
			else if(vertical)
			{
				if(ao.y == null)
					ao.y = new AO(box,animTime,{});
				aoo =  ao.y;
				aop.y.y = rmovable.y;
				aoo.nProperties = aop.y;
				axisArray = ['y',null,changesArgument];
			}
			//changes
			if(liveChanges && (changesArgument != null))
			{
				aoo.onUpdate = changeNotify;
				aoo.onUpdateArgs = axisArray;
			}
			else if(changesArgument != null)
			{
				aoo.onUpdate = null;
				aoo.onComplete = changeNotify;
				aoo.onCompleteArgs =axisArray;
			}
			else
			{
				aoo.onUpdate = null;
				aoo.onComplete = null;
				aoo.onCompleteArgs =null;
			}
			//properties
			aoo.subject = box;
			aoo.cycles = 1;
			aoo.nEasing = easingFunc;
			aoo.nSeconds = animTime;
			if(inited)
				aoo.restart(0,true);
			else
			{
				aoo.start();
				inited = true;
			}
		}
		
		
		// -------------------------------- PUBLIC API ---------------------------------- //
		/** object which limits area where <code>box</code> can be moved around according to <code>horizontalBehavior</code> 
		 * and <code>verticalBehavior</code> rules. @see #horizontalBehavior @see #verticalBehavior @see #box */
		public function get bound():DisplayObject {	return bnd }
		public function set bound(v:DisplayObject):void
		{
			if(bnd == v)
				return;
			if(bnd != null)
				removeBoundListeners();
			bnd = v;
			if(touchyBound)
				addBoundListeners();
			refresh();
		}
		
		/** object to move within <code>bound</code> area according according to <code>horizontalBehavior</code> 
		 * and <code>verticalBehavior</code> rules. listeners for dragging are  added automatically.
		 *  @see #horizontalBehavior @see #verticalBehavior @see #bound */
		public function get box():DisplayObject	{ return bx }
		public function set box(v:DisplayObject):void
		{
			if(bx != null)
				removeBoxListeners()
			bx = v;
			if(bx != null)
				addBoxListeners();
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
		 * <li> "edges" - box bottom is limited by bounds top, box top is limited by bounds bottom </li>
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
		public function refresh(omitAnimation:Boolean=false):void
		{
			if(box == null || bnd == null)
				return;
			if(horizontal && vertical)
				movementCommon(0,0,omitAnimation,true);
			else if(horizontal)
				movementHor(0,omitAnimation);
			else if(vertical)
				movementVer(0,omitAnimation);
		}
		
		/** Hrizontal position of the <code>box</code> between its minX and maxX values<br>
		 * Does not dispatch changes event, does not follow animation. @see #minX @see #maxX */
		public function set percentageHorizontal(v:Number):void { setPercentage(v, modH,true) }
		public function get percentageHorizontal():Number { return percentage.x }
		
		/** Vertical position of the <code>box</code> between its minY and maxY values.<br>
		 *  Does not dispatch changes event, does not follow animation. @see #minY @see #maxY */
		public function set percentageVertical(v:Number):void { setPercentage(v, modV,true) }
		public function get percentageVertical():Number { return percentage.y }
		
		/** determines horizontal position of the <code>box</code> between its minX and maxX values
		 * @param changesArgument - if null or false, no changes will be dispatched while processing this call, 
		 * otherwise argument will be passed to <code>onChange</code> function if specifed. @see #minX @see #maxX */
		public function setPercentageHorizontal(v:Number,omitAnimation:Boolean=false,changesArgument:Object=null):void { setPercentage(v, modH,omitAnimation,changesArgument) }
		
		/** determines vertical position of the <code>box</code> between its minY and maxY values 
		 * @param changesArgument - if null or false, no changes will be dispatched while processing this call, 
		 * otherwise argument will be passed to <code>onChange</code> function if specifed. @see #minY @see #maxY */
		public function setPercentageVertical(v:Number,omitAnimation:Boolean=false,changesArgument:Object=null):void { setPercentage(v, modV,omitAnimation,changesArgument) }
		
		/** Attempts to move box by delta, still follows <code>horizontalBehavior</code> rule
		 * @param changesArgument - if null or false, no changes will be dispatched while processing this call, 
		 * otherwise argument will be passed to <code>onChange</code> function if specifed. @see #horizontalBehavior */
		public function movementVer(delta:Number,omitAnimation:Boolean=false,changesArgument:Object=null):void  { deltaMovement(delta, modV,omitAnimation,changesArgument) }
		
		/** Attempts to move box by delta, still follows <code>verticalBehavior</code> rule
		 * @param changesArgument - if null or false, no changes will be dispatched while processing this call, 
		 * otherwise argument will be passed to <code>onChange</code> function if specifed. @see #verticalBehavior */
		public function movementHor(delta:Number,omitAnimation:Boolean=false,changesArgument:Object=null):void { deltaMovement(delta, modH,omitAnimation,changesArgument) }
		
		/** Attempts to set absolute box y, still follows <code>horizontalBehavior</code> rule
		 * @param changesArgument - if null or false, no changes will be dispatched while processing this call, 
		 * otherwise argument will be passed to <code>onChange</code> function if specifed. @see #horizontalBehavior */
		public function absoluteVer(absolute:Number,omitAnimation:Boolean=false,changesArgument:Object=null):void  { movementVer(absolute - rmovable.y,omitAnimation,changesArgument) }
		
		/** Attempts to  set absolute box x, still follows <code>verticalBehavior</code> rule
		 * @param changesArgument - if null or false, no changes will be dispatched while processing this call, 
		 * otherwise argument will be passed to <code>onChange</code> function if specifed. @see #verticalBehavior */
		public function absoluteHor(absolute:Number,omitAnimation:Boolean=false,changesArgument:Object=null):void { movementHor(absolute - rmovable.x, omitAnimation,changesArgument) }
		
		/**Updates box position by delta x and delta y simultaneously
		 * @param dx - delta x @param dx - delta y
		 * @param omitAnimation - if true, box will be updated immediately 
		 * @param changesArgument - if null or false, no changes will be dispatched while processing this call, 
		 * otherwise argument will be passed to <code>onChange</code> function if specifed.
		 * @see #absoluteCommon() @see #percentageCommon() */
		public function movementCommon(dx:Number, dy:Number, omitAnimation:Boolean=false,changesArgument:Object=null):void 
		{ 
			updateFrames();
			rmovable.x = box.x + dx;
			rmovable.y = box.y + dy;
			executeCommon(omitAnimation,changesArgument);
		}
		
		/**Updates box position to absolute values respecting horizontal and vertical behaviors
		 * @param ax - requested absolute box x  @param ay - requested absolute box y
		 * @param changesArgument - if null or false, no changes will be dispatched while processing this call, 
		 * otherwise argument will be passed to <code>onChange</code> function if specifed.
		 * @see #verticalBehavior @see #horizontalBehavior @see #movementCommon() @see #percentageCommon() */
		public function absoluteCommon(ax:Number, ay:Number, omitAnimation:Boolean=false,changesArgument:Object=null):void 
		{ 
			updateFrames();
			rmovable.x = ax;
			rmovable.y = ay;
			executeCommon(omitAnimation,changesArgument);
		}
		
		/**Updates box position to percentage of bound respecting horizontal and vertical behaviors.
		 * @param px - assuming inscribed: if bound is 200px wide setting px to 0.4 would set box x = 80
		 * @param px - assuming inscribed: if bound is 100px high setting py to 0.4 would set box y = 80
		 * @see #verticalBehavior @see #horizontalBehavior @see #absoluteCommon() @see #percentageCommon() */
		public function percentageCommon(px:Number, py:Number,omitAnimation:Boolean=false,changesArgument:Object=null):void 
		{ 
			updateFrames();
			rmovable.x = min.x + (max.x - min.x) *px;
			rmovable.y = min.y + (max.y - min.y) *py;
			executeCommon(omitAnimation,changesArgument);
		}
		
		/** Box movement can be smoothed by optimized animation of specific easing.<br>
		 * Programatic movement of box (methods <code> setPercentage*, delta*, absolute*</code>)allow to controll animation on every box movement call.</br>
		 * Mouse triggered movements can be eased if <code>omitDraggingAnimation = false</code>
		 * @see #omitDraggingAnimation
		 * @default 0 */
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
		
		/** Determines if pressing bound (not box) would magnet box to event place */
		public function get touchyBound():Boolean {	return xtouchyBound }
		public function set touchyBound(v:Boolean):void
		{
			if(xtouchyBound == v)
				return;
			xtouchyBound = v;
			if(!bnd)
				return
			if(!v)
				removeBoundListeners();
			else if(!bnd.hasEventListener(MouseEvent.MOUSE_DOWN))
				addBoundListeners();
		}
		/** Stops all current movement of box*/
		public function killAnimations():void
		{
			if(ao)
			{
				AO.killOff(ao.x);
				AO.killOff(ao.y);
				AO.killOff(ao.xy); 
				updatePercentage('x');
				updatePercentage('y');
			}
		}
		
		/** Dispatches change event*/
		public function dispatchChange(changesArgument:Object=null):void { 
			this.xChangesArgument = changesArgument;
			this.dispatchEvent(eventChange);
		}
		public function get changesArgument():Object { return xChangesArgument }
		/** If animationTime is > 0, box movements can be eased. Use BoundBox.easings to pick easing function */
		public function set easing(v:Function):void {this.easingFunc = v }
		
		/** Stops all animations, removes all event listeners and references to both bound and box */
		public function destroy():void
		{
			killAnimations();
			if(bound)
			{
				bound.removeEventListener(Event.ADDED_TO_STAGE, boundOnStage);
				bound.removeEventListener(Event.REMOVED_FROM_STAGE, boundOffStage);
				bound.removeEventListener(MouseEvent.MOUSE_DOWN, onBoundMouseDown);
			}
			if(boundStage)
			{
				boundStage.removeEventListener(MouseEvent.MOUSE_MOVE, onBoundMouseMove);
				boundStage.removeEventListener(MouseEvent.MOUSE_UP, onBoundMouseUp);
			}
			if(bx)
			{
				bx.removeEventListener(Event.ADDED_TO_STAGE, boxOnStage);
				bx.removeEventListener(Event.REMOVED_FROM_STAGE, boxOffStage);
				bx.removeEventListener(MouseEvent.MOUSE_DOWN, onBoxMouseDown);
			}
			if(boxStage)
			{
				boxStage.removeEventListener(MouseEvent.MOUSE_MOVE, onBoxMouseMove);
				boxStage.removeEventListener(MouseEvent.MOUSE_UP, onBoxMouseUp);
			}
			bound = null;
			box = null;
			boundStage = null;
			boxStage = null;
			ao = null;
			changeNotifications = false;
			xChangesArgument = null;
			liveChanges = false;
			eventChange = null;
			rmovable =  rstatic = null;
			boxStart = min = max = null;
			mapf = mapn = null;
			modH =  mods = modV = null;
		}
	}
}
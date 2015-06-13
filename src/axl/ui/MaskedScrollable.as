package axl.ui
{
	import flash.display.DisplayObject;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	
	import axl.ui.controllers.BoundBox;
	
	/** Define visible width and height, addChildren to container. Usefull for windows, viewports, textfields etc.
	 * Listen to event change and use instance method <code> percentageHorizontal</code> and <code> percentageVertical </code>
	 * to findOut current state */
	public class MaskedScrollable extends Sprite
	{
		private var vWid:Number=1;
		private var vHeight:Number=1;
		private var shapeMask:Shape;
		private var maskObject:DisplayObject;
		
		private var fakeRect:Rectangle = new Rectangle();
		private var eventChange:Event = new Event(Event.CHANGE);
		private var ctrl:BoundBox;
		private var deltaMultiply:int=1;
		
		public var container:Sprite;
		public var wheelScrollAllowed:Boolean = true;
		
		public function MaskedScrollable()
		{
			ctrl = new BoundBox();
			super();
			shapeMask = new Shape();
			container = new Sprite();
			container.mask = shapeMask;
			super.addChild(container);
			super.addChild(shapeMask);
			
			redrawMask();
			ctrl.bound = shapeMask;
			ctrl.box = container;
			maskObject = shapeMask;
			addListeners();
		}
		
		public function get scrollVertical():Boolean { return ctrl.verticalAllowed }
		public function set scrollVertical(v:Boolean):void { ctrl.verticalAllowed = v }
		public function get scrollHorizontal():Boolean { return ctrl.horizontalAllowed }
		public function set scrollHorizontal(v:Boolean):void { ctrl.horizontalAllowed = v }
		
		
		public function get behaviorVert():String { return ctrl.verticalBehavior }
		public function set behaviorVert(v:String):void { ctrl.verticalBehavior = v }
		public function get behaviorHor():String { return ctrl.horizontalBehavior }
		public function set behaviorHor(v:String):void { ctrl.horizontalBehavior = v }

		private function addListeners():void { this.addEventListener(MouseEvent.MOUSE_WHEEL, wheelEvent) }
		
		protected function wheelEvent(e:MouseEvent):void {
			if(!wheelScrollAllowed) return;
			ctrl.movementVer(e.delta * deltaMultiply);
			ctrl.dispatchEvent(eventChange);
		}
		
		private function redrawMask():void
		{
			shapeMask.graphics.clear();
			shapeMask.graphics.beginFill(0);
			shapeMask.graphics.drawRect(0,0,visibleWidth, visibleHeight);
			container.mask =shapeMask;
		}
	
		
		override public function get width():Number	{ return maskObject.width }
		override public function get height():Number { return maskObject.height }
		
		override public function getBounds(targetCoordinateSpace:DisplayObject):Rectangle
		{
			fakeRect = container.getBounds(targetCoordinateSpace);
			fakeRect.x =this.x;
			fakeRect.y =this.y;
			return fakeRect;//super.getBounds(targetCoordinateSpace);
		}
		
		override public function getRect(targetCoordinateSpace:DisplayObject):Rectangle
		{
			fakeRect = container.getRect(targetCoordinateSpace);
			fakeRect.x =this.x;
			fakeRect.y =this.y;
			return fakeRect;
		}
		
		// -------------------------------- PUBLIC API ---------------------------------- //
		public function get visibleHeight():Number { return vHeight }
		public function set visibleHeight(value:Number):void
		{
			vHeight = value;
			redrawMask();
		}
		
		public function get visibleWidth():Number { return vWid }
		public function set visibleWidth(value:Number):void
		{
			vWid = value;
			redrawMask();
		}
		
		/** determines scroll efficiency default 1. Passing font size + spacing */
		public function get deltaMultiplier():int { return deltaMultiply }
		public function set deltaMultiplier(value:int):void	{ deltaMultiply = value }
		
		/** returns controller */
		public function get controler():BoundBox { return ctrl }
	}
}
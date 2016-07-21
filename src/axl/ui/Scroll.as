package axl.ui
{
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import axl.ui.controllers.BoundBox;
	
	public class Scroll extends Sprite
	{
		private var ctrl:BoundBox;
		private var xrail:DisplayObject;
		private var xtrain:DisplayObject;
		
		/** Determines scroll efficiency default 1. For container containing text fields optimal value is 15*/
		public var deltaMultiplier:Number=1;
		/** Deterimines if masked content movement can be triggered by mouse wheel events.  @see #deltaMultiplier */
		public var wheelScrollAllowed:Boolean = false;
		/** Class provides simple scroll bar functionality. Instantiated from &lt;scrollBar/&gt;.<br>
		 * It makes use of <code>axl.ui.controllers.BoundBox</code> controler, which needs two Display Objects
		 * to satisfy functionality (bound &amp; box), here named as <code>rail</code> and <code>train</code>.
		 * @param definition - xml definition @param xroot - reference to parent xRoot object
		 * @see axl.xdef.types.display.xScroll  @see axl.xdef.interfaces.ixDef#def  @see axl.xdef.interfaces.ixDef#xroot
		 * @see axl.xdef.XSupport#getReadyType2() */
		public function Scroll()
		{
			makeBox();
			this.addEventListener(MouseEvent.MOUSE_WHEEL, wheelEvent);
			super();
		}
		
		//-----------------------  INTERNAL -------------------- //
		private function makeBox():void
		{
			ctrl = new BoundBox();
			ctrl.bound = rail;
			ctrl.box = train;
			ctrl.liveChanges = true;
			ctrl.horizontalBehavior = BoundBox.inscribed;
			ctrl.verticalBehavior = BoundBox.inscribed;
		}
		
		public function increase(e:Event=null):void
		{
			if(controller.horizontal)
				ctrl.movementHor(deltaMultiplier,false,this);
			else if(controller.vertical)
				ctrl.movementVer(deltaMultiplier,false,this);
		}
		
		public function decrease(e:Event=null):void
		{
			if(controller.horizontal)
				ctrl.movementHor(-deltaMultiplier,false,this);
			else if(controller.vertical)
				ctrl.movementVer(-deltaMultiplier,false,this);
		}
		
		/** Receives wheel events and passes delta * deltaMultipy values to controller. */
		protected function wheelEvent(e:MouseEvent):void
		{
			if(!wheelScrollAllowed || e.delta==0) 
				return;
			if(ctrl.vertical)
				ctrl.movementVer((e.delta * deltaMultiplier) * -1,false,ctrl);
			else if(ctrl.horizontal)
				ctrl.movementHor((e.delta * deltaMultiplier) * -1,false,ctrl);
		}
		
		//-----------------------  INTERNAL -------------------- //
		//-----------------------  PUBLIC API -------------------- //
		/** Defines area on which <code>train</code> can be moved. @see axl.ui.controllers.BoundBox#bound*/
		public function get rail():DisplayObject { return xrail }
		public function set rail(v:DisplayObject):void { xrail = ctrl.bound = v }
		
		/** Defines an element which can be dragged moved and scrolled within <code>rail</code> bounds.
		 *  @see axl.ui.controllers.BoundBox#box*/
		public function get train():DisplayObject { return xtrain }
		public function set train(v:DisplayObject):void { xtrain = ctrl.box = v }
		
		/** Returns controller @see axl.ui.controllers.BoundBox */
		public function get controller():BoundBox { return ctrl }
		
	}
}
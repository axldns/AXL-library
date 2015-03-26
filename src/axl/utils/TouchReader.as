package axl.utils
{
	/**
	 * [axldns free coding 2014]
	 */
	import flash.geom.Point;
	
	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.display.Stage;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;

	public class TouchReader
	{
		private static var whos:Vector.<ITouchLogic> = new Vector.<ITouchLogic>();
		public static var horMovement:Number;
		public static var verMovement:Number;
		
		public static var momental:Point 			= new Point();
		public static var movSinceChangedDir:Point 	= new Point();
		public static var abs:Point 				= new Point();
	
		public static var abr:Number;
		public static var tweakPointX:Point;
		public static var tweakPointY:Point;
		
		public static var tweakStart:Number;
		public static var fingerLoc:Point;
		public static var changedDirHor:Boolean;
		public static var changedDirVer:Boolean;
		
		public static var isDoubleClick:Boolean;
		public static var prevTimeStamp:Number;
		private static var touch:Touch;
		
		public function TouchReader()
		{
		}
		
		public static function init(s:Stage):void
		{
			s.addEventListener(starling.events.TouchEvent.TOUCH, TE);
		}
		
		private static function TE(e:TouchEvent):void
		{
			touch = e.getTouch(starling.core.Starling.current.stage);
			
			if(!touch)
				return;
			analyse(touch);
		}
		
		private static function analyse(t:Touch):void
		{
			//trace('analyse', t.phase);
			switch(t.phase)
			{
				case TouchPhase.BEGAN:
					resetTouchAnalysers(t);
					broadcast('tapBegan', t);
					break;
				case TouchPhase.MOVED:
					updateMoveAnalysers(t);
					broadcast('tapMoved', t);
					break;
				case TouchPhase.ENDED:
					broadcast('tapEnded', t);
					break;
			}
		}
		
		private static function resetTouchAnalysers(t:Touch):void
		{
			isDoubleClick = (((t.timestamp - prevTimeStamp) < .5) && (abs.y < 10) && (abs.y < 10));
			
			horMovement = 0;
			verMovement = 0;
			abs.x = 0;
			abs.y = 0;
			updateMoveAnalysers(t);
			tweakPointX = fingerLoc;
			tweakPointY = fingerLoc;
			movSinceChangedDir.x = 0;
			movSinceChangedDir.y = 0;
			momental.x = 0;
			momental.y = 0;
			
			prevTimeStamp = t.timestamp;
		}
		
		public static function updateMoveAnalysers(touch:Touch):Point
		{
			fingerLoc = touch.getLocation(starling.core.Starling.current.stage); 
			
			if(((touch.globalX > touch.previousGlobalX) && (momental.x < 0)) || ((touch.globalX < touch.previousGlobalX) &&  (momental.x > 0)))
			{
				tweakPointX = fingerLoc;
				changedDirHor = true;
				movSinceChangedDir.x = 0;
			}
			else
				changedDirHor = false;
			
			if(((touch.globalY > touch.previousGlobalY) && (momental.y < 0)) || ((touch.globalY < touch.previousGlobalY) &&  (momental.y > 0)))
			{
				tweakPointY = fingerLoc;
				changedDirVer = true;
				movSinceChangedDir.y = 0;
			}
			else
				changedDirVer = false;
			
			
			momental.x = touch.globalX - touch.previousGlobalX;
			momental.y = touch.globalY - touch.previousGlobalY;
			
			horMovement += momental.x;
			verMovement += momental.y;
			movSinceChangedDir.x += momental.x;
			movSinceChangedDir.y += momental.y;
			abs.x += Math.abs(momental.x);
			abs.y += Math.abs(momental.y);
			
			
			
			if(!(abs.y != 0))
				abs.y = 0.01;
			abr = abs.x/abs.y;
			
			return fingerLoc;
		}
		public static function isTouching(asker:Object, maybeParent:Object):Boolean
		{
			var istouching:Boolean;
			if(maybeParent == asker)
				istouching = true;
			else if(maybeParent.parent)
				istouching = isTouching(asker, maybeParent.parent);
			return istouching;
		}
		
		public static function listen(who:ITouchLogic):void
		{
			if(whos.indexOf(who) < 0)
				whos.push(who);
		}
		
		public static function dontListen(who:ITouchLogic):void
		{
			var i:int = whos.indexOf(who);
			if(i > -1)
				whos.splice(i,1);
		}
		
		public static function before(who:ITouchLogic, beforeWho:ITouchLogic):void
		{
			var i:int = whos.indexOf(beforeWho);
			whos.splice(i,0,who);
		}
		public static function after(who:ITouchLogic, afterWho:ITouchLogic):void
		{
			var i:int = whos.indexOf(afterWho);
			whos.splice(i+1,0,who);
		}
		public static function viewQueue():String
		{
			return whos.toString();
		}
		
		private static function broadcast(type:String, touch:Touch):void
		{
			//trace('broadcast', type);
			var l:int = whos.length;
			var o:ITouchLogic;
			for(var i:int = 0; i < l; i++)
			{
				o = whos[i];
				if(touch.isTouching(o as DisplayObject))
					o[type](touch);
					
			}
			o = null;
			
		}
	}
}

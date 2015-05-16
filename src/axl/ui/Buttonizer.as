package axl.ui
{
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	
	public class Buttonizer extends Sprite
	{
		public static var defaultOverProperty:String='alpha';
		public static var defaultOverValue:Object='.75';
		public static var defaultUpValue:Object='1';
		private var vProperty:String;
		private var vUp:Object;
		private var vOver:Object;
		private var isEnabled:Boolean;
		private var userClickHandler:Function;
		
		public function Buttonizer(upstate:DisplayObject, clickHandler:Function, property:String='default', valueUp:Object='default', valueOver:Object='default')
		{
			
			if(property == 'default')
				vProperty = defaultOverProperty;
			if(valueUp == 'default')
				vUp = defaultUpValue;
			if(valueOver == 'default')
				vOver = defaultOverValue;
			userClickHandler = clickHandler;
			this.addChild(upstate);
			this.buttonMode = true;
			this.useHandCursor = true;
			enabled = true;
		}
		
		protected function onOut(e:MouseEvent):void{ this[vProperty] = vUp }
		protected function onOver(e:MouseEvent):void { this[vProperty] = vOver	}
		protected function onClick(e:MouseEvent):void
		{
			if(userClickHandler != null) 
			{
				if(userClickHandler.length > 0)
					userClickHandler(e);
				else
					userClickHandler();
			}
		}
		
		public function get enabled():Boolean {	return isEnabled }
		public function set enabled(value:Boolean):void
		{
			isEnabled = value;
			if(isEnabled)
			{
				this.addEventListener(MouseEvent.CLICK, onClick);
				this.addEventListener(MouseEvent.ROLL_OVER, onOver);
				this.addEventListener(MouseEvent.ROLL_OUT, onOut);
			}
			else
			{
				this.removeEventListener(MouseEvent.CLICK, onClick);
				this.removeEventListener(MouseEvent.ROLL_OVER, onOver);
				this.removeEventListener(MouseEvent.ROLL_OUT, onOut);
			}
		}
	}
}
/**
 *
 * AXL Library
 * Copyright 2014-2015 Denis Aleksandrowicz. All Rights Reserved.
 *
 * This program is free software. You can redistribute and/or modify it
 * in accordance with the terms of the accompanying license agreement.
 *
 */
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
		private var vIdle:Object;
		private var vOver:Object;
		private var isEnabled:Boolean;
		private var texture:DisplayObject;

		private var userClickHandler:Function;
		
		public function get enabled():Boolean {	return isEnabled }
		public function set enabled(value:Boolean):void
		{
			isEnabled = value;
			if(isEnabled)
			{
				this.addEventListener(MouseEvent.CLICK, clickHandler);
				this.addEventListener(MouseEvent.ROLL_OVER, onOver);
				this.addEventListener(MouseEvent.ROLL_OUT, onOut);
			}
			else
			{
				this.removeEventListener(MouseEvent.CLICK, clickHandler);
				this.removeEventListener(MouseEvent.ROLL_OVER, onOver);
				this.removeEventListener(MouseEvent.ROLL_OUT, onOut);
			}
		}
		
		public function get upstate():DisplayObject { return texture }
		public function set upstate(v:DisplayObject):void
		{
			if(texture != null && contains(texture) && texture != v)
				this.removeChild(texture);
			texture = v;
			if(upstate !=null)
				this.addChild(texture);
		}
		
		public function Buttonizer(upstateChild:DisplayObject, clickHandler:Function, property:String='default', valueUp:Object='default', valueOver:Object='default')
		{
			if(property == 'default')
				vProperty = defaultOverProperty;
			if(valueUp == 'default')
				vIdle = defaultUpValue;
			if(valueOver == 'default')
				vOver = defaultOverValue;
			userClickHandler = clickHandler;
			upstate = upstateChild;
			this.buttonMode = true;
			this.useHandCursor = true;
			enabled = true;
		}
		
		
		public function set rollOverValue(v:Object):void { vOver = v }
		public function get idleValue():Object { return vProperty }
		public function set idleValue(v:Object):void { vIdle = v }
		
		public function get rollOverProperty():String {	return vProperty }
		public function set rollOverProperty(value:String):void	{ vProperty = value }
		public function get rollOverValue():Object { return vOver }
		
		
		protected function onOut(e:MouseEvent):void{ this[vProperty] = vIdle }
		protected function onOver(e:MouseEvent):void { this[vProperty] = vOver	}
		protected function clickHandler(e:MouseEvent):void
		{
			if(userClickHandler != null) 
			{
				if(userClickHandler.length > 0)
					userClickHandler(e);
				else
					userClickHandler();
			}
		}
		
		public function get onClick():Function { return userClickHandler }
		public function set onClick(v:Function):void { userClickHandler = v	}
		
	}
}
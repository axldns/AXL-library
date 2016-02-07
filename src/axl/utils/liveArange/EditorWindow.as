/**
 *
 * AXL Library
 * Copyright 2014-2016 Denis Aleksandrowicz. All Rights Reserved.
 *
 * This program is free software. You can redistribute and/or modify it
 * in accordance with the terms of the accompanying license agreement.
 *
 */
package axl.utils.liveArange
{
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TextEvent;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.ui.Keyboard;
	import flash.utils.describeType;
	
	import axl.utils.U;
	
	/**
	 * Class that allows "on screen edit" any DisplayObject.<br>
	 * Allows to drag  and resize this window aside from editing <code>subject</code>.<br>
	 * Provides:
	 * <ul>
	 * <li>list of <b>all</b> properties which can be set for <code>subject</code> of this editor</li>
	 * <li>Simple links to traverse display list up, down and sideways</li>
	 * <li>options to filter list by properties name</li>
	 * </ul>
	 * Input fields have easing for setting numeric and boolean values: use keyboard arrows!
	 */
	public class EditorWindow extends Sprite
	{
		private var stf:TextFormat;
		private var props:Vector.<Property>;
		private var propMatch:Vector.<Property>;
		
		private var r:RegExp;
		private var xtarget:DisplayObject;
		private var xml:XMLList;
		
		private var xwidth:Number=120;
		private var balance:Number = 0.5;
		private var coffset:Point = new Point();
		private var cGloToLo:Point = new Point();
		
		private var filter:TextField;
		private var tparent:TextField;
		private var propspool:Sprite;
		private var allbounds:Sprite;
		private var boundLeft:Sprite;
		private var boundTop:Sprite;
		private var boundMiddle:Sprite;
		private var boundRight:Sprite;
		private var boundDrag:Sprite;
		
		public var exitEditor:Function;
		public var getParent:Function;
		public var getChild:Function;
		public var getSybiling:Function
		public var shiftMultiply:int=5;
		public var maxProperties:int = 30;
		
		/** @see EditorWindow*/
		public function EditorWindow()
		{
			props = new Vector.<Property>();
			propMatch = new Vector.<Property>();
			
			stf =new TextFormat("Arial",12);
			filter = new TextField();
			filter.background = true;
			filter.border = true;
			filter.multiline = false;
			filter.type='input';
			filter.width = xwidth;
			filter.height = 17;
			filter.defaultTextFormat = stf;
			filter.text = 'name|x|y|z|scale';
			filter.setTextFormat(stf);
			tparent = new TextField();
			tparent.border = true;
			tparent.width = xwidth;
			tparent.height = 20;
			tparent.htmlText = '<font color="#ffffff"><p align="center"><u><b><a href="event:parent">parent</a> | <a href="event:child">child</a> | <a href="event:sister">sister</a></b></u></p></font>';
			tparent.y = filter.height;
			tparent.addEventListener(TextEvent.LINK, onHyperTextEvent);
			propspool = new Sprite();
			propspool.y = tparent.y + tparent.height;
			boundLeft =new Sprite();
			boundMiddle = new Sprite();
			boundTop = new Sprite();
			boundRight = new Sprite();
			allbounds = new Sprite();
			balance = 0.5;
			U.addChildGroup(allbounds, boundLeft, boundMiddle, boundRight,boundTop);
			U.addChildGroup(this, propspool,filter,tparent,allbounds );
			this.addEventListener(Event.ADDED_TO_STAGE, ats);
			this.addEventListener(Event.REMOVED_FROM_STAGE, rfs);
		}
		//------------------EVENTS HANDLING------------------------//
		
		//---STAGE EVENTS---//
		protected function ats(event:Event):void
		{
			this.addEventListener(Event.ENTER_FRAME, onEnterFrame);
			filter.addEventListener(KeyboardEvent.KEY_UP, onSearcherText);
			this.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			allbounds.addEventListener(MouseEvent.MOUSE_OVER, mouseOverBounds);
			allbounds.addEventListener(MouseEvent.MOUSE_OUT, mouseOutBounds);
			allbounds.addEventListener(MouseEvent.MOUSE_DOWN, md);
			this.propspool.addEventListener(MouseEvent.CLICK, onEditorFieldFocusIn);
		}
		
		protected function rfs(e:Event):void
		{
			propMatch.length=0;
			removeAllEventListeners();
		}
		
		protected function onEnterFrame(e:Event):void
		{
			for(var i:int = 0, j:int = propMatch.length; i < j; i++)
				propMatch[i].updateFromObjectToTextfield();
		}
		//---END OFSTAGE EVENTS---//
		
		//---KEYBOARD EVENTS---//
		protected function onKeyDown(e:KeyboardEvent):void
		{
			var p:Property =  e.target.parent as Property;
			if(!p)
				return;
			switch(e.keyCode)
			{
				case Keyboard.ENTER:
					p.updateFromTextfieldToObject();
					break;
				case Keyboard.RIGHT:
				case Keyboard.UP:
					p.keyUp(e.shiftKey ? shiftMultiply : 1);
					break;
				case Keyboard.LEFT:
				case Keyboard.DOWN:
					p.keyDown(e.shiftKey ? shiftMultiply: 1);
					break;
			}
		}
		
		protected function onSearcherText(e:KeyboardEvent):void
		{
			r = new RegExp(filter.text, "i");
			parse();
		}
		//---END OF KEYBOARD EVENTS---//
		
		//---MOUSE EVENTS---//
		protected function md(e:MouseEvent):void
		{
			U.STG.addEventListener(MouseEvent.MOUSE_MOVE, mm);
			U.STG.addEventListener(MouseEvent.MOUSE_UP, mu);
			boundDrag = e.target as Sprite;
			if(!boundDrag) return;
			coffset.x =  boundDrag.mouseX * boundDrag.scaleX;
			coffset.y =  boundDrag.mouseY * boundDrag.scaleY;
		}
		
		protected function mm(e:MouseEvent):void
		{
			cGloToLo.setTo(this.stage.mouseX, this.stage.mouseY);
			cGloToLo = this.parent.globalToLocal(cGloToLo);
			switch(boundDrag)
			{
				case boundLeft:
					this.width = this.x + this.width -  (cGloToLo.x- coffset.x);
					this.x = cGloToLo.x- coffset.x;
					
					break;
				case boundTop:
					this.x = cGloToLo.x- coffset.x;
					this.y = cGloToLo.y- coffset.y;
					break;
				case boundMiddle:
					balance = this.mouseX / xwidth;
					if(balance > 0.95) balance = 0.95;
					if(balance < 0.05) balance = 0.05;
					boundMiddle.x = balance * width - (boundMiddle.width/2)
					for(var i:int = 0, j:int = propMatch.length; i < j; i++)
						props[i].updateBalance(balance);
					break;
				case boundRight:
					var nw:Number = (cGloToLo.x- coffset.x) - this.x;
					if(nw < 10)
					{
						this.x -= 2;
						this.width = 10;
					}
					else this.width = nw;
					break;
			}
			if(this.y < 0) this.y = 0;
			if(this.x < 0) this.x = 0;
		}
		
		protected function mu(e:MouseEvent):void
		{
			U.STG.removeEventListener(MouseEvent.MOUSE_MOVE, mm);
			U.STG.removeEventListener(MouseEvent.MOUSE_UP, mu);
			if(boundDrag)
				boundDrag.alpha =0;
			boundDrag = null;
		}
		
		protected function mouseOverBounds(e:MouseEvent):void
		{
			e.target.alpha = 0.8;
		}
		
		protected function mouseOutBounds(e:MouseEvent):void
		{
			if(e.target != boundDrag)
				e.target.alpha = 0;
		}
		
		protected function onEditorFieldFocusIn(e:MouseEvent):void
		{
			var p:Property =  e.target.parent as Property;
			if(!p)
				return;
			p.expand();
			p.addEventListener(FocusEvent.FOCUS_OUT, onEditorFieldFocusOut);
			U.distribute(propspool,0,false);
		}
		
		protected function onEditorFieldFocusOut(e:Event):void
		{
			var p:Property =  e.target.parent as Property;
			if(!p)
				return;
			p.removeEventListener(FocusEvent.FOCUS_OUT, onEditorFieldFocusOut);
			p.deflate();
			U.distribute(propspool,0,false);
		}
		
		protected function onHyperTextEvent(e:TextEvent):void
		{
			var f:Function;
			switch(e.text)
			{
				case 'parent':
					f = this.getParent;
					break;
				case 'child':
					f = this.getChild;
					break;
				case 'sister':
					f = this.getSybiling;
					break;
			}
			if(f != null)
				f();
		}
		//------------------END OF EVENTS HANDLING------------------------//
		//------------------ GENERAL MECHANIC AND API------------------------//
		
		override public function set width(v:Number):void
		{
			xwidth = v;
			for(var i:int = 0, j:int = propMatch.length; i < j; i++)
				props[i].width = v;
			filter.width = v;
			tparent.width = v;
			updateBg();
		}
		
		/** Crrently edited object */
		public function get subject():DisplayObject {return xtarget}
		public function set subject(target:DisplayObject):void
		{
			var desc:XML = flash.utils.describeType(target);
			xml = desc.accessor.(@access == 'readwrite') + desc.variable.(@type != 'Function');
			xtarget = target;
			parse();
		}
		
		private function parse():void
		{
			r = r || new RegExp(filter.text, "i");
			var ll:int = xml.length();
			var limit:int=0;
			var xl:XML;
			var p:Property;
			propMatch.length = 0;
			propspool.removeChildren();
			for(var i:int = 0; i < ll; i++)
			{
				xl = xml[i];
				if(String(xl.@name).match(r))
				{
					if(limit < props.length)
						props[limit].parse(xml[i]);
					else
						props[limit] = new Property(this,xml[limit]);
					p = props[limit];
					p.width = xwidth;
					propspool.addChild(p);
					propMatch.push(p);
					if(++limit>=maxProperties)
						break;
				}
			}
			U.distribute(propspool,0,false);
			updateBg();
		}
		/** redraws instance*/
		public function updateBg():void
		{
			graphics.clear();
			boundLeft.graphics.clear();
			boundTop.graphics.clear();
			boundMiddle.graphics.clear();
			boundRight.graphics.clear();
			
			graphics.beginFill(0,0.2);
			graphics.drawRect(0,0,xwidth,height);
			
			boundLeft.graphics.beginFill(0xffff00);
			boundLeft.graphics.drawRect(0,0,5,height);
			boundLeft.alpha = 0;
			
			boundTop.graphics.beginFill(0xffff00);
			boundTop.graphics.drawRect(0,0,xwidth,5);
			boundTop.alpha = 0;
			
			boundMiddle.graphics.beginFill(0xffff00);
			boundMiddle.graphics.drawRect(0,0,5,height);
			boundMiddle.x = (xwidth * balance) - (boundMiddle.width/1);
			boundMiddle.alpha = 0;
			
			boundRight.graphics.beginFill(0xffff00);
			boundRight.graphics.drawRect(0,0,5,height);
			boundRight.x = xwidth - (boundRight.width/1);
			boundRight.alpha = 0;
		}
		
		private function removeAllEventListeners():void
		{
			this.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			this.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			if(filter)
				filter.removeEventListener(KeyboardEvent.KEY_UP, onSearcherText);
			if(allbounds)
			{
				allbounds.removeEventListener(MouseEvent.MOUSE_OVER, mouseOverBounds);
				allbounds.removeEventListener(MouseEvent.MOUSE_OUT, mouseOutBounds);
				allbounds.removeEventListener(MouseEvent.MOUSE_DOWN, md);
			}
			if(U.STG)
			{
				U.STG.removeEventListener(MouseEvent.MOUSE_MOVE, mm);
				U.STG.removeEventListener(MouseEvent.MOUSE_UP, mu);
			}
		}
		/** Removes all event listeners and destroys instance*/
		public function destroy():void
		{
			removeAllEventListeners();
			if(parent)
				parent.removeChild(this);
			removeChildren();
			if(props)
				while(props.length)
					props.pop().destroy();
			props = null;
			stf = null;
			if(propMatch)
				propMatch.length = 0;
			propMatch = null;
			r = null;
			xtarget = null;
			xml = null;
			coffset = cGloToLo = null;
			filter = tparent = null;
			propspool = allbounds = boundLeft = boundTop = boundMiddle =  boundRight = boundDrag =  null;
			exitEditor = getChild = getSybiling = null;
		}
	}
}
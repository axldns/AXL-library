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
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import flash.text.TextField;

	/**
	 * Class that holds and displays information of the display object set as <code>target</code>.<br>
	 * Draws it's outline and live(onEnterFrame) tracks it's bounds.
	 * Selector listens to enterFrame events only when its added to stage. Removed, removes listeners
	 * automatically.<br>
	 * Displays basic info (type,name,x,y,width,height) in an infobar on top of outline.
	 * If <code>mouseEnabled = true</code>, allows to doubleclick selection and fire <code>onDoubleClick</code>.
	 */
	public class Selector extends Sprite
	{
		private var bnds:Rectangle;
		private var xtarget:DisplayObject;
		private var miniHint:TextField;
		/** Executed if  <code>mouseEnabled = true</code> and doubleClick was registered*/
		public var onDoubleClick:Function;
		/** @see Selector */
		
		private var styleIndex:int;
		private var drawing:Vector.<Function>;
		private var drawingFunc:Function;
		public function Selector(doubleClickHandler:Function){
			
			onDoubleClick = doubleClickHandler;
			doubleClickEnabled = true;
			buildMiniHint();
			drawing = new <Function>[drawOutlineAndBg, drawOutlineAndBg, drawBGnoOutline, drawBGnoOutline, drawOutlineNoBg, drawOutlineNoBg  ];
			styleIndex =-1;
			nextStyle();
			this.addEventListener(Event.ADDED_TO_STAGE, ats);
			this.addEventListener(Event.REMOVED_FROM_STAGE, rfs);
		}
		
		protected function ats(event:Event):void
		{
			this.addEventListener(Event.ENTER_FRAME, onEnterFrame);
			this.addEventListener(MouseEvent.DOUBLE_CLICK, xonDoubleClick);
		}
		protected function rfs(event:Event):void
		{
			this.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			this.removeEventListener(MouseEvent.DOUBLE_CLICK, xonDoubleClick);
		}
		
		protected function xonDoubleClick(event:MouseEvent):void
		{
			if(onDoubleClick)
				onDoubleClick();
		}
		
		protected function onEnterFrame(e:Event):void { update() }
		
		private function buildMiniHint():void
		{
			miniHint = new TextField();
			miniHint.border = true;
			miniHint.background = true;
			miniHint.backgroundColor = 0xEECD8C;
			miniHint.height = 19;
			miniHint.selectable = false;
			miniHint.mouseEnabled = false;
			miniHint.tabEnabled = false;
			addChild(miniHint);
		}
		private function drawBGnoOutline():void
		{
			this.graphics.beginFill(0xff,0.2);
			this.graphics.drawRect(0,0,bnds.width,bnds.height);
			this.graphics.endFill();
		}
		
		private function drawOutlineNoBg():void
		{
			this.graphics.lineStyle(1,0x00ff00,0.8);
			this.graphics.drawRect(0.5,0.5,bnds.width-1,bnds.height-1);
		}
		
		private function drawOutlineAndBg():void
		{
			drawBGnoOutline();
			drawOutlineNoBg();
		}
		
		/** Subject of information tracking*/
		public function get target():DisplayObject { return xtarget }
		public function set target(v:DisplayObject):void{
			this.graphics.clear();
			xtarget =v;
			update();
		}
		/** Update of outilne and information is automatic but can be called manually too.*/
		public function update():void
		{
			this.graphics.clear();
			if(!target || !target.stage)
				return;
			bnds = target.getBounds(target.stage);
			drawingFunc();
			x = bnds.x;
			y = bnds.y;
			
			miniHint.text = target.toString() + '[' + target.name +'] x:' + target.x + ' y:' 
				+ target.y + ' w:' + target.width + ' h:' + target.height;
			miniHint.width = miniHint.textWidth + 5;
		}
		
		/** Changes style of selecting
		 * <ol>
		 * <li>outline, bg, minihint</li>
		 * <li>outline, bg, no minihint</li>
		 * <li>no outline, bg, minihint</li>
		 * <li>no outline, bg, no minihint</li>
		 * <li>outline, no bg, minihint</li>
		 * <li>outline, no bg, no minihint</li>
		 * </ol> */
		public function nextStyle():void
		{
			if(++styleIndex >= drawing.length)
				styleIndex = 0;
			drawingFunc = drawing[styleIndex];
			if(styleIndex%2)
				if(contains(miniHint))
					removeChild(miniHint);
			else
				addChild(miniHint);
		}
		
		/** Removes listeners and destroys the instance. Destroyed can't be reused.*/
		public function destroy():void
		{
			this.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			this.removeEventListener(MouseEvent.DOUBLE_CLICK, onDoubleClick);
			this.removeEventListener(Event.ADDED_TO_STAGE, ats);
			this.removeEventListener(Event.REMOVED_FROM_STAGE, rfs);
			removeChildren();
			if(this.parent)
				this.parent.removeChild(this);
			this.graphics.clear();
			miniHint = null;
			bnds = null;
			xtarget = null;
			onDoubleClick = null;
		}
	}
}
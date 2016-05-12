/**
 *
 * AXL Library
 * Copyright 2014-2016 Denis Aleksandrowicz. All Rights Reserved.
 *
 * This program is free software. You can redistribute and/or modify it
 * in accordance with the terms of the accompanying license agreement.
 *
 */
package axl.ui
{	
	import flash.display.DisplayObject;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	/**
	 * Class provides carousel component. Ideal for scrollable lists galleries etc.
	 * Supports children of different dimensions. Can be horizontal OR vertical.
	 * Axles can be switched seamlessly (with children inside).
	 * <br><br>
	 * Set x and/or y properties of this object exactly where you want to the see center of your carousel
	 * (as carousel would be 1px wide and/or 1px high).
	 * Children are being distributed from the most center point. Children indices are under control of this class.
	 * <br><br>
	 * Component is well optimized: whenever possible - updates inner container (<code>railElementsContainer</code>) 
	 * rather than each and every child separately. Class overrides standard children manipulation methods
	 * (addChild, addChildAt, removeChild, removeChildren, removeChildAt, getChildByName, getChildAt, swapChildren, 
	 * swapChildrenAt, getChildIndex, setChildIndex, numChildren).
	 * Requests of such will reffer to railElementsContainer, therefore using element's parent should be takien into special consideration.<br><br>
	 * Class does not provide animation or 'next element selection' utilities. 
	 * Carousel provides only one method (<code>movementBit</code>) for propel, which accepts just one parameter (<code>delta</code>).
	 * All further and higher level features should be added separately e.g. extending this class. 
	 * <br><br>
	 * Supports gaps and allows to get "MIDDLE" child.
	 * @see #movementBit()
	 * @see #maxOffset
	 * @see #getChildClosestToCenter()
	 */
	public class Carusele extends Sprite
	{
		private static const modH:Object = { a : 'x', d : 'width', s: 'scaleX'};
		private static const modV:Object = { a : 'y', d : 'height', s: 'scaleY'};
		
		protected var mod:Object;
		protected var modA:Object;
		protected var rail:Sprite;
		private var HOR:Boolean;
		private var VER:Boolean;
		private var bug:Number=0;
		
		protected var gap:Number;
		protected var railNumChildren:int;
		protected var firstChild:DisplayObject;
		protected var lastChild:DisplayObject;
		protected var railDim:Number=0;
		
		private var dbg:Shape;
		/** If value is grater then 0, debug outlines of are drawn.
		 * Color is determined by this value. @default 0*/
		public var debug:uint=0;
		/** Determines max offset that rail container can have
		 * before elements are re-sorted and rail gets re-positioned. This value is in
		 * percentage (0-1).  @default 0.25*/
		public var maxOffset:Number = 0.25;
		/** Determines if rail's oppisite axle (v if horizontal and h if vertical) should be "center registered"
		 * (shifted by half of its dimension against 0) (true) or left at 0 (false) @default true */
		public var manageOppositeAxleCenter:Boolean=true;
		/** @see axl.ui.Carusele */
		public function Carusele()
		{
			super();
			gap = 0;
			railNumChildren =0;
			rail = new Sprite();
			super.addChild(rail);
			rail.addEventListener(Event.ADDED, elementAdded);
			rail.addEventListener(Event.REMOVED,  onElementRemoved);
			setAxle(true);
		}
		
		protected function onElementRemoved(event:Event):void
		{
			railNumChildren--;
			updateRail();
		}
		
		protected function elementAdded(e:Event):void
		{
			railNumChildren++;
			updateRail();
		}
		
		private function updateRail():void
		{
			railDim = rail[mod.d];
			rail[mod.a] = railDim/-2;
			if(manageOppositeAxleCenter)
				rail[modA.a] = rail[modA.d]/-2;
			rearange();
			movementBit(0);
			updateDebug();
		}
		
		private function updateDebug():void
		{
			if(!debug) return;
			if(!dbg)
			{
				dbg = new Shape();
				super.addChild(dbg);
			}
			dbg.graphics.clear();
			dbg.graphics.lineStyle(1, debug);
			dbg.graphics.drawRect(.5, .5, rail.width-1, rail.height-1);
			dbg.graphics.moveTo(0,0);
			dbg.graphics.lineTo(dbg.width, dbg.height);
			dbg.graphics.moveTo(dbg.width, 0);
			dbg.graphics.lineTo(0, dbg.height);
			dbg.x = rail.x;
			dbg.y = rail.y;
		}
		/** Allows to set carousel either horizontally or vertically */
		public function set isHORIZONTAL(v:Boolean):void
		{
			if(HOR == v)
				return;
			resetAxle(v);
		}
		
		private function setAxle(v:Boolean):void
		{
			HOR = v;
			VER = !v;
			if(v)
			{
				mod = modH;
				modA = modV;
			}
			else
			{
				mod = modV;
				modA = modH;
			}
		}
		
		private function resetAxle(v:Boolean):void
		{
			var centerarr:Array = getChildClosestToCenter();
			var can:Boolean = centerarr && centerarr.length;
			if(can)
			{
				var centerObj:DisplayObject = centerarr[0];
				var railOffset:Number =rail[mod.d]/2 + rail[mod.a];
				var objCenterOffset:Number = rail[mod.d]/2 - centerObj[mod.a];
				var objAbsoulteOffset:Number = railOffset - objCenterOffset;
				var opositeOffset:Number = rail[modA.d]/2 - centerObj[modA.a];
			}
			
			setAxle(v);
			if(can)
			{
				var sum:Number = 0;
				for(var i:int = 0; i < railNumChildren; i++)
				{
					firstChild = rail.getChildAt(i);
					firstChild[mod.a] = sum;
					firstChild[modA.a] = 0;
					sum += firstChild[mod.d]+GAP;
				}
				if(manageOppositeAxleCenter)
					rail[modA.a] = rail[modA.d]/-2;
				else
					rail[modA.a] = 0
				rail[mod.a] = 0;
				this.movementBit(- centerObj[mod.a]+objAbsoulteOffset);
			}
			
			this.updateDebug();
		}
		
		private function get railCenter():Number { return rail[mod.a] + (rail[mod.d] /2) }
		
		/** Returns current number elements in Carousel container*/
		public function get numRailChildren():int {	return railNumChildren }
		/** Container where all rail elements are displayed. Do not add elements to 
		 * this container directly, use <code>addToRail</code> method @see #addToRail() */
		public function get railElementsContainer():Sprite { return rail }
		/** Allows to set carousel either horizontally or vertically */
		public function get isHORIZONTAL():Boolean { return HOR }
		/** Allows to set carousel either horizontally or vertically */
		public function get isVERTICAL():Boolean { return VER }
		public function set isVERTICAL(v:Boolean):void 	{ isHORIZONTAL = !v}
		/** Defines gap (horizontal or vertical) between carusele elements. Can be negative [OB1]GAP[OB2]GAP[OB3] */
		public function get GAP():Number { return  gap}
		public function set GAP(v:Number):void { gap=v, rearange()}
		/** Adds display object to carousel. If Carousele is horizontal, it manages objects "x" position,
		 * If carouslee is vertical - it manges object's "y" property.
		 * @param child - new member of carousel
		 * @param index - specific index on which child is going to be added*/
		public function addToRail(child:DisplayObject, index:int=-1):DisplayObject
		{
			child[mod.a] = railDim + (railNumChildren>0?GAP:0);
			if(index > -1 && rail.numChildren < index)
				return rail.addChildAt(child,index);
			else
				return rail.addChild(child);
		}
		
		override public function addChild(v:DisplayObject):DisplayObject { return addToRail(v) }
		
		override public function addChildAt(v:DisplayObject,i:int):DisplayObject { return addToRail(v,i) }
		
		override public function contains(child:DisplayObject):Boolean { return rail.contains(child) }
		
		override public function getChildAt(index:int):DisplayObject { return rail.getChildAt(index) }
		
		override public function getChildByName(name:String):DisplayObject { return rail.getChildByName(name) }
		
		override public function getChildIndex(child:DisplayObject):int { return rail.getChildIndex(child) 	}
		
		override public function get numChildren():int { return rail.numChildren }
		
		override public function removeChild(child:DisplayObject):DisplayObject { return rail.removeChild(child) }
		
		override public function removeChildAt(index:int):DisplayObject { return rail.removeChildAt(index) }
		
		override public function removeChildren(beginIndex:int=0, endIndex:int=2147483647):void { rail.removeChildren(beginIndex, endIndex) 	}
		
		override public function setChildIndex(child:DisplayObject, index:int):void { rail.setChildIndex(child, index) }
		
		override public function swapChildren(child1:DisplayObject, child2:DisplayObject):void { rail.swapChildren(child1, child2) }
		
		override public function swapChildrenAt(index1:int, index2:int):void { rail.swapChildrenAt(index1, index2) }
		
		/** Pass delta of momentary movement (e.g. on touch move event, or animation tick update) to move
		 * elements added to carousel.
		 * To optimize performance set <code>maxOffset</code> property.
		 * @param delta - number of pixels to move carousel elements right/down (positive delta) or left/up (negative delta)
		 * @see #maxOffset */
		public function movementBit(delta:Number):void
		{
			if(railNumChildren < 1)
				return
			firstChild =  rail.getChildAt(0);
			lastChild = rail.getChildAt(railNumChildren-1);
			var axl:String = mod.a, dim:String = mod.d;
			var lastDim:Number;
			var firstDim:Number;
			var rearangeNeeded:Boolean;
			var newRailCenter:Number = railCenter + delta;
			var newRailCenterAbsolute:Number = Math.abs(newRailCenter);
			var sum:Number = 0;
			var percOffset:Number = newRailCenterAbsolute/railDim;
			if(percOffset > maxOffset)
			{
				if(newRailCenter<0)
				{
					while(newRailCenterAbsolute > 0)	// [ --------[----x----]|---------------------]
					{									// [ -------------[----|x----]----------------]
						firstChild = rail.getChildAt(0);
						firstDim  = firstChild[dim] + gap;
						newRailCenterAbsolute -= firstDim;
						sum += firstDim;
						rail.setChildIndex(firstChild, railNumChildren-1);
						rearangeNeeded = true;
					}
				}
				else if(newRailCenter>0)	// [ -------------------|[...x...]-----------]
				{							// [ -------------[...x|...]----------------]
					while(newRailCenterAbsolute > 0)
					{

						lastChild = rail.getChildAt(railNumChildren-1);
						lastDim = lastChild[dim] + gap;
						newRailCenterAbsolute -= lastDim;
						sum -= lastDim;
						rail.setChildIndex(lastChild, 0);
						rearangeNeeded = true;
					}
				}
			}
			if(rearangeNeeded)
				rearange();
			var nw:Number = rail[axl] + delta + sum;
			
			rail[axl] = nw;
			bug += (nw - rail[axl]);
			nw = rail[axl] + bug;
			rail[axl] += bug;
			bug = nw - rail[axl];
			
			if(debug)
				updateDebug();
		}
		
		/** Redistributes carousel elements accordingly to GAP property */
		public function rearange():void
		{
			var sum:Number = 0;
			for(var i:int = 0; i < railNumChildren; i++)
			{
				firstChild = rail.getChildAt(i);
				firstChild[mod.a] = sum;
				sum += firstChild[mod.d]+GAP;
			}
		}
		
		/**
		 * Returns an array where 
		 * <br><b>ZERO</b> element is rail display object closest to relative middle point of rail (0)
		 * <br><b>FIRST</b> element is Number determining offset to center (positive or negative)<br>
		 * Passing element's offset to <code>movementBit</code>, would center that object in carousel.<br>
		 * If two elements have identical offset (difference < 0.025px), first element is 
		 * returned (left one while horizontal and/or top one while vertical).
		 * @see #movementBit() */
		public function getChildClosestToCenter():Array
		{
			if(rail.numChildren < 1)
				return null;
			var railOffset:Number = rail[mod.d]/2 + rail[mod.a];
			var relativeCenter:Number =  rail[mod.d]/2 - railOffset;
			if(rail.numChildren == 1)
				return [rail.getChildAt(0),railOffset];
			var i:int = -1;
			var pos:Number= Number.MAX_VALUE*-1, ppos:Number;
			var p:DisplayObject, n:DisplayObject;
			while(++i < railNumChildren) 
			{
				n = rail.getChildAt(i);
				pos = n[mod.a] + n[mod.d]/2 - relativeCenter;
				if(pos > 0)
					break;
			}
			// now get prev
			p = rail.getChildAt(i > 0 ? i-1 : i);
			ppos = p[mod.a] + p[mod.d]/2 - relativeCenter;
			var vp:Number = Math.abs(ppos);
			var vn:Number = Math.abs(pos);
			var dif:Number = Math.abs(vn - vp);
			if(dif < 0.025)
				return [p, ppos];
			return (vp < vn) ? [p, ppos] : [n, pos];
		}
	}
}
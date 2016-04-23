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
	 * Component is well optimized: whenever possible - updates container rather than each and every child separately.
	 * Class does not provide animation or 'next element selection' utilities. 
	 * Carousel provides only one method (<code>movementBit</code>) for propel, which accepts just one parameter (<code>delta</code>).
	 * All further and higher level features should be added separately e.g. extending this class. 
	 * <br><br>
	 * Supports gaps and allows to get "MIDDLE" child.
	 * @see #addToRail()
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
		
		public function Carusele()
		{
			super();
			gap = 0;
			railNumChildren =0;
			rail = new Sprite();
			this.addChild(rail);
			rail.addEventListener(Event.ADDED, elementAdded);
			setAxle(true);
		}
		
		protected function elementAdded(e:Event):void
		{
			railDim = rail[mod.d];
			rail[mod.a] = railDim/-2;
			rail[modA.a] = rail[modA.d]/-2;
			rearange();
			movementBit(0);
		}

		private function updateDebug():void
		{
			if(!debug) return;
			if(!dbg)
			{
				dbg = new Shape();
				this.addChild(dbg);
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
			var centerObj:DisplayObject = centerarr[0];
			var railOffset:Number =rail[mod.d]/2 + rail[mod.a];
			var objCenterOffset:Number = rail[mod.d]/2 - centerObj[mod.a];
			var objAbsoulteOffset:Number = railOffset - objCenterOffset;
			var opositeOffset:Number = rail[modA.d]/2 - centerObj[modA.a];
			setAxle(v);
			var sum:Number = 0;
			for(var i:int = 0; i < railNumChildren; i++)
			{
				firstChild = rail.getChildAt(i);
				firstChild[mod.a] = sum;
				firstChild[modA.a] = 0;
				sum += firstChild[mod.d]+GAP;
			}
			rail[modA.a] = rail[modA.d]/-2;
			rail[mod.a] = 0;
			this.movementBit(- centerObj[mod.a]+objAbsoulteOffset);
			this.updateDebug();
		}
		
		private function get railCenter():Number
		{
			return rail[mod.a] + (rail[mod.d] /2);
		}
		
		/** Returns current number elements in Carousel container*/
		public function get numRailChildren():int {	return railNumChildren }
		/** Container where all rail elements are displayed. Improper use can cause unpredictable effects */
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
		 * @param displayObject - new member of carousel
		 * @param seemles - if true, object is added at the end of carousele and no immediate movement is noticable.
		 * If false, objects are being re-aranged in order to deal with new dimensions of carousele.*/
		public function addToRail(displayObject:DisplayObject, seemles:Boolean=false):void
		{
			if(rail.contains(displayObject))
				return;
			if(!firstChild)
				firstChild = displayObject;
			lastChild = displayObject;
			lastChild[mod.a] = railDim + (railNumChildren>0?GAP:0);
			railNumChildren++;
			rail.addChild(lastChild);
		}
		/** Removes element from and rearanges rail */
		public function removeFromRail(displayObject:DisplayObject):void
		{
			if(rail.contains(displayObject))
			{
				rail.removeChild(displayObject);
				railNumChildren--;
				railDim = rail[mod.d];
				rearange();
			}
		}
		
		/** Pass delta of momentary movement (e.g. on touch move event, or animation tick update) to move
		 * elements added by <code>addToRail</code>. Children are being sorted (indices) 
		 * and not removed or added to display list.
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
			p = rail.getChildAt(i-1);
			ppos = p[mod.a] + p[mod.d]/2 - relativeCenter;
			var vp:Number = Math.abs(ppos);
			var vn:Number = Math.abs(pos);
			var dif:Number = Math.abs(vn - vp);
			if(dif < 0.025)
				return [p, ppos];
			return (vp < vn) ? [p, ppos] : [n, pos];
		}
		
		/** Removes all children, sets gap to 0*/
		public function clearRail():void
		{
			gap = 0;
			railNumChildren =0;
			rail.removeChildren();
			railNumChildren=0;
			lastChild = null;
			firstChild = null
			railDim = 0;
			rail[mod.a] = 0;
			rail[modA.a] = 0;
		}
	}
}
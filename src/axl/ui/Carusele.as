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
	/**
	 * Class provides carousel component. Ideal for scrollable lists galleries etc.
	 * Supports children of different dimensions. Can be horizontal OR vertical.
	 * Axles can be switched seamlessly (with children inside).
	 * 
	 * Children are bering distributed from most center point.
	 * Set x and/or y properties of this object exactly where you want to see center of your carousel
	 * (as carousel would be 1px wide and/or 1px high).
	 * 
	 *
	 * Supports gaps and allows to get "MIDDLE" child.
	 * Due tu huge overhead and high precision
	 * of being --in the middle-- use <code> sortEvery </code> - never set it to 0.  use <code>addToRail</code> and <code>removeFromRail</code> to get the effect
	 */
	
	import flash.display.DisplayObject;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	
	public class Carusele extends Sprite
	{
		private static const modH:Object = { a : 'x', d : 'width', p: 'pivotX', s: 'scaleX'};
		private static const modV:Object = { a : 'y', d : 'height', p: 'pivotY', s: 'scaleY'};
		
		protected var mod:Object;
		protected var modA:Object;
		protected var rail:Sprite;
		private var HOR:Boolean;
		private var VER:Boolean;
		
		protected var gap:Number;
		protected var railNumChildren:int;
		protected var firstChild:DisplayObject;
		protected var lastChild:DisplayObject;
		protected var railDim:Number=0;
		
		protected var _sortEvery:Number=200;
		private var _resetAxle:Boolean;
		private var railPivot:Number;
		private var roffset:Number;
		
		private var dbg:Shape;
		public var debug:uint=0;
		private var bug:Number=0;
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
			railPivot = railDim>>1;
			rail[mod.a] = -railPivot;
			rearange();
			movementBit(0);
		}
		
		public function get numRailChildren():int {	return railNumChildren }
		/** container where all rail elements are displayed. Improper use can cause unpredictable effects */
		public function get railElementsContainer():Sprite { return rail }

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
			setAxle(v);
			resetAxle();
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
		
		private function resetAxle():void
		{
			var sum:Number = 0;
			// was x now is y
			var offset:Number = rail[modA.a]; // prev x loc
			for(var i:int = 0; i < railNumChildren; i++)
			{
				lastChild = rail.getChildAt(i);
				lastChild[mod.a] = sum;
				lastChild[modA.a] = 0;
				sum += lastChild[mod.d]+GAP;
			}
			rail[mod.a] = rail[modA.a]; //temporary as need to be seemles
			rail[modA.a] = -rail[modA.d]/2;
		}
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
		
		public function removeFromRail(displayObject:DisplayObject):void
		{
			if(rail.contains(displayObject))
			{
				rail.removeChild(displayObject);
				railNumChildren--;
				railDim = rail[mod.d];
				railPivot = railDim>>1;
				rearange();
			}
		}
		
		private function get railCenter():Number
		{
			return rail[mod.a] + (rail[mod.d] /2);
		}
		
		/**
		 * Pass delta of momentary movement (e.g. on touch move event, or animation tick update) to move
		 * elements added by <code>addToRail</code> function  in infinite paralax mode. children are being sorted (indexes) 
		 * and not removed or added to display list. Very costful operation so use it wisely.
		 * to optimize performance set <code>sortEvery</code> property passing how many pixels of ofset is ok for instance to have  beforeo re-sorting children. By default,
		 * rail is as close to the middle (0) as possible.
		 */
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
			var sortEveryTemp:Number = _sortEvery;
			if(newRailCenterAbsolute > sortEveryTemp)
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
		
		/**
		 * rearranges rail children. use it after setting all properties, or changed axle of carusele
		 */
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
		 * <br><b>FIRST</b> element is Number of offset to center (positive or negative)
		 */
		public function getChildClosestToCenter():Array
		{
			if(rail.numChildren < 1)
				return null;
			var n:Number=rail.getChildAt(0)[mod.a];
			var an:Number=0;
			var positive:Number = (rail[mod.a] > 0) ? 1 : -1;
			var h:Number = rail[mod.d]/2;
				h +=  ((h + rail[mod.a]) * (positive ? -1 : 1));
			var i:int = 0;
			while(n <= h && ( ++i < this.numRailChildren))
			{
				firstChild = rail.getChildAt(i);
				n = firstChild[mod.a] + firstChild[mod.d]/2;
			}
			
			n += (firstChild[mod.a] * positive);
			lastChild = rail.getChildAt(i-1);
			an = h - lastChild[mod.a]  - (lastChild[mod.d]/2);
			
			return (Math.abs(an) < Math.abs(n)) ? [lastChild, an] : [firstChild, n];
		}
		
		/**
		 * Determines what offset is acceptable for <i>rail</i> to have 
		 * before paralax check.
		 * <br>Usage is ighly recomended for performance improvement. If your Carusele has
		 * 12 elements, but only three visible at the time, it should be ok to pass 5 x (element width/height +gap)
		 */
		public function get sortEvery():Number { return _sortEvery }
		public function set sortEvery(value:Number):void { _sortEvery = value }
		
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
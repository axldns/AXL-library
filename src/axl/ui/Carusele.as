package axl.ui
{	
	/**
	 * [axldns free coding 2015]
	 * 
	 * Class provides infinite paralax effect both horizontal and vertical. Supports gaps and allows to get "MIDDLE" child.
	 * Ideal for scrollable lists galleries etc. Supports children of different dimensions. Due tu huge overhead and high precision
	 * of being --in the middle-- use <code> sortEvery </code> - never set it to 0.  use <code>addToRail</code> and <code>removeFromRail</code> to get the effect
	 * <br><i>d.aleksandrowicz 2015</i>
	 */
	
	import flash.display.DisplayObject;
	import flash.display.Shape;
	import flash.display.Sprite;
	
	public class Carusele extends Sprite
	{
		private static const modH:Object = { a : 'x', d : 'width', p: 'pivotX', s: 'scaleX'};
		private static const modV:Object = { a : 'y', d : 'height', p: 'pivotY', s: 'scaleY'};
		
		protected var mod:Object;
		protected var modA:Object;
		private var rail:Sprite;
		private var HOR:Boolean;
		private var VER:Boolean;
		
		private var gap:Number;
		private var railNumChildren:int;
		private var firstChild:DisplayObject;
		private var lastChild:DisplayObject;
		private var railDim:Number=0;
		
		private var _sortEvery:Number=200;
		private var _resetAxle:Boolean;
		private var railPivot:Number;
		private var roffset:Number;
		
		private var dbg:Shape;
		private var radius:Number = 100;
		
		public var debug:Boolean;
		public function Carusele()
		{
			super();
			gap = 0;
			railNumChildren =0;
			rail = new Sprite();
			this.addChild(rail);
			this.isHORIZONTAL = false;
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
			dbg.graphics.lineStyle(1, 0x00FF00);
			dbg.graphics.drawRect(.5, .5, rail.width-1, rail.height-1);
			dbg.graphics.moveTo(0,0);
			dbg.graphics.lineTo(dbg.width, dbg.height);
			dbg.graphics.moveTo(dbg.width, 0);
			dbg.graphics.lineTo(0, dbg.height);
			dbg.x = rail.x;
			dbg.y = rail.y;
		}
		
		public function set isHORIZONTAL(v:Boolean):void
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
			resetAxle();
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
		
		public function get isHORIZONTAL():Boolean { return HOR }
		public function get isVERTICAL():Boolean { return VER }
		public function set isVERTICAL(v:Boolean):void 	{ isHORIZONTAL = !v}
		public function get GAP():Number { return  gap}
		public function set GAP(v:Number):void { gap=v, rearange()}
		
		public function addToRail(displayObject:DisplayObject, seemles:Boolean=false):void
		{
			if(!firstChild)
				firstChild = displayObject;
			if(rail.contains(displayObject))
				return;
			lastChild = displayObject;
			lastChild[mod.a] = railDim + (railNumChildren>0?GAP:0);
			rail.addChild(lastChild);
			railDim = rail[mod.d];
			railPivot = railDim>>1;
			railNumChildren++;
			if(!seemles)
				rail[mod.a] = -railPivot;
			movementBit(0);
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
			
			var lastDim:Number = lastChild[mod.d] + gap;
			var firstDim:Number  =firstChild[mod.d] + gap;
			
			var rearangeNeeded:Boolean;
			
			var nOffset:Number = railCenter + delta;
			var nOffsetA:Number = Math.abs(nOffset);
			var nra:Number = rail[mod.a] + delta;
			var sortEveryTemp:Number = _sortEvery;
			if(nOffsetA > sortEveryTemp)
			{
				if(nOffset<0)
				{
					while(nOffsetA > 0)
					{
						nOffsetA -= firstDim;
						nOffset += firstDim;
						nra += lastDim;
						firstToLast();
						lastDim = lastChild[mod.d] + gap;
						firstDim =firstChild[mod.d] + gap;
						rearangeNeeded = true;
					}
				}
				else if(nOffset>0)
				{
					while(nOffsetA > 0)
					{
						nOffsetA -= lastDim;
						nOffset -= lastDim;
						nra -= lastDim;
						lastToFirst();
						lastDim = lastChild[mod.d] + gap;
						firstDim =firstChild[mod.d] + gap;
						rearangeNeeded = true
					}
				}
			}
			
			rail[mod.a] = nra;
			if(rearangeNeeded)
				rearange();
		}
		
		private function lastToFirst():void
		{
			lastChild = rail.getChildAt(railNumChildren-1);
			rail.setChildIndex(lastChild, 0);
			lastChild = rail.getChildAt(railNumChildren-1);
		}
		
		private function firstToLast():void
		{
			firstChild = rail.getChildAt(0);
			rail.setChildIndex(firstChild, railNumChildren-1);
			firstChild = rail.getChildAt(0);
		}
		
		/**
		 * rearranges rail children. use it after setting all properties, or changed axle of carusele
		 */
		public function rearange():void
		{
			var sum:Number = 0;
			for(var i:int = 0; i < railNumChildren; i++)
			{
				lastChild = rail.getChildAt(i);
				lastChild[mod.a] = sum;
				sum += lastChild[mod.d]+GAP;
			}
		}
		
		/**
		 * returns array where 
		 * <br><b>ZERO</b> element is rail display object closest to relative middle point of rail (0)
		 * <br><b>FIRST</b> element is Number of offset to center (positive or negative)
		 */
		public function getChildClosestToCenter():Array
		{
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
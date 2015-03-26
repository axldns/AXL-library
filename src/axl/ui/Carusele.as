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
	
	import flash.geom.Rectangle;
	import starling.display.DisplayObject;
	import starling.display.Sprite;
	
	public class Carusele extends Sprite
	{
		private static const modH:Object = { a : 'x', d : 'width', p: 'pivotX', s: 'scaleX'};
		private static const modV:Object = { a : 'y', d : 'height', p: 'pivotY', s: 'scaleY'};
		
		private var rail:Sprite;
		private var HOR:Boolean;
		private var VER:Boolean;
		private var mod:Object;
		private var modA:Object;
		
		private var gap:Number;
		private var railNumChildren:int;
		private var firstChild:DisplayObject;
		private var lastChild:DisplayObject;
		private var railDim:Number=0;
		
		private var _sortEvery:Number=200;
		
		public function Carusele()
		{
			super();
			this.isHORIZONTAL = false;
			gap = 0;
			rail = new Sprite();
			railNumChildren =0;
			this.addChild(rail);
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
		}
		
		public function get isHORIZONTAL()		:Boolean 	{ return HOR }
		public function get isVERTICAL()		:Boolean 	{ return VER }
		public function set isVERTICAL(v:Boolean):void 		{ isHORIZONTAL = !v}
		public function get railBounds()		:Rectangle	{ return rail.bounds }
		public function get GAP()				:Number 	{ return  gap}
		public function set GAP(v:Number)		:void 		{ gap = v	}
		
		public function addToRail(displayObject:DisplayObject):void
		{
			if(!firstChild)
				firstChild = displayObject;
			
			lastChild = displayObject;
			lastChild[mod.a] = railDim + (railNumChildren>0?GAP:0);
			rail.addChild(lastChild);
			railNumChildren++;
			rail[mod.p] += lastChild[mod.d]>>1;
			railDim = rail[mod.d];
		}
		
		public function removeFromRail(displayObject:DisplayObject):void
		{
			if(rail.contains(displayObject))
			{
				rail[mod.p] -= displayObject[mod.d]>>1;
				rail.removeChild(displayObject);
				railNumChildren--;
				railDim = rail[mod.d];
				rearange();
			}
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
			if(railNumChildren < 2)
				return;
			var r:Number; 					// ratio delta vs rail
			var newV:Number; 				// final rail position
			var shift:Number = (delta < 0) ? -1 : 1; // determines positve or negative result of operations
			
			//delta normalization
			r = delta / railDim;
			if(Math.abs(r)>1)
				delta = railDim * (r +((r>0?Math.floor(r) : Math.ceil(r)) * shift));
			newV = rail[mod.a] + delta;
			
			if(Math.abs(newV) < _sortEvery)
			{
				rail[mod.a] = newV; // that's it!
				return;
			}
			var firstChildIndex:int=0;		// if vector is positive first is 0 last is last. if Δ is negative - oposite
			var lastChildIndex:int = railNumChildren-1;
			if(delta < 0)
			{
				firstChildIndex = railNumChildren-1;
				lastChildIndex =0;
			}
			firstChild = rail.getChildAt(firstChildIndex);
			lastChild = rail.getChildAt(lastChildIndex);
			
			//sorting indexes and summing rail offset
			while (Math.abs(newV) > _sortEvery)
			{
				newV -= (lastChild[mod.d]+gap) * shift;
				rail.setChildIndex(lastChild,firstChildIndex);
				firstChild = lastChild;
				lastChild = rail.getChildAt(lastChildIndex);
			}
			//rearrange and apply remaining
			rearange();
			rail[mod.a] = newV;
		}
		/**
		 * 
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
			var n:Number=0;
			var an:Number=0;
			var positive:Number = (rail[mod.a] > 0) ? 1 : -1;
			var h:Number = rail[mod.p] + (positive? -rail[mod.a] : rail[mod.a]) ;
			
			var i:int = 0;
			while(n < h)
				n = rail.getChildAt(++i)[mod.a];
			
			firstChild = rail.getChildAt(i);
			n += (firstChild[mod.a] * positive);
			lastChild = rail.getChildAt(i-1);
			an = h - lastChild[mod.a]  - (lastChild[mod.d]>>1);
			
			return (Math.abs(an) < Math.abs(n)) ? [lastChild, an] : [firstChild, n];
		}

		/**
		 * Determines what offset is acceptable for <i>rail</i> to have 
		 * before paralax check.
		 * <br>Usage is ighly recomended for performance improvement. If your Carusele has
		 * 12 elements, but only three visible at the time, it should be ok to pass 5 x (element width/height +gap)
		 */
		public function get sortEvery():Number { return _sortEvery }
		public function set sortEvery(value:Number):void
		{
			_sortEvery = value;
		}
		

	}
}
internal class Easings {
	private const PI_M2:Number = Math.PI*2;
	private const PI_D2:Number = Math.PI/2;
	
	public function Easings():void {}
	public const easeLinear:Function = function (t:Number, b:Number, c:Number, d:Number):Number
	{
		return c*t/d + b;
	}
	public const easeInSine:Function = function (t:Number, b:Number, c:Number, d:Number):Number
	{
		return -c * Math.cos(t/d * PI_D2) + c + b;
	}
	public const easeOutSine:Function = function (t:Number, b:Number, c:Number, d:Number):Number
	{
		return c * Math.sin(t/d * PI_D2) + b;
	}
	public const easeInOutSine:Function = function (t:Number, b:Number, c:Number, d:Number):Number
	{
		return -c/2 * (Math.cos(Math.PI*t/d) - 1) + b;
	}
	public const easeInQuint:Function = function (t:Number, b:Number, c:Number, d:Number):Number
	{
		return c*(t/=d)*t*t*t*t + b;
	}
	public const easeOutQuint:Function = function (t:Number, b:Number, c:Number, d:Number):Number
	{
		return c*((t=t/d-1)*t*t*t*t + 1) + b;
	}
	public const easeInOutQuint:Function = function (t:Number, b:Number, c:Number, d:Number):Number
	{
		if ((t/=d/2) < 1) return c/2*t*t*t*t*t + b;
		return c/2*((t-=2)*t*t*t*t + 2) + b;
	}
	public const easeInQuart:Function = function (t:Number, b:Number, c:Number, d:Number):Number
	{
		return c*(t/=d)*t*t*t + b;
	}
	public const easeOutQuart:Function = function (t:Number, b:Number, c:Number, d:Number):Number
	{
		return -c * ((t=t/d-1)*t*t*t - 1) + b;
	}
	
	public const easeInOutQuart:Function = function (t:Number, b:Number, c:Number, d:Number):Number
	{
		if ((t/=d/2) < 1) return c/2*t*t*t*t + b;
		return -c/2 * ((t-=2)*t*t*t - 2) + b;
	}
	public const easeInQuad:Function = function (t:Number, b:Number, c:Number, d:Number):Number
	{
		return c*(t/=d)*t + b;
	}
	public const easeOutQuad:Function = function (t:Number, b:Number, c:Number, d:Number):Number
	{
		return -c *(t/=d)*(t-2) + b;
	}
	public const easeInOutQuad:Function = function (t:Number, b:Number, c:Number, d:Number):Number
	{
		if ((t/=d/2) < 1) return c/2*t*t + b;
		return -c/2 * ((--t)*(t-2) - 1) + b;
	}
	public const easeInExpo:Function = function (t:Number, b:Number, c:Number, d:Number):Number
	{
		return (t==0) ? b : c * Math.pow(2, 10 * (t/d - 1)) + b;
	}
	public const easeOutExpo:Function = function (t:Number, b:Number, c:Number, d:Number):Number
	{
		return (t==d) ? b+c : c * (-Math.pow(2, -10 * t/d) + 1) + b;
	}
	public const easeInOutExpo:Function = function (t:Number, b:Number, c:Number, d:Number):Number
	{
		if (t==0) return b;
		if (t==d) return b+c;
		if ((t/=d/2) < 1) return c/2 * Math.pow(2, 10 * (t - 1)) + b;
		return c/2 * (-Math.pow(2, -10 * --t) + 2) + b;
	}
	public const easeInElastic:Function = function (t:Number, b:Number, c:Number, d:Number, a:Number=undefined, p:Number=undefined):Number
	{
		var s:Number;
		if (t==0) return b;  if ((t/=d)==1) return b+c;  if (!p) p=d*.3;
		if (!a || a < Math.abs(c)) { a=c; s=p/4; }
		else s = p/PI_M2 * Math.asin (c/a);
		return -(a*Math.pow(2,10*(t-=1)) * Math.sin( (t*d-s)*PI_M2/p )) + b;
	}
	public const easeOutElastic:Function = function (t:Number, b:Number, c:Number, d:Number, a:Number=undefined, p:Number=undefined):Number
	{
		var s:Number;
		if (t==0) return b;  if ((t/=d)==1) return b+c;  if (!p) p=d*.3;
		if (!a || a < Math.abs(c)) { a=c; s=p/4; }
		else s = p/PI_M2 * Math.asin (c/a);
		return (a*Math.pow(2,-10*t) * Math.sin( (t*d-s)*PI_M2/p ) + c + b);
	}
	public const easeInOutElastic:Function = function (t:Number, b:Number, c:Number, d:Number, a:Number=undefined, p:Number=undefined):Number
	{
		var s:Number;
		if (t==0) return b;  if ((t/=d/2)==2) return b+c;  if (!p) p=d*(.3*1.5);
		if (!a || a < Math.abs(c)) { a=c; s=p/4; }
		else s = p/PI_M2 * Math.asin (c/a);
		if (t < 1) return -.5*(a*Math.pow(2,10*(t-=1)) * Math.sin( (t*d-s)*PI_M2/p )) + b;
		return a*Math.pow(2,-10*(t-=1)) * Math.sin( (t*d-s)*PI_M2/p )*.5 + c + b;
	}
	public const easeInCircular:Function = function (t:Number, b:Number, c:Number, d:Number):Number
	{
		return -c * (Math.sqrt(1 - (t/=d)*t) - 1) + b;
	}
	public const easeOutCircular:Function = function (t:Number, b:Number, c:Number, d:Number):Number
	{
		return c * Math.sqrt(1 - (t=t/d-1)*t) + b;
	}
	public const easeInOutCircular:Function = function (t:Number, b:Number, c:Number, d:Number):Number
	{
		if ((t/=d/2) < 1) return -c/2 * (Math.sqrt(1 - t*t) - 1) + b;
		return c/2 * (Math.sqrt(1 - (t-=2)*t) + 1) + b;
	}
	public const easeInBack:Function = function (t:Number, b:Number, c:Number, d:Number, s:Number=1.70158):Number
	{
		return c*(t/=d)*t*((s+1)*t - s) + b;
	}
	public const easeOutBack:Function = function (t:Number, b:Number, c:Number, d:Number, s:Number=1.70158):Number
	{
		return c*((t=t/d-1)*t*((s+1)*t + s) + 1) + b;
	}
	public const easeInOutBack:Function = function (t:Number, b:Number, c:Number, d:Number, s:Number=1.70158):Number
	{
		if ((t/=d/2) < 1) return c/2*(t*t*(((s*=(1.525))+1)*t - s)) + b;
		return c/2*((t-=2)*t*(((s*=(1.525))+1)*t + s) + 2) + b;
	}
	public const easeInBounce:Function = function (t:Number, b:Number, c:Number, d:Number):Number
	{
		return c - easeOutBounce(d-t, 0, c, d) + b;
	}
	public const easeOutBounce:Function = function (t:Number, b:Number, c:Number, d:Number):Number
	{
		if ((t/=d) < (1/2.75)) {
			return c*(7.5625*t*t) + b;
		} else if (t < (2/2.75)) {
			return c*(7.5625*(t-=(1.5/2.75))*t + .75) + b;
		} else if (t < (2.5/2.75)) {
			return c*(7.5625*(t-=(2.25/2.75))*t + .9375) + b;
		} else {
			return c*(7.5625*(t-=(2.625/2.75))*t + .984375) + b;
		}
	}
	public const easeInOutBounce:Function = function (t:Number, b:Number, c:Number, d:Number):Number
	{
		if (t < d/2) return easeInBounce(t*2, 0, c, d) * .5 + b;
		else return  easeOutBounce(t*2-d, 0, c, d) * .5 + c*.5 + b;
	}
	public const easeInCubic:Function = function (t:Number, b:Number, c:Number, d:Number):Number
	{
		return c*(t/=d)*t*t + b;
	}
	public const easeOutCubic:Function = function (t:Number, b:Number, c:Number, d:Number):Number
	{
		return c*((t=t/d-1)*t*t + 1) + b;
	}
	public const easeInOutCubic:Function = function (t:Number, b:Number, c:Number, d:Number):Number
	{
		if ((t/=d/2) < 1) return c/2*t*t*t + b;
		return c/2*((t-=2)*t*t + 2) + b;
	}
}
package axl.utils 
{
	/**
	* [axldns free coding 2014]
	* 
	* Custom Animation Engine. Performance wise - basic tests show that it is super comparable to Starling juggler tween. 
	*  Obcoiusly abstraction level allows to animate any sort of objects.
	* One class engine makes it very handy as it gots most of everyday use features as well as easly trackable. 
	* Not every setting configurations are working as expexted though, requries some revision.
	*/	
	import flash.display.Stage;
	import flash.events.Event;
	
	public class Easing
	{
		private static var onFrameFunctions:Vector.<Function> = new Vector.<Function>();
		private static var proceeding:Vector.<Object> = new Vector.<Object>();
		private static var STG:Stage;
		private static var easings:Easings = new Easings();
		/** reference to common easing functions: linear, in^/out^/back^  ^sine/^qubic/^quart/^quint/^elastic/^circular/^expo*/
		public static function get func():Easings { return easings }

		private static var fi:int;
		
		public static  function init(stage:Stage):void
		{
			STG = stage;
			STG.addEventListener(Event.ENTER_FRAME, ENTER_FRAME);
		}
			
		public static function animate(o:Object, seconds:Number, props:Object, onComplete:Function=null, onCompleteArgs:Array=null, easingType:Function=null,loops:Boolean=false,includeTargetVal:Boolean=false,incremental:Boolean=false,onUpdate:Function=null,onUpdateArgs:Array=null):void
		{
			if(!STG)
				throw new Error("EASING: Stage not found. Make sure you pass actual stage in Easing.init method before animating");
			var totalFrames:int = Math.ceil(STG.frameRate * seconds);
			var easingFunction:Function = (easingType || easings.easeOutQuad);
			
			var eased:Object = {};
			var frameIndex:int;
			var nothingTOanimate:Boolean = true;
			var prev:Number=0;
			var hlp:Number;
			var property:String = "";
			// pre-calculate values
			for(property in props)
			{
				if(o.hasOwnProperty(property))
				{
					nothingTOanimate = false;
					eased[property] = new Vector.<Number>();
					frameIndex=0;
					if(includeTargetVal)
						while(frameIndex++ < totalFrames)
							eased[property].push(easingFunction(frameIndex, o[property], props[property], totalFrames));	
					else if(incremental)
					{
						while(frameIndex++ < totalFrames)
						{
							hlp =easingFunction(frameIndex,0, props[property], totalFrames);
							eased[property].push(hlp - prev);
							prev = hlp;
						}
					}
					else
						while(frameIndex++ < totalFrames)
							eased[property].push(easingFunction(frameIndex,o[property], props[property] - o[property], totalFrames));	
				}
			}
			if(nothingTOanimate)
			{
				if(onComplete is Function)
					onComplete.apply(null, onCompleteArgs);
				return;
			}
				
			proceeding.push({ t : o, f : loop2, oca: onCompleteArgs });
			onFrameFunction(proceeding[proceeding.length-1].f, true);
			frameIndex = 0;
			function loop2(breakNow:Boolean=false):void
			{
				if(breakNow)
				{
					end(frameIndex);
					return;
				}
				if(!(frameIndex < totalFrames))
				{
					if(loops)
						frameIndex  = 0;
					else
					{
						end(-1);
						return;
					}
				}
				if(incremental)
					for(property in eased)
						o[property] += eased[property][frameIndex];
				else
					for(property in eased)
						o[property] = eased[property][frameIndex];
				if(onUpdate is Function)
					onUpdate.apply(null, onUpdateArgs);
					
				frameIndex++;
				function end(ef:int):void
				{
					onFrameFunction(loop2, false);
					for(var i:int = 0; i < proceeding.length; i++)
					{
						if(proceeding[i].t == o)
						{
							proceeding[i].t = null;
							proceeding[i].f = null;
							proceeding.splice(i,1);
						}
					}
					if(ef > 0)
						for(property in eased)
							o[property] = eased[property].pop();
					for(property in eased)
					{
						eased[property].length = 0;
						eased[property] = null;
					}
					property=null;
					props=null;
					eased = null;
					
					if(onComplete is Function)
						onComplete.apply(null, onCompleteArgs);
				}
			}
		}
		
		public static function killOf(target:Object, completeImmediately:Boolean=false):Boolean
		{
			var i:int = proceeding.length;
			while(i-->0)
			{
				if(proceeding[i].t === target)
				{
					if(completeImmediately)
						proceeding[i].f(true);
					else
					{
						onFrameFunction(proceeding[i].f, false);
						proceeding[i].t = null;
						proceeding[i].f = null;
						proceeding.splice(i,1);
					}
					return true;
				}
			}
			return false;
		}
		
		public static function contains(target:Object):Boolean
		{
			var i:int = proceeding.length;
			while(i-->0)
				if(proceeding[i].t === target)
					return true;
			return false;
		}
		
		public static function onFrameFunction(f:Function, addTRUEremoveFALSE:Boolean):void
		{
			var i:int = onFrameFunctions.indexOf(f);
			if(i < 0)
				addTRUEremoveFALSE ? onFrameFunctions.push(f) : null;
			else
				addTRUEremoveFALSE ? null : onFrameFunctions.splice(i,1);
		}
		
		protected static function ENTER_FRAME(event:Event):void
		{
			fi = -1;
			while(++fi < onFrameFunctions.length)
				onFrameFunctions[fi]();
		}
	}
}

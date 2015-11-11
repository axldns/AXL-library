/**
 *
 * AXL Library
 * Copyright 2014-2015 Denis Aleksandrowicz. All Rights Reserved.
 *
 * This program is free software. You can redistribute and/or modify it
 * in accordance with the terms of the accompanying license agreement.
 *
 */
package axl.utils
{
	public class Easings {
		private const PI_M2:Number = Math.PI*2;
		private const PI_D2:Number = Math.PI/2;
		
		public function Easings():void {}
		
		/** LUT Optimized sin/cos */
		private function cos3(angle:Number):Number { return sin3(PI_D2 - angle) }
		private function sin3(angle:Number):Number
		{
			var ax:Number = 0.15915494309189533576888376337251*angle;
			var x:Number = ax - (ax>>0);
			var s:Number;
			if(ax<0)
				x += 1.0;
			if(x >= .5)
			{
				x = 2.0*x - 1.5;
				s = -3.6419789056581784278305460054775;
			}
			else
			{
				x = 2.0*x - 0.5;
				s = 3.6419789056581784278305460054775;
			}
			x*=x;
			return s*(x - .25)*(x - 1.098304);  
		}
		public const easeLinear:Function = function (t:Number, b:Number, c:Number, d:Number):Number
		{
			return c*t/d + b;
		}
		public const easeInSine:Function = function (t:Number, b:Number, c:Number, d:Number):Number
		{
			return -c * cos3(t/d * PI_D2) + c + b;
		}
		public const easeOutSine:Function = function (t:Number, b:Number, c:Number, d:Number):Number
		{
			return c * sin3(t/d * PI_D2) + b;
		}
		public const easeInOutSine:Function = function (t:Number, b:Number, c:Number, d:Number):Number
		{
			return -c/2 * (cos3(Math.PI*t/d) - 1) + b;
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
			return ((t/=d/2) < 1) ? (c/2*t*t*t*t*t + b) : (c/2*((t-=2)*t*t*t*t + 2) + b);
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
			return ((t/=d/2) < 1)  ?  (c/2*t*t*t*t + b) : (-c/2 * ((t-=2)*t*t*t - 2) + b);
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
			return ((t/=d/2) < 1) ? (c/2*t*t + b) : (-c/2 * ((--t)*(t-2) - 1) + b);
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
		public const easeInElastic:Function = function (t:Number, b:Number, c:Number, d:Number, a:Number=1, p:Number=1):Number
		{
			var s:Number;
			if (t==0) return b;  if ((t/=d)==1) return b+c;  if (!p) p=d*.3;
			if (!a || a < Math.abs(c)) { a=c; s=p/4; }
			else s = p/PI_M2 * Math.asin (c/a);
			return -(a*Math.pow(2,10*(t-=1)) * sin3( (t*d-s)*PI_M2/p )) + b;
		}
		public const easeOutElastic:Function = function (t:Number, b:Number, c:Number, d:Number, a:Number=1, p:Number=1):Number
		{
			var s:Number;
			if (t==0) return b;  if ((t/=d)==1) return b+c;  if (!p) p=d*.3;
			if (!a || a < Math.abs(c)) { a=c; s=p/4; }
			else s = p/PI_M2 * Math.asin (c/a);
			return (a*Math.pow(2,-10*t) * sin3( (t*d-s)*PI_M2/p ) + c + b);
		}
		public const easeInOutElastic:Function = function (t:Number, b:Number, c:Number, d:Number, a:Number=1, p:Number=1):Number
		{
			var s:Number;
			if (t==0) return b;  if ((t/=d/2)==2) return b+c;  if (!p) p=d*(.3*1.5);
			if (!a || a < Math.abs(c)) { a=c; s=p/4; }
			else s = p/PI_M2 * Math.asin (c/a);
			if (t < 1) return -.5*(a*Math.pow(2,10*(t-=1)) * sin3( (t*d-s)*PI_M2/p )) + b;
			return a*Math.pow(2,-10*(t-=1)) * sin3( (t*d-s)*PI_M2/p )*.5 + c + b;
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
			return ((t/=d/2) < 1) ? (-c/2 * (Math.sqrt(1 - t*t) - 1) + b) : (c/2 * (Math.sqrt(1 - (t-=2)*t) + 1) + b);
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
			return (t < d/2) ? (easeInBounce(t*2, 0, c, d) * .5 + b) :  (easeOutBounce(t*2-d, 0, c, d) * .5 + c*.5 + b);
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
			return ((t/=d/2) < 1) ? (c/2*t*t*t + b) : (c/2*((t-=2)*t*t + 2) + b);
		}
	}
}
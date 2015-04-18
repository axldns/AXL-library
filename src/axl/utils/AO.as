internal class Easings {
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
package axl.utils
{
	import flash.display.Stage;
	import flash.events.Event;
	import flash.utils.getTimer;

	public class AO {
		
		private static var STG:Stage;
		private static var curFrame:int;
		private static var frameTime:int;
		private static var prevFrame:int;
		
		private static var easings:Easings = new Easings();
		public static function get easing():Easings { return easings } 
		private static var animObjects:Vector.<AO> = new Vector.<AO>();
		private static var numObjects:int=0;
		
		private var propNames:Vector.<String>;
		private var propStartValues:Vector.<Number>;
		private var propEndValues:Vector.<Number>;
		private var propDifferences:Vector.<Number>;
		private var eased:Vector.<Vector.<Number>>;
		private var remains:Vector.<Number>;
		private var prevs:Vector.<Number>;
		
		private var numProperties:int=0
		private var duration:int=0;
		private var passedTotal:int=0;
		private var passedRelative:int=0;
		private var direction:int=1;
		private var cur:Number=0;
		public var cycles:int=1;
		
		public var yoyo:Boolean;
		public var subject:Object;
		public var easing:Function;
		
		public var onUpdateArgs:Array;
		public var onYoyoHalfArgs:Array;
		public var onCycleArgs:Array;
		public var onCompleteArgs:Array;
		
		public var onUpdate:Function;
		public var onYoyoHalf:Function;
		public var onCycle:Function;
		public var onComplete:Function;
		
		private var updateFunction:Function;
		private var getValue:Function;
		
		private var FPS:int;
		private var seconds:Number;
		private var incremental:Boolean;
		private var frameBased:Boolean;
		private var id:int;
		
		public function AO(target:Object, seconds:Number, props:Object, easingFunction:Function, 
						   incremental:Boolean,frameBased:Boolean) {
			if(STG == null)
				throw new Error("[AO]Stage not set up!");
			this.subject = target;
			this.seconds = seconds;
			this.easing = easingFunction;
			this.incremental = incremental;
			this.frameBased = frameBased;
			
			propNames= new Vector.<String>();
			propStartValues = new Vector.<Number>();
			propEndValues = new Vector.<Number>();
			propDifferences = new Vector.<Number>();
			
			//common
			for(var s:String in props)
			{
				if(subject.hasOwnProperty(s) && !isNaN(subject[s]) && !isNaN(props[s]))
					propNames[numProperties++] = s;
				else if(this.hasOwnProperty(s))
					this[s] = props[s];
				else throw new ArgumentError("[AO] Invalid property or value: '"+s+"'");  
			}
			
			var i:int;
			if(incremental)
			{
				prevs = new Vector.<Number>();
				remains = new Vector.<Number>();
				updateFunction = updateIncremental
				for(i=0; i<numProperties;i++)
				{
					propDifferences[i] =props[propNames[i]];
					propStartValues[i] = subject[propNames[i]];
					propEndValues[i] = propStartValues[i] + propDifferences[i];
					remains[i] = propDifferences[i];
					prevs[i] = propStartValues[i];
				}
			}
			else
			{
				updateFunction = updateAbsolute;
				for(i=0; i<numProperties;i++)
				{
					propStartValues[i] = subject[propNames[i]];
					propEndValues[i] = props[propNames[i]];
					propDifferences[i] = props[propNames[i]] - subject[propNames[i]];
				}
			}
			
			if(frameBased)
				prepareFrameBased();
			else
				prepareTimeBased();
			
			id = getTimer() + numObjects;
			AO.animObjects[numObjects++] = this;
		}
		
		// ----------------------------------------- PREPARE ----------------------------------- //
		//time - values are being calculated at runtime, every frame
		private function prepareTimeBased():void {
			duration  =  (seconds * 1000); 
			getValue = getValueLive;
		}
		//frame	- values are being pre-calculated before animation
		private function prepareFrameBased():void
		{
			duration = Math.ceil(STG.frameRate * seconds);
			getValue = getValueEased;
			eased = new Vector.<Vector.<Number>>();
			var i:int, j:int;
			for(i=0;i<numProperties;i++)
			{
				eased[i] = new Vector.<Number>();
				for(j=0; j < duration;j++) 
					eased[i][j] = easing(j, propStartValues[i], propDifferences[i], duration);
			}
		}
		// ----------------------------------------- UPDATE ------------------------- //
		
		public function tick(milsecs:int):void
		{
			passedTotal += frameBased ? 1 : milsecs;
			passedRelative = (direction < 0) ? (duration - passedTotal) : passedTotal;
			if(passedTotal >= duration) 
			{
				passedTotal = duration;
				passedDuration();
			}
			else
			{
				updateFunction();
				if(onUpdate is Function)
					onUpdate.apply(null, onUpdateArgs);
			}
		}
				
		//absolute
		private function updateAbsolute():void
		{
			for(var i:int=0;i<numProperties;i++)
				subject[propNames[i]] = getValue(i);
		}
		
		//inctemental
		private function updateIncremental():void
		{
			for(var i:int=0;i<numProperties;i++)
			{
				cur = getValue(i);
				var add:Number = (cur - prevs[i]);
				subject[propNames[i]] += (cur - prevs[i]);
				remains[i] += (-add * direction);
				prevs[i] = cur;
			}
		}
		
		//common
		private function getValueEased(i:int):Number
		{
			return eased[i][passedRelative];
		}
		private function getValueLive(i:int):Number
		{
			return  easing(passedRelative, propStartValues[i], propDifferences[i], duration);
		}
		
		private function passedDuration():void
		{
			trace('('+id+')'+state);
			var i:int
			for(i=0;i<numProperties;i++)
				trace('('+id+')'+propNames[i], ':', subject[propNames[i]].toFixed(20))
			equalize();
			if(onUpdate is Function)
				onUpdate.apply(null, onUpdateArgs);
			for(i=0;i<numProperties;i++)
				trace('('+id+')'+propNames[i], ':', subject[propNames[i]].toFixed(20))
			passedTotal = 0;
			resolveContinuation();
		}
		
		private function equalize():void
		{
			U.log('('+id+')'+'---------equalize--------');
			if(!incremental) 
				if(yoyo)
					if(direction > 0) 
						applyValues(propEndValues); 	// | > > > > > > [HERE]|
					else				
						applyValues(propStartValues);	// |[HERE] < < < < < < |
				else
					applyValues(propEndValues);
			else 		
				applyRemainings();
		}
		/** this is for incrementals only **/
		private function applyRemainings():void
		{
			for(var i:int=0;i<numProperties;i++)
			{
				U.log('r', subject[propNames[i]],propNames[i], ':', remains[i] * direction);
				subject[propNames[i]] += remains[i] * direction;
				remains[i] = propDifferences[i];
			}
			if(!yoyo || (yoyo && direction < 0))
				for(i=0; i < numProperties; i++)
					prevs[i] = propStartValues[i];
			else
				for(i=0; i < numProperties; i++)
					prevs[i] = propEndValues[i];
		}
		
		private function applyValues(v:Vector.<Number>):void
		{
			for(var i:int=0;i<numProperties;i++)
				subject[propNames[i]] = v[i];
		}
		
		private function resolveContinuation():void
		{
			U.log("------resolveContinuation----------");
			if(yoyo)
			{
				if(direction > 0) // FIRST HALF  | > > > > > > > [HERE]|
					direction = -1;
				else
				{
					direction = 1;
					completeYoyo();
					cycled();
				}
			} 
			else cycled();
		}
		
		private function completeYoyo():void
		{
			if(onYoyoHalf is Function)
				onYoyoHalf.apply(null, onYoyoHalfArgs);
		}
		
		private function cycled():void
		{
			--cycles;
			if(onCycle is Function) 
				onCycle.apply(null, onCycleArgs);
			if(cycles == 0)
				finish(true);
		}
		
		//-------------------- controll ------------------//
		private function finish(dispatchComplete:Boolean):void { 
			U.log('[Easing][finish]');
			destroy(dispatchComplete);
		}
		public function finishEarly(completeImmediately:Boolean):Boolean
		{
			U.log('[Easing][finishEarly]',completeImmediately);
			if(completeImmediately)
			{
				equalize();
				if(yoyo && (direction > 0))
				{
					direction = -1;
					equalize();
				}
				finish(true);
			}
			else finish(false);
			return true
		}
		
		public function destroy(dispCompl:Boolean):void
		{
			var i:int = animObjects.indexOf(this);
			if(i>-1) 
			{
				animObjects.splice(i,1);
				numObjects--;
			}
			if(dispCompl && (onComplete != null))
				onComplete.apply(null, onCompleteArgs);
		}
		
		public static function killOff(target:Object, completeImmediately:Boolean=false):Boolean
		{
			U.log('[Easing][killOff]', target);
			var i:int = numObjects;
			if(target is AO)
				for(i= 0; i < numObjects;i++)
					if(animObjects[i] == target)
						animObjects[i--].finishEarly(completeImmediately);
			if(!(target is AO))
			{	U.log('[Easing][killOff][nonAO]',numObjects);
				for(i = 0; i < numObjects;i++)
					if(animObjects[i].subject === target)
						animObjects[i--].finishEarly(completeImmediately);
			}
			return false;
		}
		
		public static function contains(target:Object):Boolean
		{
			var i:int = numObjects;
			if(target is AO)
				while(i-->0)
					if(animObjects[i] == target)
						return true;
			if(!(target is AO))
				while(i-->0)
					if(animObjects[i].subject === target)
						return true;
			return false;
		}
		
		public static function broadcastFrame(frameTime:int):void
		{
			for(var i:int = 0; i < numObjects;i++)
				animObjects[i].tick(frameTime);
		}
		
		private function get state():String
		{
			var s:String ='\n---------------------';
			s += String('\nincremental: ' + incremental);
			s += String('\nframeBased: ' + frameBased);
			s += String('\ncycles: ' + cycles);
			s += String('\nyoyo: ' + yoyo);
			s += String('\npassedTotal: ' + passedTotal);
			s += String('\nduration: ' + duration);
			s += '\ndirection: ' + direction;
			s += '\n---------------------';
			return s;
		}
		
		public static function set stage(v:Stage):void
		{
			if(STG != null) 
				STG.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			STG = v;
			if(STG != null) 
				STG.addEventListener(Event.ENTER_FRAME, onEnterFrame);
		}
		
		protected static function onEnterFrame(event:Event):void
		{
			curFrame = getTimer();
			frameTime = curFrame - prevFrame;
			prevFrame = curFrame;
			broadcastFrame(frameTime);
		}
		
		public static function animate(o:Object, seconds:Number, props:Object, onComplete:Function=null, cycles:int=1,yoyo:Boolean=false,
											   easingType:Function=null, incremental:Boolean=false,frameBased:Boolean=true):void
		{
			var easingFunction:Function = (easingType || easings.easeOutQuad);
			if(STG == null)
				throw new Error("[AO]Stage not set up!");
			var ao:AO = new AO(o, seconds, props,easingFunction, incremental,frameBased);
			ao.cycles = cycles;
			ao.yoyo = yoyo;
			ao.onComplete = onComplete;
		}
	}
}
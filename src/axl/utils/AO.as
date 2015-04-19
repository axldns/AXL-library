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
		//general
		private static var STG:Stage;
		private static var curFrame:int;
		private static var frameTime:int;
		private static var prevFrame:int;
		
		private static var animObjects:Vector.<AO> = new Vector.<AO>();
		private static var easings:Easings = new Easings();
		private static var defaultEasing:Function = easings.easeOutQuad;
		private static var numObjects:int=0;
		
		//internal
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
	
		private var updateFunction:Function;
		private var getValue:Function;
		private var isPlaying:Boolean;
		private var isSetup:Boolean;
		private var id:int;
		
		// applying anytime
		public var yoyo:Boolean=false;
		public var cycles:int=1;
		public var subject:Object;
		
		public var onUpdateArgs:Array;
		public var onYoyoHalfArgs:Array;
		public var onCycleArgs:Array;
		public var onCompleteArgs:Array;
		
		public var onUpdate:Function;
		public var onYoyoHalf:Function;
		public var onCycle:Function;
		public var onComplete:Function;
		public var destroyOnComplete:Boolean = true;
		
		// applying only before start
		private var uIncremental:Boolean=false;
		private var uFrameBased:Boolean=true;
		private var uPrecalculateFrameValues:Boolean=true;
		private var uProps:Object;
		private var uSeconds:Number;
		private var uEasing:Function = defaultEasing;
		
		// live copy 
		private var incremental:Boolean=false;
		private var frameBased:Boolean=true;
		private var precalculateFrameValues:Boolean;
		private var props:Object;
		private var easing:Function;
		
		public function destroy(executeOnComplete:Boolean=false):void
		{
			U.log('[AO] destroy');
			removeFromPool();
			numProperties = duration = passedTotal = passedRelative = cur = uSeconds = 0;
			propStartValues = propEndValues = propDifferences = remains =  prevs = null;
			propNames = null;
			eased = null;
			direction = cycles = 1;
			subject = props = uProps = null;
			onUpdateArgs = onYoyoHalfArgs = onCycleArgs = null;
			updateFunction = getValue = easing = uEasing = onUpdate = onYoyoHalf = onCycle = null;
			
			if(executeOnComplete && (onComplete != null))
				onComplete.apply(null, onCompleteArgs);
			
			onCompleteArgs = null;
			onComplete = null;
		}
		
		public function AO(subject:Object, seconds:Number, properties:Object) {
			if(STG == null)
				throw new Error("[AO]Stage not set up!");
			uSeconds = seconds;
			uProps = properties;
			this.subject = subject;
		}
		
		private function setUp():void
		{
			U.log('[AO][setup]');
			//common
			prepareCommon();
			if(incremental) prepareIncremental();
			else prepareAbsolute();
			
			if(frameBased) prepareFrameBased();
			else prepareTimeBased();
			isSetup = true;
		}
		
		private function prepareCommon():void
		{
			if(propNames) propNames.length = 0; else propNames = new Vector.<String>();
			if(propStartValues) propStartValues.length = 0; else propStartValues = new Vector.<Number>();
			if(propEndValues) propEndValues.length = 0; else propEndValues = new Vector.<Number>();
			if(propDifferences) propDifferences.length = 0; else propDifferences = new Vector.<Number>();
			
			numProperties  = duration = passedTotal = passedRelative = cur = 0;
			
			
			props = uProps;
			easing = uEasing || defaultEasing;
			precalculateFrameValues = uPrecalculateFrameValues;
			frameBased = uFrameBased;
			incremental = uIncremental;
			
			for(var s:String in props)
			{
				if(subject.hasOwnProperty(s) && !isNaN(subject[s]) && !isNaN(props[s]))
					propNames[numProperties++] = s;
				else if(this.hasOwnProperty(s))
					this[s] = props[s];
				else throw new ArgumentError("[AO] Invalid property or value: '"+s+"'");  
			}
			
			id = getTimer() + numObjects;
		}
		
		// ----------------------------------------- PREPARE ----------------------------------- //
		private function prepareIncremental():void
		{
			if(prevs) prevs.length = 0; else prevs = new Vector.<Number>();
			if(remains) remains.length = 0; else remains = new Vector.<Number>();
			updateFunction = updateIncremental;
			for(var i:int=0; i<numProperties;i++)
			{
				propDifferences[i] = props[propNames[i]];
				propStartValues[i] = subject[propNames[i]];
				propEndValues[i] = propStartValues[i] + propDifferences[i];
				remains[i] = propDifferences[i];
				prevs[i] = propStartValues[i];
			}
		}
		
		private function prepareAbsolute():void
		{
			updateFunction = updateAbsolute;
			for(var i:int=0; i<numProperties;i++)
			{
				propStartValues[i] = subject[propNames[i]];
				propEndValues[i] = props[propNames[i]];
				propDifferences[i] = props[propNames[i]] - subject[propNames[i]];
			}
		}
		
		private function prepareTimeBased():void {
			duration  =  (uSeconds * 1000); 
			getValue = getValueLive;
		}
		private function prepareFrameBased():void
		{
			duration = Math.ceil(STG.frameRate * uSeconds) // no frames
			
			if(!precalculateFrameValues)
				getValue = getValueLive;
			else 
			{
				getValue = getValueEased;
				eased = new Vector.<Vector.<Number>>(numProperties,true);
				var i:int, j:int;
				for(i=0;i<numProperties;i++)
				{
					eased[i] = new Vector.<Number>(duration,true);
					for(j=0; j < duration;j++) 
						eased[i][j] = easing(j, propStartValues[i], propDifferences[i], duration);
				}
			}
		}
		// ----------------------------------------- UPDATE ------------------------- //
		protected function tick(milsecs:int):void
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
				subject[propNames[i]] += add;
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
			return easing(passedRelative, propStartValues[i], propDifferences[i], duration);
		}
		
		private function passedDuration():void
		{
			trace('('+id+')');
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
			U.log('('+id+')'+'---------equalize--------', direction);
			if(!incremental) 
				if(direction > 0) 
					applyValues(propEndValues); 	// | > > > > > > [HERE]|
				else				
					applyValues(propStartValues);	// |[HERE] < < < < < < |
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
		/** this is for absolutes only **/
		private function applyValues(v:Vector.<Number>):void
		{
			trace('applying values', v == this.propStartValues  ? ' start ' : ' end');
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
			if(destroyOnComplete)
				destroy(dispatchComplete);
			else
			{
				pause();
				if(onComplete != null)
					onComplete.apply(null, onCompleteArgs);
			}
		}
		
		private function gotoEnd():void
		{
			equalize();
			if(yoyo && (direction > 0))
			{
				direction = -1;
				equalize();
			}
			direction = -1;
			passedTotal = duration;
		}
		
		private function gotoStart():void
		{
			equalize();
			if(direction > 0)
			{
				direction = -1;
				equalize();
			}
			direction = 1;
			passedTotal = 0;
		}
		
		private function removeFromPool():void
		{
			var i:int = animObjects.indexOf(this);
			if(i>-1) 
			{
				animObjects.splice(i,1);
				numObjects--;
				isPlaying = false;
			}
		}
		
		// ---------------------------------- public instance API----------------------------------------------- //
		public function get isAnimating():Boolean { return isPlaying }
		public function start():void
		{
			U.log('[AO][Start]',id);
			if(!isPlaying)
			{
				AO.animObjects[numObjects++] = this;
				isPlaying = true;
				if(!isSetup)
					setUp();
			}
		}
		public function resume():void { start() };
		public function pause():void { removeFromPool() };
		/** @param goToDirection: negative - start position, 0 - stays still, positive - end position */
		public function stop(goToDirection:int, readNchanges:Boolean=false):void
		{
			U.log('[AO][Stop]',id);
			removeFromPool();
			if(goToDirection > 0) gotoEnd();
			else if(goToDirection < 0) gotoStart();
			isSetup = !readNchanges;
		}
		public function restart(readNchanges:Boolean=false):void
		{
			stop(-1,readNchanges);
			start();
		}
		public function finishEarly(completeImmediately:Boolean):void
		{
			U.log('[Easing][finishEarly]',completeImmediately);
			if(completeImmediately)
			{
				gotoEnd();
				finish(true);
			}
			else finish(false);
		}
		
		// changes that require stop and re-read;
		public function get nIncremental():Boolean { return incremental }
		public function set nIncremental(v:Boolean):void { uIncremental = v }
		
		public function get nFrameBased():Boolean { return frameBased }
		public function set nFrameBased(v:Boolean):void { uFrameBased = v }
		
		public function get nPrecalculateFrameValues():Boolean { return precalculateFrameValues }
		public function set nPrecalculateFrameValues(v:Boolean):void {  uPrecalculateFrameValues = v }
		
		public function get nProperties():Object { return props }
		public function set nProperties(v:Object):void { uProps = v }
		
		public function get nSeconds():Number { return uSeconds }
		public function set nSeconds(v:Number):void { uSeconds = v }
		
		public function get nEasing():Function { return easing }
		public function set nEasing(v:Function):void { uEasing = v }
		
		// -----------------------  PUBLIC STATIC ------------------- //
		public static function get easing():Easings { return easings };
		public static function killOff(target:Object, completeImmediately:Boolean=false):void
		{
			U.log('[Easing][killOff]', target);
			var i:int = numObjects;
			if(target is AO)
				for(i= 0; i < numObjects;i++)
					if(animObjects[i] == target)
						animObjects[i--].finishEarly(completeImmediately);
			if(!(target is AO))
				for(i = 0; i < numObjects;i++)
					if(animObjects[i].subject === target)
						animObjects[i--].finishEarly(completeImmediately);
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
		
		public static function animate(subject:Object, seconds:Number, props:Object, onComplete:Function=null, cycles:int=1,yoyo:Boolean=false,
											   easingType:Function=null, incremental:Boolean=false,frameBased:Boolean=true):AO
		{
			if(STG == null)
				throw new Error("[AO]Stage not set up!");
			var ao:AO = new AO(subject, seconds, props);
			ao.onComplete = onComplete || ao.onComplete;
			ao.cycles = cycles;
			ao.yoyo = yoyo;
			ao.nEasing = easingType;
			ao.nIncremental = incremental;
			ao.nFrameBased = frameBased;
			ao.start();
			return ao;
		}
	}
}
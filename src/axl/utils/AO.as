/**
 *
 * AXL Library
 * Copyright 2014-2016 Denis Aleksandrowicz. All Rights Reserved.
 *
 * This program is free software. You can redistribute and/or modify it
 * in accordance with the terms of the accompanying license agreement.
 *
 */
package axl.utils
{
	import flash.display.Shape;
	import flash.events.Event;
	import flash.utils.getTimer;

	/** <h3>Tweening engine</h3>
	 * Allows to animate any numeric property of any object within given time.<br>
	 * Animations can be frame-based or time-based. Values can be updated "absolutely" or "incrementally".
	 * Supports:
	 * <ul>
	 * <li>delay</li>
	 * <li>cycles</li>
	 * <li>intervals</li>
	 * <li>yoyo</li>
	 * <li>yoyo delay</li>
	 * <li>live timeScale</li>
	 * <li>callbacks and arguments for callbacks (onStart, onUpdate, onCycle, onYoyoHalf, onComplete)</li>
	 * <li>pause, resume, restart</li>
	 * <li>stop with go to start/end</li>
	 * <li>pre-defined and custom easing functions</li>
	 * <li>destruction or re-usage instances</li>
	 * <li>dispatching fake frames</li>
	 * <li>static method for creating one off animations - self disposing instances</li>
	 * <li>static method for killing instances by target</li>
	 * </ul>
	 * Well optimized: 4 properties on 2500 objects at 60 FPS */
	public class AO {
		//general
		public static const version:String = '1.0';
		private static var prevFrame:int;
		
		private static var animObjects:Vector.<AO> = new Vector.<AO>();
		private static var allInstances:Vector.<AO> = new Vector.<AO>();
		private static var easings:Easings = new Easings();

		private static var defaultEasing:Function = easings.easeOutQuad;
		private static var numObjects:int=0;
		private static var numInstances:int = 0;
		private static var ticker:Shape = new Shape();
		ticker.addEventListener("enterFrame", onEnterFrame);
		
		//internal
		private var propNames:Vector.<String>;
		private var propStartValues:Vector.<Number>;
		private var propEndValues:Vector.<Number>;
		private var propDifferences:Vector.<Number>;
		private var incSum:Vector.<Number>;
		private var prevs:Vector.<Number>;
		
		private var numProperties:int=0
		private var duration:int=0;
		private var passedTotal:Number=0;
		private var passedRelative:Number=0;
		private var direction:int=1;
		//private var cur:Number=0;
		
		private var updateFunction:Function;
		private var isPlaying:Boolean;
		private var isSetup:Boolean;
		
		// applying anytime
		/** Indicates if animation is going to be played in reverse after reaching standard destination points.<br>
		 * yoyo doubles the initial time of animation and extends length of <code>cycle</code>. Executes <code>onYoyoHalf</code> (if defined) 
		 * on reaching original values (before going back). Reversed animation is played after each "half cycle" rather than after all cycles.<br>
		 * <br>This property can be applied any time during animation and an effect is immediate.
		 * @default false
		 * @see #cycles */
		public var yoyo:Boolean=false;
		/** Target of an animation. This can be DisplayObject but also can be anything else e.g. volume of sound object, proxy object.
		 *  Requirement is that <code>subject</code> owns all properties to animate passed in <code>props</code> parameter.
		 * Can be changed during animation. */
		public var subject:Object;
		/** Determines how many times entire animation sequence (incl. cycles and yoyo's) is going to be executed if <code>interval</code> is set 
		 * @default 1 @see #interval @see #yoyo @see #cycles */
		public var intervalRepetitions:int=1;
		/** When animation is about to start (e.g delayed or paused) <code>onStart</code> callback  can be fired. 
		 * This vairable can hold an array of arguments for this callback. @see #onStart() */
		public var onStartArgs:Array;
		/** When animation is in progress, after every update on animation target it can fire <code>onUpdate</code> callback
		 * (passed in <i>properties</i> object or set on AO instance). This vairable can hold an array of arguments for that callback. @see #onUpdate() */
		public var onUpdateArgs:Array;
		/** When animation is in progress and <code>yoyo=true</code>, every time object reaches destination values (before reversing to start values),
		 *  <code>onYoyoHalf</code> callback can be fired (passed in <i>properties</i> object or set on AO instance). This vairable can hold
		 *  an array of arguments for that callback. @see #yoyo @see #onYoyoHalf() */
		public var onYoyoHalfArgs:Array;
		/** Animation can be repeated number of times, defined by <code>cycles</code>. Each time one cycle is completed, <code>onCycle</code> callback
		 * (passed in <i>properties</i> object or set on AO instance) can be fired. 
		 * This variable can hold an array of arguments for that callback. @see #onCycle() */
		public var onCycleArgs:Array;
		/** Once animation is complete, <code>onComplete</code> callback can be fired. This variable can hold an array of arguments for that
		 * callback. @see #onComplete() */
		public var onCompleteArgs:Array;
		/** Once animation is completed (all yoyo, all cycles) the sequence can be repeated if <code>interval</code> is set. This can fire 
		 * <code>onInterval</code> callback. This property can hold an array of arguments for that callback.
		 * @see #interval @see #onInterval */
		public var onIntervalArgs:Array;
		/** Callback to fire when animation is about to start (e.g. delayed or paused). Can be set on instance or passed in animation properties object.
		 * @see #onStartArgs */
		public var onStart:Function;
		/** Callback to fire when object properties is updated during animation. Typically on every frame of animation. Not fired during delay or paused
		 * states. Can be set on instance or passed in animation properties object @see #onUpdateArgs() */
		public var onUpdate:Function;
		/** Callback to fire every time object reaches destination values (before reversing to start values) <b>if</b> <code>yoyo=true</code> @see #onYoyoHalfArgs */
		public var onYoyoHalf:Function;
		/** Animation can be repeated number of times, defined by <code>cycles</code>. Each time one cycle is completed, <code>onCycle</code> callback
		 * (passed in <i>properties</i> object or set on AO instance) can be fired. If <code>yoyo=true</code>, full cycle is when object
		 * returns back to start values. When <code>yoyo=false</code> <i>onCycle</i> is fired when object values reach end values.
		 *  @see #onCycleArgs() @see #yoyo */
		public var onCycle:Function;
		/** Callback to fire when animation is completed. If interval repetitions are defined, 
		 * fires after all repetitons, otherwise after all cycles. @see #onCompleteArgs() @see #cycles @see #intervalRepetitions */
		public var onComplete:Function;
		/** Callback to fire when time for one interval has passed.
		 * @see #interval @see #intervalRepetitions */
		public var onInterval:Function;
		/** Determines if animation instance is being disposed once animation is completed. AO instances created used <code>animate</code> method
		 * set this property to true. Destroyed instance can't be re-used - calling <i>start</i>, <i>restart</i> on it will likely cause an error.
		 * Instances which are not destroyed on complete, can be re-used. @default false  */
		public var destroyOnComplete:Boolean = false;
		/** Allows to controll speed and direction of animation during animation. 
		 * Setting value of this property to 2 would speed it up twice. If set to 0.5 -
		 * animation would be twice slower. Setting -1 would cause playing backward at normal speed @default 1*/
		public var timeScale:Number=1;
		/** Defines number of frames or seconds which target will be hold on destination values before going back to start values
		 * if <code>yoyo=true</code> @see #yoyo*/
		public var yoyoDelay:Number;
		/** Defines number of frames or seconds which target will be hold on destination values (if <code>yoyo=false</code>) 
		 * or on start values (if <code>yoyo=true</code>), before starting new cycle @see #cycles @see #yoyo*/
		public var cycleDelay:Number;
		/** Animations can be eased  by easing function. This can be custom function or one from predefined in
		 * <code>axl.utils.Easings</code> class, also available as static property of this class.<br><br>
		 * Custom easing functions needs to return Number based on four arguments function must accept:
		 * current time, start value, change in value, duration.  
		 * @see axl.utils.AO#easing */
		public var easing:Function = defaultEasing;
		
		// applying only before start
		private var uIncremental:Boolean=false;
		private var uFrameBased:Boolean=false;
		private var uProps:Object;
		
		// live copy 
		private var incremental:Boolean=false;
		private var frameBased:Boolean=false;
		private var props:Object;
		
		private var xinterval:Number;
		private var intervalDuration:Number;
		private var intervalRemaining:int;
		private var intervalPassed:Boolean;
		private var intervalLock:Boolean;
		
		private var cyclesRemaining:int=1;
		private var xcycles:int=1;
		
		private var xtime:Number;
		private var durationPassed:Boolean;
		
		private var xdelay:Number;
		private var delayRemaining:Number;
		private var valuesCalculated:Boolean;
		
		/** Destroys an instance and makes it un-usable.
		 * <ul><li>stops any animation and removes it from pool (incl. stopped, paused and delayed ones)</li>
		 * <li>disposes all internal objects</li>
		 * <li>removes refference to the subject and to all callbacks</li>
		 * </ul> @param executeOnComplete - determines if <code>onComplete</code> callback should be executed before destruction */
		public function destroy(executeOnComplete:Boolean=false):void
		{
			removeFromPool();
			removeFromInstances();
			delayRemaining = xinterval = intervalDuration = intervalRemaining =cyclesRemaining = 
				numProperties = duration = passedTotal = passedRelative  = xtime = xdelay = direction = xcycles = yoyoDelay = 0;
			propStartValues = propEndValues = propDifferences = incSum =  prevs = null;
			propNames = null;
			subject = props = uProps = null;
			onUpdateArgs = onYoyoHalfArgs = onCycleArgs = onIntervalArgs = onStartArgs = null;
			onStart = onUpdate = onYoyoHalf = onCycle = onInterval =  null;
			
			if(executeOnComplete && (onComplete != null))
				onComplete.apply(null, onCompleteArgs);
			
			onCompleteArgs = null;
			onComplete = null;
		}
		
		private function removeFromInstances():void
		{
			var i:int = allInstances.indexOf(this);
			if(i>-1) 
			{
				allInstances.splice(i,1);
				numInstances--;
				isPlaying = false;
			}
		}
		/** Creates re-usable, not self starting AO instance. Requires to call <code>start</code>
		 * after set up.
		 * If you're not going to re-use it, use static method <code>AO.animate</code> which 
		 * gives all options this instance would give but with just one line.<br>
		 * Re-usable instances are good for optimization. Animations executed big number of times 
		 * on the same target and/or with the same set of settings should be subject of optimization.
		 * set of settings and executed. In all other cases static method is fine. 
		 * @param subject - object you want to animate
		 * @param time - duration of animation in seconds or number of frames
		 * @param properties - key-values object of properties to animate and its destination values. E.g. 
		 * <code>{ x : 220, y : 100, rotation : 360 }</code> 
		 * @see #start() @see axl.utils.AO#animate() */
		public function AO(subject:Object, time:Number, properties:Object) {
			allInstances[numInstances++] = this;
			xtime = time;
			uProps = properties;
			this.subject = subject;
		}
		
		private function setUp():void
		{
			prepareCommon();
			prepareDurations();
			
			if(!delay)
				calculateValues();
			isSetup = true;
			cyclesRemaining = xcycles;
		}
		
		private function prepareDurations():void
		{
			if(frameBased) prepareFrameBased();
			else prepareTimeBased();
		}
		
		private function calculateValues():void
		{
			if(incremental) prepareIncremental();
			else prepareAbsolute();
			valuesCalculated = true;
		}
		
		private function prepareCommon():void
		{
			if(propNames) propNames.length = 0; else propNames = new Vector.<String>();
			if(propStartValues) propStartValues.length = 0; else propStartValues = new Vector.<Number>();
			if(propEndValues) propEndValues.length = 0; else propEndValues = new Vector.<Number>();
			if(propDifferences) propDifferences.length = 0; else propDifferences = new Vector.<Number>();
			
			numProperties = duration = passedTotal = passedRelative = intervalDuration= intervalRemaining = 0;
			
			props = uProps;
			frameBased = uFrameBased;
			incremental = uIncremental;

			updateFunction = incremental ?  updateIncremental : updateAbsolute;
			
			for(var s:String in props)
			{
				if(subject.hasOwnProperty(s) && !isNaN(subject[s]) && !isNaN(props[s]))
					propNames[numProperties++] = s;
				else if(this.hasOwnProperty(s))
					this[s] = props[s];
				else throw new ArgumentError("[AO]" + subject + " Invalid property '"+s+"' or value: " + props[s]);  
			}
		}
		
		// ----------------------------------------- PREPARE ----------------------------------- //
		private function prepareIncremental():void
		{
			if(prevs) prevs.length = 0; else prevs = new Vector.<Number>();
			if(incSum) incSum.length = 0; else incSum = new Vector.<Number>();
			
			for(var i:int=0; i<numProperties;i++)
			{
				propDifferences[i] = props[propNames[i]];
				propStartValues[i] = subject[propNames[i]];
				propEndValues[i] = propStartValues[i] + propDifferences[i];
				incSum[i] = 0;
				prevs[i] = propStartValues[i];
			}
		}
		
		private function prepareAbsolute():void
		{
			for(var i:int=0; i<numProperties;i++)
			{
				propStartValues[i] = subject[propNames[i]];
				propEndValues[i] = props[propNames[i]];
				propDifferences[i] = props[propNames[i]] - subject[propNames[i]];
			}
		}
		
		private function prepareTimeBased():void 
		{
			duration  =  (xtime * 1000);
			delayRemaining = xdelay * 1000;
			intervalDuration = intervalRemaining = (interval * 1000);
		}
		private function prepareFrameBased():void
		{
			duration =xtime; // no frames
			delayRemaining = xdelay;
			intervalDuration = intervalRemaining = interval;
		}
		// ----------------------------------------- UPDATE ------------------------- //
		/** Main propeller of animation engine. It's used to broadcast new frame and compute state of continuation.*/
		protected function tick(milsecs:int):void
		{
			if(delayRemaining > 0)
			{
				delayRemaining -=((frameBased ? 1 : milsecs)* Math.abs(timeScale));
				if(delayRemaining > 0)
					return;
				if(!valuesCalculated)
					calculateValues();
			}
			passedTotal += (frameBased ? 1 : milsecs) * timeScale;
			passedRelative = (direction < 0) ? (duration - passedTotal) : passedTotal;
			durationPassed = passedTotal > duration || passedTotal < 0;
			
			if(durationPassed) // end of period
			{
				if(!intervalLock && continuesCycles()) // waits for another tick (yoyo e.g.
				{
					if(passedTotal > 0) 
						passedTotal -= duration;
					else
						passedTotal += duration;
					passedRelative = (direction < 0) ? (duration - passedTotal) : passedTotal;
					if(incremental)
						loanIncrementalsNextCycle();
					updateFunction();
					
				}
				else if(intervalHasPassed(frameBased ? 1 : milsecs))
				{
					equalize(yoyo ? -1 : direction);
					finish(true); // ends an animation
				}
				//else its interval so do nothing
			}
			else // regular tick dispatch
			{
				updateFunction();
			}
		}
		
		private function intervalHasPassed(passed:Number):Boolean
		{
			if(isNaN(interval)) return true;
			else if(intervalRemaining <= 0)
			{
				intervalRepetitions--;
				passedTotal =intervalRemaining*-1;
				intervalRemaining += intervalDuration;
				cyclesRemaining = xcycles;
				intervalLock = false;
				if(onInterval != null)
					onInterval.apply(null, onIntervalArgs);
				return intervalRepetitions == 0;
			}
			if(!intervalLock)
				equalize(yoyo ? -1 : 1);
			intervalLock = true;
			intervalRemaining -= passed;
			return false;
		}
			
		//absolute
		private function updateAbsolute():void
		{
			for(var i:int=0,ni:int=numProperties,pi:Vector.<String>=propNames;i<ni;i++)
				subject[pi[i]] = getValueLive(i);
			if(onUpdate != null)
				onUpdate.apply(null, onUpdateArgs);
		}
		
		//inctemental
		private function updateIncremental():void
		{
			for(var i:int=0,ni:int=numProperties,pi:Vector.<String>=propNames;i<ni;i++)
			{
				var cv:Number = getValueLive(i);
				var pn:String = pi[i];
				var add:Number = Number((cv - prevs[i]).toPrecision(12));
				var bug:Number = subject[pn];
				subject[pn] = Number((subject[pn]+ add).toPrecision(12));
				bug = (subject[pn] - add) - bug;
				incSum[i] = Number((incSum[i]+ add + bug).toPrecision(12));
				prevs[i] = cv + bug;
			}
			if(onUpdate != null)
				onUpdate.apply(null, onUpdateArgs);
		}
		
		private function getValueLive(i:int):Number
		{
			return easing(passedRelative, propStartValues[i], propDifferences[i], duration);
		}
		
		private function equalize(dir:int):void
		{
			if(!incremental) 
			{
				if(dir > 0) 
					applyValues(propEndValues); 	// | > > > > > > [HERE]|
				else				
					applyValues(propStartValues);	// |[HERE] < < < < < < |
			}
			else 		
				applyRemainingIncrementals(dir);
			if(onUpdate is Function)
				onUpdate.apply(null, onUpdateArgs);
		}
		
		private function loanIncrementalsNextCycle():void
		{
			for(var i:int=0,mis:Number;i<numProperties;i++)
			{
				if(yoyo)
				{
					mis = Number((propDifferences[i] - incSum[i]*direction*-1).toPrecision(12));
					prevs[i] = (direction < 0) ? propEndValues[i] : propStartValues[i];
					prevs[i] = Number((prevs[i]-mis* direction * -1).toPrecision(12));
					incSum[i] = mis * direction;
				}
				else
				{
					mis =Number((propDifferences[i] - incSum[i]).toPrecision(12));
					incSum[i]=Number((mis*-1 + propDifferences[i]).toPrecision(12));
				}
			}
		}
		
		/** this is for incrementals only **/
		private function applyRemainingIncrementals(dir:int):void
		{
			for(var i:int=0,mis:Number;i<numProperties;i++)
			{
				if(yoyo)
					mis = Number(((propDifferences[i] + incSum[i]) *-1).toPrecision(12));
				else if(dir > 0)
					mis =Number((propEndValues[i]- (propStartValues[i] + incSum[i])).toPrecision(12));
				else if  (dir < 0)
					mis =Number((incSum[i]*-1).toPrecision(12));
				subject[propNames[i]] += mis;
				incSum[i] =0;
			}
			if(dir < 0)
				for(i=0; i < numProperties; i++)
					prevs[i] = propStartValues[i];
			else
				for(i=0; i < numProperties; i++)
					prevs[i] = propEndValues[i];
		}
		/** this is for absolutes only **/
		private function applyValues(v:Vector.<Number>):void
		{
			for(var i:int=0;i<numProperties;i++)
				subject[propNames[i]] = v[i];
		}
		
		private function continuesCycles():Boolean
		{
			if(yoyo)
			{
				if(direction > 0)
				{
					direction = -1;
					if(yoyoDelay > 0)
						delayRemaining = (nFrameBased ? yoyoDelay : (yoyoDelay * 1000));
					dispatchHalfYoyo();
					return true;
				}
				else
				{
					direction = 1;
					return cycled();
				}
			} 
			else 
				return cycled();
		}
		
		private function dispatchHalfYoyo():void
		{
			if(onYoyoHalf is Function)
				onYoyoHalf.apply(null, onYoyoHalfArgs);
		}
		
		private function cycled():Boolean
		{
			--cyclesRemaining;
			if(onCycle is Function) 
				onCycle.apply(null, onCycleArgs);
			if(cyclesRemaining == 0)
				return false;
			if(cycleDelay > 0)
				delayRemaining = (nFrameBased ? cycleDelay : (cycleDelay * 1000));
			return true
		}
		
		//-------------------- controll ------------------//
		private function finish(dispatchComplete:Boolean,forceDestroy:Boolean=false):void 
		{ 
			if(destroyOnComplete || forceDestroy)
				destroy(dispatchComplete);
			else
			{
				pause();
				if(onComplete != null && dispatchComplete)
					onComplete.apply(null, onCompleteArgs);
			}
		}
		
		private function gotoEnd():void
		{
			equalize(yoyo ? -1 : 1);
			direction = 1;
			passedTotal = 0;
		}
		
		private function gotoStart():void
		{
			equalize(-1);
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

		private function perform():void 
		{ 
			if(!isSetup)
				setUp();
			else
				prepareDurations();
			if(!isPlaying)
			{
				AO.animObjects[numObjects++] = this;
				isPlaying = true;
				if(onStart is Function) onStart.apply(null, onStartArgs);
			}
		}
		
		// ---------------------------------- public instance API------------------------------------------ //
		/** Returns <code>true</code> if object is actively being updated every frame. Includes delayed. 
		 * Returns <code>false</code> for stopped, paused, completed and  animations */
		public function get isAnimating():Boolean { return isPlaying }
		
		/** Starts animation if not started yet, stopped or paused.
		 * @param respectDelay - If there's a delay assigned to animation - respecting delay will cause delayed start, 
		 * otherwise animation will start promptly */
		public function start(respectDelay:Boolean=true):void
		{
			perform();
			if(!respectDelay)
				delayRemaining = 0;
		}
		/** Starts or continues an animation without respecting delay assigned to it.  @see #start() */
		public function resume():void { start(false) };
		
		/** Pauses an animation immediately. Animation can be resumed from the moment it was paused by calling <code>resume</code> @see #resume() */
		public function pause():void { removeFromPool() };
		
		/** Stops an animation promptly and sets object values according to <code>goToDirection</code> parameter.
		 *  @param goToDirection: 
		 * <ul><li>negative - start (initial) values</li><li> 0 - stays still</li><li>positive - end values</li></ul>
		 * @param readNchanges - determines if animation properties should be re-read before eventual calls 
		 * to <i>start</i> or <i>resume</i> methods */
		public function stop(goToDirection:int=0, readNchanges:Boolean=false):void
		{
			removeFromPool();
			if(goToDirection > 0) gotoEnd();
			else if(goToDirection < 0) gotoStart();
			isSetup = !readNchanges;
		}
		
		/** Restarts an animation instantly (stops it, goes to direction and calls start).
		 *  @param goToDirection: 
		 * <ul><li>negative - start (initial) values</li><li> 0 - stays still</li><li>positive - end values</li></ul>
		 * @param  readNchanges - determines if animation properties should be re-read before start */
		public function restart(goToDirection:int,readNchanges:Boolean=false):void
		{
			stop(goToDirection,readNchanges);
			start();
		}
		
		/** Stops animation before it's completed. 
		 * @param completeImmediately - if true - applies end values to subject of animation and fires <code>onComplete</code> callback
		 * if defined. If false either pauses or destroys an instance - depending on <code>destroyOnComplete</code> flag.
		 * @param forceDestroy - can force disposing instance even if <code>destroyOnComplete=false</code>   */
		public function finishEarly(completeImmediately:Boolean,forceDestroy:Boolean=false):void
		{
			if(completeImmediately)
			{
				gotoEnd();
				finish(true,forceDestroy);
			}
			else finish(false,forceDestroy);
		}
		
		// changes that require stop and re-read;
		/** Determines if updates on target are applied with respect to its current momentum values (true) or as an absolute values (false).
		 * When object properties are modified by more than one source (e.g. user interaction or multiple animation objects operates on the 
		 * same property), non inctemental updates can cause jerkiness. Incremental updates allows to overcome that but require user to  
		 * calculate destination values relatively to it's current position. */
		public function get nIncremental():Boolean { return incremental }
		public function set nIncremental(v:Boolean):void { uIncremental = v }
		
		/** Determines if "time" attribute is defined in seconds (false) or in number of frames (true) */
		public function get nFrameBased():Boolean { return frameBased }
		public function set nFrameBased(v:Boolean):void { uFrameBased = v }
		
		/** Key-value object containing keys as properties to animate (e.g. x,y,scale,rotation) 
		 * and destination values for them PLUS public properties of this class from list bellow:
		 * <ul>
		 * <li>yoyo</li><li>cycles</li><li>subject</li>
		 * <li>interval</li><li>intervalRepetitions</li><li>onStartArgs</li>
		 * <li>onUpdateArgs</li><li>onYoyoHalfArgs</li><li>onCycleArgs</li>
		 * <li>onCompleteArgs</li><li>onStart</li><li>onUpdate</li><li>onYoyoHalf</li>
		 * <li>onCycle</li></ul> 
		 * Every property passed in nProperties can override values set directly on instance or passed to <code>animate</code>
		 * method.<br>
		 * Example object: <code>{ x : 220, y : 100, rotation : 360, onUpdate : someFunction }</code> */
		public function get nProperties():Object { return props }
		public function set nProperties(v:Object):void { uProps = v }
		
		/** Duration of animation in seconds or frames number @see #nFrameBased */
		public function get time():Number { return xtime }
		public function set time(v:Number):void { 
			xtime = v;
			duration = (nFrameBased ? v :  (v * 1000));
		}
		
		/**Delay time in seconds or number of frames (dependent on <code>frameBased</code> flag) before animation starts.
		 * Delay applied during animation causes immediate delay of whatever is being set to.
		 * Delay can be omitted by calling <code>start(false)</code> 
		 * Delayed animations can be killed, stopped or  paused. 
		 * <code>isAnimating()</code> will return true for delayed ones if they're not stopped or paused, false otherwise.
		 * On queries <code>AO.contains</code> it will return true for all not destroyed instances, regardles of their playback state 
		 * @see #isAnimating @see axl.utils.AO#contains() */
		public function get delay():Number { return xdelay }
		public function set delay(v:Number):void 
		{ 
			xdelay = v;
			delayRemaining = (nFrameBased ? v : (v * 1000));
		}
		
		/** Determines how many times animation is repeated. Setting this value to 0 results in infinite number of cycles (object is animated
		 * until stopped different way).<br>
		 * Cycles without <code>yoyo</code> repeat animation from start values right after reaching end values.
		 * When yoyo is set to true, cycle is repeated after reversed animation brings object's properties back to start values.
		 * Executes <code>onCycle</code> if defined.
		 * <br>This property can be applied any time during animation and an effect is immediate.
		 * Requested during animation informs how many cycles remained till end. @default 1 
		 * @see #interval @see #yoyo */
		public function get cycles():int { return xcycles;	}
		public function set cycles(value:int):void { xcycles = cyclesRemaining =  value }
		
		/** Once animation is completed (all yoyo, all cycles) the sequence can be repeated. This property determines number of seconds after which 
		 * is going to happen if <code>intervalRepetitions</code> &gt; 1 
		 * @see #yoyo @see #cycles @see #intervalRepetitions */
		public function get interval():Number {	return xinterval;}
		public function set interval(value:Number):void
		{
			xinterval = value;
			intervalDuration = intervalRemaining = (nFrameBased ? value :  (value * 1000));
		}
		
		// -----------------------  PUBLIC STATIC ------------------- //
		/** Exposes easing functions for animation easings @see axl.utils.Easing @see #nEasing*/
		public static function get easing():Easings { return easings };
		
		/** Stops any existing animations assinged to target (including paused, stopped and delayed). 
		 * If <code>destroyOnComplete = true</code> also destroys AO instance.
		 * @param target - either object you animate or AO instance 
		 * @param completeImmediately - determines if destination values should be assigned to target */
		public static function killOff(target:Object, completeImmediately:Boolean=false):void
		{
			var ai:Vector.<AO> = allInstances,i:int;
			if(target is AO)
				for(i= 0; i < numInstances;i++)
					if(ai[i] == target)
						ai[i--].finishEarly(completeImmediately,true);
					
			if(!(target is AO))
				for(i = 0; i < numInstances;i++)
					if(ai[i].subject === target)
						ai[i--].finishEarly(completeImmediately,true);
		}
		/** Stops all tweens propeled by this class (including paused, stopped and delayed). 
		 * If <code>destroyOnComplete = true</code> also destroys AO instance.
		 * @param completeImmediately - determines if destination values should be assigned to target */
		public static function killAll(completeImmediately:Boolean=false):void
		{
			while(allInstances.length)
				allInstances.pop().finishEarly(completeImmediately,true);
		}
		/** Returns true if target is subject of any animation (incl. delayed, paused, stopped), false otherwise */
		public static function contains(target:Object):Boolean
		{
			var i:int = numInstances;
			if(target is AO)
				while(i-->0)
					if(allInstances[i] == target)
						return true;
			if(!(target is AO))
				while(i-->0)
					if(allInstances[i].subject === target)
						return true;
			return false;
		}
		
		/** Allows to artificialy speed up all animations by dispatching fake enter frame.
		 * @param frameTime for time based animations is number of milliseconnds that passed since last frame.
		 * For frame based animations its 1, autimatically.
		 * @see #nFrameBased @see #tick()  */
		public static function broadcastFrame(frameTime:int):void
		{
			var ao:Vector.<AO> = animObjects;
			var no:int = numObjects;
			for(var i:int = 0; i < no;i++)
				ao[i].tick(frameTime);
		}
		
		/** Receives frame, calculates time passed since last frame and broadcasts it to all AO instances */
		protected static function onEnterFrame(event:Event):void
		{
			var curFrame:int = getTimer();
			var frameTime:int = curFrame - prevFrame;
			prevFrame = curFrame;
			broadcastFrame(frameTime);
		}
		
		/** Animates object according to parameters passed.<br>
		 *  This is core static function to perform custom, complex animations without instantaiting AO manually, to do it 
		 * in one line. By default all AO instances created by this function are going to be destroyed once animation
		 * is completed.
		 * @param subject - object you want to animate
		 * @param time - duration of animation in seconds or number of frames if <code>frameBased true</code>
		 * @param props - key-values object of properties to animate and its destination values. E.g. 
		 * <code>{ x : 220, y : 100, rotation : 360 }</code>
		 * @param  onComplete - callback function to execute once animation is completed 
		 * @param cycles - number of times to repeat animation instantly
		 * @param yoyo - once reached destination values, determines if animation is going to play in reverse (back
		 * to start values)
		 * @param easingType - function to make your animation smooth, bouncy, elastic or other
		 * @param incremental - determines if updates on object respect it's current values (adds the difference) or update with 
		 * absolute values 
		 * @param frameBased - determines if time is specified in frames or seconds
		 * @see #nProperties @see #onComplete @see #cycles  @see #yoyo @see #nEasing @see #nIncremental @see #nFrameBased*/
		public static function animate(subject:Object, time:Number, props:Object, onComplete:Function=null, cycles:int=1,yoyo:Boolean=false,
											   easingType:Object=null, incremental:Boolean=false,frameBased:Boolean=false):AO
		{
			var ao:AO = new AO(subject, time, props);
			ao.onComplete = onComplete || ao.onComplete;
			ao.cycles = cycles;
			ao.yoyo = yoyo;
			ao.easing = (AO.easing.hasOwnProperty(easingType)) ?  AO.easing[easingType] : easingType as Function || AO.defaultEasing ;
			ao.nIncremental = incremental;
			ao.frameBased = frameBased;
			ao.destroyOnComplete=true;
			ao.start();
			return ao;
		}
	}
}

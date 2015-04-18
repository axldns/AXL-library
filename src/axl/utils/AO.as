package axl.utils
{
	public class AO {
		
		private static var animObjects:Vector.<AO> = new Vector.<AO>();
		private static var numObjects:int=0;
		public static function get numAnimObjects():int { return numObjects }
		
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
		
		private var FPS:int;
		private var seconds:Number;
		private var incremental:Boolean;
		private var frameBased:Boolean;
		
		private var passed:Function =passedForward;
		private function passedForward():Number { return passedTotal }
		private function passedBackward():Number { return duration - passedTotal }
		
		private var id:int;
		private var passedRelative:Number;
		private var getValue:Function;
		
		public function AO(target:Object, seconds:Number, props:Object, easingFunction:Function, incremental:Boolean,FPS:int=0) {
			this.subject = target;
			this.seconds = seconds;
			this.easing = easingFunction;
			this.incremental = incremental;
			this.FPS = FPS;
			this.frameBased = (FPS > 0);
			
			propNames= new Vector.<String>();
			propStartValues = new Vector.<Number>();
			propEndValues = new Vector.<Number>();
			propDifferences = new Vector.<Number>();
			//common
			
			for(var s:String in props)
				if(subject.hasOwnProperty(s) && !isNaN(subject[s]) && !isNaN(props[s]))
					propNames[numProperties++] = s;
			
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
					propEndValues[i] = propStartValues[i] + propDifferences[i]; // are they even needed?
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
			id = numObjects;
			animObjects[numObjects++] = this;
		}
		
		// ----------------------------------------- PREPARE ----------------------------------- //
		//time - values are being calculated at runtime, every frame
		private function prepareTimeBased():void {
			duration  = seconds * 1000; // ms
			getValue = getValueLive;
		}
		//frame	- values are being pre-calculated before animation
		private function prepareFrameBased():void
		{
			
			duration  = Math.ceil(FPS * seconds); // number of frames
			getValue = getValueEased;
			eased = new Vector.<Vector.<Number>>();
			var i:int, j:int;
			
			for(i=0;i<numProperties;i++)
			{
				eased[i] = new Vector.<Number>();
				for(j=0; j < duration;j++) 
					eased[i][j] = easing(j,propStartValues[i], propDifferences[i], duration);
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
			var passd:Number = passed();
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
			trace("PT NOW", passedTotal);
			resolveContinuation();
		}
		
		private function equalize():void
		{
			trace('('+id+')'+'---------equalize--------');
			if(!incremental) 
				if(yoyo)
					if(direction > 0) // | > > > > > > [HERE]|
						applyValues(propEndValues);
					else				// |[HERE] < < < < < < |
						applyValues(propStartValues);
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
			trace("------resolveContinuation----------");
			if(yoyo)
			{
				if(direction > 0) // FIRST HALF  | > > > > > > > [HERE]|
				{
					direction = -1;
					passed = passedBackward;
				}
				else
				{
					direction = 1;
					passed = passedForward;
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
		
		public static function killOff(target:Object, completeImmediately:Boolean):Boolean
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
			if(!(target != AO))
				while(i-->0)
					if(animObjects[i].subject === target)
						return true;
			return false;
		}
		
		public static function dispatchFrame(frameTime:int):void
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
	}
}
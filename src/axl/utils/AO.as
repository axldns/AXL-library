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
		
		private var id:int;
		
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
			{
				if(subject.hasOwnProperty(s) && !isNaN(subject[s]) && !isNaN(props[s]))
				{
					propNames[numProperties] = s;
					numProperties++;
				}
			}
			var i:int;
			if(incremental)
			{
				prevs = new Vector.<Number>();
				remains = new Vector.<Number>();
				for(i=0; i<numProperties;i++)
				{
					propDifferences[i] =props[propNames[i]];
					propStartValues[i] = subject[propNames[i]];
					propEndValues[i] = propStartValues[i] + propDifferences[i];
					remains[i] = propDifferences[i];
				}
				
			}
			else
			{
				for(i=0; i<numProperties;i++)
				{
					propStartValues[i] = subject[propNames[i]];
					propEndValues[i] = props[propNames[i]];
					propDifferences[i] = props[propNames[i]] - subject[propNames[i]];
				}
			}
			applyForwardFunctions();
			if(frameBased)
				prepareFrameBased();
			else
				prepareTimeBased();
			id = numObjects;
			animObjects[numObjects++] = this;
			passedTotal = 0;
		}
		
		// ----------------------------------------- PREPARE ----------------------------------- //
		//time - values are being calculated at runtime, every frame
		private function prepareTimeBased():void {
			duration  = seconds * 1000; // ms
			if(incremental)
				for(var i:int = numProperties; i-->0;)
					prevs[i] = propStartValues[i];
		}
		//frame	- values are being pre-calculated before animation
		private function prepareFrameBased():void
		{
			eased = new Vector.<Vector.<Number>>();
			duration  = Math.ceil(FPS * seconds); // number of frames
			var i:int, j:int;
			
			for(i=0;i<numProperties;i++)
			{
				eased[i] = new Vector.<Number>();
				for(j=0; j < duration;j++) 
					eased[i][j] = easing(j,propStartValues[i], propDifferences[i], duration);
			}
			if(incremental)
				for(i = numProperties; i-->0;)
					prevs[i] = propStartValues[i];
		}
		// ----------------------------------------- UPDATE ------------------------- //
		
		public function tick(milsecs:int):void
		{
			passedTotal += frameBased ? 1 : milsecs;
			if(passedTotal >= duration) 
			{
				trace("FRAME", passedTotal);
				passedTotal = duration;
				passedDuration();
			}
			else
				updateFunction();
			if(onUpdate is Function)
				onUpdate.apply(null, onUpdateArgs);
		}
		
		//absolute
		private function updateFrameAbsolute():void
		{
			for(var i:int=0;i<numProperties;i++)
				subject[propNames[i]] = eased[i][passedTotal];
		}
		private function updateFrameAbsoluteRev():void
		{
			for(var i:int=0;i<numProperties;i++)
				subject[propNames[i]] = eased[i][duration - passedTotal];
		}
		private function updateTimeAbsolute():void
		{
			for(var i:int=0;i<numProperties;i++)
				subject[propNames[i]] = easing(passedTotal, propStartValues[i],propDifferences[i], duration);
		}
		private function updateTimeAbsoluteRev():void
		{
			for(var i:int=0;i<numProperties;i++)
				subject[propNames[i]] = easing(duration - passedTotal, propStartValues[i], propDifferences[i], duration);
		}
		
		//inctemental
		private function updateFrameIncremental():void
		{
			for(var i:int=0;i<numProperties;i++)
			{
				cur = eased[i][passedTotal];
				var add:Number = (cur - prevs[i]);
				
				trace('('+id+')'+passedTotal, 
					'|cur:', cur.toFixed(20), 
					'|prev:', prevs[i].toFixed(20),
					'|dif:',add.toFixed(20),
					'|RES:',(subject[propNames[i]] + (cur - prevs[i])).toFixed(20),
					'|remains:',(remains[i]-add).toFixed(20), 
					'|check:', cur + (remains[i] - add) 
				);
				subject[propNames[i]] += (cur - prevs[i]);
				remains[i] -= add;
				prevs[i] = cur;
			}
		}
		
		private function updateFrameIncrementalRev():void
		{
			for(var i:int=0;i<numProperties;i++)
			{
				cur = eased[i][duration - passedTotal];
				var add:Number = (cur - prevs[i]);
				remains[i] += add;
				
				trace('('+id+')'+passedTotal, 
					'|cur:', cur.toFixed(1), 
					'|prev:', prevs[i].toFixed(12)
					,'|dif:',(cur - prevs[i]).toFixed(12)
					,'|RES:',(subject[propNames[i]] +  (cur - prevs[i])).toFixed(12)
					,'|remains:',remains[i].toFixed(2), 
					'|check:', cur - remains[i] );
				
				subject[propNames[i]] += (cur - prevs[i]);
				prevs[i] = cur;
			}
		}
		
		private function updateTimeIncremental():void
		{
			for(var i:int=0;i<numProperties;i++)
			{
				cur = easing(passedTotal, propStartValues[i], propDifferences[i], duration);
				var add:Number = (cur - prevs[i]);
				trace('('+id+')'+passedTotal, 
					'|cur:', cur.toFixed(20), 
					'|prev:', prevs[i].toFixed(20),
					'|dif:',add.toFixed(20),
					'|RES:',(subject[propNames[i]] + (cur - prevs[i])).toFixed(20),
					'|remains:',(remains[i]-add).toFixed(20), 
					'|check:', cur + (remains[i] - add) 
				);
				subject[propNames[i]] += (cur - prevs[i]);
				remains[i] -= add;
				prevs[i] = cur;
			}
		}
		
		private function updateTimeIncrementalRev():void
		{
			for(var i:int=0;i<numProperties;i++)
			{
				cur = easing(duration - passedTotal,  propStartValues[i],propDifferences[i], duration);
				var add:Number = (cur - prevs[i]);
				
				
				trace('('+id+')'+passedTotal, 
					'|cur:', cur.toFixed(1), 
					'|prev:', prevs[i].toFixed(12)
					,'|dif:',(cur - prevs[i]).toFixed(12)
					,'|RES:',(subject[propNames[i]] +  (cur - prevs[i])).toFixed(20)
					,'|remains:',remains[i].toFixed(2), 
					'|check:', cur - remains[i] );
				subject[propNames[i]] += (cur - prevs[i]);
				remains[i] += add;
				prevs[i] = cur;
			}
		}
		//common
		private function passedDuration():void
		{
			trace('('+id+')'+state);
			var i:int
			for(i=0;i<numProperties;i++)
				trace('('+id+')'+propNames[i], ':', subject[propNames[i]].toFixed(20))
			equalize();
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
		
		private function applyRemainings():void
		{
			trace('('+id+')'+"------applyRemainings----------", direction);
			
			for(var i:int=0;i<numProperties;i++)
			{
				trace('r:', remains[i] * direction);
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
			trace("asignValues", v == propStartValues ? 'start' : 'end?');
			for(var i:int=0;i<numProperties;i++)
				subject[propNames[i]] = v[i];
		}
		
		
		private function resolveContinuation():void
		{
			trace("------resolveContinuation----------");
			if(yoyo)
			{
				if(direction > 0) // FIRST HALF  | > > > > > > > [HERE]|
					applyRevFunctions();
				else
				{
					applyForwardFunctions();
					completeYoyo();
					cycled();
				}
				direction = (direction > 0) ? -1 : 1;
			} 
			else cycled();
		}
		
		private function completeYoyo():void
		{
			trace("completeYoyo");
			if(onYoyoHalf is Function)
				onYoyoHalf.apply(null, onYoyoHalfArgs);
		}
		
		
		private function cycled():void
		{
			trace("------------cycled--------(remaining:", cycles-1,")");
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
				trace("PASSED REMAINING", passedTotal, 'direction', direction);
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
		
		private function applyRevFunctions():void
		{
			if(incremental)
				updateFunction = frameBased ? updateFrameIncrementalRev : updateTimeIncrementalRev;
			else
				updateFunction = frameBased ? updateFrameAbsoluteRev : updateTimeAbsoluteRev;
		}
		
		private function applyForwardFunctions():void
		{
			if(incremental)
				updateFunction = frameBased ? updateFrameIncremental : updateTimeIncremental;
			else
				updateFunction = frameBased ? updateFrameAbsolute : updateTimeAbsolute;
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
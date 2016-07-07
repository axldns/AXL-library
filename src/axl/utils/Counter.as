/**
 *
 * AXL Library
 * Copyright 2014-2016 Denis Aleksandrowicz. All Rights Reserved.
 *
 * This program is free software. You can redistribute and/or modify it
 * in accordance with the terms of the accompanying license agreement.
 *
 */
package axl.utils {
	import flash.system.ApplicationDomain;
	import flash.utils.clearInterval;
	import flash.utils.clearTimeout;
	import flash.utils.getDefinitionByName;
	import flash.utils.getTimer;
	import flash.utils.setInterval;
	import flash.utils.setTimeout;
	/** 
	 * Class combines <i>flash.utils.setTimeout</i> and <i>flas.utlis.setInterval</i> package 
	 * level functions and provides easy API for:
	 * <ul>
	 * <li>Setting subsequent callbacks of irregular time periods (cue point style)</li>
	 * <li>Detailed information about time remaining across periods</li>
	 * <li>Returning well formatted strings (supports custom formats) with that informations</li>
	 * </ul><br>
	 * Works around limitation of native setTimeout and Timer.delay where max number of milliseconds
	 * is equal to int.MAX_VALUE which is approx. 24.8 days. Ideal solution for countdowns.
	 * <h3>Example</h3>
	 * Custom formating can be defined similarly to <i>flash.globalization.DateTimeFormatter</i> manner.<br>
	 * <code>time = 0;<br>timing = [3667];<br>tillNext("'time left:' dd : hh : mm : s"); </code>// time left 00 : 01 : 01 : 7<br>
	 * <code>tillNext("mm 'minutes' ss 'seconds left'"); </code>// 61 minutes  07 seconds left
	 * @see #timing @see #timeIndex
	 * */
	public class Counter
	{
		private static var regexp:RegExp = /y+|w+|M+|d+|m+|h+|'.+?'|s+|S+|\s+|\W+/g;
		/** Default value for <code>tillNext()</code> time formatting. @see #tillNext() */
		public var defaultFormat:String="hh'h' mm'm' ss's'";
		/** Function to execute when timeIndex changes. @see #timeIndex */
		public var onTimeIndexChange:Object;
		/** Function to execute when max timeIndex is reached @see #timeIndex*/
		public var onComplete:Object;
		/** Function to execute on interval's tick. @see #interval*/
		public var onUpdate:Object;
		/** Indicates logging errors and infos */
		public var debug:Boolean;
		/** Log function for counter. By default U.log if available, native trace otherwise. 
		 * Logging occures only if debug is set to true @see #debug*/
		public var log:Function = ApplicationDomain.currentDomain.hasDefinition('axl.utils::U') ? Class(getDefinitionByName('axl.utils::U')).log : trace;
		
		private var initTime:int;
		private var intervalID:uint = 0;
		private var intervalValue:uint;
		private var timeoutID:uint;
		private var xremaining:Number;
		private var tillChangePortions:Array;
		
		private var maxIndex:uint;
		private var xTime:Number;
		private var xTiming:Array;
		private var xTimeIndex:int=-2;
		private var xname:String;
		private var tname:String = '[Counter]';
		public function Counter()
		{
		}
		/** Counters can be identified by name */
		public function get name():String { return xname }
		public function set name(v:String):void { xname = v; tname = '[Counter]['+v+']'}
		/** Sets/gets sets server time in seconds.<ul><li> Setting time saves value and starts counter</li>
		 * <li>Getting serveTime returns initial time plus time since it was set</li></ul>
		 * @param v - number of seconds e.g utc timestamp @see #originaltime*/
		public function set time(v:Number):void 
		{
			if(isNaN(v)) 
			{
				if(debug) log(tname+"[time] CAN'T BE NaN");
				return;
			}
			clearTimeout(timeoutID);
			xTime = v;
			initTime = getTimer();
			if(timing != null)
				findTimeIndex();
		}
		public function get time():Number 
		{
			if(!isNaN(xTime))
				return xTime + Math.round((getTimer() - initTime)/1000);
			return NaN; 
		}
		
		/** Returns original server time assigned without time offset since passed. @see #time*/
		public function get originaltime():Number { return xTime } 
		
		/** An Array of numeric values - numbers of seconds.<br>Values in array <u>must be layed out increasingly</u>. These
		 * are not defining time gaps relatively to each other. Values in array represent "cue points" on timeline  
		 * and <code>time</code> is compared against these values to work out <code>timeIndex</code> (head).<br>
		 * The delay is equal to difference between <i>time</i> and particular cue points.<br> 
		 * <br>If timeIndex is lower than the timing array length, callback to next 
		 * cue point is set.<br>Everytime new timeIndex is set onTimeIndexChange is fired.<br> When timeIndex 
		 * reaches length of timing array - <i>onComplete</i> is fired
		 * <h3>Example</h3><code>time='0';<br>timing='[20,30,80,90,400]';</code><br> Will result:<br>
		 * <ul>
		 * <li>timeIndex changes from -2 to -1 immediately, <i>onTimeIndexChange(-1)</i> is fired</li>
		 * <li>After 20 seconds: timeIndex changes from -1 to 0, <i>onTimeIndexChange(0)</i> is fired</li>
		 * <li>After another 10 seconds: timeIndex changes from 0 to 1, <i>onTimeIndexChange(1)</i> is fired</li>
		 * <li>After another 50 seconds: timeIndex changes from 1 to 2, <i>onTimeIndexChange(2)</i> is fired</li>
		 * <li>After 90 seconds since time/timing was set: timeIndex changes from 2 to 3, <i>onTimeIndexChange(3)</i> is fired</li>
		 * <li>After another 310 seconds: timeIndex changes from 3 to 4, <i>onTimeIndexChange(4)</i> is fired,
		 * <i>onComplete</i> is fired</li></ul> @see #timeIndex  */
		public function get timing():Array { return xTiming }
		public function set timing(v:Array):void
		{
			xTiming = v;
			xTimeIndex = -2;
			clearTimeout(timeoutID);
			if(!xTiming)
				return;
			findTimeIndex();
		}
		
		/** Returns current period id figured out based on comparison of <i>time</i> against <i>timing</i> array
		 * values.<br> Returns <ul>
		 * <li><b>-2</b> if timing or time is not set</li>
		 * <li><b>-1</b> if time value is less than first value in timing array</li>
		 * <li>other int equal to index of last value in timing array which is smaller than <i>time</i></li></ul>
		 * @see #timing */
		public function get timeIndex():int { return xTimeIndex }
		
		private function findTimeIndex():void
		{
			if(isNaN(time) || !timing)
				return;
			maxIndex = timing.length-1;
			if(maxIndex < 0)
				return;
			var newTimeIndex:int = -1;
			var server:Number = time;
			if(debug) log(tname+"[findTimeIndex] time:", server, 'current time index', timeIndex,"max time index", maxIndex);			
			for(var i:int = 0; i <= maxIndex; i++)
			{
				if(debug) log(server, '>', timing[i], (server > timing[i]))
				if(!(server > timing[i]))
					break;
			}
			newTimeIndex = i-1;
			if(newTimeIndex == timeIndex)
			{
				if(debug) log(tname+"[findTimeIndex][NO TIME INDEX CHANGE]", newTimeIndex, timeIndex);
				return;
			}
			else if(debug)
			{
				log(tname+"[findTimeIndex][NEW TIME INDEX]:", newTimeIndex, 'from (', timeIndex,') time:', server);
			}
			xTimeIndex = newTimeIndex;
			executeOnTimeIndexChange();
			setUpNextCallback();
		}		
		
		private function setUpNextCallback():void
		{
			if(timeIndex < maxIndex)
			{
				var secondsTillNextPeriod:Number = ((xTiming[timeIndex + 1] - time) + 1);
				var tillChangeMs:Number = secondsTillNextPeriod*1000;
				var parcel:Number = int.MAX_VALUE;
				tillChangePortions=[];
				
				while(tillChangeMs > parcel)
				{
					tillChangeMs -= parcel;
					tillChangePortions.push(parcel);
				}
				
				if(debug) log(tname+"[setUpNextCallback] time Index:", timeIndex, 
					'NEXT CHANGE TIME', xTiming[timeIndex + 1], 'which is in', secondsTillNextPeriod,
					'seconds', "(packed in groups of", this.tillChangePortions.length +1,')');
				timeoutID = setTimeout(nextTimeParcel, tillChangeMs);
			}
			else
			{
				executeTimerComplete();
			}
		}
		
		private function nextTimeParcel():void
		{
			if(!tillChangePortions || tillChangePortions.length <1)
				findTimeIndex();
			else
			{
				var nextMs:Number = tillChangePortions.pop();
				timeoutID = setTimeout(nextTimeParcel, nextMs);
			}
		}		
		/** Executed when timeIndex changes. */
		protected function executeOnTimeIndexChange():void
		{
			if(onTimeIndexChange is Function)
				onTimeIndexChange(timeIndex);
		}
		/** Executed when timeIndex reaches end of timing array. */
		protected function executeTimerComplete():void
		{
			if(debug) log(tname+"[COMPLETE]");
			if(intervalID)
				clearInterval(intervalID);
			if(onComplete is Function)
				onComplete();
		}
		//---------------------------------------------- TIMEOUT SECTION -----------------------------------//
		//---------------------------------------------- INTERVAL SECTION -----------------------------------//
		
		/** Sets/gets frequency of executing <code>onUpdate</code> function in seconds.<br>
		 * Can't be greater then approx 24 days (int.MAX_VALUE/1000 seconds).
		 * @param v number of seconds @see #onUpdate() */
		public function get interval():Number { return intervalValue}
		public function set interval(v:Number):void
		{
			if(isNaN(intervalValue)) 
			{
				if(debug) log(tname+"[interval] CAN'T BE NaN");
				return;
			}
			var ms:Number = v * 1000;
			if(ms > int.MAX_VALUE)
			{
				if(debug) log(tname+"[interval][MAX exceeded]" + int.MAX_VALUE/1000);
				return;
			}
			if(intervalID)
				clearInterval(intervalID);
			intervalValue = v;
			intervalID = setInterval(executeOnIntervalUpdate, ms);
		}
		/** Executed when interval time value passes */
		protected function executeOnIntervalUpdate():void
		{
			updateRemaining();
			if(onUpdate is Function)
				onUpdate();
		}
		
		private function updateRemaining():void
		{
			xremaining = time;
		}
		
		//---------------------------------------------- INTERVAL SECTION -----------------------------------//
		//---------------------------------------------- API SECTION -----------------------------------//
		/** Stops onUpdate interval, stops time index changes, set, sets timeIndex to -2.<br>
		 * After this call neither onUpdate, nor onTimeIndexChange, nor
		 * onComplete will be called. Does not remove references to these functions, does not clear timing array.<br>
		 * Unlike tillNext functions, requesting <code>time</code>  still return right value. @see #destroy() */
		public function stopAll():void
		{
			clearInterval(intervalID);
			clearTimeout(this.timeoutID);
			this.xTimeIndex = -2;
			this.timeoutID = 0;
			this.intervalID = 0;
		}
		/** Stops all counters, removes all callbacks references, names, timing arrays. @see #stopAll() */
		public function destroy():void
		{
			stopAll();
			this.defaultFormat = xname = null;
			this.initTime = xremaining = intervalValue = xTime = maxIndex = 0;
			this.log = null;
			this.onComplete = this.onTimeIndexChange = this.onUpdate = null;
			this.tillChangePortions = xTiming = null;
			
		}
		/** Returns number of miliseconds till next period defined in timing array.
		 * @param nextSybiling (default s) : <ul><li>null - returns absolute number remaining</li><li>one of 
		 * (<i>s,m,h,d,w,M,y</i>) - returns value relative to next sybiling e.g. 1h 3590000 ms</li></ul>
		 * @param mod (default 1) : <ul><li>positive: next period defined as timeIndex + mod</li>
		 * <li>negative: next period defined as timing.length + mod (-1 would take "end" value)</li></ul> 
		 * @param leadingZeros: - adds as many zeros at the begining of output value as needed to match 
		 * output value's <u>length</u>. If leadingZeros is positive - returned value is floored, raw otherwise. 
		 * @see #timing @see #timeIndex  */
		public function millisecondsTillNext(nextSybiling:String='s',mod:int=1,leadingZeros:int=0):String
		{
			var stn:Number = getOffset(mod)*1000, out:String;
			switch(nextSybiling) {
				case "s": stn = stn % 1000; break;
				case "m": stn = stn % 60000; break;
				case "h": stn = stn % 3600000; break; // 60 * 60
				case "d": stn = stn % 86400000; break; // 60 * 60 * 24
				case "w": stn = stn % 604800000; break;// 60 * 60 * 24 * 7
				case "M": stn = stn % (365.25/12 * 86400000); break;
				case "y": stn = stn % (365.25 * 86400000); break;
			}
			out = String(leadingZeros < 0 ? stn : Math.floor(stn));
			while(out.length < leadingZeros)
				out = '0' + out;
			return out;
		}
		
		/** Returns number of seconds till next period defined in timing array.
		 * @param nextSybiling (default m): <ul><li>null - returns absolute number remaining</li><li>one of 
		 * (<i>m,h,d,w,M,y</i>) - returns value relative to next sybiling e.g. 1h 3590s</li></ul>
		 * @param mod (default 1) : <ul><li>positive: next period defined as timeIndex + mod</li>
		 * <li>negative: next period defined as timing.length + mod (-1 would take "end" value)</li></ul> 
		 * @param leadingZeros: - adds as many zeros at the begining of output value as needed to match 
		 * output value's <u>length</u>. If leadingZeros is positive - returned value is floored, raw otherwise. 
		 * @see #timing @see #timeIndex */
		public function secondsTillNext(nextSybiling:String='m',mod:int=1,leadingZeros:int=0):String
		{
			var stn:Number = getOffset(mod), out:String;
			switch(nextSybiling) {
				case "m": stn = stn % 60; break;
				case "h": stn = stn % 3600; break; // 60 * 60
				case "d": stn = stn % 86400; break; // 60 * 60 * 24
				case "w": stn = stn % 604800; break;// 60 * 60 * 24 * 7
				case "M": stn = stn % (365.25/12 * 86400); break;
				case "y": stn = stn % (365.25 * 86400); break;
			}
			out = String(leadingZeros < 0 ? stn : Math.floor(stn));
			while(out.length < leadingZeros)
				out = '0' + out;
			return out;
		}
		/** Returns number of minutes till next period defined in timing array.
		 * @param nextSybiling (default h): <ul><li>null - returns absolute number remaining</li><li>one of 
		 * (<i>h,d,w,M,y</i>) - returns value relative to next sybiling e.g. 1day 120min </li></ul>
		 * @param mod (default 1) : <ul><li>positive: next period defined as timeIndex + mod</li>
		 * <li>negative: next period defined as timing.length + mod (-1 would take "end" value)</li></ul> 
		 * @param leadingZeros: - adds as many zeros at the begining of output value as needed to match 
		 * output value's <u>length</u>. If leadingZeros is positive - returned value is floored, raw otherwise.  
		 * @see #timing @see #timeIndex */
		public function minutesTillNext(nextSybiling:String='h',mod:int=1,leadingZeros:int=0):String
		{
			var stn:Number = getOffset(mod) / 60, out:String;
			switch(nextSybiling) {
				case "h": stn = stn % 60; break;
				case "d": stn = stn % 1440; break; // 60 * 24
				case "w": stn = stn % 10080; break; // 60 * 24 * 7
				case "M": stn = stn % (365.25/12 * 1440); break;
				case "y": stn = stn % (365.25 * 1440); break;
			}
			out = String(leadingZeros < 0 ? stn : Math.floor(stn));
			while(out.length < leadingZeros)
				out = '0' + out;
			return out;
		}
		
		/** Returns number of hours till next period defined in timing array.
		 * @param nextSybiling (default d): <ul><li>null - returns absolute number remaining</li><li>one of 
		 * (<i>d,w,M,y</i>) - returns value relative to next sybiling e.g. 1week 36h </li></ul>
		 * @param mod (default 1) : <ul><li>positive: next period defined as timeIndex + mod</li>
		 * <li>negative: next period defined as timing.length + mod (-1 would take "end" value)</li></ul> 
		 * @param leadingZeros: - adds as many zeros at the begining of output value as needed to match 
		 * output value's <u>length</u>. If leadingZeros is positive - returned value is floored, raw otherwise.  
		 * @see #timing @see #timeIndex */
		public function hoursTillNext(nextSybiling:String='d',mod:int=1,leadingZeros:int=0):String
		{
			var stn:Number = getOffset(mod) / 3600, out:String;
			switch(nextSybiling) {
				case "d": stn = stn % 24; break; 
				case "w": stn = stn % 168; break; // 24 * 7
				case "M": stn = stn % (365.25/12 * 24); break;
				case "y": stn = stn % (365.25 * 24); break;
			}
			out = String(leadingZeros < 0 ? stn : Math.floor(stn));
			while(out.length < leadingZeros)
				out = '0' + out;
			return out;
		}
		
		/** Returns number of days till next period defined in timing array.
		 * @param nextSybiling (default w): <ul><li>null - returns absolute number remaining</li><li>one of 
		 * (<i>w,M,y</i>) - returns value relative to next sybiling e.g. 1y <b>95</b> days  or 1y 3m <b>2</b>d </li></ul>
		 * @param mod (default 1) : <ul><li>positive: next period defined as timeIndex + mod</li>
		 * <li>negative: next period defined as timing.length + mod (-1 would take "end" value)</li></ul> 
		 * @param leadingZeros: - adds as many zeros at the begining of output value as needed to match 
		 * output value's <u>length</u>. If leadingZeros is positive - returned value is floored, raw otherwise.  
		 * @see #timing @see #timeIndex */
		public function daysTillNext(nextSybiling:String='w',mod:int=1,leadingZeros:int=0):String
		{
			var stn:Number = getOffset(mod) / 86400, out:String;
			switch(nextSybiling) {
				case "w": stn = stn % 7; break; 
				case "M": stn = stn % (365.25/12); break;
				case "y": stn = stn % (365.25); break;
			}
			out = String(leadingZeros < 0 ? stn : Math.floor(stn));
			while(out.length < leadingZeros)
				out = '0' + out;
			return out;
		}
		
		/** Returns number of weeks till next period defined in timing array.
		 * @param nextSybiling (default M): <ul><li>null - returns absolute number remaining</li><li>one of 
		 * (<i>M,y</i>) - returns value relative to next sybiling e.g. 1y <b>15</b> weeks  or 1y 3m <b>3</b>w </li></ul>
		 * @param mod (default 1) : <ul><li>positive: next period defined as timeIndex + mod</li>
		 * <li>negative: next period defined as timing.length + mod (-1 would take "end" value)</li></ul> 
		 * @param leadingZeros: - adds as many zeros at the begining of output value as needed to match 
		 * output value's <u>length</u>. If leadingZeros is positive - returned value is floored, raw otherwise.  
		 * @see #timing @see #timeIndex */
		public function weeksTillNext(nextSybiling:String='M',mod:int=1,leadingZeros:int=0):String
		{
			var stn:Number = getOffset(mod) / 604800, out:String;
			switch(nextSybiling) {
				case "M": stn = stn % (4.34524); break;
				case "y": stn = stn % (52.1429); break;
			}
			out = String(leadingZeros < 0 ? stn : Math.floor(stn));
			while(out.length < leadingZeros)
				out = '0' + out;
			return out;
		}
		/** Returns number of months till next period defined in timing array.
		 * @param nextSybiling (default y): <ul><li>null - returns absolute number remaining</li><li>one of 
		 * (<i>y</i>) - returns value relative to next sybiling e.g. 1y <b>4</b>months  or <b>16</b>months</li></ul>
		 * @param mod (default 1) : <ul><li>positive: next period defined as timeIndex + mod</li>
		 * <li>negative: next period defined as timing.length + mod (-1 would take "end" value)</li></ul> 
		 * @param leadingZeros: - adds as many zeros at the begining of output value as needed to match 
		 * output value's <u>length</u>. If leadingZeros is positive - returned value is floored, raw otherwise.  
		 * @see #timing @see #timeIndex */
		public function monthsTillNext(nextSybiling:String='y',mod:int=1,leadingZeros:int=0):String
		{
			var stn:Number = getOffset(mod) / (365.25/12 * 86400), out:String;
			switch(nextSybiling) {
				case "y": stn = stn % (12); break;
			}
			out = String(leadingZeros < 0 ? stn : Math.floor(stn));
			while(out.length < leadingZeros)
				out = '0' + out;
			return out;
		}
		/** Returns number of years till next period defined in timing array.
		 * @param nextSybiling - doesn't have any meaning. Kept for consistency with other tillNext functions
		 * @param mod (default 1) : <ul><li>positive: next period defined as timeIndex + mod</li>
		 * <li>negative: next period defined as timing.length + mod (-1 would take "end" value)</li></ul> 
		 * @param leadingZeros: - adds as many zeros at the begining of output value as needed to match 
		 * output value's <u>length</u>. If leadingZeros is positive - returned value is floored, raw otherwise.  
		 * @see #timing @see #timeIndex */
		public function yearsTillNext(nextSybiling:String=null,mod:int=1,leadingZeros:int=0):String
		{
			var stn:Number = getOffset(mod) / (365.25 * 86400),out:String;
			out = String(leadingZeros < 0 ? stn : Math.floor(stn));
			while(out.length < leadingZeros)
				out = '0' + out;
			return out;
		}
		
		private function getOffset(mod:int):Number 
		{
			if(mod < 0)
				mod += timing.length;
			else
				mod += timeIndex;
			if(mod < 0 || mod > maxIndex)
				return -1;
			return timing[mod] -xremaining;
		}
		/** Returns time remaining to next period.  Alias to (y|M|w|d|h|s|S)tillNext functions.
		 * @param scale - portion of time to express time remaining - one of (y,M,w,d,h,m,s,S)
		 * @param nextSybiling: <ul><li>null - returns absolute portion remaining</li><li>one of 
		 * (<i>y,M,w,d,h,m,s,S</i>) - returns value relative to next sybiling. E.g.</li></ul>
		 * <pre>tillNextBit('M',null) // 13<br>tillNextBit('M','y') // 1</pre>
		 * @param mod (default 1) : <ul><li>positive: next period defined as timeIndex + mod</li>
		 * <li>negative: next period defined as timing.length + mod (-1 would take "end" value)</li></ul>
		 * @param leadingZeros: - adds as many zeros at the begining of output value as needed to match 
		 * output value's <u>length</u>. If leadingZeros is positive - returned value is floored, raw otherwise.  
		 * @see #timing @see #timeIndex */
		public function tillNextBit(scale:String,nextSybiling:String=null,mod:int=1,leadingZeros:int=0):String
		{
			switch(scale)
			{
				case "y": return yearsTillNext(nextSybiling,mod,leadingZeros);
				case "M": return monthsTillNext(nextSybiling,mod,leadingZeros);
				case "w": return weeksTillNext(nextSybiling,mod,leadingZeros);
				case "d": return daysTillNext(nextSybiling,mod,leadingZeros);
				case "h": return hoursTillNext(nextSybiling,mod,leadingZeros);
				case "m": return minutesTillNext(nextSybiling,mod,leadingZeros);
				case "s": return secondsTillNext(nextSybiling,mod,leadingZeros);
				case "S": return millisecondsTillNext(nextSybiling,mod,leadingZeros);
				default: return null;
			}
		}
		/** Returns well formatted time remaining to next period. Combines (y|M|w|d|h|s|S)tillNext functions.<br>
		 * Custom formating can be defined similarly to flash.globalization.DateTimeFormatter manner.<br>
		 * <code>time = 0;<br>timing = [3667];<br>tillNext("'time left:' dd : hh : mm : s"); </code>// time left 00 : 01 : 01 : 7<br>
		 * <code>tillNext("mm 'minutes' ss 'seconds left'"); </code>// 61 minutes  07 seconds left
		 * @param format  - format pattern stirng. Any "non-time" values must be wrapped in a single quotes.
		 * @param mod (default 1) : <ul><li>positive: next period defined as timeIndex + mod</li>
		 * <li>negative: next period defined as timing.length + mod (-1 would take "end" value)</li></ul>
		 * @see #timing @see #timeIndex */
		public function tillNext(format:String=null,mod:int=1):String
		{
			updateRemaining();
			format = format || defaultFormat;
			var a:Array = format.match(regexp), out:String='';
			var bm:Object={};
			for(var i:int =0,j:int = a.length,s:String,l:int; i<j;i++)
				bm[a[i].charAt(0)]= true;
			for(i =0;i<j;i++)
			{
				s=a[i].charAt(0);
				l =a[i].length;
				switch(s)
				{
					case "'": out += a[i].replace(/'/g, ""); break;
					case "y": out += yearsTillNext(null,mod,l); break;
					case "M": out += monthsTillNext(bm.y?'y':null,mod,l); break;
					case "w": out += weeksTillNext(bm.M?'M':(bm.y?'y':null),mod,l); break;
					case "d": out += daysTillNext(bm.w?'w':(bm.M?'M':(bm.y?'y':null)),mod,l); break;
					case "h": out += hoursTillNext(bm.d?'d':(bm.w?'w':(bm.M?'M':(bm.y?'y':null))),mod,l); break;
					case "m": out += minutesTillNext(bm.h?'h':(bm.d?'d':(bm.w?'w':(bm.M?'M':(bm.y?'y':null)))),mod,l); break;
					case "s": out += secondsTillNext(bm.m?'m':(bm.h?'h':(bm.d?'d':(bm.w?'w':(bm.M?'M':(bm.y?'y':null))))),mod,l); break;
					case "S": out += millisecondsTillNext(bm.s?'s':(bm.m?'m':(bm.h?'h':(bm.d?'d':(bm.w?'w':(bm.M?'M':(bm.y?'y':null)))))),mod,l); break;
					default: out +=a[i];
				}
			}
			return out;
		}
		/** Provides one line style counter. Creates, sets up and returns Counter instance.*/
		public static function count(timing:Array,onComplete:Object=null,time:Number=0,onTimeIndexChange:Object=null,interval:Number=1,onUpdate:Object=null,defaultFormat:String=null,debug:Boolean=false,counterName:String=null,log:Function=null):Counter
		{
			var c:Counter = new Counter();
			c.debug = debug;
			c.time = time;
			c.defaultFormat = defaultFormat;
			if(counterName!=null) c.name = counterName;
			if(log!=null) c.log = log;
			c.onComplete = onComplete;
			c.onTimeIndexChange = onTimeIndexChange;
			c.onUpdate = onUpdate;
			c.interval = interval;
			c.timing = timing;
			return c;
		}
	}
}
package axl.utils
{
	/**
	 * [axldns free coding 2015]
	 */
	import flash.display.Sprite;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.UncaughtErrorEvent;
	import flash.external.ExternalInterface;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.ui.Keyboard;
	import flash.utils.describeType;
	import flash.utils.getDefinitionByName;
	
	/**
	 * Console window for flash :) ctrl + alt + RIGHT_ARROW to run it/hide it.
	 * Use it to interact with your live compiled app elements. 
	 * It can read basic actionscript syntax. Understands references, assignments, mathematical operations basic types. All live but buggy in some areas (Boolean)
	 * Use it for trace outs wherever you can't see regular trace. 
	 * Use bin.pool to asign any object anywhere and debug it quickly
	 * Use setExternalTrace to pass trace to ExternalInterface too
	 */
	public class BinAgent extends Sprite
	{
		private var regFreeIndex:RegExp = /".*?"\s*\d/g;
		private var regScontext:RegExp= /(\A|[\(|\[|\{|\+|\,|\=])\s*".*?"\s*|\Z|[\+|\=|\.|\,|\)|\]|\}|;]/g;
		private var regEdgeRight:RegExp = /\A\s*?([.,;:=}\+\)\]\|\&]|\Z)/;
		private var regEdgeLeft:RegExp = /\.*(\A|\s|[.,;:=\+\|\(\{\[\&])\Z/;
		protected var regArgumentEquations:RegExp = /-=|[\|]{2}|[\d*[.]{0,1}\d]|[\+|\*|\/|<|>|\|=|\!]={0,2}|¬|[\&]{2}/g;///[\d*[.]{0,1}\d]|[+|\-|*|\/|==|<|>]/g;
		
		public var hierarchy:Array = [['*','/','*=','/=','!'],['+','-','+=','-='],['<','<=','>','>=','==','===','!=', '!==', S_IS], ['||','&&'],['=']]
		protected var asignments:Array=['=','+=','-=','*=','/='];
		private var hdict:Object = {};
		
		private var HASH_BRACKETS:Array;
		private var HASH_STRINGS:Array;
		protected var S_IS:String = '¬';
		protected var S_BRACKETS:String = '©';
		protected var S_STRINGS:String = 'µ';
		
		private var input:TextField;
		private var console:TextField;
		public var rootObj:Object;
		private var EXTERNAL_JS:String;
		
		private var console_textFormat:TextFormat = new TextFormat('Lucida Console', 14, 0xaaaaaa, null, null, null, null, null, null, null, null, null, -1);
		private var input_textFormat:TextFormat =  new TextFormat('Lucida Console', 14, 0x333333, null, null, null, null, null, null, null, null, null, -1);
		private var consoleOutput_TextFormat:TextFormat =  new TextFormat('Lucida Console', 14, 0xFFDE9D, null, null, null, null, null, null, null, null, null, -1);
		
		private var past:Vector.<String> = new Vector.<String>();
		private var pastIndex:int;
		private var container:Sprite;
		private var LISTENER_ADDED:Boolean;
		private var _pool:Object = {};
		private var cslider:Sprite;
		private var sliderIsDown:Boolean;
		public static var LIVE:Boolean;
		public var regularTrace:Boolean = true;
		
		public function BinAgent(root:Object, isitDebug:Boolean)
		{
			LIVE = !isitDebug;
			if(LIVE)
				return;
			rootObj = root;
			rootObj.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, uncaughtError);

			build();
			rootObj.addChild(this);
			this.alpha = .9;
			trace("==== BIN AGENT ====");
		}
		
		public function resize(w:Number, h:Number=0):void
		{
			if(LIVE)
				return;
			console.width = w;
			input.width = w;
			cslider.x = console.width - cslider.width;
			if(h !=0)
			{
				console.height = h;
				input.height = h;
			}
		}
		private function uncaughtError(e:UncaughtErrorEvent):void
		{
			var message:String;
			
			if (e.error is Error)
				message = Error(e.error).message;
			else if (e.error is ErrorEvent)
				message = ErrorEvent(e.error).text;
			else
				message = e.error.toString();
			trrace('uncaught error: ', message, '(', e.error, e.text, e.toString(), e.type, e.target, ')');
		}
		
		
		
		private function build():void
		{
			this.build_hierarchy();
			this.container = new Sprite();
			this.build_console();
			this.build_consoleSlider();
			this.build_input();
			this.build_controll();
		}
		private function build_hierarchy():void
		{
			var ha:Array;
			while(hierarchy.length)
			{
				ha = hierarchy.pop();
				while(ha.length)
					hdict[ha.pop()] = hierarchy.length;
			}
			ha =null;
			hierarchy = null;
		}
		
		//////// GUI ////////
		
		private function build_console():void
		{
			console = new TextField();
			console.defaultTextFormat = console_textFormat;
			console.multiline = true;
			console.wordWrap= true;
			console.border = true;
			console.width = 500;
			console.height = 200;
			console.background = true;
			console.backgroundColor = 0x333333;
			console.type = 'dynamic';
			console.selectable = true;
			container.addChild(console);
		}
		
		private function build_consoleSlider():void
		{
			cslider = new Sprite();
			cslider.graphics.beginFill(0xffffff);
			cslider.graphics.drawRoundRect(0,0, 15,25,5,5);
			cslider.graphics.endFill();
			cslider.x = console.x + console.width - cslider.width;
			cslider.mouseChildren = false;
			cslider.y = console.y + console.height - cslider.height;
			container.addChild(cslider);
			
		}
		
		protected function sliderMove(e:MouseEvent):void
		{
			if(!this.sliderIsDown)
				return;
			var newy:Number = console.mouseY;
			
			if(newy < 0)
				newy = 0
			if(newy > console.height)
				newy = console.height;
			
			var p:Number = newy / console.height;
			console.scrollV = p * console.maxScrollV;
			
			var sy:Number = p * console.height;
			sy -= (p*cslider.height);
			cslider.y = sy;
		}
		
		private function build_input():void
		{
			input = new TextField();
			input.defaultTextFormat = input_textFormat;
			input.multiline = false;
			input.wordWrap= true;
			input.border = true;
			input.width = 500;
			input.height = 20;
			input.y = console.height;
			input.background=true;
			input.backgroundColor= 0xffffff;
			input.type = 'input';
			
			container.addChild(input);
		}
		
		private function build_controll():void
		{
			this.addEventListener(Event.ADDED_TO_STAGE, ats);
			this.addEventListener(Event.REMOVED_FROM_STAGE, rfs);
			this.addEventListener(MouseEvent.MOUSE_DOWN, md);
			input.addEventListener(KeyboardEvent.KEY_UP, KEY_UP);
		}
		
		
		///////  CONTROL
		
		public function ats(e:Event):void{
			stage.focus= this;
			if(!LISTENER_ADDED)
				stage.addEventListener(KeyboardEvent.KEY_DOWN, KEY_DOWN);
			LISTENER_ADDED = true;
			rootObj.stage.addEventListener(MouseEvent.MOUSE_UP, mu);
			rootObj.stage.addEventListener(MouseEvent.MOUSE_MOVE, sliderMove);
		}
		public function rfs(e:Event):void
		{
			rootObj.stage.removeEventListener(MouseEvent.MOUSE_UP, mu);
			rootObj.stage.removeEventListener(MouseEvent.MOUSE_MOVE, sliderMove);
		}
		
		public function md(e:MouseEvent):void
		{
			if(e.shiftKey)
				this.startDrag();
			sliderIsDown = (e.target == cslider);
		}
		
		public function mu(e:MouseEvent):void
		{
			this.stopDrag()
			sliderIsDown = false;
		}
		
		protected function KEY_DOWN(e:KeyboardEvent):void
		{
			//trace(e);
			if(e.altKey && e.ctrlKey && (e.keyCode == Keyboard.RIGHT)) // alt + s
			{
				if(this.contains(container))
					this.removeChild(container);
				else
				{
					this.addChild(container);
					this.stage.focus =input;
				}
				
			}
		}
		
		protected function KEY_UP(e:KeyboardEvent):void
		{
			if(e.charCode == 13)
			{
				var t:String = input.text;
				if(t.length < 1)
					return;
				var tstart:int = console.text.length;
				var tlen:int = trrace(t);
				
				console.setTextFormat(consoleOutput_TextFormat, tstart, tstart +tlen);
				console.scrollV = console.maxScrollV;
				
				try{ trrace(PARSE_INPUT(t))}
				catch (e:*) { trrace("ERROR OCCURED:\n", e) }
				
				console.setTextFormat(console_textFormat, tstart +tlen, console.text.length);
				past.push(t);
				pastIndex = past.length;
				input.text = '';
			}
			else if(e.keyCode == flash.ui.Keyboard.UP)
			{
				if(past.length < 1)
					return;
				if(--pastIndex < 0)
					pastIndex = past.length-1;
				input.text = past[pastIndex];	
				input.setSelection(0, input.text.length);
			}
			else if(e.keyCode == flash.ui.Keyboard.DOWN)
			{
				if(past.length < 1)
					return;
				if(++pastIndex >= past.length)
					pastIndex = 0;
				input.text = past[pastIndex];
				input.setSelection(0, input.text.length);
			}
		}
		//////////////////////////////// END OF BUILD //////////////////////////////// 
		
		/////////////////////////////  magic
		
		private function PARSE_INPUT(s:String):Object
		{
			
			HASH_BRACKETS = [];
			HASH_STRINGS  = [];
			s = hashStrings(s);
			if(s==null)
				return "ERROR: Incorrect Strings. Unpaired or embed wrong.";
			//trace('strings hashed, STATE:\n' + s);
			s = hashBrackets(s)
			if(s==null)
				return "ERROR: Unpaired brackets";
			//trace('brackets hashed, STATE:\n' + s);
			dsp(HASH_BRACKETS); // display
			//trace('------------------------------------------------------------------------');
			var RESULT:Object = loopStructure(s,0);
			//trace("RESULT", RESULT);
			return RESULT;
		}
		
		
		private function hashStrings(s:String):String
		{
			//trace("HASH STRINGS", s);
			if(s.match(/\"/g).length % 2)
				return null;
			
			var f:int;
			var t:int=-1;
			var edgeRight:String;
			var edgeLeft:String;
			while((f = s.indexOf('"')) > -1)
			{
				t = s.indexOf('"',f+1);
				edgeLeft	= s.substr(0,f);
				edgeRight 	= s.substr(t+1);
				//trace('testing L>', edgeLeft, '<(', edgeLeft.length, ') :', edgeLeft.match(regEdgeLeft),'\|/ testing R>', edgeRight, '(', edgeRight.length, ')> :', edgeRight.match(regEdgeRight))
				if(!edgeLeft.match(regEdgeLeft) || !edgeRight.match(regEdgeRight))
					return null;//["Incorect string edge:" + String(edgeLeft.match(regEdgeLeft) ? edgeLeft : edgeRight)];
				HASH_STRINGS.push(s.substring(f+1,t));
				s = String(edgeLeft +  S_STRINGS + String(HASH_STRINGS.length-1) + S_STRINGS + edgeRight);
				t=-1;
			}
			/// replaces IS statement 
			s = s.replace(/\sis\s/g, S_IS);
			/// clear space confusions
			s = s.replace(/\s/g,"");
			return s;
		}
		
		protected function hashBrackets(s:String,deepness:int=0):String
		{
			//trace(deepness, ") HASH Brackets", s);
			// (main(lev1)(again1)(ag1butgot2(lev2got3(lev3))))
			// NEED EDGES VALIDATION
			
			var ss:String;
			var f:int=-1;
			var i:int;
			var skip:int = 0;
			var hashed:String
			for(i=0; i < s.length; i++)
			{
				if(s.charAt(i) == '(')
				{
					if(f < 0)
						f = i;
					else
						skip++;
				}
				else if(s.charAt(i) == ')')
				{
					//trace("SKIP IS", skip)
					if(skip--> 0)
						continue;
					//trace('got pair', f, i)
					if(f < 0)
						return null;
					skip = 0;
					ss = s.substring(f+1,i);
					//s = String(s.substring(0,f) + S_BRACKETS +  String(map.length) +s.substr(i+1));
					
					hashed = hashBrackets(ss,deepness+1);
					if(hashed == null)
						return null;
					s = String(s.substring(0,f) + S_BRACKETS +  String(HASH_BRACKETS.length) + S_BRACKETS+s.substr(i+1));
					HASH_BRACKETS.push(hashed);
					
					i = f;
					f = -1;
				}
			}
			if(s.match(/\(|\)/))
				return null;
			return s;
		}
		
		private function loopStructure(s:String, DEEP:int):Array
		{
			//trace(DEEP, '- loopStructure');	
			if(!s)
				return null;
			var ARGUMENTS:Array = PARSE_ARGUMENTS(s.split(','), DEEP);
			//trace(DEEP, "ARGUMENTS DONE", ARGUMENTS);
			return ARGUMENTS;
		}
		
		private function PARSE_ARGUMENTS(ARGUMENTS:Array, DEEP:int):Array
		{
			//trace(DEEP, '- PARSE_ARGUMENTS:', ARGUMENTS);
			var ARESULT:Array = [];
			for(var i:int = 0; i < ARGUMENTS.length;i++)
			{
				var arg:String = ARGUMENTS[i];
				//trace('\t---------- ARGUMENT', i+1,'/',ARGUMENTS.length, '-----(,)-----:\t',arg);
				var helper:Array = argumentReadyTypeCheck(arg, DEEP);
				if(helper)
				{
					ARESULT[i] = helper.pop();
					//trace('argument is ready type', ARESULT[i]);
				}
				else
					ARESULT[i] = PARSE_ARGUMENT_ELEMENTS(arg,DEEP);
			}
			return ARESULT;
		}
		
		private function argumentReadyTypeCheck(arg:String, DEEP:int):Array
		{
			if(!isNaN(Number(arg)))
				return [Number(arg)]//, trace('skip due to numeric');
			else if(arg == 'true' || arg == 'false')
				return [(arg == 'true')]//, trace('skip due to boolean');
			else if(arg == 'null')
				return [null]// trace('skip due to null');
			else if(arg == 'this')
				return [this]// trace('skip due to null');
			else if(arg.replace(/(\w|\d|\$)+/g, "").length == 0)
				return [findRootBit(arg,DEEP)]// trace('skip due to whole-word case');
			return null;
		}
		
		private function PARSE_ARGUMENT_ELEMENTS(arg:String, DEEP:int):Object
		{
			//trace(DEEP, ' - PARSE_ARGUMENT_ELEMENTS', arg)
			// /[\|]{2}|[\d*[.]{0,1}\d]|[\+|\-|\*|\/|<|>|\|=|\!]={0,2}|¬|[\&]{2}/g;
			var operations:Array = arg.match(regArgumentEquations);
			var ELEMENTS:Array = arg.split(regArgumentEquations);
			var ERESULT:Object; // ACTUAL ARGUMENT ITSELFT
			var e:int;
			var el:String;
			removeEmptyStrings(ELEMENTS);
			//trace(ELEMENTS.length, "ELEMENTS", ELEMENTS);
			//trace(operations.length, "OPERATIONS", operations);
			var GHOSTS:Array = [];
			var helper:Array;
			for( e=0; e < ELEMENTS.length; e++)
			{
				trace('\t\t---------- ELEMENT', e+1,'/',ELEMENTS.length, '----------:\t', ELEMENTS[e]);
				
				el = ELEMENTS[e];
				//trace('-el', el);
				if(!isNaN(Number(el))){
					ELEMENTS[e] = [Number(el)];// trace('skip due to numeric case'); | array because of ghost access
					GHOSTS[e] = [Number(el)];
				}
				else
				{
					helper = PARSE_BIT_PATHS(el, DEEP);
					if(!helper || helper.length != 2)
						return new Error("incorrect argument: " + helper ? helper.pop().message  : arg);
					ELEMENTS[e] = helper.pop();//[[chain][of][access]]
					GHOSTS[e] = helper.pop();// [[for][asignments]]
				}
			}
			// OPERATIONS
			//trace('ghosts', GHOSTS);
			bitOperations(ELEMENTS, operations, GHOSTS);
			
			
			// after all operations it should do fusion to single argument; which may be an array chain
			//trace("ALL ELEMENTS DONE ("+ELEMENTS.length+"):", ELEMENTS);
			if(ELEMENTS.length > 1)
				return new Error("incorrect argument: " + arg);
			helper = ELEMENTS.pop();
			//since elements are storing CHAINS of elements
			
			return helper.pop();
		}
		
		private function PARSE_BIT_PATHS(argumentElement:String, DEEP:int):Array
		{
			//trace('PARSE_BIT_PATHS', argumentElement);
			var result:Array = [];
			var BITS:Array = argumentElement.split(/[\.©]/g);
			removeEmptyStrings(BITS);
			var GHOSTS:Array = BITS.concat();
			var bit:Object;
			var lastObject:Object;
			var curObject:Object;
			for(var i:int = 0; i < BITS.length; i++)
			{
				//trace('\t\t\t---------- BIT', i,'/',BITS.length-1, '----------:\t', BITS[i]);
				bit = BITS[i];
				//trace('!isNaN(bit.replace(S_STRINGS, "") test', bit.replace(/\µ/g, ""), 'isnan?', isNaN( bit.replace(/\µ/g, "")));
				if(!isNaN(Number(bit)))
				{
					bit = revHash(Number(bit), lastObject);
					//trace("REVERSED", bit, 'is array?', bit is Array);
					dsp(bit as Array);
				}
				else if(!isNaN(bit.replace(/\µ/g, "")))
				{
					//trace('hash brackets restore');
					bit = HASH_STRINGS[Number(bit.replace(/\µ/g, ""))];
				}
				if(result.length > 0) // root already there
				{
					//trace(i,'=bit=', bit, 'while last obj', lastObject, 'bit is array', bit is Array)
					try {
						if(result[i-1] is Function)
						{
							if(bit == null)
								result[i] = result[i-1].apply(null,null);
							else
								result[i] = result[i-1].apply(null, bit is Array ? bit : [bit]);
						}
							
						else
						{
							//trace('trying to get', bit, 'from', result[i-1], ' --->', result[i-1][bit]);
							result[i] = result[i-1][bit is Array ? bit.pop() : bit] ;
						}
						
					}
					catch(e:Error) {
						//trace(e);
						return [e] }
				}
				else{
					//trace('crap root');
					result[i]  = findRootBit(bit.toString(), DEEP);
					//trace(i,"ROOT is", result[i]);
				}
				lastObject=result[i];
				//trace("AXON ENDING", lastObject);
			}
			//trace('bit path merged', result);//
			return [GHOSTS, result];
		}		
		
		private function bitOperations(elements:Array, operations:Array, ghosts:Array):Object
		{
			//trace("BIT OPERATIONS:", elements, '------', operations);
			if(!operations || operations.length == 0)
				return elements;
			
			var op:String;
			var i:int;
			
			//trace(parseObject(hdict))
			
			var order:Array=[];
			for(i=0; i < operations.length;i++)
				order[i] = hdict[operations[i]]
			//trace("OPERATIONS OREDER", order);
			
			var min:int;
			var mix:int;
			var left:Object; 
			var right:Object;
			var result:Object;
			var isAsignment:Boolean;
			while(operations.length)
			{
				min = int.MAX_VALUE;
				mix = -1;
				for(i=0;i<order.length;i++)
				{
					if(order[i] < min)
					{
						min = order[i];
						mix = i;
					}
				}
				op = operations[mix];
				if(op == '!')
				{
					left = elements[mix].pop();
					elements[mix+1] = [!left]
				}
				isAsignment = (asignments.indexOf(op)> -1);
				
				
				right = elements[mix+1].pop();
				left = elements[mix].pop();
				if(isAsignment)
					left = elements[mix].pop();
				//trace("OPERATION:", left, op, right, '//a:', ghosts[mix]);
				try{ result = operate(left, op, right,  ghosts[mix].pop())} 
				catch(e:Error)
				{
				//	trace('operation errror', left, op, right);
					trrace(e.message);
					return null;
				} 
				elements[mix] = [result]
				elements.splice(mix+1,1);
				ghosts.splice(mix+1,1);
				order.splice(mix,1);
				operations.splice(mix,1);
				//trace('result:', elements[mix]);
			}
			
			return elements;
		}
		private function operate (left:Object, op:String, right:Object,asig:String=null):Object
		{
			//[['*','/','*=','/='],['+','-','+=','-='],['<','<=','>','>=','==','===','!=', '!==', 'is'], ['||','&&'],['=']]
			//trace("OPERATE", left, op, right, '/asig:', asig);
			switch (op)
			{
				case "+": return left + right;
				case "-": return Number(left) - Number(right);
				case "*": return Number(left) * Number(right);
				case "/": return Number(left) / Number(right);
				case ">" : return Number(left) > Number(right);
				case "<" : return Number(left) < Number(right);
				case "<=" : return Number(left) <= Number(right);
				case ">=" : return Number(left) >= Number(right);
				case "==" : return left == right;
				case "===" : return left === right;
				case "!" : return !right;
				case "!=" : return left != right;
				case "!==" : return left !== right;
				case S_IS : return left is Class(right);
				case "||" : return left || right;
				case "&&" : return left && right;
					//do object beforee
				case "=" : return left[asig] = right;
				case "+=" : return left[asig] += right;
				case "-=" : return left[asig] -= Number(right);
				case "*=" : return left[asig] *= Number(right);
				case "/=" : return left[asig] /= Number(right);
			}
			return null;
		}
		
		private function removeEmptyStrings(ELEMENTS:Array):void
		{
			for(var e:int=0;e<ELEMENTS.length;e++)
				if(ELEMENTS[e].length == 0) 
					ELEMENTS.splice(e--,1);
		}
		
		private function findRootBit(bit:String, DEEP:int):Object
		{
			//trace("FIND ROOT BIT", bit, 'bit is arr?', bit is Array);
			var helper:Object;
			if(bit == 'this')
				return this;
			else if(bit == 'true')
				return true;
			else if(bit == 'false')
				return false;
			else if(bit == 'null')
				return null;
			else if(rootObj.hasOwnProperty(bit))
			{
				//trace('root is bit');
				return  rootObj[bit];
			}
			else 
			{
				// THIS WILL RETURN STRING IF IT"S NOT A CLASS
				try { helper = getDefinitionByName(bit) }
				catch(e:Error) { 
					//trace("root is not a class");
					return bit }
			}
			return null;
		}
		
		private function revHash(indx:int, caller:Object=null, DEEP:int=0):Object
		{
			//trace("REV HASH", indx, caller, DEEP);
			var dehashed:Object = loopStructure(HASH_BRACKETS[indx], DEEP+1);
			//trace("REV HASHed", indx, caller, DEEP);
			return dehashed;
		}
		/////// features 
		
		public function trrace(...args):int
		{
			if(LIVE)
				return 0;
			if(regularTrace)
				trace.apply(null,args);
			var v:Object;
			var s:String='';
			for(var i:int = 0; i < args.length; i++)
			{
				v = args[i];
				if(v == null)
					s += 'null';
				else if(v is String)
					s += v;
				else if(v is XML || v is XMLList)
					s += v.toXMLString();
				else
					s += v.toString();
				if(args.length - i > 1)
					s += ' ';
			}
			s += '\n';
			console.appendText(s);
			externalTrace(s);
			
			console.scrollV = console.maxScrollV;
			if(this.parent)
				this.parent.setChildIndex(this, this.parent.numChildren-1);
			v=null;
			return s.length;
		}
		
		public function setExternalTrace(funcName:String=null):void
		{
			if(LIVE)
				return;
			EXTERNAL_JS = funcName;
		}
		
		private function externalTrace(v:String):void
		{
			if(EXTERNAL_JS && ExternalInterface.available)
				ExternalInterface.call(EXTERNAL_JS,v);
		}
		
		////////////////////////// helpers
		
		
		public function dsp(a:Object, t:String=''):String
		{
			//trace(a);
			if(LIVE)
				return null;
			if(!a)
				return null;
			var s:String = t + a.toString();
			
			if(a is Object)
			{
				for (var ss:String in a)
				{
					s += '\n' + t  +ss + ' : ' + dsp(a[ss], t + '\t');
					/*if(a[ss] is Object)
					s+= */
				}
			}
			return s;
		}	
		
		public function desc(a:Object=null):void
		{
			if(LIVE)
				return;
			this.trrace(flash.utils.describeType(a));
		}
		
		public function get pool():Object
		{
			if(LIVE)
				return null;
			return _pool;
		}
	}
}
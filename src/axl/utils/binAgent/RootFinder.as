/**
 *
 * AXL Library
 * Copyright 2014-2015 Denis Aleksandrowicz. All Rights Reserved.
 *
 * This program is free software. You can redistribute and/or modify it
 * in accordance with the terms of the accompanying license agreement.
 *
 */
package axl.utils.binAgent
{
	import flash.display.DisplayObject;
	import flash.utils.getDefinitionByName;
	
	public class RootFinder
	{
		private var opchars:Vector.<String> = new <String>['+','-','*','/','%','=','<','>','|','&','!','?',':', S_IS]
		private var hierarchy:Vector.<Vector.<String>> =new <Vector.<String>> [
			new <String>['*','/','*=','/=','!','%', '%='],
			new <String>['+','-','+=','-='],
			new <String>['<','<=','>','>=', '<<','>>','==','===','!=', '!==', S_IS], 
			new <String>['?', ':', '||','&&'],
			new <String>['=']
		];
		private var asignments:Vector.<String> = new <String>['=','+=','-=','*=','/=','%='];
		private var oneSiders:Vector.<String> = new <String>['!', '++', '--'];
		private var allOperations:Vector.<String> = new Vector.<String>();
		private var mathLevelDict:Object = {}
		private var numMathLevels:int = hierarchy.length;
		private var numAllOperations:int;
		private var S_NEW:String = '®';
		private var S_IS:String = '¬';
		private var S_NULL:String = "•";
		private var hString:String = 'µ';
		private var hSquare:String = '‡';
		private var hRound:String = '©';
		private var hCurl:String = 'ƒ';
		private var hashSymbols:Array = [S_IS,S_NEW, hString, hSquare, hRound, hCurl];
		private var hashedStrings:Vector.<String> = new Vector.<String>();
		private var hashedSquares:Vector.<String> = new Vector.<String>();
		private var hashedRounds:Vector.<String> = new Vector.<String>();
		private var hashedCurl:Vector.<String> = new Vector.<String>();
		private var numStrings:int=0;
		//oper
		private var original:String;
		private var current:Object;
		public const errorUnmatchedString:Error = new Error("Unmatched String!",1);
		public const errorUnmatchedBrackets:Error = new Error("Unmatched bracket, curly bracket or square bracket!", 2);
		public const errorSyntax:Error = new Error("bad syntax?", 4);
		private var errorInvalidObject:Error = new Error("Invalid Object to create?");
		private var errorMaxClassArguments:Error = new Error("This software supports up to 10 constructor arguments");
		private var errorInvalidClassArgument:Error = new Error("Null class argument?");
		private var userRoot:Object;
		private var consoleRoot:Object;
		private var binApi:Object;
		public var currentResult:Object;
		private var errorOperands:Error = new Error("Invalid logic operator");
		private var consoleResult:Result = new Result();
		
		
		public function get userInputRoot():Object {  return consoleRoot }
		
		public function RootFinder(userRoot:DisplayObject, api:Object)
		{
			this.userRoot = userRoot;
			binApi = api;
			build_hierarchy();
		}
		
		public function changeContext(v:Object):void { this.userRoot = v ? v : this.userRoot }
		private function build_hierarchy():void
		{
			var levelLength:int;
			allOperations
			for(var i:int = 0; i < numMathLevels; i++)
			{
				levelLength = hierarchy[i].length;
				for(var j:int = 0; j < levelLength; j++)
				{
					allOperations[numAllOperations++] = hierarchy[i][j];
					mathLevelDict[hierarchy[i][j]] = i;
				}
			}
		}
		/** Parses input string and returns evealuated result. 
		 * <br>Supported operations: 
		 * <ul><li>
		 * Returning Classes, its instances, public methods, properties and its values</li>
		 * <li>Type casting, asignments, negations, concatenation, mathematical operations with it's order, nesting in parentheses</li>
		 * <li>Creating new Objects, Arrays and instances of any Classes</li>
		 * <li>Basic conditionals with ternary operator (both true and false are evauated! only right one is returned)</li>
		 * </ul>
		 * Does <b>not</b> support: 
		 * <ul>
		 * <li>creating functions</li>
		 * <li>if-else-if and switch blocks</li>
		 * <li>for-do-while loops</li>
		 * <li>in-de-crementation</li>
		 * </ul>
		 * */
		public function parseInput(text:String):Object
		{
			//trace('---input:',text);
			consoleRoot =userRoot;
			hashedStrings.length= hashedSquares.length = hashedRounds.length = hashedCurl.length=  numStrings =0;
			current = hashStrings(text);
			//trace('strings hashed:\n', current);
			if(current is Error)
				return current;
			current = hashIs(current as String);
			current = hashNew(current as String);
			//trace('is cleared:', current);
			current = hashBrackets(current as String);
			//trace('--brackets hashed/ all hashed:\n', current);
			if(current is Error)
				return current;
			current = loop(current as String);
			//trace('---output:',current);//flash.utils.describeType(current));
			currentResult = current;
			return current;
		}
		
		private function loop(cur:String):Object
		{
			//trace('loop', cur);
			if(cur==null) return null;
			return parseArguments(cur.split(','));
		}
		
		private function parseArguments(main:Array):Object
		{
			var len:int = main.length;
			var result:Array = [];
			//trace('parseArguments ('+ len +'):', main);
			for(var i:int = 0; i < len; i++)
			{
				var help:* = parseArgument(main[i]);
				if(help is Error)
					return help;
				else
					result.push(help);
			}
			//trace('allArgumentsParsed('+ len +'):', result);
			if(len > 1)
				return result
			else
				return result.pop()
		}
		
		private function parseArgument(arg:String, doParseOperations:Boolean=true):*
		{
			//trace(doParseOperations ? '  arg' : '   dot', arg);
			var help:* = readyTypeCheck(arg);
			if(help != null)
			{
				//trace('  <readyType!:', help);
				if(help is String && help == S_NULL)
					help = null;
				return help;
			}
			else if(doParseOperations)
			{
				//trace('  <not ready type. parsing Operations',arg);
				help = parseOperations(arg);
			}
			return help;
		}
		
		private function parseOperations(argument:String):*
		{
			//trace('    ||||||parseOperations', argument);
			var q:int = argument.indexOf('?');
			var argLeft:String;
			if(q > -1)
			{
				argLeft = argument.substr(q+1);
				argument = argument.substr(0,q);
			}
			var rawElements:Array =[];
			var liveElements:Array = [];
			var numOperations:int;
			// reading math operators
			for(var charIndex:int = 0; charIndex < argument.length; charIndex++)
			{
				var char:String = argument.charAt(charIndex);
				var mathOperIndex:int = opchars.indexOf(char, 0); // check if its a special char
				var operatorLength:int = 0;
				while(mathOperIndex > -1)
				{
					mathOperIndex = opchars.indexOf(argument.charAt(charIndex++ + ++operatorLength));
				}
				//trace('     ', mathOperIndex,'/', opchars.length, '|', char, "OPERATOR LEN", operatorLength);
				if(operatorLength >0)
				{
					numOperations++;
					if(charIndex!=operatorLength)
						rawElements.push( argument.substr(0, charIndex-operatorLength)); // bit before operation
					var center:String=  argument.substr(charIndex-operatorLength,operatorLength);
					//trace('center', center, "("+center.length+")/pos", mathLevelDict[center]);
					while(mathLevelDict[center] == null)
					{
						center = center.substr(0,-1); // cropping too long operators
						if(--operatorLength < 1) return this.errorOperands;
						charIndex--;
						//trace('new center', center, 'ol', operatorLength);
					}
					rawElements.push(center); // operation bit itself
					//trace('arg before crop', argument, '||index', charIndex );//'i-ol', i-ol, 'charati+ol', arg.charAt(i-ol));
					argument = argument.substr(charIndex);
					//trace('arg after crop', argument);
					charIndex=-1
				}
			}
			//trace("MY LIVE STUFF", rawElements);
			rawElements.push(argument); // leftovers
			var len:int = rawElements.length;
			//trace('    Making elements live');
			for(charIndex = 0; charIndex < len; charIndex++)
			{
				var help:*
				if(rawElements[charIndex] == null) // edges of ++x ; i--
					return new Error("Wrong argument parsing");
				else
				{
					if(opchars.indexOf(rawElements[charIndex].charAt(0)) > -1)
					{
						//trace('skiping due to math', rawElements[charIndex]);
						//here operands are being put as live elements + - * = 
						liveElements[charIndex] = rawElements[charIndex];   /////////// placing [+][-]
						continue;
					}
					else
					{
						if(!isNaN(rawElements[charIndex]))
							help = new Result([Number(rawElements[charIndex])], [rawElements[charIndex]]);
						else
							help = parseDots(rawElements[charIndex].split('.'),true); ////////// <<<<<<<<< PARSING DOTS
						if(help is Error) return help;
						if(help == null) 
							return new Error("Undefined " + rawElements[charIndex] + " reference");
						else liveElements[charIndex] = help;
					}
				}
			}
			
			//trace("walk through to look for negat posit)");
			var p:* = liveElements[0],ll:int = liveElements.length, c:*, n:*, e:*, s:int=3;
			if(p is String)
			{
				if(p.match(/(\+|\-|\!)/) && ll > 1 )
				{
					e = liveElements[i+1];
					e.chain = (p == '!' ? [!e.chain.pop()] :  [Number(String(p + e.chain.pop()))]);
					e.text = [String(e.chain[0])];
					liveElements.splice(0,2,e);
					ll--;
				}
				else
					return this.errorOperands;
			}
			for(var i:int = 0; i < ll -2; i++)
			{
				p = liveElements[i];
				c = liveElements[i+1];
				n = liveElements[i+2];
				
					if(c is String && n is String)
					{
						if((i+s) >= liveElements.length)
							return this.errorOperands;
						e = liveElements[i+s];
						if(e is Result)
						{
							if(n.match(/(\+|\-|\!)/))
							{
								e.chain = (n == '!' ? [!e.chain.pop()] :  [Number(String(n + e.chain.pop()))]);
								e.text = [String(e.chain[0])];
								liveElements.splice(i+s-1,2,e);
								--ll;
								--i;
							}
						}
					}
			}
			numOperations =0, i= 0, ll = liveElements.length;
			for(; i < ll; i++)
				if(liveElements[i] is String)
					numOperations++;
				
			if(numOperations == 0) // if there are no operations
			{
				//trace('      no operations, return single live element, last of the chain');
				
				//trace('    level one:', help);//, '\n\n', describeType(help).toXMLString());
				help = liveElements.pop();
				if(help is Result)
					help =help.chain.pop();
				//trace('    level two:\n\n', describeType(help).toXMLString());
			}
			else
			{
				//trace('      ', numOperations, 'operations to validate and perform on', liveElements);
				// this should fold to a single argument
				help = performChainOperations(liveElements);
			}
			//trace("RETURN", help, q > -1);
			if(q >-1)
			{
				q = argLeft.indexOf(':');
				if(q < 0)
					return errorOperands;
				argument = argLeft.substr(0,q);
				argLeft = argLeft.substr(q+1);
				help = help ? parseOperations(argument) : parseOperations(argLeft);
			}
			//trace("FINALLY", help);
			return help
		}
		
		private function performChainOperations(liveElements:Array):*
		{
			//steps to do: validate wrong operations
			//perform one side operations
			//rearange order according to math rules
			// sumarize everything
			//trace(opchars);
			//trace("chain operations on ", liveElements.length, 'live elements:', liveElements);
			var len:int = liveElements.length;
			var help:*;
			var shelp:*;
			var mle:Number;
			var breakNow:Boolean = false;
			for(var ml:int=0; ml < numMathLevels; ml++)
			{
				//trace("MATH level:::::::::: ", hierarchy[ml]);
				for(var i:int = 0; i < liveElements.length; i++)
				{
					
					
					help = liveElements[i];
					if(help is Error) return help // dunno why but still
					if(!(help is String)) continue; // only operations ar of our interest
					mle = mathLevelDict[help];
					if(isNaN(mle)) return errorOperands;
					if(mle > ml) continue;
					try { shelp = operate(liveElements, i) } catch(e:*) { shelp = e}  ///////// <<< MATH/LOGIC
					if(shelp is Error) return shelp;
					liveElements = shelp;
					if(liveElements.length == 1) 
					{ 
						breakNow = true;
						break;
					}
					i--;
					//trace("AFTER OPERATION CAN WE CUT?", liveElements.length);
				}
				if(breakNow) break;
			}
			/*isOneSide = oneSiders.indexOf(ope);
			isAsignment = asignments.indexOf(ope);*/
			//trace('at the end', liveElements);
			if(liveElements.length > 1)
				return errorOperands;
			else
			{
				help =  liveElements.pop();
				if(help is Result)
					return Result(help).chain.pop();
				else
					return help;
			}
		}
		
		private function operate(liveElements:Array, i:int):*
		{
			
			//trace("OPERATE", i,'@', liveElements);
			var oper:String = liveElements[i];
			var isAsignment:Boolean = asignments.indexOf(oper) > -1;
			var deleteCount:int = (oneSiders.indexOf(oper) > -1) ? 1 : 2;
			var np:int;
			var right:* = (i+1 < liveElements.length) ? liveElements[i+1] : null;
			var left:* = (i > 0) ? liveElements[i-1] : null;
			if(right != null)
			{
				var rc:Array = right.chain;
				var rci:int = rc.length-1;
			}
			if(left != null)
			{
				var lc:Array = left.chain;
				var lci:int = lc.length-1;
				if(isAsignment)
				{
					var lastText:String = Result(left).text[left.text.length-1];
					//trace("ASIGNMENT TEXT", left.text);
				}
			}
			var help:*;			
			//trace('left				is 			', left, left is Result ? left.chain : '');
			//trace('math				is			', oper);
			//trace('right				is			', right, right is Result ? right.chain : '');
			switch(oper)
			{
				case '!': rc[rci] = !rc[rci]; break;
				case '+': lc[lci] = lc[lci] + rc[rci]; break;
				case '-': lc[lci] = lc[lci] - rc[rci]; break;
				case '*': lc[lci] = lc[lci] * rc[rci]; break;
				case '/': lc[lci] = lc[lci] / rc[rci]; break;
				case '%': lc[lci] = lc[lci] % rc[rci]; break;
				case '>': lc[lci] = lc[lci] > rc[rci]; break;
				case '<': lc[lci] = lc[lci] < rc[rci]; break;
				case '<=': lc[lci] = lc[lci] <= rc[rci]; break;
				case '>=': lc[lci] = lc[lci] >= rc[rci]; break;
				case '>>': lc[lci] = lc[lci] >> rc[rci]; break;
				case '<<': lc[lci] = lc[lci] << rc[rci]; break;
				case '==': lc[lci] = lc[lci] == rc[rci]; break;
				case '===': lc[lci] = lc[lci] === rc[rci]; break;
				case '&&': lc[lci] = lc[lci] && rc[rci]; break;
				case '||': lc[lci] = lc[lci] || rc[rci]; break;
				case '+=': lc[lci] = lc[lci-1][lastText] += rc[rci]; break;
				case '-=':  lc[lci] = lc[lci-1][lastText] -= rc[rci]; break;
				case '*=': lc[lci] = lc[lci-1][lastText] *= rc[rci]; break;
				case '/=':  lc[lci] = lc[lci-1][lastText] /= rc[rci]; break;
				case '%=':  lc[lci] = lc[lci-1][lastText] %= rc[rci]; break;
				case '=': lc[lci-1][lastText] = rc[rci]; break;
				case S_IS: lc[lci] = lc[lci] is rc[rci]; break;
			}
			liveElements.splice(i, deleteCount);
			//trace('leftover', liveElements, "("+liveElements.length+")");
			return liveElements;
		}
		
		private function parseDots(main:Array,returnChain:Boolean):*
		{
			
			var mainWithHashes:Array = [];
			var textual:Array = [];
			var chain:Array = [];
			var mlen:int = main.length;
			var mwhlen:int;
			var help:*;
			var prev:*;
			
			var isNewObject:Boolean = (main[0].charAt(0) == S_NEW);
			if(isNewObject)
				main[0] = main[0].substr(1);
			//trace('   parseDots ('+ mlen +'):', main);
			//trace('   >dirty class check');
			
			mlen =  main.length;
			var bit:String;
			for(var i:int = 0; i < mlen; i++)
			{
				help = checkForHashes(main[i], mainWithHashes)
				if(help is Error) return help; // no mercy
				if(help != null) 
					mainWithHashes.push(help);// leftovers
			}
			//trace("     MAIN with hashes",mainWithHashes);
			
			help = dirtyClassCheck(mainWithHashes);
			//trace("dirty classCheck result", help, 'from', main);
			if(help != null)
			{
				//trace('dirty paid', help);
				mainWithHashes = mainWithHashes.slice(help.pop());
				mainWithHashes[0] = help.pop();
				chain[0] = help.pop();
				textual[0] = mainWithHashes[0];
				//trace("now main is ", main, 'and chain is ', chain);
			}
			// ! REVERSING HASHES ! //
			var chainLen:int = chain.length;
			mwhlen = mainWithHashes.length;
			for(i = chainLen; i < mwhlen; i++)
			{	
				
				if(chainLen > 0)
				{
					if (mainWithHashes[i] is Error)
					{
						consoleRoot = chain[i-1];
						return mainWithHashes[i]; // bad dots
					}
					prev = chain[i-1];
					help = isHash(mainWithHashes[i]);
					if(help is Error) 
						return help;
					//trace('    >checking on prev of chain:', prev, '<-[' + help + ']-/',mainWithHashes[i].length);
					textual[i] = help;
					if(prev is Function)
					{
						//trace("   {} FUNCTION EXEC {}:", prev, 'ARGUMENTS(s)', help, help is Array ? '('+help.length+')' : '');
						try {
							if(help is Array)
							{
								var shelp:*;
								//trace("MULTI ARG");
								try { shelp = prev.apply(null, help) } catch(e:*) { shelp = e}
								if(shelp is Error)
									try { shelp =prev(help) } catch (e:*) {shelp = e}
								help = shelp
								//trace("DONE?", help);
							}
							else if(help == null)
								help = prev();
							else if(mainWithHashes[i].charAt(0) == hRound)
								help = prev(help);
							else help = prev[help]
						} 
						catch(e:*) { help = e }
					}
					else if(prev is Class)
					{
						//trace("prev is class. prev prev?", i-2 >= 0 ? chain[i-2] : 'eee help?',help);
						if(help is Array)
							try { help = classMultiCast(prev, help,isNewObject) } catch(e:*) { help = e }
						else if(help == null)
						{
							//trace('help is null');
							if(mainWithHashes[i].charAt(0) == hRound)
								try{help = isNewObject ? new prev() : prev() } catch(e:*) {help = e}
							else
								help = errorInvalidClassArgument;
						}
						else {
							//trace('help is either constructor argument or static method/property. arg:?');
							if(mainWithHashes[i].charAt(0) == hRound)
								try{help = isNewObject ? new prev(help) : prev(help)} catch(e:*) {help = e}
							else
								try{help = prev[help]} catch(e:*) {help = e}
						}
					}
					else
					{
						try { help = chain[i-1][help] } catch(e:*){help = e}
					}
					consoleRoot = prev;
					if(help is Error) return help;
					//trace('prev class', prev, 'resolved as', help);
					chain[chainLen++] = help;
				}
				else // FIRST OF THE CHAIN  ! ! ! !
				{// attention! live objects being passed to parseArguments?
					//trace('    ->checking as first of chain',  mainWithHashes[i], 'out of', mainWithHashes.length);
					//as first it doesnt go as here, if its null, its an error?
					help = isHash(mainWithHashes[i]);
					textual[0] =help;
					if(help is Error) 
					{
						if(mlen > 1) consoleRoot = null;
						return help;
					}
					if(help == mainWithHashes[i])
					{
						//trace("  ->->reparsing argument?");
						help = parseArgument(mainWithHashes[i],false);
						//trace("  <-<-", help, help is Error || help == null);
						if(help is Error || help == null)
						{
							if(mlen > 1) consoleRoot = null;
							return help;
						}
						chain[chainLen++] = help;
					}
					else
						chain[chainLen++] = help;
					consoleRoot = chain[chainLen-1];
					//trace('    <-got it as', chain[chainLen-1]);
				}
			}
			//trace("CHAIN OK", chain, 'while main with hashes', mainWithHashes,'\nTEXTUAL', textual);
			return  new Result(chain, textual);
		}
		/** returns either null or array [Class, packageString, index of last Keyword*/
		private function dirtyClassCheck(main:Array):*
		{
			if(main == null || main.length == 0)
				return new Error("Dirty class check should have at list one dot");
			var c:Class;
			var t:String = main[0]; // 
			var l:int = main.length;
			var success:Boolean;
			for(var i:int = 1;i<l;i++)
			{
				t += '.' + main[i];
				//trace("DIRTY CHECK:", t);
				try { c= flash.utils.getDefinitionByName(t) as Class }
				catch(e:*){ /* uuu! how dirty am I! */}
				if(c is Class) return [c,t,i];
			}
			return null;
		}
		
		private function classMultiCast(classObject:Class, args:Array, newObject:Boolean):*
		{
			//trace('classMultiCast');
			var al:int = args.length;
			if(newObject)
			{
				switch(al)
				{
					case 0 : return new classObject();
					case 1 : return new classObject(args[0]);
					case 2 : return new classObject(args[0],args[1]);
					case 3 : return new classObject(args[0],args[1],args[2]);
					case 4 : return new classObject(args[0],args[1],args[2],args[3]);
					case 5 : return new classObject(args[0],args[1],args[2],args[3],args[4]);
					case 6 : return new classObject(args[0],args[1],args[2],args[3],args[4],args[5]);
					case 7 : return new classObject(args[0],args[1],args[2],args[3],args[4],args[5],args[6]);
					case 8 : return new classObject(args[0],args[1],args[2],args[3],args[4],args[5],args[6],args[7]);
					case 9 : return new classObject(args[0],args[1],args[2],args[3],args[4],args[5],args[6],args[7],args[8]);
					case 10: return new classObject(args[0],args[1],args[2],args[3],args[4],args[5],args[6],args[7],args[8],args[9]);
				}
				
			}
			else
			{
				if(al == 0) return classObject();
				if(al == 1) return classObject(args[0]);
				if(al == 2) return classObject(args[0],args[1]);
				if(al == 3) return classObject(args[0],args[1],args[2]);
				if(al == 4) return classObject(args[0],args[1],args[2],args[3]);
				if(al == 5) return classObject(args[0],args[1],args[2],args[3],args[4]);
				if(al == 6) return classObject(args[0],args[1],args[2],args[3],args[4],args[5]);
				if(al == 7) return classObject(args[0],args[1],args[2],args[3],args[4],args[5],args[6]);
				if(al == 8) return classObject(args[0],args[1],args[2],args[3],args[4],args[5],args[6],args[7]);
				if(al == 9) return classObject(args[0],args[1],args[2],args[3],args[4],args[5],args[6],args[7],args[8]);
				if(al ==10) return classObject(args[0],args[1],args[2],args[3],args[4],args[5],args[6],args[7],args[8],args[9]);
			}
			return errorMaxClassArguments;
		}
		
		private function isHash(bit:String):Object
		{
			var char:String = bit.charAt(0);
			var hi:int = hashSymbols.indexOf(char);
			if(hi < 0) return bit;
			var symbol:String = hashSymbols[hi];
			hi = bit.indexOf(symbol,1);
			if(hi < 0) return bit;
			if(bit.length -1 != hi) return errorSyntax;
			var indexS:Number = Number(bit.substring(1,hi));
			if(isNaN(indexS)) return errorSyntax;
			var i:int = int(indexS)
			var help:*;
			switch (symbol)
			{
				case hString:
					//trace("DE-HASH STRING");
					return hashedStrings[i];
				case hCurl:
					//trace("DE-HASH OBJECT CREATION");
					return createObject(hashedCurl[i]);
				case hRound:
					//trace("DE-HASH ( ) looping");
					if(hashedRounds[i].length == 0) return null;
					help = loop(hashedRounds[i]);
					//trace("DE-HASH () RESULT:", help);
					return help;
				case hSquare:
					//trace("DE-HASH [ ] looping");
					help = createArray(hashedSquares[i]);
					//trace("DE-HASH [] RESULT:", help);
					return help;
				default:
					//trace("UNINDENTIFIED HASH", bit);
					return bit;
					
			}
		}
		
		private function createArray(input:String):*
		{
			//trace('creating array from', input);
			var props:Array = input.split(',');
			var plen:int = props.length;
			var output:Array= [];
			var help:*;
			for(var i:int = 0; i < plen; i++)
			{
				help = parseArgument(props[i]);
				if(help is Error) return help;
				output[i] = help;
			}
			return output;
		}
		
		private function createObject(input:String):*
		{
			var props:Array = input.split(',');
			var plen:int = props.length;
			var output:Object = {};
			var k:String;
			var v:*;
			for(var i:int = 0; i < plen; i++)
			{
				var kv:Array = props[i].split(':');
				if(kv.length == 1 && kv[0].length == '') continue; // empty object
				if(kv.length != 2) return errorInvalidObject;
				k = kv[0], v = parseArgument(kv[1]);
				if(v is Error) return v;
				k = isHash(k) as String;
				if(k == null)
					return errorInvalidObject;
				output[k] = v;
			}
			return output;
		}
		
		private function checkForHashes(chunk:String, resultsTo:Array):Object
		{
			//trace(" <> incoming chunk <> ", chunk, '('+chunk.length+')');
			if(chunk.length < 1) return errorSyntax;
			var hi:int, char:String, pair:int, left:String;
			for(var i:int= 0; i < chunk.length; i++)
			{
				char = chunk.charAt(i);
				hi = hashSymbols.indexOf(char);
				if(hi> -1)
				{
					//trace('found hash', hashSymbols[hi], 'at', i);
					if(i > 0)
					{
						left = chunk.substr(0,i);
						resultsTo.push(left);
					}
					chunk = chunk.substr(i);
					//trace('after crop:', chunk);
					pair = chunk.indexOf(hashSymbols[hi], 1);
					//trace("pair", pair);
					if(pair < 0) return errorSyntax;
					left = chunk.substr(0, pair+1);
					resultsTo.push(left);
					chunk = chunk.substr(pair+1);
					//trace('after 2 crop', chunk);
					i=-1;
				}
			}
			return (chunk.length > 0) ? chunk : null;
		}
		
		private function readyTypeCheck(arg:String,tryUserRoot:Boolean=true):*
		{
			// trace('[*]readyTypeCheck[*]', arg);
			if(!isNaN(Number(arg))) return Number(arg)
			else if(arg == 'true' || arg == 'false') return (arg == 'true')
			else if(arg == 'this') return userRoot;
			else if(arg == 'null') return S_NULL;
			else if(arg == 'trace') return Object(trace);
			else if(arg == '@') return binApi;
			else
			{
				var help:*;
				try { help = getDefinitionByName(arg) as Class} catch (e:*) {}
				if(help is Class) return help as Class;
				else if(tryUserRoot)
				{
					//trace("TRYING USER ROOT PROPERTY", userRoot,'?', help);
					try { help = userRoot[arg] } catch (e:*) {}
					return help;
				}
				else return null;
			}
		}
		
		private function hashBrackets(text:String):Object
		{
			var o:Array = ['[', '(', '{'];
			var e:Array = [']', ')', '}'];
			var h:Array = [hSquare, hRound, hCurl];
			var v:Array = [hashedSquares, hashedRounds, hashedCurl];
			//start bracket
			var s:int = text.indexOf(o[0]); 
			var r:int = text.indexOf(o[1]);
			var c:int = text.indexOf(o[2]);
			//trace("TEXT", text, 'src',s,r,c);
			var i:int =0;
			var startI:int = s, endI:int = 0;
			if(r>-1&&(r<startI || startI<0)) startI=r;
			if(c>-1&&(r<startI || startI<0)) startI=c;
			if(startI < 0) return text;
			if(startI == s) i=0;
			else if(startI == r)i=1;
			else if(startI == c) i=2;
			//end bracket
			var toAdd:int, l:int = text.length;
			for(endI=startI+1; endI < l;endI++)
			{
				if(text.charAt(endI) == o[i])
					toAdd++;
				if(text.charAt(endI) == e[i])
					if(toAdd-- <1)
						break;
			}
			//trace(o[i], 's:', startI, 'e:', endI, '/', l);
			if(endI >= l) return errorUnmatchedBrackets;
			//hash
			var left:String = text.substr(0,startI);
			var center:String = text.substring(startI+1, endI);
			var right:String = text.substr(endI+1);
			var help:* = hashBrackets(center);
			if(help is Error) return help;
			s = v[i].length;
			text = left + h[i] + s + h[i] + right;
			v[i][s++] = help;
			return hashBrackets(text);
		}
		
		private function hashIs(s:Object):Object
		{
			/// replaces IS statement 
			s = s.replace(/\sis\s/g, S_IS);
			return s;
		}
		
		private function hashNew(s:Object):Object
		{
			/// replaces IS statement 
			s = s.replace(/(^|\s|=|\[|\(|\:)new\s/g, "$1" + S_NEW);
			/// clear space confusions
			s = s.replace(/\s/g,"").replace(/;$/, "");
			return s;
		}
		
		private function hashStrings(text:Object):Object
		{
			var single:String = "'";
			var double:String = '"';
			var i:int = text.indexOf(single);
			var j:int = text.indexOf(double);
			var leading:String;
			var startIndex:int = (j>-1)?(i>-1&&i<j?i:j):i;
			//trace("STRING IDS", i,j, startIndex);
			if(startIndex < 0) return text;
			leading = (startIndex == i ? single : double);
			var endIndex:int = text.indexOf(leading, startIndex+1);
			if(endIndex < 0) return errorUnmatchedString;
			var left:String = text.substr(0,startIndex);
			var center:String = text.substring(startIndex+1, endIndex);
			var right:String = text.substr(endIndex+1);
			text = left + hString + numStrings + hString + right
			hashedStrings[numStrings++] = center;
			return hashStrings(text);
		}
		
		public function findCareteContext(text:String, caretIndex:int):Object
		{
			original = text.substr();
			var schars:Array= [',','+', '-','=','*','\\','/','<','>','!','&','?',':', '%','"',"'",'|','(', '{','[',' '];
			var pairs:Object = { '[' : ']', '(' : ')', '{' : '}' }
			var sames:Array = ['"',"'"];
			var char:String;
			var cropped:String = text.substring(0, caretIndex);
			var key:String;
			var lastIndex:int = -1;
			var verseMatch:int = -1;
			var li:int;
			var help:*
			var li2:int;
			for(var i:int = schars.length; i-->0;)
			{
				li = cropped.lastIndexOf(schars[i]);
				if(li > lastIndex)
				{
					char = schars[i];
					if(cropped.lastIndexOf(pairs[char]) < li)
					{
						
						var ii:int = sames.indexOf(char);
						if((ii > -1))
						{
							li2 = cropped.indexOf(sames[ii]);
							if(li2 > -1 && li2 < li)
							{
								lastIndex = li2-1;
								verseMatch = li2;
							}
						}
						else
						{
							lastIndex = li;
							verseMatch = -1;
						}
					}
				}
			}
			cropped = cropped.substr(lastIndex+ (verseMatch > 0) ? 0 : 1);
			li = cropped.lastIndexOf('.');
			if(li > -1)
			{
				if(cropped.length > li)
					key = cropped.substr(li+1);
				cropped = cropped.substr(0,li)
			}
			help = this.parseInput(cropped);
			return { r : help is Error ? null : help, k: key };
		}
	}
}
internal class Result { 
	public var chain:Array;
	public var text:Array;
	public function Result(c:Array=null, t:Array=null) { chain = c, text = t }
}
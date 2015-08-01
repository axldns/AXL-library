package axl.utils.binAgent
{
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.ui.Keyboard;
	import flash.utils.describeType;

	public class BinAgent extends Console
	{
		private static var _instance:BinAgent;
		private var tfSyntax:TextFormat = new TextFormat('Lucida Console', 15,0xff0000,true);
		private var hintContainer:Sprite;
		private var selectedHint:Hint
		private var numHints:int=0;
		private var hintIndex:int;
		private var hHeight:int=20;
		private var hintTextFormat:TextFormat;
		private var curRoot:Object;
		private var curRootProps:Vector.<XMLList>;
		private var curRootCarete:int=0;
		private var rootDesc:XML;
		private var rootFinder:RootFinder;
		private var inputHeight:Number;
		private var inputWidth:Number;
		private var userRoot:DisplayObject;
		private var assist:Asist;
		private var maxHints:int = 10;
		private var prevText:String;
		private var miniHint:TextField;
		public var disableAsYouType:Boolean=true;
		public function BinAgent(rootObject:DisplayObject)
		{
				if(instance != null)
				{
					hintContainer = instance.hintContainer;
					userRoot = instance.userRoot;
					miniHint = instance.miniHint;
					hintContainer = instance.hintContainer;
					curRootProps = instance.curRootProps;
					rootFinder = instance.rootFinder;
					assist = instance.assist;
					curRoot = instance.curRoot;
				}
				else
				{
					_instance = this;
					hintContainer = new Sprite();
					hintContainer.addEventListener(MouseEvent.MOUSE_MOVE, hintTouchMove);
					hintContainer.addEventListener(MouseEvent.MOUSE_UP, hintTouchSelect);
					userRoot = rootObject;
					makeMiniHint();
					super(rootObject);
					this.addChild(hintContainer);
					curRootProps = new Vector.<XMLList>();
					hintIndex = 0;
					hintTextFormat = input.defaultTextFormat;
					Hint.hintWidth = 100;//input.width;
					Hint.hintHeight = 15;//hHeight;
					rootFinder =new RootFinder(rootObject, this);
					assist = new Asist();
					curRoot = userRoot;
				}
		}
		
		public static function get instance():BinAgent { return _instance }
		
		private function makeMiniHint():void
		{
			miniHint = new TextField();
			miniHint.border = true;
			miniHint.background = true;
			miniHint.backgroundColor = 0xEECD8C;
			miniHint.height = 17;
			miniHint.selectable = false;
			miniHint.mouseEnabled = false;
			miniHint.tabEnabled = false;
		}
		
		private function showMiniHint(v:XML, fname:String):void
		{
			
			var adds:String  = fname + '(';
			var params:XMLList = v.parameter;
			for(var i:int = 0, l:int = params.length(); i < l; i++)
			{
				adds += String(params[i].@type) + ', ';
				trace("ads", adds);
			}
			
			adds = adds.substr(0,-2) + ')';
			miniHint.text=  adds;
			miniHint.width= miniHint.textWidth + 5;
			miniHint.x = inputWidth - miniHint.width>>1;
			if(!contains(miniHint))
				addChild(miniHint);
		}
		
		private function hideMinihint():void
		{
			if(this.contains(miniHint))
				removeChild(miniHint);
		}
		protected function hintTouchMove(e:MouseEvent):void
		{
			if(numHints == 0 || !e.buttonDown) return;
			var mh:Hint = e.target as Hint;
			if(mh == null) return;
			if(selectedHint != null)
			{
				if(selectedHint == mh) return;
				else selectedHint.selected = false;
			}
			selectedHint = mh;
			selectedHint.selected = true;
		}
		
		protected function hintTouchSelect(e:MouseEvent):void
		{
			if(selectedHint !=null)
				chooseHighlightedHint();
			else selectedHint = e.target as Hint;
			if(selectedHint != null) selectedHint.selected = true;
		}
		
		private function addHint(v:XML):void
		{
			hintContainer.addChild(Hint.getHint(v));
		}
		
		private function removeHints():void
		{
			hintContainer.removeChildren();
			Hint.removeHints();
		}
		
		private function alignHints():void
		{
			Hint.alignHints();
			hintContainer.y = input.y - hintContainer.height;
		}
		
		override protected function align():void
		{
			super.align();
			inputWidth = input.width, inputHeight = input.height;
			Hint.hintWidth = inputWidth;
			maxHints = Math.floor((console.height / Hint.hintHeight) *.75);
			alignHints();
			miniHint.y = input.y - miniHint.height;
		}
		
		override protected function KEY_UP(e:KeyboardEvent):void
		{
			switch(e.keyCode)
			{
				case Keyboard.UP:
				case Keyboard.DOWN:
					if(Hint.numHints > 0) selectHint(e.keyCode);
					else super.showPast(e.keyCode);
					break;
				case Keyboard.ENTER:
					if(Hint.numHints > 0 && selectedHint != null) 
						chooseHighlightedHint();
					else super.enterConsoleText();
					removeHints();
					break;
				case Keyboard.TAB:
					if(Hint.numHints > 0) 
					{
						if(selectedHint == null)
							selectHint(Keyboard.UP);
						else
							chooseHighlightedHint();
					}
					break;
				default : asYouType();
					
			}
		}
		override protected function PARSE_INPUT(s:String):Object
		{
			return rootFinder.parseInput(s);
		}
		
		private function chooseHighlightedHint():void
		{
			//input.text += selectedHint.text;
			if(curRootCarete == 0)
				input.text =selectedHint.text;
			else
				input.text = input.text.substr(0, curRootCarete+1) + selectedHint.text;
			var itl:int = input.text.length;
			input.setSelection( itl, itl);
			removeHints();
			asYouType();
		}
		
		private function selectHint(keyCode:int):void
		{
			if(Hint.numHints == 0) return;
			hintIndex += (keyCode == Keyboard.UP ? -1 : 1);
			if(hintIndex < 0)
				hintIndex = Hint.numHints-1;
			if((hintIndex >= Hint.numHints) || (hintIndex < 0))
				hintIndex = 0;
			if(selectedHint != null)
			{
				if(selectedHint == Hint.atIndex(hintIndex))return;
				else selectedHint.selected = false;
			}
			selectedHint = Hint.atIndex(hintIndex);
			selectedHint.selected = true;
		}
		
		protected function asYouType():void
		{
			if(disableAsYouType)
				return
			//////// ---------------- prev ------------- /////////
			if(selectedHint != null)
				selectedHint.selected = false;
			selectedHint = null;
			var t:String = input.text;
			//if(prevText == t) return;
			var tl:int = t.length;
			removeHints();
			numHints = 0;
			//if(tl < 1) return;
			//trace('=========== as you type ===========');
			
			///////// ------------- define -------------------- ///////
			var result:Object = findCurRoot();
			var chain:Array;
			var textual:Array;
			if(result == null || !result.hasOwnProperty('chain'))
			{
				//trace("no root find", result);
				return;
			}
			else
			{
				chain = result.chain;
				textual = result.text;
			}
			var newRoot:Object = chain.pop();
			var newName:String = textual.pop();
			
			curRootCarete = t.lastIndexOf('.', input.caretIndex);
			if(curRootCarete < 0)
				curRootCarete = 0;
			if(true || newRoot != curRoot)
			{
				curRoot = newRoot;
			}
			if(input.caretIndex == 0)
				curRoot = userRoot;
			
			
			///////// ------------------ desc --------------------- ///////// 
			t = t.substring(curRootCarete > 0 ? curRootCarete+1 : 0);
			tl = t.length;
			//if(tl == 0) return;
			rootDesc = describeType(curRoot);
			//trace(rootDesc.toXMLString());
			
			if(curRoot is Function)
			{
				if(chain.length > 0)
				{
					showMiniHint(describeType(chain[chain.length - 1]).method.(@name == newName)[0], newName);
				}
				else
				{
					showMiniHint(rootDesc, newName);
				}
				
			}
			else
				hideMinihint();
			var additions:XMLList = assist.check(curRoot);
			if(additions is XMLList)
				for each (var x:XML in additions)
					rootDesc.appendChild(x);
			
			curRootProps[0] = rootDesc.accessor;
			curRootProps[1] = rootDesc.method;
			curRootProps[2] = rootDesc.variable;
			var n:String, i:int, l:int;
			for(var a:int = 0; a < curRootProps.length; a++)
			{
				l =  curRootProps[a].length();
				for(i = 0; i < l; i++)
				{
					n = curRootProps[a][i].@name;
					if(n.substr(0,tl) == t && tl < n.length)
					{
						addHint(curRootProps[a][i]);
						if(++numHints > maxHints)break;
					}
				}
			}
			alignHints();
			prevText = input.text;
		}
		
		private function findCurRoot():Object
		{
			return rootFinder.findCareteContext(input.text, input.caretIndex);
		}
	}
}
import flash.system.System;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.utils.getQualifiedClassName;

internal class Asist
{
	
	private var dict:Object = 
		{
			String : abstractString,
			Object : abstractObject
		}
	private var abstractString:Astring;
	private var abstractObject:Aobject;
	public function Asist()
	{
		abstractObject = new Aobject();
		abstractString = new Astring();
	}
	
	
	public function check(v:*):XMLList
	{
		if(v is String)
			return abstractString.all.children().copy();
		else if(v is Object)
			return abstractObject.all.children().copy();
		return null
	}
	
	public static function method(name:String, args:Array, returnType:Class, declaredBy:Class):XML
	{
		var xml:XML = <method/>;
		xml.@name = name;
		xml.@declaredBy = getQualifiedClassName(declaredBy);
		xml.@returnType = getQualifiedClassName(returnType);
		var i:int = 0, l:int = args.length;
		for(;i<l;i++)
			xml.appendChild(XML('<parameter type="'+getQualifiedClassName(args[i])+'"/>'));
		return xml;
	}
}

internal class Aobject {
	
	public var am:Function = Asist.method;
	public var all:XML;
	private var objectGeneric:Vector.<XML> = new Vector.<XML>();
	private var inherited:Vector.<XML>= new <XML>
		[ 
			am('hasOwnProperty', [String], Boolean, Object),
			am('isPrototypeOf', [Object], Object, Object),
			am('propertyIsEnumerable', [String], Boolean, Object),
			am('setPropertyIsEnumerable', [String, Boolean], null, Object),
			am('toLocaleString', [], String, Object),
			am('toString', [], String, Object),
			am('valueOf', [], Object, Object)
		];
	public function Aobject()
	{
		all = <additions/>;
		for(var i:int = 0, j:int = inherited.length; i<j;i++)
			all.appendChild(inherited[i])
		for(i= 0, j= generic.length; i<j;i++)
			all.appendChild(generic[i]);
	}
	public function get generic():Vector.<XML> { return objectGeneric} 
}

internal class Astring  extends Aobject {
	private var stringGeneric:Vector.<XML>= new <XML>
		[
			Asist.method('charAt', [Number], String, String),
			Asist.method('charCodeAt', [Number],String,String)
			
		];
	public function Astring() {	super(); }
	override public function get generic():Vector.<XML> { return stringGeneric} 
}

internal class Hint extends TextField
{
	private static var tfSelected:TextFormat = new TextFormat('Lucida Console', 11, 0xEECD8C);
	private static var tfIdle:TextFormat = new TextFormat('Lucida Console', 11, 0x333333);
	private static var liveHints:Vector.<Hint>= new Vector.<Hint>();
	private static var spareHints:Vector.<Hint> = new Vector.<Hint>();
	private static var nHints:int=0;
	private static var hWidth:Number = 30;
	private static var hHeight:int = 18;
	public static var maxPool:int =10;
	public static function get numHints():int { return nHints };
	
	public static function get hintWidth():Number { return hWidth }
	public static function set hintWidth(v:Number):void
	{
		if(hWidth == v) return;
		hWidth = v;
		for(var i:int = nHints; i-->0;)
			liveHints[i].width = v;
	}
	public static function get hintHeight():Number { return hHeight }
	public static function set hintHeight(v:Number):void
	{
		if(hHeight == v) return;
		hHeight = v;
		for(var i:int = nHints; i-->0;)
			liveHints[i].height = v;
	}
	public static function atIndex(v:int):Hint { return liveHints[v] }
	public static function getHint(v:XML):Hint
	{
		var spareAvailable:Boolean = (spareHints.length > 0);
		if(spareAvailable)
			liveHints[nHints++] = spareHints.pop();
		else
			new Hint();
		
		liveHints[nHints-1].parse(v);
		return liveHints[nHints-1];
	}
	public static function removeHints():void
	{
		spareHints = spareHints.concat(liveHints);
		while(spareHints.length > maxPool)
			spareHints.pop().destroy();
		liveHints.length = nHints = 0;
	}
	public static function alignHints():void
	{
		for(var i:int = numHints; i-->0;)
			liveHints[i].y = i * hHeight;
	}
	
	/// instance
	private var isSelected:Boolean;
	private var xdef:XML;
	private var parameters:XMLList;
	private var hname:String;
	private var htype:String;
	private var hvalue:String;
	private var fulltext:String;
	public function Hint()
	{
		reset();
		liveHints[nHints++] = this;
	}
	
	private function reset():void
	{
		var tf:TextField = this;
		tf.border = true;
		tf.height = hHeight;
		tf.width = hWidth;
		tf.wordWrap = true;
		tf.multiline = false;
		tf.type = 'dynamic';
		tf.background = true;
		tf.backgroundColor = 0xbbbbbb;
		tf.defaultTextFormat = tfIdle;
		tf.selectable =false;
	}	
	private function parse(v:XML):void
	{
		xdef = v;
		hname = v.@name;
		htype = v.name();
		fulltext = hname;
		switch(htype)
		{
			case 'accessor':
				parseAccesor(v);
				break;
			case 'method':
				parseMethod(v);
				hname += '(';
				break;
			case 'variable':
				parseVariable(v);
				break;
		}
		text = fulltext;
	}
	
	private function parseVariable(v:XML):void
	{
		fulltext += ' : ' + typeInfo(v);
	}
	
	private function parseMethod(v:XML):void
	{
		fulltext += '(';
		parameters = v.parameter;
		var l:int = parameters.length();
		var ptype:String;
		for(var i:int = 0; i < l; i++)
			fulltext += typeInfo(parameters[i]) + ', ';
		if(l > 0)
			fulltext = fulltext.substr(0,-2);
		fulltext += '):' + returnType(v);
	}
	
	private function classInfo(v:String):String { return v.replace(/.*::/,'') }
	private function typeInfo(v:XML):String { return classInfo(v.@type) };
	private function returnType(v:XML):String { return classInfo(v.@returnType) }
	
	private function parseAccesor(v:XML):void
	{
		fulltext += ' : ' + typeInfo(v) + ' (' + v.@access+')';
	}
	
	//	/public function set text(v:String):void { maintf.text =v }
	override public function get text():String { return hname }
	public function get selected():Boolean {return isSelected }
	public function set selected(v:Boolean):void
	{
		if(isSelected == v) return;
		isSelected = v;
		if(hname == null) return; // might be destroyed
		setTextFormat(v?tfSelected:tfIdle, 0, text.length);
		backgroundColor = v ? 0x888888 : 0xbbbbbb;
	}
	
	private function destroy():void{
		//maintf = null;//there will be more
		fulltext = hname = htype = hvalue = null, text = '';
		System.disposeXML(xdef);
		
	}
}

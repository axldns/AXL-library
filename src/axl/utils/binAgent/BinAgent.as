package axl.utils.binAgent
{
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.text.TextFormat;
	import flash.ui.Keyboard;
	import flash.utils.describeType;
	public class BinAgent extends Console
	{
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
		
		public function BinAgent(rootObject:DisplayObject)
		{
			hintContainer = new Sprite();
			hintContainer.addEventListener(MouseEvent.MOUSE_MOVE, hintTouchMove);
			hintContainer.addEventListener(MouseEvent.MOUSE_UP, hintTouchSelect);
			userRoot = rootObject;
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
			return rootFinder.find(s);
		}
		
		private function chooseHighlightedHint():void
		{
			trace("SELECTING HIGH");
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
			if(selectedHint != null)
				selectedHint.selected = false;
			selectedHint = null;
			var t:String = input.text;
			//if(prevText == t) return;
			var tl:int = t.length;
			removeHints(); //this need to verify root change
			numHints = 0;
			if(tl < 1) return;
			var newRoot:Object = findCurRoot();
			trace('=========== as you type ===========');
			trace("is it new root? c:", curRoot, 'n:', newRoot)
			
			curRootCarete = t.lastIndexOf('.', input.caretIndex);
			if(curRootCarete < 0)
				curRootCarete = 0;
			if(newRoot != curRoot)
			{
				trace('setting new root');
				curRoot = newRoot;
			}
			trace('midle time root', curRoot);
			if(input.caretIndex == 0)
				curRoot = userRoot;
			
			t = t.substring(curRootCarete > 0 ? curRootCarete+1 : 0);
			tl = t.length;
			trace('### to match' , t, '('+tl+') for: ', curRoot);
			//if(tl == 0) return;
			rootDesc = describeType(curRoot);
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
			var carete:int = input.caretIndex;
			var result:* = rootFinder.find(input.text);
			
			trace("CONSOLE",  rootFinder.userInputRoot);
			return rootFinder.userInputRoot;
		}
	}
}

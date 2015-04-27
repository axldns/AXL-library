package axl.utils.binAgent
{
	import flash.system.System;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	public class Hint extends TextField
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
				liveHints[i].setWidth(v);
		}
		public static function get hintHeight():Number { return hHeight }
		public static function set hintHeight(v:Number):void
		{
			if(hHeight == v) return;
			hHeight = v;
			for(var i:int = nHints; i-->0;)
				liveHints[i].setHeight(v);
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
		private var type:String;
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
			trace(v, tfSelected,tfIdle, text);
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
}
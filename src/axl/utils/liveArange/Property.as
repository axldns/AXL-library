/**
 *
 * AXL Library
 * Copyright 2014-2016 Denis Aleksandrowicz. All Rights Reserved.
 *
 * This program is free software. You can redistribute and/or modify it
 * in accordance with the terms of the accompanying license agreement.
 *
 */
package axl.utils.liveArange
{
	import flash.display.Sprite;
	import flash.system.System;
	import flash.text.TextField;
	import flash.text.TextFormat;
	/** 
	 * Class prepared to parse and modify single node of XML description of object defined as 
	 * <code>editor.subject</code> of this instance.<br>
	 * Contains two textfields: name & value.<br>
	 * Allows bi-directional update:
	 * <ul>
	 * <li><code>updateFromObjectToTextfield</code> - from object's actual value to this instance text input field</li>
	 * <li><code>updateFromTextfieldToObject</code> - from this instance text input field to actual object</li>
	 * </ul>
	 * Elements are parsed through JSON.parse if needed.</br>
	 * Class has no internal event listeners.
	 */
	public class Property extends Sprite
	{
		private static var tff:TextFormat;
		/** @see Property*/
		public function Property(editorInstance:EditorWindow,v:XML=null)
		{
			if(!tff)
			tff = new TextFormat("Arial",12,0xffffff);
			createTname();
			createTvalue();
			editor = editorInstance;
			if(v)parse(v);
		}
		private var pname:String;
		private var pvalue:String;
		private var type:String;
		private var tname:TextField;
		private var tvalue:TextField;
		private var fwidth:Number = 120;
		public var editor:EditorWindow;
		private var balance:Number=0.5;
		
		/** Parses single XML property (accessor or variable) to update name / value textfields */
		public function parse(v:XML):void
		{
			if(!editor)
				return;
			tname.text = pname = v.@name;
			type = v.@type;
			if(type != "Object")
				tvalue.text = String(editor.subject[pname]);
			else
				tvalue.text = JSON.stringify(editor.subject[pname]);
			switch(type)
			{
				case 'int':
					tvalue.restrict = '0-9';
					break;
				case 'Number':
					tvalue.restrict = '0-9 .';
					break;
				case 'Boolean':
					tvalue.restrict = 'truefalse';
					break;
				default:
					tvalue.restrict = null;
			}
			flash.system.System.disposeXML(v);
			v = null;
		}
		// --- BUILD SECTION --- //
		private function createTname():void
		{
			var t:TextField = createTf();
			tname = t;
			tname.selectable = false;
			addChild(tname);
		}
		private function createTvalue():void
		{
			var t:TextField = createTf();
			tvalue = t;
			tvalue.type= 'input';
			tvalue.x = tname.x + tname.width;
			addChild(tvalue);
		}
		
		private function createTf():TextField
		{
			var t:TextField = new TextField();
			t.border = true;
			t.width = fwidth/2;
			t.height = 17;
			t.defaultTextFormat = tff;
			return t;
		}
		// --- END OF BUILD SECTION --- //
		// --- MECHANIC AND API SECTION --- //
		/**
		 * Updates  input field<--from--edited--object.
		 * Strings and XML objects are casted, everything else
		 * goes through JSON.parse
		 */
		public function updateFromObjectToTextfield():void
		{
			if(tvalue.stage && tvalue.stage.focus != tvalue)
			{
				if(type != "Object")
					tvalue.text = String(editor.subject[pname]);
				else
					tvalue.text = JSON.stringify(editor.subject[pname]);
			}
		}
		
		/**
		 * Applies value from--input--field--to--> edited object.
		 * Strings and XML objects are casted, everything else
		 * goes through JSON.parse
		 */
		public function updateFromTextfieldToObject():void
		{
			switch(type)
			{
				case "String":
					editor.subject[pname] = tvalue.text;
					break;
				case "XML":
					editor.subject[pname] = XML(tvalue.text);
					break;
				default:
					try {
						var val:* = JSON.parse(tvalue.text);
						editor.subject[pname] = val;
					}
					catch(e:*) {trace("updateToUserInput FAIL",e);}
					break;
			}
		}
		/** sets width balance between name and value fields (0-1)*/
		public function updateBalance(n:Number):void
		{
			balance = n;
			tname.width = fwidth * balance;
			tvalue.width = fwidth * (1-balance);
			tvalue.x= tname.x + tname.width;
		}
		/** adjusts fields height to display all contained text*/
		public function expand():void
		{
			tname.wordWrap = tvalue.wordWrap = tvalue.multiline = tname.multiline =  true;
			var h:Number = 5+ (tname.textHeight > tvalue.textHeight ? tname.textHeight : tvalue.textHeight);
			tname.height = tvalue.height = h;
		}
		/** folds down fields to its initial height, does not wrap words, no multiline neither*/
		public function deflate():void
		{
			tname.wordWrap = tvalue.wordWrap = tvalue.multiline = tname.multiline =  false;
			tname.height = tvalue.height = 17;
		}
		/** allows to in/de-crement numeric or to set oposite boleans values*/
		public function keyAction(dir:int):void
		{
			var nw:String;
			var cw:String =tvalue.text;
			switch(type)
			{
				case 'Number':
					 nw = String(Number(cw) + 1 * dir);
					 break;
				case "uint":
					nw = String(uint(cw) + 1 * dir);
					break;
				case "int":
					nw = String(int(cw) + 1 * dir);
					break;
				case 'Boolean':
					nw = String(!editor.subject[pname]);
					break;
			}
			if(nw)
			{
				tvalue.text = nw;
				updateFromTextfieldToObject();
			}
		}
		/** allows to increment numeric or to set oposite boleans values*/
		public function keyUp(mod:Number=1):void { keyAction(1 * mod) }
		/** allows to decrement numeric or to set oposite boleans values*/
		public function keyDown(mod:Number=1):void { keyAction(-1 * mod) }
		/** Returns current value of the property */
		public function get value():String { return pvalue }
		/** Name of the property passed in parse method */
		override public function get name():String{ return pname }
		override public function set name(v:String):void { trace('seting name only via parse') }
		
		override public function set width(v:Number):void
		{
			fwidth = v;
			updateBalance(balance);
		}
		/** destroys instance*/
		public function destroy():void
		{
			if(parent)
				parent.removeChild(this);
			removeChildren();
			pname = pvalue = type = null;
			tname = tvalue = null;
			editor = null;
		}
	}
}
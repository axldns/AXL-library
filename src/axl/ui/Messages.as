/**
 *
 * AXL Library
 * Copyright 2014-2015 Denis Aleksandrowicz. All Rights Reserved.
 *
 * This program is free software. You can redistribute and/or modify it
 * in accordance with the terms of the accompanying license agreement.
 *
 */
package axl.ui
{
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.getTimer;
	
	import axl.utils.U;
	
	/**
	 * Basic native flash display list messages on top of the screen.
	 * Provides basic interactivity by defining inside and outside tap functions.
	 */
	public class Messages
	{
		private static var tff_msg:TextFormat = new TextFormat("Verdana", 16, 0xffffff,null,null,null,null,null,'center');
		private static var tff_mini:TextFormat =new TextFormat("Verdana", 8, 0xffffff,null,null,null,null,null,'center');
		private static var tf:TextField = makeTf();
		private static var insideTap:Function;
		private static var outsideTap:Function;
		public static var logMessages:Boolean=true;
		
		/**
		 * tells if messages dialog is on stage at the moment
		 */
		public static function get areDisplayed():Boolean { return (tf && tf.parent) };
		public static function set bgColour(u:uint):void {tf.backgroundColor = u }
		public static function set textFormat(v:TextFormat):void 
		{
			tff_msg = v;
			tf.defaultTextFormat = tff_msg;
			tf.setTextFormat(tff_msg);
		}
		public static function msg(v:String=null, onTapOutside:Function=null, onTapInside:Function=null):void
		{
			if(v == null || U.STG == null)
				return MD();
			insideTap = onTapInside;
			outsideTap = onTapOutside;
			tf.text = v;
			tf.appendText(String(' ('+getTimer()/1000 + ')'));
			tf.setTextFormat(tff_mini, v.length, tf.text.length);
			tf.width = U.REC.width;
			tf.height = tf.textHeight + 5;
			U.STG.addChild(tf);
			if(logMessages)
				U.log(v);
			U.STG.addEventListener(MouseEvent.MOUSE_DOWN, MD);
		}
		
		private static function makeTf():TextField
		{
			var tfm:TextField = new TextField();
			tfm.selectable = false;
			tfm.border = true;
			tfm.defaultTextFormat = tff_msg;
			tfm.multiline = true;
			tfm.wordWrap = true;
			tfm.backgroundColor = 0x4f6dff;
			tfm.background = true;
			tfm.text = ' ';
			tfm.height = tfm.textHeight + 5;
			return tfm;
		}
		
		private static function MD(e:MouseEvent=null):void
		{
			
			if(tf != null && (tf.parent != null))
				tf.parent.removeChild(tf);
			if(e != null)
			{
				if(e.target == tf)
					if(insideTap != null) insideTap();
				else 
					if(outsideTap != null)
						outsideTap();
			}
			if(U.STG != null)
				U.STG.removeEventListener(MouseEvent.MOUSE_DOWN, MD);
		}	
		
		public static function resize():void
		{
			tf.width = U.REC.width;
		}
	}
}
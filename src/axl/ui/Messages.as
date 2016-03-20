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
		private static var tff_msg:TextFormat = new TextFormat("Verdana", 16, 0xffffff,null,null,null,null,null,'center',null,null,null,-4);
		private static var tf:TextField = makeTf();
		private static var insideTap:Function;
		private static var outsideTap:Function;
		public static var logMessages:Boolean=true;
		
		/**
		 * tells if messages dialog is on stage at the moment
		 */
		public static function get areDisplayed():Boolean { return (tf && tf.parent) };
		public static function set bgColour(u:uint):void {tf.backgroundColor = u }
		public static function get textfield():TextField { return tf }
		public static function set textFormat(v:TextFormat):void 
		{
			tff_msg = v;
			tf.defaultTextFormat = tff_msg;
			tf.setTextFormat(tff_msg);
		}
		public static function msg(v:String=null, onTapOutside:Function=null, onTapInside:Function=null,forceClickInside:Boolean=false):void
		{
			if(v == null || U.STG == null)
				return MD();
			insideTap = onTapInside;
			outsideTap = onTapOutside;
			tf.htmlText = v + '<br><font size="7">('+getTimer()/1000 + ')</font>';
			
			tf.width = U.REC.width;
			tf.height = tf.textHeight + 5;
			U.STG.addChild(tf);
			if(logMessages)
				U.log(v);
			U.STG.addEventListener(MouseEvent.MOUSE_DOWN, MD);
			
			function MD(e:MouseEvent=null):void
			{
				if((forceClickInside && e.target == tf) || !forceClickInside)
					remove();
				if(e != null)
				{
					if(e.target == tf)
					{
						if(insideTap != null) 
							insideTap();
					}
					else 
					{
						if(outsideTap != null)
							outsideTap();
					}
				}
			}
			
			function remove():void
			{
				if(tf != null && (tf.parent != null))
					tf.parent.removeChild(tf);
				if(U.STG != null)
					U.STG.removeEventListener(MouseEvent.MOUSE_DOWN, MD);
			}
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
		
		
		public static function resize():void
		{
			tf.width = U.REC.width;
		}
	}
}
package axl.ui
{
	/**
	 * [axldns free coding 2014]
	 */
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.getTimer;
	
	import axl.utils.U;
	
	/**
	 * handy as stupidly simple widget to dialog user. If only stage is accesssible, you are free to 
	 * display  "interactive" message/nottification to the user. Very usefull for debugging too.
	 */

	public class Messages
	{
		private static var tff_msg:TextFormat = new TextFormat("Verdana", 16, 0xffffff,null,null,null,null,null,'center');
		private static var tff_mini:TextFormat =new TextFormat("Verdana", 8, 0xffffff,null,null,null,null,null,'center');
		private static var tf:TextField = makeTf();
		private static var ON_TAP:Function;
		
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
		public static function msg(v:String=null, onTap:Function=null):void
		{
			if(v == null)
				return MD();
			ON_TAP = onTap;
			tf.text = v;
			tf.appendText(String(' ('+getTimer()/1000 + ')'));
			tf.setTextFormat(tff_mini, v.length, tf.text.length);
			tf.width = U.REC.width;
			tf.height = tf.textHeight + 5;
			U.STG.addChild(tf);
			
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
		
		protected static function MD(e:MouseEvent=null):void
		{
			U.STG.removeEventListener(MouseEvent.MOUSE_DOWN, MD);
			if(tf != null && U.STG.contains(tf))
				U.STG.removeChild(tf);
			if(ON_TAP is Function)
				ON_TAP();
		}	
	}
}
package axl.ui
{
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	
	import axl.utils.U;
	
	public class ProgressBar extends Sprite implements IprogBar
	{
		private var bar:Shape;
		private var frame:Shape;
		private var _BAR_COLOR:uint = 0x0000ff;
		private var _BAR_WIDTH:Number = 100;
		private var _BAR_HEIGHT:Number = 20;
		private var _FRAME_COLOR:uint = 0x0000ff;
		private var _FRAME_THICK:Number = 3;
		private var _progess:Number;
		public function ProgressBar()
		{
			super();
			build();
		}
		
		public function build():void
		{
			bar = new Shape();
			frame = new Shape();
			
			bar.graphics.beginFill(BAR_COLOR);
			bar.graphics.drawRect(0,0,BAR_WIDTH,BAR_HEIGHT);
			bar.scaleX = 0;
			
			frame.graphics.lineStyle(FRAME_WID,FRAME_COLOR,1,true);
			frame.graphics.drawRect(FRAME_WID/2,FRAME_WID/2, BAR_WIDTH-FRAME_WID, BAR_HEIGHT-FRAME_WID);
			this.addChild(bar);
			this.addChild(frame);
			this.addEventListener(Event.ADDED_TO_STAGE, ats);
		}
		
		protected function ats(e:Event):void
		{
			this.removeEventListener(Event.ADDED_TO_STAGE, ats);
			BAR_WIDTH = U.REC.width;
		}		
				
		private function redraw():void
		{
			bar.graphics.clear();
			bar.graphics.beginFill(BAR_COLOR);
			bar.graphics.drawRect(0,0,BAR_WIDTH,BAR_HEIGHT);
			bar.scaleX = 0;
			
			frame.graphics.clear();
			frame.graphics.lineStyle(FRAME_WID,FRAME_COLOR,1,true);
			frame.graphics.drawRect(FRAME_WID/2,FRAME_WID/2, BAR_WIDTH-FRAME_WID, BAR_HEIGHT-FRAME_WID);
		}

		public function get BAR_COLOR():uint
		{
			return _BAR_COLOR;
		}

		public function set BAR_COLOR(value:uint):void
		{
			_BAR_COLOR = value;
			redraw();
		}

		public function get BAR_WIDTH():Number
		{
			return _BAR_WIDTH;
		}

		public function set BAR_WIDTH(value:Number):void
		{
			_BAR_WIDTH = value;
			redraw();
		}

		public function get BAR_HEIGHT():Number
		{
			return _BAR_HEIGHT;
		}

		public function set BAR_HEIGHT(value:Number):void
		{
			_BAR_HEIGHT = value;
			redraw();
		}

		public function get FRAME_COLOR():uint
		{
			return _FRAME_COLOR;
		}

		public function set FRAME_COLOR(value:uint):void
		{
			_FRAME_COLOR = value;
			redraw();
		}

		public function get FRAME_WID():Number
		{
			return _FRAME_THICK;
		}

		public function set FRAME_WID(value:Number):void
		{
			_FRAME_THICK = value;
			redraw();
		}

		public function get progess():Number
		{
			return _progess;
		}

		/**
		 * methods to set progress of bar
		 * @params bitProgress: 0-1
		 */
		public function setProgress(bitProgress:Number):void
		{
			//trace("PROGRESS", bitProgress);
			_progess = bitProgress;
			bar.scaleX =  _progess;
		}


		public function destroy():void
		{
			this.removeChildren(0, this.numChildren-1);
			this.graphics.clear();
			bar.graphics.clear();
			bar = null;
			frame.graphics.clear();
			frame = null;
			
		}
	}
}
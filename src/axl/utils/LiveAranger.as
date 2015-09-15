package axl.utils
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Shape;
	import flash.display.Stage;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.ui.Keyboard;

	public class LiveAranger
	{
		public static var instance:LiveAranger;
		private var miniHint:TextField;
		private var c:DisplayObject;
		private var cp:DisplayObjectContainer;
		private var added:Boolean;
		private var outline:Shape;
		private var resizeHhint:Boolean;
		private var resizeVhint:Boolean;
		private var go:Point = new Point();
		
		private var oap:Array = [];
		private var oapi:int = 0;
		private var cpi:int;
		
		private var objectMouse:Point = new Point();;
		private var startObject:Point = new Point();
		private var coffset:Point = new Point();
		private var cGloToLo:Point = new Point();
		private var startMouse:Point = new Point();
		private var resizingH:Boolean;
		private var resizingV:Boolean;
		private var moving:Boolean;
		private var cbounds:Rectangle = new Rectangle()
		private var ci:int;
		private var isOn:Boolean=false;
		
		public function LiveAranger()
		{
			if(instance == null)
			{
				instance = this;
				miniHint = new TextField();
				miniHint.border = true;
				miniHint.background = true;
				miniHint.backgroundColor = 0xEECD8C;
				miniHint.height = 19;
				miniHint.selectable = false;
				miniHint.mouseEnabled = false;
				miniHint.tabEnabled = false;
				U.STG.addEventListener(MouseEvent.MOUSE_MOVE, mm);
				U.STG.addEventListener(MouseEvent.MOUSE_DOWN, md);
				U.STG.addEventListener(MouseEvent.MOUSE_UP, mu);
				U.STG.addEventListener(KeyboardEvent.KEY_UP, ku);
				U.STG.addEventListener(KeyboardEvent.KEY_DOWN, kd);
				outline = new Shape();
				super();
			}
			else
			{
				miniHint = instance.miniHint;
				
				added = instance.added;
				c = instance.c;
				cbounds = instance.cbounds;
				ci = instance.ci;
				cp = instance.cp;
				cpi = instance.cpi;
				go = instance.go;
				isOn = instance.isOn;
				moving = instance.moving;
				oap = instance.oap;
				oapi = instance.oapi;
				objectMouse = instance.objectMouse;
				outline = instance.outline;
				resizeHhint = instance.resizeHhint;
				resizeVhint = instance.resizeVhint;
				resizingH = instance.resizingH;
				resizingV = instance.resizingV;
				startMouse = instance.startMouse;
				startObject = instance.startObject;
				cGloToLo = instance.cGloToLo;
				coffset = instance.coffset;
			}
		}
		public function get cTarget():Object { return c}
		protected function kd(e:KeyboardEvent):void
		{
			if(c == null) return
			var mod:String;
			var dir:int;
			switch(e.keyCode)
			{
				case Keyboard.RIGHT:
					mod = 'x';
					dir = 1;
					break;
				case Keyboard.LEFT:
					mod = 'x';
					dir = -1;
					break;
				case Keyboard.UP:
					mod = 'y';
					dir = -1;
					break;
				case Keyboard.DOWN:
					mod = 'y';
					dir = 1;
					break;
			}
			if(mod == null) return;
			c[mod] += (1 + (e.shiftKey ? 5 : 0)) * dir;
			updateStuff();
		}
		
		protected function ku(e:KeyboardEvent):void
		{
			if(e.keyCode == 117)
			{
				isOn = !isOn;
			}
			if(c==null) return;
			//goes up
			if(e.keyCode == Keyboard.Z)
			{
				objectUp();
			}
			else if(e.keyCode == Keyboard.X)
			{
				if(c is DisplayObjectContainer && c['numChildren'] > 0)
				{
					cpi = 0;
					newC(c['getChildAt'](cpi));
				}
				
			}
			else if(e.keyCode == Keyboard.NUMBER_2)
			{
				if(cp == null  || cp.numChildren == 0)
					return;
				if(++cpi >= cp.numChildren)
					cpi = 0;
				newC(cp.getChildAt(cpi));
			}
			else if(e.keyCode == Keyboard.NUMBER_1)
			{
				if(cp == null || cp.numChildren == 0)
					return;
				if(--cpi <= 0)
					cpi = cp.numChildren-1;
				newC(cp.getChildAt(cpi));
			}
		}
		
		private function objectUp():void { newC(c.parent) }
		
		private function newC(v:DisplayObject):void
		{
			c = v;
			descC();
			if(!c)
			{
				cp = null;
				cpi = -1;
				removeHint();
				return;
			}
			cp = c.parent;
			if(cp)
			{
				cpi = cp.getChildIndex(c);
			}
			resizingH = false;
			resizingV = false;
			moving = false;
			
			go.x = go.y = 0;
			globalOffsetFind(cp);
			updateStuff();
		}
		
		protected function mu(e:MouseEvent):void
		{
			descC();
			c=null;
			cp = null;
			oap =[];
			resizingH = false;
			resizingV = false;
			moving = false;
		}
		
		private function descC():void
		{
			if(c)
				trace('<' + c.toString(),'name="' + c.name + '" x="' + c.x + '" y="' + c.y 
					+ '" width="' + c.width + '" height="' + c.height + '" scaleX="' + c.scaleX + '" scaleY="' + c.scaleY + '" />'
					+ '\njson:' + '{"x":' + c.x + ',"y":' + c.y + ',"width":' + c.width + ',"height":' + c.height + ',"alpha":' 
					+ c.alpha + ',"scaleX":' + c.scaleX + ',"scaleY":' + c.scaleY + '}');
		}
		
		protected function md(e:MouseEvent):void
		{
			if(!isOn) return;
			if(c != null)
			{
				startObject.x = c.x;
				startObject.y = c.y;
				objectMouse.x = c.mouseX;
				objectMouse.y = c.mouseY;
				startMouse.x = U.STG.mouseX;
				startMouse.y = U.STG.mouseY;
				coffset.x = c.mouseX;
				coffset.y = c.mouseY;
				resizingH = resizeHhint;
				resizingV = resizeVhint;
				moving = (!resizingH && !resizingV);
			}
			else
			{
				resizingH = false;
				resizingV = false;
				moving = false;
			}
		}
		
		protected function mm(e:MouseEvent):void
		{
			if(isOn)
			{
				var t:DisplayObject = e.target as DisplayObject;
				if(c != t && !e.buttonDown)
					newC(t);
				updateStuff();
			}
			else
				removeHint();
		}
		
		private function updateStuff():void
		{
			if(c==null) return;
			resizeVhint = false;
			resizeHhint = false;
			if(U.STG.mouseX - (cbounds.x + cbounds.width) > -10)
				resizeHhint=true;
			if(U.STG.mouseY - ( cbounds.y + cbounds.height)  > -10)
				resizeVhint=true;
			if(c.parent)
			{
				cGloToLo.setTo(c.stage.mouseX, c.stage.mouseY);
				cGloToLo = c.parent.globalToLocal(cGloToLo);
			}
			
			if(moving && !(c is Stage))
			{
				c.x = cGloToLo.x- coffset.x;//startObject.x + (U.STG.mouseX - startMouse.x);
				c.y = cGloToLo.y- coffset.y;//startObject.y + (U.STG.mouseY - startMouse.y);
			}
			else if(!(c is Stage))
			{
				var hval:Number = U.STG.mouseX - go.x - c.x;
				var vval:Number = U.STG.mouseY - go.y - c.y;
				if(resizingH && resizingV)
				{
					var hd:Number = hval - c.width;
					var vd:Number = vval - c.height;
					if(hd>vd)
					{
						c.width = hval;
						c.scaleY = c.scaleX;
					}
					else
					{
						c.height = vval;
						c.scaleX = c.scaleY;
					}
				}
				else
				{
					if(resizingH)
						c.width = hval;
					if(resizingV)
						c.height = vval;
				}
			}
			addMiniHint(c);
		}
		
		private function removeHint():void
		{
			c = null;
			if(!added)
				return
			if(U.STG.contains(miniHint))
				U.STG.removeChild(miniHint);
			U.STG.removeChild(outline);
			added = false;
		}
		
		private function addMiniHint(c:DisplayObject):void
		{
			if(!added)
				U.STG.addChild(miniHint);
			U.STG.addChild(outline);
			added = true;
			
			cbounds = c.getBounds(c.stage);
			miniHint.text = c.toString() + '[' + c.name +'] x:' + c.x + ' y:' + c.y + ' w:' + c.width + ' h:' + c.height;
			miniHint.width = miniHint.textWidth + 5;
			
			
			outline.graphics.clear();
			outline.graphics.lineStyle(1,0x00ff00,.8);
			if(false)
				outline.graphics.beginFill(0,0.2);
			outline.graphics.drawRect(0.5,0.5, cbounds.width-1, cbounds.height-1);
			if(resizeHhint || resizingH)
			{
				outline.graphics.lineStyle(1,0x0ff000,.8);
				outline.graphics.drawRect(cbounds.width-11, 0.5,10, cbounds.height-1);
			}
			if(resizeVhint || resizingV)
			{
				outline.graphics.lineStyle(1,0x0ff000,.8);
				outline.graphics.drawRect(0.5, cbounds.height-11,cbounds.width-1, 10);
			}
			outline.x = cbounds.x;
			outline.y = cbounds.y;
			miniHint.x =  cbounds.x;
			miniHint.y =  cbounds.y;
		}
		
		private function globalOffsetFind(dob:DisplayObject):void
		{
			if(dob == null)
				return
			go.x += dob.x;
			go.y += dob.y;
			globalOffsetFind(dob.parent);
		}
	}
}
/**
 *
 * AXL Library
 * Copyright 2014-2016 Denis Aleksandrowicz. All Rights Reserved.
 *
 * This program is free software. You can redistribute and/or modify it
 * in accordance with the terms of the accompanying license agreement.
 *
 */
package axl.utils
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.SyncEvent;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.ui.Keyboard;
	
	import axl.utils.liveArange.EditorWindow;
	import axl.utils.liveArange.Property;
	import axl.utils.liveArange.Selector;

	/**
	 * Class that allows onscreen edit display objects.
	 * Objects are being detected based on mouse pointer position.
	 * An outline of currently detected object is being drawn.<br>
	 * Hotkeys:
	 * <ul>
	 * <li><b>F6</b> - turns it on/off.</li>
	 * <li><b>PageUp,PageDown,Home</b> - opens or closes editor window for selected object</li>
	 * <li>hold <b>CTRL or CMD</b>
	 * 	<ul>
	 * 		<li>if editor is off: allows to drag buttons preventing from executing their functions</li>
	 * 		<li>if editor is on: allows to select new object without exiting editor</li>
	 * 	</ul>
	 * </li>
	 * <li><b>Z</b> - (traverse up) sets parent of selected object as selected object if available.</li>
	 * <li><b>X</b> - (traverse down) selects first child of selected object as selected object if available.</li>
	 * <li><b>1</b> - (traverse side) selects another child(+1) in container of selected object if available.</li>
	 * <li><b>2</b> - (traverse side) selects another child(-1) in container of selected object if available.</li>
	 * <li><b>ESC</b> - turns off editor. If editor is closed, turns aranger off.</li>
	 * </ul>
	 * 
	 * <h3>Class is a singletone</h3> 
	 * Singletone contoll is managed by dispatching SyncEvent of type <i>axl.utils.LiveAranger</i> 
	 * to <code>stage.loaderInfo.sharedEvents</code> passing itself instance in <code>changesList</code>.<br>
	 * If there's any primary class listening to this event, it will call <code>destroy</code> method on the
	 * instance passed in changesList.<br>
	 * If there's no response on SyncEvent, the dispatcher instance becomes ruling primary listener to SyncEvents, and 
	 * it's only allowed one to continue with building it's contents.
	 */
	public class LiveAranger
	{
		public static var instance:LiveAranger;
		
		private var subject:DisplayObject;
		private var subjectParent:DisplayObjectContainer;
		private var added:Boolean;
		
		private var objectsUnderPoint:Array;
		private var withinLayerIndex:int;
		
		private var offset:Point;
		private var cGloToLo:Point = new Point();
		private var moving:Boolean;
		private var xisOn:Boolean=false;
		private var destroyed:Boolean;
		private var xselector:Selector;
		private var editorWindow:EditorWindow;
		private var editorWindowOn:Boolean;
		private var version:String = '2.0.2';
		private var tname:String = "[LiveArranger "+ version + "]";
		private var userKeyboarOpenSequenceCount:int;
		/** Defines the sequence of key codes that activates/deactivates LiveArranger @default [117] - means F6 to toggle. 
		 * [117,117,117] would require pressing F6 key three times to act/deactivate  */
		public var userKeyboarOpenSequence:Array = [117];
		
		/** @see LiveAranger*/
		public function LiveAranger()
		{
			U.log(tname, "[constructor]");
			U.STG.loaderInfo.sharedEvents.dispatchEvent(new SyncEvent('axl.utils.LiveAranger',true,false,[this]));
			if(destroyed)
				return;
			else
			{
				instance =this;
				U.STG.loaderInfo.sharedEvents.addEventListener('axl.utils.LiveAranger',liveArangerAlreadyExists);
				xselector = new Selector(selectorDoubleClick);
				offset = new Point();
				cGloToLo = new Point();
				U.STG.addEventListener(KeyboardEvent.KEY_UP, keyUp);
			}
			U.log(tname, "[CONSTRUCTED]");
		}
		
		//------------------EVENTS HANDLING------------------------//

		protected function onUnload(event:Event):void { destroy() }
		protected function liveArangerAlreadyExists(e:SyncEvent):void
		{
			var o:Object = e.changeList.length > 0 ? e.changeList.pop() : null;
			U.log(tname, "[liveArangerAlreadyExists]", 'self?', o == this);
			if(o.hasOwnProperty('destroy'))
				o.destroy();
			o = null;
		}
		
		//---KEYBOARD EVENTS---//
		protected function keyDown(e:KeyboardEvent):void
		{
			if(!isOn || subject==null || (U.STG.focus is TextField && U.STG.focus.parent is Property)) 
				return;
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
				case Keyboard.COMMAND:
				case Keyboard.CONTROL:
						this.xselector.mouseEnabled =!this.editorWindowOn;
					break;
				case Keyboard.HOME:
				case Keyboard.PAGE_UP:
				case Keyboard.PAGE_DOWN:
					toggleEditor();
					break;
				case Keyboard.ESCAPE:
					editorWindowOn ? exitEditor() : isOn = false;
					break;
			}
			if(mod == null) return;
			subject[mod] += (1 + (e.shiftKey ? 5 : 0)) * dir;
			updateInfo();
		}
		
		protected function keyUp(e:KeyboardEvent):void
		{
			if((e.keyCode) == userKeyboarOpenSequence[userKeyboarOpenSequenceCount++])
			{
				if(userKeyboarOpenSequenceCount >= userKeyboarOpenSequence.length)
					isOn = !isOn
			}
			else
				userKeyboarOpenSequenceCount =0;
			if(!isOn && subject==null || (U.STG.focus is TextField && U.STG.focus.parent is Property)) 
				return;
			switch (e.keyCode)
			{
				case Keyboard.Z:
					objectUp();
					break
				case Keyboard.X:
					objectDown();
					break;
				case Keyboard.NUMBER_1:
					objectSybilingPrev();
					break;
				case Keyboard.NUMBER_2:
					objectSybilingNext();
					break;
				case Keyboard.SHIFT:
					changeSelectorStyle();
					break;
				case Keyboard.COMMAND:
				case Keyboard.CONTROL:
					this.xselector.mouseEnabled = this.editorWindowOn;
					break;
			}
		}
		
		//---END OF KEYBOARD EVENTS---//
		//---MOUSE EVENTS---//
		protected function md(e:MouseEvent):void
		{
			if(!isOn) return;
			if(subject != null || xselector.target != null)
			{
				
				offset.x =  xselector.target.mouseX * xselector.target.scaleX;
				offset.y =  xselector.target.mouseY* xselector.target.scaleY;
				moving = (this.editorWindowOn ?  (e.target == xselector) : true);
			}
			else
				moving = false;
		}
		
		protected function mm(e:MouseEvent):void
		{
			if(isOn)
			{
				var t:DisplayObject = e.target as DisplayObject;
				var movbl:Boolean = (t != xselector && (!editorWindowOn && !e.ctrlKey && !e.buttonDown) || (editorWindowOn && e.ctrlKey));
				if(movbl)
				{
					this.objectsUnderPoint = U.STG.getObjectsUnderPoint(new Point(U.STG.mouseX, U.STG.mouseY));
					var dob:DisplayObject;
					for(var i:int = objectsUnderPoint.length; i-->0;)
					{
						dob = objectsUnderPoint[i];
						if(t != dob && U.isTargetGrandChild(dob, t))
						{
							t = dob;
							break;
						}
					}
				}
				if(((subject != t && !e.buttonDown) || movbl) && t != xselector)
				{
					if(!movbl)
						return;
					newSubject(t);
				}
				else
					updateInfo();
			}
			else
				removeSelector();
		}
		
		protected function mu(e:MouseEvent):void { moving = false }
		
		protected function selectorDoubleClick(e:MouseEvent=null):void
		{
			if(xselector.target.hasOwnProperty('numChildren') && xselector.target['numChildren'] > 0)
				this.objectDown();
			else
			{
				if(xselector.target.parent != U.STG)
					this.objectUp();
				else
				{
					this.objectUp();
					this.objectSybilingNext();
				}
			}
		}
		
		//------------------END EVENTS HANDLING------------------------//
		//------------------EDITOR DIRECTIVES------------------------//
		private function toggleEditor():void
		{
			if(this.editorWindowOn)
				exitEditor();
			else
				addEditorWindow();
		}
		
		private function addEditorWindow():void
		{
			if(!xselector.target)
				return;
			if(editorWindow == null)
			{
				editorWindow = new EditorWindow();
				editorWindow.exitEditor = this.exitEditor;
				editorWindow.getChild = this.objectDown;
				editorWindow.getParent = this.objectUp;
				editorWindow.getSybiling = this.objectSybilingNext;
			}
			editorWindow.subject = xselector.target;
			editorWindowOn = true;
			xselector.mouseEnabled = true;
			moving = false;
			U.STG.addChild(editorWindow);
		}
		
		private function exitEditor():void
		{
			if(editorWindow && editorWindow.parent)
			{
				editorWindow.parent.removeChild(editorWindow);
			}
			editorWindowOn = false;
			xselector.target = null;
			xselector.mouseEnabled = false;
			removeSelector();
			subject=null;
			subjectParent = null;
			objectsUnderPoint =[];
			moving = false;
		}
		//------------------ END OF EDITOR DIRECTIVES------------------------//
		//------------------ SELECTOR DIRECTIVES------------------------//
		private function removeSelector():void
		{
			subject = null;
			if(!added)
				return
			U.STG.removeChild(xselector);
			added = false;
		}
		
		private function addSelector(c:DisplayObject):void
		{
			if(!added)		
				U.STG.addChild(xselector);
			added = true;
			xselector.update();
		}
		
		private function changeSelectorStyle():void
		{
			xselector.nextStyle();
		}
		
		//------------------ END OF SELECTOR DIRECTIVES------------------------//
		//------------------ OBJECT TRAVERSING------------------------//
		private function objectSybilingNext():void
		{
			if(subjectParent == null  || subjectParent.numChildren == 0)
				return;
			if(++withinLayerIndex >= subjectParent.numChildren)
				withinLayerIndex = 0;
			newSubject(subjectParent.getChildAt(withinLayerIndex));
		}
		
		private function objectSybilingPrev():void
		{
			if(subjectParent == null || subjectParent.numChildren == 0)
				return;
			if(--withinLayerIndex < 0)
				withinLayerIndex = subjectParent.numChildren-1;
			newSubject(subjectParent.getChildAt(withinLayerIndex));
		}
		
		private function objectDown():void
		{
			if(subject is DisplayObjectContainer && subject['numChildren'] > 0)
			{
				withinLayerIndex = 0;
				newSubject(subject['getChildAt'](withinLayerIndex));
			}
		}
		
		private function objectUp():void { 
			if(subject.parent)
				newSubject(subject.parent)
		}
		//------------------ END OF OBJECT TRAVERSING------------------------//
		//------------------ GENERAL MECHANIC AND API------------------------//
		private function newSubject(v:DisplayObject):void
		{
			xselector.target = v;
			subject = v;
			
			xselector.mouseEnabled = false;
			if(!subject)
			{
				subjectParent = null;
				withinLayerIndex = -1;
				removeSelector();
				return;
			}
			subjectParent = subject.parent;
			if(subjectParent)
			{
				withinLayerIndex = subjectParent.getChildIndex(subject);
			}
			moving = false;
			if(editorWindowOn)
				addEditorWindow();
			updateInfo();
		}
		
		private function updateInfo():void
		{
			if(xselector.target==null) return;
			
			if(moving && !(xselector.target is Stage))
			{
				if(xselector.target.stage)
				{
					cGloToLo.setTo(xselector.target.stage.mouseX, xselector.target.stage.mouseY);
					cGloToLo = xselector.target.parent.globalToLocal(cGloToLo);
				
					xselector.target.x = cGloToLo.x- offset.x;
					xselector.target.y = cGloToLo.y- offset.y;
				}
			}
			addSelector(xselector.target);
		}
		/** Returns reference to selector that provides information about current subject of edition.*/
		public function get selector():Selector { return selector }
		
		public function get VERSION():String { return version } 
		/** Sets aranger on and off. Usually triggered by F6 automatically.*/
		public function get isOn():Boolean { return xisOn }
		public function set isOn(v:Boolean):void
		{
			xisOn = v;
			if(isOn)
			{
				U.STG.addEventListener(MouseEvent.MOUSE_MOVE, mm);
				U.STG.addEventListener(MouseEvent.MOUSE_DOWN, md);
				U.STG.addEventListener(MouseEvent.MOUSE_UP, mu);
				U.STG.addEventListener(KeyboardEvent.KEY_DOWN, keyDown);
			}
			else
			{
				removeSelector();
				exitEditor();
				U.STG.removeEventListener(MouseEvent.MOUSE_MOVE, mm);
				U.STG.removeEventListener(MouseEvent.MOUSE_DOWN, md);
				U.STG.removeEventListener(MouseEvent.MOUSE_UP, mu);
				U.STG.removeEventListener(KeyboardEvent.KEY_DOWN, keyDown);
			}
		}
		
		/** Removes all event listeners and destroys instance. Destroyed instance can not be reused.*/
		public static function destroyInstance():void
		{
			if(instance != null)
				instance.destroy();
		}
		/** Removes all event listeners and destroys instance. Destroyed instance can not be reused.*/
		public function destroy():void
		{
			U.log(tname, "[DESTROY]");
			U.STG.removeEventListener(MouseEvent.MOUSE_MOVE,mm);
			U.STG.removeEventListener(MouseEvent.MOUSE_DOWN, md);
			U.STG.removeEventListener(MouseEvent.MOUSE_UP, mu);
			U.STG.removeEventListener(KeyboardEvent.KEY_UP, keyUp);
			U.STG.removeEventListener(KeyboardEvent.KEY_DOWN, keyDown);
			U.STG.loaderInfo.sharedEvents.removeEventListener('axl.utils.LiveAranger',liveArangerAlreadyExists);
			//instance = null;
			
			if(xselector)
			{
				xselector.loaderInfo.removeEventListener(Ldr.unloadEvent.type,onUnload);
				xselector.destroy();
			}
			xselector = null;
			if(editorWindow)
				editorWindow.destroy();
			editorWindow = null;
			
			offset = null;
			cGloToLo = null;
			moving = false;
			objectsUnderPoint = null;
			destroyed = true;
		}
	}
}
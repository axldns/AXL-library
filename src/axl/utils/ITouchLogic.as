package axl.utils
{
	import starling.events.Touch;

	
	public interface ITouchLogic
	{
		function tapBegan(touch:Touch):void; 
		function tapMoved(touch:Touch):void; 
		function tapEnded(touch:Touch):void; 
	}
}
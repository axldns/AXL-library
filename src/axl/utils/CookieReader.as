package axl.utils
{
	import flash.net.SharedObject;

	public class CookieReader
	{
		public static var CLEAR_COOKIE:Boolean = false;
		public function CookieReader()
		{
		}
		
		public static function read(filename:String, variable:String, arrayToReadTo:Array):SharedObject
		{
			var cookie:SharedObject = SharedObject.getLocal(filename);
			if(CLEAR_COOKIE)
				cookie.clear()
			if(cookie.data.hasOwnProperty(variable) && cookie.data[variable] is Array) // check group var
			{
				var sourceArray				:Array = cookie.data[variable];
				var sourceSubArray			:Array;
				var sourceArrayLength		:int = sourceArray.length;
				
				var targetArrayLength		:int = arrayToReadTo.length;
				var targetArrayIndex		:int;
				
				while(sourceArrayLength-->0) // read through all STORED properties of group var
				{
					sourceSubArray = sourceArray[sourceArrayLength]; 
					targetArrayIndex = targetArrayLength;
					while(targetArrayIndex-->0) // through all CODE properties
					{
						if(arrayToReadTo[targetArrayIndex][1] == sourceSubArray[1]) // if IDs MATCH
						{
							for(var i:int = sourceSubArray.length; i-->0;)
								arrayToReadTo[targetArrayIndex][i] = sourceSubArray[i]; // apply value on CODE
							break;
						}
					}
				}
			}
			return cookie;
		}
		
	
	}
}
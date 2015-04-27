package axl.utils.binAgent
{
	import flash.utils.getQualifiedClassName;
	public class Asist
	{
		
		private var dict:Object = 
		{
			String : abstractString,
			Object : abstractObject
		}
		private var abstractString:Astring;
		private var abstractObject:Aobject;
		public function Asist()
		{
			abstractObject = new Aobject();
			abstractString = new Astring();
		}
		
		
		public function check(v:*):XMLList
		{
			if(v is String)
				return abstractString.all.children().copy();
			else if(v is Object)
				return abstractObject.all.children().copy();
			return null
		}
		
		public static function method(name:String, args:Array, returnType:Class, declaredBy:Class):XML
		{
			var xml:XML = <method/>;
			xml.@name = name;
			xml.@declaredBy = getQualifiedClassName(declaredBy);
			xml.@returnType = getQualifiedClassName(returnType);
			var i:int = 0, l:int = args.length;
			for(;i<l;i++)
				xml.appendChild(XML('<parameter type="'+getQualifiedClassName(args[i])+'"/>'));
			return xml;
		}
	}
}
import axl.utils.binAgent.Asist;
internal class Aobject {
	
	public var am:Function = Asist.method;
	public var all:XML;
	private var objectGeneric:Vector.<XML> = new Vector.<XML>();
	private var inherited:Vector.<XML>= new <XML>
		[ 
			am('hasOwnProperty', [String], Boolean, Object),
			am('isPrototypeOf', [Object], Object, Object),
			am('propertyIsEnumerable', [String], Boolean, Object),
			am('setPropertyIsEnumerable', [String, Boolean], null, Object),
			am('toLocaleString', [], String, Object),
			am('toString', [], String, Object),
			am('valueOf', [], Object, Object)
		];
	public function Aobject()
	{
		all = <additions/>;
		for(var i:int = 0, j:int = inherited.length; i<j;i++)
			all.appendChild(inherited[i])
		for(i= 0, j= generic.length; i<j;i++)
			all.appendChild(generic[i]);
	}
	public function get generic():Vector.<XML> { return objectGeneric} 
}
internal class Astring  extends Aobject {
	private var stringGeneric:Vector.<XML>= new <XML>
		[
			Asist.method('charAt', [Number], String, String),
			Asist.method('charCodeAt', [Number],String,String)
		
		];
	public function Astring() {	super(); }
	override public function get generic():Vector.<XML> { return stringGeneric} 
	
	
}
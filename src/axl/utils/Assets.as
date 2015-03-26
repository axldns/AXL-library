package axl.utils
{
/**
 * [axldns free coding 2015]
 * 
 * Custom AssetsManager Privodes some interface to a singletone Utils.Ldr class
 */	
	import flash.media.Sound;
	import flash.media.SoundTransform;
	public class Assets
	{
		private static var instance:Assets;
		private var numAssets:uint;
		private var _onProgress:Function;
		private var _onComplete:Function;
		private var soundTransform:SoundTransform;
		public var VOLUME:Number=1;
		
		public function Assets()
		{
			instance = this;
			soundTransform = new SoundTransform();
		}
		
		/**
		 * Loads all assets (unlike Starling assets manager) synchroniously from array of paths.
		 * 
		 * @param array : array of paths,
		 * @param onComplete : function of 0 arguments, dispatched once all elements are loaded
		 * @param onQueueProgress : function of  1 argument - name of asset available
		 */
		public function loadFromArray(array:Array, onComplete:Function,onQueueProgress:Function=null):void
		{
			numAssets = array.length;
			Ldr.loadQueueSynchro(array, onComplete, onQueueProgress);
		}
		
		/**
		 * Loads specific file upon request. It's being queued if loader is busy and will dispatch onComplete as soon as its ready to.
		 * @param path : path to file
		 * @param onComplete : function which accepts one parameter. 1: Object(requested asset)
		 * @param onProgress (optional): function which acctpts 1 param. 1: Number(0-1)
		 */
		public function loadSpecific(path:String, onComplete:Function, onProgress:Function=null):void
		{
			Ldr.load(path,onComplete, onProgress);
		}
		/**
		 * returns null / undefined if asset is not loaded or data as follows if loaded:<br>
		 * <ul>
		 * <li>flash.disply.DisplayObject / Bitmap for jpg, jpeg, png, gif</li>
		 * <li>flash.media.Sound for mp3,mpg</li>
		 * <li> ByteArray / UTF bytes for any binary (xml, json, txt, atf, etc..)
		 * <ul>
		 * 
		 */
		public function getAsset(v:String):Object {	return Ldr.getme(v) }
		
		/**
		 * Plays sound from assets library (Ldr) if available.
		 * @param v: asset name with an extension (eg. <i>"start.mp3"</i>)
		 * @param volume: Specific volume (0-1) or Assets.VOLUME if -1
		 */
		public function playSound(v:String, volume:Number=-1):void
		{
			if(volume > -1)
				soundTransform.volume = volume
			else
				soundTransform.volume = VOLUME;
			if(Ldr.getme(v) && Ldr.getme(v) is Sound)
				Sound(Ldr.getme(v)).play(0,0,soundTransform);
		}
	}
}
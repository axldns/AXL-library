package axl.utils
{
	import flash.display.DisplayObject;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.setTimeout;
	
	import axl.ui.IprogBar;
	import axl.ui.Messages;
	

	public class Flow extends EventDispatcher
	{
		private var uUpdateRequestObjectFactory:Function;
		private var uAppRemoteGateway:String;
		private var uconfigPath:String;
		
		public var appRemoteRoot:String;
		/** <code>Ldr.load</code> first argument: string, file, XML, XMLList or Arrays or Vectors of these. 
		 * @see axl.utls.Ldr#load*/
		public var filesToLoad:Object;
		
		public var onAllDone:Function;
		
		private var progBar:IprogBar;
		private var configDefinedFiles:XML;
		private var webflow:Boolean;
		private var mobileflow:Boolean;
		private var files:Array = [];
		private var updateFiles:Array=[];
		private var appConfigDate:String;
		private var php:ConnectPHP;
		private var errorCoruptedConfig:ErrorEvent = new ErrorEvent(ErrorEvent.ERROR,false,false, "Corupted or missing config file",1);
		private var errorFilesLoading:ErrorEvent = new ErrorEvent(ErrorEvent.ERROR,false,true, "Not all files loaded",2);
		
		public function Flow()
		{
		}
		
		/** (AIR) When config is loaded, flow can check for updates by sending post request to <code>appRemoteGateway
		 * </code> using <code>ConnectPHP.sendData</code> method. This function should return data argument (POST content).
		 * Returned object will be JSON.stringify and POST as 'update' variable. Response will be parsed, looking for json string.
		 * If response contains variable <code>files</code>, these files will be attempted to download and overwrite
		 * existing ones along with loading remaining. If no function is set, no launch update check will be mande.
		 * @see configPath
		 * @see Ldr#load
		 * @see ConnectPHP
		 * <br>*/
		public function get updateRequestObjectFactory():Function { return uUpdateRequestObjectFactory }
		public function set updateRequestObjectFactory(value:Function):void	{ uUpdateRequestObjectFactory = value }
		
		/** can be set any time. if its loading at the moment and its' displayObject,
		 * it will get added to stage straight away */
		public function get progressBar():IprogBar { return progBar }
		public function set progressBar(value:IprogBar):void
		{
			if(value == progBar) return;
			if(progBar != null)
				progBar.destroy();
			progBar = value;
			if(Ldr.isLoading) progBar.build();
			if(progBar is DisplayObject && U.STG != null)
				U.STG.addChild(progressBar as DisplayObject);
		}
		
		/** Default address for <code>ConnectPHP</code> class. Auto-update from config */
		public function get appRemoteGateway():String { return uAppRemoteGateway }
		public function set appRemoteGateway(value:String):void
		{
			uAppRemoteGateway = value;
			ConnectPHP.defaultAddress = uAppRemoteGateway
		}
		/** If config path is set, there will be an attempt to load it and parse config as 
		 * a first flows asynchronous operation, before file loading. <br>Aside from fact,
		 * that loaded config will be available as <code>U.CONFIG</code>, parsing config reads
		 * five main properties: 
		 * <ul>
		 * <li><code>files</code> - files specified in config will be added to flow load list.
		 * <li><code>date</code> - indicates when config/files has been updated last time. This 
		 * <li><code>gatway</code> - updates remote gateway address - updates default ConnectPHP address</li>
		 * <li><code>remote</code> - updates remote app address used mostly for Ldr & ConnectPHP</li>
		 * value will be updated and config will get re-saved on disc (air) if flow's update point is there.
		 * If it's not set, flow goes to next step which is files loading.
		 * it should be either full path or (preferable) sub-path similar to <code>/assets/config.cfg</code>
		 * as loading process usues <code>Ldr.defaultPathPrefixes</code> and behaviors.*/
		public function get configPath():String	{ return uconfigPath }
		public function set configPath(value:String):void { uconfigPath = value }
		private var flowName:String;
		public function start():void
		{
			mobileflow = Ldr.fileInterfaceAvailable;
			webflow = !mobileflow;
			U.log('[Flow][Start][' + webflow ? 'web]' : 'mobile]');
			defaultFlow();
		}
		/** this represents main flow in a nutshell. 
		 * 1. setup, 2. config ^, 3.files, 4. complete 
		 * <br>^ on mobile flow, after config load there 
		 * is also server update check and potential repeat config load*/
		protected function defaultFlow():void
		{
			setDefaultLoadingPaths();
			
			if(configPath != null)
				loadConfig();
			else
				if(filesToLoad != null)
					loadFiles();
				else
					complete();
		}
		
		protected function setDefaultLoadingPaths():void
		{
			if(webflow)
			{
				Ldr.defaultPathPrefixes[0] = appRemoteRoot;
				Ldr.defaultPathPrefixes[1] = '';
			}
			else if(mobileflow)
			{
				Ldr.defaultPathPrefixes[0] = Ldr.FileClass.applicationStorageDirectory;
				Ldr.defaultPathPrefixes[1] = appRemoteRoot;
				Ldr.defaultPathPrefixes[2] = Ldr.FileClass.applicationDirectory;
				Ldr.defaultStoreDirectory = Ldr.FileClass.applicationStorageDirectory;
			}
		}
		
		protected function loadConfig():void { 	
			U.log('[Flow][ConfigLoad]');
			Ldr.load(configPath, configLoaded)	
		}
		
		protected function configLoaded():void
		{
			if(readConfig())
				afterConfigLoaded();
			else 
			{
				U.log('[Flow][BREAK] config not loaded');
				Messages.msg("Can't load config file :( Tap to try againg", loadConfig);
				this.dispatchEvent(errorCoruptedConfig);
			}
		}
		
		protected function afterConfigLoaded():void
		{
			U.log('[Flow][configLoaded]');
			if(webflow) 
				return loadFiles();
			else if(mobileflow)
			{
				if(appRemoteGateway != null && updateRequestObjectFactory != null)
					performUpdateRequest();
				else
					loadFiles();
			}
		}
		
		protected function performUpdateRequest():void
		{
			U.log('[Flow][UpdateRequest]');
			php = new ConnectPHP('update');
			php.sendData(updateRequestObjectFactory(), onUpdateReceived, appRemoteGateway);
		}
		
		protected function onUpdateReceived(e:Object):void
		{
			U.log('[Flow][onUpdateReceived]');
			php.destroy();
			if((e== null) || (e is Error)) 
				return loadFiles();
			else
			{
				if(e.hasOwnProperty('date'))
					appConfigDate = e.date;
				if(e.hasOwnProperty('files') && e.files is Array)
				{
					updateFiles = e.files;
					var configIndex:int = e.files.indexOf(configPath);
					if(configIndex > -1)
					{
						updateFiles.splice(configIndex, 1);
						U.log('[Flow][configUpdate]');
						// special flow - load config first, re-read it
						// remove it from list, hen load other files
						// it looks for new config only in appRemoteGateway
						Ldr.load(configPath, configUpdated,null,null,appRemoteRoot,Ldr.behaviours.loadOverwrite);
					}
					else
					{
						if(updateFiles.length > 0)
							mergeLoadings();
						else
							loadFiles();
					}
				}
				else
					loadFiles();
			}
		}

		protected function configUpdated():void
		{
			U.log('[Flow][configUpdateReceived]');
			if(readConfig())
				afterConfigUpdated();
			else 
			{
				Messages.msg("Config update corrupted :( Tap to try againg", loadConfig);
				this.dispatchEvent(errorCoruptedConfig);
			}
		}
		
		protected function afterConfigUpdated():void
		{
			mergeLoadings();
		}
		
		/** This function is in use when there are
		 * files to load from two different resources and with different behaviors.
		 * <br>Update files need to be downloaded from web and stored to hdd
		 * <br>Regular files need to be loaded according to defaultPathPrefixes
		 * <br>Both need to display progress and listen for global complete.
		 * <br>This effectively makes two queues with both separate and global listeners.
		 * <br>On complete of update queue, new config date need to be stored.
		*/
		protected function mergeLoadings():void
		{
			U.log('[Flow][MergeLoad]');
			var a:int = Ldr.load(updateFiles,null,validateUpdatedFiles,null, appRemoteRoot,Ldr.behaviours.loadOverwrite);
			loadFiles();
		}
		
		private function validateUpdatedFiles(fname:String):void
		{
			if(Ldr.numCurrentRemaining == 0)
			{
				U.log("[Flow]UPDATE DONE! Skipped ?", Ldr.numCurrentSkipped, 'saving with date', appConfigDate);
				U.log('state:', Ldr.state);
				U.CONFIG.@date = appConfigDate;
				Ldr.save(configPath, U.CONFIG);
			}
		}
		
		protected function readConfig():Boolean
		{
			var cfg:XML = Ldr.getXML(configPath);
			if(cfg is XML)
			{
				U.CONFIG = cfg;
				if(cfg.remote != null)
					appRemoteRoot = cfg.remote;
				if(cfg.gateway != null)
					appRemoteGateway = cfg.gateway;
				if(cfg.files != null)
					configDefinedFiles = cfg;
				U.log('[Flow][configReaded]');
				setDefaultLoadingPaths();
				return true;
			}
			return false;
		}
		
		//-----------------------------------------------//
		/** If there are any update files to load, this should
		 * be called AFTER update load request (make it second queue in row)
		 * to prevent early <code>filesLoaded</code> execution.*/
		protected function loadFiles():void
		{
			U.log('[Flow][LoadingFiles]');
			if(filesToLoad != null)
				files.push(filesToLoad);
			if(configDefinedFiles != null)
				files.push(configDefinedFiles);
			
			if(files.length < 1)
				return filesLoaded();
			if(progBar != null) progBar.build();
			if(progBar is DisplayObject)
				U.STG.addChild(progBar as DisplayObject);
			Ldr.load(files, filesLoaded,fileProgressListener);
			files = null;
				
		}
		protected function fileProgressListener(fname:String):void
		{
			U.log('progress:', (Ldr.numAllLoaded+ Ldr.numAllSkipped)/Ldr.numAllQueued * 100 + '%');
			if(progBar != null)
				progBar.setProgress((Ldr.numAllLoaded+Ldr.numAllSkipped)/Ldr.numAllQueued);
		}
		
		protected function filesLoaded():void
		{
			U.log('[Flow][FilesLoaded]:',Ldr.numAllQueued + '/' + Ldr.numAllLoaded);
			var notLoaded:int = Ldr.numCurrentSkipped - updateFiles.length;
			if(notLoaded > 0)
			{ 
				U.log("[Flow][BREAK]: " + Ldr.numCurrentSkipped + " file(s) not loaded!");
				this.dispatchEvent(errorFilesLoading); 
			} else {
				setTimeout(complete, 100);
			}
		}
		
		protected function complete():void
		{
			U.log("[Flow][Complete]");
			if(onAllDone != null) onAllDone();
			this.dispatchEvent(new Event(Event.COMPLETE));
		}
		
		public function destroy():void
		{
			U.log('[Flow][Destroy]');
			errorFilesLoading = errorCoruptedConfig = null;
			files = null;
			filesToLoad = null;
			onAllDone = null;
			if(php != null) php.destroy(true);
			php = null
			if(progBar) progBar.destroy();
			progBar = null;
			updateFiles = null;
		}
	}
}
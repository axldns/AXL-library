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
	import flash.events.ErrorEvent;	
	import flash.events.Event;
	import flash.utils.ByteArray;
	import flash.events.EventDispatcher;
	import flash.utils.setTimeout;
	import axl.ui.Messages;
	
	/** Automates initial flow of the project by loading files and updates. */
	public class Flow extends EventDispatcher
	{
		private var uUpdateRequestObjectFactory:Function;
		
		private var flowName:String;
		private var configDefinedFiles:Object;
		private var webflow:Boolean;
		private var mobileflow:Boolean;
		private var files:Array = [];
		private var updateFiles:Array=[];
		private var appConfigDate:String;
		private var php:ConnectPHP;
		private var errorCoruptedConfig:ErrorEvent = new ErrorEvent(ErrorEvent.ERROR,false,false, "Corupted or missing config file",1);
		private var errorFilesLoading:ErrorEvent = new ErrorEvent(ErrorEvent.ERROR,false,true, "Not all files loaded",2);
		private var configToLoad:String;
		private var updateRequest:Function;
		
		/** Function to fire when all flow elements (load config, load files defined in config, update config, reload config) are done.
		 * Called right before dispatching event complete*/
		public var onAllDone:Function;
		/** Dispatched when file specified in NetworkSettings.configPath is loaded.
		 * @see axl.utils.NetworkSettings#configPath */
		public var onConfigLoaded:Function;
		/** If files are defined in config file, loader loads them in the flow. This function will be called every time 
		 * progress Event is received from queue of files. Function must accept Number argument - total progress (0-1)
		 * @see axl.utils.Ldr#load()*/
		public var onFilesLoadProgress:Function;
		/** <code>Ldr.load</code> first argument: string, file, XML, XMLList or Arrays or Vectors of these. 
		 * @see axl.utls.Ldr#load*/
		public var filesToLoad:Object;
		/** If your app loads config and/or files and/or makes update requests,
		 * then setup your Network Settings Class first */
		public function Flow()
		{
			configToLoad = NetworkSettings.configPath;
			updateRequest = NetworkSettings.filesUpdateRequestObjectFactory;
		}
		
		/** Starts the flow */
		public function start():void
		{
			mobileflow = Ldr.fileInterfaceAvailable;
			webflow = !mobileflow;
			U.log('[Flow][Start]' + (webflow? '[WEB]' : '[MOBILE]'));
			defaultFlow();
		}
		/** this represents main flow in a nutshell. 
		 * 1. setup, 2. config ^, 3.files, 4. complete 
		 * <br>^ on mobile flow, after config load there 
		 * is also server update check and potential repeat config load*/
		protected function defaultFlow():void
		{
			setDefaultLoadingPaths();
			
			if(configToLoad != null)
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
				Ldr.defaultPathPrefixes.push(NetworkSettings.appRemoteAddresses);
			}
			else if(mobileflow)
			{
				Ldr.defaultPathPrefixes.push( mobileLoadingOrder);
				Ldr.defaultStoreDirectory = Ldr.FileClass.applicationStorageDirectory;
			}
		}
		
		protected function get mobileLoadingOrder():Array
		{
			return 	[
				Ldr.FileClass.applicationStorageDirectory,
				Ldr.FileClass.applicationDirectory,
				NetworkSettings.appRemoteAddresses,
					];
		}
		
		protected function loadConfig():void { 	
			U.log('[Flow][ConfigLoad]');
			Ldr.load(configToLoad, configLoaded)	
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
			U.log('[Flow]' + webflow ? '[webFlow]' : '[mobileFlow]' +'[configLoaded]');
			/*if(onConfigLoaded != null)
				onConfigLoaded()*/
			if(webflow) 
				return loadFiles();
			else if(mobileflow)
			{
				if(configToLoad != null && updateRequest != null)
					performUpdateRequest();
				else
					loadFiles();
			}
		}
		
		protected function performUpdateRequest():void
		{
			U.log('[Flow][UpdateRequest]');
			php = new ConnectPHP('update');
			php.sendData(updateRequest(), onUpdateReceived);
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
					var configIndex:int = e.files.indexOf(configToLoad);
					if(configIndex > -1)
					{
						updateFiles.splice(configIndex, 1);
						U.log('[Flow][configUpdate]');
						// special flow - load config first, re-read it
						// remove it from list, hen load other files
						// it looks for new config only in appRemoteGateway
						Ldr.load(configToLoad, configUpdated,null,null,
							NetworkSettings.appRemoteAddresses,Ldr.behaviours.loadOverwrite);
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
		 * <br>On complete of update queue, new config date need to be stored.*/
		protected function mergeLoadings():void
		{
			U.log('[Flow][MergeLoad]');
			Ldr.load(updateFiles,null,validateUpdatedFiles,null, 
				NetworkSettings.appRemoteAddresses,Ldr.behaviours.loadOverwrite);
			loadFiles();
		}
		
		private function validateUpdatedFiles(fname:String):void
		{
			if(Ldr.numCurrentRemaining == 0)
			{
				U.log("[Flow]UPDATE DONE! Skipped ?", Ldr.numCurrentSkipped, 'saving with date', appConfigDate);
				U.log('state:', Ldr.state);
				U.CONFIG.date = appConfigDate;
				Ldr.save(configToLoad, U.CONFIG);
			}
		}
		/** warining! this function can modify app server addresses */
		protected function readConfig():Boolean
		{
			//either json or xml
			var cfg:Object = Ldr.getAny(configToLoad);
			if((cfg is XML || cfg is Object) && !(cfg is ByteArray))
			{
				if(onConfigLoaded != null)
				{
					if(onConfigLoaded.length > 0)
						onConfigLoaded(cfg);
					else
						onConfigLoaded();
				}
				U.CONFIG = cfg;
				if(cfg.hasOwnProperty('remote') && cfg.remote != null)
				{
					var newRemotes:Array = [];
					for each (var o:Object in cfg.remote)
						newRemotes.push(o);
					NetworkSettings.appRemoteAddresses = newRemotes;
				}
				if(cfg.hasOwnProperty('gateway') && cfg.gateway != null)
					NetworkSettings.gatewayPath = cfg.gateway;
				if(cfg.hasOwnProperty('files') && cfg.files != null)
					configDefinedFiles = cfg;
				U.log('[Flow][configReaded] version:', cfg.hasOwnProperty('date') ? cfg.date : null);
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
			Ldr.load(files, filesLoaded,fileProgressListener);
			files = null;
				
		}
		protected function fileProgressListener(fname:String):void
		{
			var p:Number = (Ldr.numAllLoaded+ Ldr.numAllSkipped)/Ldr.numAllQueued;
			U.log('progress:', p* 100 + '%');
			if(onFilesLoadProgress != null)
				onFilesLoadProgress(p);
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
			updateFiles = null;
		}
	}
}
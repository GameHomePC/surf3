package
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.display.Loader;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.utils.Timer;
	import flash.utils.ByteArray;
	import flash.external.ExternalInterface;
	import flash.display.LoaderInfo;
	
	import ru.inspirit.surf.SURFOptions;
	import ru.inspirit.surf.ASSURF;
	import ru.inspirit.surf.IPoint;
	
	import ru.inspirit.surf_example.MatchElement;
	import ru.inspirit.surf_example.utils.SURFUtils;
	import ru.inspirit.surf_example.utils.QuasimondoImageProcessor;
	
	[SWF(width="640", height="360")]
	
	public class Main extends Sprite 
	{
		
		private static const SCALE:Number = 1.5;
		private static const SCALE_MAT:Matrix = new Matrix(1/SCALE, 0, 0, 1/SCALE, 0, 0);
		private static const ORIGIN:Point = new Point();
		
		private var _maxCounter:Number;
		private var _counter:Number = 0;
		private var _obj_bmds:Object = {};
		
		private var _view:Sprite;
		private var _bg:Bitmap;
		private var _bg_matrix:Matrix;
		private var _screenBitmap:Bitmap;
		private var _cameraImage:CameraImage;
		private var _cameraImageBitmap:BitmapData;
		private var _stageWidth:uint;
		private var _stageHeight:uint;
		private var _overlay:Shape;
		private var _buffer:BitmapData;
		private var _quasimondoProcessor:QuasimondoImageProcessor;
		
		public var bmds:Array = [];
		public var matchEls:Vector.<MatchElement> = new Vector.<MatchElement>();
		public var surf:ASSURF;
		public var surfOptions:SURFOptions;
		
		public function Main() 
		{
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			
			loadMarkers(create)
		}
		
		private function addExternal():void
		{
			ExternalInterface.addCallback('_createScreen', function():void {
				
				var stageBitmap:BitmapData = new BitmapData(_stageWidth, _stageHeight);
				stageBitmap.draw(stage);
				
				var screen:MyCamera = new MyCamera();
				var bmd:BitmapData = screen.crop(stageBitmap, _stageWidth, _stageHeight);
				
				screen.saveServer(bmd, function(data:String):void {
					ExternalInterface.call('_createScreen', data);
				});
				
			});
			
			ExternalInterface.addCallback('_pointMatchFactor', onMatchFactorChange);
			ExternalInterface.addCallback('_pointsThreshold', onThresholdChange);
			ExternalInterface.addCallback('_imageProcessor', onCorrectLevels);
		}
		
		private function create():void
		{
			_stageWidth = stage.stageWidth;
			_stageHeight = stage.stageHeight;
			
			addExternal();
			
			_view = new Sprite();
			_view.x = 0;
			_view.y = 0;
			
			_screenBitmap = new Bitmap();
			_view.addChild(_screenBitmap);
			
			_overlay = new Shape();
			_view.addChild(_overlay);
			
			_bg = new Bitmap();
			_bg.x = 0;
			_bg.y = 0;
			_view.addChild(_bg);
			
			_cameraImage = new CameraImage(_stageWidth, _stageHeight, 30);
			_cameraImageBitmap = _cameraImage._bitmapImage;
			
			_screenBitmap.bitmapData = _cameraImageBitmap;
			
			surfOptions = new SURFOptions(int(_stageWidth / SCALE), int(_stageHeight / SCALE), 200, 0.001, true, 4, 4, 2);
			surf = new ASSURF(surfOptions);
			surf.pointMatchFactor = 0.3;
			
			_buffer = new BitmapData(surfOptions.width, surfOptions.height, false, 0x00);
			_buffer.lock();
			
			_quasimondoProcessor = new QuasimondoImageProcessor(_buffer.rect);
			
			surf.imageProcessor = _quasimondoProcessor;
			
			addChild(_view);
			
			initMatchElements();
			
			_cameraImage.addEventListener(Event.RENDER, render);
		}
		
		private function render(event:Event):void
		{
			var gfx:Graphics = _overlay.graphics;
			gfx.clear();
			
			_buffer.draw(_cameraImage._bitmapImage, SCALE_MAT);
			
			var ipts:Vector.<IPoint> = surf.getInterestPoints(_buffer);
			// SURFUtils.drawIPoints(gfx, ipts, SCALE);
			
			
			var len:uint = bmds.length;
			var i:uint;
			var el:MatchElement;
			
			var matches:Array = [];
			
			for (i = 0; i < len; i++) {
				el = matchEls[i];
				el.matchCount = surf.getMatchesToPointsData(el.pointsCount, el.pointsData).length;
				if (el.matchCount >= 4) {
					matches.push(el);
					drawBorder(bmds[i]);
				}
			}
			
			if (matches.length){
				_bg.visible = true;
			} else {
				_bg.visible = false;
			}
			
		}
		
		private function drawBorder(item:Object):void
		{

			var name:String = item.name;
			var background:BitmapData = item.background;
			
			_bg_matrix = new Matrix();
			_bg_matrix.scale(_stageWidth / background.width, 1);
			_bg.bitmapData = new BitmapData(_stageWidth, _stageHeight, true, 0x000000);
			_bg.bitmapData.draw(background, _bg_matrix);
			
			
			ExternalInterface.call('_detectImage', name);
		}
		
		private function initMatchElements():void
		{
			var len:uint = bmds.length;
			var i:uint;
			var el:MatchElement;
			
			var matchOptions:SURFOptions = new SURFOptions(320, 100, 400, 0.0001, true, 4, 4, 2);
			
			for (i = 0; i < len; i++) {
				el = new MatchElement();
				el.id = i;
				el.bitmap = bmds[i].bitmapdata;
				el.pointsData = new ByteArray();
				
				matchOptions.width = el.bitmap.width;
				matchOptions.height = el.bitmap.height;
				surf.changeSurfOptions(matchOptions);
				
				el.pointsCount = surf.getInterestPointsByteArray(el.bitmap, el.pointsData);
				
				matchEls[i] = el;
			}
			
			surf.changeSurfOptions(surfOptions);
		}
		
		private function loadMarkers(callback:Function):void
		{
			
			var flashvars:Boolean = true;
			var i:uint;
			var len:uint;
			var item:Object;
			var data:Array;
			
			if (flashvars) {
				
				var paramObj:Object = LoaderInfo(this.root.loaderInfo).parameters;
			
				try {
					
					if ('images' in paramObj){
						
						var dataMain:Object = JSON.parse(paramObj.images);
						data = dataMain.data;
						len = data.length;
						_maxCounter = len * 2;
						
						for (i = 0; i < len; i++) {
							item = data[i];
							newLoadMarkers(item, callback);
						}
						
					}
					
					
				} catch (err:Error) { }
				
			} else {
				
				data = [{
					links: {
						url: 'http://c2364.paas2.ams.modxcloud.com/assets/as3/webx/assets/markers/alpen-cold-1.jpg',
						background: 'http://c2364.paas2.ams.modxcloud.com/assets/as3/webx/assets/background/1.png'
					},
					name: 'boy'
				},{
					links: {
						url: 'http://c2364.paas2.ams.modxcloud.com/assets/as3/webx/assets/markers/checks.png',
						background: 'http://c2364.paas2.ams.modxcloud.com/assets/as3/webx/assets/background/2.png'
					},
					name: 'checks'
				},{
					links: {
						url: 'http://c2364.paas2.ams.modxcloud.com/assets/as3/webx/assets/markers/pinocchio.jpg',
						background: 'http://c2364.paas2.ams.modxcloud.com/assets/as3/webx/assets/background/3.png'
					},
					name: 'pinocchio'
				}];
				
				len = data.length;
				_maxCounter = len * 2;
				
				for (i = 0; i < len; i++) {
					item = data[i];
					newLoadMarkers(item, callback);
				}
				
			}
		}
		
		private function newLoadMarkers(item:Object, callback:Function):void
		{
			var name:String = item.name;
			var links:Object = item.links;
			var p:String;
			var value:String;
			for (p in links){
				if (p == 'url' || p == 'background') {
					if (!(name in _obj_bmds)) _obj_bmds[name] = {}; 	
					value = links[p];
					newLoadImage(name, p, value, callback);
				} else {
					continue;
				}
			}
			
		}
		
		private function newLoadImage(name:String, key:String, value:String, callback:Function):void
		{
			
			var item:Object = _obj_bmds[name];
			
			var requestLoader:URLRequest = new URLRequest(value);
			requestLoader.method = 'GET';
			
			var loader:Loader = new Loader();
			loader.load(requestLoader);
			
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, complete);
			
			function complete(event:Event):void
			{
				var bitmap:Bitmap = event.target.content;
				var bitmapData:BitmapData = bitmap.bitmapData;
				
				switch(key){
					case 'url':
						item['bitmapdata'] = bitmapData;
						break;
					case 'background':
						item['background'] = bitmapData;
						break;
				}
				
				_counter += 1;
				
				if (_counter == _maxCounter) {
					var newKey:String;
					var newDataKey:String;
					var newData:Object;
					
					for (newKey in _obj_bmds) {
						newData = _obj_bmds[newKey];
						
						bmds.push({
							name: newKey,
							bitmapdata: newData.bitmapdata,
							background: newData.background
						});
						
					}
					
					var timerCreate:Timer = new Timer(100, 1);
					timerCreate.start();
					timerCreate.addEventListener(TimerEvent.TIMER_COMPLETE, function(eventTimer:TimerEvent):void {
						callback();
					});
				}
				
			}
			
		}
		
		private function onCorrectLevels(value:Boolean):void
		{
			surf.imageProcessor = value ? _quasimondoProcessor : null;
			ExternalInterface.call('_imageProcessor', value);
		}
		
		private function onThresholdChange(value:Number):void
		{
			surf.pointsThreshold = value;
			ExternalInterface.call('_pointsThreshold', value);
		}
		
		private function onMatchFactorChange(value:Number):void
		{
			surf.pointMatchFactor = value;
			ExternalInterface.call('_pointMatchFactor', value);
		}
		
	}
	
}
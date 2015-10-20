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
		
		private var _view:Sprite;
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
		
		private function create():void
		{
			_stageWidth = stage.stageWidth;
			_stageHeight = stage.stageHeight;
			
			ExternalInterface.addCallback('_createScreen', function():void {
				
				var stageBitmap:BitmapData = new BitmapData(_stageWidth, _stageHeight);
				stageBitmap.draw(stage);
				
				var screen:MyCamera = new MyCamera();
				var bmd:BitmapData = screen.crop(stageBitmap, _stageWidth, _stageHeight);
				
				screen.saveServer(bmd, function(data:String):void {
					ExternalInterface.call('_createScreen', data);
				});
				
			});
			
			_view = new Sprite();
			_view.x = 0;
			_view.y = 0;
			
			_screenBitmap = new Bitmap();
			_view.addChild(_screenBitmap);
			
			_overlay = new Shape();
			_view.addChild(_overlay);
			
			_cameraImage = new CameraImage(_stageWidth, _stageHeight, 30);
			_cameraImageBitmap = _cameraImage._bitmapImage;
			
			_screenBitmap.bitmapData = _cameraImageBitmap;
			
			surfOptions = new SURFOptions(int(_stageWidth / SCALE), int(_stageHeight / SCALE), 200, 0.006, true, 4, 4, 2);
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
			
			var matched:Vector.<MatchElement> = new Vector.<MatchElement>();
			var matchedStr:Vector.<String> = new Vector.<String>();
			
			var len:uint = bmds.length;
			var i:uint;
			var el:MatchElement;
			
			for (i = 0; i < len; i++) {
				el = matchEls[i];
				el.matchCount = surf.getMatchesToPointsData(el.pointsCount, el.pointsData).length;
				if (el.matchCount >= 4){
					matched.push(el);
					matchedStr.push(bmds[i].name +'-' + el.matchCount);
					ExternalInterface.call('_detectImage', bmds[i].name);
				}
			}
			
		}
		
		private function initMatchElements():void
		{
			var len:uint = bmds.length;
			var i:uint;
			var el:MatchElement;
			
			var matchOptions:SURFOptions = new SURFOptions(320, 240, 400, 0.0001, true, 4, 4, 2);
			
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
						
						for (i = 0; i < len; i++) {
							item = data[i];
							loadMarker(item, i, len, callback);
						}
						
					}
					
					
				} catch (err:Error) { }
				
			} else {
				
				data = [{
					url: 'http://c2364.paas2.ams.modxcloud.com/assets/as3/webx/assets/markers/boy.jpg',
					name: 'boy'
				}];
				
				len = data.length;
				
				for (i = 0; i < len; i++) {
					item = data[i];
					loadMarker(item, i, len, callback);
				}
				
			}
		}
		
		private function loadMarker(item:Object, index:uint, len:uint, callback:Function):void
		{
			
			var url:String = item.url;
			var name:String = item.name;
			
			var requestLoader:URLRequest = new URLRequest(url);
			requestLoader.method = 'GET';
			
			var loader:Loader = new Loader();
			loader.load(requestLoader);
			
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, complete);
			
			function complete(event:Event):void
			{
				var bitmap:Bitmap = event.target.content;
				var bitmapData:BitmapData = bitmap.bitmapData;
				
				trace(bitmapData, bmds.length);
				
				bmds.push({
					name: name,
					bitmapdata: bitmapData
				});
				
				if (index == len - 1){
					var timerCreate:Timer = new Timer(100, 1);
					timerCreate.start();
					timerCreate.addEventListener(TimerEvent.TIMER_COMPLETE, function(eventTimer:TimerEvent):void {
						callback();
					});
				}
			}
			
		}
		
	}
	
}
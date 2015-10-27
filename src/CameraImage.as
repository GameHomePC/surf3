package 
{
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.events.EventDispatcher;
	import flash.media.Camera;
	import flash.media.Video;
	import flash.utils.Timer;
	import flash.external.ExternalInterface;
	
	public class CameraImage extends EventDispatcher
	{
		
		public var _bitmapImage:BitmapData;
		public var _addExternal:Boolean = true;
		private var _frameRate:uint = 30;
		private var _width:uint = 100;
		private var _height:uint = 100;
		private var _camera:Camera;
		private var _video:Video;
		private var _timer:Timer;
		private var _timerInit:Timer;
		
		public function CameraImage(width:uint, height:uint, frameRate:uint = 30) 
		{	
			_width = width;
			_height = height;
			_frameRate = frameRate;
			
			_bitmapImage = new BitmapData(_width, _height);
			
			if (Camera.names.length) {
				_camera = Camera.getCamera();
				
				if (_camera != null) {
					_camera.setMode(_width, _height, _frameRate, true);
					_timerInit = new Timer(100, 1);
					_timerInit.start();
					_timerInit.addEventListener(TimerEvent.TIMER_COMPLETE, timerInit);
				} else {
					cameraError('Камера не найдена');
				}
				
			} else {
				cameraError('Камера не найдена');
			}
			
		}
		
		private function cameraError(camErr:String):void
		{
			if (_addExternal){
				ExternalInterface.call('_cameraError', camErr);
			} else {
				trace(camErr);
			}
		}
		
		private function cameraInit():void
		{
			_video = new Video(_camera.width, _camera.height);
			_video.attachCamera(_camera);
			
			_timer = new Timer(1000 / _frameRate);
			_timer.start();
			_timer.addEventListener(TimerEvent.TIMER, draw);
		}
		
		private function draw(event:TimerEvent = null):void
		{
			_bitmapImage.draw(_video);
			dispatchEvent(new Event(Event.RENDER));
		}
		
		private function timerInit(event:TimerEvent):void
		{
			cameraInit();
		}
		
	}

}
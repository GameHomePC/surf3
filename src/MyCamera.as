package 
{
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.net.FileReference;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.utils.ByteArray;
	
	import com.adobe.images.JPGEncoder;
	
	public class MyCamera 
	{
		
		public var requestUrl:String = 'php/save.php';
		
		public function MyCamera() 
		{
			
		}
		
		public function crop(bitmapdata:BitmapData, width:uint, height:uint, x:uint = 0, y:uint = 0):BitmapData
		{
			var bmd:BitmapData = new BitmapData(bitmapdata.width, bitmapdata.height);
			bmd.draw(bitmapdata);
			
			var bmdNew:BitmapData = new BitmapData(width, height);
			var j:int, i:int;
			
			for (i = 0; i < height; i++) {
				for (j = 0; j < width; j++) {
					bmdNew.setPixel(j, i, bmd.getPixel(x + j, y + i));
				}
			}
			
			return bmdNew;
		}
		
		public function getBytesBitmapData(bitmapdata:BitmapData):ByteArray
		{
			var jpgEncoder:JPGEncoder = new JPGEncoder(100);
			var bytes:ByteArray = jpgEncoder.encode(bitmapdata);
			return bytes;
		}
		
		public function getName():String
		{
			var date:Date = new Date();
			var time:Number = date.getTime();
			var name:String = (Math.round(Math.random() * 100000)).toString() + '_' + time.toString();
			return name;
		}
		
		public function saveClient(bitmapdata:BitmapData):void
		{
			var bytes:ByteArray = getBytesBitmapData(bitmapdata);
			var name:String = getName();
			
			var file:FileReference = new FileReference();
			file.save(bytes, name + '.png');
		}
		
		public function saveServer(bitmapdata:BitmapData, callback:Function):void
		{
			var response:Object = {};
			var bytes:ByteArray = getBytesBitmapData(bitmapdata);
			
			var header:URLRequestHeader = new URLRequestHeader('Content-type', 'application/octet-stream');
			
			var urlRequest:URLRequest = new URLRequest();
			urlRequest.url = requestUrl;
			urlRequest.method = 'POST';
			urlRequest.data = bytes;
			urlRequest.requestHeaders.push(header);
			
			var loader:URLLoader = new URLLoader();
			loader.load(urlRequest);
			
			loader.addEventListener(Event.COMPLETE, complete);
			loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, httpStatus);
			loader.addEventListener(IOErrorEvent.IO_ERROR, ioError);
			loader.addEventListener(ProgressEvent.PROGRESS, progress);
			loader.addEventListener(Event.OPEN, open);
			
			function allEventFn(data:Object):void
			{
				callback(JSON.stringify(data));
			}
			
			function complete(event:Event):void
			{
				response.type = event.type;
				allEventFn(event.type);
			}
			
			function httpStatus(event:HTTPStatusEvent):void
			{
				response.type = event.type;
				allEventFn(event.type);
			}
			
			function ioError(event:IOErrorEvent):void
			{
				response.type = event.type;
				allEventFn(event.type);
			}
			
			function progress(event:ProgressEvent):void
			{
				response.type = event.type;
				allEventFn(event.type);
			}
			
			function open(event:Event):void
			{
				response.type = event.type;
				allEventFn(event.type);
			}
		}
		
	}

}
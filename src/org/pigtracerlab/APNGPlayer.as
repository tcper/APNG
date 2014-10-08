package org.pigtracerlab {

  import flash.display.Sprite;
  import flash.events.Event;
  import flash.net.URLLoader;
  import flash.net.URLRequest;
  import flash.net.URLLoaderDataFormat;
  import flash.net.FileReference;
  import flash.net.FileFilter;
  import flash.display.Loader;
  import flash.events.IOErrorEvent;
  import flash.display.Bitmap;
  import flash.utils.ByteArray;
  import pngutil.PngData;
  import pngutil.PngFrames;

  public class APNGPlayer extends Sprite {
    // プロパティ
    private var loader:URLLoader;
    private var file:FileReference;
    private static var typeFilter:Array;
    private var _loader:Loader;
    private var decoder:PngData;
    private var frames:PngFrames;
    private var container:Bitmap;
    private var currentFrame:int = 0;
    private var totalFrames:uint = 1;
    private var autoPlay:Boolean = false;
    public static const APNG_LOADED:String = "apng_loaded";
    public static const NOT_APNG:String = "not_apng";

    // コンストラクタ
    public function APNGPlayer(auto:Boolean = false) {
      autoPlay = auto;
    }

    // メソッド
    public function load(filePath:String):void {
      loader = new URLLoader();
      loader.dataFormat = URLLoaderDataFormat.BINARY;
      loader.addEventListener(Event.COMPLETE, loaded, false, 0, true);
      loader.addEventListener(IOErrorEvent.IO_ERROR, ioerror, false, 0, true);
      loader.load(new URLRequest(filePath));
    }
    private function loaded(evt:Event):void {
      loader.removeEventListener(Event.COMPLETE, loaded);
      loader.removeEventListener(IOErrorEvent.IO_ERROR, ioerror);
      decode(loader.data);
      dispatchEvent(evt);
    }
    public function asset(Data:Class):void {
      decode(new Data());
      dispatchEvent(new Event(Event.COMPLETE));
    }
    public function upload():void {
      file = new FileReference();
      file.addEventListener(Event.CANCEL, cancel, false, 0, true);
      file.addEventListener(Event.SELECT, select, false, 0, true);
      file.addEventListener(Event.COMPLETE, uploaded, false, 0, true);
      file.addEventListener(IOErrorEvent.IO_ERROR, ioerror, false, 0, true);
      var fileFilter:FileFilter = new FileFilter("画像ファイル", "*.png");
      typeFilter = [fileFilter];
      file.browse(typeFilter);
    }
    private function cancel(evt:Event):void {
      dispatchEvent(evt);
    }
    private function select(evt:Event):void {
      file.load();
      dispatchEvent(evt);
    }
    private function uploaded(evt:Event):void {
      dispatchEvent(evt);
      try {
        decode(file.data);
        dispatchEvent(evt);
      } catch (err:Error) {
        trace(err.message);
        dispatchEvent(new Event(NOT_APNG));
      }
    }
    private function ioerror(evt:IOErrorEvent):void {
      trace(evt.text);
      dispatchEvent(evt);
    }
    private function decode(data:ByteArray):void {
      decoder = new PngData();
      decoder.data = data;
      decoder.addEventListener(Event.COMPLETE, decoded, false, 0, true);
      decoder.addEventListener(IOErrorEvent.IO_ERROR, ioerror, false, 0, true);
      decoder.loadToPngFrames();
    }
    private function decoded(evt:Event):void {
      decoder.removeEventListener(IOErrorEvent.IO_ERROR, ioerror);
      decoder.removeEventListener(Event.COMPLETE, decoded);
      frames = decoder.pngFrames;
      totalFrames = frames.numFrames;
      decoder.release();
      container = new Bitmap();
      addChild(container);
      update();
      if (autoPlay) play();
      dispatchEvent(new Event(APNG_LOADED));
    }
    public function play():void {
      frames.resume(currentFrame);
      addEventListener(Event.ENTER_FRAME, update, false, 0, true);
    }
    public function stop():void {
      removeEventListener(Event.ENTER_FRAME, update);
    }
    private function update(evt:Event = null):void {
      if (frames.updateCurrentFrame()) {
        currentFrame = frames.currentFrameIndex;
        container.bitmapData = frames.currentFrameBmp;
      }
    }
    public function clear():void {
      if (container) container.bitmapData = null;
    }

  }

}
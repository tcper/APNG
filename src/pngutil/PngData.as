package pngutil 
{
	import flash.display.Bitmap;
	import flash.display.Loader;
	import flash.events.*;
	import flash.utils.ByteArray;
	import flash.display.BitmapData;
	
	/**
	* ...
	* @author Default
	*/
	public class PngData extends EventDispatcher
	{
		public static const SIZE_OF_SIGNATURE:uint = 8;
		public static const SIGNATURE0:uint = 0x89504E47;
		public static const SIGNATURE1:uint = 0x0D0A1A0A;
		
		private var _chunks:Array;
		private var _defaultIsFirstFrame:Boolean;
		private var _imageHeaderChunk:ImageHeaderChunk;
		private var _animationControlChunk:AnimationControlChunk;
		private var _transparencyChunk:TransparencyChunk;
		
		private var _loadtmp_frameIndex:int;
		private var _loadtmp_chunkIndex:int;
		private var _loadtmp_frameData:Array;
		private var _loadtmp_pngFrames:PngFrames;
		private var _loadtmp_loader:Loader;
		
		public function PngData() 
		{
		}
		
		public function set bitmapData(bmp:BitmapData):void
		{
			setBitmapData(bmp, true, false);
		}
		
		public function get pngFrames():PngFrames
		{
			if (!loadedAllFrames() )
				throw new Error("PngData : png frames are not loaded yet.");
			
			return _loadtmp_pngFrames;
		}
		
		public function set pngFrames(pngFrames:PngFrames):void
		{
			setPngFrames(pngFrames, false);
		}
		
		public function get imageHeaderChunk():ImageHeaderChunk
		{
			if (_chunks.length == 0)
				throw new Error("PngData : chunk is empty.");
			
			return _imageHeaderChunk;
		}
		
		public function get animationControlChunk():AnimationControlChunk
		{
			if (_chunks.length == 0)
				throw new Error("PngData : chunk is empty.");
			
			return _animationControlChunk;
		}
		
		public function get transparencyChunk():TransparencyChunk
		{
			if (_chunks.length == 0)
				throw new Error("PngData : chunk is empty.");
			
			return _transparencyChunk;
		}
		
		// png画像ファイルのバイナリデータを受け取り、Chunk毎に分解して保持する。
		public function set data(buff:ByteArray):void
		{
			release();
			
			if (!checkSignature(buff) )
				throw new Error("PngData : Signature is not PNG.");
			
			_chunks = new Array();
			loadloop:
			while (buff.bytesAvailable > 0)
			{
				var c:Chunk = ChunkFactory.createFromBytes(buff);
				_chunks.push(c);
				switch(c.type)
				{
				case ImageEndChunk.TYPE:
					break loadloop;
				case ImageHeaderChunk.TYPE:
					_imageHeaderChunk = c as ImageHeaderChunk;
					break;
				case AnimationControlChunk.TYPE:
					_animationControlChunk = c as AnimationControlChunk;
					break;
				case TransparencyChunk.TYPE:
					_transparencyChunk = c as TransparencyChunk;
					break;
				}
			}
		}
		
		// Chunkのバイナリデータを連結してpng画像ファイルの形式で返す。
		public function get data():ByteArray
		{
			if (_chunks == null)
				return null;
			
			var res:ByteArray = new ByteArray();
			// %89PNG\r\n%1A\n
			res.writeUnsignedInt(SIGNATURE0);
			res.writeUnsignedInt(SIGNATURE1);
			
			for each(var c:Chunk in _chunks)
			{
				res.writeBytes(c.bytes, 0, c.bytes.length);
			}
			
			return res;
		}
		
		// APNGの各フレーム毎の画像を、個別の画像データに分解して返す。
		// 各画像のデータはPngDataクラスの形式。
		// 注) _chunksは_frameData内で共有される
		public function get frameData():Array
		{
			if (_chunks.length == 0)
				throw new Error("PngData : chunks are empty.");
			
			var res:Array = new Array();
			_defaultIsFirstFrame = false;
			var countFrames:uint = 0;
			var numFrames:uint = 0;
			
			var frameChunks:Array;
			var frameChunk:FrameControlChunk;
			var framePngData:PngData;
			
			var headerChunk:ImageHeaderChunk;
			var endChunk:ImageEndChunk = _chunks[_chunks.length - 1];
			
			// IHDR、IDAT、IENDとAPNG関係以外のチャンクをsharedChunksに
			var sharedChunks:Array = new Array();
			for each(var c:Chunk in _chunks)
			{
				var type:uint = c.type;
				if ( (type != ImageHeaderChunk.TYPE) &&
				     (type != ImageDataChunk.TYPE) &&
				     (type != ImageEndChunk.TYPE) &&
					 (type != AnimationControlChunk.TYPE) &&
					 (type != FrameControlChunk.TYPE) &&
					 (type != FrameDataChunk.TYPE) )
				{
					sharedChunks.push(c);
				}
				else if (type == AnimationControlChunk.TYPE)
				{
					numFrames = (c as AnimationControlChunk).numFrames;
				}
				else if (type == FrameControlChunk.TYPE)
				{
					countFrames++;
				}
				else if ( (type == ImageDataChunk.TYPE ) && (countFrames > 0) )
				{
					_defaultIsFirstFrame = true; // デフォルト画像がアニメーションに含まれる
				}
			}
			
			// フレーム数の整合性チェック
			if (numFrames != countFrames)
			{
				throw new Error("PngData : num_frames is not match.");
			}
			
			var i:int;
			// デフォルト画像がアニメーションに使用されない場合
			if (!_defaultIsFirstFrame)
			{
				framePngData = new PngData();
				frameChunks = new Array();
				frameChunks.push(_chunks[0] ); // IHDR
				frameChunks = frameChunks.concat(sharedChunks);
				for (i = 0; i < _chunks.length; i++)
				{
					c = _chunks[i];
					type = c.type;
					if (type == ImageDataChunk.TYPE) // IDATをframeChunksに追加
					{
						frameChunks.push(c);
					}
					else if (type == FrameControlChunk.TYPE) // 次のフレームを発見したら終了
					{
						break;
					}
				}
				frameChunks.push(endChunk);
				framePngData._chunks = frameChunks;
				res.push(framePngData);
			}
			
			// 最初のFrameControlChunkを探す
			for (; i < _chunks.length; i++)
				if (_chunks[i].type == FrameControlChunk.TYPE)
					break;
			
			// 各フレームの画像を取得
			while (i < _chunks.length)
			{
				frameChunk = _chunks[i]; // ループの先頭では必ず(_chunks[i]  is FrameControlChunk)
				framePngData = new PngData();
				frameChunks = new Array();
				
				// ImageHeaderChunkをコピーし、各フレームのサイズに変更
				headerChunk = _chunks[0].copy();
				headerChunk.width = frameChunk.width;
				headerChunk.height = frameChunk.height;
				headerChunk.calcCRC();
				frameChunks.push(headerChunk);
				
				frameChunks = frameChunks.concat(sharedChunks);
				
				// 各フレームの画像チャンクを選びだす
				for (i++; i < _chunks.length; i++)
				{
					c = _chunks[i];
					type = c.type;
					if (type == ImageDataChunk.TYPE)
					{
						frameChunks.push(c);
					}
					else if (type == FrameDataChunk.TYPE)
					{
						// FrameDataChunkはImageDataChunkに変換してから追加
						frameChunks.push( (c as FrameDataChunk).toImageData() );
					}
					else if (type == FrameControlChunk.TYPE)
					{
						break;
					}
				}
				
				frameChunks.push(endChunk);
				framePngData._chunks = frameChunks;
				res.push(framePngData);
			}
			
			return res;
		}
		
		// デフォルト画像がアニメーションの最初に使用されているか
		public function get defaultIsFirstFrame():Boolean
		{
			return _defaultIsFirstFrame;
		}
		
		// TransparencyChunkの追加、または、入れ替え
		// カラータイプがCOLOR_TYPE_GRAYの場合、valueは下位8bitのみ使用
		// COLOR_TYPE_RGB24の場合、valueはRGB8bitずつで右詰め。上位8bitは無視。
		// それ以外のカラータイプは未対応
		public function setTransparency(value:uint):void
		{
			var tchunk:TransparencyChunk = new TransparencyChunk();
			
			var headerChunk:ImageHeaderChunk = _chunks[0];
			switch(headerChunk.colorType)
			{
			case ImageHeaderChunk.COLOR_TYPE_GRAY:
				tchunk.createGrayBytes(value);
				break;
			case ImageHeaderChunk.COLOR_TYPE_RGB24:
				tchunk.createRGBBytes(value);
				break;
			case ImageHeaderChunk.COLOR_TYPE_INDEXES:
				throw new Error("PngData : cannot use transparency property  if colorType==indexes.");
			default:
				throw new Error("PngData : cannot have tRNS chunk. colorType = " + headerChunk.colorType);
			}
			
			// tRNSチャンクがあるならば、入れ替え
			var idatIndex:int = 0;
			for (var i:int = 0; i < _chunks.length; i++)
			{
				var c:Chunk = _chunks[i];
				if (c.type == TransparencyChunk.TYPE)
				{
					_chunks[i] = tchunk;
					break;
				}
				// 先頭のIDATチャンクの位置を記憶
				else if (c.type == ImageDataChunk.TYPE)
				{
					idatIndex = i;
					break;
				}
			}
			
			// なければIDATチャンクの前に挿入
			if (idatIndex != 0)
			{
				_chunks.splice(idatIndex, 0, tchunk);
			}
		}
		
		public function setBitmapData(bmp:BitmapData, transparent:Boolean = true, grayscale:Boolean = false):void
		{
			var pngFrames:PngFrames = new PngFrames(false, 0, transparent);
			pngFrames.defaultBmp = bmp;
			
			setPngFrames(pngFrames, grayscale);
		}
		
		public function setPngFrames(pngFrames:PngFrames, grayscale:Boolean = false):void
		{
			release();
			_defaultIsFirstFrame = pngFrames.defaultIsFirstFrame;
			_chunks = ChunkFactory.createFromPngFrames(pngFrames, grayscale);
			
			_imageHeaderChunk = _chunks[0] as ImageHeaderChunk;
			for each(var c:Chunk in _chunks)
			{
				if (c.type == AnimationControlChunk.TYPE)
				{
					_animationControlChunk = c as AnimationControlChunk;
					break;
				}
			}
		}
		
		public function checkSignature(buff:ByteArray):Boolean
		{
			if (buff.bytesAvailable < SIZE_OF_SIGNATURE)
				return false;
			
			// 最初の4バイトをチェック
			if (buff.readUnsignedInt() != SIGNATURE0)
				return false;
			
			return buff.readUnsignedInt() == SIGNATURE1;
		}
		
		public function release():void
		{
			_chunks = null;
			_defaultIsFirstFrame = false;
			_imageHeaderChunk = null;
			_animationControlChunk = null;
			_transparencyChunk = null;
			
			if (_loadtmp_loader != null)
				_loadtmp_loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onLoadFrameComplete);
			_loadtmp_chunkIndex = 0;
			_loadtmp_frameData = null;
			_loadtmp_frameIndex = 0;
			_loadtmp_loader = null;
			_loadtmp_pngFrames = null;
		}
		
		// _chunksの内容からPngFramesクラスのインスタンスを作成する。
		// 非同期処理なので、Event.COMPLETEのイベントハンドラでPngFramesを受け取る。
		// 作成後pngFramesプロパティにアクセスするとインスタンスが得られる。
		public function loadToPngFrames():void
		{
			if (_chunks.length == 0)
				throw new Error("PngData : chunk is empty.");
			
			var numPlays:uint = _animationControlChunk.numPlays;
			var transparent:Boolean =
				( (_imageHeaderChunk.colorType & ImageHeaderChunk.COLOR_TYPE_BIT_ALPHA) > 0)
				|| (_transparencyChunk != null);
			
			_loadtmp_frameIndex = 0;
			_loadtmp_chunkIndex = 0;
			_loadtmp_frameData = this.frameData;
			_loadtmp_pngFrames = new PngFrames(_defaultIsFirstFrame, numPlays, transparent);
			if (_loadtmp_loader == null)
			{
				_loadtmp_loader = new Loader();
				_loadtmp_loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoadFrameComplete);
				_loadtmp_loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
			}
			
			// 最初のフレームorデフォルト画像から順番に読み込む
			_loadtmp_loader.loadBytes( (_loadtmp_frameData[0] as PngData).data);
			_loadtmp_frameData[0] = null;
		}
		
		// 最初のフレームから順番に1フレームずつ画像を読み込む
		private function onLoadFrameComplete(event:Event):void
		{
			var loader:Loader = event.target.loader as Loader;
			var bmp:BitmapData = (loader.content as Bitmap).bitmapData;
			
			// デフォルト画像がアニメーションに含まれない場合
			if ( (_loadtmp_frameIndex == 0) && (!_defaultIsFirstFrame) )
			{
				_loadtmp_pngFrames.defaultBmp = bmp;
			}
			// APNGフレームの追加
			else
			{
				var frameControlChunk:FrameControlChunk = null;
				while (_loadtmp_chunkIndex < _chunks.length)
				{
					var c:Chunk = _chunks[_loadtmp_chunkIndex];
					if (c.type == FrameControlChunk.TYPE)
					{
						frameControlChunk = c as FrameControlChunk;
						_loadtmp_chunkIndex++;
						break;
					}
					
					_loadtmp_chunkIndex++;
				}
				
				if (frameControlChunk == null)
				{
					throw new Error("PngData : fcTL chunk is not found.");
				}
				
				with (frameControlChunk)
				{
					var pngFrame:PngFrame = new PngFrame(bmp, XOffset, YOffset, delayNum, delayDen, disposeOp, blendOp);
					_loadtmp_pngFrames.add(pngFrame);
				}
			}
			_loadtmp_frameIndex++;
			
			if (loadedAllFrames() )
			{
				// コンプリートイベント送出
				dispatchEvent(new Event(Event.COMPLETE) );
				
				_loadtmp_frameData = null;
				_loadtmp_loader = null;
			}
			else
			{
				// 次の画像をロード
				_loadtmp_loader.loadBytes( (_loadtmp_frameData[_loadtmp_frameIndex] as PngData).data);
				_loadtmp_frameData[_loadtmp_frameIndex] = null;
			}
		}
		
		// _loadtmp_loaderでエラーイベントが発生した場合、targetをthisに変えて投げる。
		private function onIOError(event:Event):void
		{
			var ioErrorEvent:IOErrorEvent = new IOErrorEvent(
				IOErrorEvent.IO_ERROR,
				event.bubbles,
				event.cancelable,
				"PngData : load frame error.");
			if (hasEventListener(IOErrorEvent.IO_ERROR) )
				dispatchEvent(ioErrorEvent);
		}
		
		private function loadedAllFrames():Boolean
		{
			if (_loadtmp_pngFrames == null)
				return false;
			if (_loadtmp_pngFrames.defaultBmp == null)
				return false;
			return _loadtmp_pngFrames.numFrames == this.animationControlChunk.numFrames;
		}
	}
}
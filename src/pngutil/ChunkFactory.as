package pngutil 
{
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	import flash.display.BitmapData;
	
	/**
	* ...
	* @author Default
	*/
	public class ChunkFactory
	{
		public static const SIZE_OF_PIXEL_RGBA:uint = 4;
		public static const SIZE_OF_PIXEL_RGB:uint = 3;
		public static const SIZE_OF_PIXEL_GRAY_ALPHA:uint = 2;
		
		public static const GRAY_COEFFICIENT_R:Number = 0.298912;
		public static const GRAY_COEFFICIENT_G:Number = 0.586611;
		public static const GRAY_COEFFICIENT_B:Number = 0.114478;
		
		public static function createFromBytes(buff:ByteArray):Chunk
		{
			var base:uint = buff.position;
			
			// size,type,crcの4バイトずつで12バイト無ければエラー
			if (buff.bytesAvailable < Chunk.SIZE_OF_EMPTY_CHUNK)
				throw new Error("ChunkFactory : size error. buff.length = " + buff.length);
			
			var size:uint = buff.readUnsignedInt();
			var type:uint = buff.readUnsignedInt();
			
			// chunk全体のサイズ(size,type,data,crc)があるかをチェック
			buff.position = base;
			if(buff.bytesAvailable < Chunk.SIZE_OF_EMPTY_CHUNK + size)
				throw new Error("ChunkFactory : size error. size = " + size + "buff.available = " + buff.bytesAvailable);
			
			var chunkdata:ByteArray = new ByteArray();
			buff.readBytes(chunkdata, 0, Chunk.SIZE_OF_EMPTY_CHUNK + size);
			
			// buffに書かれているCRCと実際のCRCが一致するかを確認
			buff.position -= Chunk.SIZE_OF_CRC;
			var crc:uint = buff.readUnsignedInt();
			//typeとdataのCRCをチェック
			if (crc != CRC32.check(chunkdata, Chunk.INDEX_OF_TYPE, Chunk.SIZE_OF_TYPE + size) )
			{
				buff.position = base + Chunk.INDEX_OF_TYPE;
				var typestr:String = encodeURI(buff.readUTFBytes(Chunk.SIZE_OF_TYPE) );
				throw new Error("ChunkFactory : " + typestr + " CRC error.");
			}
			
			var res:Chunk;
			switch(type)
			{
			case ImageHeaderChunk.TYPE:
				res = new ImageHeaderChunk();
				break;
			case ImageDataChunk.TYPE:
				res = new ImageDataChunk();
				break;
			case ImageEndChunk.TYPE:
				res = new ImageEndChunk();
				break;
			case AnimationControlChunk.TYPE:
				res = new AnimationControlChunk();
				break;
			case FrameControlChunk.TYPE:
				res = new FrameControlChunk();
				break;
			case FrameDataChunk.TYPE:
				res = new FrameDataChunk();
				break;
			case TransparencyChunk.TYPE:
				res = new TransparencyChunk();
				break;
			case PalletChunk.TYPE:
				res = new PalletChunk();
				break;
			default:
				res = new UnknownChunk();
			}
			res.bytes = chunkdata;
			trace(res.toString() );
			return res;
		}
		
		// Chunkの配列で返す
		public static function createFromPngFrames(
			pngFrames:PngFrames,
			grayscale:Boolean = false):Array
		{
			if(pngFrames == null)
				throw new Error("ChunkFactory : PngFrames is null.");
			if (pngFrames.defaultBmp == null)
				throw new Error("ChunkFactory : default image is not found.");
			
			var res:Array = new Array();
			var isAPNG:Boolean = pngFrames.numFrames > 0;
			var colorType:uint;
			var bitDepth:uint = ImageHeaderChunk.DEFAULT_BIT_DEPTH;
			var bmp:BitmapData;
			var transparent:Boolean = pngFrames.transparent;
			
			// カラータイプ、ビット数を設定
			if (grayscale)
			{
				colorType = transparent ? ImageHeaderChunk.COLOR_TYPE_GRAY_ALPHA
				                                  : ImageHeaderChunk.COLOR_TYPE_GRAY;
			}
			else
			{
				// 使用色数をチェック
				var palletIndexes:PalletIndexes = new PalletIndexes();
				var suitableBitDepth:uint = palletIndexes.add(pngFrames.defaultBmp, transparent);
				for (var i:int = 0; i < pngFrames.numFrames; i++)
				{
					suitableBitDepth = palletIndexes.add(pngFrames.frameAt(i).bmp, transparent);
				}
				if (suitableBitDepth == uint.MAX_VALUE) // 256色以上
				{
					colorType = transparent ? ImageHeaderChunk.COLOR_TYPE_RGBA32
													  : ImageHeaderChunk.COLOR_TYPE_RGB24;
				}
				else
				{
					bitDepth = suitableBitDepth;
					colorType = ImageHeaderChunk.COLOR_TYPE_INDEXES;
				}
			}
			
			// IHDRチャンク
			bmp = pngFrames.defaultBmp; // デフォルト画像用BitmapData
			var headerChunk:ImageHeaderChunk = new ImageHeaderChunk();
			headerChunk.createBytes(bmp.width, bmp.height, bitDepth, colorType);
			res.push(headerChunk);
			
			// acTLチャンク
			if (isAPNG)
			{
				var animationControlChunk:AnimationControlChunk = new AnimationControlChunk();
				animationControlChunk.createBytes(pngFrames);
				res.push(animationControlChunk);
			}
			
			// PLTE、tRNSチャンク
			if (colorType == ImageHeaderChunk.COLOR_TYPE_INDEXES)
			{
				var palletChunk:PalletChunk = new PalletChunk();
				palletChunk.createBytesFromRGBArray(palletIndexes.indexes);
				res.push(palletChunk);
				
				var transparencyChunk:TransparencyChunk = new TransparencyChunk();
				transparencyChunk.createBytesFromARGBArray(palletIndexes.indexes);
				if (!transparencyChunk.isEmpty)
				{
					res.push(transparencyChunk);
				}
			}
			
			// デフォルト画像がアニメーションに含まれない場合、IDATチャンクを追加。
			if (!pngFrames.defaultIsFirstFrame)
			{
				bmp = pngFrames.defaultBmp;
				var pixels:ByteArray =
					bitmapData2Bytes(bmp, colorType, transparent, bitDepth, palletIndexes);
				addImageOrFrameDataChunks(res, true, pixels);
			}
			
			// アニメーションの各フレームのチャンクを追加
			var sequenceNumber:uint = 0;
			for (i = 0; i < pngFrames.numFrames; i++)
			{
				// fcTLチャンク
				var frameControlChunk:FrameControlChunk = new FrameControlChunk();
				frameControlChunk.createBytes(sequenceNumber, pngFrames.frameAt(i) );
				res.push(frameControlChunk);
				sequenceNumber++;
				
				// IDATチャンク or fdATチャンク
				bmp = pngFrames.frameAt(i).bmp;
				pixels = bitmapData2Bytes(bmp, colorType, transparent, bitDepth, palletIndexes);
				sequenceNumber = addImageOrFrameDataChunks(
					res,
					pngFrames.defaultIsFirstFrame && (i == 0), // IDAT or fdAT
					pixels,
					sequenceNumber);
			}
			
			// IENDチャンク
			var footer:ImageEndChunk = new ImageEndChunk();
			footer.createDefaultBytes();
			res.push(footer);
			
			return res;
		}
		
		// BitmapDataからIDATのdata部を作成する
		private static function bitmapData2Bytes(
			bmp:BitmapData,
			colorType:uint,
			transparent:Boolean,
			bitDepth:uint,
			palletIndexes:PalletIndexes):ByteArray
		{
			var res:ByteArray;
			switch(colorType)
			{
			case ImageHeaderChunk.COLOR_TYPE_RGB24:
				res = createRawImageDataRGB24(bmp);
				break;
			case ImageHeaderChunk.COLOR_TYPE_RGBA32:
				res = createRawImageDataRGBA32(bmp);
				break;
			case ImageHeaderChunk.COLOR_TYPE_INDEXES:
				res = createRawImageDataIndexes(bmp, transparent, bitDepth, palletIndexes);
				break;
			case ImageHeaderChunk.COLOR_TYPE_GRAY:
				res = createRawImageDataGray(bmp);
				break;
			case ImageHeaderChunk.COLOR_TYPE_GRAY_ALPHA:
				res = createRawImageDataGrayAlpha(bmp);
				break;
			default:
				throw new Error("ChunkFactory : Unknown color type.");
			}
			
			res.compress();  // デフォルトのCompressionAlgorithm.ZLIB形式
			res.position = 0;
			return res;
		}
		
		// 引数chunksで指定された配列にデータチャンクを追加する。
		// isIDATがtureの場合IDATチャンクを、falseの場合fdATチャンクを追加。
		private static function addImageOrFrameDataChunks(
			chunks:Array,
			isIDAT:Boolean,
			pixels:ByteArray,
			sequenceNumber:uint = 0):uint
		{
			// ImageDataChunk.DEFAULT_SIZE毎に分割(fdATでも)
			while (pixels.bytesAvailable > 0)
			{
				var datasize:uint = pixels.bytesAvailable;
				if(datasize > ImageDataChunk.DEFAULT_SIZE)
					datasize = ImageDataChunk.DEFAULT_SIZE;
				var data:ByteArray = new ByteArray();
				pixels.readBytes(data, 0, datasize);
				
				if (isIDAT)
				{
					var dataChunk:ImageDataChunk = new ImageDataChunk();
					dataChunk.createDefaultBytes();
					dataChunk.data = data;
					chunks.push(dataChunk);
				}
				else
				{
					var frameDataChunk:FrameDataChunk = new FrameDataChunk();
					frameDataChunk.createBytes(sequenceNumber, data);
					chunks.push(frameDataChunk);
					sequenceNumber++;
				}
			}
			
			return sequenceNumber;
		}
		
		private static function createRawImageDataRGBA32(bmp:BitmapData):ByteArray
		{
			var pixels:ByteArray = bmp.getPixels(new Rectangle(0, 0, bmp.width, bmp.height) );
			var res:ByteArray = new ByteArray();
			res.length = pixels.length + bmp.height; // filter byte分のサイズを追加
			
			// ARGBをRGBAに変換
			for (var y:int = 0; y < bmp.height; y++)
			{
				res[ (bmp.width * SIZE_OF_PIXEL_RGBA + 1) * y] = 0; // filter byte ... フィルター無し
				for (var x:int = 0; x < bmp.width; x++)
				{
					var srcIndex:int = (bmp.width * y + x) * SIZE_OF_PIXEL_RGBA;
					var dstIndex:int = (bmp.width * SIZE_OF_PIXEL_RGBA + 1) * y + x * SIZE_OF_PIXEL_RGBA + 1;
					res[dstIndex] = pixels[srcIndex + 1];
					res[dstIndex + 1] = pixels[srcIndex + 2];
					res[dstIndex + 2] = pixels[srcIndex + 3];
					res[dstIndex + 3] = pixels[srcIndex];
				}
			}
			
			return res;
		}
		
		private static function createRawImageDataRGB24(bmp:BitmapData):ByteArray
		{
			var pixels:ByteArray = bmp.getPixels(new Rectangle(0, 0, bmp.width, bmp.height) );
			var res:ByteArray = new ByteArray();
			res.length = pixels.length * SIZE_OF_PIXEL_RGB / SIZE_OF_PIXEL_RGBA + bmp.height; // filter byte分のサイズを追加
			
			// ARGBをRGBに変換
			for (var y:int = 0; y < bmp.height; y++)
			{
				res[ (bmp.width * SIZE_OF_PIXEL_RGB + 1) * y] = 0; // filter byte ... フィルター無し
				for (var x:int = 0; x < bmp.width; x++)
				{
					var srcIndex:int = (bmp.width * y + x) * SIZE_OF_PIXEL_RGBA;
					var dstIndex:int = (bmp.width * SIZE_OF_PIXEL_RGB + 1) * y + x * SIZE_OF_PIXEL_RGB + 1;
					res[dstIndex] = pixels[srcIndex + 1];
					res[dstIndex + 1] = pixels[srcIndex + 2];
					res[dstIndex + 2] = pixels[srcIndex + 3];
				}
			}
			
			return res;
		}
		
		private static function createRawImageDataIndexes(bmp:BitmapData, transparent:Boolean, bitDepth:uint, palletIndexes:PalletIndexes):ByteArray
		{
			var pixels:ByteArray = bmp.getPixels(new Rectangle(0, 0, bmp.width, bmp.height) );
			var res:ByteArray = new ByteArray();
			var lineLen:int = Math.ceil(bmp.width * bitDepth / 8) + 1; // filter byte分のサイズを追加
			res.length = lineLen * bmp.height;
			
			var bitStartIndex:int = 8 - bitDepth;
			
			// ARGBをINDEXESに変換
			for (var y:int = 0; y < bmp.height; y++)
			{
				var bitIndex:int = bitStartIndex
				var byteIndex:int = 1; // filter byteの次から
				var index:uint;
				var t:uint;
				var b:uint = 0;
				
				res[lineLen * y] = 0; // filter byte ... フィルター無し
				for (var x:int = 0; x < bmp.width; x++)
				{
					// pixelに対応するパレットインデックスを得る
					t = bmp.getPixel32(x, y);
					if (!transparent)
						t |= PalletIndexes.ALPHA_MASK;
					index = palletIndexes.indexOf(t);
					
					b |= index << bitIndex;
					
					bitIndex -= bitDepth;
					
					// 1byte分書き込まれた場合
					if (bitIndex < 0)
					{
						res[lineLen * y + byteIndex] = b;
						bitIndex = bitStartIndex;
						byteIndex++;
						b = 0;
					}
				}
				
				// 1byte分に満たない分を書き込み
				if (bitIndex != bitStartIndex)
				{
					res[lineLen * y + byteIndex] = b;
				}
			}
			
			return res;
		}
		
		// bitDepth==8 のみ対応
		// NTSC Coefficients
		private static function createRawImageDataGray(bmp:BitmapData):ByteArray
		{
			var pixels:ByteArray = bmp.getPixels(new Rectangle(0, 0, bmp.width, bmp.height) );
			var res:ByteArray = new ByteArray();
			res.length = pixels.length / SIZE_OF_PIXEL_RGBA + bmp.height; // filter byte分のサイズを追加
			
			// ARGBをgrayscaleに変換
			for (var y:int = 0; y < bmp.height; y++)
			{
				res[ (bmp.width + 1) * y] = 0; // filter byte ... フィルター無し
				for (var x:int = 0; x < bmp.width; x++)
				{
					var srcIndex:int = (bmp.width * y + x) * SIZE_OF_PIXEL_RGBA;
					var dstIndex:int = (bmp.width + 1) * y + x + 1;
					res[dstIndex] = rgb2gray(pixels[srcIndex + 1] , pixels[srcIndex + 2], pixels[srcIndex + 3] );
				}
			}
			
			return res;
		}
		
		// NTSC Coefficients
		private static function createRawImageDataGrayAlpha(bmp:BitmapData):ByteArray
		{
			var pixels:ByteArray = bmp.getPixels(new Rectangle(0, 0, bmp.width, bmp.height) );
			var res:ByteArray = new ByteArray();
			res.length = pixels.length * SIZE_OF_PIXEL_GRAY_ALPHA / SIZE_OF_PIXEL_RGBA + bmp.height; // filter byte分のサイズを追加
			
			// ARGBをgrayscale+alphaに変換
			for (var y:int = 0; y < bmp.height; y++)
			{
				res[ (bmp.width * SIZE_OF_PIXEL_GRAY_ALPHA + 1) * y] = 0; // filter byte ... フィルター無し
				for (var x:int = 0; x < bmp.width; x++)
				{
					var srcIndex:int = (bmp.width * y + x) * SIZE_OF_PIXEL_RGBA;
					var dstIndex:int = (bmp.width * SIZE_OF_PIXEL_GRAY_ALPHA + 1) * y + x * SIZE_OF_PIXEL_GRAY_ALPHA + 1;
					res[dstIndex] = rgb2gray(pixels[srcIndex + 1] , pixels[srcIndex + 2], pixels[srcIndex + 3] );
					res[dstIndex + 1] = pixels[srcIndex];
				}
			}
			
			return res;
		}
		
		// RGBにNTSC係数をかけてグレースケール化
		private static function rgb2gray(r:uint, g:uint, b:uint):uint
		{
			return GRAY_COEFFICIENT_R * r + GRAY_COEFFICIENT_G * g + GRAY_COEFFICIENT_B * b;
		}
	}
}
package pngutil 
{
	import flash.utils.ByteArray;
	
	/**
	* ...
	* @author Default
	*/
	public class ImageHeaderChunk extends Chunk
	{
		public static const TYPE:uint = 0x49484452; // IHDR
		public static const SIZE:uint = 13;
		
		public static const INDEX_OF_WIDTH:uint = INDEX_OF_DATA + 0;
		public static const INDEX_OF_HEIGHT:uint = INDEX_OF_DATA + 4;
		public static const INDEX_OF_BIT_DEPTH:uint = INDEX_OF_DATA + 8;
		public static const INDEX_OF_COLOR_TYPE:uint = INDEX_OF_DATA + 9;
		public static const INDEX_OF_COMPRESSION_METHOD:uint = INDEX_OF_DATA + 10;
		public static const INDEX_OF_FILTER_METHOD:uint = INDEX_OF_DATA + 11;
		public static const INDEX_OF_INTERLACE_METHOD:uint = INDEX_OF_DATA + 12;
		
		public static const DEFAULT_WIDTH:uint = 16;
		public static const DEFAULT_HEIGHT:uint = 16;
		public static const DEFAULT_BIT_DEPTH:uint = 8;
		public static const DEFAULT_COLOR_TYPE:uint = 6; // ARGB
		public static const DEFAULT_COMPRESSION_METHOD:uint = 0;
		public static const DEFAULT_FILTER_METHOD:uint = 0;
		public static const DEFAULT_INTERLACE_METHOD:uint = 0;
		
		public static const COLOR_TYPE_BIT_PALLET:uint = 1;
		public static const COLOR_TYPE_BIT_COLOR:uint = 2;
		public static const COLOR_TYPE_BIT_ALPHA:uint = 4;
		public static const COLOR_TYPE_RGB24:uint = COLOR_TYPE_BIT_COLOR;
		public static const COLOR_TYPE_RGBA32:uint = COLOR_TYPE_BIT_COLOR | COLOR_TYPE_BIT_ALPHA;
		public static const COLOR_TYPE_INDEXES:uint = COLOR_TYPE_BIT_PALLET | COLOR_TYPE_BIT_COLOR;
		public static const COLOR_TYPE_GRAY:uint = 0;
		public static const COLOR_TYPE_GRAY_ALPHA:uint = COLOR_TYPE_BIT_ALPHA;
		
		public function ImageHeaderChunk() 
		{
			_type_data_size = SIZE;
		}
		
		public function get width():uint
		{
			checkSize();
			_bytes.position = INDEX_OF_WIDTH;
			return _bytes.readUnsignedInt();
		}
		
		// CRCは計算されないので、呼び出し側でChunk.calcCRC()を使用すること
		public function set width(value:uint):void
		{
			checkSize();
			_bytes.position = INDEX_OF_WIDTH;
			_bytes.writeUnsignedInt(value);
		}
		
		public function get height():uint
		{
			checkSize();
			_bytes.position = INDEX_OF_HEIGHT;
			return _bytes.readUnsignedInt();
		}
		
		// CRCは計算されないので、呼び出し側でChunk.calcCRC()を使用すること
		public function set height(value:uint):void
		{
			checkSize();
			_bytes.position = INDEX_OF_HEIGHT;
			_bytes.writeUnsignedInt(value);
		}
		
		public function get bitDepth():uint
		{
			checkSize();
			_bytes.position = INDEX_OF_BIT_DEPTH;
			return _bytes.readUnsignedByte();
		}
		
		public function set bitDepth(value:uint):void
		{
			checkSize();
			_bytes.position = INDEX_OF_BIT_DEPTH;
			_bytes.writeByte(value);
		}
		
		public function get colorType():uint
		{
			checkSize();
			_bytes.position = INDEX_OF_COLOR_TYPE;
			return _bytes.readUnsignedByte();
		}
		
		public function set colorType(value:uint):void
		{
			checkSize();
			_bytes.position = INDEX_OF_COLOR_TYPE;
			_bytes.writeByte(value);
		}
		
		public function get compressionMethod():uint
		{
			checkSize();
			_bytes.position = INDEX_OF_COMPRESSION_METHOD;
			return _bytes.readUnsignedByte();
		}
		
		public function get filterMethod():uint
		{
			checkSize();
			_bytes.position = INDEX_OF_FILTER_METHOD;
			return _bytes.readUnsignedByte();
		}
		
		public function get interlaceMethod():uint
		{
			checkSize();
			_bytes.position = INDEX_OF_INTERLACE_METHOD;
			return _bytes.readUnsignedByte();
		}
		
		public override function toString():String
		{
			var res:String = "[IHDR]\n";
			res += "\twidth = " + width;
			res += "\n\theight = " + height;
			res += "\n\tbitDepth = " + bitDepth;
			res += "\n\tcolorType = " + colorType;
			res += "\n\tcompressionMethod = " + compressionMethod;
			res += "\n\tfilterMethod = " + filterMethod;
			res += "\n\tinterlaceMethod = " + interlaceMethod;
			return res;
		}
		
		public override function copy():Chunk
		{
			var res:ImageHeaderChunk = new ImageHeaderChunk();
			var copybuff:ByteArray = new ByteArray();
			this._bytes.position = 0;
			copybuff.writeBytes(this._bytes, 0, this._bytes.length);
			res._bytes = copybuff;
			return res;
		}
		
		public override function createDefaultBytes():void
		{
			_bytes = new ByteArray();
			_bytes.writeUnsignedInt(SIZE);
			_bytes.writeUnsignedInt(TYPE);
			_bytes.writeUnsignedInt(DEFAULT_WIDTH);
			_bytes.writeUnsignedInt(DEFAULT_HEIGHT);
			_bytes.writeByte(DEFAULT_BIT_DEPTH);
			_bytes.writeByte(DEFAULT_COLOR_TYPE);
			_bytes.writeByte(DEFAULT_COMPRESSION_METHOD);
			_bytes.writeByte(DEFAULT_FILTER_METHOD);
			_bytes.writeByte(DEFAULT_INTERLACE_METHOD);
			_bytes.writeUnsignedInt(0); // dummy CRC
			this.calcCRC();
		}
		
		public function createBytes(pngWidth:uint, pngHeight:uint, pngBitDepth:uint, pngColorType:uint):void
		{
			_bytes = new ByteArray();
			_bytes.writeUnsignedInt(SIZE);
			_bytes.writeUnsignedInt(TYPE);
			_bytes.writeUnsignedInt(pngWidth);
			_bytes.writeUnsignedInt(pngHeight);
			_bytes.writeByte(pngBitDepth);
			_bytes.writeByte(pngColorType);
			_bytes.writeByte(DEFAULT_COMPRESSION_METHOD);
			_bytes.writeByte(DEFAULT_FILTER_METHOD);
			_bytes.writeByte(DEFAULT_INTERLACE_METHOD);
			_bytes.writeUnsignedInt(0); // dummy CRC
			this.calcCRC();
		}
	}
}
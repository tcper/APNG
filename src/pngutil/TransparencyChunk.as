package pngutil 
{
	import flash.utils.ByteArray;
	
	/**
	* IHDRチャンクで指定されたカラータイプとの整合性はチェックしていないので注意
	*/
	public class TransparencyChunk extends Chunk
	{
		public static const TYPE:uint = 0x74524E53; // "tRNS"
		
		public static const INDEX_OF_GRAY:uint = INDEX_OF_DATA;
		public static const SIZE_OF_GRAY_DATA:uint = 2;
		
		public static const INDEX_OF_RGB_R:uint = INDEX_OF_DATA;
		public static const INDEX_OF_RGB_G:uint = INDEX_OF_DATA + 2;
		public static const INDEX_OF_RGB_B:uint = INDEX_OF_DATA + 4;
		public static const SIZE_OF_RGB_DATA:uint = 6;
		
		public static const INDEX_OF_INDEXES:uint = INDEX_OF_DATA;
		
		private var _colorType:uint;
		
		public function TransparencyChunk() 
		{
			_colorType = uint.MAX_VALUE
		}
		
		// rgbsはuintの配列。ARGB32bit。
		public function createBytesFromARGBArray(rgbs:Array):void
		{
			_bytes = null;
			_colorType = ImageHeaderChunk.COLOR_TYPE_INDEXES;
			
			// 要素数を調べる。アルファ値を使用する最後のインデックスをlenに記憶。
			var len:int;
			for (len = rgbs.length; len > 0; len--)
				if (uint(rgbs[len - 1] & 0xff000000) != 0xff000000)
					break;
			
			if (len == 0)
				return;
			
			_bytes = new ByteArray();
			_bytes.writeUnsignedInt(len);
			_bytes.writeUnsignedInt(TYPE);
			
			for (var i:int = 0; i < len; i++)
				_bytes.writeByte(rgbs[i] >>> 24);
			
			_bytes.writeUnsignedInt(0); // dummy CRC
			this.calcCRC();
		}
		
		// IHDRチャンクで指定されたカラータイプがCOLOR_TYPE_RGB24のとき使う
		public function createRGBBytes(rgb:uint):void
		{
			_colorType = ImageHeaderChunk.COLOR_TYPE_RGB24;
			var r:uint = (rgb & 0x00ff0000) >>> 16;
			var g:uint = (rgb & 0x0000ff00) >>> 8;
			var b:uint = rgb & 0x000000ff;
			
			_bytes = new ByteArray();
			_bytes.writeUnsignedInt(SIZE_OF_RGB_DATA);
			_bytes.writeUnsignedInt(TYPE);
			_bytes.writeShort(r);
			_bytes.writeShort(g);
			_bytes.writeShort(b);
			_bytes.writeUnsignedInt(0); // dummy CRC
			this.calcCRC();
		}
		
		// IHDRチャンクで指定されたカラータイプがCOLOR_TYPE_GRAYのとき使う
		public function createGrayBytes(gray:uint):void
		{
			_colorType = ImageHeaderChunk.COLOR_TYPE_GRAY;
			gray &= 0x000000ff;
			
			_bytes = new ByteArray();
			_bytes.writeUnsignedInt(SIZE_OF_GRAY_DATA);
			_bytes.writeUnsignedInt(TYPE);
			_bytes.writeShort(gray);
			_bytes.writeUnsignedInt(0); // dummy CRC
			this.calcCRC();
		}
		
		public override function checkSize():void
		{
			var sizetmp:uint = this.size;
			
			switch(_colorType)
			{
			case ImageHeaderChunk.COLOR_TYPE_GRAY:
				if (sizetmp != SIZE_OF_GRAY_DATA)
				{
					throw new Error("TransparencyChunk : size is not match. size = " + sizetmp + "bytes.length = " + _bytes.length);
				}
				break;
			case ImageHeaderChunk.COLOR_TYPE_RGB24:
				if (sizetmp != SIZE_OF_RGB_DATA)
				{
					throw new Error("TransparencyChunk : size is not match. size = " + sizetmp + "bytes.length = " + _bytes.length);
				}
				break;
			}
			super.checkSize();
		}
		
		public override function toString():String
		{
			var res:String = "[tRNS] ";
			switch(_colorType)
			{
			case ImageHeaderChunk.COLOR_TYPE_GRAY:
				_bytes.position = INDEX_OF_GRAY;
				res += "GRAY(" + _bytes.readShort() + ")";
				break;
			case ImageHeaderChunk.COLOR_TYPE_RGB24:
				_bytes.position = INDEX_OF_RGB_R;
				res += "RGB(" + _bytes.readShort() + ", " + _bytes.readShort() + ", " + _bytes.readShort() + ")";
				break;
			case ImageHeaderChunk.COLOR_TYPE_INDEXES:
				res += "INDEXEX, size = " + this.size;
				break;
			default:
				res += "Color type is not checked yet. size = " + this.size;
			}
			
			return res;
		}
	}
}
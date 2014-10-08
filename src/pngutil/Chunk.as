package pngutil 
{
	import flash.errors.IllegalOperationError;
	import flash.utils.ByteArray;
	
	/**
	* png画像のChunkのバイナリデータ(ByteArray)をラッピング
	* @author Default
	*/
	public class Chunk 
	{
		//public static const CHUNK_TYPE_PLTE:uint = 0x504C5445;
		
		public static const SIZE_OF_SIZE:uint = 4;
		public static const SIZE_OF_TYPE:uint = 4;
		public static const SIZE_OF_CRC:uint = 4;
		public static const SIZE_OF_EMPTY_CHUNK:uint = 12;
		public static const INDEX_OF_SIZE:uint = 0;
		public static const INDEX_OF_TYPE:uint = 4;
		public static const INDEX_OF_DATA:uint = 8;
		
		// png画像のChunkのバイナリデータ
		protected var _bytes:ByteArray;
		
		// Chunkのサイズが固定の場合、サブクラスのコンストラクタで値を指定。
		// Chunkのサイズが画像によって異なる場合、uint.MAX_VALUEを指定。
		protected var _type_data_size:uint;
		
		public function Chunk() 
		{
			_type_data_size = uint.MAX_VALUE;
		}
		
		// 呼び出し元と共有するので注意
		public function set bytes(buff:ByteArray):void
		{
			_bytes = buff;
		}
		
		// _bytesのコピーを返す
		public function get bytes():ByteArray
		{
			var res:ByteArray = new ByteArray();
			res.writeBytes(_bytes, 0, SIZE_OF_EMPTY_CHUNK + size);
			res.position = 0;
			return res;
		}
		
		public function get size():uint
		{
			if (_bytes == null)
				throw new Error("Chunk : empty error.");
			if (_bytes.length < SIZE_OF_EMPTY_CHUNK)
				throw new Error("Chunk : size error. bytes.length = " + _bytes.length);
			
			_bytes.position = INDEX_OF_SIZE;
			return _bytes.readUnsignedInt();
		}
		
		public function get type():uint
		{
			if (_bytes == null)
				throw new Error("Chunk : empty error.");
			if (_bytes.length < SIZE_OF_EMPTY_CHUNK)
				throw new Error("Chunk : size error. bytes.length = " + _bytes.length);
			
			_bytes.position = INDEX_OF_TYPE;
			return _bytes.readUnsignedInt();
		}
		
		// type,size,data,crcの中で、data部分のコピーを返す
		public function get data():ByteArray
		{
			checkSize();
			
			var res:ByteArray = new ByteArray();
			res.writeBytes(_bytes, INDEX_OF_DATA, size);
			res.position = 0;
			return res;
		}
		
		public function set data(buff:ByteArray):void
		{
			var sizetmp:uint = buff.length;
			var typetmp:uint = this.type;
			
			_bytes = new ByteArray();
			_bytes.writeUnsignedInt(sizetmp);
			_bytes.writeUnsignedInt(typetmp);
			_bytes.writeBytes(buff, 0, buff.length);
			_bytes.writeUnsignedInt(0); // dummy CRC
			calcCRC();
		}
		
		public function get CRC():uint
		{
			checkSize();
			_bytes.position = INDEX_OF_DATA + size;
			return _bytes.readUnsignedInt();
		}
		
		public function get isEmpty():Boolean
		{
			return _bytes == null;
		}
		
		public function checkCRC():Boolean
		{
			checkSize();
			return CRC == CRC32.check(_bytes, INDEX_OF_TYPE, SIZE_OF_TYPE + this.size);
		}
		
		public function calcCRC():void
		{
			checkSize();
			
			var sizetmp:uint = this.size;
			_bytes.position = INDEX_OF_DATA + sizetmp;
			_bytes.writeUnsignedInt(CRC32.check(_bytes, INDEX_OF_TYPE, SIZE_OF_TYPE + sizetmp));
		}
		
		public function checkSize():void
		{
			if (_bytes == null)
				throw new Error("Chunk : empty error.");
			var sizetmp:uint = this.size;
			if(_bytes.length < SIZE_OF_EMPTY_CHUNK + sizetmp)
				throw new Error("Chunk : size error. size = " + sizetmp + "bytes.length = " + _bytes.length);
			if ( (_type_data_size != uint.MAX_VALUE) && (sizetmp != _type_data_size) )
				throw new Error("Chunk : size is not match. size = " + sizetmp + "bytes.length = " + _bytes.length);
		}
		
		public function toString():String
		{
			var res:String = "[Unknown] ";
			res += "type = " + type;
			res += ", size = " + size;
			return res;
		}
		
		public function copy():Chunk
		{
			throw new IllegalOperationError("Chunk : copy method is not implemented.");
		}
		
		public function createDefaultBytes():void
		{
			throw new IllegalOperationError("Chunk : copy method is not implemented.");
		}
	}
}
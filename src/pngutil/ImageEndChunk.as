package pngutil 
{
	import flash.utils.ByteArray;
	
	/**
	* ...
	* @author Default
	*/
	public class ImageEndChunk extends Chunk
	{
		public static const TYPE:uint = 0x49454E44;
		public static const SIZE:uint = 0;
		public static const CRC:uint = 0xAE426082;
		
		public function ImageEndChunk() 
		{
			_type_data_size = SIZE;
		}
		
		public override function set bytes(buff:ByteArray):void
		{
			_bytes = buff;
			var sizetmp:uint = this.size;
			if (sizetmp != SIZE)
				throw new Error("ImageEndChunk : size error. size = " + sizetmp + "bytes.length = " + _bytes.length);
		}
		
		public override function toString():String
		{
			return "[IEND]";
		}
		
		public override function createDefaultBytes():void
		{
			_bytes = new ByteArray();
			_bytes.writeUnsignedInt(SIZE);
			_bytes.writeUnsignedInt(TYPE);
			_bytes.writeUnsignedInt(ImageEndChunk.CRC);
		}
	}
}
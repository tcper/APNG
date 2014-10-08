package pngutil 
{
	import flash.utils.ByteArray;
	
	/**
	* ...
	* @author Default
	*/
	public class ImageDataChunk extends Chunk
	{
		public static const TYPE:uint = 0x49444154;
		public static const DEFAULT_SIZE:uint = 8192;
		
		public function ImageDataChunk() 
		{
			
		}
		
		public override function toString():String
		{
			return "[IDAT] size = " + size;
		}
		
		public override function createDefaultBytes():void
		{
			_bytes = new ByteArray();
			_bytes.writeUnsignedInt(0); // size
			_bytes.writeUnsignedInt(TYPE);
			_bytes.writeUnsignedInt(0); // dummy CRC
			this.calcCRC();
		}
	}
}
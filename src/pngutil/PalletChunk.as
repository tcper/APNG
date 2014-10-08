package pngutil 
{
	import flash.utils.ByteArray;
	
	/**
	* ...
	* @author Default
	*/
	public class PalletChunk extends Chunk
	{
		public static const TYPE:uint = 0x504C5445; // PLTE
		public static const SIZE_OF_PIXEL_RGB:uint = 3;
		
		public function PalletChunk() 
		{
			
		}
		
		// rgbsはuintの配列。RGB24bit。
		public function createBytesFromRGBArray(rgbs:Array):void
		{
			_bytes = new ByteArray();
			_bytes.writeUnsignedInt(rgbs.length * SIZE_OF_PIXEL_RGB);
			_bytes.writeUnsignedInt(TYPE);
			
			for each(var rgb:uint in rgbs)
			{
				_bytes.writeByte( (rgb & 0xff0000) >>> 16);
				_bytes.writeByte( (rgb & 0x00ff00) >>> 8);
				_bytes.writeByte(rgb & 0x0000ff);
			}
			
			_bytes.writeUnsignedInt(0); // dummy CRC
			this.calcCRC();
		}
		
		public override function toString():String
		{
			return "[PLTE] size = " + size;
		}
	}
}
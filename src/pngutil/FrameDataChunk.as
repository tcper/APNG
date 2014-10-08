package pngutil 
{
	import flash.utils.ByteArray;
	
	/**
	* ...
	* @author Default
	*/
	public class FrameDataChunk extends Chunk
	{
		public static const TYPE:uint = 0x66644154; // "fdAT"
		
		public static const SIZE_OF_SEQUENCE_NUMBER:uint = 4;
		public static const INDEX_OF_SEQUENCE_NUMBER:uint = INDEX_OF_DATA + 0;
		public static const INDEX_OF_FRAME_DATA:uint = INDEX_OF_DATA + 4;
		
		public function FrameDataChunk() 
		{
		}
		
		public function get sequenceNumber():uint
		{
			checkSize();
			_bytes.position = INDEX_OF_SEQUENCE_NUMBER;
			return _bytes.readUnsignedInt();
		}
		
		// シーケンス番号を取り除いたデータでImageDataChunkを作成する
		public function toImageData():ImageDataChunk
		{
			var res:ImageDataChunk = new ImageDataChunk();
			var buff:ByteArray = new ByteArray();
			
			var datasize:uint = this.size - SIZE_OF_SEQUENCE_NUMBER;
			
			buff.writeUnsignedInt(datasize);
			buff.writeUnsignedInt(ImageDataChunk.TYPE);
			buff.writeBytes(_bytes, INDEX_OF_FRAME_DATA, datasize);
			buff.writeUnsignedInt(0); // dummy CRC
			res.bytes = buff;
			res.calcCRC();
			
			return res;
		}
		
		public override function toString():String
		{
			var res:String = "[fdAT] sequenceNumber = " + sequenceNumber;
			return res;
		}
		
		public function createBytes(sequenceNumber:uint, buff:ByteArray):void
		{
			_bytes = new ByteArray();
			_bytes.writeUnsignedInt(SIZE_OF_SEQUENCE_NUMBER + buff.length);
			_bytes.writeUnsignedInt(TYPE);
			_bytes.writeUnsignedInt(sequenceNumber);
			_bytes.writeBytes(buff, 0, buff.length);
			_bytes.writeUnsignedInt(0); // dummy CRC
			this.calcCRC();
		}
	}
	
}
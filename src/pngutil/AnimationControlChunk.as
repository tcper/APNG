package pngutil 
{
	import flash.utils.ByteArray;
	
	/**
	* ...
	* @author Default
	*/
	public class AnimationControlChunk extends Chunk
	{
		public static const TYPE:uint = 0x6163544C; // acTL
		public static const SIZE:uint = 8;
		
		public static const INDEX_OF_NUM_FRAMES:uint = INDEX_OF_DATA + 0;
		public static const INDEX_OF_NUM_PLAYS:uint = INDEX_OF_DATA + 4;
		
		public function AnimationControlChunk() 
		{
			_type_data_size = SIZE;
		}
		
		public function get numFrames():uint
		{
			checkSize();
			_bytes.position = INDEX_OF_NUM_FRAMES;
			return _bytes.readUnsignedInt();
		}
		
		public function get numPlays():uint
		{
			checkSize();
			_bytes.position = INDEX_OF_NUM_PLAYS;
			return _bytes.readUnsignedInt();
		}
		
		public override function toString():String
		{
			var res:String = "[acTL]\n";
			res += "\tnum_frames = " + numFrames;
			res += "\n\tnum_plays = " + numPlays;
			return res;
		}
		
		public function createBytes(frames:PngFrames):void
		{
			_bytes = new ByteArray();
			_bytes.writeUnsignedInt(SIZE);
			_bytes.writeUnsignedInt(TYPE);
			_bytes.writeUnsignedInt(frames.numFrames);
			_bytes.writeUnsignedInt(frames.numPlays);
			_bytes.writeUnsignedInt(0); // dummy CRC
			this.calcCRC();
		}
	}
}
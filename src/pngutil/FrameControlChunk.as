package pngutil 
{
	import flash.utils.ByteArray;
	
	/**
	* ...
	* @author Default
	*/
	public class FrameControlChunk  extends Chunk
	{
		public static const TYPE:uint = 0x6663544C; // fcTL
		public static const SIZE:uint = 26;
		
		public static const INDEX_OF_SEQUENCE_NUMBER:uint = INDEX_OF_DATA + 0;
		public static const INDEX_OF_WIDTH:uint = INDEX_OF_DATA + 4;
		public static const INDEX_OF_HEIGHT:uint = INDEX_OF_DATA + 8;
		public static const INDEX_OF_X_OFFSET:uint = INDEX_OF_DATA + 12;
		public static const INDEX_OF_Y_OFFSET:uint = INDEX_OF_DATA + 16;
		public static const INDEX_OF_DELAY_NUM:uint = INDEX_OF_DATA + 20;
		public static const INDEX_OF_DELAY_DEN:uint = INDEX_OF_DATA + 22;
		public static const INDEX_OF_DISPOSE_OP:uint = INDEX_OF_DATA + 24;
		public static const INDEX_OF_BLEND_OP:uint = INDEX_OF_DATA + 25;
		
		public static const APNG_DISPOSE_OP_NONE:uint = 0;
		public static const APNG_DISPOSE_OP_BACKGROUND:uint = 1;
		public static const APNG_DISPOSE_OP_PREVIOUS:uint = 2;
		
		public static const APNG_BLEND_OP_SOURCE:uint = 0;
		public static const APNG_BLEND_OP_OVER:uint = 1;
		
		public function FrameControlChunk() 
		{
			_type_data_size = SIZE;
		}
		
		public function get sequenceNumber():uint
		{
			checkSize();
			_bytes.position = INDEX_OF_SEQUENCE_NUMBER;
			return _bytes.readUnsignedInt();
		}
		
		public function get width():uint
		{
			checkSize();
			_bytes.position = INDEX_OF_WIDTH;
			return _bytes.readUnsignedInt();
		}
		
		public function get height():uint
		{
			checkSize();
			_bytes.position = INDEX_OF_HEIGHT;
			return _bytes.readUnsignedInt();
		}
		
		public function get XOffset():uint
		{
			checkSize();
			_bytes.position = INDEX_OF_X_OFFSET;
			return _bytes.readUnsignedInt();
		}
		
		public function get YOffset():uint
		{
			checkSize();
			_bytes.position = INDEX_OF_Y_OFFSET;
			return _bytes.readUnsignedInt();
		}
		
		public function get delayNum():uint
		{
			checkSize();
			_bytes.position = INDEX_OF_DELAY_NUM;
			return _bytes.readUnsignedShort();
		}
		
		public function get delayDen():uint
		{
			checkSize();
			_bytes.position = INDEX_OF_DELAY_DEN;
			return _bytes.readUnsignedShort();
		}
		
		public function get disposeOp():uint
		{
			checkSize();
			_bytes.position = INDEX_OF_DISPOSE_OP;
			return _bytes.readUnsignedByte();
		}
		
		public function get blendOp():uint
		{
			checkSize();
			_bytes.position = INDEX_OF_BLEND_OP;
			return _bytes.readUnsignedByte();
		}
		
		public override function toString():String
		{
			var res:String = "[fcTL]\n";
			res += "\tsequenceNumber = " + sequenceNumber;
			res += "\n\twidth = " + width;
			res += "\n\theight = " + height;
			res += "\n\tXOffset = " + XOffset;
			res += "\n\tYOffset = " + YOffset;
			res += "\n\tdelayNum = " + delayNum;
			res += "\n\tdelayDen = " + delayDen;
			res += "\n\tdisposeOp = " + disposeOp;
			res += "\n\tblendOp = " + blendOp;
			return res;
		}
		
		public function createBytes(sequenceNumber:uint, frame:PngFrame):void
		{
			_bytes = new ByteArray();
			_bytes.writeUnsignedInt(SIZE);
			_bytes.writeUnsignedInt(TYPE);
			_bytes.writeUnsignedInt(sequenceNumber);
			_bytes.writeUnsignedInt(frame.width);
			_bytes.writeUnsignedInt(frame.height);
			_bytes.writeUnsignedInt(frame.XOffset);
			_bytes.writeUnsignedInt(frame.YOffset);
			_bytes.writeShort(frame.delayNum);
			_bytes.writeShort(frame.delayDen);
			_bytes.writeByte(frame.disposeOp);
			_bytes.writeByte(frame.blendOp);
			_bytes.writeUnsignedInt(0); // dummy CRC
			this.calcCRC();
		}
	}
}
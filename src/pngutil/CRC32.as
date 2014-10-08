package pngutil 
{
	import flash.utils.ByteArray;
	
	/**
	* ...
	* @author Default
	*/
	public class CRC32 
	{
		private static var crcTable:Array;
		
		public static function check(buff:ByteArray, start:uint, length:uint):uint
		{
			if (crcTable == null)
				makeCRCTable();
			
			var c:uint = 0xffffffff;
			for (var i:uint = 0; i < length; i++)
			{
				c = crcTable[ (c ^ buff[start + i] ) & uint(0xff) ] ^ uint(c >>> 8);
			}
			
			return c ^ uint(0xffffffff);
		}
		
		private static function makeCRCTable():void
		{
			crcTable = new Array(256);
			
			var c:uint;
			for (var n:uint = 0; n < 256; n++)
			{
				c = n;
				for (var k:uint = 0; k < 8; k++)
				{
					if (c & 1)
					{
						c = uint(uint(0xedb88320) ^ uint(c >>> 1) );
					}
					else
					{
						c = uint(c >>> 1);
					}
				}
				crcTable[n] = c;
			}
		}
	}
}
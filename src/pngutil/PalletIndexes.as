package pngutil 
{
	import flash.display.BitmapData;
	import flash.utils.ByteArray;
	
	/**
	* ...
	* @author Default
	*/
	public class PalletIndexes 
	{
		public static const MAX_ENTRY:uint = 256;
		public static const ALPHA_MASK:uint = 0xff000000;
		
		private var _indexes:Array;
		
		public function PalletIndexes() 
		{
			_indexes = new Array();
		}
		
		// インデックス数がMAX_INDEXを超えた場合、uint.MAX_VALUEを返す。
		public function get suitableBitDepth():uint
		{
			if (_indexes.length <= 2)
				return 1;
			if (_indexes.length <= 4)
				return 2;
			if (_indexes.length <= 16)
				return 4;
			if (_indexes.length <= 256)
				return 8;
			
			return uint.MAX_VALUE;
		}
		
		public function get indexes():Array
		{
			return _indexes;
		}
		
		public function get length():uint
		{
			return _indexes.length;
		}
		
		public function add(bmp:BitmapData, transparent:Boolean = true):uint
		{
			var pixel:uint;
			
			loop:
			for (var y:int = 0; y < bmp.height; y++)
			{
				for (var x:int = 0; x < bmp.width; x++)
				{
					pixel = bmp.getPixel32(x, y);
					
					if (!transparent)
					{
						pixel |= ALPHA_MASK;
					}
					
					var index:int = search(pixel);
					if (index == int.MIN_VALUE) // 登録されているピクセルの最小値より小さい
					{
						_indexes.unshift(pixel);
					}
					else if (index == int.MAX_VALUE) // 最大値より大きい
					{
						_indexes.push(pixel);
					}
					else if (_indexes[index] != pixel) // _indexes[index]～_indexes[index+1]の間にある
					{
						_indexes.splice(index + 1, 0, pixel); // _indexes[index]の後ろに挿入
					}
					
					if (MAX_ENTRY < _indexes.length)
					{
						break loop;
					}
				}
			}
			
			return suitableBitDepth;
		}
		
		public function indexOf(rgb:uint):uint
		{
			var res:uint = search(rgb);
			if (_indexes[res] == rgb)
				return res;
			
			throw new Error("PalletIndexes : value does not contain.");
		}
		
		// 登録されているピクセルの最小値より小さい場合、int.MIN_VALUEを返す。
		// 最大値より大きい場合、int.MAX_VALUEを返す。
		// _indexes[index]～_indexes[index+1]の間にある場合、indexを返す。
		private function search(key:uint):int
		{
			var low:int, high:int, mid:int;
			
			if (_indexes.length == 0)
				return int.MAX_VALUE;
			
			if (_indexes[_indexes.length - 1] == key)
			{
				return _indexes.length - 1;
			}
			
			if (key < _indexes[0] )
				return int.MIN_VALUE;
			
			low = 0;
			high = _indexes.length - 2;
			
			while (low <= high)
			{
				mid = (low + high) / 2;
				if ( (_indexes[mid] <= key) && (key < _indexes[mid + 1] ) )
				{
					return mid;
				}
				else if (key < _indexes[mid] )
				{
					high = mid - 1;
				}
				else
				{
					low = mid + 1;
				}
			}
			
			return int.MAX_VALUE;
		}
	}
}
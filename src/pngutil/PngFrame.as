package pngutil 
{
	import flash.display.BitmapData;
	import pngutil.FrameControlChunk;
	
	/**
	* ...
	* @author Default
	*/
	public class PngFrame 
	{
		public static const DEFAULT_DELAY_NUM:uint = 6;
		public static const DEFAULT_DELAY_DEN:uint = 30;
		
		private var _bmp:BitmapData;
		private var _XOffset:uint;
		private var _YOffset:uint;
		private var _delayNum:uint;
		private var _delayDen:uint;
		private var _disposeOp:uint;
		private var _blendOp:uint;
		private var _delay:Number;
		
		public function PngFrame(
			bmp:BitmapData,
			XOffset:uint = 0,
			YOffset:uint = 0,
			delayNum:uint = DEFAULT_DELAY_NUM,
			delayDen:uint = DEFAULT_DELAY_DEN,
			disposeOp:uint = 0, //FrameControlChunk.APNG_DISPOSE_OP_NONE
			blendOp:uint = 0) //FrameControlChunk.APNG_BLEND_OP_SOURCE
		{
			if (bmp == null)
				throw new Error("PngFrame : BitmapData is null.");
			
			if (int(XOffset) < 0)
				throw new Error("PngFrame : x_offset is negative.");
			if (int(YOffset) < 0)
				throw new Error("PngFrame : y_offset is negative.");
			if(delayNum > 0xffff)
				throw new Error("PngFrame : overflow. delay_num has to be unsigned short.");
			if(delayDen > 0xffff)
				throw new Error("PngFrame : overflow. delay_den has to be unsigned short.");
			if(disposeOp > 0xff)
				throw new Error("PngFrame : overflow. dispose_op has to be byte.");
			if(blendOp > 0xff)
				throw new Error("PngFrame : overflow. blend_op has to be byte.");
			
			_bmp = bmp;
			_XOffset = XOffset;
			_YOffset = YOffset;
			_delayNum = delayNum;
			_delayDen = delayDen;
			_disposeOp = disposeOp;
			_blendOp = blendOp;
			
			var delayDenTmp:Number = (delayDen > 0) ? Number(delayDen) : 100;
			_delay = _delayNum * 1000 / delayDenTmp;
		}
		
		public function get bmp():BitmapData
		{
			return _bmp;
		}
		
		public function get width():uint
		{
			return _bmp.width;
		}
		
		public function get height():uint
		{
			return _bmp.height;
		}
		
		public function get XOffset():uint
		{
			return _XOffset;
		}
		
		public function get YOffset():uint
		{
			return _YOffset;
		}
		
		public function get delayNum():uint
		{
			return _delayNum;
		}
		
		public function get delayDen():uint
		{
			return _delayDen;
		}
		
		// 1ループにかかる時間(ミリ秒単位)
		public function get delay():uint
		{
			return _delay;
		}
		
		public function get disposeOp():uint
		{
			return _disposeOp;
		}
		
		public function get blendOp():uint
		{
			return _blendOp;
		}
	}
}
package pngutil 
{
	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.getTimer;
	
	/**
	* デフォルト画像がアニメーションに含まれない場合、最初にdefaultBmpプロパティを設定すること。
	* @author Default
	*/
	public class PngFrames 
	{
		private var _defaultBmp:BitmapData;
		private var _frames:Array;
		private var _numPlays:uint;
		private var _transparent:Boolean;
		private var _defaultIsFirstFrame:Boolean;
		
		private var _previousBmp:BitmapData;
		private var _currentBmp:BitmapData;
		private var _frameIndex:int;
		private var _frame0time:int;
		private var _delayTime:Number;
		private var _countPlays:int;
		
		// ガベージコレクタの動作を抑えるため、描画に使うgeometryはメンバーで持っておく。
		private var _tmp_rect:Rectangle;
		private var _tmp_point:Point;
		
		public function PngFrames(defaultIsFirstFrame:Boolean = true, numPlays:uint = 0, transparent:Boolean = true) 
		{
			_frames = new Array();
			_defaultIsFirstFrame = defaultIsFirstFrame;
			_numPlays = numPlays;
			_transparent = transparent;
		}
		
		public function get defaultIsFirstFrame():Boolean
		{
			return _defaultIsFirstFrame;
		}
		
		public function get numFrames():uint
		{
			return _frames.length;
		}
		
		public function get numPlays():uint
		{
			return _numPlays;
		}
		
		public function set numPlays(value:uint):void
		{
			_numPlays = value;
		}
		
		public function get defaultBmp():BitmapData
		{
			return _defaultBmp;
		}
		
		public function set defaultBmp(value:BitmapData):void
		{
			if (_defaultIsFirstFrame)
				throw new Error("PngFrames : default image has to set at 'add' method.");
			
			_defaultBmp = value;
		}
		
		public function get currentFrameBmp():BitmapData
		{
			return _currentBmp;
		}
		
		public function get width():int
		{
			return _defaultBmp.width;
		}
		
		public function get height():int
		{
			return _defaultBmp.height;
		}
		
		public function get currentFrameIndex():int
		{
			return _frameIndex;
		}
		
		public function get countPlays():int
		{
			return _countPlays;
		}
		
		public function get transparent():Boolean
		{
			return _transparent;
		}
		
		public function add(frame:PngFrame):void
		{
			// デフォルト画像を追加する場合、オフセットをチェックする。
			if (_defaultIsFirstFrame && (_frames.length == 0) )
				if ( (frame.XOffset != 0) || (frame.YOffset != 0) )
					throw new Error("PngFrames : default frame offset has to be 0.");
			
			_frames.push(frame);
			
			if(_defaultIsFirstFrame)
				_defaultBmp = (_frames[0] as PngFrame).bmp;
			
			// デフォルト画像が無いと枠のチェックができない
			if (_defaultBmp == null)
				throw new Error("PngFrames : default image is not exist.");
			
			// デフォルト画像の枠に収まっているかをチェック
			if(_defaultBmp.width < frame.XOffset + frame.width)
				throw new Error("PngFrames : out of bounds. (width)");
			if (_defaultBmp.height < frame.YOffset + frame.height)
				throw new Error("PngFrames : out of bounds. (height)");
		}
		
		public function frameAt(index:int):PngFrame
		{
			return _frames[index];
		}
		
		// 再生アニメーションのカレントフレームを0にリセットする。
		public function resetCurrentFrame():void
		{
			var f:PngFrame = _frames[0];
			_currentBmp = new BitmapData(_defaultBmp.width, _defaultBmp.height, _transparent, 0x00000000);
			
			// _previousBmpを作るのはAPNG_DISPOSE_OP_PREVIOUSが有った時のみ
			if (f.disposeOp == FrameControlChunk.APNG_DISPOSE_OP_PREVIOUS)
			{
				_previousBmp = new BitmapData(_defaultBmp.width, _defaultBmp.height, _transparent, 0x00000000);
			}
			
			_tmp_rect = new Rectangle(0, 0, f.width, f.height);
			_tmp_point = new Point(f.XOffset, f.YOffset);
			
			_frameIndex = 0;
			_frame0time = getTimer();
			_delayTime = 0;
			_countPlays = 0;
			
			_currentBmp.copyPixels(f.bmp, _tmp_rect, _tmp_point);
		}
		
		// 再生アニメーションの更新を行う。
		// 更新されるタイミングはEvent.ENTER_FRAMEやタイマーから独立しており、
		// この関数が呼ばれた時刻を元に何フレーム目を表示すべきか判断し、更新する。
		// 画像の内容が更新された場合trueを返す。
		// currentFrameBmpプロパティで現在のフレームを取得。
		// 初めて呼ばれたときは0フレーム目の画像で初期化。
		public function updateCurrentFrame():Boolean
		{
			var f:PngFrame;
			var res:Boolean = false;
			
			// デフォルト画像しかない場合
			if (_frames.length == 0)
				return false;
			
			// 初期化されていない場合
			if (_currentBmp == null)
			{
				resetCurrentFrame();
				return true;
			}
			
			while(isDelayOver() )
			{
				res = true;
				var previousFrameIndex:int = _frameIndex;
				
				// _frameIndexをカレントフレームに進める
				_frameIndex++;
				if (_frames.length <= _frameIndex)
				{
					_frameIndex = 0;
					_delayTime = 0;
					
					_countPlays++;
					if ( (_numPlays == 0) || (_countPlays < _numPlays) )
					{
						_frame0time = getTimer();
					}
					else // ループ終了
					{
						_frame0time = int.MAX_VALUE;
						break;
					}
				}
				
				// 前フレームのdispose_op
				if(0 < _frameIndex)
				{
					f = _frames[previousFrameIndex];
					_tmp_rect.x = f.XOffset;
					_tmp_rect.y = f.YOffset;
					_tmp_rect.width = f.width;
					_tmp_rect.height = f.height;
					if (f.disposeOp == FrameControlChunk.APNG_DISPOSE_OP_BACKGROUND)
					{
						_currentBmp.fillRect(_tmp_rect, 0x00000000);
					}
					else if (f.disposeOp == FrameControlChunk.APNG_DISPOSE_OP_PREVIOUS)
					{
						_tmp_point.x = f.XOffset;
						_tmp_point.y = f.YOffset;
						_currentBmp.copyPixels(_previousBmp, _tmp_rect, _tmp_point);
					}
				}
				else
				{
					_tmp_rect.x = 0;
					_tmp_rect.y = 0;
					_tmp_rect.width = _defaultBmp.width;
					_tmp_rect.height = _defaultBmp.height;
					_currentBmp.fillRect(_tmp_rect, 0x00000000);
				}
				
				f = _frames[_frameIndex];
				
				// dispose_opがAPNG_DISPOSE_OP_PREVIOUSの場合、描画前の画像を取っておく
				if (f.disposeOp == FrameControlChunk.APNG_DISPOSE_OP_PREVIOUS)
				{
					// _previousBmpを作るのはAPNG_DISPOSE_OP_PREVIOUSが有った時のみ
					if (_previousBmp == null)
					{
						_previousBmp = new BitmapData(_defaultBmp.width, _defaultBmp.height, _transparent, 0x00000000);
					}
					_tmp_rect.x = f.XOffset;
					_tmp_rect.y = f.YOffset;
					_tmp_rect.width = f.width;
					_tmp_rect.height = f.height;
					if (_frameIndex == 0)
					{
						_previousBmp.fillRect(_tmp_rect, 0x00000000);
					}
					else
					{
						_tmp_point.x = f.XOffset;
						_tmp_point.y = f.YOffset;
						_previousBmp.copyPixels(_currentBmp, _tmp_rect, _tmp_point);
					}
				}
				
				// 現在のフレームを描画
				_tmp_rect.x = 0;
				_tmp_rect.y = 0;
				_tmp_rect.width = f.width;
				_tmp_rect.height = f.height;
				_tmp_point.x = f.XOffset;
				_tmp_point.y = f.YOffset;
				var mergeAlpha:Boolean = (f.blendOp == FrameControlChunk.APNG_BLEND_OP_OVER);
				_currentBmp.copyPixels(f.bmp, _tmp_rect, _tmp_point, null, null, mergeAlpha);
			}
			
			return res;
		}
		
		// 現在のフレームがディレイ中ならばfalse、ディレイ時間を過ぎているならばtrue
		private function isDelayOver():Boolean
		{
			var passed:Number = Number(getTimer() - _frame0time);
			
			var delay:Number = (_frames[_frameIndex] as PngFrame).delay;
			if (passed < _delayTime + delay)
				return false;
			
			_delayTime += delay;
			return true;
    }

    public function resume(currentFrame:int):void {
      _frameIndex = currentFrame;
    }
	}
}
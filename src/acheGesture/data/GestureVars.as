package acheGesture.data
{
	public class GestureVars
	{
		/** @private **/
		protected var _vars:Object;
		
		public function GestureVars(vars:Object=null)
		{
			_vars = {};
			if (vars != null) {
				for (var p:String in vars) {
					_vars[p] = vars[p];
				}
			}
		}
		
		/** @private **/
		protected function _set(property:String, value:*):GestureVars {
			if (value == null) {
				delete _vars[property]; //in case it was previously set
			} else {
				_vars[property] = value;
			}
			return this;
		}
		
		public function prop(property:String, value:*):GestureVars {
			return _set(property, value);
		}
		
		public function dispatchEvent(value:Boolean):GestureVars {
			return _set("dispatchEvent", value);
		}
		
		public function onTouch(value:Function):GestureVars { return _set("onTouch", value); }
		
		////////////////////////////////////////////////////////////////////
		public function onTap(value:Object):GestureVars  { return _set("tap", value); }		
		public function onDoubleTap(value:Object):GestureVars { return _set("doubleTap", value); }
		public function onPan(value:Object):GestureVars { return _set("pan", value); }
		public function onSwipe(value:Object):GestureVars { return _set("swipe", value); }
		public function onHold(value:Object):GestureVars { return _set("hold", value); }
		public function onPinch(value:Object):GestureVars { return _set("pinch", value); }
		
		public function onTrigger(value:Function):GestureVars {
			return _set("onTrigger", value);
		}
		
		/** The generic Object populated by all of the method calls in the LoaderMaxVars instance. This is the raw data that gets passed to the loader. **/
		public function get vars():Object {
			return _vars;
		}
	}
}
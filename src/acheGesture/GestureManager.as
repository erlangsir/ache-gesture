package acheGesture
{
	import acheGesture.core.PropGesture;
	import acheGesture.gestures.DoubleTapGestureRecognizer;
	import acheGesture.gestures.HoldGestureRecognizer;
	import acheGesture.gestures.PanGestureRecognizer;
	import acheGesture.gestures.PinchGestureRecognizer;
	import acheGesture.gestures.RotationGestureRecognizer;
	import acheGesture.gestures.SwipeGestureRecognizer;
	import acheGesture.gestures.TapGestureRecognizer;
	
	import flash.utils.Dictionary;
	
	import starling.display.DisplayObject;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	
	public class GestureManager
	{
		/**
		 * 手势配置的参数 
		 */
		public var vars:Object;
		
		/**
		 * 作用的显示对象 
		 */		
		public var target:DisplayObject;
		
		/**
		 * 手势的其实位置
		 */		
		public var startGlobalX:Number;
		public var startGlobalY:Number;
		
		/**
		 * 整个手势计算链中的第一个 
		 */		
		public var _firstG:PropGesture;
		
		/**
		 * 是否允许多个手势同时作用 
		 */		
		private var _allowSimultaneous:Boolean;
		
		/**
		 * 用于绑定当前创建的PropGesture与其对应的GesturePlugin（具体的某个手势） 
		 */		
		private var _ref:Object = {};
		
		private var _ts:Vector.<Touch>;	
		private var _t:Touch;		
		
		/**
		 * 对所有创建的手势的引用查询，使用target作为键值
		 */		
		private static var _gestures:Dictionary = new Dictionary(false);
		
		public static var _gesturePlugins:Object = {
			"tap": TapGestureRecognizer,
			"doubleTap" : DoubleTapGestureRecognizer,
			"hold": HoldGestureRecognizer,
			"swipe": SwipeGestureRecognizer,
			"pan": PanGestureRecognizer,
			"pinch" : PinchGestureRecognizer,
			"rotate": RotationGestureRecognizer
		};
		
		public function GestureManager(target:DisplayObject, vars:Object = null, allowSimultaneous:Boolean = false)
		{
			this.vars = vars || {};
			this.target = target;
			this._allowSimultaneous = allowSimultaneous;
			_initGesture();
		}
		
		protected function _initGesture():void
		{
			var p:String,  plugin:Object;
			for (p in vars) 
			{
				if ((p in _gesturePlugins) && (plugin = new _gesturePlugins[p]())._onInitGesture(vars[p], vars[p]["config"], this))
				{
					_firstG = new PropGesture(plugin, "executeGesturRecognizedCallback", "checkGesture", "updateValue", _firstG, plugin._continuous, plugin._priority, plugin._numTouchesRequired);
					_ref[plugin._gestureType]  = _firstG;
				}
			}
			linkGestureCondition();
			target.addEventListener(TouchEvent.TOUCH, onTouched);
		}
		
		private function linkGestureCondition():void
		{
			var pg:PropGesture = _firstG;
			while (pg) {
				if(pg.t._callBack.hasOwnProperty("requireGestureRecognizerToFail")  && pg.t._callBack.requireGestureRecognizerToFail != null)
				{	
					var tg:PropGesture = _ref[pg.t._callBack.requireGestureRecognizerToFail.type];
					pg._f = tg;
					tg._o = pg;		
					tg.t._requireGestureRecognizerToFail = true;
					pg.t._requireGestureRecognizerToFail = true;
				}
				pg = pg._next;
			}
		}
		
		public function gestureRecognizerStateChange(name:String, value:Boolean):void
		{
			var pg:PropGesture = _ref[name];
			var newFirstG:PropGesture;
			if(pg._o != null){
				if(value)
				{
//					trace("1"+ ">>" + pg.t._gestureName);
					pg.t[pg.p0]();
					if(pg._o.h) pg._o.h = false;
					pg.r = true;
					if(pg.c){
						//离散的收拾在识别之后直接执行即可,对于连续的手势，r属性会保持到ended状态
						//连续的手势executeGesturRecognizedCallback是Began，
//						pg.t[pg.p2](ts); //如果是保持识别状态的手势，则调用更新，如果是离散手势，r只是瞬时状态，对于连续的，r会在ended的时候被重置为false
						newFirstG = _allowSimultaneous ? null : pg;
					}
					newFirstG = pg;
				}else{
					//识别失败的情况下，只有当识别周期到达结束点的时候，才会确认这个手势是否已经识别失败，否则还认为有可能被识别
					//例如点击操作，需要经历TouchBegan, TouchMoved到TouchEnded才完成一次点击操作的判断
					pg.f =  true;
					if(pg._o.h){
						pg._o.t[pg._o.p0]();
//						trace("2"+ ">>" + pg._o.t._gestureName + "::::" + pg.t._gestureName);
						if(pg._o.c) pg._o.r = true;													
						pg.f = false; //如果当前已经在hold状态了，则需要重置这个f，其实就是，这次hold手势已经执行了，所以重置f
						//否则f就需要保留到下次那个先决条件手势的识别之后					
						pg._o.h = false;													
					}			
				}			
			}else{
//				trace("0"+ ">>" + pg.t._gestureName);
				if(value)
				{
					pg.t[pg.p0]();
					pg.r = true;
					newFirstG = pg;
				}else{
					
				}
			}
			if(newFirstG != null)
			{
				pg = _firstG;
				while (pg) {
					if(pg != newFirstG){
//						pg.t[pg.p3]();
						pg = pg._next;
					}else{
						if(pg != _firstG){
							pg._prev._next = pg._next;
							if(pg._next != null) pg._next._prev = pg._prev;
							_firstG._prev = pg;
							pg._next = _firstG;
							pg._prev = null;
							_firstG = pg;
						}					
						break;
					}
				}
			}
//			trace(_firstG.t._gestureName + ">>>" + _firstG.r);
		}
		
		private function onTouched(e:TouchEvent):void
		{
			var ts:Vector.<Touch> = e.getTouches(target);
			if(ts.length == 0) return;
			_ts = ts;
			var t:Touch = ts[0];
			_t = t;
			
			var n:int = ts.length;		
			if(t == null) return;
			
			if(t.phase == TouchPhase.BEGAN)
			{
				startGlobalX = t.globalX;
				startGlobalY = t.globalY;
			}
			
			loopGesture();
			if(vars.onTouch != null && vars.onTouch is Function) vars.onTouch(ts);					
			
			//循环当前绑定的识别手势链，每次都是从第一个开始，并利用_next指针。
			function loopGesture():void
			{				
				var pg:PropGesture = _firstG;			
				//////////////////////////////////////////////////////////////// TO DO 确认这段代码有没有必要
				if(pg != null && pg.r && !pg.c)
				{
					pg.r = false;
					if(!_allowSimultaneous) return; 
				}
				////////////////////////////////////////////////////////////////
				
				if(pg != null && pg.r && !_allowSimultaneous && pg.c){	
					
					pg.r = pg.t[pg.p2](ts);////////////////----------TO DO 如果在change时候（update）返回false，说明这个连续手势也停止了
//					trace("****" + pg.r + ">>" + ts.length);
				}else{
					//用于确认是否需要更换手势识别链的顺序，将识别出来的，连续的手势链挪到第一个
					var newFirstG:PropGesture;
					while (pg) {
						var r:Boolean = (pg.n == n) ? pg.t[pg.p1](ts) : false; //识别与否暂时使用强制相同的触摸点数n，考虑是否需要修改成 < n 
						if(r)
						{
							if(pg._o != null && pg._o.h) pg._o.h = false; 	//2012-11-26 如果识别出来了，并且有依赖这个手势识别失败作为条件的，则需要将hold状态消除。
																			//虽然这个手势不一定执行（如果还依赖别的手势），但是依赖关机只关心是否能识别，不关心是否执行与否。							
							if(pg._f != null)
							{						
								if(pg._f.r)
								{
									if(!pg._f.c) pg._f.r = false; //连续的情况会持续执行，一直到end，而里离散的情况需要在这重置
									pg = pg._next;
								}else if(pg._f.f){
									if(pg._o != null && pg._o.h) pg._o.h = false;
									pg._f.f = false;
									pg.t[pg.p0]();
//									trace("3"+ ">>" + pg.t._gestureName);
									if(pg._o != null) pg.r = true;
									if(pg.c){
										pg.r = true;
										pg.t[pg.p2](ts); //如果是保持识别状态的手势，则调用更新，如果是离散手势，r只是瞬时状态，对于连续的，r会在ended的时候被重置为false
										newFirstG = _allowSimultaneous ? null : pg;
									}
									pg = _allowSimultaneous ? pg._next : null;
								}else{
									if(!pg.h) pg.h = true;
									pg = pg._next;
								}
							}else{
								if(pg._o != null && pg._o.h) pg._o.h = false;			
								pg.t[pg.p0]();
//								trace("4" + ">>" + pg.t._gestureName + ">>" + pg.r);
								if(pg._o != null && pg.c) pg.r = true;
								if(pg.c){
									pg.r = true;
									pg.t[pg.p2](ts); //如果是保持识别状态的手势，则调用更新，如果是离散手势，r只是瞬时状态，对于连续的，r会在ended的时候被重置为false
									newFirstG = _allowSimultaneous ? null : pg;
								}
								pg = _allowSimultaneous ? pg._next : null;
							}		
						}else{
							if(pg._o != null)
							{
								pg.f = (pg.t._inProcess) ? false : true;
//								trace(pg.t._gestureName + ">>" + ts[0].phase + "::" + pg.f);
								if(pg.f){
									if(pg._o.h){
										pg._o.t[pg._o.p0]();
//										trace("5"+ ">>" + pg._o.t._gestureName);
										if(pg._o.c){
											pg._o.t[pg._o.p2](ts); 
											pg._o.r = true;													
										}
										pg.f = false; //如果当前已经在hold状态了，则需要重置这个f，其实就是，这次hold手势已经执行了，所以重置f
										//否则f就需要保留到下次那个先决条件手势的识别之后					
										pg._o.h = false;
										pg = null;
									}else{
										pg = pg._next;
									}
								}else{
									pg = pg._next;
								}		
							}else{
								pg = pg._next;
							}
							
						}
					}
					
					//找到已经被识别出来的手势，并且不允许多手势同事识别，此时需要将识别出来的手势挪到第一位，
					//实际上不需要多判断这个_allowSimultaneous，因为在之前的轮训中一旦发现是_allowSimultaneous，则newFirstG一定是null，只是保险起见
					if(newFirstG != null && !_allowSimultaneous)
					{
						pg = _firstG;
						while (pg) {
							if(pg != newFirstG){
//								pg.t[pg.p3]();
								pg = pg._next;
							}else{
								if(pg != _firstG){
									pg._prev._next = pg._next;
									if(pg._next != null) pg._next._prev = pg._prev;
									_firstG._prev = pg;
									pg._next = _firstG;
									pg._prev = null;
									_firstG = pg;
								}					
								break;
							}
						}
					}
				}
			}
		}
		
		public function getTouches():Vector.<Touch> { return _ts; }		
		public function getTouch():Touch { return _ts[0]; }
		
		/**
		 * 添加某种手势 
		 * @param vars
		 * @replaceExist	是否覆盖相同的手势
		 */		
		public function add(vars:Object, replaceExist:Boolean = false):void
		{
			if(!replaceExist)
			{
				var p:String,  plugin:Object;
				for (p in vars) 
				{
					if ((p in _gesturePlugins) && (plugin = new _gesturePlugins[p]())._onInitGesture(vars[p], vars[p]["config"], this))
					{
						_firstG = new PropGesture(plugin, "executeGesturRecognizedCallback", "checkGesture", "updateValue", _firstG, plugin._continuous, plugin._priority, plugin._numTouchesRequired);
						_ref[plugin._gestureType]  = _firstG;
					}
				}
			}else{
				//TO DO 完成覆盖相同手势的操作
			}
		}
		
		/**
		 * 移除莫一种手势 
		 * @param gestureType
		 * 
		 */		
		public function remove(gestureType:String):Boolean
		{
			var result:PropGesture;
			var pg:PropGesture = _firstG;
			while(pg){
				if(pg.t._gestureType == gestureType)
				{
					result = pg;			
					if(result._prev != null) result._prev._next = result._next;
					if(result._next != null) result._next._prev = result._prev;	
					if(result == _firstG) _firstG = result._next;
				}
				pg = pg._next;		
			}
			return result != null;
		}
		
		/**
		 * 销毁当前的和target关联的手势 
		 * 
		 */		
		public function dispose():void
		{
			
		}
		
		public static function add(target:DisplayObject, vars:Object = null, allowSimultaneous:Boolean = false):GestureManager
		{
			var g:GestureManager = new GestureManager(target, vars, allowSimultaneous);
			if(_gestures[target] == null) _gestures[target] = Vector.<GestureManager>([g]);
			else{
				var ref:Vector.<GestureManager> = _gestures[target];
				ref.push(g);
			}
			return g;
		}
		
		public static function removeAll(target:DisplayObject):void
		{
			
		}
		
		public function get allowSimultaneous():Boolean { return _allowSimultaneous; } 
		public function set allowSimultaneous(value:Boolean):void
		{
			_allowSimultaneous = value;
		}
		
	}
	
}
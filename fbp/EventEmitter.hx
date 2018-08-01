package fbp;

/**
 * An event emitter class. 
 * ...
 * @author Damilare Akinlaja
 */
class EventEmitter implements IEmitter
{
	public var _callbacks:Map<String, Array<EventCallback>> = new Map<String, Array<EventCallback>>();
	/**
	 * Initialize a new `Emitter`.
	 *
	 */

	public function new(){}
	

	/**
	 * Listen on the given `event` with `fn`.
	 *
	 * @param {String} event
	 * @param {Function} fn
	 * @return {Emitter}
	 */

	public function on(event:String, fn:EventCallback):EventEmitter
	{

		if (this._callbacks.exists(event))
		{
			this._callbacks.get(event).push(fn);

		}else{
			this._callbacks.set(event, [fn]);
		}
		
		return this;
	}

	/**
	 * Listen on the given `event` with `fn`.
	 *
	 * @param {String} event
	 * @param {Function} fn
	 * @return {Emitter}
	 */
	public function addEventListener(event:String, fn:EventCallback):EventEmitter
	{
		return this.on(event, fn);
	}

	/**
	 * Adds an `event` listener that will be invoked a single
	 * time then automatically removed.
	 *
	 * @param {String} event
	 * @param {Function} fn
	 * @return {Emitter}
	 */

	public function once(event:String, fn:EventCallback):EventEmitter
	{
		var self:EventEmitter = this;
		fn.once = true;	
		this.on(event, fn);
		return this;
	}

	/**
	 * Remove the given callback for `event` or all
	 * registered callbacks.
	 *
	 * @param {String} event
	 * @param {Function} fn
	 * @return {Emitter}
	 */

	public function off(?event:String, ?fn:EventCallback):EventEmitter
	{
		
		// All
		if (event == null)
		{
			for (key in this._callbacks.keys())
			{
				this._callbacks.remove(key);
			}

			return this;
		}

		// specific event
		if (!this._callbacks.exists(event))
		{
			return this;
		}
	
		// remove all handlers
		if (event != null && fn == null)
		{
			this._callbacks.remove(event);
			return this;
		}

		// remove specific handler
		var callbacks:Array<EventCallback> = this._callbacks.get(event);
		for (i in 0...(callbacks.length))
		{
			var cb = callbacks[i];

			if (cb == fn)
			{
				this._callbacks.get(event).splice(i, 1);
				break;
			}
		}

		return this;

	}

	public function removeListener(event:String, ?fn:EventCallback):EventEmitter
	{
		return this.off(event, fn);
	}

	public function removeAllListeners():EventEmitter
	{
		return this.off();
	}

	public function removeEventListener(event:String, fn:EventCallback):EventEmitter
	{
		return this.off(event, fn);
	}

	/**
	 * Emit `event` with the given args.
	 *
	 * @param {String} event
	 * @param {Array} args
	 * @return {Emitter}
	 */

	public function emit(event:String, ?args:Array<Dynamic>):EventEmitter
	{

		var _args:Array<Dynamic> = [];

		if (args != null)
		{
			_args = args.slice(0);
			
		}
		else{
			_args = [];
		}
		
		var callbacks = this._callbacks.get(event);
		

		if (callbacks != null)
		{
			callbacks = this._callbacks.get(event).slice(0);
			for (i in 0...callbacks.length)
			{
				
				var fn:EventCallback = callbacks[i];
				if(fn.once == true){
					this.off(event, fn);
				}
				
				fn.call(_args);
				
			}
		}

		return this;
	}

	/**
	 * Return array of callbacks for `event`.
	 *
	 * @param {String} event
	 * @return {Array}
	 */

	public function listeners(event:String):Array<Dynamic>
	{
		if (this._callbacks.exists(event))
		{
			return this._callbacks.get(event);
		}
		else{
			return [];
		}
	}

	/**
	 * Check if this emitter has `event` handlers.
	 *
	 * @param {String} event
	 * @return {Boolean}
	 */

	public function hasListeners(event:String):Bool
	{
		return this.listeners(event).length != 0;
	}

}


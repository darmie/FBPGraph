package fbp;

/**
 * Emitter interface
 * @author Damilare Akinlaja
 */
interface IEmitter 
{
	/**
	 * Listen on the given `event` with `fn`.
	 *
	 * @param {String} event
	 * @param {Function} fn
	 * @return {Emitter}
	 */

	public function on(event:String, fn:EventCallback):EventEmitter;


	/**
	 * Listen on the given `event` with `fn`.
	 *
	 * @param {String} event
	 * @param {Function} fn
	 * @return {Emitter}
	 */
	public function addEventListener(event:String, fn:EventCallback):EventEmitter;


	/**
	 * Adds an `event` listener that will be invoked a single
	 * time then automatically removed.
	 *
	 * @param {String} event
	 * @param {Function} fn
	 * @return {Emitter}
	 */

	public function once(event:String, fn:EventCallback):EventEmitter;


	/**
	 * Remove the given callback for `event` or all
	 * registered callbacks.
	 *
	 * @param {String} event
	 * @param {Function} fn
	 * @return {Emitter}
	 */

	public function off(?event:String, ?fn:EventCallback):EventEmitter;


	public function removeListener(event:String, ?fn:EventCallback):EventEmitter;


	public function removeAllListeners():EventEmitter;


	public function removeEventListener(event:String, fn:EventCallback):EventEmitter;


	/**
	 * Emit `event` with the given args.
	 *
	 * @param {String} event
	 * @param {Array} args
	 * @return {Emitter}
	 */

	public function emit(event:String, ?args:Array<Dynamic>):EventEmitter;

	
	/**
	 * Return array of callbacks for `event`.
	 *
	 * @param {String} event
	 * @return {Array}
	 */

	public function listeners(event:String):Array<Dynamic>;


	/**
	 * Check if this emitter has `event` handlers.
	 *
	 * @param {String} event
	 * @return {Boolean}
	 */

	public function hasListeners(event:String):Bool;

  
}
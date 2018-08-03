package fbp;

/**
 * Event Emitter Tools
 * @author Damilare Akinlaja
 */
class EmitterTools 
{

	static public function event(object:Dynamic):Dynamic
	{
		var emitter = new EventEmitter();
		var objholder = {
			on:  emitter.on,
			off: emitter.off,
			addEventListener: emitter.addEventListener,
			once: emitter.once ,
			removeListener: emitter.removeListener,
		    removeAllListeners: emitter.removeAllListeners,
			removeEventListener: emitter.removeEventListener,
			emit: emitter.emit,
			listeners: emitter.listeners,
			hasListeners: emitter.hasListeners
		}

		
		return objholder;
		
	}
	
}
package fbp;

/**
 * ...
 * @author Damilare Akinlaja
 */
class Events extends EventEmitter
{
	public function new() 
	{
		super();
	}
	
	public function fire(event:String, ?args:Array<Dynamic>):Void
	{
		this.emit(event, args);
	}
	
	public function hasEvent(event:String):Bool 
	{
		return this.hasListeners(event);
	}
}
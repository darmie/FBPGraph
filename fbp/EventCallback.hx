package fbp;

/**
 * The EventCallback class holds the callback function
 * It also make both the callback and it's arguments accessible and assignable 
 * 		from the class instance.
 * ...
 * @author Damilare Akinlaja
 */
class EventCallback
{
	@:isVar
	public var _args(get, set):Array <Dynamic>;
	
	@:isVar
	public var once(get, set):Bool;
	
	@:isVar 
	public var _call(get, set):Array<Dynamic>->Void;

	public function new(func:Array<Dynamic>->Void):Void
	{
		this._call = func;
	}
	
	
	private function get__call():Array<Dynamic>->Void
	{
		
		return this._call;
	}
	
	private function set__call(func:Array<Dynamic>->Void):Array<Dynamic>->Void
	{
		
		this._call = func;
		return this._call;
	}	
	
	
	private function get_once():Bool
	{
		
		return this.once;
	}
	
	private function set_once(bool):Bool
	{
		
		this.once = bool;
		return this.once;
	}	
	
	
	private function get__args():Array<Dynamic>
	{
		if(this._args == null){
			this._args = [];
		}
		return this._args;
	}
	
	
	private function set__args(args):Array<Dynamic>
	{
		
		this._args = args;
		
		return this._args;
	}

	public dynamic function call(args:Array<Dynamic>):Void
	{
		this._args = args;
		this._call(args);
	}

}
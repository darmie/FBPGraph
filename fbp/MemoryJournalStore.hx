package fbp;

class MemoryJournalStore extends JournalStore {
	public var transactions:Array<Dynamic>;

	public function new(graph:Graph) {
		super(graph);

		this.transactions = [];
	}

	@:keep override public function putTransaction(revId:Int, entries:Dynamic):Void {
		super.putTransaction(revId, entries);
		this.transactions.insert(revId, entries);
	}

	@:keep override public function fetchTransaction(revId:Int, ?entries:Dynamic):Dynamic {
		return transactions[revId];
	}
}
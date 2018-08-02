package fbp;

@:keep class JournalStore extends  EventEmitter {
	public var lastRevision:Int = 0;
	private var graph:Graph;

	public function new(graph:Graph) {
		super();
		this.graph = graph;
		this.lastRevision = 0;
	}

	@:keep public function putTransaction(revId:Int, entries:Dynamic):Void {
		if (revId > lastRevision){
			lastRevision = revId;
		}

		emit('transaction', [revId]);
	}

	@:keep public function fetchTransaction(revId:Int, ?entries:Dynamic):Dynamic {
		return {};
	}


}
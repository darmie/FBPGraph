/**
 * FBP Journal
 * (c) 2018 Damilare Akinlaja, Nigeria
 * (c) 2016-2017 Flowhub UG
 * (c) 2014 Jon Nordby
 * (c) 2013 Flowhub UG
 * (c) 2011-2012 Henri Bergius, Nemein
 * FBP Graph may be freely distributed under the MIT license
 */
package fbp;

@:keep class JournalStore extends  EventEmitter {
	public var lastRevision:Int = 0;
	private var graph:Graph;

	public function new(graph:Graph) {
		super();
		this.graph = graph;
		this.lastRevision = 0;
	}

	@:keep public function putTransaction(revId:Int, entries:Array<Journal.Entry>):Void {
		if (revId > lastRevision){
			lastRevision = revId;
		}

		emit('transaction', [revId]);
	}

	@:keep public function fetchTransaction(revId:Int, ?entries:Array<Journal.Entry>):Array<Journal.Entry> {
		return [];
	}


}
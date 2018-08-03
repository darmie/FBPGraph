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

class MemoryJournalStore extends JournalStore {
	public var transactions:Array<Array<Journal.Entry>>;

	public function new(graph:Graph) {
		super(graph);

		this.transactions = [];
	}

	@:keep override public function putTransaction(revId:Int, entries:Array<Journal.Entry>):Void {
		super.putTransaction(revId, entries);
		this.transactions.insert(revId, entries);
	}

	@:keep override public function fetchTransaction(revId:Int, ?entries:Array<Journal.Entry>):Array<Journal.Entry> {
		return transactions[revId];
	}
}
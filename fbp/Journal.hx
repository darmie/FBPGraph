
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

import fbp.Graph.*;


typedef Entry = {
	var cmd:String;
	var args:Dynamic;
	@:optional var rev:Dynamic;
}

/**
 * Journalling graph changes
 * 
 * The Journal can follow graph changes, store them
 * and allows to recall previous revisions of the graph.
 * 
 * Revisions stored in the journal follow the transactions of the graph.
 * It is not possible to operate on smaller changes than individual transactions.
 * Use startTransaction and endTransaction on Graph to structure the revisions logical changesets.
 */
@:keep class Journal extends  EventEmitter {
	@:keep public var graph:Graph;

	/**
	 * Entries added during this revision
	 */
	@:keep public var entries:Array<Dynamic>;

	/**
	 *  Whether we should respond to graph change notifications or not
	 */
	@:keep public var subscribed:Bool = true;

	@:keep private var store:MemoryJournalStore;

	@:keep private var currentRevision:Int;


	public function new(graph:Graph, metadata:Dynamic, ?store:MemoryJournalStore) {
		super();

		this.graph = graph;
		this.entries = [];
		this.subscribed = true;
		this.store = store != null ? store : new MemoryJournalStore(graph);


		if(this.store.transactions.length == 0){
			// Sync journal with current graph to start transaction history
			this.currentRevision = -1;
			this.startTransaction('initial', metadata);

			for(node in this.graph.nodes){
				this.appendCommand('addNode', node);
			}

			for(edge in this.graph.edges) {
				this.appendCommand('addEdge', edge);
			}
			
			for (iip in this.graph.initializers) {
				this.appendCommand('addInitial', iip);
			}
			if(Reflect.fields(this.graph.properties).length > 0) {
				this.appendCommand('changeProperties', this.graph.properties, {});
			}
			for(k in Reflect.fields(this.graph.inports)){
				var v = Reflect.field(this.graph.inports, k);
				this.appendCommand('addInport', {name: k, port: v});
			}
			for(k in Reflect.fields(this.graph.outports)){
				var v = Reflect.field(this.graph.outports, k);
				this.appendCommand('addOutport', {name: k, port: v});
			}	

			for(group in this.graph.groups){
				this.appendCommand('addGroup', group);
			}		
			
			
			this.endTransaction('initial', metadata);		
		} else {
			// Persistent store, start with its latest rev
			currentRevision = this.store.lastRevision;
		}

		// Subscribe to graph changes
		this.graph.on('addNode', new EventCallback(function(args:Array<Dynamic>):Void {
			var node = args[0];
			appendCommand('addNode', node);
		}));

		this.graph.on('removeNode', new EventCallback(function(args:Array<Dynamic>):Void {
			var node = args[0];
			appendCommand('removeNode', node);
		}));		

		this.graph.on('renameNode', new EventCallback(function(args:Array<Dynamic>):Void {
			var oldId = args[0];
			var newId = args[1];

			appendCommand('renameNode', {
				oldId: oldId,
				newId: newId
			});
		}));

		this.graph.on('changeNode', new EventCallback(function(args:Array<Dynamic>):Void {
			var node:fbp.Graph.Node = args[0];
			var oldMeta = args[1];

			appendCommand('changeNode', {id: node.id, _new: node.metadata, _old: oldMeta});
		}));

		this.graph.on('addEdge', new EventCallback(function(args:Array<Dynamic>):Void {
			var edge:fbp.Graph.Edge = args[0];
			appendCommand('addEdge', edge);
		}));	

		this.graph.on('removeEdge', new EventCallback(function(args:Array<Dynamic>):Void {
			var edge:fbp.Graph.Edge = args[0];
			appendCommand('removeEdge', edge);
		}));	

		this.graph.on('changeEdge', new EventCallback(function(args:Array<Dynamic>):Void {
			var edge:fbp.Graph.Edge = args[0];
			appendCommand('changeEdge', edge);
		}));	

		this.graph.on('addInitial', new EventCallback(function(args:Array<Dynamic>):Void {
			var iip:fbp.Graph.Initializer = args[0];
			appendCommand('addInitial', iip);
		}));

		this.graph.on('removeInitial', new EventCallback(function(args:Array<Dynamic>):Void {
			var iip:fbp.Graph.Initializer = args[0];
			appendCommand('removeInitial', iip);
		}));

		this.graph.on('changeProperties', new EventCallback(function(args:Array<Dynamic>):Void {
			var newProps = args[0];
			var oldProps = args[1];
			appendCommand('changeProperties', {_new: newProps, _old: oldProps});
		}));

		this.graph.on('addGroup', new EventCallback(function(args:Array<Dynamic>):Void {
			var group:fbp.Graph.Group = args[0];
			appendCommand('addGroup', group);
		}));

		this.graph.on('renameGroup', new EventCallback(function(args:Array<Dynamic>):Void {
			var oldName = args[0];
			var newName = args[1];
			appendCommand('renameGroup', {oldName: oldName, newName: newName});
		}));

		this.graph.on('removeGroup', new EventCallback(function(args:Array<Dynamic>):Void {
			var group:fbp.Graph.Group = args[0];
			appendCommand('removeGroup', group);
		}));

		this.graph.on('changeGroup', new EventCallback(function(args:Array<Dynamic>):Void {
			var group:fbp.Graph.Group = args[0];
			var oldMeta:Dynamic = args[1];
			appendCommand('changeGroup', {name: group.name, _new: group.metadata, _old: oldMeta});
		}));

		this.graph.on('addExport', new EventCallback(function(args:Array<Dynamic>):Void {
			var exported = args[0];
			appendCommand('addExport', exported);
		}));

		this.graph.on('removeExport', new EventCallback(function(args:Array<Dynamic>):Void {
			var exported = args[0];
			appendCommand('removeExport', exported);
		}));


		this.graph.on('addInport', new EventCallback(function(args:Array<Dynamic>):Void {
			var name:String = args[0];
			var port:String = args[1];
			appendCommand('addInport', {name: name, port: port});
		}));

		this.graph.on('removeInport', new EventCallback(function(args:Array<Dynamic>):Void {
			var name:String = args[0];
			var port:String = args[1];
			appendCommand('removeInport', {name: name, port: port});
		}));

		this.graph.on('renameInport', new EventCallback(function(args:Array<Dynamic>):Void {
			var oldId:String = args[0];
			var newId:String = args[1];
			appendCommand('renameInport', {oldId: oldId, newId: newId});
		}));

		this.graph.on('changeInport', new EventCallback(function(args:Array<Dynamic>):Void {
			var name:String = args[0];
			var port:Dynamic = args[1];
			var oldMeta:Dynamic = args[2];
			appendCommand('changeInport', {name: name, _new: port.metadata, _old: oldMeta});
		}));






		this.graph.on('addOutport', new EventCallback(function(args:Array<Dynamic>):Void {
			var name:String = args[0];
			var port:String = args[1];
			appendCommand('addOutport', {name: name, port: port});
		}));

		this.graph.on('removeOutport', new EventCallback(function(args:Array<Dynamic>):Void {
			var name:String = args[0];
			var port:String = args[1];
			appendCommand('removeOutport', {name: name, port: port});
		}));

		this.graph.on('renameOutport', new EventCallback(function(args:Array<Dynamic>):Void {
			var oldId:String = args[0];
			var newId:String = args[1];
			appendCommand('renameInport', {oldId: oldId, newId: newId});
		}));

		this.graph.on('changeOutport', new EventCallback(function(args:Array<Dynamic>):Void {
			var name:String = args[0];
			var port:Dynamic = args[1];
			var oldMeta:Dynamic = args[2];
			appendCommand('changeOutport', {name: name, _new: port.metadata, _old: oldMeta});
		}));


		this.graph.on('startTransaction', new EventCallback(function(args:Array<Dynamic>):Void {
			var id:String = args[0];
			var meta:Dynamic = args[1];	
			startTransaction(id, meta);	
		}));

		this.graph.on('endTransaction', new EventCallback(function(args:Array<Dynamic>):Void {
			var id:String = args[0];
			var meta:Dynamic = args[1];	
			endTransaction(id, meta);	
		}));																									
	}


	public function startTransaction(id:String, meta:Dynamic):Void {
		if(!this.subscribed){
			return;
		}

		if(this.entries.length > 0){
			throw "Inconsistent entries";
		}

		currentRevision++;
		appendCommand('startTransaction', {id: id, metadata: meta}, currentRevision);
	}

	public function endTransaction(id:String, meta:Dynamic):Void {
		if(!this.subscribed){
			return;
		}

		appendCommand('endTransaction', {id: id, metadata: meta}, currentRevision);

		// TODO: this would be the place to refine entries into
		// a minimal set of changes, like eliminating changes early in transaction
		// which were later reverted/overwritten
		store.putTransaction(currentRevision, entries);
		this.entries = [];
	}


	public function appendCommand(cmd:String, args:Dynamic, ?rev:Dynamic):Void {
		if(!this.subscribed){
			return;
		}

		var entry:Entry = {
			cmd:cmd,
			args: Reflect.copy(args)
		};

		if(rev != null){
			entry.rev = rev;
		}
		
		this.entries.push(entry);
	}
}
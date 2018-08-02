
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
	@:keep public var entries:Array<Entry>;

	/**
	 *  Whether we should respond to graph change notifications or not
	 */
	@:keep public var subscribed:Bool = true;

	@:keep private var store:MemoryJournalStore;

	@:keep private var currentRevision:Int;


	private static function calculateMeta(oldMeta:Dynamic, newMeta:Dynamic):Dynamic
	{
		var setMeta = {};
		for(k in Reflect.fields(oldMeta)){
			Reflect.setField(setMeta, k, null);
		}

		for(k in Reflect.fields(newMeta)){
			var v = Reflect.field(newMeta, k);
			Reflect.setField(setMeta, k, v);
		}

		return setMeta;	
	}

	private static function entryToPrettyString(entry:Entry){
		var a = entry.args;
		switch entry.cmd {
			case 'addNode' : return '${a.id}(${a.component})';
			case 'removeNode' : return 'DEL ${a.id}(${a.component})';
			case 'renameNode' : return 'RENAME ${a.oldId} ${a.newId}';
			case 'changeNode' : return 'META ${a.id}';
			case 'addEdge' : return '${a.from.node} ${a.from.port} -> ${a.to.port} ${a.to.node}';
			case 'removeEdge' : return '${a.from.node} ${a.from.port} -X> ${a.to.port} ${a.to.node}';
			case 'changeEdge' : return 'META ${a.from.node} ${a.from.port} -> ${a.to.port} ${a.to.node}';
			case 'addInitial' : return ''${a.from.data}' -> ${a.to.port} ${a.to.node}';
			case 'removeInitial' : return '"${a.from.data}" -X> ${a.to.port} ${a.to.node}';
			case 'startTransaction' : return '>>> ${entry.rev}: ${a.id}';
			case 'endTransaction' : return '<<< ${entry.rev}: ${a.id}';
			case 'changeProperties' : return 'PROPERTIES';
			case 'addGroup' : return 'GROUP ${a.name}';
			case 'renameGroup' : return 'RENAME GROUP ${a.oldName} ${a.newName}';
			case 'removeGroup' : return 'DEL GROUP ${a.name}';
			case 'changeGroup' : return 'META GROUP ${a.name}';
			case 'addInport' : return 'INPORT ${a.name}';
			case 'removeInport' : return 'DEL INPORT ${a.name}';
			case 'renameInport' : return 'RENAME INPORT ${a.oldId} ${a.newId}';
			case 'changeInport' : return 'META INPORT ${a.name}';
			case 'addOutport' : return 'OUTPORT ${a.name}';
			case 'removeOutport' : return 'DEL OUTPORT ${a.name}';
			case 'renameOutport' : return 'RENAME OUTPORT ${a.oldId} ${a.newId}';
			case 'changeOutport' : return 'META OUTPORT ${a.name}';
			default: throw 'Unknown journal entry: ${entry.cmd}';
		}
	}


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
			throw 'Inconsistent entries';
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


	@:keep public function executeEntry(entry:Entry):Void {
		var a:Dynamic = entry.args;

		switch entry.cmd {
			case 'addNode': this.graph.addNode(a.id, a.component);
			case 'removeNode': this.graph.removeNode(a.id);
			case 'renameNode': this.graph.renameNode(a.oldId, a.newId);
			case 'changeNode': this.graph.setNodeMetadata(a.id, calculateMeta(a._old, a._new));
			case 'addEdge': this.graph.addEdge(a.from.node, a.from.port, a.to.node, a.to.port);
			case 'removeEdge': this.graph.removeEdge(a.from.node, a.from.port, a.to.node, a.to.port);
			case 'changeEdge': this.graph.setEdgeMetadata(a.from.node, a.from.port, a.to.node, a.to.port, calculateMeta(a._old, a._new));
			case 'addInitial': this.graph.addInitial(a.from.data, a.to.node, a.to.port);
			case 'removeInitial': this.graph.removeInitial(a.to.node, a.to.port);
			case 'startTransaction': return;
			case 'endTransaction': return;
			case 'changeProperties' : this.graph.setProperties(a._new);
			case 'addGroup' : this.graph.addGroup(a.name, a.nodes, a.metadata);
			case 'renameGroup' : this.graph.renameGroup(a.oldName, a.newName);
			case 'removeGroup' : this.graph.removeGroup(a.name);
			case 'changeGroup' : this.graph.setGroupMetadata(a.name, calculateMeta(a._old, a._new));
			case 'addInport' : this.graph.addInport(a.name, a.port.process, a.port.port, a.port.metadata);
			case 'removeInport' : this.graph.removeInport(a.name);
			case 'renameInport' : this.graph.renameInport(a.oldId, a.newId);
			case 'changeInport' : this.graph.setInportMetadata(a.name, calculateMeta(a._old, a._new));
			case 'addOutport' : this.graph.addOutport(a.name, a.port.process, a.port.port, a.port.metadata);
			case 'removeOutport' : this.graph.removeOutport(a.name);
			case 'renameOutport' : this.graph.renameOutport(a.oldId, a.newId);
			case 'changeOutport' : this.graph.setOutportMetadata(a.name, calculateMeta(a._old, a._new));
			default: throw 'Unknown journal entry: ${entry.cmd}';										
		}
	}


	@:keep public function executeEntryInversed(entry:Entry):Void {
		var a:Dynamic = entry.args;

		switch entry.cmd {
			case 'addNode': this.graph.removeNode(a.id);
			case 'removeNode': this.graph.addNode(a.id, a.component);
			case 'renameNode': this.graph.renameNode(a.newId, a.oldId);
			case 'changeNode': this.graph.setNodeMetadata(a.id, calculateMeta(a._new, a._old));
			case 'addEdge': this.graph.removeEdge(a.from.node, a.from.port, a.to.node, a.to.port);
			case 'removeEdge': this.graph.addEdge(a.from.node, a.from.port, a.to.node, a.to.port);
			case 'changeEdge': this.graph.setEdgeMetadata(a.from.node, a.from.port, a.to.node, a.to.port, calculateMeta(a._new, a._old));
			case 'addInitial': this.graph.removeInitial(a.to.node, a.to.port);
			case 'removeInitial': this.graph.addInitial(a.from.data, a.to.node, a.to.port);
			case 'startTransaction': return;
			case 'endTransaction': return;
			case 'changeProperties' : this.graph.setProperties(a._old);
			case 'addGroup' : this.graph.removeGroup(a.name);
			case 'renameGroup' : this.graph.renameGroup(a.newName, a.oldName);
			case 'removeGroup' : this.graph.addGroup(a.name, a.nodes, a.metadata);
			case 'changeGroup' : this.graph.setGroupMetadata(a.name, calculateMeta(a._new, a._old));
			case 'addInport' : this.graph.removeInport(a.name);
			case 'removeInport' : this.graph.addInport(a.name, a.port.process, a.port.port, a.port.metadata);
			case 'renameInport' : this.graph.renameInport(a.newId, a.oldId);
			case 'changeInport' : this.graph.setInportMetadata(a.name, calculateMeta(a._new, a._old));
			case 'addOutport' : this.graph.removeOutport(a.name);
			case 'removeOutport' : this.graph.addOutport(a.name, a.port.process, a.port.port, a.port.metadata);
			case 'renameOutport' : this.graph.renameOutport(a.newId, a.oldId);
			case 'changeOutport' : this.graph.setOutportMetadata(a.name, calculateMeta(a._new, a._old));
			default: throw 'Unknown journal entry: ${entry.cmd}';										
		}
	}


	@:keep public function moveToRevision(revId:Int){
			if(revId == currentRevision){
				return;
			}

			subscribed = false;

			if(revId > currentRevision){
				// Forward replay journal to revId
				for(r in (currentRevision+1)...revId){
					for(entry in store.fetchTransaction(r)){
						executeEntry(entry);
					}
				}
			} else {
				// Move backwards, and apply inverse changes
				var j, i;
				j = currentRevision;
				while (j > (revId+1)) {
					entries = store.fetchTransaction(j);
					i = entries.length-1;
					while (i > 0) {
						executeEntryInversed(entries[i]);
						i += -1;
					}
					j += -1;
				}
			}

			currentRevision = revId;
			subscribed = true;
	}

		// Undoing & redoing

		/**
		 * Undo the last graph change
		 */
		@:keep public function undo() {
			if(!canUndo()){
				return;
			}
			moveToRevision(currentRevision-1);
		}

		/**
		 * Redo the last undo
		 */
		@:keep public function redo() {
			if(!canRedo()){
				return;
			}
			moveToRevision(currentRevision+1);
		}

		/**
		 * If there is something to undo
		 * @return Bool
		 */
		public function canUndo():Bool {
			return currentRevision > 0;
		}

		/**
		 * If there is something to redo
		 * @return Bool
		 */
		public function canRedo():Bool {
			return currentRevision < store.lastRevision;
		}



	// Serializing


	/**
	 * Render a pretty printed string of the journal. Changes are abbreviated
	 * @param startRev 
	 * @param endRev 
	 */
	public function toPrettyString(?startRev:Int, ?endRev:Int) {
		startRev |= 0;
		endRev |= store.lastRevision;
		var lines:Array<String> = [];

		for(r in startRev...endRev) {
			var e = store.fetchTransaction(r);

			for(entry in e){
				lines.push(entryToPrettyString(entry));
			}
		}

		return lines.join('\n');
	}

	/**
	 * Serialize journal to JSON
	 * @param startRev 
	 * @param endRev 
	 */
	public function toJSON(?startRev:Int, ?endRev:Int) {
		startRev |= 0;
		endRev |= store.lastRevision;
		var entries:Array<String> = [];
		var r = startRev;
		while(r < endRev) {
			var e = store.fetchTransaction(r);

			for(entry in e){
				entries.push(entryToPrettyString(entry));
			}

			r += 1;
		}

		return entries;
	}

	#if !js
	public function save(file:String, success:String->Void) {
		var json = haxe.Json.stringify(toJSON(), null, '\t');
		try{
			sys.io.File.saveContent('${file}.json', json);
			success(file);
		} catch(e:Dynamic) {
			throw e;
		}
	}
	#end

}
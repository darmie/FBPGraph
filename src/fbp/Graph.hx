/**
 * FBP Graph
 * (c) 2018 Damilare Akinlaja, Nigeria
 * (c) 2013-2017 Flowhub UG
 * (c) 2011-2012 Henri Bergius, Nemein
 * FBP Graph may be freely distributed under the MIT license
 */
package fbp;



#if !js
	import sys.io.File;
#end

using StringTools;

typedef Json =
{
	var caseSensitive:Bool;
	var properties:haxe.DynamicAccess<Dynamic>;
	var inports:haxe.DynamicAccess<Dynamic>;
	var outports:haxe.DynamicAccess<Dynamic>;
	var groups:Array<Group>;
	var processes:haxe.DynamicAccess<Dynamic>;
	var connections:Array<Connection>;
}

typedef ConnectionProp =
{
	var process:String;
	var port:String;
	var index:Int;
}

typedef Connection =
{
	@:optional var src:ConnectionProp;
	@:optional var tgt:ConnectionProp;
	@:optional var metadata:Dynamic;
	@:optional var data:Dynamic;
}

typedef Transaction =
{
	var id:String;
	var depth:Int;
}

typedef EdgeDirection =
{
	var node:String;
	var port:String;
	@:optional var index:Int;
}

typedef Edge =
{
	var from:EdgeDirection;
	var to:EdgeDirection;
	var metadata:Dynamic;
	@:optional var index:Int;
}

typedef InitializerTo =
{
	var node:String;
	var port:String;
	@:optional var index:Int;
}

typedef InitializerFrom =
{
	var data:Dynamic;
}

typedef Initializer =
{
	var from:InitializerFrom;
	var to:InitializerTo;
	@:optional var metadata:Dynamic;
}

typedef Node =
{
	var id:String;
	var component:String;
	@:optional var metadata:Dynamic;
	@:optional var display:Dynamic;
}

typedef Group =
{
	var name:String;
	var nodes:Array<String>;
	var metadata:Dynamic;
}

/**
 * FBP graphs are Event Emitters, providing signals when the graph
 * definition changes.
 *
 * This class represents an abstract FBP graph containing nodes
 * connected to each other with edges.
 *
 * These graphs can be used for visualization and sketching, but
 * also are the way to start an FBP network.
 */
@:keep class Graph extends EventEmitter
{

	@:keep public var name:String = '';

	@:keep public var caseSensitive:Bool = false;

	@:keep public var properties:Dynamic = {};

	@:keep public var nodes:Array<Node>;

	@:keep public var edges:Array<Edge>;

	@:keep public var initializers:Array<Initializer> = new Array<Initializer>();

	@:keep public var inports:Dynamic = {};

	@:keep public var outports:Dynamic = {};

	@:keep public var groups:Array<Group> = new Array<Group>();

	@:keep public var transaction:Transaction;

	/**
	 * Creating new graphs
	 *
	 * Graphs are created by simply instantiating the Graph class
	 * and giving it a name:
	 *
	 *
	 * var myGraph = new Graph('My very cool graph');
	 */
	public function new(name:String = '', ?options:Dynamic)
	{
		super();

		this.edges = new Array<Edge>();
		this.nodes = new Array<Node>();

		this.name = name;
		if (Reflect.hasField(options, 'caseSensitive') && options.caseSensitive != null)
		{
			this.caseSensitive = options.caseSensitive;
		}

		this.transaction =
		{
			id: null,
			depth: 0
		};
	}

	@:keep public function getPortName(port:String):String
	{
		if (this.caseSensitive)
		{
			return port;
		}
		else {
			return port.toLowerCase();
		}
	}

	/**
	 * Group graph changes into transactions
	 *
	 * If no transaction is explicitly opened, each call to
	 * the graph API will implicitly create a transaction for that change
	 *
	 * @param	id
	 * @param	metadata
	 */
	@:keep public function startTransaction(id:String, ?metadata:Dynamic):Void
	{
		if (this.transaction.id != null)
		{
			throw "Nested transaction not supported";
		}

		this.transaction.id = id;
		this.transaction.depth = 1;
		this.emit('startTransaction', [id, metadata != null ? metadata : {}]);
	}

	@:keep public function endTransaction(id:String, ?metadata:Dynamic):Void
	{
		if (this.transaction.id == null)
		{
			throw "Attempted to end non-existing transaction";
		}

		this.transaction.id = null;
		this.transaction.depth = 0;
		this.emit('endTransaction', [id, metadata != null ? metadata : {}]);
	}

	@:keep public function checkTransactionStart():Void
	{
		if (this.transaction.id == null)
		{
			this.startTransaction('implicit');
		}
		else if (this.transaction.id == 'implicit')
		{
			this.transaction.depth += 1;
		}
	}

	@:keep public function checkTransactionEnd():Void
	{
		if (this.transaction.id == 'implicit')
		{
			this.transaction.depth -= 1;
		}
		else if (this.transaction.depth == 0)
		{
			this.endTransaction('implicit');
		}
	}

	@:keep public function setProperties(properties:Dynamic):Void
	{
		this.checkTransactionStart();

		var before = Reflect.copy(this.properties);

		var propertyFields = Reflect.fields(properties);

		for (i in 0...propertyFields.length)
		{
			Reflect.setField(this.properties, propertyFields[i], Reflect.field(properties, propertyFields[i]));
		}

		this.emit('changeProperties', [this.properties, before]);
		this.checkTransactionEnd();
	}

	@:keep public function addInport(publicPort:String, nodeKey:String, portKey:String, ?metadata:Dynamic):Void
	{
		// Check that node exists

		if (this.getNode(nodeKey) == null)
		{
			return;
		}

		var publicPort:String = this.getPortName(publicPort);

		this.checkTransactionStart();

		Reflect.setField(this.inports, publicPort, {
			process: nodeKey,
			port: this.getPortName(portKey),
			metadata: metadata != null ? metadata : {}
		});

		this.emit('addInport', [publicPort, Reflect.field(this.inports, publicPort)]);
		this.checkTransactionEnd();
	}

	@:keep public function removeInport(publicPort:String):Void
	{
		publicPort = this.getPortName(publicPort);

		if (Reflect.field(this.inports, publicPort) == null)
		{
			return;
		}

		this.checkTransactionStart();
		var port = Reflect.field(this.inports, publicPort);

		this.setInportMetadata(publicPort, {});

		Reflect.deleteField(this.inports, publicPort);

		this.emit('removeInport', [publicPort, port]);

		this.checkTransactionEnd();

	}

	@:keep public function renameInport(oldPort:String, newPort:String):Void
	{
		oldPort = getPortName(oldPort);
		newPort = getPortName(newPort);

		if (Reflect.field(inports, 'oldPort') == null)
		{
			return;
		}

		if (newPort == oldPort)
		{
			return;
		}

		checkTransactionStart();

		Reflect.setField(inports, newPort, Reflect.field(inports, oldPort));

		Reflect.deleteField(inports, oldPort);

		emit('renameInport', [oldPort, newPort]);
		checkTransactionEnd();
	}

	@:keep public function setInportMetadata(publicPort:String, ?metadata:Dynamic):Void
	{
		metadata = metadata != null ? metadata : {};

		publicPort = getPortName(publicPort);

		if (Reflect.field(inports, publicPort) == null)
		{
			return;
		}

		checkTransactionStart();

		var before:Dynamic = Reflect.copy(Reflect.field(Reflect.field(inports, publicPort), 'metadata'));

		if (Reflect.field(Reflect.field(inports, publicPort), 'metadata') == null)
		{
			Reflect.setField(Reflect.field(inports, publicPort), 'metadata', {});
		}

		for (i in 0...Reflect.fields(metadata).length)
		{
			var val = Reflect.field(metadata, Reflect.fields(metadata)[i]);
			var item = Reflect.fields(metadata)[i];
			if (val != null)
			{
				Reflect.setField(Reflect.field(Reflect.field(inports, publicPort), 'metadata'), item, val);
			}
			else
			{
				Reflect.deleteField(Reflect.field(Reflect.field(inports, publicPort), 'metadata'), item);
			}
		}

		emit('changeInport', [publicPort, Reflect.field(inports, publicPort), before, metadata]);

		checkTransactionEnd();
	}

	@:keep public function addOutport(publicPort:String, nodeKey:String, portKey:String, ?metadata:Dynamic):Void
	{
		// Check that node exists

		if (this.getNode(nodeKey) == null)
		{
			return;
		}

		var publicPort:String = this.getPortName(publicPort);

		this.checkTransactionStart();

		Reflect.setField(this.outports, publicPort, {
			process: nodeKey,
			port: this.getPortName(portKey),
			metadata: metadata != null ? metadata : {}
		});

		this.emit('addOutport', [publicPort, Reflect.field(this.outports, publicPort)]);
		this.checkTransactionEnd();
	}

	@:keep public function removeOutport(publicPort:String):Void
	{
		publicPort = this.getPortName(publicPort);

		if (Reflect.field(this.outports, publicPort) == null)
		{
			return;
		}

		this.checkTransactionStart();
		var port = Reflect.field(this.outports, publicPort);

		this.setInportMetadata(publicPort, {});

		Reflect.deleteField(this.outports, publicPort);

		this.emit('removeOutport', [publicPort, port]);

		this.checkTransactionEnd();

	}

	@:keep public function renameOutport(oldPort:String, newPort:String):Void
	{
		oldPort = getPortName(oldPort);
		newPort = getPortName(newPort);

		if (Reflect.field(outports, 'oldPort') == null)
		{
			return;
		}

		if (newPort == oldPort)
		{
			return;
		}

		checkTransactionStart();

		Reflect.setField(outports, newPort, Reflect.field(outports, oldPort));

		Reflect.deleteField(outports, oldPort);

		emit('renameOutport', [oldPort, newPort]);
		checkTransactionEnd();
	}

	@:keep public function setOutportMetadata(publicPort:String, ?metadata:Dynamic):Void
	{

		metadata = metadata != null ? metadata : {};

		publicPort = getPortName(publicPort);

		if (Reflect.field(outports, publicPort) == null)
		{
			return;
		}

		checkTransactionStart();

		var before:Dynamic = Reflect.copy(Reflect.field(Reflect.field(outports, publicPort), 'metadata'));

		if (Reflect.field(Reflect.field(outports, publicPort), 'metadata') == null)
		{
			Reflect.setField(Reflect.field(outports, publicPort), 'metadata', {});
		}

		for (i in 0...Reflect.fields(metadata).length)
		{
			var val = Reflect.field(metadata, Reflect.fields(metadata)[i]);
			var item = Reflect.fields(metadata)[i];
			if (val != null)
			{
				Reflect.setField(Reflect.field(Reflect.field(outports, publicPort), 'metadata'), item, val);
			}
			else
			{
				Reflect.deleteField(Reflect.field(Reflect.field(outports, publicPort), 'metadata'), item);
			}
		}

		emit('changeOutport', [publicPort, Reflect.field(outports, publicPort), before, metadata]);

		checkTransactionEnd();
	}

	/**
	 * Group Nodes in a graph
	 * @param	group
	 * @param	nodes
	 * @param	metadata
	 */
	@:keep public function addGroup(group:String, nodes:Array<String>, ?metadata:Dynamic):Void
	{
		this.checkTransactionStart();

		var g:Group = {
			name: group,
			nodes: nodes,
			metadata: metadata != null ? metadata : {}
		};

		groups.push(g);

		emit('addGroup', [g]);

		checkTransactionEnd();
	}

	@:keep public function renameGroup(oldName:String, newName:String):Void
	{
		checkTransactionStart();
		for (i in 0...groups.length)
		{
			if (groups[i] == null)
			{
				continue;
			}

			if (groups[i].name == oldName)
			{
				continue;
			}

			groups[i].name = newName;

			emit('renameGroup', [oldName, newName]);
		}

		checkTransactionEnd();
	}

	@:keep public function removeGroup(groupName:String):Void
	{
		checkTransactionStart();

		for (i in 0...groups.length)
		{
			if (groups[i] == null)
			{
				continue;
			}

			if (groups[i].name == groupName)
			{
				continue;
			}

			setGroupMetadata(groups[i].name, {});

			groups.slice(groups.indexOf(groups[i]), 1);

			emit('removeGroup', [groups[i]]);
		}

		checkTransactionEnd();
	}

	@:keep public function setGroupMetadata(groupName:String, ?metadata:Dynamic):Void
	{
		metadata = metadata != null ? metadata : {};
		checkTransactionStart();
		for (i in 0...groups.length)
		{

			if (groups[i] == null)
			{
				continue;
			}

			if (groups[i].name == groupName)
			{
				continue;
			}

			var before:Dynamic = Reflect.copy(groups[i].metadata);

			for (k in 0...Reflect.fields(metadata).length)
			{
				var item = Reflect.fields(metadata)[k];
				var val = Reflect.field(metadata, item);

				if (val != null)
				{
					Reflect.setField(groups[i].metadata, item, val);
				}
				else
				{
					Reflect.deleteField(groups[i].metadata, item);
				}
			}
			emit('changeGroup', [groups[i], before, metadata]);
		}

		checkTransactionEnd();
	}

	/**
	 * Adding a node to the graph
	 *
	 * Nodes are identified by an ID unique to the graph. Additionally,
	 * a node may contain information on what FBP component it is and
	 * possible display coordinates.
	 *
	 * For example:
	 * 		myGraph.addNode('Read, 'ReadFile', {x:91, y:154});
	 *
	 * Addition of a node will emit the `addNode` event.
	 *
	 * @param	id
	 * @param	component
	 * @param	metadata
	 * @return  Node
	 */
	@:keep public function addNode(id:String, component:String, ?metadata:Dynamic):Node
	{
		checkTransactionStart();

		if (metadata == null)
		{
			metadata = {};
		}

		var node = {
			id: id,
			component: component,
			metadata: metadata
		};

		nodes.push(node);

		emit('addNode', [node]);

		checkTransactionEnd();

		return node;
	}

	@:keep public function removeNode(id:String):Void
	{
		var node:Node = getNode(id);
		if (node == null)
		{
			return;
		}

		checkTransactionStart();

		var toRemove:Array<Edge> = new Array<Edge>();

		for (i in 0...edges.length)
		{
			var edge = edges[i];
			if (edge.from.node == node.id ||  edge.to.node == node.id)
			{
				toRemove.push(edge);
			}
		}

		for (k in 0...toRemove.length)
		{
			var edge = toRemove[k];
			removeEdge(edge.from.node, edge.from.port, edge.to.node, edge.to.port);
		}

		var toRemove:Array<Initializer> = new Array<Initializer>();

		for (i in 0...initializers.length)
		{
			var initializer = initializers[i];
			if (initializer.to.node == node.id)
			{
				toRemove.push(initializer);
			}
		}

		for (k in 0...toRemove.length)
		{
			var initializer = toRemove[k];
			removeEdge(initializer.to.node, initializer.to.port);
		}

		var toRemove:Array<Dynamic> = new Array<Dynamic>();

		for (pub in Reflect.fields(outports))
		{
			var priv = Reflect.getProperty(outports, pub);

			if (priv.process == id)
			{
				toRemove.push(pub);
			}
		}

		for (pub in toRemove)
		{
			removeOutport(pub);
		}

		for (group in groups)
		{

			if (group == null)
			{
				continue;
			}

			var index = group.nodes.indexOf(id);

			if (index == -1)
			{
				continue;
			}

			group.nodes.splice(index, 1);
		}

		setNodeMetadata(id, {});

		if (nodes.indexOf(node) != -1)
		{
			nodes.splice(nodes.indexOf(node), 1);
		}

		emit('removeNode', [node]);

		checkTransactionEnd();
	}

	/**
	 * Getting a node
	 *
	 * Nodes objects can be retrieved from the graph by their ID:
	 *
	 * 		var myNode = myGraph.getNode('Read');
	 * @param	id
	 * @return  Node
	 */

	@:keep public function getNode(id:String):Node
	{
		for (i in 0...nodes.length)
		{
			if (nodes[i] == null)
			{
				continue;
			}

			if (nodes[i].id == id)
			{
				return nodes[i];
			}
		}

		return null;
	}

	@:keep public function renameNode(oldId:String, newId:String):Void
	{
		this.checkTransactionStart();

		var node = this.getNode(oldId);
		if (node == null)
		{
			return;
		}
		node.id = newId;

		for (edge in edges)
		{
			if (edge == null)
			{
				continue;
			}

			if (edge.from.node == oldId)
			{
				edge.from.node = newId;
			}
			if (edge.to.node == oldId)
			{
				edge.to.node = newId;
			}
		}

		for (iip in this.initializers)
		{
			if (iip == null)
			{
				continue;
			}
			if (iip.to.node == oldId)
			{
				iip.to.node = newId;
			}
		}

		for (pub in Reflect.fields(inports))
		{
			var priv = Reflect.getProperty(inports, pub);
			if (priv.process == oldId)
			{
				priv.process = newId;
			}
		}

		for (pub in Reflect.fields(outports))
		{
			var priv = Reflect.getProperty(outports, pub);
			if (priv.process == oldId)
			{
				priv.process = newId;
			}
		}

		for (group in groups)
		{
			if (group == null)
			{
				continue;
			}
			var index = group.nodes.indexOf(oldId);

			if (index == -1)
			{
				continue;
			}
			group.nodes[index] = newId;
		}

		emit('renameNode', [oldId, newId]);
		checkTransactionEnd();
	}

	/**
	 * Changing a node's metadata
	 *
	 * Node metadata can be set or changed by calling this method.
	 * @param	id
	 * @param	metadata
	 */
	@:keep public function setNodeMetadata(id:String, metadata:Dynamic):Void
	{
		var node = getNode(id);
		if (node == null)
		{
			return;
		}

		checkTransactionStart();

		var before = Reflect.copy(node.metadata);
		if (node.metadata == null)
		{
			node.metadata = {};
		}

		for (item in Reflect.fields(metadata))
		{
			var val = Reflect.field(metadata, item);

			if (val != null)
			{
				Reflect.setField(node.metadata, item, val);
			}
			else
			{
				Reflect.deleteField(metadata, item);
			}

		}

		emit('changeNode', [node, before, metadata]);
		checkTransactionEnd();

	}

	/**
	 * Adding an edge will emit the `addEdge` event.
	 */
	@:keep public function addEdgeIndex(outNode:String, outPort:String, outIndex:Int, inNode:String, inPort:String, inIndex:Int, ?metadata:Dynamic):Edge
	{
		if (getNode(outNode) == null)
		{
			return null;
		}
		if (getNode(inNode) == null)
		{
			return null;
		}

		outPort = getPortName(outPort);
		inPort = getPortName(inPort);

		checkTransactionStart();

		var edge:Edge = {
			from: {
				node:outNode,
				port:outPort,
				index:outIndex
			},
			to: {
				node:inNode,
				port:inPort,
				index:inIndex
			},
			metadata: metadata != null ? metadata : {}
		};

		edges.push(edge);

		emit('addEdge', [edge]);
		checkTransactionEnd();

		return edge;
	}

	/**
	 * Connecting nodes
	 * Nodes can be connected by adding edges between a node's outport
	 * and another node's inport:
	 *
	 *      myGraph.addEdge('Read', 'out', 'Display', 'in');
	 *      myGraph.addEdgeIndex('Read', 'out', null, 'Display', 'in', 2);
	 *
	 * Adding an edge will emit the `addEdge` event.
	 */
	@:keep public function addEdge(outNode:String, outPort:String, inNode:String, inPort:String, ?metadata:Dynamic):Edge
	{
		outPort = getPortName(outPort);
		inPort = getPortName(inPort);

		for (i in 0...edges.length)
		{
			var edge:Edge = edges[i];

			// don't add a duplicate edge
			if ((edge.from.node == outNode) && (edge.from.port == outPort) && (edge.to.node == inNode) && (edge.to.port == inPort))
			{
				return null;
			}
		}
		if (getNode(outNode) == null)
		{
			return null;
		}

		if (getNode(inNode) == null)
		{
			return null;
		}
		checkTransactionStart();

		var edge:Edge = {
			from: {
				node:outNode,
				port:outPort
			},
			to: {
				node:inNode,
				port:inPort
			},
			metadata: metadata != null ? metadata : {}
		};

		this.edges.push(edge);
		this.emit('addEdge', [edge]);

		checkTransactionEnd();

		return edge;
	}

	@:keep public function removeEdge(node:String, port:String, ?node2:String, ?port2:String):Void
	{
		this.checkTransactionStart();

		port = this.getPortName(port);

		if(port2 != null){
			port2 = getPortName(port2);
		}
		

		var toRemove:Array<Edge> = new Array<Edge>();

		var toKeep:Array<Edge> = new Array<Edge>();

		if (node2 != null && port2 != null)
		{
			for (i in 0...(edges.length))
			{
				var edge = edges[i];

				if ((edge.from.node == node) && (edge.from.port == port) && (edge.to.node == node2) && (edge.to.port == port2))
				{
					setEdgeMetadata(edge.from.node, edge.from.port, edge.to.node, edge.to.port, {});
					toRemove.push(edge);
				}
				else
				{
					toKeep.push(edge);
				}
			}
		}
		else {
			for (i in 0...edges.length)
			{
				var edge = edges[i];
				//var index = i;

				if ((edge.from.node == node && edge.from.port == port) || (edge.to.node == node && edge.to.port == port))
				{
					setEdgeMetadata(edge.from.node, edge.from.port, edge.to.node, edge.to.port, {});
					toRemove.push(edge);
				}
				else
				{
					toKeep.push(edge);
				}
			}
		}

		edges = toKeep;

		for (edge in toRemove)
		{
			emit('removeEdge', [edge]);
		}

		checkTransactionEnd();
	}

	/**
	 * Getting an edge
	 * Edge objects can be retrieved from the graph by the node and port IDs:
	 *
	 * 		 var myEdge = myGraph.getEdge('Read', 'out', 'Write', 'in');
	 * @param	node
	 * @param	port
	 * @param	node2
	 * @param	port2
	 * @return  Edge
	 */
	@:keep public function getEdge(node:String, port:String, node2:String, port2:String):Edge
	{
		port = getPortName(port);
		port2 = getPortName(port2);

		for (edge in edges)
		{
			if (edge == null)
			{
				continue;
			}

			if (edge.from.node == node && edge.from.port == port)
			{
				if (edge.to.node == node2 && edge.to.port == port2)
				{
					return edge;
				}
			}
		}

		return null;
	}

	/**
	 * Changing an edge's metadata
	 *
	 * Edge metadata can be set or changed by calling this method.
	 *
	 * @param	node
	 * @param	port
	 * @param	node2
	 * @param	port2
	 * @param	metadata
	 */
	@:keep public function setEdgeMetadata(node:String, port:String, node2:String, port2:String, ?metadata:Dynamic):Void
	{
		metadata = metadata != null ? metadata : {};

		var edge = getEdge(node, port, node2, port2);

		if (edge == null)
		{
			return;
		}

		checkTransactionStart();

		var before = Reflect.copy(edge.metadata);

		if (edge.metadata == null)
		{
			edge.metadata = {};
		}

		for (item in Reflect.fields(metadata))
		{
			var val = Reflect.field(metadata, item);

			if (val != null)
			{
				Reflect.setField(edge.metadata, item, val);
			}
			else
			{
				Reflect.deleteField(edge.metadata, item);
			}
		}

		emit('changeEdge', [edge, before, metadata]);

		checkTransactionEnd();
	}

	/**
	 * Adding Initial Information Packets
	 *
	 * Initial Information Packets (IIPs) can be used for sending data
	 * to specified node inports without a sending node instance.
	 *
	 * IIPs are especially useful for sending configuration information
	 * to components at FBP network start-up time. This could include
	 * filenames to read, or network ports to listen to.
	 *
	 * 		myGraph.addInitial('somefile.txt', 'Read', 'source');
	 * 		myGraph.addInitialIndex('somefile.txt', 'Read', 'source', 2);
	 *
	 * If inports are defined on the graph, IIPs can be applied calling
	 * the `addGraphInitial` or `addGraphInitialIndex` methods.
	 *
	 * 		myGraph.addGraphInitial('somefile.txt', 'file');
	 * 		myGraph.addGraphInitialIndex('somefile.txt', 'file', 2);
	 *
	 * Adding an IIP will emit a `addInitial` event.
	 * @param	data
	 * @param	node
	 * @param	port
	 * @param	metadata
	 * @return
	 */
	@:keep public function addInitial(data:String, node:String, port:String, ?metadata:Dynamic):Initializer
	{
		if (getNode(node) == null)
		{
			return null;
		}

		port = getPortName(port);

		checkTransactionStart();

		var initializer:Initializer = {
			from :{
				data: data
			},
			to:{
				node: node,
				port: port
			},
			metadata: metadata != null ? metadata : {}
		};

		initializers.push(initializer);

		emit('addInitial', [initializer]);

		checkTransactionEnd();

		return initializer;
	}

	@:keep public function addInitialIndex(data:String, node:String, port:String, index:Int, ?metadata:Dynamic):Initializer
	{
		if (getNode(node) == null)
		{
			return null;
		}

		port = getPortName(port);

		checkTransactionStart();

		var initializer:Initializer = {
			from: {
				data: data
			},
			to: {
				node: node,
				port: port,
				index: index
			},
			metadata: metadata != null ? metadata : {}
		};

		initializers.push(initializer);

		emit('addInitial', [initializer]);

		checkTransactionEnd();

		return initializer;
	}

	@:keep public function addGraphInitial(data:String, node:String, ?metadata:Dynamic):Void
	{
		var inport = Reflect.field(inports, node);

		if (inport == null)
		{
			return;
		}

		addInitial(data, inport.process, inport.port, metadata != null ? metadata : {});
	}

	@:keep public function addGraphInitialIndex(data:String, node:String, index:Int, ?metadata:Dynamic):Void
	{
		var inport = Reflect.field(inports, node);

		if (inport == null)
		{
			return;
		}

		addInitialIndex(data, inport.process, inport.port, index, metadata != null ? metadata : {});
	}

	@:keep public function removeInitial(node:String, port:String):Void
	{
		port = getPortName(port);

		checkTransactionStart();

		var toRemove:Array<Initializer> = [];
		var toKeep:Array<Initializer> = [];

		for (i  in 0...initializers.length)
		{
			var edge = initializers[i];

			if (edge.to.node == node && edge.to.port == port)
			{
				toRemove.push(edge);
			}
			else
			{
				toKeep.push(edge);
			}
		}

		initializers = toKeep;

		for (edge in toRemove)
		{
			emit('removeInitial', [edge]);
		}

		checkTransactionEnd();
	}

	@:keep public function removeGraphInitial(node:String):Void
	{
		var inport = Reflect.field(inports, node);

		if (inport == null)
		{
			return;
		}

		removeInitial(inport.process, inport.port);
	}

	@:keep public function toJSON():Json
	{
		var json:Json = {
			caseSensitive: caseSensitive,
			properties: {},
			inports: {},
			outports:{},
			groups: [],
			processes: {},
			connections: []
		};

		json.properties.set('name', name);
		for (property in Reflect.fields(properties))
		{
			var value = Reflect.field(properties, property);
			json.properties.set(property, value);
		}

		for (pub in Reflect.fields(inports))
		{
			json.inports.set(pub, Reflect.field(inports, pub));
		}

		for (pub in Reflect.fields(outports))
		{
			json.outports.set(pub, Reflect.field(outports, pub));
		}

		for (i in 0...groups.length)
		{
			var group = groups[i];
			var groupData:Group =
			{
				name: group.name,
				nodes: group.nodes,
				metadata: {}
			};

			if (Reflect.fields(group.metadata).length > 0)
			{
				groupData.metadata = group.metadata;
			}

			json.groups.push(groupData);
		}

		for(node in this.nodes){
			json.processes.set(node.id, {
				component: node.component
			});

			if(node.metadata != {}){
				json.processes.get(node.id).metadata = node.metadata;
			}
		}

		for (i in 0...edges.length)
		{
			var edge = edges[i];
			var connection:Connection =
			{
				src: {
					process: edge.from.node,
					port: edge.from.port,
					index: edge.from.index
				},
				tgt: {
					process: edge.to.node,
					port: edge.to.port,
					index: edge.to.index
				},
				metadata: {}
			};

			if (Reflect.fields(edge.metadata).length > 0)
			{
				connection.metadata = edge.metadata;
			}

			json.connections.push(connection);
		}

		for (i in 0...initializers.length)
		{
			var initializer:Initializer = initializers[i];
			json.connections.push(
			{
				data: initializer.from.data,
				tgt: {
					process: initializer.to.node,
					port: initializer.to.port,
					index: initializer.to.index
				}
			});
		}

		return json;
	}

	#if !js
	@:keep public function save(file:String, callback:Dynamic->String->Void):Void
	{
		var json:String = haxe.Json.stringify(toJSON(), null, '\t');

		var regx = new EReg('\\.json$', '');

		if (regx.match(file))
		{
			file = '${file}.json';
		}

		try{
			File.saveContent(file, json);
			callback(null, file);
		}
		catch (e:Dynamic)
		{
			callback(e, null);
		}
	}

	#end

	@:keep public static function loadJSON(definition:Json, callback:Dynamic->Graph->Void, ?metadata:Dynamic):Void
	{
		metadata = metadata != null ? metadata : {};
		var name = definition.properties.get('name');
		var graph = new Graph(name, {caseSensitive: definition.caseSensitive});

		graph.startTransaction('loadJSON', metadata);

		var properties = {};
		
		for(property in definition.properties.keys()) {
			var value = definition.properties.get(property);
			if (property ==  'name'){
				Reflect.setField(properties, property, value);
			}
		}
		
		graph.setProperties(properties);
		
		for (id in definition.processes.keys()) {
			var def = definition.processes.get(id);
			
			graph.addNode(id, def.component, def.metadata);
		}
		
		for(i in 0...definition.connections.length) {
			var conn = definition.connections[i];
			
			metadata = conn.metadata;
			
			if(conn.data != null) {
				if (Std.is(conn.tgt.index, Int)){
					graph.addInitialIndex(conn.data, conn.tgt.process, graph.getPortName(conn.tgt.port), conn.tgt.index, metadata);
				} else {
					graph.addInitial(conn.data, conn.tgt.process, graph.getPortName(conn.tgt.port), metadata);
				}
				
				continue;
			}
			
			if (Std.is(conn.src.index, Int) ||  Std.is(conn.tgt.index, Int)){
				graph.addEdgeIndex(conn.src.process, graph.getPortName(conn.src.port), conn.src.index, conn.tgt.process, graph.getPortName(conn.tgt.port), conn.tgt.index, metadata);
			
				continue;
			}
			
			graph.addEdge(conn.src.process, graph.getPortName(conn.src.port), conn.tgt.process, graph.getPortName(conn.tgt.port), metadata);
		}
		
		if(definition.inports != null){
			for(pub in definition.inports.keys()){
				var priv = definition.inports.get(pub);
				graph.addInport(pub, priv.process, graph.getPortName(priv.port), priv.metadata);
			}
		}
		if(definition.outports != null){
			for(pub in definition.outports.keys()){
				var priv = definition.outports.get(pub);
				graph.addInport(pub, priv.process, graph.getPortName(priv.port), priv.metadata);
			}
		}
		
		if(definition.groups != null){
			for(i in 0...definition.groups.length){
				var group = definition.groups[i];
				graph.addGroup(group.name, group.nodes, group.metadata);
			}
		}
		
		graph.endTransaction('loadJSON');
		
		callback(null, graph);
	}
	
	
	@:keep private static function resetGraph(graph:Graph):Void {
		// Edges and similar first, to have control over the order
		// If we'd do nodes first, it will implicitly delete edges
		// Important to make journal transactions invertible
		var groups = graph.groups.copy();
		groups.reverse();
		for(group in groups){
			if(group != null) {
				graph.removeGroup(group.name);
			}
		}

		for(port in Reflect.fields(graph.outports)) {
			graph.removeOutport(port);
		}

		for(port in Reflect.fields(graph.inports)) {
			graph.removeInport(port);
		}

		graph.setProperties({});

		var initializers = graph.initializers;
		initializers.reverse();
		for(iip in initializers) {
			graph.removeInitial(iip.to.node, iip.to.port);
		}

		var edges = graph.edges;
		edges.reverse();
		for(edge in edges){
			graph.removeEdge(edge.from.node, edge.from.port, edge.to.node, edge.to.port);
		}

		var nodes = graph.nodes;
		nodes.reverse();
		for(node in nodes){
			graph.removeNode(node.id);
		}
	}
	
	/**
	 * Note: Caller should create transaction
	 * First removes everything in *base, before building it up to mirror *to
	 * @param base 
	 * @param to 
	 */
	@:keep public static function mergeResolveTheirsNaive(base:Graph, to:Graph) {
		resetGraph(base);

		for(node in to.nodes){
			base.addNode(node.id, node.component, node.metadata);
		}

		for(edge in to.edges){
			base.addEdge(edge.from.node, edge.from.port, edge.to.node, edge.to.port, edge.metadata);
		}

		for(iip in to.initializers){
			base.addInitial(iip.from.data, iip.to.node, iip.to.port, iip.metadata);
		}

		base.setProperties(to.properties);

		for(pub in Reflect.fields(to.inports)){
			var priv = Reflect.field(to.inports, pub);
			base.addInport(pub, priv.process, priv.port, priv.metadata);
		}

		for(pub in Reflect.fields(to.outports)){
			var priv = Reflect.field(to.outports, pub);
			base.addOutport(pub, priv.process, priv.port, priv.metadata);
		}

		for(group in to.groups){
			base.addGroup(group.name, group.nodes, group.metadata);
		}
	}
}


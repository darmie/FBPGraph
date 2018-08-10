package;

import utest.Assert;
import utest.Runner;
import utest.ui.Report;
import fbp.*;

import fbp.Graph.Node;

/**
 * Graph test spec
 */
class GraphSpec {

	public var g:fbp.Graph;

	public var n:fbp.Graph.Node = null;

	public function new() {}

	public function setup(){
		//g = null;
	}

	public function testUnNamedGraphInstance() {
		g = new Graph();

		Assert.equals("", g.name);
	}

	public function testNamedGraphInstance() {
		g = null;
		g = new Graph('Foo bar', {caseSensitive: true});
		
		Assert.equals("Foo bar", g.name);

		var moreTests = new utest.Dispatcher();

		moreTests.add(shouldHaveNoNodesInitially);
		moreTests.add(shouldHaveNoEdgesInitially);
		moreTests.add(shouldHaveNoInitializersInitially);
		moreTests.add(shouldHaveNoExportsInitially);
		moreTests.add(shouldEmitAnEventWhenNewNode);
		moreTests.add(shouldBeInGraphListOfNodes);
		moreTests.add(shouldBeAccessibleViaGetter);
		moreTests.add(shouldHaveEmptyMetadata);
		moreTests.add(shouldBeAvailableInJSONExport);
		moreTests.add(shouldEmitEventWhenRemoved);

		moreTests.add(shouldEmitAnEventWhenNewEdge);
		moreTests.add(shouldAddEdge);
		moreTests.add(shouldRefuseDuplicateEdge);
		moreTests.add(shouldEmitAnEventWhenNewEdgeWithIndex);

		moreTests.dispatch(null);
	}

	public function shouldHaveNoNodesInitially(e:Dynamic) {
		Assert.equals(0, g.nodes.length);
	}

	public function shouldHaveNoEdgesInitially(e:Dynamic) {
		Assert.equals(0, g.edges.length);
	}	

	public function shouldHaveNoInitializersInitially(e:Dynamic) {
		Assert.equals(0, g.initializers.length);
	}

	public function shouldHaveNoExportsInitially(e:Dynamic) {
		Assert.isTrue(Reflect.fields(g.inports).length == 0);
		Assert.isTrue(Reflect.fields(g.outports).length == 0);
	}

	public function shouldEmitAnEventWhenNewNode(e:Dynamic) {
		n = null;
		
		g.once('addNode', new fbp.EventCallback((args:Array<Dynamic>)->{
			var node:fbp.Graph.Node = args[0];
			Assert.equals('Foo', node.id);
			Assert.equals('Bar', node.component);
			n = node;
		}));

		g.addNode('Foo', 'Bar');
	}

	public function shouldBeInGraphListOfNodes(e:Dynamic) {
		Assert.equals(1, g.nodes.length);
		Assert.equals(0, g.nodes.indexOf(n));
	}

	public function shouldBeAccessibleViaGetter(e:Dynamic) {
		var node = g.getNode('Foo');
		Assert.equals('Foo', node.id);
		Assert.same(node, n);	
	}

	public function shouldHaveEmptyMetadata(e:Dynamic) {
		var node:Node = g.getNode('Foo');

		Assert.same({}, node.metadata);
		Assert.isNull(node.display);	
	}


	public function shouldBeAvailableInJSONExport(e:Dynamic) {
	 	var json = g.toJSON();
		
	 	Assert.isTrue(Std.is(json.processes.get('Foo'), Dynamic));

	 	var val = json.processes.get('Foo');
	 	Assert.equals('Bar', val.component);
		Assert.isNull(val.display);
	}


	public function shouldEmitEventWhenRemoved(e:Dynamic) {
		g.once('removeNode', new fbp.EventCallback((args:Array<Dynamic>)->{
			var node:Node = args[0];

			Assert.equals('Foo', node.id);
			Assert.same(node, n);
		}));

		g.removeNode('Foo');
	}


	public function shouldEmitAnEventWhenNewEdge(e:Dynamic) {
		g.addNode('Foo', 'foo');
		g.addNode('Bar', 'bar');

		g.once('addEdge', new fbp.EventCallback((args:Array<Dynamic>)->{
			var edge:fbp.Graph.Edge = args[0];

			Assert.equals('Foo', edge.from.node);
			Assert.equals('In', edge.to.port);
		}));

		g.addEdge('Foo', 'Out', 'Bar', 'In');
	}

	public function shouldAddEdge(e:Dynamic) {
		g.addEdge('Foo', 'out', 'Bar', 'in2');

		Assert.equals(2, g.edges.length);
	}

	public function shouldRefuseDuplicateEdge(e:Dynamic) {
		var edge = g.edges[0];

		g.addEdge(edge.from.node, edge.from.port, edge.to.node, edge.to.port);

		Assert.equals(g.edges.length, 2);
	}

	public function shouldEmitAnEventWhenNewEdgeWithIndex(e:Dynamic) {
		g.once('addEdge', new fbp.EventCallback((args:Array<Dynamic>)->{
			var edge:fbp.Graph.Edge = args[0];

			Assert.equals('Foo', edge.from.node);
			Assert.equals('in', edge.to.port);
			Assert.equals(1, edge.to.index);
			Assert.equals(edge.from.index, 0);
			Assert.equals(3, g.edges.length);
		}));

		g.addEdgeIndex('Foo', 'out', 0, 'Bar', 'in', 1);
	}


	private var jsonString = '
	{
		"caseSensitive": true,
		"properties": {
			"name": "Example",
			"foo": "Baz",
			"bar": "Foo"
		},
		"inports": {
			"inPut": {
			"process": "Foo",
			"port": "inPut",
			"metadata": {
				"x": 5,
				"y": 100
			}
			}
		},
		"outports": {
			"outPut": {
			"process": "Bar",
			"port": "outPut",
			"metadata": {
				"x": 500,
				"y": 505
			}
			}
		},
		"groups": [
			{
			"name": "first",
			"nodes": [
				"Foo"
			],
			"metadata": {
				"label": "Main"
			}
			},
			{
			"name": "second",
			"nodes": [
				"Foo2",
				"Bar2"
			]
			}
		],
		"processes": {
			"Foo": {
			"component": "Bar",
			"metadata": {
				"display": {
				"x": 100,
				"y": 200
				},
				"routes": [
				"one",
				"two"
				],
				"hello": "World"
			}
			},
			"Bar": {
			"component": "Baz",
			"metadata": {}
			},
			"Foo2": {
			"component": "foo",
			"metadata": {}
			},
			"Bar2": {
			"component": "bar",
			"metadata": {}
			}
		},
		"connections": [
			{
			"src": {
				"process": "Foo",
				"port": "outPut"
			},
			"tgt": {
				"process": "Bar",
				"port": "inPut"
			},
			"metadata": {
				"route": "foo",
				"hello": "World"
			}
			},
			{
			"src": {
				"process": "Foo",
				"port": "out2"
			},
			"tgt": {
				"process": "Bar",
				"port": "in2",
				"index": 2
			},
			"metadata": {
				"route": "foo",
				"hello": "World"
			}
			},
			{
			"data": "Hello, world!",
			"tgt": {
				"process": "Foo",
				"port": "inPut"
			}
			},
			{
			"data": "Hello, world, 2!",
			"tgt": {
				"process": "Foo",
				"port": "in2"
			}
			},
			{
			"data": "Cheers, world!",
			"tgt": {
				"process": "Foo",
				"port": "arr",
				"index": 0
			}
			},
			{
			"data": "Cheers, world, 2!",
			"tgt": {
				"process": "Foo",
				"port": "arr",
				"index": 1
			}
			}
		]
	}';

	var json:fbp.Graph.Json;
	public function testShouldProduceAGraph(){
		json = haxe.Json.parse(jsonString);
		g = null;

		fbp.Graph.loadJSON(json, (err:Dynamic, instance:fbp.Graph)->{
			if(err != null){
				return;
			}

			g = instance;
			Assert.is(g, fbp.Graph);
		});

		var moreTasks = new utest.Dispatcher();

		//should have a name
		moreTasks.add((e:Dynamic)->{
			Assert.equals('Example', g.name);
		});

		//should have graph metadata intact
		moreTasks.add((e:Dynamic)->{
			Assert.same({foo:'Baz', bar:'Foo'}, g.properties);
		});

		// should produce same JSON when serialized
		moreTasks.add((e:Dynamic)->{
			Assert.same(json, g.toJSON());
		});	

		// should allow modifying graph metadata
		moreTasks.add((e:Dynamic)->{
			g.once('changeProperties', new fbp.EventCallback((args:Array<Dynamic>)->{
				var properties:Dynamic = args[0];
				Assert.same(properties, g.properties);
				Assert.same(g.properties, {
					foo: 'Baz',
					bar: 'Bar',
					hello: 'World'
				});
			}));

			g.setProperties({
				hello: 'World',
				bar: 'Bar'
			});
		});

		// should contain four nodes
		moreTasks.add((e:Dynamic)->{
			Assert.equals(4, g.nodes.length);
		});

		// the first Node should have its metadata intact
		moreTasks.add((e:Dynamic)->{
			var node = g.getNode('Foo');

			Assert.is(node.metadata, Dynamic);
			Assert.is(node.metadata.display, Dynamic);
			Assert.equals(100, node.metadata.display.x);
			Assert.equals(200, node.metadata.display.y);
			Assert.is(node.metadata.routes, Array);
			Assert.contains('one', node.metadata.routes);
			Assert.contains('two', node.metadata.routes);
		});

		// should allow modifying node metadata
		moreTasks.add((e:Dynamic)->{
			g.once('changeNode', new fbp.EventCallback((args:Array<Dynamic>)->{
				var node:fbp.Graph.Node = args[0];
				Assert.equals('Foo', node.id);
				Assert.is(node.metadata.routes, Array);
				Assert.contains('one', node.metadata.routes);
				Assert.contains('two', node.metadata.routes);
				Assert.equals('World', node.metadata.hello);					
			}));

			g.setNodeMetadata('Foo', {
				hello: 'World'
			});
		});

		// should contain two connections
		moreTasks.add((e:Dynamic)->{
			Assert.equals(2, g.edges.length);
		});

		// the first Edge should have its metadata intact
		moreTasks.add((e:Dynamic)->{
			var e = g.edges[0];

			g.once('changeEdge', new fbp.EventCallback((args:Array<Dynamic>)->{
				var edge:fbp.Graph.Edge = args[0];
				Assert.equals(e, edge);
				Assert.equals('foo', edge.metadata.route);
				Assert.equals('World', edge.metadata.hello);
			}));

			g.setEdgeMetadata(e.from.node, e.from.port, e.to.node, e.to.port, {hello: 'World'});
		});

		// should contain four IIPs
		moreTasks.add((e:Dynamic)->{
			Assert.equals(4, g.initializers.length);
		});

		// should contain one published inport
		moreTasks.add((e:Dynamic)->{
			Assert.isFalse(Reflect.fields(g.inports).length == 0);
		});

		// should contain one published outport
		moreTasks.add((e:Dynamic)->{
			Assert.isFalse(Reflect.fields(g.outports).length == 0);
		});		

		// should keep the output export metadata intact
		moreTasks.add((e:Dynamic)->{
			var exp = g.outports.outPut;

			Assert.equals(500, exp.metadata.x);
			Assert.equals(505, exp.metadata.y);
		});

		// should contain two groups
		moreTasks.add((e:Dynamic)->{
			Assert.equals(2, g.groups.length);
		});

		// should allow modifying group metadata
		moreTasks.add((e:Dynamic)->{
			var group = g.groups[0];

			g.once('changeGroup', new fbp.EventCallback((args:Array<Dynamic>)->{
				var grp:fbp.Graph.Group = args[0];

				Assert.same(group, grp);
				Assert.equals('Main', grp.metadata.label);
				Assert.equals('Bar', grp.metadata.foo);
				Assert.same({}, g.groups[1].metadata);
			}));

			g.setGroupMetadata('first', {
				foo: 'Bar'
			});
		});

		// should allow renaming groups
		moreTasks.add((e:Dynamic)->{
			var group = g.groups[0];

			g.once('renameGroup', new fbp.EventCallback((args:Array<Dynamic>)->{
				var oldName:String = args[0];
				var newName:String = args[1];

				Assert.equals('first', oldName);
				Assert.equals('renamed', newName);
				Assert.equals(newName, group.name);
			}));

			g.renameGroup('first', 'renamed');
		});
		
		// renaming a node should emit event
		moreTasks.add((e:Dynamic)->{

			g.once('renameNode', new fbp.EventCallback((args:Array<Dynamic>)->{
				var oldId:String = args[0];
				var newId:String = args[1];

				Assert.equals('Foo', oldId);
				Assert.equals('Baz', newId);
			}));

			g.renameNode('Foo', 'Baz');
		});

		// should be available with the new name
		moreTasks.add((e:Dynamic)->{
			Assert.is(g.getNode('Baz'), Dynamic);
		});

		// shouldn't be available with the old name
		moreTasks.add((e:Dynamic)->{
			Assert.isNull(g.getNode('Foo'));
		});

		// should have the edge still going from it
		moreTasks.add((e:Dynamic)->{
			var connection = null;

			for(edge in g.edges){
				if (edge.from.node == 'Baz') {
					connection = edge;
				}
			}

			Assert.is(connection, Dynamic);
		});

		// should still be exported
		moreTasks.add((e:Dynamic)->{
			Assert.equals('Baz', g.inports.inPut.process);
		});


		// should still be grouped
		moreTasks.add((e:Dynamic)->{
		 	var groups = 0;

		 	for (group in g.groups){
		 		if(group.nodes.indexOf('Baz') != -1){
		 			groups++;
		 		}
		 	}
		 	Assert.equals(1, groups);
		});

		// shouldn't be having edges with the old name
		moreTasks.add((e:Dynamic)->{
			var connection = null;

			for(edge in g.edges) {
				if(edge.from.node == 'Foo') {
					connection = edge;
				}
				if(edge.to.node == 'Foo'){
					connection = edge;
				}
			}	
			Assert.isNull(connection);
		});

		// should have the IIP still going to it
		moreTasks.add((e:Dynamic)->{
			var iip = null;

			for(edge in g.initializers){
				if(edge.to.node == 'Baz'){
					iip = edge;
				}
			}
			Assert.is(iip, Dynamic);
		});

		// shouldn't be grouped with the old name
		moreTasks.add((e:Dynamic)->{
			var groups = 0;
			
			for(group in g.groups){
		 		if (group.nodes.indexOf('Foo') != -1) {
		 			groups++;
		 		}
		 	}
		 	Assert.equals(0, groups);
		});


		// renaming an inport should emit an event
		moreTasks.add((e:Dynamic)->{
			
			g.once('renameInport', new fbp.EventCallback((args:Array<Dynamic>)->{
				var oldName = args[0];
				var newName = args[1];

				Assert.equals('inPut', oldName);
				Assert.equals('opt', newName);
				Assert.is(g.inports.inPut, Dynamic);
				Assert.is(g.inports.opt, Dynamic);
				Assert.equals('Baz', g.inports.opt.process);
				Assert.equals('inPut', g.inports.opt.port);
			}));

			g.renameInport('inPut', 'opt');
		});

		// renaming an outport should emit an event
		moreTasks.add((e:Dynamic)->{
			
			g.once('renameOutport', new fbp.EventCallback((args:Array<Dynamic>)->{
				var oldName = args[0];
				var newName = args[1];

				Assert.equals('outPut', oldName);
				Assert.equals('foo', newName);
				Assert.isNull(g.outports.outPut);
				Assert.is(g.outports.foo, Dynamic);
				Assert.equals('Bar', g.outports.foo.process);
				Assert.equals('outPut', g.outports.foo.port);
			}));

			g.renameOutport('outPut', 'foo');
		});

		// removing a node should emit an event
		moreTasks.add((e)->{
			g.once('removeNode', new fbp.EventCallback((args)->{
				var node:Node = args[0];
				Assert.equals('Baz', node.id);
			}));

			g.removeNode('Baz');
		});

		// shouldn't have edges left behind
		moreTasks.add((e)->{
			var connections = 0;
			for(edge in g.edges){
				if (edge.from.node == 'Baz') {
					connections++;
				}

				if(edge.to.node == 'Baz') {
					connections++;
				}
			}

			Assert.equals(0, connections);
		});

		// shouldn't have IIPs left behind
		moreTasks.add((e)->{
			var connections = 0;

			for(edge in g.initializers){
				if(edge.to.node == 'Baz'){
					connections++;
				}
			}
			Assert.equals(0, connections);
		});

		// shouldn't be grouped
		moreTasks.add((e)->{
			var groups = 0;
			for(group in g.groups){
				if(group.nodes.indexOf('Baz') != -1){
					groups++;
				}
			}
			Assert.equals(0, groups);
		});

		// shouldn't affect other groups
		moreTasks.add((e)->{
			var otherGroup = g.groups[1];
			Assert.equals(2, otherGroup.nodes.length);
		});

		var d:Bool = moreTasks.dispatch(null);
		
	}
	

	public function teardown(){
		//g = null;
	}
}

/**
 * Journal test spec
 */
class JournalSpec {
 	public function new() {}

	public function setup(){

	}

	public function teardown(){

	}	 
}



class Main {
	public static function main(){
		var test = new Runner();
		test.addCase(new GraphSpec());
		test.addCase(new JournalSpec());
		
		Report.create(test);
		test.run();
	}
}
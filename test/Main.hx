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
			Assert.isNull(edge.from.index);
			Assert.equals(3, g.edges.length);
		}));

		 g.addEdgeIndex('Foo', 'out', null, 'Bar', 'in', 1);
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
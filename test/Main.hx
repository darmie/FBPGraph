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
		moreTests.add(shouldEmitAnEvent);
		moreTests.add(shouldBeInGraphListOfNodes);
		moreTests.add(shouldBeAccessibleViaGetter);
		moreTests.add(shouldHaveEmptyMetadata);
		moreTests.add(shouldBeAvailableInJSONExport);
		moreTests.add(shouldEmitEventWhenRemoved);

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

	public function shouldEmitAnEvent(e:Dynamic) {
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
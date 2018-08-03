package;

import utest.Assert;
import utest.Runner;
import utest.ui.Report;
import fbp.*;


/**
 * Graph test spec
 */
class GraphSpec {

	public var g:Graph;

	public function new() {}

	public function setup(){

	}

	public function testUnNamedGraphInstance() {
		g = new Graph();

		Assert.equals("", g.name);
	}

	public function testNamedGraphInstance() {
		g = null;
		g = new Graph('Foo bar', {caseSensitive: true});

		Assert.equals("Foo bar", g.name);
	}

	public function teardown(){
		g = null;
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
# FBP Graph Library for Haxe.

This library provides a Haxe implementation of Flow-Based Programming graphs. There are two areas covered:

* `Graph` - the actual graph library
* `Journal` -  journal system for keeping track of graph changes and undo history

See [this](https://github.com/flowbased/fbp-graph) for more information.


## Installation

`$ haxelib install FBPGraph`

## Usage

```hx
var source:String = sys.io.File.getContent('some/path.json');
var json:Graph.Json = haxe.Json.parse(source);
Graph.loadJSON(json, function(err:Dynamic, graph:Graph), {});
```

Sample JSON

```json
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
	}
```


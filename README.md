# FBP Graph Library for Haxe.

This library provides a Haxe implementation of Flow-Based Programming graphs. There are two areas covered:

* `Graph` - the actual graph library
* `Journal` -  journal system for keeping track of graph changes and undo history

See [this](https://github.com/flowbased/fbp-graph) for more information.

## Usage

```hx
var source:String = sys.io.File.getContent('some/path.json');
var json:Graph.Json = haxe.Json.parse(source);
Graph.loadJSON(json, function(err:Dynamic, graph:Graph), {});
```


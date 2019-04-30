// VB.cmd += -X -lccanjson
void main()
{
    var json = """
{
    "a": "hello",
    "b": "world",
    "c": 1,
    "d": 2,
    "e": 1.1,
    "f": 2.2,
    "g": null,
    "h": [1, 2, 3, "h1", "h2", "h3"],
    "i": {
            "i1": "hello",
            "i2": "world"
         }
}
""";

    print("validate result = %s\n", Ccan.Json.validate(json).to_string());
    var node = new Ccan.Json.Node.decode(json);
    print("stringify with default 4 space indent\n");
    print("%s\n", node.stringify());
    print("stringify with 2 space indent\n");
    print("%s\n", node.stringify("  "));
    print("stringify with no indent\n");
    print("%s\n", node.stringify(null));
    print("stringify with tab indent\n");
    print("%s\n", node.stringify("\t"));

    var node_null = new Ccan.Json.Node.null();
    var node_bool = new Ccan.Json.Node.bool(true);
    var node_string = new Ccan.Json.Node.string("hell world");
    var node_number = new Ccan.Json.Node.number(3);
    var node_array = new Ccan.Json.Node.array();
    var node_object = new Ccan.Json.Node.object();

    print("node_array: %s\n", node_array.stringify());
    print("node_object: %s\n", node_object.stringify());

    node_array.append_element(node_null);
    node_array.append_element(node_bool);
    node_array.prepend_element(node_string);
    node_array.prepend_element(node_number);
    print("node_array (after append prepend): %s\n", node_array.stringify());
    print("node_array[3] = %s\n", node_array.find_element(3).to_string());

    node_array.foreach_element((self, idx, ele, t) => {
        print("node_array[%u] = %s (%s)\n", idx, ele.to_string(), t.to_string());
    });

    node_null.remove_from_parent();
    node_bool.remove_from_parent();
    node_string.remove_from_parent();
    node_number.remove_from_parent();
    print("node_array (after remove): %s\n", node_array.stringify());


    node_object.append_member("null", node_null);
    node_object.append_member("bool", node_bool);
    node_object.prepend_member("string", node_string);
    node_object.prepend_member("number", node_number);
    print("node_object (after append preprend): %s\n", node_object.stringify());
    print("node_object.number = %s\n", node_object.find_member("number").to_string());

    node_object.foreach_member((self, key, member, t) => {
        print("node_object.%s = %s (%s)\n", key, member.to_string(), t.to_string());
    });
}

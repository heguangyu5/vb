void main()
{
    var json = """
{
	"a": "hello 你好",
	"b": "world \u4e16\u754c",
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

    // validate
    stdout.printf("validate result = %s\n", Ccan.Json.validate(json).to_string());

    // decode
    var node = new Ccan.Json.Node.decode(json);
    // encode
    stdout.printf("======encode======\n");
    stdout.printf("%s\n", node.encode());
    stdout.printf("encode with 4 space indent\n");
    stdout.printf("%s\n", node.encode("    "));
    // find
    stdout.printf("======find======\n");
    stdout.printf("h[3] = %s\n", node.find_member("h").find_element(3).get_string());
    stdout.printf("b = %s\n", node.find_member("b").get_string());
    // foreach
    stdout.printf("======foreach and free non-string node======\n");
    node.foreach_member((key, member, node) => {
        stdout.printf("%s:\n\t", key);
        if (member.is_null()) {
            stdout.printf("NULL");
            member.free();
        } else if (member.is_bool()) {
            stdout.printf("%s", member.get_bool().to_string());
            member.free();
        } else if (member.is_string()) {
            stdout.printf("%s", member.get_string());
        } else if (member.is_number()) {
            stdout.printf("%s\n", member.get_number().to_string());
            member.free();
        } else if (member.is_array()) {
            member.foreach_element((idx, element, member) => {
                stdout.printf("[%u]: %s\n\t", idx, element.to_string());
                if (!element.is_string()) {
                    element.free();
                }
            });
        } else if (member.is_object()) {
            member.foreach_member((key2, member2, member) => {
                stdout.printf("%s: %s\n\t", key2, member2.to_string());
                if (!member2.is_string()) {
                    member2.free();
                }
            });
        }
        stdout.printf("\n");
    });
    stdout.printf("node keep string: %s\n", node.encode("  "));
    // construction manipulation
    stdout.printf("======construction manipulation======\n");
    var node_array = new Ccan.Json.Node.array();
    var node_object = new Ccan.Json.Node.object();
    node_array.append_element_null();
    node_array.append_element_bool(true);
    node_array.prepend_element_string("hello world");
    node_array.prepend_element_number(3);
    unowned Ccan.Json.Node inner_array = node_array.append_element_array();
    inner_array.append_element_string("i am inner array");
    inner_array.append_element_bool(false);
    unowned Ccan.Json.Node inner_object = node_array.prepend_element_object();
    inner_object.prepend_member_string("str", "i am inner object");
    inner_object.prepend_member_bool("bool", false);
    stdout.printf("node_array.encode = %s\n", node_array.encode("  "));
    node_object.append_member_null("null");
    node_object.append_member_bool("bool", true);
    node_object.prepend_member_string("string", "hello world");
    node_object.prepend_member_number("number", 3);
    inner_array = node_object.prepend_member_array("inner_array");
    inner_array.prepend_element_string("i am inner array");
    inner_array.prepend_element_bool(false);
    inner_object = node_object.append_member_object("inner_object");
    inner_object.append_member_string("str", "i am inner object");
    inner_object.append_member_bool("bool", false);
    stdout.printf("node_object.encode = %s\n", node_object.encode("  "));
    inner_array.free();
    inner_object.free();
    stdout.printf("node_object.encode after free inner array and inner object = %s\n", node_object.encode("  "));
    unowned Ccan.Json.Node node_array_3 = node_array.find_element(3);
    node_object.append_member("node_array[3]", node_array_3);
    stdout.printf("node_object.encode = %s\n", node_object.encode("  "));
    stdout.printf("node_array.encode = %s\n", node_array.encode("  "));

    var node_array2 = new Ccan.Json.Node.array();
    node_array2.append_element_owned((owned)node_object);
    stdout.printf("node_array2.encode = %s\n", node_array2.encode("  "));

    var node_object2 = new Ccan.Json.Node.object();
    node_object2.append_member_owned("array", (owned)node_array);
    stdout.printf("node_object2.encode = %s\n", node_object2.encode("  "));
}

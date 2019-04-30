[CCode (cheader_filename="ccan/json/json.h", lower_case_cprefix="json_", cprefix="Json")]
namespace Ccan.Json
{
    [CCode (cprefix="JSON_", has_type_id=false)]
    enum Tag
    {
        NULL,
        BOOL,
        STRING,
        NUMBER,
        ARRAY,
        OBJECT
    }

    [Compact]
    [CCode (lower_case_cprefix="json_", free_function="json_delete")]
    class Node
    {
        [CCode (cname="json_decode")]
        public Node.decode(string json);

        [CCode (cname="json_mknull")]
        public Node.null();

        [CCode (cname="json_mkbool")]
        public Node.bool(bool b);

        [CCode (cname="json_mkstring")]
        public Node.string(string s);

        [CCode (cname="json_mknumber")]
        public Node.number(double n);

        [CCode (cname="json_mkarray")]
        public Node.array();

        [CCode (cname="json_mkobject")]
        public Node.object();

        public void append_element(Node n);
        public void prepend_element(Node n);

        public void append_member(string key, Node n);
        public void prepend_member(string key, Node n);

        public void remove_from_parent();

        public string stringify(string? space = "    ");

        public unowned Node? find_element(int index);
        public unowned Node? find_member(string key);

        public void foreach_element(ArrayForeach func);
        public void foreach_member(ObjectForeach func);

        public bool is_null();
        public bool is_bool();
        public bool is_string();
        public bool is_number();
        public bool is_array();
        public bool is_object();

        public bool get_bool();
        public unowned string get_string();
        public double get_number();

        public string to_string()
        {
            if (this.is_null()) {
                return "NULL";
            }
            if (this.is_bool()) {
                return this.get_bool().to_string();
            }
            if (this.is_string()) {
                return this.get_string();
            }
            if (this.is_number()) {
                return this.get_number().to_string();
            }
            if (this.is_array()) {
                return "[Array]";
            }
            if (this.is_object()) {
                return "[Object]";
            }
        }
    }

    bool validate(string json);

    delegate void ArrayForeach(Node array, uint index, Node element, Tag t);
    delegate void ObjectForeach(Node object, string key, Node member, Tag t);
}

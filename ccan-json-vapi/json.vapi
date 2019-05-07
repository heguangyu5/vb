[CCode (cheader_filename="ccan/json/json.h", lower_case_cprefix="json_", cprefix="Json")]
namespace Ccan.Json
{
    // validate
    public bool validate(string json);

    public delegate void ArrayForeach(uint index, Node element, Node array);
    public delegate void ObjectForeach(string key, Node member, Node object);

    [Compact]
    [CCode (lower_case_cprefix="json_", free_function="json_delete")]
    public class Node
    {
        // decode
        [CCode (cname="json_decode")]
        public Node.decode(string json);
        // encode
        public string encode(string? space = null);
        // find
        public unowned Node? find_element(int index);
        public unowned Node? find_member(string key);
        // foreach
        public void foreach_element(ArrayForeach func);
        public void foreach_member(ObjectForeach func);
        // type
        public bool is_null();
        public bool is_bool();
        public bool is_string();
        public bool is_number();
        public bool is_array();
        public bool is_object();
        // get value
        public bool get_bool();
        public unowned string get_string();
        public double get_number();
        // to_string
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
        // construction
        [CCode (cname="json_mkarray")]
        public Node.array();
        [CCode (cname="json_mkobject")]
        public Node.object();
        // manipulation
        public void append_element(owned Node n);
        public void append_element_null();
        public void append_element_bool(bool b);
        public void append_element_string(string str);
        public void append_element_number(double n);
        public void prepend_element(owned Node n);
        public void prepend_element_null();
        public void prepend_element_bool(bool b);
        public void prepend_element_string(string str);
        public void prepend_element_number(double n);
        public void append_member(string key, owned Node n);
        public void append_member_null(string key);
        public void append_member_bool(string key, bool b);
        public void append_member_string(string key, string str);
        public void append_member_number(string key, double n);
        public void prepend_member(string key, owned Node n);
        public void prepend_member_null(string key);
        public void prepend_member_bool(string key, bool b);
        public void prepend_member_string(string key, string str);
        public void prepend_member_number(string key, double n);
    }
}

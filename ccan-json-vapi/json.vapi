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
        // free
        [CCode (cname="json_delete")]
        public void free();
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
        // set value
        public void set_null();
        public void set_bool(bool b);
        public void set_string(string str);
        public void set_number(double n);
        public void set_array();
        public void set_object();
        public void set_key(string new_key);
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
        public unowned Node append_element(Node n);
        [CCode (cname="json_append_element")]
        public unowned Node append_element_owned(owned Node n);
        public unowned Node append_element_null();
        public unowned Node append_element_bool(bool b);
        public unowned Node append_element_string(string str);
        public unowned Node append_element_number(double n);
        public unowned Node append_element_array();
        public unowned Node append_element_object();
        public unowned Node prepend_element(Node n);
        [CCode (cname="json_prepend_element")]
        public unowned Node prepend_element_owned(owned Node n);
        public unowned Node prepend_element_null();
        public unowned Node prepend_element_bool(bool b);
        public unowned Node prepend_element_string(string str);
        public unowned Node prepend_element_number(double n);
        public unowned Node prepend_element_array();
        public unowned Node prepend_element_object();
        public unowned Node append_member(string key, Node n);
        [CCode (cname="json_append_member")]
        public unowned Node append_member_owned(string key, owned Node n);
        public unowned Node append_member_null(string key);
        public unowned Node append_member_bool(string key, bool b);
        public unowned Node append_member_string(string key, string str);
        public unowned Node append_member_number(string key, double n);
        public unowned Node append_member_array(string key);
        public unowned Node append_member_object(string key);
        public unowned Node prepend_member(string key, Node n);
        [CCode (cname="json_prepend_member")]
        public unowned Node prepend_member_owned(string key, owned Node n);
        public unowned Node prepend_member_null(string key);
        public unowned Node prepend_member_bool(string key, bool b);
        public unowned Node prepend_member_string(string key, string str);
        public unowned Node prepend_member_number(string key, double n);
        public unowned Node prepend_member_array(string key);
        public unowned Node prepend_member_object(string key);
    }
}

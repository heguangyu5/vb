[CCode (cprefix="LMDB_", cheader_filename="lmdb-wrapper.h")]
namespace LMDB
{
    [Compact]
    class Db
    {
        public Db(string path, size_t db_size_in_mb);
        [CCode (array_length_type="size_t")]
        public unowned uint8[] get(uint8[] key);
        public bool put(uint8[] key, uint8[] data);
    }

    uint8[] string_null_data(string s)
    {
        var len = s.length + 1;
        var null_data = new uint8[len];
        GLib.Memory.copy(null_data, s, len);
        return null_data;
    }
}

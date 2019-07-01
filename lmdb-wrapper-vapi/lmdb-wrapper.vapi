[CCode (cprefix="LMDB_", cheader_filename="lmdb-wrapper.h")]
namespace LMDB
{
    [Compact]
    class Db
    {
        public Db(string path, size_t db_size_in_mb);
        public void sync();
        [CCode (array_length_type="size_t")]
        public unowned uint8[]? get(uint8[] key);
        public bool put(uint8[] key, uint8[] data);
        public Stat stat();

        public unowned uint8[]? get_key_str(string key)
        {
            unowned uint8[] k = key.data;
            k.length++;
            return get(k);
        }

        public unowned string? get_str(string key)
        {
            unowned uint8[] k = key.data;
            k.length++;
            unowned uint8[] data = get(k);
            if (data == null) {
                return null;
            }
            return (string)data;
        }

        public bool put_str(string key, string data)
        {
            unowned uint8[] k = key.data;
            k.length++;
            unowned uint8[] d = data.data;
            d.length++;
            return put(k, d);
        }

        public Iterator iterator()
        {
            return new Iterator(this);
        }
    }

    [Compact]
    [CCode (free_function="free")]
    class Stat
    {
        public uint ms_psize;
        public uint ms_depth;
        public size_t ms_branch_pages;
        public size_t ms_leaf_pages;
        public size_t ms_overflow_pages;
        public size_t ms_entries;

        public size_t total_size()
        {
            return this.ms_psize * (this.ms_branch_pages + this.ms_leaf_pages + this.ms_overflow_pages);
        }

        public void print()
        {
            GLib.stdout.printf("== lmdb stat ==
psize          = %u
depth          = %u
branch_pages   = %lu
leaf_pages     = %lu
overflow_pages = %lu
entries        = %lu
total_size     = %lu
== lmdb stat end ==
",
    this.ms_psize,
    this.ms_depth,
    this.ms_branch_pages,
    this.ms_leaf_pages,
    this.ms_overflow_pages,
    this.ms_entries,
    this.total_size());
            GLib.stdout.flush();
        }
    }

    [Compact]
    class Item
    {
        public Item();
        [CCode (array_length_type="size_t")]
        public unowned uint8[] key();
        [CCode (array_length_type="size_t")]
        public unowned uint8[] data();
        public unowned string str_key()
        {
            unowned uint8[] k = key();
            return (string)k;
        }
        public unowned string str_data()
        {
            unowned uint8[] d = data();
            return (string)d;
        }
    }

    [Compact]
    class Iterator
    {
        public Iterator(Db db);
        public Item? next_value();
    }
}

void main()
{
    var db = new LMDB.Db("/tmp/", 10);
    db.put_str("key1", "val1");
    db.put_str("key2", "val2");
    db.put_str("key3", "val3");
    stdout.printf("key1 = %s\n", db.get_str("key1"));
    stdout.printf("key2 = %s\n", db.get_str("key2"));
    stdout.printf("key3 = %s\n", db.get_str("key3"));

    foreach (var item in db) {
        stdout.printf("%s = %s\n", item.str_key(), item.str_data());
    }
}

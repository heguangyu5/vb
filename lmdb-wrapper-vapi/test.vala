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

    unowned uint8[] data = db.get_key_str("key1");
    foreach (var i in data) {
        stdout.printf("%#x %c\n", i, i);
    }

    db.stat().print();

}

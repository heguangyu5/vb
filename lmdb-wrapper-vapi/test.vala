void main()
{
    var db = new LMDB.Db("/tmp/", 10);
    db.put("key1".data, LMDB.string_null_data("val1"));
    db.put("key2".data, LMDB.string_null_data("val2"));
    db.put("key3".data, LMDB.string_null_data("val3"));
    unowned uint8[] val1 = db.get("key1".data);
    unowned uint8[] val2 = db.get("key2".data);
    unowned uint8[] val3 = db.get("key3".data);
    stdout.printf("key1 = %s\n", (string)val1);
    stdout.printf("key2 = %s\n", (string)val2);
    stdout.printf("key3 = %s\n", (string)val3);
}

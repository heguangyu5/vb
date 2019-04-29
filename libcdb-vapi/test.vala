void main()
{
    var fd = Posix.open("./test.cdb", Posix.O_RDONLY);

    // Query Mode 1
    var cdb = Cdb.Cdb();
    cdb.init(fd);
    print("cdb.fd = %d\n", cdb.fileno());
    cdb.find("key1".data);
    print("datalen = %u, datapos %u, data = %.*s\n", cdb.datalen(), cdb.datapos(), cdb.datalen(), cdb.getdata());
    print("%s\n", cdb.find_str("key1"));
    print("%s\n", cdb.find_str0("key1"));

    // Query Mode 2
    uint dlen;
    Cdb.seek(fd, "key2".data, out dlen);
    var buf = new uint8[dlen + 1];
    Cdb.bread(fd, buf);
    buf[dlen] = 0;
    print("key2 = %s\n", (string)buf);
}

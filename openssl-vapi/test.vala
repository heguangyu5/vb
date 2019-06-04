void main()
{
    // BIO
    var b = new OpenSSL.BIO.file("/tmp/vala-test-bio", "w");
    b.write("hello world\n".data);

    b = new OpenSSL.BIO.file("/tmp/vala-test-bio", "r");
    var buf = new uint8[100];
    b.read(buf);

    stdout.printf((string)buf);
}

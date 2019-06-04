void main()
{
    // EVP
    var pkey = OpenSSL.rsa_keygen(2048);
    pkey.write_private_key("/tmp/privkey.pem");
    pkey.write_public_key("/tmp/pubkey.pem");

    string privkey;
    string pubkey;
    try {
        FileUtils.get_contents("/tmp/privkey.pem", out privkey);
        FileUtils.get_contents("/tmp/pubkey.pem", out pubkey);
        stdout.printf("===/tmp/privkey.pem===\n");
        stdout.printf(privkey);
        stdout.printf("===/tmp/pubkey.pem===\n");
        stdout.printf(pubkey);
    } catch (FileError e) {
        stdout.printf("%s\n", e.message);
    }
}

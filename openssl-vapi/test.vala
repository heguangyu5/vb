void main()
{
    var rsa = OpenSSL.RSA.keygen(2048);
    rsa.write_privkey("/tmp/privkey.pem");
    rsa.write_pubkey("/tmp/pubkey.pem");
    rsa.write_privkey_binary("/tmp/privkey.bin");
    rsa.write_pubkey_binary("/tmp/pubkey.bin");

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

    test_encrypt_decrypt(
        OpenSSL.RSA.read_privkey("/tmp/privkey.pem"),
        OpenSSL.RSA.read_pubkey("/tmp/pubkey.pem"),
        "Base64"
    );

    test_encrypt_decrypt(
        OpenSSL.RSA.read_privkey_binary("/tmp/privkey.bin"),
        OpenSSL.RSA.read_pubkey_binary("/tmp/pubkey.bin"),
        "Binary"
    );
}

void test_encrypt_decrypt(OpenSSL.RSA privkey, OpenSSL.RSA pubkey, string key_type)
{
    stdout.printf("===%s pubkey encrypt===\n", key_type);
    var encrypted = pubkey.pubkey_encrypt_base64("hello world".data);
    stdout.printf("%s\n", encrypted);
    stdout.printf("===%s privkey decrypt===\n", key_type);
    stdout.printf("%s\n", (string)privkey.privkey_decrypt_base64(encrypted));
    stdout.printf("===%s privkey encrypt===\n", key_type);
    encrypted = privkey.privkey_encrypt_base64("你好,世界!".data);
    stdout.printf("%s\n", encrypted);
    stdout.printf("===%s pubkey decrypt===\n", key_type);
    stdout.printf("%s\n", (string)pubkey.pubkey_decrypt_base64(encrypted));
}

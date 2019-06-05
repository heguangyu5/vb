void main()
{
    // EVP
    var pkey = OpenSSL.rsa_keygen(2048);
    pkey.write_privkey("/tmp/privkey.pem");
    pkey.write_pubkey("/tmp/pubkey.pem");

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

    // RSA
    var rsa_privkey = OpenSSL.RSA.read_privkey("/tmp/privkey.pem");
    var rsa_pubkey  = OpenSSL.RSA.read_pubkey("/tmp/pubkey.pem");
    stdout.printf("===pubkey encrypt===\n");
    var encrypted = rsa_pubkey.pubkey_encrypt_base64("hello world".data);
    stdout.printf("%s\n", encrypted);
    stdout.printf("===privkey decrypt===\n");
    stdout.printf("%s\n", (string)rsa_privkey.privkey_decrypt_base64(encrypted));
    stdout.printf("===privkey encrypt===\n");
    encrypted = rsa_privkey.privkey_encrypt_base64("你好,世界!".data);
    stdout.printf("%s\n", encrypted);
    stdout.printf("===pubkey decrypt===\n");
    stdout.printf("%s\n", (string)rsa_pubkey.pubkey_decrypt_base64(encrypted));
}

[CCode (cprefix="", lower_case_cprefix="")]
namespace OpenSSL
{

    [CCode (cname="pem_password_cb", has_target=false)]
    public delegate int pemPasswordCb(uint8[] buf, int rwflag, [CCode (array_length=false)]  uint8[] userdata);

    // EVP
    [Compact]
    [CCode (lower_case_cprefix="EVP_PKEY_", cheader_filename="openssl/evp.h,openssl/pem.h", free_function="EVP_PKEY_free")]
    public class EVP_PKEY
    {
        public EVP_PKEY();

        [CCode (cname="PEM_write_PrivateKey", instance_pos=1.1)]
        public int pem_write_privkey(GLib.FileStream out_stream = GLib.stdout, EVP_CIPHER? enc = null, uint8[]? kstr = null, pemPasswordCb? cb = null, [CCode (array_length=false)] uint8[]? u = null);
        [CCode (cname="PEM_write_PUBKEY", instance_pos=1.1)]
        public int pem_write_pubkey(GLib.FileStream out_stream = GLib.stdout);

        public bool write_privkey(string filename)
        {
            var stream = GLib.FileStream.open(filename, "w");
            return pem_write_privkey(stream) == 1;
        }

        public bool write_pubkey(string filename)
        {
            var stream = GLib.FileStream.open(filename, "w");
            return pem_write_pubkey(stream) == 1;
        }
    }

    [Compact]
    [CCode (lower_case_cprefix="EVP_PKEY_CTX_", cheader_filename="openssl/evp.h", free_function="EVP_PKEY_CTX_free")]
    public class EVP_PKEY_CTX
    {
        public EVP_PKEY_CTX.id(int id, ENGINE? e = null);

        public static EVP_PKEY_CTX rsa()
        {
            return new EVP_PKEY_CTX.id(6);
        }

        [CCode (cname="EVP_PKEY_keygen_init")]
        public int keygen_init();

        [CCode (cheader_filename="openssl/rsa.h")]
        public int set_rsa_keygen_bits(int bits);

        [CCode (cname="EVP_PKEY_keygen")]
        public int keygen(out EVP_PKEY pkey);
    }

    // RSA
    [Compact]
    [CCode (lower_case_cprefix="RSA_", cheader_filename="openssl/pem.h,openssl/rsa.h,openssl/engine.h", free_function="RSA_free")]
    public class RSA
    {
        public RSA();
        [CCode (cname="PEM_read_RSA_PUBKEY")]
        public RSA.pem_read_pubkey(GLib.FileStream in_stream, out RSA? x = null, pemPasswordCb? cb = null, [CCode (array_length=false)] uint8[]? u = null);
        [CCode (cname="PEM_read_RSAPrivateKey")]
        public RSA.pem_read_privkey(GLib.FileStream in_stream, out RSA? x = null, pemPasswordCb? cb = null, [CCode (array_length=false)] uint8[]? u = null);


        public static RSA read_pubkey(string filename)
        {
            return new RSA.pem_read_pubkey(GLib.FileStream.open(filename, "r"));
        }

        public static RSA read_privkey(string filename)
        {
            return new RSA.pem_read_privkey(GLib.FileStream.open(filename, "r"));
        }

        public int size();

        [CCode (instance_pos=2.1)]
        public int public_encrypt([CCode (array_length_pos=0.1)] uint8[] data, [CCode (array_length=false)] uint8[] crypted, int padding = 1);
        [CCode (instance_pos=2.1)]
        public int private_decrypt([CCode (array_length_pos=0.1)] uint8[] data, [CCode (array_length=false)] uint8[] decrypted, int padding = 1);
        [CCode (instance_pos=2.1)]
        public int private_encrypt([CCode (array_length_pos=0.1)] uint8[] data, [CCode (array_length=false)] uint8[] crypted, int padding = 1);
        [CCode (instance_pos=2.1)]
        public int public_decrypt([CCode (array_length_pos=0.1)] uint8[] data, [CCode (array_length=false)] uint8[] decrypted, int padding = 1);

        public uint8[]? pubkey_encrypt(uint8[] data)
        {
            var len = size();
            var crypted = new uint8[len];
            if (public_encrypt(data, crypted) != len) {
                return null;
            }
            return crypted;
        }

        public uint8[]? privkey_decrypt(uint8[] data)
        {
            var len = size();
            var decrypted = new uint8[len + 1];
            len = private_decrypt(data, decrypted);
            if (len == -1) {
                return null;
            }
            decrypted[len] = 0;
            decrypted.resize(len + 1);
            return decrypted;
        }

        public string? pubkey_encrypt_base64(uint8[] data)
        {
            var crypted = pubkey_encrypt(data);
            if (crypted == null) {
                return null;
            }
            return GLib.Base64.encode(crypted);
        }

        public uint8[]? privkey_decrypt_base64(string base64_str)
        {
            return privkey_decrypt(GLib.Base64.decode(base64_str));
        }

        public uint8[]? privkey_encrypt(uint8[] data)
        {
            var len = size();
            var crypted = new uint8[len];
            if (private_encrypt(data, crypted) != len) {
                return null;
            }
            return crypted;
        }

        public uint8[]? pubkey_decrypt(uint8[] data)
        {
            var len = size();
            var decrypted = new uint8[len + 1];
            len = public_decrypt(data, decrypted);
            if (len == -1) {
                return null;
            }
            decrypted[len] = 0;
            decrypted.resize(len + 1);
            return decrypted;
        }

        public string? privkey_encrypt_base64(uint8[] data)
        {
            var crypted = privkey_encrypt(data);
            if (crypted == null) {
                return null;
            }
            return GLib.Base64.encode(crypted);
        }

        public uint8[]? pubkey_decrypt_base64(string base64_str)
        {
            return pubkey_decrypt(GLib.Base64.decode(base64_str));
        }
    }

    // ENGINE
    [Compact]
    [CCode (lower_case_cprefix="ENGINE_", cheader_filename="openssl/engine.h", free_function="ENGINE_free")]
    public class ENGINE
    {
        public ENGINE();
    }

    [Compact]
    public class EVP_CIPHER
    {}

    public EVP_PKEY? rsa_keygen(int bits)
    {
        var ctx = EVP_PKEY_CTX.rsa();
        if (ctx == null) {
            return null;
        }
        if (ctx.keygen_init() <= 0) {
            return null;
        }
        if (ctx.set_rsa_keygen_bits(bits) <= 0) {
            return null;
        }
        EVP_PKEY pkey;
        if (ctx.keygen(out pkey) <= 0) {
            return null;
        }
        return pkey;
    }
}

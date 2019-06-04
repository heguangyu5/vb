[CCode (cprefix="", lower_case_cprefix="")]
namespace OpenSSL
{
    // EVP
    [Compact]
    [CCode (lower_case_cprefix="EVP_PKEY_", cheader_filename="openssl/evp.h,openssl/pem.h", free_function="EVP_PKEY_free")]
    public class EVP_PKEY
    {
        public EVP_PKEY();

        [CCode (cname="pem_password_cb", has_target=false)]
        public delegate int pemPasswordCb(uint8[] buf, int rwflag, [CCode (array_length=false)]  uint8[] userdata);

        [CCode (cname="PEM_write_PrivateKey", instance_pos=1.1)]
        public int pem_write_private_key(GLib.FileStream out_stream = GLib.stdout, EVP_CIPHER? enc = null, uint8[]? kstr = null, pemPasswordCb? cb = null, [CCode (array_length=false)] uint8[]? u = null);
        [CCode (cname="PEM_write_PUBKEY", instance_pos=1.1)]
        public int pem_write_public_key(GLib.FileStream out_stream = GLib.stdout);

        public bool write_private_key(string filename)
        {
            var stream = GLib.FileStream.open(filename, "w");
            return pem_write_private_key(stream) == 1;
        }

        public bool write_public_key(string filename)
        {
            var stream = GLib.FileStream.open(filename, "w");
            return pem_write_public_key(stream) == 1;
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

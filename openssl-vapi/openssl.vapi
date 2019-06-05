[CCode (cprefix="", lower_case_cprefix="", cheader_filename="openssl/pem.h,openssl/rsa.h,openssl/engine.h,openssl/bn.h")]
namespace OpenSSL
{

    [CCode (cname="pem_password_cb", has_target=false)]
    public delegate int pemPasswordCb(uint8[] buf, int rwflag, [CCode (array_length=false)]  uint8[] userdata);

    // RSA
    [Compact]
    [CCode (lower_case_cprefix="RSA_", free_function="RSA_free")]
    public class RSA
    {
        public const uint F4;

        public RSA();
        [CCode (cname="PEM_read_RSA_PUBKEY")]
        public RSA.pem_read_pubkey(GLib.FileStream in_stream, out RSA? x = null, pemPasswordCb? cb = null, [CCode (array_length=false)] uint8[]? u = null);
        [CCode (cname="PEM_read_RSAPrivateKey")]
        public RSA.pem_read_privkey(GLib.FileStream in_stream, out RSA? x = null, pemPasswordCb? cb = null, [CCode (array_length=false)] uint8[]? u = null);
        [CCode (cname="d2i_RSAPublicKey")]
        public RSA.d2i_pubkey(out RSA? a = null, uint8 **p, long length);
        [CCode (cname="d2i_RSAPrivateKey")]
        public RSA.d2i_privkey(out RSA? a = null, uint8 **p, long length);

        public static RSA? read_pubkey(string filename)
        {
            return new RSA.pem_read_pubkey(GLib.FileStream.open(filename, "r"));
        }

        public static RSA? read_privkey(string filename)
        {
            return new RSA.pem_read_privkey(GLib.FileStream.open(filename, "r"));
        }

        public static RSA? read_pubkey_binary(string filename)
        {
            uint8[] binary;
            try {
                GLib.FileUtils.get_data(filename, out binary);
            } catch (GLib.FileError e) {
                return null;
            }
            uint8 *p = binary;
            return new RSA.d2i_pubkey(null, &p, binary.length);
        }

        public static RSA? read_privkey_binary(string filename)
        {
            uint8[] binary;
            try {
                GLib.FileUtils.get_data(filename, out binary);
            } catch (GLib.FileError e) {
                return null;
            }
            uint8 *p = binary;
            return new RSA.d2i_privkey(null, &p, binary.length);
        }

        public static RSA? keygen(int bits)
        {
            var rsa = new RSA();
            var bn  = new BIGNUM();
            if (rsa == null || bn == null || bn.set_word(RSA.F4) == 0) {
                return null;
            }
            if (rsa.generate_key_ex(bits, bn) == 0) {
                return null;
            }
            return rsa;
        }

        public int size();
        public int generate_key_ex(int bits, BIGNUM e, BN_GENCB? cb = null);

        [CCode (cname="PEM_write_RSAPrivateKey", instance_pos=1.1)]
        public int pem_write_privkey(GLib.FileStream out_stream = GLib.stdout, EVP_CIPHER? enc = null, uint8[]? kstr = null, pemPasswordCb? cb = null, [CCode (array_length=false)] uint8[]? u = null);
        [CCode (cname="PEM_write_RSA_PUBKEY", instance_pos=1.1)]
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

        [CCode (cname="i2d_RSAPrivateKey")]
        public int i2d_privkey([CCode (array_length=false)] out uint8[] binary);
        [CCode (cname="i2d_RSAPublicKey")]
        public int i2d_pubkey([CCode (array_length=false)] out uint8[] binary);

        public bool write_privkey_binary(string filename)
        {
            uint8[] binary;
            int len = i2d_privkey(out binary);
            if (len <= 0) {
                return false;
            }
            binary.length = len;
            try {
                GLib.FileUtils.set_data(filename, binary);
                return true;
            } catch (GLib.FileError e) {
                return false;
            }
        }

        public bool write_pubkey_binary(string filename)
        {
            uint8[] binary;
            int len = i2d_pubkey(out binary);
            if (len <= 0) {
                return false;
            }
            binary.length = len;
            try {
                GLib.FileUtils.set_data(filename, binary);
                return true;
            } catch (GLib.FileError e) {
                return false;
            }
        }

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

    // BIGNUM
    [Compact]
    [CCode (lower_case_cprefix="BN_", free_function="BN_free")]
    public class BIGNUM
    {
        public BIGNUM();
        public int set_word(uint w);
    }

    // BN_GENCB
    [Compact]
    public class BN_GENCB
    {}
    // EVP_CIPHER
    [Compact]
    public class EVP_CIPHER
    {}
}

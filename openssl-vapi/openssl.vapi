[CCode (cprefix="", lower_case_cprefix="")]
namespace OpenSSL
{
    [Compact]
    [CCode (lower_case_cprefix="BIO_", cheader_filename="openssl/bio.h", free_function="BIO_vfree")]
    class BIO
    {
        public BIO.file(string filename, string mode);
        public int read(uint8[] buf);
        public int write(uint8[] buf);
    }
}

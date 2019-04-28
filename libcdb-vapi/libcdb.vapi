// @see http://www.corpit.ru/mjt/tinycdb.html
[CCode (cheader_filename="cdb.h")]
namespace Cdb
{
    // Query Mode 1
    [CCode (cname="struct cdb", cprefix="cdb_", destroy_function="cdb_free")]
    struct Cdb {
        public int init(int fd);
        public int fileno();

        public int find(uint8[] key);
        public uint datapos();
        public uint datalen();

        public int readdata([CCode (array_length=false)]uint8[] buf);
        public uint8* getdata();

        public string? findStr(string key)
        {
            var result = find(key.data);
            if (result <= 0) {
                return null;
            }
            var len = datalen();
            var val = new uint8[len + 1];
            result = readdata(val);
            if (result < 0) {
                return null;
            }
            val[len] = 0;
            return (string)val;
        }

        public string? findStr0(string key)
        {
            var result = find(key.data);
            if (result <= 0) {
                return null;
            }
            var p = getdata();
            if (p == null) {
                return null;
            }
            return (string)p;
        }
    }

    // Query Mode 2
    int seek(int fd, uint8[] key, out uint dlen);
    int bread(int fd, uint8[] buf);
}

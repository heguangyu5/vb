// VB.cmd += --pkg=mysql
// VB.cmd += -X -lmysqlclient
namespace Mysql
{
    public class Db
    {
        protected Database db = new Database();

        static construct
        {
            string[] args;
            library_init(args);
        }

        public Db(
            string username,
            string passwd,
            string dbname,
            uint port = 3306,
            string host = "localhost",
            string charset = "utf8"
        ) throws DbError
        {
            if (this.db == null) {
                throw new DbError.Init("new Database failed, insufficient memory!");
            }
            if (this.db.options(Option.SET_CHARSET_NAME, charset) != 0) {
                throw new DbError.Options("set charset failed: %s", this.db.error());
            }
            if (!this.db.real_connect(host, username, passwd, dbname, port)) {
                throw new DbError.Connect("connect failed: %s", this.db.error());
            }
        }

        public ulong insert(string table, ...) throws DbError
        {
            var list = va_list();
            var sb = new StringBuilder();
            var sb_vals = new StringBuilder();

            sb.append_printf("INSERT INTO `%s`(", table);
            do {
                unowned string col = list.arg<string>();
                if (col == null) {
                    break;
                }
                unowned string val = list.arg<string>();
                if (val == null) {
                    throw new DbError.ColValMismatch("insert: value required");
                }
                if (sb_vals.len > 0) {
                    sb.append_c(',');
                    sb_vals.append_c(',');
                }
                sb.append_printf("`%s`", col);
                sb_vals.append(this.quote(val));
            } while (true);
            sb.append_printf(") VALUES (%s)", sb_vals.str);

            return this.query(sb.str);
        }

        public string quote(string str)
        {
            var s = new uint8[str.length * 2 + 1];
            this.db.real_escape_string((string)s, str, str.length);
            return "'%s'".printf((string)s);
        }

        public ulong query(string sql) throws DbError
        {
            if (this.db.query(sql) != 0) {
                throw new DbError.Query("query \"%s\" failed: %s", sql, this.db.error());
            }
            return this.db.affected_rows();
        }

        public ulong last_insert_id()
        {
            return this.db.insert_id();
        }

        public ulong update(string table, string where, ...) throws DbError
        {
            var list = va_list();
            var sb = new StringBuilder();

            sb.append_printf("UPDATE `%s` SET ", table);
            bool need_comma = false;
            do {
                unowned string col = list.arg<string>();
                if (col == null) {
                    break;
                }
                unowned string val = list.arg<string>();
                if (val == null) {
                    throw new DbError.ColValMismatch("insert: value required");
                }
                if (need_comma) {
                    sb.append_c(',');
                }
                sb.append_printf("`%s` = %s", col, this.quote(val));
                if (!need_comma) {
                    need_comma = true;
                }
            } while (true);
            sb.append(" WHERE ");
            sb.append(where);

            return this.db.query(sb.str);
        }

        public ulong delete(string table, string where = "")
        {
            var s = "DELETE FROM `%s`".printf(table);
            if (where != "") {
                s += " WHERE " + where;
            }
            return this.db.query(s);
        }

        public DbStoreResult? store_result() throws DbError
        {
            Result* res = this.db.store_result();
            if (res == null) {
                unowned string errstr = this.db.error();
                if (errstr != "") {
                    throw new DbError.StoreResult("store_result failed: %s", errstr);
                }
                return null;
            }
            return new DbStoreResult(res);
        }

        public DbRow[] fetch_all(string sql) throws DbError
        {
            this.query(sql);
            var res = this.store_result();
            if (res == null) {
                return new DbRow[0];
            }
            return res.to_array();
        }

        public DbUseResult use_result() throws DbError
        {
            Result* res = this.db.use_result();
            if (res == null) {
                throw new DbError.UseResult("use_result failed: %s", this.db.error());
            }
            return new DbUseResult(res, this.db);
        }

        public DbRow? fetch_row(string sql) throws DbError
        {
            this.query(sql);
            return this.use_result().iterator().next_value();
        }

        public string? fetch_one(string sql) throws DbError
        {
            this.query(sql);
            var res = this.db.use_result();
            if (res == null) {
                throw new DbError.Query("fetch_one \"%s\" failed: %s", sql, this.db.error());
            }

            var row = res.fetch_row();
            if (row == null) {
                unowned string errstr = this.db.error();
                if (errstr != "") {
                    throw new DbError.Query("fetch_one \"%s\" failed: %s", sql, this.db.error());
                }
                return null;
            }

            return row[0];
        }

        public string[] fetch_col(string sql) throws DbError
        {
            string[] vals = {};

            this.query(sql);
            var res = this.db.store_result();
            if (res == null) {
                unowned string errstr = this.db.error();
                if (errstr != "") {
                    throw new DbError.Query("fetch_col \"%s\" failed: %s", sql, errstr);
                }
                return vals;
            }

            uint num_rows = res.num_rows();
            vals.resize((int)num_rows);
            for (uint i = 0; i < num_rows; i++) {
                vals[i] = res.fetch_row()[0];
            }
            return vals;
        }

        public void begin_transaction() throws DbError
        {
            this.query("START TRANSACTION");
        }

        public void commit() throws DbError
        {
            this.query("COMMIT");
        }

        public void roll_back() throws DbError
        {
            this.query("ROLLBACK");
        }
    }

    public class DbStoreResult
    {
        protected Result* res;
        protected uint num_rows;
        protected unowned Field[] fields;

        public DbStoreResult(Result* res)
        {
            this.res      = res;
            this.num_rows = res->num_rows();
            this.fields   = res->fetch_fields();
        }

        ~DbStoreResult()
        {
            delete this.res;
        }

        public uint size {
            get { return this.num_rows; }
        }

        public DbRow get(uint index)
        {
            this.res->data_seek(index);
            return new DbRow(this.fields, this.res->fetch_row());
        }

        public DbRow[] to_array()
        {
            var rows = new DbRow[this.num_rows];
            for (uint i = 0; i < this.num_rows; i++) {
                rows[i] = new DbRow(this.fields, this.res->fetch_row());
            }
            return rows;
        }
    }

    public class DbUseResult
    {
        protected Result *res;
        protected unowned Database db;

        public DbUseResult(Result *res, Database db)
        {
            this.res = res;
            this.db = db;
        }

        ~DbUseResult()
        {
            delete this.res;
        }

        public DbUseResultIterator iterator()
        {
            return new DbUseResultIterator(this.res, this.db);
        }
    }

    public class DbUseResultIterator
    {
        protected Result *res;
        protected unowned Database db;
        protected unowned Field[] fields;

        public DbUseResultIterator(Result *res, Database db)
        {
            this.res = res;
            this.db  = db;
            this.fields = res->fetch_fields();
        }

        public DbRow? next_value() throws DbError
        {
            var row = this.res->fetch_row();
            if (row == null) {
                unowned string errstr = this.db.error();
                if (errstr != "") {
                    throw new DbError.UseResult("fetch_row failed: %s", errstr);
                }
                return null;
            }

            return new DbRow(this.fields, row);
        }
    }

    [Compact]
    public class DbColumn
    {
        public string name;
        public string val;
    }

    public class DbRow
    {
        protected HashTable<string, string> row = new HashTable<string, string>(str_hash, str_equal);

        public DbRow(Field[] fields, string[] row)
        {
            for (int i = 0; i < fields.length; i++) {
                this.row.insert(fields[i].name, row[i]);
            }
        }

        public unowned string get(string col_name)
        {
            return this.row.get(col_name);
        }

        public void set(string key, string value)
        {
            this.row.set(key, value);
        }

        public DbRowIterator iterator()
        {
            return new DbRowIterator(this.row);
        }
    }

    public class DbRowIterator
    {
        public HashTableIter<string, string> iter;

        public DbRowIterator(HashTable<string, string> row)
        {
            this.iter = HashTableIter<string, string>(row);
        }

        public DbColumn? next_value()
        {
            var col = new DbColumn();
            if (this.iter.next(out col.name, out col.val)) {
                return col;
            }
            return null;
        }
    }

    public errordomain DbError
    {
        Init,
        Options,
        Connect,
        ColValMismatch,
        Query,
        StoreResult,
        UseResult
    }
}

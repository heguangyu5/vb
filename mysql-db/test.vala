struct SKV
{
    uint id;
    string k;
    string v;
}

void main()
{
    try {
        stdout.printf("connect\n");
        var db = new Mysql.Db("root", "123456", "test", 3306, "127.0.0.1");

        stdout.printf("create table\n");
        db.query("""
CREATE TABLE `kv` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `k` varchar(200) NOT NULL,
  `v` varchar(200) NOT NULL,
  primary key (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8
""");

        stdout.printf("insert\n");
        uint total_rows = 10;
        while (total_rows-- > 0) {
            db.insert("kv",
                "k", @"key-$total_rows",
                "v", @"value-$total_rows"
            );
            db.insert("kv",
                "k", @"键-$total_rows",
                "v", @"值-$total_rows"
            );
        }

        stdout.printf("fetch_all\n");
        foreach (Mysql.DbRow row in db.fetch_all("SELECT * FROM kv")) {
            foreach (Mysql.DbColumn col in row) {
                stdout.printf("%s => %s\t", col.name, col.val);
            }
            stdout.printf("\trow['k'] = %s\n", row["k"]);
        }

        stdout.printf("store_result foreach\n");
        db.query("SELECT * FROM kv");
        var res = db.store_result();
        if (res != null) {
            foreach (Mysql.DbRow row in res) {
                foreach (Mysql.DbColumn col in row) {
                    stdout.printf("%s => %s\t", col.name, col.val);
                }
                stdout.printf("\trow['k'] = %s\n", row["k"]);
            }
            stdout.printf("store_result to_array\n");
            foreach (Mysql.DbRow row in res.to_array(true)) {
                foreach (Mysql.DbColumn col in row) {
                    stdout.printf("%s => %s\t", col.name, col.val);
                }
                stdout.printf("\n");
            }
            stdout.printf("store_result foreach\n");
            var rows = new SKV[res.num_rows];
            res.foreach((i, row) => {
                stdout.printf("%s\n", string.joinv("\t", row));
                rows[i].id = int.parse(row[0]);
                rows[i].k  = row[1];
                rows[i].v  = row[2];
            }, true);
            foreach (unowned SKV row in rows) {
                stdout.printf("id = %u, k = %s, v = %s\n", row.id, row.k, row.v);
            }
        }

        stdout.printf("use_result foreach\n");
        db.query("SELECT * FROM kv");
        foreach (Mysql.DbRow row in db.use_result()) {
            foreach (Mysql.DbColumn col in row) {
                stdout.printf("%s => %s\t", col.name, col.val);
            }
            stdout.printf("\trow['k'] = %s\n", row["k"]);
        }

        stdout.printf("update\n");
        db.update("kv", "k = 'kk'", "v", "VVVVV");

        stdout.printf("fetch_row\n");
        var row = db.fetch_row("SELECT * FROM kv");
        if (row != null) {
            foreach (Mysql.DbColumn col in row) {
                stdout.printf("%s => %s\t", col.name, col.val);
            }
            stdout.printf("\n");
            row["k"] = "new kkkk";
            stdout.printf("row['k'] = %s\n", row["k"]);
        }

        stdout.printf("fetch_one\n");
        stdout.printf("count(*) = %s\n", db.fetch_one("SELECT COUNT(*) FROM kv"));

        stdout.printf("fetch_col\n");
        stdout.printf("%s\n", string.joinv(", ", db.fetch_col("SELECT k FROM kv")));

        stdout.printf("delete\n");
        db.delete("kv", "k = 'kk'");
        db.delete("kv");

        stdout.printf("drop table\n");
        db.query("DROP TABLE kv");
    } catch (Mysql.DbError e) {
        print("%d: %s\n", e.code, e.message);
    }
}

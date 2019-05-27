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
        db.insert(
            "kv",
            "k", "kk",
            "v", "vv"
        );
        db.insert(
            "kv",
            "k", "键",
            "v", "值"
        );

        stdout.printf("fetch_all\n");
        foreach (Mysql.DbRow row in db.fetch_all("SELECT * FROM kxv")) {
            foreach (Mysql.DbColumn col in row) {
                stdout.printf("%s => %s\t", col.name, col.val);
            }
            stdout.printf("\trow['k'] = %s\n", row["k"]);
        }

        stdout.printf("update\n");
        db.update("kv", "k = 'kk'", "v", "VVVVV");

        stdout.printf("fetch_row\n");
        var row = db.fetch_row("SELECT * FROM kv WHERE k = 'kk' LIMIT 1");
        if (row != null) {
            foreach (Mysql.DbColumn col in row) {
                stdout.printf("%s => %s\t", col.name, col.val);
            }
            stdout.printf("\n");
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

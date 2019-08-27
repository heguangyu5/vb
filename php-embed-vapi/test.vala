// VB.cmd += -X -L/usr/lib/oracle/19.3/client64/lib/
// VB.cmd += -X -lnnz19
// VB.cmd += -X -lclntsh

int php_say_hi()
{
    PHP.req_startup(false);
    stdout.printf("%s\n", (string)PHP.execute_return_string("'php_say_hi'"));
    PHP.req_shutdown(false);
    return 0;
}

void main(string[] args)
{
    PHP.startup();

    PHP.req_startup();
    PHP.execute("phpinfo();");
    PHP.req_shutdown();

    PHP.req_startup();
    PHP.execute("$exists = class_exists('A'); var_dump($exists); if (!$exists) { class A { public static $a; } } A::$a = 1; var_dump(A::$a);");
    PHP.req_shutdown();

    PHP.req_startup();
    PHP.execute("$exists = class_exists('A'); var_dump($exists); if (!$exists) { class A { public static $a; } } A::$a = 1; var_dump(A::$a);");
    PHP.execute("$exists = class_exists('A'); var_dump($exists); if ($exists) { A::$a = 2; var_dump(A::$a); }");
    stdout.printf("%s\n", (string)PHP.execute_return_string("'hello'"));
    stdout.printf("%s\n", (string)PHP.execute_return_string("get_include_path();"));
    PHP.req_shutdown();

    // test memory
    PHP.req_startup();
    var i = 1024;
    while (i-- > 0) {
        PHP.execute_return_string("str_repeat('a', 1024 * 1024)");
    }
    PHP.req_shutdown();

    // test threads
    var t = new Thread<int>(null, php_say_hi);
    t.join();
    t = new Thread<int>(null, php_say_hi);
    t.join();

    PHP.shutdown();
}

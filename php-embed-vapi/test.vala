int php_say_hi()
{
    PHP.req_startup();
    stdout.printf("%s\n", (string)PHP.execute_return_string("'php_say_hi'"));
    PHP.req_shutdown();
    return 0;
}

void main(string[] args)
{
    PHP.startup();

    PHP.req_startup();
    PHP.execute("$exists = class_exists('A'); var_dump($exists); if (!$exists) { class A { public static $a; } } A::$a = 1; var_dump(A::$a);");
    PHP.req_shutdown();

    PHP.req_startup();
    PHP.execute("$exists = class_exists('A'); var_dump($exists); if (!$exists) { class A { public static $a; } } A::$a = 1; var_dump(A::$a);");
    PHP.execute("$exists = class_exists('A'); var_dump($exists); if ($exists) { A::$a = 2; var_dump(A::$a); }");
    stdout.printf("%s\n", (string)PHP.execute_return_string("'hello'"));
    stdout.printf("%s\n", (string)PHP.execute_return_string("get_include_path();"));
    PHP.req_shutdown();

    var t = new Thread<int>(null, php_say_hi);
    t.join();

    // test memory
    PHP.req_startup();
    var i = 1024;
    while (i-- > 0) {
        PHP.execute_return_string("str_repeat('a', 1024 * 1024)");
    }
    PHP.req_shutdown();

    PHP.shutdown();
}

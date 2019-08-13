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
    PHP.req_shutdown();

    PHP.shutdown();
}

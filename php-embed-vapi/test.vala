int main(string[] args)
{
    if (args.length != 2) {
        stderr.printf("usage: %s x.php\n", args[0]);
        return 1;
    }

    stdout.printf("%s\n", (string)PHP.run_php(args[1]));

    return 0;
}

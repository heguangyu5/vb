// VB.cmd += --pkg=posix
class ValaBuild
{
    string[] cmd = new string[] {
        "valac",
        "-v",
        "--directory=./build",
        "--output=" + Path.get_basename(Environment.get_current_dir())
    };

    HashTable<string, bool> vapidir = new HashTable<string, bool>(str_hash, str_equal);
    HashTable<string, bool> VBcmd = new HashTable<string, bool>(str_hash, str_equal);

    public ValaBuild(string[] args)
    {
        var args_copy = args;
        if (args_copy.length == 1) {
            args_copy += "release";
        }

        if (args_copy[1][0] == '-') {
            this.cmd += "-X";
            this.cmd += "-O";
        }

        switch (args_copy[1]) {
            case "release":
                this.cmd += "-X";
                this.cmd += "-O";
                break;
            case "debug":
                this.cmd += "-g";
                this.cmd += "--save-temps";
                break;
            case "run":
                this.cmd = new string[] {
                    "vala",
                    "-v"
                };
                break;
            case "help":
                ValaBuild.show_help();
                Posix.exit(1);
                break;
            default:
                this.cmd += args_copy[1];
                break;
        }

        for (var i = 2; i < args_copy.length; i++) {
            this.cmd += args_copy[i];
        }
    }

    public void run()
    {
        this.append_source_files();

        stdout.printf("==exec==\n\n%s\n\n========\n\n\n", string.joinv(" \\\n  ", this.cmd));
        this.cmd += null;
        Posix.execvp(this.cmd[0], this.cmd);
    }

    protected void append_source_files(string path = "./")
    {
        Dir dir = null;
        try {
            dir = Dir.open(path);
        } catch (FileError e) {
            stderr.printf("%s\n", e.message);
            Posix.exit(1);
        }

        string? name = null;
        while ((name = dir.read_name()) != null) {
            if (FileUtils.test(name, FileTest.IS_DIR)) {
                this.append_source_files(path + name + "/");
            } else if (name.length > 5) {
                var ext = name[-4:name.length];
                if (ext == "vala") {
                    this.cmd += path + name;
                    this.parse_vb_cmd(path + name);
                } else if (ext == "vapi") {
                    if (!(path in vapidir)) {
                        vapidir[path] = true;
                        this.cmd += "--vapidir=" + path;
                    }
                    this.cmd += "--pkg=" + name[0:name.length-5];
                }
            }
        }
    }

    protected void parse_vb_cmd(string file)
    {
        string contents;
        try {
            FileUtils.get_contents(file, out contents);
        } catch (FileError e) {
            stderr.printf("%s\n", e.message);
            Posix.exit(1);
        }

        try {
            var regex = new Regex("""^ *// *VB\.cmd *\+= *([^ ].*)$""", RegexCompileFlags.MULTILINE);
            MatchInfo match;
            if (regex.match(contents, 0, out match)) {
                do {
                    var m = match.fetch(1);
                    if (!(m in VBcmd)) {
                        VBcmd[m] = true;
                        foreach (string s in m.split(" ")) {
                            this.cmd += s;
                        }
                    }
                } while (match.next());
            }
        } catch (RegexError e) {
            stderr.printf("%s\n", e.message);
            Posix.exit(1);
        }
    }


    public static void show_help()
    {
        stdout.printf("""
vala-build - an ultra simple build tool for vala.

Usage: (hard coded vala(c) options: -v --directory=./build --output=dir_name)
    vala-build [release] [extra-options]   (add -X -O)
    vala-build debug     [extra-options]   (add -g --save-temps)
    vala-build run       [extra-options]   (call vala, no extra options)
    vala-build help

Notes:
    you can add more extra options by comment line like `// VB.cmd += --pkg=mysql -X -lmysqlclient`.

""");
    }
}

void main(string[] args)
{
    new ValaBuild(args).run();
}

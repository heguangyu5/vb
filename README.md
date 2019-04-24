vala-build - an ultra simple build tool for vala.

    Usage: (hard coded vala(c) options: -v --directory=./build --output=dir_name)
        vala-build [release]    (add -X -O)
        vala-build debug        (add -g --save-temps)
        vala-build run          (call vala, no extra options)
        vala-build help

Notes:
    you can add more custom options by comment line like `// VB.cmd += --pkg=mysql -X -lmysqlclient`.

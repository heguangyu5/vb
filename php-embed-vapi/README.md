# php-embed

    ./configure --enable-embed=static --enable-maintainer-zts --with-pdo-mysql --enable-dba --disable-cgi --disable-phar --disable-session
    # libphp7.a needs libxml2.a,libresolv.a,libz.a
    
    @see Extending\_and\_embedding_php Chapter 19. Setting Up a Host Environment

# how to install oci8 extension

1. download oracle instant client, https://www.oracle.com/database/technologies/instant-client/linux-x86-64-downloads.html, download basic rpm and devel rpm.
2. use `alien -d` convert to deb
3. `dpkg -i` install
4. `ln -s /usr/include/oracle/xx.x/client64 /usr/lib/oracle/xx.x/client64/lib/include`
5. php configure add option `--with-oci8=instantclient,/usr/lib/oracle/xx.x/client64/lib --with-pdo-oci=instantclient,/usr/lib/oracle/xx.x/client64/lib`

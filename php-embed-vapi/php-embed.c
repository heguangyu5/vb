#include <stdlib.h>
#include <string.h>
#include <sapi/embed/php_embed.h>

char *run_php(char *filename, size_t *len)
{
    int argc = 1;
    char *argv[1] = {filename};
    char *ret = NULL;
    PHP_EMBED_START_BLOCK(argc, argv)
        char *include;
        zval retval;
        spprintf(&include, 0, "include '%s';", filename);
        zend_eval_string(include, &retval, "run_php" TSRMLS_CC);
        efree(include);
        *len = Z_STRLEN(retval);
        ret = malloc(*len + 1);
        memcpy(ret, Z_STRVAL(retval), *len);
        ret[*len] = 0;
    PHP_EMBED_END_BLOCK()

    return ret;
}

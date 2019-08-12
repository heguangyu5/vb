#include <stdlib.h>
#include <string.h>
#include <sapi/embed/php_embed.h>

char *run_php(char *code, size_t *len)
{
    char *ret = NULL;
    PHP_EMBED_START_BLOCK(0, NULL)
        zval retval;
        zend_eval_string(code, &retval, "run_php" TSRMLS_CC);
        if (Z_TYPE(retval) == IS_STRING) {
            *len = Z_STRLEN(retval);
            ret = malloc(*len + 1);
            memcpy(ret, Z_STRVAL(retval), *len);
            ret[*len] = 0;
        }
    PHP_EMBED_END_BLOCK()

    return ret;
}

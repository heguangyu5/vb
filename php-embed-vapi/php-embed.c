#include <sapi/embed/php_embed.h>
#include <ext/standard/php_standard.h>
#include "php-embed.h"

#define HARDCODED_INI "html_errors=0\nregister_argc_argv=0\nimplicit_flush=1\noutput_buffering=0\nmax_execution_time=0\nmax_input_time=-1\n\0"

ZEND_BEGIN_ARG_INFO(arginfo_dl, 0)
    ZEND_ARG_INFO(0, extension_filename)
ZEND_END_ARG_INFO()

static const zend_function_entry additional_functions[] = {
    ZEND_FE(dl, arginfo_dl)
    {NULL, NULL, NULL}
};

bool php_startup()
{
    signal(SIGPIPE, SIG_IGN);

    tsrm_startup(1, 1, 0, NULL);
    (void)ts_resource(0);
    ZEND_TSRMLS_CACHE_UPDATE();

    zend_signal_startup();

    sapi_startup(&php_embed_module);

    php_embed_module.ini_entries = malloc(sizeof(HARDCODED_INI));
    memcpy(php_embed_module.ini_entries, HARDCODED_INI, sizeof(HARDCODED_INI));

    php_embed_module.additional_functions = additional_functions;

    if (php_embed_module.startup(&php_embed_module) == -1) {
        return false;
    }

    SG(options) |= SAPI_OPTION_NO_CHDIR;

    return true;
}

void php_shutdown()
{
    php_module_shutdown();
    sapi_shutdown();
    tsrm_shutdown();
    free(php_embed_module.ini_entries);
    php_embed_module.ini_entries = NULL;
}

bool php_req_startup()
{
    if (php_request_startup() == -1) {
        return false;
    }

    SG(headers_sent) = 1;
    SG(request_info).no_headers = 1;
    php_register_variable("PHP_SELF", "-", NULL);

    return true;
}

void php_req_shutdown()
{
    php_request_shutdown(NULL);
}

void php_execute(char *code)
{
    zend_first_try {
        zend_eval_string(code, NULL, "php_embed_vala" TSRMLS_CC);
    } zend_end_try();
}

char *php_execute_return_string(char *code, size_t *len)
{
    char *ret = NULL;

    zend_first_try {
        zval retval;
        zend_eval_string(code, &retval, "php_embed_vala" TSRMLS_CC);
        if (Z_TYPE(retval) == IS_STRING) {
            *len = Z_STRLEN(retval);
            ret = malloc(*len + 1);
            memcpy(ret, Z_STRVAL(retval), *len);
            ret[*len] = 0;
        } else {
            *len = 0;
        }
    } zend_end_try();

    return ret;
}

#ifndef _PHP_EMBED_VALA_
#define _PHP_EMBED_VALA_

#include <stdbool.h>

bool php_startup();
void php_shutdown();

bool php_req_startup();
void php_req_shutdown();

void php_execute(char *code);
char *php_execute_return_string(char *code, size_t *len);

#endif

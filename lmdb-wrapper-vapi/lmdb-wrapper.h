#ifndef LMDB_WRAPPER
#define LMDB_WRAPPER

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>

typedef struct LMDB_Db LMDB_Db;

LMDB_Db *lmdb_db_new(const char *path, size_t db_size_in_mb);
void lmdb_db_free(LMDB_Db *db);
uint8_t *lmdb_db_get(LMDB_Db *db, uint8_t *key, size_t key_len, size_t *data_len);
bool lmdb_db_put(LMDB_Db *db, uint8_t *key, size_t key_len, uint8_t *data, size_t data_len);

#endif

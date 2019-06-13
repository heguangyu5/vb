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

typedef struct LMDB_Item LMDB_Item;
LMDB_Item *lmdb_item_new();
void lmdb_item_free(LMDB_Item *item);
uint8_t *lmdb_item_key(LMDB_Item *item, size_t *key_len);
uint8_t *lmdb_item_data(LMDB_Item *item, size_t *data_len);

typedef struct LMDB_Iterator LMDB_Iterator;
LMDB_Iterator *lmdb_iterator_new(LMDB_Db *db);
void lmdb_iterator_free(LMDB_Iterator *iterator);
LMDB_Item *lmdb_iterator_next_value(LMDB_Iterator *iterator);

#endif

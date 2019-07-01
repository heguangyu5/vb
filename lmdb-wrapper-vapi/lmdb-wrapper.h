#ifndef LMDB_WRAPPER
#define LMDB_WRAPPER

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>

typedef struct LMDB_Db LMDB_Db;

LMDB_Db *lmdb_db_new(const char *path, size_t db_size_in_mb);
void lmdb_db_free(LMDB_Db *db);
void lmdb_db_sync(LMDB_Db *db);
uint8_t *lmdb_db_get(LMDB_Db *db, uint8_t *key, size_t key_len, size_t *data_len);
bool lmdb_db_put(LMDB_Db *db, uint8_t *key, size_t key_len, uint8_t *data, size_t data_len);

typedef struct LMDB_Stat {
	unsigned int	ms_psize;			/**< Size of a database page.
											This is currently the same for all databases. */
	unsigned int	ms_depth;			/**< Depth (height) of the B-tree */
	size_t		ms_branch_pages;	/**< Number of internal (non-leaf) pages */
	size_t		ms_leaf_pages;		/**< Number of leaf pages */
	size_t		ms_overflow_pages;	/**< Number of overflow pages */
	size_t		ms_entries;			/**< Number of data items */
} LMDB_Stat;
LMDB_Stat *lmdb_db_stat(LMDB_Db *db);

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

#include "lmdb-wrapper.h"
#include <stdlib.h>
#include "lmdb.h"

struct LMDB_Db
{
    MDB_env *env;
    MDB_dbi dbi;
};

LMDB_Db *lmdb_db_new(const char *path, size_t db_size_in_mb)
{
    LMDB_Db *db = calloc(1, sizeof(LMDB_Db));
    if (db == NULL) {
        exit(1);
    }

    MDB_txn *txn;
    if (   mdb_env_create(&db->env) != MDB_SUCCESS
        || mdb_env_set_mapsize(db->env, db_size_in_mb * 1024 * 1024) != MDB_SUCCESS
        || mdb_env_open(db->env, path, MDB_MAPASYNC | MDB_WRITEMAP, 0640) != MDB_SUCCESS
        || mdb_txn_begin(db->env, NULL, 0, &txn) != MDB_SUCCESS
        || mdb_dbi_open(txn, NULL, 0, &db->dbi) != MDB_SUCCESS
        || mdb_txn_commit(txn) != MDB_SUCCESS
    ) {
        exit(1);
    }

    return db;
}

void lmdb_db_free(LMDB_Db *db)
{
    mdb_env_sync(db->env, 1);
    mdb_dbi_close(db->env, db->dbi);
    mdb_env_close(db->env);
    free(db);
}

void lmdb_db_sync(LMDB_Db *db)
{
    mdb_env_sync(db->env, 1);
}

uint8_t *lmdb_db_get(LMDB_Db *db, uint8_t *key, size_t key_len, size_t *data_len)
{
    MDB_txn *txn;
    if (mdb_txn_begin(db->env, NULL, MDB_RDONLY, &txn) != MDB_SUCCESS) {
        return NULL;
    }

    MDB_val k = {key_len, key};
    MDB_val d;
    if (mdb_get(txn, db->dbi, &k, &d) != MDB_SUCCESS) {
        mdb_txn_abort(txn);
        return NULL;
    }

    mdb_txn_commit(txn);

    *data_len = d.mv_size;
    return d.mv_data;
}

bool lmdb_db_put(LMDB_Db *db, uint8_t *key, size_t key_len, uint8_t *data, size_t data_len)
{
    MDB_txn *txn;
    if (mdb_txn_begin(db->env, NULL, 0, &txn) != MDB_SUCCESS) {
        return false;
    }

    MDB_val k = {key_len, key};
    MDB_val d = {data_len, data};
    if (mdb_put(txn, db->dbi, &k, &d, 0) != MDB_SUCCESS) {
        mdb_txn_abort(txn);
        return false;
    }

    return mdb_txn_commit(txn) == MDB_SUCCESS;
}

LMDB_Stat *lmdb_db_stat(LMDB_Db *db)
{
    LMDB_Stat *stat = malloc(sizeof(LMDB_Stat));
    mdb_env_stat(db->env, (MDB_stat *)stat);
    return stat;
}

struct LMDB_Item
{
    MDB_val k;
    MDB_val d;
};

LMDB_Item *lmdb_item_new()
{
    return calloc(1, sizeof(LMDB_Item));
}

void lmdb_item_free(LMDB_Item *item)
{
    free(item);
}

uint8_t *lmdb_item_key(LMDB_Item *item, size_t *key_len)
{
    *key_len = item->k.mv_size;
    return item->k.mv_data;
}

uint8_t *lmdb_item_data(LMDB_Item *item, size_t *data_len)
{
    *data_len = item->d.mv_size;
    return item->d.mv_data;
}

struct LMDB_Iterator
{
    MDB_txn *txn;
    MDB_cursor *cursor;
    MDB_cursor_op op;
};

LMDB_Iterator *lmdb_iterator_new(LMDB_Db *db)
{
    LMDB_Iterator *iterator = calloc(1, sizeof(LMDB_Iterator));
    if (iterator == NULL) {
        return NULL;
    }

    if (mdb_txn_begin(db->env, NULL, MDB_RDONLY, &iterator->txn) != MDB_SUCCESS) {
        free(iterator);
        return NULL;
    }
    if (mdb_cursor_open(iterator->txn, db->dbi, &iterator->cursor) != MDB_SUCCESS) {
        mdb_txn_abort(iterator->txn);
        free(iterator);
        return NULL;
    }

    iterator->op = MDB_FIRST;
    return iterator;
}

void lmdb_iterator_free(LMDB_Iterator *iterator)
{
    if (iterator->cursor != NULL) {
        mdb_cursor_close(iterator->cursor);
    }
    if (iterator->txn != NULL) {
        mdb_txn_abort(iterator->txn);
    }
    free(iterator);
}

LMDB_Item *lmdb_iterator_next_value(LMDB_Iterator *iterator)
{
    LMDB_Item *item = lmdb_item_new();
    if (item == NULL) {
        goto end_iterator;
    }

    if (mdb_cursor_get(iterator->cursor, &item->k, &item->d, iterator->op) != MDB_SUCCESS) {
        free(item);
        goto end_iterator;
    }

    if (iterator->op != MDB_NEXT) {
        iterator->op = MDB_NEXT;
    }
    return item;

end_iterator:
    mdb_cursor_close(iterator->cursor);
    mdb_txn_abort(iterator->txn);
    iterator->cursor = NULL;
    iterator->txn = NULL;
    return NULL;
}

#include "lmdb-wrapper.h"
#include <stdlib.h>
#include <lmdb.h>

struct LMDB_Db
{
    MDB_env *env;
    MDB_dbi dbi;
};

LMDB_Db *lmdb_db_new(const char *path, size_t db_size_in_mb)
{
    LMDB_Db *db = calloc(1, sizeof(LMDB_Db));

    MDB_txn *txn;
    if (   mdb_env_create(&db->env) != MDB_SUCCESS
        || mdb_env_set_mapsize(db->env, db_size_in_mb * 1024 * 1024) != MDB_SUCCESS
        || mdb_env_open(db->env, path, 0, 0640) != MDB_SUCCESS
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
    mdb_dbi_close(db->env, db->dbi);
    mdb_env_close(db->env);
    free(db);
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

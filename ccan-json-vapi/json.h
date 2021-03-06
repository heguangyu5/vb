/*
  Copyright (C) 2011 Joseph A. Adams (joeyadams3.14159@gmail.com)
  All rights reserved.

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in
  all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
  THE SOFTWARE.
*/

#ifndef CCAN_JSON_H
#define CCAN_JSON_H
#include <stdbool.h>
#include <stddef.h>

typedef struct JsonNode JsonNode;

/*** Encoding, decoding, and validation ***/

JsonNode   *json_decode     (const char *json);
char       *json_encode     (const JsonNode *node, const char *space);
void        json_delete     (JsonNode *node);
bool        json_validate   (const char *json);

/*** Lookup and traversal ***/

JsonNode   *json_find_element   (const JsonNode *array, int index);
JsonNode   *json_find_member    (const JsonNode *object, const char *key);
JsonNode   *json_first_child    (const JsonNode *node);

bool json_is_null(const JsonNode *node);
bool json_is_bool(const JsonNode *node);
bool json_is_string(const JsonNode *node);
bool json_is_number(const JsonNode *node);
bool json_is_array(const JsonNode *node);
bool json_is_object(const JsonNode *node);

bool json_get_bool(const JsonNode *node);
char *json_get_string(const JsonNode *node);
double json_get_number(const JsonNode *node);
char *json_get_key(const JsonNode *node);

void json_set_null(JsonNode *node);
void json_set_bool(JsonNode *node, bool b);
void json_set_string(JsonNode *node, const char *str);
void json_set_number(JsonNode *node, double n);
void json_set_array(JsonNode *node);
void json_set_object(JsonNode *node);
void json_set_key(JsonNode *node, const char *new_key);

/*** Construction and manipulation ***/

JsonNode *json_mkarray(void);
JsonNode *json_mkobject(void);

JsonNode *json_append_element(JsonNode *array, JsonNode *element);
JsonNode *json_append_element_null(JsonNode *array);
JsonNode *json_append_element_bool(JsonNode *array, bool b);
JsonNode *json_append_element_string(JsonNode *array, const char *str);
JsonNode *json_append_element_number(JsonNode *array, double n);
JsonNode *json_append_element_array(JsonNode *array);
JsonNode *json_append_element_object(JsonNode *array);
JsonNode *json_prepend_element(JsonNode *array, JsonNode *element);
JsonNode *json_prepend_element_null(JsonNode *array);
JsonNode *json_prepend_element_bool(JsonNode *array, bool b);
JsonNode *json_prepend_element_string(JsonNode *array, const char *str);
JsonNode *json_prepend_element_number(JsonNode *array, double n);
JsonNode *json_prepend_element_array(JsonNode *array);
JsonNode *json_prepend_element_object(JsonNode *array);
JsonNode *json_append_member(JsonNode *object, JsonNode *value, const char *key);
JsonNode *json_append_member_null(JsonNode *object, const char *key);
JsonNode *json_append_member_bool(JsonNode *object, const char *key, bool b);
JsonNode *json_append_member_string(JsonNode *object, const char *key, const char *str);
JsonNode *json_append_member_number(JsonNode *object, const char *key, double n);
JsonNode *json_append_member_array(JsonNode *object, const char *key);
JsonNode *json_append_member_object(JsonNode *object, const char *key);
JsonNode *json_prepend_member(JsonNode *object, JsonNode *value, const char *key);
JsonNode *json_prepend_member_null(JsonNode *object, const char *key);
JsonNode *json_prepend_member_bool(JsonNode *object, const char *key, bool b);
JsonNode *json_prepend_member_string(JsonNode *object, const char *key, const char *str);
JsonNode *json_prepend_member_number(JsonNode *object, const char *key, double n);
JsonNode *json_prepend_member_array(JsonNode *object, const char *key);
JsonNode *json_prepend_member_object(JsonNode *object, const char *key);

/*** Iterator ***/
typedef struct JsonIterator JsonIterator;
JsonIterator *json_iterator_new(JsonNode *node);
void json_iterator_delete(JsonIterator *iterator);
JsonNode *json_iterator_next_value(JsonIterator *iterator);

#endif

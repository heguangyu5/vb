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

JsonNode   *json_find_element   (JsonNode *array, int index);
JsonNode   *json_find_member    (JsonNode *object, const char *key);

typedef void (*JsonArrayForeach)(unsigned int index, JsonNode *element, JsonNode *self, void *userdata);
typedef void (*JsonObjectForeach)(const char *key, JsonNode *member, JsonNode *self, void *userdata);
void json_foreach_element(JsonNode *array, JsonArrayForeach func, void *userdata);
void json_foreach_member(JsonNode *object, JsonObjectForeach func, void *userdata);

bool json_is_null(const JsonNode *node);
bool json_is_bool(const JsonNode *node);
bool json_is_string(const JsonNode *node);
bool json_is_number(const JsonNode *node);
bool json_is_array(const JsonNode *node);
bool json_is_object(const JsonNode *node);

bool json_get_bool(const JsonNode *node);
char *json_get_string(const JsonNode *node);
double json_get_number(const JsonNode *node);

/*** Construction and manipulation ***/

JsonNode *json_mkarray(void);
JsonNode *json_mkobject(void);

void json_append_element(JsonNode *array, JsonNode *element);
JsonNode *json_append_element_null(JsonNode *array);
JsonNode *json_append_element_bool(JsonNode *array, bool b);
JsonNode *json_append_element_string(JsonNode *array, const char *str);
JsonNode *json_append_element_number(JsonNode *array, double n);
JsonNode *json_append_element_array(JsonNode *array);
JsonNode *json_append_element_object(JsonNode *array);
void json_prepend_element(JsonNode *array, JsonNode *element);
JsonNode *json_prepend_element_null(JsonNode *array);
JsonNode *json_prepend_element_bool(JsonNode *array, bool b);
JsonNode *json_prepend_element_string(JsonNode *array, const char *str);
JsonNode *json_prepend_element_number(JsonNode *array, double n);
JsonNode *json_prepend_element_array(JsonNode *array);
JsonNode *json_prepend_element_object(JsonNode *array);
void json_append_member(JsonNode *object, const char *key, JsonNode *value);
JsonNode *json_append_member_null(JsonNode *object, const char *key);
JsonNode *json_append_member_bool(JsonNode *object, const char *key, bool b);
JsonNode *json_append_member_string(JsonNode *object, const char *key, const char *str);
JsonNode *json_append_member_number(JsonNode *object, const char *key, double n);
JsonNode *json_append_member_array(JsonNode *object, const char *key);
JsonNode *json_append_member_object(JsonNode *object, const char *key);
void json_prepend_member(JsonNode *object, const char *key, JsonNode *value);
JsonNode *json_prepend_member_null(JsonNode *object, const char *key);
JsonNode *json_prepend_member_bool(JsonNode *object, const char *key, bool b);
JsonNode *json_prepend_member_string(JsonNode *object, const char *key, const char *str);
JsonNode *json_prepend_member_number(JsonNode *object, const char *key, double n);
JsonNode *json_prepend_member_array(JsonNode *object, const char *key);
JsonNode *json_prepend_member_object(JsonNode *object, const char *key);

/*** Debugging ***/

/*
 * Look for structure and encoding problems in a JsonNode or its descendents.
 *
 * If a problem is detected, return false, writing a description of the problem
 * to errmsg (unless errmsg is NULL).
 */
bool json_check(const JsonNode *node, char errmsg[256]);

#endif

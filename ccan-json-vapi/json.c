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

#include "json.h"

#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef enum {
	JSON_NULL,
	JSON_BOOL,
	JSON_STRING,
	JSON_NUMBER,
	JSON_ARRAY,
	JSON_OBJECT,
} JsonTag;

struct JsonNode
{
	/* only if parent is an object or array (NULL otherwise) */
	JsonNode *parent;
	JsonNode *prev, *next;

	/* only if parent is an object (NULL otherwise) */
	char *key; /* Must be valid UTF-8. */

	JsonTag tag;
	union {
		/* JSON_BOOL */
		bool bool_;

		/* JSON_STRING */
		char *string_; /* Must be valid UTF-8. */

		/* JSON_NUMBER */
		double number_;

		/* JSON_ARRAY */
		/* JSON_OBJECT */
		struct {
			JsonNode *head, *tail;
		} children;
	};
};

#define json_foreach(i, object_or_array)            \
	for ((i) = json_first_child(object_or_array);   \
		 (i) != NULL;                               \
		 (i) = (i)->next)

#define out_of_memory() do {                    \
		fprintf(stderr, "Out of memory.\n");    \
		exit(EXIT_FAILURE);                     \
	} while (0)

/* Sadly, strdup is not portable. */
static char *json_strdup(const char *str)
{
	char *ret = (char*) malloc(strlen(str) + 1);
	if (ret == NULL)
		out_of_memory();
	strcpy(ret, str);
	return ret;
}

/* String buffer */

typedef struct
{
	char *cur;
	char *end;
	char *start;
} SB;

static void sb_init(SB *sb)
{
	sb->start = (char*) malloc(17);
	if (sb->start == NULL)
		out_of_memory();
	sb->cur = sb->start;
	sb->end = sb->start + 16;
}

/* sb and need may be evaluated multiple times. */
#define sb_need(sb, need) do {                  \
		if ((sb)->end - (sb)->cur < (need))     \
			sb_grow(sb, need);                  \
	} while (0)

static void sb_grow(SB *sb, int need)
{
	size_t length = sb->cur - sb->start;
	size_t alloc = sb->end - sb->start;

	do {
		alloc *= 2;
	} while (alloc < length + need);

	sb->start = (char*) realloc(sb->start, alloc + 1);
	if (sb->start == NULL)
		out_of_memory();
	sb->cur = sb->start + length;
	sb->end = sb->start + alloc;
}

static void sb_put(SB *sb, const char *bytes, int count)
{
	sb_need(sb, count);
	memcpy(sb->cur, bytes, count);
	sb->cur += count;
}

#define sb_putc(sb, c) do {         \
		if ((sb)->cur >= (sb)->end) \
			sb_grow(sb, 1);         \
		*(sb)->cur++ = (c);         \
	} while (0)

static void sb_puts(SB *sb, const char *str)
{
	sb_put(sb, str, strlen(str));
}

static char *sb_finish(SB *sb)
{
	*sb->cur = 0;
	assert(sb->start <= sb->cur && strlen(sb->start) == (size_t)(sb->cur - sb->start));
	return sb->start;
}

static void sb_free(SB *sb)
{
	free(sb->start);
}

/*
 * Unicode helper functions
 *
 * These are taken from the ccan/charset module and customized a bit.
 * Putting them here means the compiler can (choose to) inline them,
 * and it keeps ccan/json from having a dependency.
 */

/*
 * Type for Unicode codepoints.
 * We need our own because wchar_t might be 16 bits.
 */
typedef uint32_t uchar_t;

/*
 * Validate a single UTF-8 character starting at @s.
 * The string must be null-terminated.
 *
 * If it's valid, return its length (1 thru 4).
 * If it's invalid or clipped, return 0.
 *
 * This function implements the syntax given in RFC3629, which is
 * the same as that given in The Unicode Standard, Version 6.0.
 *
 * It has the following properties:
 *
 *  * All codepoints U+0000..U+10FFFF may be encoded,
 *    except for U+D800..U+DFFF, which are reserved
 *    for UTF-16 surrogate pair encoding.
 *  * UTF-8 byte sequences longer than 4 bytes are not permitted,
 *    as they exceed the range of Unicode.
 *  * The sixty-six Unicode "non-characters" are permitted
 *    (namely, U+FDD0..U+FDEF, U+xxFFFE, and U+xxFFFF).
 */
static int utf8_validate_cz(const char *s)
{
	unsigned char c = *s++;

	if (c <= 0xC1) { /* 80..C1 */
		/* Disallow overlong 2-byte sequence. */
		return 0;
	} else if (c <= 0xDF) { /* C2..DF */
		/* Make sure subsequent byte is in the range 0x80..0xBF. */
		if (((unsigned char)*s++ & 0xC0) != 0x80)
			return 0;

		return 2;
	} else if (c <= 0xEF) { /* E0..EF */
		/* Disallow overlong 3-byte sequence. */
		if (c == 0xE0 && (unsigned char)*s < 0xA0)
			return 0;

		/* Disallow U+D800..U+DFFF. */
		if (c == 0xED && (unsigned char)*s > 0x9F)
			return 0;

		/* Make sure subsequent bytes are in the range 0x80..0xBF. */
		if (((unsigned char)*s++ & 0xC0) != 0x80)
			return 0;
		if (((unsigned char)*s++ & 0xC0) != 0x80)
			return 0;

		return 3;
	} else if (c <= 0xF4) { /* F0..F4 */
		/* Disallow overlong 4-byte sequence. */
		if (c == 0xF0 && (unsigned char)*s < 0x90)
			return 0;

		/* Disallow codepoints beyond U+10FFFF. */
		if (c == 0xF4 && (unsigned char)*s > 0x8F)
			return 0;

		/* Make sure subsequent bytes are in the range 0x80..0xBF. */
		if (((unsigned char)*s++ & 0xC0) != 0x80)
			return 0;
		if (((unsigned char)*s++ & 0xC0) != 0x80)
			return 0;
		if (((unsigned char)*s++ & 0xC0) != 0x80)
			return 0;

		return 4;
	} else {                /* F5..FF */
		return 0;
	}
}

/*
 * Write a single UTF-8 character to @s,
 * returning the length, in bytes, of the character written.
 *
 * @unicode must be U+0000..U+10FFFF, but not U+D800..U+DFFF.
 *
 * This function will write up to 4 bytes to @out.
 */
static int utf8_write_char(uchar_t unicode, char *out)
{
	unsigned char *o = (unsigned char*) out;

	assert(unicode <= 0x10FFFF && !(unicode >= 0xD800 && unicode <= 0xDFFF));

	if (unicode <= 0x7F) {
		/* U+0000..U+007F */
		*o++ = unicode;
		return 1;
	} else if (unicode <= 0x7FF) {
		/* U+0080..U+07FF */
		*o++ = 0xC0 | unicode >> 6;
		*o++ = 0x80 | (unicode & 0x3F);
		return 2;
	} else if (unicode <= 0xFFFF) {
		/* U+0800..U+FFFF */
		*o++ = 0xE0 | unicode >> 12;
		*o++ = 0x80 | (unicode >> 6 & 0x3F);
		*o++ = 0x80 | (unicode & 0x3F);
		return 3;
	} else {
		/* U+10000..U+10FFFF */
		*o++ = 0xF0 | unicode >> 18;
		*o++ = 0x80 | (unicode >> 12 & 0x3F);
		*o++ = 0x80 | (unicode >> 6 & 0x3F);
		*o++ = 0x80 | (unicode & 0x3F);
		return 4;
	}
}

/*
 * Compute the Unicode codepoint of a UTF-16 surrogate pair.
 *
 * @uc should be 0xD800..0xDBFF, and @lc should be 0xDC00..0xDFFF.
 * If they aren't, this function returns false.
 */
static bool from_surrogate_pair(uint16_t uc, uint16_t lc, uchar_t *unicode)
{
	if (uc >= 0xD800 && uc <= 0xDBFF && lc >= 0xDC00 && lc <= 0xDFFF) {
		*unicode = 0x10000 + ((((uchar_t)uc & 0x3FF) << 10) | (lc & 0x3FF));
		return true;
	} else {
		return false;
	}
}

#define is_space(c) ((c) == '\t' || (c) == '\n' || (c) == '\r' || (c) == ' ')
#define is_digit(c) ((c) >= '0' && (c) <= '9')

static bool parse_value     (const char **sp, JsonNode        **out);
static bool parse_string    (const char **sp, char            **out);
static bool parse_number    (const char **sp, double           *out);
static bool parse_array     (const char **sp, JsonNode        **out);
static bool parse_object    (const char **sp, JsonNode        **out);
static bool parse_hex16     (const char **sp, uint16_t         *out);

static bool expect_literal  (const char **sp, const char *str);
static void skip_space      (const char **sp);

static void emit_value              (SB *out, const JsonNode *node);
static void emit_value_indented     (SB *out, const JsonNode *node, const char *space, int indent_level);
static void emit_string             (SB *out, const char *str);
static void emit_number             (SB *out, double num);
static void emit_array              (SB *out, const JsonNode *array);
static void emit_array_indented     (SB *out, const JsonNode *array, const char *space, int indent_level);
static void emit_object             (SB *out, const JsonNode *object);
static void emit_object_indented    (SB *out, const JsonNode *object, const char *space, int indent_level);

static JsonNode *mknode(JsonTag tag);
static void append_node(JsonNode *parent, JsonNode *child);
static void prepend_node(JsonNode *parent, JsonNode *child);

/* Assertion-friendly validity checks */
static bool tag_is_valid(unsigned int tag);
static bool number_is_valid(const char *num);

JsonNode *json_decode(const char *json)
{
	const char *s = json;
	JsonNode *ret;

	skip_space(&s);
	if (!parse_value(&s, &ret))
		return NULL;

	skip_space(&s);
	if (*s != 0) {
		json_delete(ret);
		return NULL;
	}

	return ret;
}

char *json_encode(const JsonNode *node, const char *space)
{
	SB sb;
	sb_init(&sb);

	if (space != NULL)
		emit_value_indented(&sb, node, space, 0);
	else
		emit_value(&sb, node);

	return sb_finish(&sb);
}

static void remove_from_parent(JsonNode *node, bool free_key)
{
	JsonNode *parent = node->parent;

	if (parent != NULL) {
		if (node->prev != NULL)
			node->prev->next = node->next;
		else
			parent->children.head = node->next;
		if (node->next != NULL)
			node->next->prev = node->prev;
		else
			parent->children.tail = node->prev;

        if (free_key) {
		    free(node->key);
		    node->key = NULL;
		}

		node->parent = NULL;
		node->prev = node->next = NULL;
	}
}

void json_delete(JsonNode *node)
{
	if (node != NULL) {
		remove_from_parent(node, true);

		switch (node->tag) {
			case JSON_STRING:
				free(node->string_);
				break;
			case JSON_ARRAY:
			case JSON_OBJECT:
			{
				JsonNode *child, *next;
				for (child = node->children.head; child != NULL; child = next) {
					next = child->next;
					json_delete(child);
				}
				break;
			}
			default:;
		}
        free(node);
	}
}

bool json_validate(const char *json)
{
	const char *s = json;

	skip_space(&s);
	if (!parse_value(&s, NULL))
		return false;

	skip_space(&s);
	if (*s != 0)
		return false;

	return true;
}

JsonNode *json_first_child(const JsonNode *node)
{
	if (node != NULL && (node->tag == JSON_ARRAY || node->tag == JSON_OBJECT))
		return node->children.head;
	return NULL;
}

JsonNode *json_find_element(const JsonNode *array, int index)
{
	JsonNode *element;
	int i = 0;

	if (array == NULL || array->tag != JSON_ARRAY)
		return NULL;

	json_foreach(element, array) {
		if (i == index)
			return element;
		i++;
	}

	return NULL;
}

JsonNode *json_find_member(const JsonNode *object, const char *name)
{
	JsonNode *member;

	if (object == NULL || object->tag != JSON_OBJECT)
		return NULL;

	json_foreach(member, object)
		if (strcmp(member->key, name) == 0)
			return member;

	return NULL;
}

bool json_is_null(const JsonNode *node)
{
    return node->tag == JSON_NULL;
}

bool json_is_bool(const JsonNode *node)
{
    return node->tag == JSON_BOOL;
}

bool json_is_string(const JsonNode *node)
{
    return node->tag == JSON_STRING;
}

bool json_is_number(const JsonNode *node)
{
    return node->tag == JSON_NUMBER;
}

bool json_is_array(const JsonNode *node)
{
    return node->tag == JSON_ARRAY;
}

bool json_is_object(const JsonNode *node)
{
    return node->tag == JSON_OBJECT;
}

bool json_get_bool(const JsonNode *node)
{
    assert(node->tag == JSON_BOOL);
    return node->bool_;
}

char *json_get_string(const JsonNode *node)
{
    assert(node->tag == JSON_STRING);
    return node->string_;
}

double json_get_number(const JsonNode *node)
{
    assert(node->tag == JSON_NUMBER);
    return node->number_;
}

char *json_get_key(const JsonNode *node)
{
    return node->key;
}

static void set_cleanup(JsonNode *node)
{
    switch (node->tag) {
        case JSON_STRING:
            free(node->string_);
            break;
        case JSON_ARRAY:
        case JSON_OBJECT:
            {
                JsonNode *child, *next;
                for (child = node->children.head; child != NULL; child = next) {
                    next = child->next;
                    json_delete(child);
                }
                break;
            }
        default:;
    }
}

void json_set_null(JsonNode *node)
{
    set_cleanup(node);
    node->tag = JSON_NULL;
}

void json_set_bool(JsonNode *node, bool b)
{
    set_cleanup(node);
    node->tag = JSON_BOOL;
    node->bool_ = b;
}

void json_set_string(JsonNode *node, const char *str)
{
    set_cleanup(node);
    node->tag = JSON_STRING;
    node->string_ = json_strdup(str);
}

void json_set_number(JsonNode *node, double n)
{
    set_cleanup(node);
    node->tag = JSON_NUMBER;
    node->number_ = n;
}

void json_set_array(JsonNode *node)
{
    set_cleanup(node);
    node->tag = JSON_ARRAY;
}

void json_set_object(JsonNode *node)
{
    set_cleanup(node);
    node->tag = JSON_OBJECT;
}

void json_set_key(JsonNode *node, const char *new_key)
{
    free(node->key);
    node->key = json_strdup(new_key);
}

static JsonNode *mknode(JsonTag tag)
{
    JsonNode *ret = (JsonNode*) calloc(1, sizeof(JsonNode));
    if (ret == NULL)
        out_of_memory();
	ret->tag = tag;
	return ret;
}

static JsonNode *json_mknull(void)
{
	return mknode(JSON_NULL);
}

static JsonNode *json_mkbool(bool b)
{
	JsonNode *ret = mknode(JSON_BOOL);
	ret->bool_ = b;
	return ret;
}

static JsonNode *mkstring(char *s)
{
	JsonNode *ret = mknode(JSON_STRING);
	ret->string_ = s;
	return ret;
}

static JsonNode *json_mkstring(const char *s)
{
	return mkstring(json_strdup(s));
}

static JsonNode *json_mknumber(double n)
{
	JsonNode *node = mknode(JSON_NUMBER);
	node->number_ = n;
	return node;
}

JsonNode *json_mkarray(void)
{
	return mknode(JSON_ARRAY);
}

JsonNode *json_mkobject(void)
{
	return mknode(JSON_OBJECT);
}

static void append_node(JsonNode *parent, JsonNode *child)
{
	child->parent = parent;
	child->prev = parent->children.tail;
	child->next = NULL;

	if (parent->children.tail != NULL)
		parent->children.tail->next = child;
	else
		parent->children.head = child;
	parent->children.tail = child;
}

static void prepend_node(JsonNode *parent, JsonNode *child)
{
	child->parent = parent;
	child->prev = NULL;
	child->next = parent->children.head;

	if (parent->children.head != NULL)
		parent->children.head->prev = child;
	else
		parent->children.tail = child;
	parent->children.head = child;
}

JsonNode *json_append_element(JsonNode *array, JsonNode *element)
{
    assert(array->tag == JSON_ARRAY);
    remove_from_parent(element, true);
    append_node(array, element);
    return element;
}

JsonNode *json_prepend_element(JsonNode *array, JsonNode *element)
{
    assert(array->tag == JSON_ARRAY);
    remove_from_parent(element, true);
    prepend_node(array, element);
    return element;
}

JsonNode *json_append_member(JsonNode *object, JsonNode *value, const char *key)
{
    assert(object->tag == JSON_OBJECT);
    if (key == NULL) {
        assert(value->key != NULL);
        remove_from_parent(value, false);
        append_node(object, value);
    } else {
        char *key_dup = json_strdup(key);
        remove_from_parent(value, true);
        value->key = key_dup;
        append_node(object, value);
    }
    return value;
}

JsonNode *json_prepend_member(JsonNode *object, JsonNode *value, const char *key)
{
    assert(object->tag == JSON_OBJECT);
    if (key == NULL) {
        assert(value->key != NULL);
        remove_from_parent(value, false);
        prepend_node(object,value);
    } else {
        char *key_dup = json_strdup(key);
        remove_from_parent(value, true);
        value->key = key_dup;
        prepend_node(object, value);
    }
    return value;
}

JsonNode *json_append_element_null(JsonNode *array)
{
    return json_append_element(array, json_mknull());
}

JsonNode *json_append_element_bool(JsonNode *array, bool b)
{
    return json_append_element(array, json_mkbool(b));
}

JsonNode *json_append_element_string(JsonNode *array, const char *str)
{
    JsonNode *node = json_mkstring(str);
    json_append_element(array, node);
    return node;
}

JsonNode *json_append_element_number(JsonNode *array, double n)
{
    return json_append_element(array, json_mknumber(n));
}

JsonNode *json_append_element_array(JsonNode *array)
{
    return json_append_element(array, json_mkarray());
}

JsonNode *json_append_element_object(JsonNode *array)
{
    return json_append_element(array, json_mkobject());
}

JsonNode *json_prepend_element_null(JsonNode *array)
{
    return json_prepend_element(array, json_mknull());
}

JsonNode *json_prepend_element_bool(JsonNode *array, bool b)
{
    return json_prepend_element(array, json_mkbool(b));
}

JsonNode *json_prepend_element_string(JsonNode *array, const char *str)
{
    return json_prepend_element(array, json_mkstring(str));
}

JsonNode *json_prepend_element_number(JsonNode *array, double n)
{
    return json_prepend_element(array, json_mknumber(n));
}

JsonNode *json_prepend_element_array(JsonNode *array)
{
    return json_prepend_element(array, json_mkarray());
}

JsonNode *json_prepend_element_object(JsonNode *array)
{
    return json_prepend_element(array, json_mkobject());
}

JsonNode *json_append_member_null(JsonNode *object, const char *key)
{
    return json_append_member(object, json_mknull(), key);
}

JsonNode *json_append_member_bool(JsonNode *object, const char *key, bool b)
{
    return json_append_member(object, json_mkbool(b), key);
}

JsonNode *json_append_member_string(JsonNode *object, const char *key, const char *str)
{
    return json_append_member(object, json_mkstring(str), key);
}

JsonNode *json_append_member_number(JsonNode *object, const char *key, double n)
{
    return json_append_member(object, json_mknumber(n), key);
}

JsonNode *json_append_member_array(JsonNode *object, const char *key)
{
    return json_append_member(object, json_mkarray(), key);
}

JsonNode *json_append_member_object(JsonNode *object, const char *key)
{
    return json_append_member(object, json_mkobject(), key);
}

JsonNode *json_prepend_member_null(JsonNode *object, const char *key)
{
    return json_prepend_member(object, json_mknull(), key);
}

JsonNode *json_prepend_member_bool(JsonNode *object, const char *key, bool b)
{
    return json_prepend_member(object, json_mkbool(b), key);
}

JsonNode *json_prepend_member_string(JsonNode *object, const char *key, const char *str)
{
    return json_prepend_member(object, json_mkstring(str), key);
}

JsonNode *json_prepend_member_number(JsonNode *object, const char *key, double n)
{
    return json_prepend_member(object, json_mknumber(n), key);
}

JsonNode *json_prepend_member_array(JsonNode *object, const char *key)
{
    return json_prepend_member(object, json_mkarray(), key);
}

JsonNode *json_prepend_member_object(JsonNode *object, const char *key)
{
    return json_prepend_member(object, json_mkobject(), key);
}

static bool parse_value(const char **sp, JsonNode **out)
{
	const char *s = *sp;

	switch (*s) {
		case 'n':
			if (expect_literal(&s, "null")) {
				if (out)
					*out = json_mknull();
				*sp = s;
				return true;
			}
			return false;

		case 'f':
			if (expect_literal(&s, "false")) {
				if (out)
					*out = json_mkbool(false);
				*sp = s;
				return true;
			}
			return false;

		case 't':
			if (expect_literal(&s, "true")) {
				if (out)
					*out = json_mkbool(true);
				*sp = s;
				return true;
			}
			return false;

		case '"': {
			char *str;
			if (parse_string(&s, out ? &str : NULL)) {
				if (out)
					*out = mkstring(str);
				*sp = s;
				return true;
			}
			return false;
		}

		case '[':
			if (parse_array(&s, out)) {
				*sp = s;
				return true;
			}
			return false;

		case '{':
			if (parse_object(&s, out)) {
				*sp = s;
				return true;
			}
			return false;

		default: {
			double num;
			if (parse_number(&s, out ? &num : NULL)) {
				if (out)
					*out = json_mknumber(num);
				*sp = s;
				return true;
			}
			return false;
		}
	}
}

static bool parse_array(const char **sp, JsonNode **out)
{
	const char *s = *sp;
	JsonNode *ret = out ? json_mkarray() : NULL;
	JsonNode *element;

	if (*s++ != '[')
		goto failure;
	skip_space(&s);

	if (*s == ']') {
		s++;
		goto success;
	}

	for (;;) {
		if (!parse_value(&s, out ? &element : NULL))
			goto failure;
		skip_space(&s);

		if (out)
			json_append_element(ret, element);

		if (*s == ']') {
			s++;
			goto success;
		}

		if (*s++ != ',')
			goto failure;
		skip_space(&s);
	}

success:
	*sp = s;
	if (out)
		*out = ret;
	return true;

failure:
	json_delete(ret);
	return false;
}

static bool parse_object(const char **sp, JsonNode **out)
{
	const char *s = *sp;
	JsonNode *ret = out ? json_mkobject() : NULL;
	char *key;
	JsonNode *value;

	if (*s++ != '{')
		goto failure;
	skip_space(&s);

	if (*s == '}') {
		s++;
		goto success;
	}

	for (;;) {
		if (!parse_string(&s, out ? &key : NULL))
			goto failure;
		skip_space(&s);

		if (*s++ != ':')
			goto failure_free_key;
		skip_space(&s);

		if (!parse_value(&s, out ? &value : NULL))
			goto failure_free_key;
		skip_space(&s);

		if (out) {
		    value->key = key;
		    append_node(ret, value);
		}

		if (*s == '}') {
			s++;
			goto success;
		}

		if (*s++ != ',')
			goto failure;
		skip_space(&s);
	}

success:
	*sp = s;
	if (out)
		*out = ret;
	return true;

failure_free_key:
	if (out)
		free(key);
failure:
	json_delete(ret);
	return false;
}

bool parse_string(const char **sp, char **out)
{
	const char *s = *sp;
	SB sb;
	char throwaway_buffer[4];
		/* enough space for a UTF-8 character */
	char *b;

	if (*s++ != '"')
		return false;

	if (out) {
		sb_init(&sb);
		sb_need(&sb, 4);
		b = sb.cur;
	} else {
		b = throwaway_buffer;
	}

	while (*s != '"') {
		unsigned char c = *s++;

		/* Parse next character, and write it to b. */
		if (c == '\\') {
			c = *s++;
			switch (c) {
				case '"':
				case '\\':
				case '/':
					*b++ = c;
					break;
				case 'b':
					*b++ = '\b';
					break;
				case 'f':
					*b++ = '\f';
					break;
				case 'n':
					*b++ = '\n';
					break;
				case 'r':
					*b++ = '\r';
					break;
				case 't':
					*b++ = '\t';
					break;
				case 'u':
				{
					uint16_t uc, lc;
					uchar_t unicode;

					if (!parse_hex16(&s, &uc))
						goto failed;

					if (uc >= 0xD800 && uc <= 0xDFFF) {
						/* Handle UTF-16 surrogate pair. */
						if (*s++ != '\\' || *s++ != 'u' || !parse_hex16(&s, &lc))
							goto failed; /* Incomplete surrogate pair. */
						if (!from_surrogate_pair(uc, lc, &unicode))
							goto failed; /* Invalid surrogate pair. */
					} else if (uc == 0) {
						/* Disallow "\u0000". */
						goto failed;
					} else {
						unicode = uc;
					}

					b += utf8_write_char(unicode, b);
					break;
				}
				default:
					/* Invalid escape */
					goto failed;
			}
		} else if (c > 0x1F && c <= 0x7F) {
		    *b = c;
		    b++;
		} else {
			/* Validate and echo a UTF-8 character. */
			int len;
			s--;
			len = utf8_validate_cz(s);
			if (len == 0)
				goto failed; /* Invalid UTF-8 character. */
			while (len--)
			    *b++ = *s++;
		}

		/*
		 * Update sb to know about the new bytes,
		 * and set up b to write another character.
		 */
		if (out) {
			sb.cur = b;
			sb_need(&sb, 4);
			b = sb.cur;
		} else {
			b = throwaway_buffer;
		}
	}
	s++;

	if (out)
		*out = sb_finish(&sb);
	*sp = s;
	return true;

failed:
	if (out)
		sb_free(&sb);
	return false;
}

/*
 * The JSON spec says that a number shall follow this precise pattern
 * (spaces and quotes added for readability):
 *	 '-'? (0 | [1-9][0-9]*) ('.' [0-9]+)? ([Ee] [+-]? [0-9]+)?
 *
 * However, some JSON parsers are more liberal.  For instance, PHP accepts
 * '.5' and '1.'.  JSON.parse accepts '+3'.
 *
 * This function takes the strict approach.
 */
bool parse_number(const char **sp, double *out)
{
	const char *s = *sp;

	/* '-'? */
	if (*s == '-')
		s++;

	/* (0 | [1-9][0-9]*) */
	if (*s == '0') {
		s++;
	} else {
		if (!is_digit(*s))
			return false;
		do {
			s++;
		} while (is_digit(*s));
	}

	/* ('.' [0-9]+)? */
	if (*s == '.') {
		s++;
		if (!is_digit(*s))
			return false;
		do {
			s++;
		} while (is_digit(*s));
	}

	/* ([Ee] [+-]? [0-9]+)? */
	if (*s == 'E' || *s == 'e') {
		s++;
		if (*s == '+' || *s == '-')
			s++;
		if (!is_digit(*s))
			return false;
		do {
			s++;
		} while (is_digit(*s));
	}

	if (out)
		*out = strtod(*sp, NULL);

	*sp = s;
	return true;
}

static void skip_space(const char **sp)
{
	const char *s = *sp;
	while (is_space(*s))
		s++;
	*sp = s;
}

static void emit_value(SB *out, const JsonNode *node)
{
	assert(tag_is_valid(node->tag));
	switch (node->tag) {
		case JSON_NULL:
			sb_puts(out, "null");
			break;
		case JSON_BOOL:
			sb_puts(out, node->bool_ ? "true" : "false");
			break;
		case JSON_STRING:
			emit_string(out, node->string_);
			break;
		case JSON_NUMBER:
			emit_number(out, node->number_);
			break;
		case JSON_ARRAY:
			emit_array(out, node);
			break;
		case JSON_OBJECT:
			emit_object(out, node);
			break;
		default:
			assert(false);
	}
}

void emit_value_indented(SB *out, const JsonNode *node, const char *space, int indent_level)
{
	assert(tag_is_valid(node->tag));
	switch (node->tag) {
		case JSON_NULL:
			sb_puts(out, "null");
			break;
		case JSON_BOOL:
			sb_puts(out, node->bool_ ? "true" : "false");
			break;
		case JSON_STRING:
			emit_string(out, node->string_);
			break;
		case JSON_NUMBER:
			emit_number(out, node->number_);
			break;
		case JSON_ARRAY:
			emit_array_indented(out, node, space, indent_level);
			break;
		case JSON_OBJECT:
			emit_object_indented(out, node, space, indent_level);
			break;
		default:
			assert(false);
	}
}

static void emit_array(SB *out, const JsonNode *array)
{
	const JsonNode *element;

	sb_putc(out, '[');
	json_foreach(element, array) {
		emit_value(out, element);
		if (element->next != NULL)
			sb_putc(out, ',');
	}
	sb_putc(out, ']');
}

static void emit_array_indented(SB *out, const JsonNode *array, const char *space, int indent_level)
{
	const JsonNode *element = array->children.head;
	int i;

	if (element == NULL) {
		sb_puts(out, "[]");
		return;
	}

	sb_puts(out, "[\n");
	while (element != NULL) {
		for (i = 0; i < indent_level + 1; i++)
			sb_puts(out, space);
		emit_value_indented(out, element, space, indent_level + 1);

		element = element->next;
		sb_puts(out, element != NULL ? ",\n" : "\n");
	}
	for (i = 0; i < indent_level; i++)
		sb_puts(out, space);
	sb_putc(out, ']');
}

static void emit_object(SB *out, const JsonNode *object)
{
	const JsonNode *member;

	sb_putc(out, '{');
	json_foreach(member, object) {
		emit_string(out, member->key);
		sb_putc(out, ':');
		emit_value(out, member);
		if (member->next != NULL)
			sb_putc(out, ',');
	}
	sb_putc(out, '}');
}

static void emit_object_indented(SB *out, const JsonNode *object, const char *space, int indent_level)
{
	const JsonNode *member = object->children.head;
	int i;

	if (member == NULL) {
		sb_puts(out, "{}");
		return;
	}

	sb_puts(out, "{\n");
	while (member != NULL) {
		for (i = 0; i < indent_level + 1; i++)
			sb_puts(out, space);
		emit_string(out, member->key);
		sb_puts(out, ": ");
		emit_value_indented(out, member, space, indent_level + 1);

		member = member->next;
		sb_puts(out, member != NULL ? ",\n" : "\n");
	}
	for (i = 0; i < indent_level; i++)
		sb_puts(out, space);
	sb_putc(out, '}');
}

void emit_string(SB *out, const char *str)
{
	const char *s = str;
	char *b;

	/*
	 * 14 bytes is enough space to write up to two
	 * \uXXXX escapes and two quotation marks.
	 */
	sb_need(out, 14);
	b = out->cur;

	*b++ = '"';
	while (*s != 0) {
		unsigned char c = *s++;

		/* Encode the next character, and write it to b. */
		switch (c) {
			case '"':
				*b++ = '\\';
				*b++ = '"';
				break;
			case '\\':
				*b++ = '\\';
				*b++ = '\\';
				break;
			case '\b':
				*b++ = '\\';
				*b++ = 'b';
				break;
			case '\f':
				*b++ = '\\';
				*b++ = 'f';
				break;
			case '\n':
				*b++ = '\\';
				*b++ = 'n';
				break;
			case '\r':
				*b++ = '\\';
				*b++ = 'r';
				break;
			case '\t':
				*b++ = '\\';
				*b++ = 't';
				break;
			default: {
			    if (c > 0x1F && c <= 0x7F) {
				    *b = c;
				    b++;
				} else {
				    int len;
				    s--;
				    len = utf8_validate_cz(s);
				    if (len == 0)
					    goto out;
				    while (len--)
				        *b++ = *s++;
				}
				break;
			}
		}

		/*
		 * Update *out to know about the new bytes,
		 * and set up b to write another encoded character.
		 */
		out->cur = b;
		sb_need(out, 14);
		b = out->cur;
	}
out:
	*b++ = '"';

	out->cur = b;
}

static void emit_number(SB *out, double num)
{
	/*
	 * This isn't exactly how JavaScript renders numbers,
	 * but it should produce valid JSON for reasonable numbers
	 * preserve precision well enough, and avoid some oddities
	 * like 0.3 -> 0.299999999999999988898 .
	 */
	char buf[64];
	sprintf(buf, "%.16g", num);

	if (number_is_valid(buf))
		sb_puts(out, buf);
	else
		sb_puts(out, "null");
}

static bool tag_is_valid(unsigned int tag)
{
	return (/* tag >= JSON_NULL && */ tag <= JSON_OBJECT);
}

static bool number_is_valid(const char *num)
{
	return (parse_number(&num, NULL) && *num == '\0');
}

static bool expect_literal(const char **sp, const char *str)
{
	const char *s = *sp;

	while (*str != '\0')
		if (*s++ != *str++)
			return false;

	*sp = s;
	return true;
}

/*
 * Parses exactly 4 hex characters (capital or lowercase).
 * Fails if any input chars are not [0-9A-Fa-f].
 */
static bool parse_hex16(const char **sp, uint16_t *out)
{
    static int8_t map[] = {
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, // 0-15
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, // 16-31
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, // 32-47
         0,  1,  2,  3,  4,  5,  6,  7,  8,  9, -1, -1, -1, -1, -1, -1, // 48-63
        -1, 10, 11, 12, 13, 14, 15, -1, -1, -1, -1, -1, -1, -1, -1, -1, // 64-79
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, // 80-95
        -1, 10, 11, 12, 13, 14, 15 // 96-102
    };
	const char *s = *sp;
	uint16_t ret = 0;
	uint16_t i;
	uint16_t tmp;
	uint8_t c;

	for (i = 0; i < 4; i++) {
		c = s[i];
		if (c > 102) {
		    return false;
		}
		tmp = map[c];
		if (tmp == -1) {
		    return false;
		}

		ret <<= 4;
		ret += tmp;
	}

	if (out)
		*out = ret;
	*sp = s + 4;
	return true;
}

struct JsonIterator
{
    JsonNode *cur;
    JsonNode *next;
};

JsonIterator *json_iterator_new(JsonNode *node)
{
    JsonIterator *iterator = malloc(sizeof(JsonIterator));
    if (node == NULL) {
        iterator->cur  = NULL;
        iterator->next = NULL;
        return iterator;
    }

    if (node->tag == JSON_ARRAY || node->tag == JSON_OBJECT) {
        iterator->cur = json_first_child(node);
        if (iterator->cur == NULL) {
            iterator->next = NULL;
        } else {
            iterator->next = iterator->cur->next;
        }
    } else {
        iterator->cur  = node;
        iterator->next = iterator->cur->next;
    }
    return iterator;
}

void json_iterator_delete(JsonIterator *iterator)
{
    free(iterator);
}

JsonNode *json_iterator_next_value(JsonIterator *iterator)
{
    JsonNode *cur = iterator->cur;
    if (cur == NULL) {
        return NULL;
    }

    if (iterator->next == NULL) {
        iterator->cur = NULL;
    } else {
        iterator->cur  = iterator->next;
        iterator->next = iterator->cur->next;
    }
    return cur;
}

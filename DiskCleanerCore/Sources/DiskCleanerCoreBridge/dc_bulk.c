//
//  dc_bulk.c
//  DiskCleanerCoreBridge
//
//  Bulk directory enumeration via getattrlistbulk(2). One system call returns
//  metadata (name, object type, sizes, APFS clone id) for many directory
//  entries at once — far fewer syscalls than readdir + stat per entry.
//
//  The buffer returned by getattrlistbulk holds a sequence of variable-length
//  records, each starting with a uint32_t entry_length, followed by the
//  requested attributes in the order they appear in struct attrlist. With
//  FSOPT_PACK_INVAL_ATTRS the layout is predictable even for entries where
//  not all requested attributes are valid (e.g. file-size attributes on a
//  directory).
//

#include "DiskCleanerCoreBridge.h"

#include <fcntl.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/attr.h>
#include <sys/types.h>
#include <sys/vnode.h>

#define DC_BULK_BUFFER_SIZE (64 * 1024)

struct DCBulkContext {
    int fd;
    struct attrlist attrlist;

    /// Number of entries returned by the most recent syscall that have not
    /// yet been emitted from the buffer.
    int remaining;

    /// Pointer to the next entry in `buffer` to parse.
    uint8_t *cursor;

    uint8_t buffer[DC_BULK_BUFFER_SIZE];
};

DCBulkContext *dc_bulk_open(const char *path) {
    if (path == NULL) {
        return NULL;
    }
    int fd = open(path, O_RDONLY | O_DIRECTORY);
    if (fd < 0) {
        return NULL;
    }

    DCBulkContext *ctx = (DCBulkContext *)calloc(1, sizeof(*ctx));
    if (ctx == NULL) {
        close(fd);
        return NULL;
    }

    ctx->fd = fd;
    ctx->remaining = 0;
    ctx->cursor = NULL;

    ctx->attrlist.bitmapcount = ATTR_BIT_MAP_COUNT;
    ctx->attrlist.commonattr  = ATTR_CMN_RETURNED_ATTRS
                              | ATTR_CMN_NAME
                              | ATTR_CMN_OBJTYPE;
    ctx->attrlist.fileattr    = ATTR_FILE_TOTALSIZE
                              | ATTR_FILE_ALLOCSIZE;
    ctx->attrlist.forkattr    = ATTR_CMNEXT_CLONEID;

    return ctx;
}

void dc_bulk_close(DCBulkContext *ctx) {
    if (ctx == NULL) {
        return;
    }
    if (ctx->fd >= 0) {
        close(ctx->fd);
    }
    free(ctx);
}

int dc_bulk_next(DCBulkContext *ctx, DCBulkEntry *entries, size_t max_entries) {
    if (ctx == NULL || entries == NULL || max_entries == 0) {
        return -1;
    }

    // Refill the internal buffer if the last syscall's entries are exhausted.
    if (ctx->remaining <= 0) {
        int returned = getattrlistbulk(
            ctx->fd,
            &ctx->attrlist,
            ctx->buffer,
            sizeof(ctx->buffer),
            FSOPT_PACK_INVAL_ATTRS | FSOPT_ATTR_CMN_EXTENDED
        );
        if (returned < 0) {
            return -1;
        }
        if (returned == 0) {
            return 0;
        }
        ctx->remaining = returned;
        ctx->cursor = ctx->buffer;
    }

    size_t emitted = 0;
    while (ctx->remaining > 0 && emitted < max_entries) {
        uint8_t *entry_start = ctx->cursor;

        uint32_t entry_length = 0;
        memcpy(&entry_length, entry_start, sizeof(entry_length));

        DCBulkEntry *out = &entries[emitted];
        memset(out, 0, sizeof(*out));

        uint8_t *p = entry_start + sizeof(uint32_t);

        // ATTR_CMN_RETURNED_ATTRS — always first.
        attribute_set_t returned_attrs;
        memcpy(&returned_attrs, p, sizeof(returned_attrs));
        p += sizeof(returned_attrs);

        // ATTR_CMN_NAME — attrreference_t with attr_dataoffset relative to
        // the address of the attrreference itself.
        attrreference_t name_ref;
        memcpy(&name_ref, p, sizeof(name_ref));
        if (returned_attrs.commonattr & ATTR_CMN_NAME) {
            const char *name_ptr = (const char *)p + name_ref.attr_dataoffset;
            size_t name_len = name_ref.attr_length;
            if (name_len >= sizeof(out->name)) {
                name_len = sizeof(out->name) - 1;
            }
            if (name_len > 0) {
                memcpy(out->name, name_ptr, name_len);
            }
            out->name[name_len < sizeof(out->name) ? name_len : sizeof(out->name) - 1] = '\0';
        }
        p += sizeof(name_ref);

        // ATTR_CMN_OBJTYPE — fsobj_type_t (uint32 enum).
        if (returned_attrs.commonattr & ATTR_CMN_OBJTYPE) {
            fsobj_type_t obj_type = 0;
            memcpy(&obj_type, p, sizeof(obj_type));
            out->is_directory = (obj_type == VDIR) ? 1 : 0;
            out->is_symlink   = (obj_type == VLNK) ? 1 : 0;
        }
        p += sizeof(fsobj_type_t);

        // ATTR_FILE_TOTALSIZE — off_t (int64).
        if (returned_attrs.fileattr & ATTR_FILE_TOTALSIZE) {
            off_t value = 0;
            memcpy(&value, p, sizeof(value));
            out->logical_size = (int64_t)value;
        }
        p += sizeof(off_t);

        // ATTR_FILE_ALLOCSIZE — off_t (int64).
        if (returned_attrs.fileattr & ATTR_FILE_ALLOCSIZE) {
            off_t value = 0;
            memcpy(&value, p, sizeof(value));
            out->allocated_size = (int64_t)value;
        }
        p += sizeof(off_t);

        // ATTR_CMNEXT_CLONEID — uint64.
        if (returned_attrs.forkattr & ATTR_CMNEXT_CLONEID) {
            uint64_t value = 0;
            memcpy(&value, p, sizeof(value));
            out->clone_id = value;
        }
        p += sizeof(uint64_t);

        ctx->cursor = entry_start + entry_length;
        ctx->remaining--;
        emitted++;
    }

    return (int)emitted;
}

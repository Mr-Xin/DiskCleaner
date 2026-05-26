//
//  dc_clone.c
//  DiskCleanerCoreBridge
//
//  APFS clone identifier lookup. `ATTR_CMNEXT_CLONEID` is part of the extended
//  common attribute group, which is requested by placing it in `attrlist.forkattr`
//  together with the `FSOPT_ATTR_CMN_EXTENDED` option.
//

#include "DiskCleanerCoreBridge.h"

#include <string.h>
#include <unistd.h>
#include <sys/attr.h>
#include <sys/clonefile.h>

uint64_t dc_get_clone_id(const char *path) {
    if (path == NULL) {
        return 0;
    }

    struct attrlist attrs;
    memset(&attrs, 0, sizeof(attrs));
    attrs.bitmapcount = ATTR_BIT_MAP_COUNT;
    attrs.forkattr = ATTR_CMNEXT_CLONEID;

    // The returned buffer begins with a uint32_t length (which includes the
    // length field itself), followed by the requested attributes in the order
    // they appear in `struct attrlist`. We request a single 8-byte attribute,
    // so the minimum buffer is 4 + 8 = 12 bytes. Pad to 16 for alignment
    // safety.
    char buffer[16];
    memset(buffer, 0, sizeof(buffer));

    if (getattrlist(path, &attrs, buffer, sizeof(buffer), FSOPT_ATTR_CMN_EXTENDED) != 0) {
        return 0;
    }

    uint32_t length = 0;
    memcpy(&length, buffer, sizeof(length));
    if (length < sizeof(uint32_t) + sizeof(uint64_t)) {
        return 0;
    }

    uint64_t clone_id = 0;
    memcpy(&clone_id, buffer + sizeof(uint32_t), sizeof(clone_id));
    return clone_id;
}

int dc_clone_file(const char *source, const char *destination) {
    if (source == NULL || destination == NULL) {
        return -1;
    }
    return clonefile(source, destination, 0);
}

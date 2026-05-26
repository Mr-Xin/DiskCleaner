//
//  DiskCleanerCoreBridge.h
//  DiskCleanerCoreBridge
//
//  C interface for macOS-specific APIs that Swift cannot reach directly.
//

#ifndef DiskCleanerCoreBridge_h
#define DiskCleanerCoreBridge_h

#include <stdint.h>
#include <stddef.h>

// MARK: - APFS clone identifier

/// Returns the APFS clone identifier for the file at `path`, or 0 if the file
/// has no clone identity (for example, it lives on a non-APFS volume) or the
/// file cannot be queried.
///
/// Files that share a clone identifier share their physical storage on disk,
/// so deleting one of them frees no space.
uint64_t dc_get_clone_id(const char *path);

/// Creates a clone of `source` at `destination` using `clonefile`. Returns 0
/// on success and -1 on failure. Provided primarily so unit tests can build
/// reliable APFS clone fixtures.
int dc_clone_file(const char *source, const char *destination);


// MARK: - Bulk directory enumeration (getattrlistbulk)

/// One entry returned by bulk directory enumeration. All metadata that
/// `DiskScanner` needs to build its tree is filled in by a single system call.
typedef struct {
    /// Null-terminated UTF-8 file name (NAME_MAX is 255 on macOS).
    char name[256];

    /// Non-zero if the entry is a directory.
    uint32_t is_directory;

    /// Non-zero if the entry is a symbolic link.
    uint32_t is_symlink;

    /// Logical file size in bytes (zero for directories).
    int64_t logical_size;

    /// Allocated (on-disk) size in bytes (zero for directories).
    int64_t allocated_size;

    /// APFS clone identifier (0 if not on APFS or not returned).
    uint64_t clone_id;
} DCBulkEntry;

/// Opaque enumeration context.
typedef struct DCBulkContext DCBulkContext;

/// Opens a directory for bulk enumeration. Returns NULL on failure (path is
/// not a directory, cannot be opened, etc.). The returned context must be
/// released with `dc_bulk_close`.
DCBulkContext *dc_bulk_open(const char *path);

/// Reads up to `max_entries` entries from the context into `entries`.
/// Returns:
///   > 0 — number of entries written (caller should call again);
///   0   — no more entries (EOF);
///   -1  — error (caller should fall back to a different enumeration method).
int dc_bulk_next(DCBulkContext *ctx, DCBulkEntry *entries, size_t max_entries);

/// Closes the enumeration context, releasing its file descriptor and buffer.
/// Safe to call with NULL.
void dc_bulk_close(DCBulkContext *ctx);

#endif /* DiskCleanerCoreBridge_h */

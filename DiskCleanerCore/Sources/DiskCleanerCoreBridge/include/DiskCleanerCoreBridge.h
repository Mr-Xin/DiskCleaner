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

#endif /* DiskCleanerCoreBridge_h */

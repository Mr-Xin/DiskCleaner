//
//  DiskCleanerCore.swift
//  DiskCleanerCore
//
//  The UI-agnostic engine behind DiskCleaner: scanning, hashing, duplicate
//  detection, junk rules, application uninstalling and safe deletion.
//
//  Keeping this logic in a standalone Swift package means it can be unit
//  tested without launching the app, and reused (for example by a future
//  command-line tool).
//

/// Namespace and metadata for the DiskCleanerCore module.
public enum DiskCleanerCore {

    /// Semantic version of the core engine.
    public static let version = "0.0.1"
}

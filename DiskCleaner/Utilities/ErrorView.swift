//
//  ErrorView.swift
//  DiskCleaner
//
//  A small reusable error display. Pulls `errorDescription` and
//  `recoverySuggestion` from `LocalizedError` if the underlying error
//  conforms; otherwise falls back to `localizedDescription`.
//

import SwiftUI

struct ErrorView: View {

    let error: any Error
    var onRetry: (() -> Void)? = nil
    var onOpenSettings: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                Text(title)
                    .fontWeight(.medium)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let suggestion {
                Text(suggestion)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if onRetry != nil || onOpenSettings != nil {
                HStack(spacing: 8) {
                    if let onRetry {
                        Button("重试", action: onRetry)
                    }
                    if let onOpenSettings {
                        Button("打开系统设置", action: onOpenSettings)
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
    }

    private var title: String {
        if let localized = error as? LocalizedError, let description = localized.errorDescription {
            return description
        }
        return error.localizedDescription
    }

    private var suggestion: String? {
        (error as? LocalizedError)?.recoverySuggestion
    }
}

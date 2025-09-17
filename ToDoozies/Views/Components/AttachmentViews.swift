//
//  AttachmentViews.swift
//  ToDoozies
//
//  Created by Claude Code on 9/16/25.
//

import SwiftUI

// MARK: - Attachment Row View

struct AttachmentRowView: View {
    let attachment: Attachment
    let onDelete: () -> Void
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // File type icon or thumbnail
            attachmentIcon

            // File info
            VStack(alignment: .leading, spacing: 2) {
                Text(attachment.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(attachment.attachmentType.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(attachment.formattedFileSize)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Actions
            HStack(spacing: 8) {
                Button(action: onTap) {
                    Image(systemName: "eye")
                        .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }

    @ViewBuilder
    private var attachmentIcon: some View {
        if let thumbnailData = attachment.thumbnailData,
           let uiImage = UIImage(data: thumbnailData) {
            // Show thumbnail for images and PDFs
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        } else {
            // Show file type icon
            Image(systemName: attachment.attachmentType.iconName)
                .font(.title2)
                .foregroundColor(iconColor)
                .frame(width: 40, height: 40)
                .background(iconColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }

    private var iconColor: Color {
        switch attachment.attachmentType {
        case .image:
            return .green
        case .document:
            return .blue
        case .audio:
            return .orange
        case .video:
            return .purple
        case .other:
            return .gray
        }
    }
}

// MARK: - Attachment Grid View

struct AttachmentGridView: View {
    let attachments: [Attachment]
    let onDelete: (Attachment) -> Void
    let onAdd: () -> Void
    let onTap: (Attachment) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 120), spacing: 12)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Attachments")
                    .font(.headline)
                    .fontWeight(.medium)

                Spacer()

                Button(action: onAdd) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
                .accessibilityLabel("Add attachment")
            }

            // Content
            if attachments.isEmpty {
                emptyState
            } else {
                attachmentGrid
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "paperclip")
                .font(.title2)
                .foregroundColor(.secondary)

            Text("No attachments")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Button("Add Files", action: onAdd)
                .font(.caption)
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var attachmentGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(attachments, id: \.id) { attachment in
                AttachmentGridCellView(
                    attachment: attachment,
                    onDelete: { onDelete(attachment) },
                    onTap: { onTap(attachment) }
                )
            }
        }
    }
}

// MARK: - Attachment Grid Cell View

struct AttachmentGridCellView: View {
    let attachment: Attachment
    let onDelete: () -> Void
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            // Thumbnail or icon
            ZStack(alignment: .topTrailing) {
                attachmentPreview

                // Delete button
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .background(Color.white, in: Circle())
                }
                .offset(x: 6, y: -6)
            }

            // File name
            Text(attachment.displayName)
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            // File size
            Text(attachment.formattedFileSize)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(width: 100)
        .onTapGesture(perform: onTap)
    }

    @ViewBuilder
    private var attachmentPreview: some View {
        if let thumbnailData = attachment.thumbnailData,
           let uiImage = UIImage(data: thumbnailData) {
            // Show thumbnail
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            // Show file type icon
            Image(systemName: attachment.attachmentType.iconName)
                .font(.title)
                .foregroundColor(iconColor)
                .frame(width: 80, height: 80)
                .background(iconColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private var iconColor: Color {
        switch attachment.attachmentType {
        case .image:
            return .green
        case .document:
            return .blue
        case .audio:
            return .orange
        case .video:
            return .purple
        case .other:
            return .gray
        }
    }
}

// MARK: - Compact Attachment List View

struct CompactAttachmentListView: View {
    let attachments: [Attachment]
    let onDelete: (Attachment) -> Void
    let onAdd: () -> Void
    let onTap: (Attachment) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Text("Attachments")
                    .font(.headline)
                    .fontWeight(.medium)

                Spacer()

                if !attachments.isEmpty {
                    Text("\(attachments.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Button(action: onAdd) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
                .accessibilityLabel("Add attachment")
            }

            // Content
            if attachments.isEmpty {
                Text("No attachments")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                VStack(spacing: 8) {
                    ForEach(attachments, id: \.id) { attachment in
                        AttachmentRowView(
                            attachment: attachment,
                            onDelete: { onDelete(attachment) },
                            onTap: { onTap(attachment) }
                        )

                        if attachment.id != attachments.last?.id {
                            Divider()
                        }
                    }
                }
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

// MARK: - Attachment Preview View

struct AttachmentPreviewView: View {
    let attachment: Attachment
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Large preview
                if let thumbnailData = attachment.thumbnailData,
                   let uiImage = UIImage(data: thumbnailData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    Image(systemName: attachment.attachmentType.iconName)
                        .font(.system(size: 80))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: 200)
                }

                // File info
                VStack(spacing: 8) {
                    Text(attachment.displayName)
                        .font(.title2)
                        .fontWeight(.semibold)

                    HStack(spacing: 16) {
                        Label(attachment.attachmentType.displayName, systemImage: attachment.attachmentType.iconName)
                        Label(attachment.formattedFileSize, systemImage: "doc.text")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }

                Spacer()

                // Actions
                if let localURL = attachment.localURL {
                    ShareLink(item: URL(fileURLWithPath: localURL)) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .navigationTitle("Attachment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Attachment Row") {
    let sampleAttachment = Attachment(
        fileName: "sample-document.pdf",
        fileExtension: "pdf",
        mimeType: "application/pdf",
        fileSize: 2_048_576,
        localURL: "/path/to/file.pdf"
    )

    return AttachmentRowView(
        attachment: sampleAttachment,
        onDelete: {},
        onTap: {}
    )
    .padding()
}

#Preview("Attachment Grid") {
    let sampleAttachments = [
        Attachment(
            fileName: "document.pdf",
            fileExtension: "pdf",
            mimeType: "application/pdf",
            fileSize: 1_024_000
        ),
        Attachment(
            fileName: "image.jpg",
            fileExtension: "jpg",
            mimeType: "image/jpeg",
            fileSize: 512_000
        ),
        Attachment(
            fileName: "audio.mp3",
            fileExtension: "mp3",
            mimeType: "audio/mpeg",
            fileSize: 3_072_000
        )
    ]

    return AttachmentGridView(
        attachments: sampleAttachments,
        onDelete: { _ in },
        onAdd: {},
        onTap: { _ in }
    )
    .padding()
}
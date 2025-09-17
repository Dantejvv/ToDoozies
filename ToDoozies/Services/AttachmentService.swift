//
//  AttachmentService.swift
//  ToDoozies
//
//  Created by Claude Code on 9/16/25.
//

import Foundation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers
import PDFKit

// MARK: - Attachment Error Types

enum AttachmentError: LocalizedError {
    case accessDenied
    case fileTooLarge(maxSize: Int64)
    case unsupportedFileType
    case copyFailed
    case thumbnailGenerationFailed
    case directoryCreationFailed
    case invalidURL

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Unable to access the selected file. Please try again."
        case .fileTooLarge(let maxSize):
            return "File is too large. Maximum size is \(ByteCountFormatter.string(fromByteCount: maxSize, countStyle: .file))."
        case .unsupportedFileType:
            return "This file type is not supported."
        case .copyFailed:
            return "Failed to save the file. Please try again."
        case .thumbnailGenerationFailed:
            return "Could not generate thumbnail for this file."
        case .directoryCreationFailed:
            return "Failed to create attachments directory."
        case .invalidURL:
            return "Invalid file location."
        }
    }
}

// MARK: - Attachment Service Protocol

protocol AttachmentServiceProtocol {
    func createAttachment(from url: URL, for task: Task) async throws -> Attachment
    func deleteAttachment(_ attachment: Attachment) async throws
    func generateThumbnail(for attachment: Attachment) async throws -> Data?
    nonisolated func getSupportedContentTypes() -> [UTType]
    nonisolated func getFileSizeLimit(for type: AttachmentType) -> Int64
}

// MARK: - Attachment Service Implementation

@MainActor
final class AttachmentService: AttachmentServiceProtocol {
    private let modelContext: ModelContext
    private let fileManager = FileManager.default
    private let appState: AppState
    weak var diContainer: DIContainer?

    // File size limits (in bytes)
    private enum FileSizeLimit {
        static let image: Int64 = 25 * 1024 * 1024      // 25MB
        static let document: Int64 = 50 * 1024 * 1024    // 50MB
        static let audio: Int64 = 100 * 1024 * 1024      // 100MB
        static let video: Int64 = 100 * 1024 * 1024      // 100MB
        static let other: Int64 = 50 * 1024 * 1024       // 50MB
    }

    init(modelContext: ModelContext, appState: AppState) {
        self.modelContext = modelContext
        self.appState = appState
    }

    // MARK: - Public Methods

    func createAttachment(from url: URL, for task: Task) async throws -> Attachment {
        // Validate file access
        guard url.startAccessingSecurityScopedResource() else {
            throw AttachmentError.accessDenied
        }

        defer { url.stopAccessingSecurityScopedResource() }

        // Get file attributes
        let fileAttributes = try fileManager.attributesOfItem(atPath: url.path)
        guard let fileSize = fileAttributes[.size] as? Int64 else {
            throw AttachmentError.invalidURL
        }

        // Extract file information
        let fileName = url.lastPathComponent
        let fileExtension = url.pathExtension.lowercased()

        // Determine MIME type
        let mimeType = getMimeType(for: url)
        let attachmentType = AttachmentType.from(mimeType: mimeType, fileExtension: fileExtension)

        // Validate file size
        let sizeLimit = getFileSizeLimit(for: attachmentType)
        guard fileSize <= sizeLimit else {
            throw AttachmentError.fileTooLarge(maxSize: sizeLimit)
        }

        // Copy file to app directory
        let destinationURL = try await copyFileToAppDirectory(url, for: task.id)

        // Create attachment model
        let attachment = Attachment(
            fileName: fileName,
            fileExtension: fileExtension,
            mimeType: mimeType,
            fileSize: fileSize,
            localURL: destinationURL.path,
            parentTask: task
        )

        // Generate thumbnail if applicable
        if attachmentType == .image || attachmentType == .document {
            do {
                attachment.thumbnailData = try await generateThumbnail(for: attachment)
            } catch {
                // Thumbnail generation is not critical, log but continue
                print("Warning: Failed to generate thumbnail for \(fileName): \(error)")
            }
        }

        // Save to context
        modelContext.insert(attachment)
        try modelContext.save()

        // Add to task
        task.addAttachment(attachment)
        try modelContext.save()

        // Track offline change
        trackOfflineChange()

        return attachment
    }

    func deleteAttachment(_ attachment: Attachment) async throws {
        // Delete file from filesystem
        if let localURL = attachment.localURL {
            let fileURL = URL(fileURLWithPath: localURL)
            try? fileManager.removeItem(at: fileURL)

            // Delete thumbnail if exists
            let thumbnailURL = getThumbnailURL(for: attachment)
            try? fileManager.removeItem(at: thumbnailURL)
        }

        // Remove from task
        attachment.parentTask?.removeAttachment(attachment)

        // Delete from context
        modelContext.delete(attachment)
        try modelContext.save()

        // Track offline change
        trackOfflineChange()
    }

    func generateThumbnail(for attachment: Attachment) async throws -> Data? {
        guard let localURL = attachment.localURL else { return nil }
        let fileURL = URL(fileURLWithPath: localURL)

        switch attachment.attachmentType {
        case .image:
            return try await generateImageThumbnail(from: fileURL)
        case .document where attachment.fileExtension == "pdf":
            return try await generatePDFThumbnail(from: fileURL)
        default:
            return nil
        }
    }

    nonisolated func getSupportedContentTypes() -> [UTType] {
        return [
            // Images
            .image, .jpeg, .png, .heic, .gif, .bmp, .tiff, .webP,

            // Documents
            .pdf, .plainText, .rtf, .html,

            // Microsoft Office
            .item, // For .docx, .xlsx, .pptx

            // Audio
            .audio, .mp3, .wav, .aiff,

            // Video
            .movie, .quickTimeMovie, .avi,

            // Other
            .data, .item
        ]
    }

    nonisolated func getFileSizeLimit(for type: AttachmentType) -> Int64 {
        switch type {
        case .image:
            return FileSizeLimit.image
        case .document:
            return FileSizeLimit.document
        case .audio:
            return FileSizeLimit.audio
        case .video:
            return FileSizeLimit.video
        case .other:
            return FileSizeLimit.other
        }
    }

    // MARK: - Private Methods

    private func copyFileToAppDirectory(_ sourceURL: URL, for taskId: UUID) async throws -> URL {
        // Create attachments directory structure
        let attachmentsDir = try getAttachmentsDirectory()
        let taskDir = attachmentsDir.appendingPathComponent(taskId.uuidString)

        // Create task directory if it doesn't exist
        if !fileManager.fileExists(atPath: taskDir.path) {
            try fileManager.createDirectory(at: taskDir, withIntermediateDirectories: true)
        }

        // Generate unique filename to avoid conflicts
        let fileName = sourceURL.lastPathComponent
        let fileExtension = sourceURL.pathExtension
        let baseName = fileName.replacingOccurrences(of: ".\(fileExtension)", with: "")

        var destinationURL = taskDir.appendingPathComponent(fileName)
        var counter = 1

        while fileManager.fileExists(atPath: destinationURL.path) {
            let newFileName = "\(baseName)_\(counter).\(fileExtension)"
            destinationURL = taskDir.appendingPathComponent(newFileName)
            counter += 1
        }

        // Copy the file
        try fileManager.copyItem(at: sourceURL, to: destinationURL)

        return destinationURL
    }

    private func getAttachmentsDirectory() throws -> URL {
        guard let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw AttachmentError.directoryCreationFailed
        }

        let attachmentsDir = documentsDir.appendingPathComponent("Attachments")

        if !fileManager.fileExists(atPath: attachmentsDir.path) {
            try fileManager.createDirectory(at: attachmentsDir, withIntermediateDirectories: true)
        }

        return attachmentsDir
    }

    private func getThumbnailURL(for attachment: Attachment) -> URL {
        guard let localURL = attachment.localURL else {
            return URL(fileURLWithPath: "")
        }

        let fileURL = URL(fileURLWithPath: localURL)
        let directory = fileURL.deletingLastPathComponent()
        let thumbnailsDir = directory.appendingPathComponent("thumbnails")

        // Create thumbnails directory if needed
        try? fileManager.createDirectory(at: thumbnailsDir, withIntermediateDirectories: true)

        return thumbnailsDir.appendingPathComponent("\(attachment.id.uuidString).jpg")
    }

    private func generateImageThumbnail(from url: URL) async throws -> Data? {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                guard let imageData = try? Data(contentsOf: url),
                      let image = UIImage(data: imageData) else {
                    continuation.resume(throwing: AttachmentError.thumbnailGenerationFailed)
                    return
                }

                // Generate thumbnail (200x200 max)
                let thumbnailSize = CGSize(width: 200, height: 200)
                let thumbnail = image.preparingThumbnail(of: thumbnailSize)

                guard let thumbnail = thumbnail,
                      let thumbnailData = thumbnail.jpegData(compressionQuality: 0.8) else {
                    continuation.resume(throwing: AttachmentError.thumbnailGenerationFailed)
                    return
                }

                continuation.resume(returning: thumbnailData)
            }
        }
    }

    private func generatePDFThumbnail(from url: URL) async throws -> Data? {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                guard let pdfDocument = PDFDocument(url: url),
                      let firstPage = pdfDocument.page(at: 0) else {
                    continuation.resume(throwing: AttachmentError.thumbnailGenerationFailed)
                    return
                }

                let pageRect = firstPage.bounds(for: .mediaBox)
                let renderer = UIGraphicsImageRenderer(size: CGSize(width: 200, height: 200 * pageRect.height / pageRect.width))

                let thumbnail = renderer.image { context in
                    UIColor.white.set()
                    context.fill(CGRect(origin: .zero, size: renderer.format.bounds.size))

                    context.cgContext.translateBy(x: 0, y: renderer.format.bounds.height)
                    context.cgContext.scaleBy(x: 1, y: -1)
                    context.cgContext.scaleBy(x: renderer.format.bounds.width / pageRect.width,
                                            y: renderer.format.bounds.height / pageRect.height)

                    firstPage.draw(with: .mediaBox, to: context.cgContext)
                }

                guard let thumbnailData = thumbnail.jpegData(compressionQuality: 0.8) else {
                    continuation.resume(throwing: AttachmentError.thumbnailGenerationFailed)
                    return
                }

                continuation.resume(returning: thumbnailData)
            }
        }
    }

    private func getMimeType(for url: URL) -> String {
        if let type = UTType(filenameExtension: url.pathExtension)?.preferredMIMEType {
            return type
        }
        return "application/octet-stream"
    }

    private func trackOfflineChange() {
        diContainer?.trackOfflineChange()
    }
}
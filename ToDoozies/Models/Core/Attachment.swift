//
//  Attachment.swift
//  ToDoozies
//
//  Created by Dante Vercelli on 9/14/25.
//

import Foundation
import SwiftData
import CloudKit
import UniformTypeIdentifiers

@Model
final class Attachment {
    var id: UUID
    var fileName: String
    var fileExtension: String
    var mimeType: String
    var fileSize: Int64
    var localURL: String?
    var cloudURL: String?
    var thumbnailData: Data?
    var createdDate: Date
    var modifiedDate: Date

    var parentTask: Task?

    init(
        fileName: String,
        fileExtension: String,
        mimeType: String,
        fileSize: Int64,
        localURL: String? = nil,
        parentTask: Task? = nil
    ) {
        self.id = UUID()
        self.fileName = fileName
        self.fileExtension = fileExtension
        self.mimeType = mimeType
        self.fileSize = fileSize
        self.localURL = localURL
        self.cloudURL = nil
        self.thumbnailData = nil
        self.createdDate = Date()
        self.modifiedDate = Date()
        self.parentTask = parentTask
    }

    var attachmentType: AttachmentType {
        AttachmentType.from(mimeType: mimeType, fileExtension: fileExtension)
    }

    var formattedFileSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }

    var isImage: Bool {
        attachmentType == .image
    }

    var isDocument: Bool {
        attachmentType == .document
    }

    var displayName: String {
        fileName.isEmpty ? "Untitled" : fileName
    }

    func updateModifiedDate() {
        modifiedDate = Date()
    }
}

// MARK: - AttachmentType Enum
enum AttachmentType: String, CaseIterable, Codable {
    case image = "image"
    case document = "document"
    case audio = "audio"
    case video = "video"
    case other = "other"

    static func from(mimeType: String, fileExtension: String) -> AttachmentType {
        let type = mimeType.lowercased()
        let ext = fileExtension.lowercased()

        if type.hasPrefix("image/") || ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "webp", "heic"].contains(ext) {
            return .image
        } else if type.hasPrefix("audio/") || ["mp3", "wav", "aac", "flac", "m4a"].contains(ext) {
            return .audio
        } else if type.hasPrefix("video/") || ["mp4", "mov", "avi", "mkv", "wmv"].contains(ext) {
            return .video
        } else if type.hasPrefix("text/") || type.contains("document") ||
                  ["pdf", "doc", "docx", "txt", "rtf", "pages"].contains(ext) {
            return .document
        } else {
            return .other
        }
    }

    var displayName: String {
        switch self {
        case .image: return "Image"
        case .document: return "Document"
        case .audio: return "Audio"
        case .video: return "Video"
        case .other: return "File"
        }
    }

    var iconName: String {
        switch self {
        case .image: return "photo"
        case .document: return "doc.text"
        case .audio: return "music.note"
        case .video: return "video"
        case .other: return "paperclip"
        }
    }
}
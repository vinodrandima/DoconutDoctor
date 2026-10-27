//
//  FirestoreScanRepository.swift
//  CoconutDoctor
//
//  Cloud repository implementation for backing up and synchronizing scans to Cloud Firestore.
//  Target path: users/{uid}/scans/{scanId}
//

import Foundation
import FirebaseCore
import FirebaseFirestore

@MainActor
public final class FirestoreScanRepository: ScanRepositoryProtocol, @unchecked Sendable {
    private let db: Firestore?
    public var currentUID: String?
    
    public init(uid: String? = nil) {
        self.currentUID = uid
        if FirebaseApp.allApps?.isEmpty == false {
            self.db = Firestore.firestore()
        } else {
            self.db = nil
        }
    }
    
    // MARK: - Collection Reference
    
    private func scansCollection(for uid: String) throws -> CollectionReference {
        guard let db = db else {
            throw AuthError.firebaseNotConfigured
        }
        return db.collection("users").document(uid).collection("scans")
    }
    
    // MARK: - ScanRepositoryProtocol Implementation
    
    public func fetchAll() async throws -> [ScanRecord] {
        guard let uid = currentUID else {
            return []
        }
        let collection = try scansCollection(for: uid)
        let snapshot = try await collection.order(by: "timestamp", descending: true).getDocuments()
        
        return snapshot.documents.compactMap { doc in
            parseDocument(doc)
        }
    }
    
    public func save(_ scan: ScanRecord) async throws {
        guard let uid = currentUID else {
            throw AuthError.unauthenticated
        }
        let collection = try scansCollection(for: uid)
        let docRef = collection.document(scan.id.uuidString)
        let data = serializeScan(scan)
        try await docRef.setData(data, merge: true)
    }
    
    public func delete(id: UUID) async throws {
        guard let uid = currentUID else {
            throw AuthError.unauthenticated
        }
        let collection = try scansCollection(for: uid)
        try await collection.document(id.uuidString).delete()
    }
    
    public func deleteAll() async throws {
        guard let uid = currentUID else {
            throw AuthError.unauthenticated
        }
        let collection = try scansCollection(for: uid)
        let snapshot = try await collection.getDocuments()
        for doc in snapshot.documents {
            try await doc.reference.delete()
        }
    }
    
    public func fetchUnsynced() async throws -> [ScanRecord] {
        // Remote Firestore documents are already considered synced
        return []
    }
    
    public func markAsSynced(id: UUID) async throws {
        // No-op for remote store
    }
    
    public func saveFromRemote(_ scan: ScanRecord) async throws {
        try await save(scan)
    }
    
    // MARK: - Real-Time Remote Listener
    
    public func listenToRemoteScans(
        uid: String,
        onChange: @escaping @Sendable ([ScanRecord]) -> Void
    ) -> ListenerRegistration? {
        guard let collection = try? scansCollection(for: uid) else {
            return nil
        }
        
        return collection.addSnapshotListener { snapshot, error in
            guard let snapshot = snapshot, error == nil else {
                return
            }
            
            let records = snapshot.documents.compactMap { self.parseDocument($0) }
            onChange(records)
        }
    }
    
    // MARK: - Serialization Helpers
    
    private func serializeScan(_ scan: ScanRecord) -> [String: Any] {
        var dict: [String: Any] = [
            "id": scan.id.uuidString,
            "timestamp": Timestamp(date: scan.timestamp),
            "diseaseLabel": scan.diseaseLabel,
            "confidence": scan.confidence,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        if let lat = scan.latitude {
            dict["latitude"] = lat
        }
        if let lon = scan.longitude {
            dict["longitude"] = lon
        }
        if let treatment = scan.treatmentSnapshot {
            dict["treatmentSnapshot"] = treatment
        }
        if let notes = scan.notes {
            dict["notes"] = notes
        }
        if let imagePath = scan.imagePath {
            dict["imagePath"] = imagePath
        }
        if let thumbnailData = scan.imageThumbnail {
            dict["imageThumbnailBase64"] = thumbnailData.base64EncodedString()
        }
        
        return dict
    }
    
    private func parseDocument(_ doc: DocumentSnapshot) -> ScanRecord? {
        guard let data = doc.data() else { return nil }
        
        let idString = data["id"] as? String ?? doc.documentID
        guard let id = UUID(uuidString: idString) else { return nil }
        
        let timestamp: Date
        if let ts = data["timestamp"] as? Timestamp {
            timestamp = ts.dateValue()
        } else if let date = data["timestamp"] as? Date {
            timestamp = date
        } else {
            timestamp = Date()
        }
        
        let diseaseLabel = data["diseaseLabel"] as? String ?? DiseaseType.healthy.rawValue
        let confidence = data["confidence"] as? Double ?? 0.0
        let latitude = data["latitude"] as? Double
        let longitude = data["longitude"] as? Double
        let treatmentSnapshot = data["treatmentSnapshot"] as? String
        let notes = data["notes"] as? String
        let imagePath = data["imagePath"] as? String
        
        var thumbnailData: Data? = nil
        if let base64 = data["imageThumbnailBase64"] as? String {
            thumbnailData = Data(base64Encoded: base64)
        }
        
        return ScanRecord(
            id: id,
            timestamp: timestamp,
            diseaseLabel: diseaseLabel,
            confidence: confidence,
            latitude: latitude,
            longitude: longitude,
            imageThumbnail: thumbnailData,
            treatmentSnapshot: treatmentSnapshot,
            notes: notes,
            imagePath: imagePath,
            isSynced: true
        )
    }
}

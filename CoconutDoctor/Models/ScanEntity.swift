//
//  ScanEntity.swift
//  CoconutDoctor
//
//  Core Data NSManagedObject representing an offline coconut leaf diagnosis record.
//

import Foundation
import CoreData

@objc(ScanEntity)
public class ScanEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var timestamp: Date?
    @NSManaged public var diseaseLabel: String?
    @NSManaged public var confidence: Double
    @NSManaged public var latitude: NSNumber?
    @NSManaged public var longitude: NSNumber?
    @NSManaged public var imageThumbnail: Data?
    @NSManaged public var treatmentSnapshot: String?
    @NSManaged public var isSynced: Bool
}

extension ScanEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ScanEntity> {
        return NSFetchRequest<ScanEntity>(entityName: "ScanEntity")
    }
    
    public var coordinateLatitude: Double? {
        get { latitude?.doubleValue }
        set { latitude = newValue.map { NSNumber(value: $0) } }
    }
    
    public var coordinateLongitude: Double? {
        get { longitude?.doubleValue }
        set { longitude = newValue.map { NSNumber(value: $0) } }
    }
    
    public func toRecord() -> ScanRecord {
        let label = diseaseLabel ?? DiseaseType.healthy.rawValue
        return ScanRecord(
            id: id ?? UUID(),
            timestamp: timestamp ?? Date(),
            diseaseLabel: label,
            confidence: confidence,
            latitude: coordinateLatitude,
            longitude: coordinateLongitude,
            imageThumbnail: imageThumbnail,
            treatmentSnapshot: treatmentSnapshot,
            isSynced: isSynced
        )
    }
    
    public func update(from record: ScanRecord) {
        self.id = record.id
        self.timestamp = record.timestamp
        self.diseaseLabel = record.diseaseLabel
        self.confidence = record.confidence
        self.coordinateLatitude = record.latitude
        self.coordinateLongitude = record.longitude
        self.imageThumbnail = record.imageThumbnail
        self.treatmentSnapshot = record.treatmentSnapshot
        self.isSynced = record.isSynced
    }
}

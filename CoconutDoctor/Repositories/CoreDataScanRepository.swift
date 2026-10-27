//
//  CoreDataScanRepository.swift
//  CoconutDoctor
//
//  Offline Core Data repository implementation for coconut leaf scan history.
//

import Foundation
import CoreData

public final class CoreDataScanRepository: ScanRepositoryProtocol, @unchecked Sendable {
    public let container: NSPersistentContainer
    
    public init(inMemory: Bool = false) {
        let model = Self.resolveManagedObjectModel()
        let persistentContainer = NSPersistentContainer(name: "CoconutDoctor", managedObjectModel: model)
        
        if inMemory {
            let description = NSPersistentStoreDescription()
            description.url = URL(fileURLWithPath: "/dev/null")
            persistentContainer.persistentStoreDescriptions = [description]
        }
        
        persistentContainer.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                print("CoreDataScanRepository: Failed to load persistent store: \(error), \(error.userInfo)")
            }
        }
        
        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
        persistentContainer.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        self.container = persistentContainer
    }
    
    // MARK: - ScanRepositoryProtocol Implementation
    
    public func fetchAll() async throws -> [ScanRecord] {
        let context = container.viewContext
        return try await context.perform {
            let request: NSFetchRequest<ScanEntity> = ScanEntity.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
            let entities = try context.fetch(request)
            return entities.compactMap { $0.toRecord() }
        }
    }
    
    public func fetchUnsynced() async throws -> [ScanRecord] {
        let context = container.viewContext
        return try await context.perform {
            let request: NSFetchRequest<ScanEntity> = ScanEntity.fetchRequest()
            request.predicate = NSPredicate(format: "isSynced == NO OR isSynced == nil")
            request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
            let entities = try context.fetch(request)
            return entities.compactMap { $0.toRecord() }
        }
    }
    
    public func markAsSynced(id: UUID) async throws {
        let context = container.viewContext
        try await context.perform {
            let request: NSFetchRequest<ScanEntity> = ScanEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            if let entity = try context.fetch(request).first {
                entity.isSynced = true
                if context.hasChanges {
                    try context.save()
                }
            }
        }
    }
    
    public func saveFromRemote(_ scan: ScanRecord) async throws {
        let context = container.viewContext
        try await context.perform {
            let request: NSFetchRequest<ScanEntity> = ScanEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", scan.id as CVarArg)
            request.fetchLimit = 1
            
            let existing = try context.fetch(request).first
            let entity = existing ?? ScanEntity(context: context)
            entity.update(from: scan)
            entity.isSynced = true // Mark as synced so we do not re-upload what we just downloaded
            
            if context.hasChanges {
                try context.save()
            }
        }
    }
    
    public func save(_ scan: ScanRecord) async throws {
        let context = container.viewContext
        try await context.perform {
            let request: NSFetchRequest<ScanEntity> = ScanEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", scan.id as CVarArg)
            request.fetchLimit = 1
            
            let existing = try context.fetch(request).first
            let entity = existing ?? ScanEntity(context: context)
            entity.update(from: scan)
            
            if context.hasChanges {
                try context.save()
            }
        }
    }
    
    public func delete(id: UUID) async throws {
        let context = container.viewContext
        try await context.perform {
            let request: NSFetchRequest<ScanEntity> = ScanEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            let matchingEntities = try context.fetch(request)
            for entity in matchingEntities {
                context.delete(entity)
            }
            if context.hasChanges {
                try context.save()
            }
        }
    }
    
    public func deleteAll() async throws {
        let context = container.viewContext
        try await context.perform {
            let request: NSFetchRequest<ScanEntity> = ScanEntity.fetchRequest()
            let allEntities = try context.fetch(request)
            for entity in allEntities {
                context.delete(entity)
            }
            if context.hasChanges {
                try context.save()
            }
        }
    }
    
    // MARK: - Model Resolution Helper
    
    private static func resolveManagedObjectModel() -> NSManagedObjectModel {
        let candidateBundles = [Bundle.main, Bundle(for: ScanEntity.self)] + Bundle.allBundles
        for bundle in candidateBundles {
            if let modelURL = bundle.url(forResource: "CoconutDoctor", withExtension: "momd"),
               let model = NSManagedObjectModel(contentsOf: modelURL),
               !model.entities.isEmpty {
                return model
            }
        }
        
        if let merged = NSManagedObjectModel.mergedModel(from: candidateBundles), !merged.entities.isEmpty {
            return merged
        }
        
        let model = NSManagedObjectModel()
        let entity = NSEntityDescription()
        entity.name = "ScanEntity"
        entity.managedObjectClassName = NSStringFromClass(ScanEntity.self)
        
        let idAttr = NSAttributeDescription()
        idAttr.name = "id"
        idAttr.attributeType = .UUIDAttributeType
        idAttr.isOptional = false
        
        let timestampAttr = NSAttributeDescription()
        timestampAttr.name = "timestamp"
        timestampAttr.attributeType = .dateAttributeType
        timestampAttr.isOptional = false
        
        let diseaseLabelAttr = NSAttributeDescription()
        diseaseLabelAttr.name = "diseaseLabel"
        diseaseLabelAttr.attributeType = .stringAttributeType
        diseaseLabelAttr.isOptional = false
        
        let confidenceAttr = NSAttributeDescription()
        confidenceAttr.name = "confidence"
        confidenceAttr.attributeType = .doubleAttributeType
        confidenceAttr.isOptional = false
        confidenceAttr.defaultValue = 0.0
        
        let latAttr = NSAttributeDescription()
        latAttr.name = "latitude"
        latAttr.attributeType = .doubleAttributeType
        latAttr.isOptional = true
        
        let lonAttr = NSAttributeDescription()
        lonAttr.name = "longitude"
        lonAttr.attributeType = .doubleAttributeType
        lonAttr.isOptional = true
        
        let imageAttr = NSAttributeDescription()
        imageAttr.name = "imageThumbnail"
        imageAttr.attributeType = .binaryDataAttributeType
        imageAttr.isOptional = true
        imageAttr.allowsExternalBinaryDataStorage = true
        
        let treatmentAttr = NSAttributeDescription()
        treatmentAttr.name = "treatmentSnapshot"
        treatmentAttr.attributeType = .stringAttributeType
        treatmentAttr.isOptional = true
        
        let isSyncedAttr = NSAttributeDescription()
        isSyncedAttr.name = "isSynced"
        isSyncedAttr.attributeType = .booleanAttributeType
        isSyncedAttr.isOptional = true
        isSyncedAttr.defaultValue = false
        
        entity.properties = [idAttr, timestampAttr, diseaseLabelAttr, confidenceAttr, latAttr, lonAttr, imageAttr, treatmentAttr, isSyncedAttr]
        model.entities = [entity]
        return model
    }
}

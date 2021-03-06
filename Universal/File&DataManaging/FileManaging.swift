//
//  FileManaging.swift
//  BirthdayReminder
//
//  Created by CaptainHikigayaHachiman on 17/06/2017.
//Copyright © 2017 CaptainHikigayaHachiman. All rights reserved.
//

import Foundation
import UIKit
import CoreData


// Core Data Persisting

public final class PeopleToSave: ManagedObject {
    
    @NSManaged public private(set) var name: String
    @NSManaged public private(set) var birth: String
    @NSManaged public private(set) var picData: Data?
    @NSManaged public var shouldSync: Bool
    
    static func insert(into context:NSManagedObjectContext, name: String, birth: String, picData: Data?) {
        let entity = NSEntityDescription.entity(forEntityName: entityName, in: context)
        let person = NSManagedObject(entity: entity!, insertInto: context)
        person.setValue(name, forKey: "name")
        person.setValue(birth, forKey: "birth")
        person.setValue(picData, forKey: "picData")
        
        do {
            try context.save()
        } catch {
            fatalError("Failed to save: \(error)")
        }
    }
    
}

extension PeopleToSave: ManagedObjectType {
    
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(key: "name", ascending: false)]
    }
    
    public static var entityName: String {
        return "People"
    }
    
    public static var sortedFetchRequest: NSFetchRequest<PeopleToSave> {
        let request = NSFetchRequest<PeopleToSave>(entityName: "People")
        request.sortDescriptors = defaultSortDescriptors
        return request
    }
}

public class ManagedObject: NSManagedObject {
    
}

private let storeUrl = FileManager().containerURL(forSecurityApplicationGroupIdentifier: "group.tech.tcwq.birthdayreminder")?.appendingPathComponent("Data.br")

public func createDataMainContext() -> NSManagedObjectContext {
    let bundles = [Bundle(for: PeopleToSave.self)]
    guard let model = NSManagedObjectModel.mergedModel(from: bundles) else {
        fatalError("Model not found")
    }
    let psc = NSPersistentStoreCoordinator(managedObjectModel: model)
    try! psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeUrl, options: nil)
    let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    context.persistentStoreCoordinator = psc
    return context
}

@objc(PeopleToTransfer)

class PeopleToTransfer: NSObject, NSCoding {
    var name: String
    var birth: String
    var picData: Data?
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: "name")
        aCoder.encode(birth, forKey: "birth")
        aCoder.encode(picData, forKey: "picData")
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.name = aDecoder.decodeObject(forKey: "name") as! String
        self.birth = aDecoder.decodeObject(forKey: "birth") as! String
        self.picData = aDecoder.decodeObject(forKey: "picData") as! Data?
    }
    
    init(withName: String,birth: String,picData: Data?) {
        self.name = withName
        self.birth = birth
        self.picData = picData
    }
    
    public var encoded: Data {
        return NSKeyedArchiver.archivedData(withRootObject: self)
    }
    
}

extension Data {
    func toPeopleToTransfer() -> PeopleToTransfer? {
        return NSKeyedUnarchiver.unarchiveObject(with: self) as? PeopleToTransfer
    }
}

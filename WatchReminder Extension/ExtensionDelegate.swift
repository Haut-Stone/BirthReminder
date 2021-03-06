//
//  ExtensionDelegate.swift
//  WatchReminder Extension
//
//  Created by Jacky Yu on 25/07/2017.
//  Copyright © 2017 CaptainYukinoshitaHachiman. All rights reserved.
//

import WatchKit
import WatchConnectivity
import CoreData

class ExtensionDelegate: NSObject , WKExtensionDelegate , WCSessionDelegate {
    
    var context = createDataMainContext()
    let request = PeopleToSave.sortedFetchRequest
    var reloadController = ReloadController()
    
    func applicationDidFinishLaunching() {
        //Watch Connectivity Configuration
        let session = WCSession.default
        session.delegate = self
        session.activate()
        
        let defaults = UserDefaults()
        defaults.set(true, forKey: "startup")
    }
    
    func applicationDidBecomeActive() {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillResignActive() {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, etc.
    }
    
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        // Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.
        for task in backgroundTasks {
            // Use a switch statement to check the task type
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                // Be sure to complete the background task once you’re done.
                backgroundTask.setTaskCompletedWithSnapshot(false)
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                // Snapshot tasks have a unique completion call, make sure to set your expiration date
                snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date.distantFuture, userInfo: nil)
            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                // Be sure to complete the connectivity task once you’re done.
                connectivityTask.setTaskCompletedWithSnapshot(false)
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                // Be sure to complete the URL session task once you’re done.
                urlSessionTask.setTaskCompletedWithSnapshot(false)
            default:
                // make sure to complete unhandled task types
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    
    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        print("Got file")
        let defaults = UserDefaults()
        defaults.set(true, forKey: "dataBaseIsUpdated")
        
        try! context.fetch(request).forEach { object in
            context.delete(object)
        } //Delete all the previous objects
        
        (NSKeyedUnarchiver.unarchiveObject(withFile: file.fileURL.path) as! [PeopleToTransfer]).forEach { person in
            PeopleToSave.insert(into: context, name: person.name, birth: person.birth, picData: person.picData)
        } //Add new objects
        
        reloadController.reload()
        
        //Update the complications
        let server = CLKComplicationServer.sharedInstance()
        server.activeComplications?.forEach { complication in
            server.reloadTimeline(for: complication)
        }
    }
    
}

public class ReloadController {
    
    private var reloadControllerDelegate: ReloadControllerDelegate?
    var delegate: ReloadControllerDelegate? {
        get {
            return reloadControllerDelegate
        }
        
        set {
            reloadControllerDelegate = newValue
        }
    }
    
    func reload() {
        delegate?.reload()
    }
    
}

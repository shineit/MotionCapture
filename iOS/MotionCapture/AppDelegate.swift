//
//  AppDelegate.swift
//  MotionCapture
//
//  Created by Jessica Yeh on 8/15/15.
//  Copyright (c) 2015 Yeh. All rights reserved.
//

import UIKit
import ApplicationInsights
import Parse
import Bolts

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var band: MSBClient?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        // Setup and start Application Insights
        MSAIApplicationInsights.setup()
        MSAIApplicationInsights.start()
        
        // Setup Parse for push notifications
        Parse.setApplicationId("6kLHABpe2RCK40YYE9i0F1Dlz9SOQ1JQdsCz7KfH",
            clientKey: "mQ8SBTiBzBXDus7N1C2yJCJygwuHgFixtZrHvU1l")
        
        // Register for Push Notitications
        if application.applicationState != UIApplicationState.Background {
            // Track an app open here if we launch with a push, unless
            // "content_available" was used to trigger a background push (introduced in iOS 7).
            // In that case, we skip tracking here to avoid double counting the app-open.
            
            let preBackgroundPush = !application.respondsToSelector("backgroundRefreshStatus")
            let oldPushHandlerOnly = !self.respondsToSelector("application:didReceiveRemoteNotification:fetchCompletionHandler:")
            var pushPayload = false
            if let options = launchOptions {
                pushPayload = options[UIApplicationLaunchOptionsRemoteNotificationKey] != nil
            }
            if (preBackgroundPush || oldPushHandlerOnly || pushPayload) {
                PFAnalytics.trackAppOpenedWithLaunchOptions(launchOptions)
            }
        }
        if application.respondsToSelector("registerUserNotificationSettings:") {
            let userNotificationTypes = UIUserNotificationType.Alert | UIUserNotificationType.Badge | UIUserNotificationType.Sound
            let settings = UIUserNotificationSettings(forTypes: userNotificationTypes, categories: nil)
            application.registerUserNotificationSettings(settings)
            application.registerForRemoteNotifications()
        } else {
            let types = UIRemoteNotificationType.Badge | UIRemoteNotificationType.Alert | UIRemoteNotificationType.Sound
            application.registerForRemoteNotificationTypes(types)
        }
        
        // Connect to Microsoft Band
        let clients = MSBClientManager.sharedManager().attachedClients()
        self.band = clients.first as? MSBClient
        if let band = self.band {
            MSBClientManager.sharedManager().connectClient(self.band)
            println("[MSB] Connecting to Band...")
        } else {
            println("[MSB] No Bands attached.")
        }
        
        return true
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        let installation = PFInstallation.currentInstallation()
        installation.setDeviceTokenFromData(deviceToken)
        installation.saveInBackground()
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        if error.code == 3010 {
            println("Push notifications are not supported in the iOS Simulator.")
        } else {
            println("application:didFailToRegisterForRemoteNotificationsWithError: %@", error)
        }
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        PFPush.handlePush(userInfo)
        if let band = self.band {
            sendNotificationToBand(band)
        }
        if application.applicationState == UIApplicationState.Inactive {
            PFAnalytics.trackAppOpenedWithRemoteNotificationPayload(userInfo)
        } else if application.applicationState == UIApplicationState.Active {
            // Send notification that motion was detected
            NSNotificationCenter.defaultCenter().postNotificationName("motionDetected", object: nil)
            
            // Set the badge notification count to 0
            UIApplication.sharedApplication().applicationIconBadgeNumber = 0
        }
    }
    
    func sendNotificationToBand(band: MSBClient) {
        if (band.isDeviceConnected) {
            let tileId = NSUUID(UUIDString: "be2066df-306f-438e-860c-f82a8bc0bd6a")
            let tileName = "MotionCapture Tile"
            let tileIcon = MSBIcon(UIImage: UIImage(named: "MSBIcon-46"), error: nil)
            let smallIcon = MSBIcon(UIImage: UIImage(named: "MSBIcon-24"), error: nil)
            let tile = MSBTile(id: tileId, name: tileName, tileIcon: tileIcon, smallIcon: smallIcon, error: nil)
            
            band.tileManager.addTile(tile, completionHandler: { (error) -> Void in
                if (error == nil || error?.code == MSBErrorType.TileAlreadyExist.rawValue) {
                    println("[MSB] Sending notification...")
                    band.notificationManager.sendMessageWithTileID(tile.tileId, title: "MotionCapture", body: "Motion detected!", timeStamp: NSDate(), flags: .ShowDialog, completionHandler: { (error) -> Void in
                        if (error == nil) {
                            println("[MSB] Successfully sent notification!")
                        } else {
                            println("[MSB] Error sending notification: \(error.localizedDescription)")
                        }
                    })
                } else {
                    println("[MSB] Error creating tile: \(error.localizedDescription)")
                }
            })
        }
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        // Set the badge notification count to 0
        UIApplication.sharedApplication().applicationIconBadgeNumber = 0
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

}


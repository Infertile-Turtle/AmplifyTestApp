//
//  AmplifyTestAppApp.swift
//  AmplifyTestApp
//
//  Created by Andrew Fairchild on 12/6/22.
//

import SwiftUI
import Amplify
import AWSAPIPlugin


class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        do {
            
            Amplify.Logging.logLevel = .verbose
            //Configure Amplify as Usual
            
            try Amplify.configure()
        } catch {
            print("An error occurred setting up Amplify: \(error)")
        }
        return true
    }
}


@main
struct AmplifyTestAppApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

//
//  ContentView.swift
//  AmplifyTestApp
//
//  Created by Andrew Fairchild on 12/6/22.
//

import SwiftUI
import Amplify
import AWSAPIPlugin
import AWSCognitoAuthPlugin
import Foundation
import Combine

struct ContentView: View {
    //    var sark: SARK = SARK()
    @State private var sink: AnyCancellable?
    //    @State private var usernames: String?
    //    @State private var passwords: String?
    //    @State private var emails: String?
    //    @State private var confirmationCode: String?
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var email: String = ""
    @State private var verification: String = ""
    @State private var phonenumber: String = ""
    @State private var MFA: String = ""
    //    @State private var confirmationCode: String = ""
    var body: some View {
        VStack {
            
            
            Group {
                
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundColor(.accentColor)
                Text("Hello, world!")
                Button(action: {
                    sink = postTodo()
                }) {
                    Text("Run API POST Check")
                }
                Button(action: {
                    sink = fetchCurrentAuthSession()
                }) {
                    Text("Run Auth Check")
                    
                }
                
                Button(action: {
                    for _ in 0..<100 {print("")}
                }) {
                    Text("Clear Console")
                }
            }
            
            Group {
                
                TextField("Username", text: $username) // <1>, <2>
                TextField("Email", text: $email) // <1>, <2>
                TextField("Password", text: $password) // <1>, <2>
                TextField("Phone Number", text: $phonenumber) // <1>, <2>
                TextField("Verification Code", text: $verification) // <1>, <2>
                TextField("MFA Code", text: $MFA) // <1>, <2>
                
                Button(action: {
                    sink = signUp(username: username, password: password, email: email, phonenumber: phonenumber)
                }) {
                    Text("Sign Up")
                }
                
                Button(action: {
                    sink = confirmSignUp(for: username, with: verification)
                }) {
                    Text("Confirmation Code Check")
                }
                Button(action: {
                    sink = signIn(username: username, password: password)
//                    sink = confirmSignIn()
                }) {
                    Text("Sign In")
                }
            }
            Button(action: {
                sink = signIn(username: username, password: password)
                sink = confirmSignIn()
            }) {
                Text("Confirm Sign In")
            }
            Button(action: {
                sink = signOutLocally()
            }) {
                Text("Sign Out Locally")
            }
            
            
            
        }
        .padding()
        .onAppear()
    }
    init() {
        do {
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.add(plugin: AWSAPIPlugin())
            try Amplify.configure()
            print("Amplify configured with API and Auth plugin")
        } catch {
            print("Failed to initialize Amplify with \(error)")
        }
        
        //        do {
        //            try Amplify.add(plugin: AWSCognitoAuthPlugin())
        //            try Amplify.configure()
        //            print("Amplify configured with auth plugin")
        //        } catch {
        //            print("Failed to initialize Amplify with \(error)")
        //        }
        
    }
    //MARK: API Call
    
    func postTodo() -> AnyCancellable {
        print("Running ToDo function")
        let message = #"{"message": "my new Todo"}"#
        let request = RESTRequest(path: "/todo", body: message.data(using: .utf8))
        let sink = Amplify.Publisher.create {
            try await Amplify.API.post(request: request)
        }
            .sink {
                if case let .failure(apiError) = $0 {
                    print("Failed", apiError)
                }
            }
    receiveValue: { data in
        let str = String(decoding: data, as: UTF8.self)
        print("Success \(str)")
    }
        return sink
    }
    
    //MARK: Check Auth Status
    
    func fetchCurrentAuthSession() -> AnyCancellable {
        Amplify.Publisher.create {
            try await Amplify.Auth.fetchAuthSession()
        }.sink {
            if case let .failure(authError) = $0 {
                print("Fetch session failed with error \(authError)")
            }
        }
    receiveValue: { session in
        print("Is user signed in - \(session.isSignedIn)")
    }
    }
    
    //MARK: Sign Up & Verification Code
    
    func signUp(username: String, password: String, email: String, phonenumber: String) -> AnyCancellable {
        let userAttributes = [
            AuthUserAttribute(.email, value: email),
            AuthUserAttribute(.phoneNumber, value: phonenumber)
        ]
        let options = AuthSignUpRequest.Options(userAttributes: userAttributes)
        let sink =  Amplify.Publisher.create {
            try await Amplify.Auth.signUp(
                username: username,
                password: password,
                options: options
            )
        }.sink {
            if case let .failure(authError) = $0 {
                print("An error occurred while registering a user \(authError)")
            }
        }
    receiveValue: { signUpResult in
        if case let .confirmUser(deliveryDetails, _, userId) = signUpResult.nextStep {
            print("Delivery details \(String(describing: deliveryDetails)) for userId: \(String(describing: userId))")
        } else {
            print("SignUp Complete")
        }
    }
        return sink
    }
    func confirmSignUp(for username: String, with confirmationCode: String) -> AnyCancellable {
        Amplify.Publisher.create {
            try await Amplify.Auth.confirmSignUp(
                for: username,
                confirmationCode: confirmationCode
            )
        }.sink {
            if case let .failure(authError) = $0 {
                print("An error occurred while confirming sign up \(authError)")
            }
        }
    receiveValue: { _ in
        print("Confirm signUp succeeded")
    }
    }
    
    //MARK: Login
    func signIn(username: String, password: String) -> AnyCancellable {
        Amplify.Publisher.create {
            try await Amplify.Auth.signIn(
                username: username,
                password: password
            )
        }.sink {
            if case let .failure(authError) = $0 {
                print("Sign in failed \(authError)")
            }
        }
    receiveValue: { signInResult in
        if signInResult.isSignedIn {
            print("Sign in succeeded")
        }
    }
    }
    
    //MARK: MFA
    
    func confirmSignIn() -> AnyCancellable {
        Amplify.Publisher.create {
            try await Amplify.Auth.confirmSignIn(challengeResponse: "<confirmation code received via SMS>")
        }.sink {
            if case let .failure(authError) = $0 {
                print("Confirm sign in failed \(authError)")
            }
        }
    receiveValue: { signInResult in
        print("Confirm sign in succeeded. Next step: \(signInResult.nextStep)")
    }
    }
    
    //MARK: Log Out
    
    func signOutLocally() -> AnyCancellable {
        Amplify.Publisher.create {
            await Amplify.Auth.signOut()
        }.sink(receiveValue: { result in
            guard let signOutResult = result as? AWSCognitoSignOutResult
            else {
                print("Signout failed")
                return
            }
            print("Local signout successful: \(signOutResult.signedOutLocally)")
            switch signOutResult {
            case .complete:
                // Sign Out completed fully and without errors.
                print("Signed out successfully")
                
            case let .partial(revokeTokenError, globalSignOutError, hostedUIError):
                // Sign Out completed with some errors. User is signed out of the device.
                if let hostedUIError = hostedUIError {
                    print("HostedUI error  \(String(describing: hostedUIError))")
                }
                
                if let globalSignOutError = globalSignOutError {
                    // Optional: Use escape hatch to retry revocation of globalSignOutError.accessToken.
                    print("GlobalSignOut error  \(String(describing: globalSignOutError))")
                }
                
                if let revokeTokenError = revokeTokenError {
                    // Optional: Use escape hatch to retry revocation of revokeTokenError.accessToken.
                    print("Revoke token error  \(String(describing: revokeTokenError))")
                }
                
            case .failed(let error):
                // Sign Out failed with an exception, leaving the user signed in.
                print("SignOut failed with \(error)")
            }
        })
    }
}

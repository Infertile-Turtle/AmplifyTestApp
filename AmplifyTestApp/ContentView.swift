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
    var body: some View {
        VStack {
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
//                print("Testing")
                sink = fetchCurrentAuthSession()
            }) {
                Text("Run Auth Check")
            }
            Button(action: {
//                print("Testing")
                sink = signUp(username: "adf020", password: "adf020", email: "andrew.d.fairchild@gmail.com")
            }) {
                Text("Run Auth Check")
            }
            Button(action: {
                for _ in 0..<100 {print("")}
            }) {
                Text("Clear Console")
            }
        }
        .padding()
        .onAppear {
        }
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
    
    func signUp(username: String, password: String, email: String) -> AnyCancellable {
        let userAttributes = [AuthUserAttribute(.email, value: email)]
        let options = AuthSignUpRequest.Options(userAttributes: userAttributes)
        let sink = Amplify.Publisher.create {
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
                print("Delivery details \(String(describing: deliveryDetails)) for userId: \(String(describing: userId)))")
            } else {
                print("SignUp Complete")
            }

        }
        return sink
    }
}


//struct MyNewTodo: Codable {
//    var message: String
//    enum CodingKeys: String, CodingKey {
//        case message = "message"
//    }
//}
//
//struct PostResponse: Codable {
//    let response: String?
//    let result: String?
//    let error: String?
//    let code: String?
//    let text: String?
//    let message: String?
//    let Message: String?
//
//    enum CodingKeys: String, CodingKey {
//        case response = "response"
//        case result = "result"
//        case error = "Error"
//        case code = "code"
//        case text = "text"
//        case message = "message"
//        case Message = "Message"
//    }
//}
//
//
//class SARK {
//
//    //MARK: Networking
//    var dg = DispatchGroup()
//    var subscriptions = Set<AnyCancellable>()
//
//    func requestAuth<T: Codable>(_ value: T, url: String, token: String, httpMethod: String = "POST") -> URLRequest {
//        let url = URL(string: url)
//        var jsonData = Data()
//        let jsonEncoder = JSONEncoder()
//        do {
//            jsonData = try jsonEncoder.encode(value)
//        }
//        catch {
//            print("Error Encoding JSON Body...")
//        }
//        var request = URLRequest(url: url!)
//        request.httpMethod = httpMethod
//        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.addValue("\(token)", forHTTPHeaderField: "authorizationToken")
//        request.httpBody = jsonData
//        return request
//    }
//
//    func requestAuth(url: String, httpMethod: String = "GET") -> URLRequest {
//        let url = URL(string: url)
//        var request = URLRequest(url: url!)
//        request.httpMethod = httpMethod
//        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//        return request
//    }
//
//    func postToDo() {
//        let url = "https://lbkdggcx25.execute-api.us-east-1.amazonaws.com/dev/todo"
//        let request = requestAuth(MyNewTodo(message: "My New Todo"), url: url)
//        dg.enter()
//        fetch(request: request) { [self] (result: Result<PostResponse, Error>) in
//            switch result {
//            case .success(let result):
//                print("RESULT: \(result)")
//            case .failure(let error):
//                print("Error: \(error.localizedDescription)")
//            }
//            dg.leave()
//        }
//        dg.notify(queue: .main) {
//            print("Call Complete.")
//        }
//    }
//
//
//
//    func fetch<T: Decodable>(request: URLRequest, completion: @escaping (Result<T, Error>) -> Void) {
//        URLSession.shared.dataTaskPublisher(for: request)
//            .map { $0.data }
//            .decode(type: T.self, decoder: JSONDecoder())
//            .receive(on: RunLoop.main)
//            .sink { (resultCompletion) in
//                switch resultCompletion {
//                case .failure(let error):
//                    completion(.failure(error))
//                case .finished:
//                    return
//                }
//            } receiveValue: { (resultArr) in
//                completion(.success(resultArr))
//            }.store(in: &subscriptions)
//    }
//}

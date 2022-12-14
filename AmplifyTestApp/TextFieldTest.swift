//
//  TextFieldTest.swift
//  AmplifyTestApp
//
//  Created by Andrew Fairchild on 12/13/22.
//

import Foundation
import SwiftUI

struct TextFieldTest: View {
    @State private var username: String = ""
    
    var body: some View {
        VStack {
            TextField("Username", text: $username) // <1>, <2>
        }
    }
}

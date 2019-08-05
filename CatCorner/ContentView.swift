//
//  ContentView.swift
//  CatCorner
//
//  Created by Trang Nguyen on 2019-08-04.
//  Copyright © 2019 Blynkode. All rights reserved.
//

import Combine
import SwiftUI

// BindableObject : notify the form whenever the state change.
class Order: BindableObject, Codable{
    // Self conform coding keys  = things that we want to convert to JSON and back
    enum CodingKeys: String, CodingKey {
        case type, color, hair, age, hypoallergenic, name, streetAddress, city, postalCode
    }
    
    // PassThroughSubject: sends no data and never throw a value
    // This would allow a form to bind to an object
    var didChange = PassthroughSubject<Void, Never>()
    
    static let types = ["Persian", "Maine", "Siamese", "Ragdoll", "Sphynx", "Bengal", "Abyssinian", "Russian Blue"]
    
    static let colours = ["Black", "White", "Gray", "Tabby", "Black and White", ]
    
    static let hairLengths = ["Short", "Long"]
    
    // Selected type
    var type = 0 { didSet { update() }}
    var color = 0 { didSet { update() }}
    var hair = 0 { didSet { update() }}
    var specialRequest = false { didSet { update() }}
    var age = 0 { didSet { update() }}
    var hypoallergenic = false { didSet { update() }}
    
    // Address
    var name = "" { didSet { update() }}
    var streetAddress = "" { didSet { update() }}
    var city = "" { didSet { update() }}
    var postalCode = "" { didSet { update() }}
    
    // Send all updated data
    func update() {
        didChange.send()
    }
    
    var isValid: Bool {
        if name.isEmpty || streetAddress.isEmpty || city.isEmpty ||
            postalCode.isEmpty {
            return false
        }
        return true
    }
}

struct ContentView : View {
    @ObjectBinding var order = Order()
    @State var confirmMessage = ""
    @State var showingConfirmation = false
 
    var body: some View {
        NavigationView {
            // Form: create a list on the left side of the view
            Form{
                Section {
                    // Picker is bound to Order
                    Picker(selection: $order.type, label: Text("Select your cat type")){
                        // Loop thru each item in Order list.
                        ForEach (0..<Order.types.count){
                            Text(Order.types[$0]).tag($0)
                        }
                    }//.pickerStyle(.wheel) // If really want a picker style
                    Picker(selection: $order.color, label: Text("Select a colour")) {
                        // Loop thru each colour type
                        ForEach(0..<Order.colours.count) {
                            Text(Order.colours[$0]).tag($0)
                        }
                    }
                
                    Stepper(value: $order.age, in: 0...48){
                        Text("Number of month old: \(order.age)")
                    }
                    
                }
                Section {
                    Toggle(isOn: $order.specialRequest) {
                        Text ("Any Special Request?")
                    }
                    if order.specialRequest {
                        Picker(selection: $order.hair, label: Text("Select hair length")){
                            ForEach (0..<Order.hairLengths.count) {
                                Text(Order.hairLengths[$0]).tag($0)
                            }
                        }
                        Toggle(isOn: $order.hypoallergenic) {
                            Text("Hypoallergenic")
                        }
                    }
                }
                Section {
                    TextField("Name", text: $order.name)
                    TextField("Street Address", text: $order.streetAddress)
                    TextField("City", text: $order.city)
                    TextField("Postal Code", text: $order.postalCode)
                }
                Section {
                    Button(action: { self.PlaceOrder() } ) {
                        Text ("Place Order")
                    }
                }.disabled(!order.isValid)
            }
                .navigationBarTitle(Text("Cat Corner"))
                .presentation($showingConfirmation) {
                    Alert(title: Text("Thank you"), message: Text(confirmMessage), dismissButton: .default(Text("OK")))
                }
        }
    }
    
    func PlaceOrder() {
        guard let encoded = try? JSONEncoder().encode(order) else {
            print ("Failed to encode order")
            return
        }
        // a testing api that mirror back json data
        let url = URL(string: "https://reqres.in/api/catcorner")!
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = encoded
        
        // Send data
        URLSession.shared.dataTask(with: request){
            guard let data = $0 else {
                print ("No data in response: \($2?.localizedDescription ?? "Unknown Eror" ).")
                return
            }
            
            if let decodeOrder = try? JSONDecoder().decode(Order.self, from: data) {
                self.confirmMessage = "Your search for \(Order.types[decodeOrder.type]), \(Order.colours[decodeOrder.color]), \(Order.hairLengths[decodeOrder.hair]) hair cat is found."
                self.showingConfirmation = true
            }
            else {
                let dataString = String(decoding: data, as: UTF8.self)
                print ("Invalid response: \(dataString)")
                self.showingConfirmation = false
            }
        }.resume()
    }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif

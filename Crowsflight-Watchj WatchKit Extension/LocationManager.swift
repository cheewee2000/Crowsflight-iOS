


import Foundation
import Combine
//import CoreLocation
import WatchKit
import SwiftUI


class LocationManager: NSObject, ObservableObject{
    //var extensionDelegate = ExtensionDelegate();

    var objectWillChange = PassthroughSubject<Void, Never>()
    
    var heading: Double = .zero {
        didSet {
            objectWillChange.send()
        }
    }
    
    var lat: Double = .zero {
        didSet {
            objectWillChange.send()
        }
    }
    
    var lng: Double = .zero {
        didSet {
            objectWillChange.send()
        }
    }
    var bearing: Double = .zero {
        didSet {
            objectWillChange.send()
        }
    }

    var horizontalAccuracy: Double = .zero {
        didSet {
            objectWillChange.send()
        }
    }
    
    var headingAccuracy: Double = .zero {
        didSet {
            objectWillChange.send()
        }
    }
    
    var here: CLLocation = .init(latitude: 0, longitude: 0) {
        didSet {
            objectWillChange.send()
        }
    }
    

    var targetMax: Int = 1 {
        didSet {
            objectWillChange.send()
        }
    }
    
    var targetList : Array = [Any]() {
        didSet {
            objectWillChange.send()
        }
    }

    
    var list : Array = [Any]() {
        didSet {
            objectWillChange.send()
        }
    }
    
    
    var defaultTargetList : Array =      [
        ["searchedText": "BOTA",
         "lat": 42.460549,
         "lng": 18.766894,
         "address": ""]
        ,
        ["searchedText": "POLIEGOS",
         "lat": 36.774635,
         "lng": 24.641630,
         "address": ""]
        ,
        ["searchedText": "TURN 2",
         "lat": 36.8087908,
         "lng": 24.5551709,
         "address": ""]
        ,
        ["searchedText": "SKIADI",
         "lat": 36.8091440,
         "lng": 24.5392309,
         "address": ""]
        
    ]
    

//    private let locationManager: CLLocationManager
    
    override init() {
        //self.targetIndex = targetIndex
        
        //self.locationManager = CLLocationManager()
        super.init()
        //self.locationManager.delegate = self
        self.setup()

    }
    
    
    private func setup() {
//        self.locationManager.requestWhenInUseAuthorization()
//
//        if CLLocationManager.headingAvailable() {
//            self.locationManager.startUpdatingLocation()
//            self.locationManager.startUpdatingHeading()
//        }
        
        //let extensionDelegate = ExtensionDelegate();
        //loadData()
        //print("target setup complete")
    }
    
    

    

    

}

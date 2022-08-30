//
//  Compass.swift
//  Compass
//
//  Created by ProgrammingWithSwift on 2019/10/06.
//  Copyright © 2019 ProgrammingWithSwift. All rights reserved.
//

import Foundation
import Combine
import CoreLocation

class CompassHeading: NSObject, ObservableObject, CLLocationManagerDelegate {
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
    var distance: Double = .zero {
        didSet {
            objectWillChange.send()
        }
    }
    
    var accuracy: Double = .zero {
        didSet {
            objectWillChange.send()
        }
    }
    
    var here: CLLocation = .init(latitude: 0, longitude: 0) {
        didSet {
            objectWillChange.send()
        }
    }
    
    private let locationManager: CLLocationManager
    
    override init() {
        self.locationManager = CLLocationManager()
        super.init()
        
        self.locationManager.delegate = self
        self.setup()


    }
    
    private func setup() {
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.headingAvailable() {
            self.locationManager.startUpdatingLocation()
            self.locationManager.startUpdatingHeading()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        self.heading = -1 * newHeading.trueHeading
        print("heading: \(self.heading)")

    }
    

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
      print("LocationManager didUpdateLocations: numberOfLocation: \(locations.count)")
      let dateFormatter = DateFormatter()
      dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
      
        
      locations.forEach { (location) in
        print("LocationManager didUpdateLocations: \(dateFormatter.string(from: location.timestamp)); \(location.coordinate.latitude), \(location.coordinate.longitude)")
//        print("LocationManager altitude: \(location.altitude)")
        print("LocationManager horizontalAccuracy: \(location.horizontalAccuracy)")


          
          
          if(self.lat != 0 && self.lng != 0){
              self.here = CLLocation(latitude:self.lat, longitude: self.lng)
          }
          //let target = CLLocation(latitude: 36.774181, longitude: 24.548975)
          //let target = CLLocation(latitude: 36.8091440, longitude: 24.5392309) //rock
          let target = CLLocation(latitude: 36.774635, longitude: 24.641630) //poliegos

          //measure distance
          self.distance = here.distance(from: target)

          
          //measure bearing
          self.bearing = getBearing(L1: here, L2: target)
          print("bearing: \(self.bearing)")

          
          //bearing accuracy
          let offset = self.bearing+90.0;
          
          let xMeters=Double(cosf(Float(offset / 180.0 * Double.pi))) * location.horizontalAccuracy;
          let yMeters=Double(sinf(Float(offset / 180.0 * Double.pi))) * location.horizontalAccuracy;
          
          //111111 meters / degree (approximate) +- 10m
          let olat1 = self.lat+xMeters/111111.0;
          let olng1 = self.lng+yMeters/111111.0;
          
          let oLoc =  CLLocation.init(latitude: olat1, longitude: olng1)
          let altBearing = getBearing(L1: oLoc, L2: target)

          let bearingAccuracy = Int(bearing-altBearing + 360) % 360;
          
          
          
          // get bearing accuracy
          self.accuracy=location.courseAccuracy + Double(bearingAccuracy)
          
           if(self.accuracy <= 1.0){self.accuracy = 60.0};
           if(self.accuracy > 180.0){self.accuracy = 180.0};
          
          
          
          self.lat = location.coordinate.latitude
          self.lng = location.coordinate.longitude
          
          
//        print("LocationManager verticalAccuracy: \(location.verticalAccuracy)")
//        print("LocationManager speedAccuracy: \(location.speedAccuracy)")
//        print("LocationManager speed: \(location.speed)")
//        print("LocationManager timestamp: \(location.timestamp)")
//        print("LocationManager courseAccuracy: \(location.courseAccuracy)") // 13.4
//        print("LocationManager course: \(location.course)")
      }
    }
    
    
    
}
func getBearing(L1: CLLocation,  L2: CLLocation) -> Double{
       
    let lat1 = (L1.coordinate.latitude / 180.0 * Double.pi);
    let lat2 = (L2.coordinate.latitude / 180.0 * Double.pi);
    let dLon = (L2.coordinate.longitude / 180.0 * Double.pi) - (L1.coordinate.longitude / 180.0 * Double.pi);
    let y = sin(dLon) * cos(lat2);
    let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
    let brng = atan2(y, x);
    
    let bearing = Int(brng * (180.0 / Double.pi) + 360.0) % 360;
    
    
    return Double(bearing)
}
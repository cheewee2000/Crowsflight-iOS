


import Foundation
import Combine
//import CoreLocation
import WatchKit
import WatchConnectivity


//struct target: Identifiable {
//    let lat: Double
//    let lng: Double
//    let searchedText: String
//}


class LocationManager: NSObject, ObservableObject, WCSessionDelegate{
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
    
    
//    @Published var targetList: Array = []

    
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
    
    func loadData() {
        let path = self.dataFilePath() as String
        let defaultManager = FileManager()
        
        //print(path)
        if defaultManager.fileExists(atPath: path) {
            print("path exists")
            let url = URL(fileURLWithPath: path)
            print (url)
            let arr = NSArray(contentsOfFile: path) as? [Any]
            self.targetList = arr ?? self.defaultTargetList
            self.targetMax = self.targetList.count
        }
        
        
    }
    
    func documentsDirectory()->String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths.first!
        return documentsDirectory
    }
    
    func dataFilePath ()->String{
        return self.documentsDirectory().appendingFormat("/locationList.plist")
    }
    
    func saveData(_ locations : [[String:Any]]) {
        let archiver = NSKeyedArchiver(requiringSecureCoding: true)
        archiver.encode(locations, forKey: "locationList")
        let data = archiver.encodedData
        try! data.write(to: URL(fileURLWithPath: dataFilePath()))
    }
    
    
//    private let locationManager: CLLocationManager
    
    override init() {
        //self.targetIndex = targetIndex
        
        //self.locationManager = CLLocationManager()
        super.init()
        //self.locationManager.delegate = self
        self.setup()
        setupWatchConnectivity()

    }
    
    
    private func setup() {
//        self.locationManager.requestWhenInUseAuthorization()
//
//        if CLLocationManager.headingAvailable() {
//            self.locationManager.startUpdatingLocation()
//            self.locationManager.startUpdatingHeading()
//        }
        
        //let extensionDelegate = ExtensionDelegate();
        loadData()
        print("target setup complete")
    }
    
    

    
//    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
//        self.heading = -1 * newHeading.trueHeading
//        self.headingAccuracy = newHeading.headingAccuracy
//    }
//
//
//    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//
//        let location = locations[0]
//
//        self.lat = location.coordinate.latitude
//        self.lng = location.coordinate.longitude
//
//        if(self.lat != 0 && self.lng != 0){
//            self.here = CLLocation(latitude:self.lat, longitude: self.lng)
//        }
//
//        self.horizontalAccuracy = location.horizontalAccuracy
//
//    }
    
//
//    func getBearing(L1: CLLocation,  L2: CLLocation) -> Double{
//
//        let lat1 = (L1.coordinate.latitude / 180.0 * Double.pi);
//        let lat2 = (L2.coordinate.latitude / 180.0 * Double.pi);
//        let dLon = (L2.coordinate.longitude / 180.0 * Double.pi) - (L1.coordinate.longitude / 180.0 * Double.pi);
//        let y = sin(dLon) * cos(lat2);
//        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
//        let brng = atan2(y, x);
//
//        let bearing = Int(brng * (180.0 / Double.pi) + 360.0) % 360;
//
//
//        return Double(bearing)
//    }
    
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WC Session activation failed with error: " + "\(error.localizedDescription)")
            return
        }
        print("WC Session activated with state: \(activationState.rawValue)")
    }
    
    func setupWatchConnectivity() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext:[String:Any]) {
        if let data = applicationContext["data"] as? [String] {
            print(data)
            DispatchQueue.main.async {
                WKInterfaceController.reloadRootPageControllers( withNames: ["SomeController"], contexts: nil,
                                                                 orientation: WKPageOrientation.vertical, pageIndex: 0)
            }
        }
    }
    
    
    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        
        print("Received File with URL: \(file.fileURL)")
        print("Outstanding file transfers: \(WCSession.default.outstandingFileTransfers)")
        print("Has content pending: \(WCSession.default.hasContentPending)")
        
        
        //self.fileURL = file.fileURL
        
        let array=(NSArray(contentsOf:file.fileURL) as? [Any])!
        if(!array.isEmpty){
            print(array)
            self.list=(NSArray(contentsOf: file.fileURL) as? [Any])!
            saveData(self.list);
            
        }
        
        
    }
    
    func session(_session: WCSession, didFinishFileTransfer fileTransfer: WCSessionFileTransfer, error: NSError?) {
        print("file transfer complete")
        print("error: ", error as Any)
    }
    
    
    func getDocumentsDirectory() -> URL {
        // find all possible documents directories for this user
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        
        // just send back the first one, which ought to be the only one
        return paths[0]
    }
    
    
    func dataFilePath ()->URL{
        return self.getDocumentsDirectory().appendingPathComponent("locationList.plist")
    }
    
    func saveData(_ locations : [Any]) {
        (locations as NSArray).write(to: dataFilePath(), atomically: true)
        print("saved list to file")
        print(dataFilePath() as String)
        
        //restart ContentView
        
    }
}

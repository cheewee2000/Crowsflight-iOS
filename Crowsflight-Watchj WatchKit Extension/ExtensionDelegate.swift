import WatchKit
import WatchConnectivity

//var locationInstance = LocationManager()

class ExtensionDelegate: NSObject, ObservableObject, WKExtensionDelegate, WCSessionDelegate {
    
    func applicationDidFinishLaunching() {
        print("watch launched")
        setupWatchConnectivity()
        
        // var compassHeading = CompassHeading()
        //compassHeading.loadData()
        //compassHeading.loadDictionary()
        let  locationManager = LocationManager()
        
        //locationManager.loadData()
        
        //loadData()
        loadLocations()

        
        
    }
    
    
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
        
        //        let array=(NSArray(contentsOf:file.fileURL) as? [Any])!
        //        if(!array.isEmpty){
        //            print(array)
        //            let list=(NSArray(contentsOf: file.fileURL) as? [Any])!
        //            saveData(list);
        //        }
        
        let array=(NSArray(contentsOf:file.fileURL) as? [[String:Any]])!
        if(!array.isEmpty){
            print(array)
            let list=(NSArray(contentsOf: file.fileURL) as? [[String:Any]])!
            saveData(list);
            
            loadArrayToStruct(list: list)
            
        }
        //loadData()
        
    }
    
    
    
    func loadArrayToStruct(list : [[String:Any]] ){
        tabViewModel.tabItems.removeAll()
        
        //save to struct
        var count = 0
        for item in list {
            //print(item)
            let target = TabItem(lat: item["lat"] as! Double, lng: item["lng"] as! Double, address: "", searchedText: item["searchedText"] as! String, tag: count)
            tabViewModel.tabItems.append(target)
            count += 1
        }
        
        //save to defaults
        UserDefaults.standard.set(try? PropertyListEncoder().encode(tabViewModel.tabItems), forKey:"locations")
    }
    
    
    func loadLocations(){
        if let data = UserDefaults.standard.value(forKey:"locations") as? Data {
            tabViewModel.tabItems = try! PropertyListDecoder().decode(Array<TabItem>.self, from: data)
        }
        
    }
    
    
    func session(_session: WCSession, didFinishFileTransfer fileTransfer: WCSessionFileTransfer, error: NSError?) {
        print("file transfer complete")
        print("error: ", error as Any)
    }
    
    
    
    func loadData() {
        let path = self.dataFilePath() as String
        let defaultManager = FileManager()
        
        //print(path)
        if defaultManager.fileExists(atPath: path) {
            print("path exists")
            let url = URL(fileURLWithPath: path)
            print (url)
            let arr = NSArray(contentsOfFile: path) as? [Any]
            print(arr)
            
            
            //self.targetList = arr ?? self.defaultTargetList
            //self.targetMax = self.targetList.count
            //for i in vehicleList?._embedded.userVehicles ?? [] { }
            
            for item in arr ?? [] {
                print(item)
                //tabs.add(T)
                tabViewModel.tabItems.append(TabItem( lat:0.0, lng:0.0, address: "",searchedText: "hello", tag: 1))
                
            }
            
        }
        //
        
        //        var tabStructArray = functionsStruct()
        //        tabs.add(item:tabStructArray[0])
        //        tabs.add(item:tabStructArray[1])
        //        tabs.add(item:tabStructArray[3])
        //
        //
        
        
    }
    
    
    
    
    //save file
    //    func getDocumentsDirectory() -> URL {
    //        // find all possible documents directories for this user
    //        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    //
    //        // just send back the first one, which ought to be the only one
    //        return paths[0]
    //    }
    //
    //
    //    func dataFilePath ()->URL{
    //        return self.getDocumentsDirectory().appendingPathComponent("locationList.plist")
    //    }
    
    //    func saveData(_ locations : [Any]) {
    //        (locations as NSArray).write(to: dataFilePath(), atomically: true)
    //        print("saved list to file")
    //        print(dataFilePath())
    //
    //        //restart ContentView
    //
    //    }
    
    
    func functionsStruct() -> [TabItem] {
        
        let path = self.dataFilePath()
        //let defaultManager = FileManager()
        
        //print(path)
        //        if (!defaultManager.fileExists(atPath: path)) {
        //         return
        //        }
        //print("path exists")
        let url = URL(fileURLWithPath: path)
        
        //print (url)
        
        //let url = Bundle.main.url(forResource: "locationList", withExtension: "plist")!
        let data = try! Data(contentsOf: url)
        let decoder = PropertyListDecoder()
        print(data)
        //}
        return try! decoder.decode([TabItem].self, from: data)
        
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
    
    
    //    func documentsDirectory()->String {
    //        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
    //        let documentsDirectory = paths.first!
    //        return documentsDirectory
    //    }
    ////
    //    func dataFilePath ()->String{
    //        return self.documentsDirectory().appendingFormat("/locationList.plist")
    //    }
    ////
    //    func saveData(_ locations : [Any]) {
    //        let archiver = NSKeyedArchiver(requiringSecureCoding: true)
    //        archiver.encode(locations, forKey: "locationList")
    //        let data = archiver.encodedData
    //        try! data.write(to: URL(fileURLWithPath: dataFilePath()))
    //    }
    
    
    
    
}


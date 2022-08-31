//
//  cwtAppDelegate.m
//  Crowsflight
//
//  Created by Che-Wei Wang on 5/4/13.
//  Copyright (c) 2013 CW&T. All rights reserved.
////#import <Crashlytics/Crashlytics.h>

#import "cwtAppDelegate.h"
#import "cwtViewController3.h"
#import "cwtUITableViewController.h"
//#import "cwtIAP.h"
#import "cwtMapViewController.h"
#import "Reachability.h"
//#import "NVSlideMenuController.h"
#import "QuartzCore/CALayer.h"
#import "cwtMapViewController.h"
#import "Crowsflight-Swift.h"


@interface cwtAppDelegate ()<UIAlertViewDelegate,CLLocationManagerDelegate,UIAppearanceContainer>//,MTStatusBarOverlayDelegate>

@end

@implementation cwtAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{

    
    
    //[Crashlytics startWithAPIKey:@"1eb6d15737d50f2df4316cb5b8b073da76a42b67"];

    //[cwtIAP sharedInstance];

    
    [self loadmyLocations];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.viewController = [[cwtViewController3 alloc] init];
    self.window.rootViewController = self.viewController;
    
    
    [self.viewController.view setFrame:[[UIScreen mainScreen] bounds]];
    
    self.navController = [[UINavigationController alloc] initWithRootViewController:self.viewController];
    [self.navController setNavigationBarHidden:YES animated:NO];
    //self.navController.wantsFullScreenLayout=NO;

    
    [self.window makeKeyAndVisible];
    [self.window addSubview:self.navController.view];
    
//    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
//    {
//        NSLog(@"Running in IOS-7");
//
//        CGRect screenBounds = [[UIScreen mainScreen] applicationFrame];
//        self.window.frame=[[UIScreen mainScreen] applicationFrame];
//        self.viewController.view.frame=[[UIScreen mainScreen] applicationFrame];
//
//        UIView* status=[[UIView alloc] initWithFrame:CGRectMake(0, -20, screenBounds.size.width, 20)];
//        status.backgroundColor=[UIColor whiteColor];
//        [self.window addSubview:status];
//    }
    
    //[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    //[[UINavigationBar appearance] setBarTintColor:[UIColor colorWithRed:255.0/255 green:255.0/255 blue:255.0/255 alpha:1.0]];

    
//    self.overlay = [MTStatusBarOverlay sharedInstance];
//    self.overlay.animation = MTStatusBarOverlayAnimationNone;
//    self.overlay.detailViewMode = MTDetailViewModeHistory;
//    self.overlay.delegate = self;
//    self.overlay.backgroundColor=[UIColor colorWithWhite:.95 alpha:1];
//    //overlay.hidesActivity=TRUE;
//
    self.headingAccuracy=-2;
    
    

    // Allocate a reachability object
    Reachability* reach = [Reachability reachabilityWithHostname:@"www.google.com"];
    
    
    //watchsesssion sync
    WatchSessionManager* watchSession = [WatchSessionManager init];
    
    //watchSession.
    

    
    
    // Set the blocks
    reach.reachableBlock = ^(Reachability*reach)
    {
        NSLog(@"REACHABLE!");
        self.hasInternet=TRUE;
    };
    
    reach.unreachableBlock = ^(Reachability*reach)
    {
        NSLog(@"UNREACHABLE!");
        self.hasInternet=FALSE;

    };
    
    // Start the notifier, which will cause the reachability object to retain itself!
    [reach startNotifier];
    

    //iCloud
    NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateKeyValuePairs:) name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification object:store];
    
    // Synchronize Store
    [store synchronize];
    

    
    return YES;
}




- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    
	//cout<<url;
	//NSString * urlString= [[NSString alloc] initWithUTF8String:url.c_str()];
    //NSString *urlString = [[url host] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *urlString = [[url host] stringByRemovingPercentEncoding] ;
    
    
    
    
    urlString=[urlString stringByReplacingOccurrencesOfString:@"+" withString:@" "];

    
    NSArray *pairs = [urlString componentsSeparatedByString: @"&"];
    
	NSString *hnear=@"";
	NSString *ll=@"0.0,0.0";
    NSArray *q;
    
	for (int i=0; i<[pairs count]; i++) {
		
        q=[[pairs objectAtIndex:i] componentsSeparatedByString:@"="];
		
		if([q count]>1){
            if( [[q objectAtIndex:0] isEqualToString:@"placename" ]){
				hnear=[q objectAtIndex:1];
			}
			else if( [[q objectAtIndex:0] isEqualToString:@"q" ]){
				hnear=[q objectAtIndex:1];
			}
            else if( [[q objectAtIndex:0] isEqualToString:@"hnear" ]){
				hnear=[q objectAtIndex:1];
			}
			else if( [[q objectAtIndex:0] isEqualToString:@"ll" ]){
				ll=[q objectAtIndex:1];
			}
		}
	}
    
	NSArray *latlng = [ll componentsSeparatedByString: @","];
    
    if([latlng count]>1){
        double nlat=[[latlng objectAtIndex:0] doubleValue];
        double nlng=[[latlng objectAtIndex:1] doubleValue];
        
        //clear last search text
        [[NSUserDefaults standardUserDefaults] setObject:@"" forKey:@"lastSearchText"];
        
        //set current values
        [[NSUserDefaults standardUserDefaults] setFloat:nlat forKey:@"currentLat"];
        [[NSUserDefaults standardUserDefaults] setFloat:nlng forKey:@"currentLng"];
        [[NSUserDefaults standardUserDefaults] setObject:hnear forKey:@"currentDestination"];
        
        //save to locationList
        [self addNewDestination:hnear newlat:nlat newlng:nlng];
        
        
        NSLog(@"save url to: %i", (int)[self.locationDictionaryArray count]-1);
        

        [[NSUserDefaults standardUserDefaults]setInteger:[self.locationDictionaryArray count]-1 forKey:@"currentDestinationN"];
        //self.viewController.locationViewController.page=[[NSUserDefaults standardUserDefaults] integerForKey:@"currentDestinationN"];
        [self.viewController flipToPage:[[NSUserDefaults standardUserDefaults] integerForKey:@"currentDestinationN"]];

        
    }
  return YES;
    
    

}


-(void) loadmyLocations{
	
	if( [[NSUserDefaults standardUserDefaults] stringForKey:@"units"]!=nil){
		self.units=[[NSUserDefaults standardUserDefaults] stringForKey:@"units"] ;
	}else{
        self.units=@"m";
        [[NSUserDefaults standardUserDefaults] setObject:@"m" forKey:@"units"];
    }
	
    //load plist
    [self copyFile];
    
	//load destination list
	NSLog(@"The array count: %i", (int)[self.locationDictionaryArray count]);
	self.nDestinations=(int)[self.locationDictionaryArray count];
        

}



- (void) copyFile
{

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory , NSUserDomainMask, YES);
    NSString *documentsDir = [paths objectAtIndex:0];
    NSFileManager *fileManager = [NSFileManager defaultManager];

    
    //create directory
    //NSString * folderPath = [documentsDir stringByAppendingPathComponent:@"Locations"];
    //[fileManager createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:nil];
    
    NSError *error;
    NSString *legacyDocPath = [documentsDir stringByAppendingString:@"/Locations/locationList.plist"];
    NSString *docPath = [documentsDir stringByAppendingString:@"/locationList.plist"];

    BOOL success = [fileManager fileExistsAtPath:docPath];

    
    if ([fileManager fileExistsAtPath: legacyDocPath] && !success){
        NSLog(@"copy legacy files to new location");
        BOOL legacySuccess = [fileManager copyItemAtPath:legacyDocPath toPath:docPath error:&error];
       
        if (!legacySuccess) NSAssert1(0, @"Failed to copy '%@'.", [error localizedDescription]);
        else NSLog(@"copied legacy locations plist");
        
        //delete legacy
        legacySuccess = [fileManager removeItemAtPath:legacyDocPath error:&error];
        if (!legacySuccess) NSAssert1(0, @"Failed to delete '%@'.", [error localizedDescription]);
        else NSLog(@"deleted legacy locations plist");
        
        legacySuccess = [fileManager removeItemAtPath:[documentsDir stringByAppendingString:@"/Locations"] error:&error];
        if (!legacySuccess) NSAssert1(0, @"Failed to delete '%@'.", [error localizedDescription]);
        else NSLog(@"deleted legacy locations folder");
        
        
    }
    
    //NSString *docPath = [documentsDir stringByAppendingString:@"/locationList.plist"];
    
    //first run
    else if(!success) {
        
        NSLog(@"The file does not exist. First run.");
        
        NSString *bundlePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"locationList.plist"];
        
        success = [fileManager copyItemAtPath:bundlePath toPath:docPath error:&error];
        
        if (!success) NSAssert1(0, @"Failed to create writable file with message '%@'.", [error localizedDescription]);
        else NSLog(@"copied locations plist");
        
        
    }
    
    
    
    self.locationDictionaryArray = [[NSMutableArray alloc] initWithContentsOfFile:docPath];
}


//- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
//    if(alertView.tag==1){
//        if(buttonIndex==1){
//            //if([store canMakePurchases]) [store unlockcrowsflight];
//        }
//        
//    }
//
//    
//}


- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {

    
    // test the age of the location measurement to determine if the measurement is cached
    // in most cases you will not want to rely on cached measurements
    NSTimeInterval locationAge = -[newLocation.timestamp timeIntervalSinceNow];
    if (locationAge > 5.0) return; //5 seconds
    
    // test that the horizontal accuracy does not indicate an invalid measurement
    self.accuracy=newLocation.horizontalAccuracy;
    if (self.accuracy < 0) return;
    
    //simply get the speed provided by the phone from newLocation
    self.speed = newLocation.speed;
    
    self.altitude= newLocation.altitude;
    self.altitudeAccuracy= newLocation.verticalAccuracy;

    // update the display with the new location data
    
    self.myLat=newLocation.coordinate.latitude;
    self.myLng=newLocation.coordinate.longitude;

    [(cwtViewController3*)self.window.rootViewController updateViewControllersWithLatLng: (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"currentDestinationN"]];
    
    //[(cwtMapViewController*)self.viewController.mapViewController centerDeviceLocation];
    //[(cwtMapViewController*)self.viewController.mapViewController.mapView setCenterCoordinate:newLocation.coordinate animated:YES];

    
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
    //if(self.headingAccuracy<0)return;
    //NSLog(@"truHeading: %f", newHeading.trueHeading);
    //NSLog(@"magHeading: %f", newHeading.magneticHeading);

    self.heading=newHeading.trueHeading; //heading in degress
    //self.heading=newHeading.magneticHeading; //heading in degress

    self.headingAccuracy=newHeading.headingAccuracy;

    [(cwtViewController3*)self.window.rootViewController updateViewControllersWithHeading:(int)[[NSUserDefaults standardUserDefaults] integerForKey:@"currentDestinationN"]];
    
    //[self.viewController.mapViewController updateCone];
    //[self.viewController.mapViewController mapView:self.viewController.mapViewController.mapView rendererForOverlay:self.viewController.mapViewController.cone];

    //[(cwtMapViewController*)self.viewController.mapViewController drawCone];
     
    
//    if(self.lastHeadingAccuracy!=self.headingAccuracy){
//        if( (self.headingAccuracy <=22 && self.headingAccuracy>-1) || self.headingAccuracy==-2)
//
//            //testing
//        //if( (self.headingAccuracy <=5 && self.headingAccuracy>-1) || self.headingAccuracy==-2)
//
//        {
//            [self.overlay hideTemporary];
//        }
//        else
//        {
//            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(shrink) object:nil];
//            [self.overlay show];
//            if(self.overlay.isShrinked==YES) [self.overlay setShrinked:NO animated:YES ];
//            [self.overlay postImmediateMessage:[NSString stringWithFormat:@"Compass Accuracy: ±%i°",(int)(self.headingAccuracy)]  duration:3.0 ];
//            [self.overlay postErrorMessage:@"move away from interference" duration:3.0 ];
//            [self.overlay postErrorMessage:@"wave in ∞ motion to calibrate compass" duration:0];
//
//            //[overlay setShrinked:YES animated:YES];
//            //if(self.overlay.isShrinked==NO) [self performSelector:@selector(shrink) withObject:nil afterDelay:12.0];
//        }
//        self.lastHeadingAccuracy=self.headingAccuracy;
//    }
//
    

    
    
}


//-(void) shrink{
//        [self.overlay setShrinked:YES animated:YES];
//}

-(void)addNewDestination:(NSString *)name newlat:(double)_lat newlng:(double)_lng{
	
    
	//clear last search text
	[[NSUserDefaults standardUserDefaults] setObject:@"" forKey:@"lastSearchText"];
    
	//set current values
	[[NSUserDefaults standardUserDefaults] setFloat:_lat forKey:@"currentLat"];
	[[NSUserDefaults standardUserDefaults] setFloat:_lng forKey:@"currentLng"];
	[[NSUserDefaults standardUserDefaults] setObject:name forKey:@"currentDestination"];
	
 	//set save path
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSString *path = [documentsDirectory stringByAppendingPathComponent:@"/locationList.plist"];
	
  	NSArray *keys = [NSArray arrayWithObjects:@"searchedText", @"address", @"lat", @"lng", nil];
    
    //save to locationList

    [self.locationDictionaryArray addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects: [[NSUserDefaults standardUserDefaults] stringForKey:@"currentDestination"], @"123 place", [[NSUserDefaults standardUserDefaults] stringForKey:@"currentLat"], [[NSUserDefaults standardUserDefaults] stringForKey:@"currentLng"], nil] forKeys:keys]];
    
	//write to file
	bool didWrite=[self.locationDictionaryArray writeToFile:path atomically:YES];
    
	if(didWrite){
        [self loadmyLocations];

		[[NSUserDefaults standardUserDefaults] setInteger:[self.locationDictionaryArray count]-1 forKey:@"currentDestinationN"];
		
        NSLog(@"Saved destination. nDestinations: %i", (int)[self.locationDictionaryArray count]);

	}
    
    
   [self iCloudSync];
    
    
    
}

-(void)iCloudSync{
    // Save To iCloud
    NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
    
    if (store != nil) {
        [store setObject:self.locationDictionaryArray forKey:@"locations"];
        [store synchronize];
        NSLog(@"iCloud Sync Upload");
    }
}



- (void)updateKeyValuePairs:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    NSNumber *changeReason = [userInfo objectForKey:NSUbiquitousKeyValueStoreChangeReasonKey];
    NSInteger reason = -1;
    NSLog(@"iCloud Sync Download");

    // Is a Reason Specified?
    if (!changeReason) {
        return;
        
    } else {
        reason = [changeReason integerValue];
    }
    
    // Proceed If Reason Was (1) Changes on Server or (2) Initial Sync
    if ((reason == NSUbiquitousKeyValueStoreServerChange) || (reason == NSUbiquitousKeyValueStoreInitialSyncChange)) {
        NSArray *changedKeys = [userInfo objectForKey:NSUbiquitousKeyValueStoreChangedKeysKey];
        NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
        
        // Search Keys for "locations" Key
        for (NSString *key in changedKeys) {
            if ([key isEqualToString:@"locations"]) {
                // Update Data Source
                self.locationDictionaryArray = [NSMutableArray arrayWithArray:[store objectForKey:key]];
                
                // Save Local Copy
                NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
                [ud setObject:self.locationDictionaryArray forKey:@"locations"];
                
                NSLog(@"update locationDictionaryArray");

                // Reload Table View
                //[self.tableView reloadData];
            }
        }
    }
}



-(void)editDestination:(NSString *)name newlat:(double)_lat newlng:(double)_lng{
    //get old values
    int currentDestinationN=(int)[[NSUserDefaults standardUserDefaults] integerForKey:@"currentDestinationN"];
	//load dictionary
	NSMutableDictionary * dictionary = [self.locationDictionaryArray objectAtIndex:currentDestinationN];
    
	[[NSUserDefaults standardUserDefaults] setObject:name forKey:@"currentDestination"];

    //replace with new value
    
    NSArray *keys = [NSArray arrayWithObjects:@"searchedText", @"address", @"lat", @"lng", nil];
    float lat;
    float lng;
    
    //check if lat lng is 0 for editing name only
    if(_lat==0 && _lng==0){
        lat=[[dictionary valueForKey:@"lat"] floatValue];
        lng=[[dictionary valueForKey:@"lng"] floatValue];
    }
    else{        
        lat=_lat;
        lng=_lng;
    }
    
    
    [self.locationDictionaryArray  replaceObjectAtIndex:[[NSUserDefaults standardUserDefaults] integerForKey:@"currentDestinationN"] withObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects: [[NSUserDefaults standardUserDefaults] stringForKey:@"currentDestination"], @"123 place", [NSNumber numberWithFloat:lat], [NSNumber numberWithFloat:lng], nil] forKeys:keys]];
    
    //save nsmutablearray
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"/locationList.plist"];
    [self.locationDictionaryArray writeToFile:path atomically:YES];
    
    [(cwtViewController3*)self.window.rootViewController updateViewControllersWithLatLng: (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"currentDestinationN"]];
    [(cwtViewController3*)self.window.rootViewController updateViewControllersWithName];
    
    [self iCloudSync];

        
}




- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    [self.locationManager stopUpdatingHeading];
    [self.locationManager stopUpdatingLocation];
    
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    [self loadmyLocations];

}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
    self.heading=999;
    self.headingAccuracy=-2;
    self.lastHeadingAccuracy=-3;

    
    

    // Create the manager object
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self.locationManager requestWhenInUseAuthorization];
    }

    // This is the most important property to set for the manager. It ultimately determines how the manager will
    // attempt to acquire location and thus, the amount of power that will be consumed.
    //self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;

    // When "tracking" the user, the distance filter can be used to control the frequency with which location measurements
    // are delivered by the manager. If the change in distance is less than the filter, a location will not be delivered.
    self.locationManager.distanceFilter = kCLDistanceFilterNone;
    
    // Once configured, the location manager must be "started".
    [self.locationManager startUpdatingLocation];
    
    //heading
    self.locationManager.headingFilter = kCLHeadingFilterNone;
    [self.locationManager startUpdatingHeading];
    

}



- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

-(BOOL)shouldAutorotate{
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}


@end

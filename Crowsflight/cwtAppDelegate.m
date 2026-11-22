//
//  cwtAppDelegate.m
//  Crowsflight
//
//  Created by Che-Wei Wang on 5/4/13.
//  Copyright (c) 2013 CW&T. All rights reserved.
////#import <Crashlytics/Crashlytics.h>

#import "cwtAppDelegate.h"
#import "UINavigationController+GZDrawer.h"
#import "cwtListViewController.h"
#import "cwtViewController3.h"
#import "cwtUITableViewController.h"
//#import "cwtIAP.h"
#import "cwtMapViewController.h"
#import "Reachability.h"
//#import "NVSlideMenuController.h"
#import "QuartzCore/CALayer.h"
#import "cwtMapViewController.h"
#import "Crowsflight-Swift.h"


@interface cwtAppDelegate ()<UIAlertViewDelegate,CLLocationManagerDelegate,UIAppearanceContainer,WCSessionDelegate>{//,MTStatusBarOverlayDelegate>
    WCSession *session;
}
@property (nonatomic, strong) Reachability *reachability;
- (void)setUpWindowInScene:(UIWindowScene *)scene;
@end

// Apps built with the iOS 27 SDK must use the UIScene lifecycle or UIKit traps at launch.
// Thin shim (named in Info.plist UIApplicationSceneManifest): all logic stays in cwtAppDelegate.
@interface cwtSceneDelegate : UIResponder <UIWindowSceneDelegate>
@end

@implementation cwtSceneDelegate

- (cwtAppDelegate *)app { return (cwtAppDelegate *)[UIApplication sharedApplication].delegate; }

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    if (![scene isKindOfClass:[UIWindowScene class]]) return;
    [[self app] setUpWindowInScene:(UIWindowScene *)scene];
    [self scene:scene openURLContexts:connectionOptions.URLContexts];
}

- (void)scene:(UIScene *)scene openURLContexts:(NSSet<UIOpenURLContext *> *)URLContexts {
    for (UIOpenURLContext *context in URLContexts) {
        [[self app] application:[UIApplication sharedApplication] openURL:context.URL options:@{}];
    }
}

//the window changed size (iPhone Duo folded/unfolded, or moved between its cover and inner
//displays). an open list/map drawer slides a screenshot of the old-size compass aside, so
//it cannot follow the new size: close it and let the compass re-lay out.
//ponytail: closes the drawer rather than re-flowing it in place; re-push it after the
//resize if staying in the list/map across a fold ever matters.
- (void)windowSizeMayHaveChanged:(UIWindowScene *)windowScene {
    static CGSize lastSize;
    CGSize size = windowScene.coordinateSpace.bounds.size;
    if (CGSizeEqualToSize(size, lastSize)) return;
    BOOL first = CGSizeEqualToSize(lastSize, CGSizeZero);
    lastSize = size;
    if (!first) [[self app].navController popDrawerViewController:NO];
}

//iOS 26+
- (void)windowScene:(UIWindowScene *)windowScene didUpdateEffectiveGeometry:(UIWindowSceneGeometry *)previousEffectiveGeometry {
    [self windowSizeMayHaveChanged:windowScene];
}

//iOS 15-25
- (void)windowScene:(UIWindowScene *)windowScene didUpdateCoordinateSpace:(id<UICoordinateSpace>)previousCoordinateSpace interfaceOrientation:(UIInterfaceOrientation)previousInterfaceOrientation traitCollection:(UITraitCollection *)previousTraitCollection {
    [self windowSizeMayHaveChanged:windowScene];
}

- (void)sceneDidBecomeActive:(UIScene *)scene { [[self app] applicationDidBecomeActive:[UIApplication sharedApplication]]; }
- (void)sceneWillResignActive:(UIScene *)scene { [[self app] applicationWillResignActive:[UIApplication sharedApplication]]; }
- (void)sceneDidEnterBackground:(UIScene *)scene { [[self app] applicationDidEnterBackground:[UIApplication sharedApplication]]; }
- (void)sceneWillEnterForeground:(UIScene *)scene { [[self app] applicationWillEnterForeground:[UIApplication sharedApplication]]; }

@end

CGRect CFScreenBounds(void) {
    UIWindow *window = ((cwtAppDelegate *)[UIApplication sharedApplication].delegate).window;
    return window ? window.bounds : [UIScreen mainScreen].bounds;
}

CGFloat CFListWidth(void) {
    cwtAppDelegate *app = (cwtAppDelegate *)[UIApplication sharedApplication].delegate;
    if (app.rootController.listPaneWidth > 0) return app.rootController.listPaneWidth;
    return CFScreenBounds().size.width - MAX(40.0, app.window.safeAreaInsets.right);
}

@implementation cwtRootViewController {
    cwtListViewController *list;
}

- (cwtAppDelegate *)app { return (cwtAppDelegate *)[UIApplication sharedApplication].delegate; }

- (void)viewDidLoad {
    [super viewDidLoad];
    //shows in the left safe-area strip beside the list pane, so match the list
    self.view.backgroundColor = [UIColor colorWithRed:1.0 green:78/255.0f blue:36/255.0f alpha:1];
    UINavigationController *nav = [self app].navController;
    [self addChildViewController:nav];
    //the compass wedge and the sliding drawer cover are larger than their pane
    nav.view.clipsToBounds = YES;
    [self.view addSubview:nav.view];
    [nav didMoveToParentViewController:self];
}

//landscape is offered only where both panes fit (an unfolded iPhone Duo); every other
//iPhone, and the Duo's cover screen, stay portrait as before
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    CGSize size = CFScreenBounds().size;
    return MIN(size.width, size.height) >= 600 ? UIInterfaceOrientationMaskAllButUpsideDown : UIInterfaceOrientationMaskPortrait;
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    CGSize size = self.view.bounds.size;
    CGFloat safeLeft = self.view.safeAreaInsets.left;
    BOOL split = size.width > size.height && size.height >= 600;
    CGFloat pane = split ? MIN(360.0, (size.width - safeLeft)*0.45) : 0;

    //the list lays its rows out for one width when it is built, so rebuild it if that changes
    if (list && pane != _listPaneWidth) {
        [list willMoveToParentViewController:nil];
        [list.view removeFromSuperview];
        [list removeFromParentViewController];
        list = nil;
    }
    _listPaneWidth = pane;  //before building the list: it sizes itself with CFListWidth()
    if (split && !list) {
        //coming from portrait with the list drawer still open: put the compass back first
        [[self app].navController popDrawerViewController:NO];
        list = [[cwtListViewController alloc] init];
        [self addChildViewController:list];
        list.view.clipsToBounds = YES;
        [self.view addSubview:list.view];
        [list didMoveToParentViewController:self];
    }
    list.view.frame = CGRectMake(safeLeft, 0, pane, size.height);
    CGFloat x = split ? safeLeft + pane : 0;
    [self app].navController.view.frame = CGRectMake(x, 0, size.width - x, size.height);

    //the window can cross the landscape threshold when the phone folds/unfolds
    if (@available(iOS 16.0, *)) [self setNeedsUpdateOfSupportedInterfaceOrientations];

    //headings are reported relative to the top of the device; keep them relative to the
    //top of the interface now that it can be landscape (interface left == device right)
    UIWindowScene *scene = self.view.window.windowScene;
    if (scene) {
        UIInterfaceOrientation o;
        if (@available(iOS 16.0, *)) o = scene.effectiveGeometry.interfaceOrientation;
        else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            o = scene.interfaceOrientation;
#pragma clang diagnostic pop
        }
        CLDeviceOrientation heading = CLDeviceOrientationPortrait;
        if (o == UIInterfaceOrientationLandscapeLeft) heading = CLDeviceOrientationLandscapeRight;
        else if (o == UIInterfaceOrientationLandscapeRight) heading = CLDeviceOrientationLandscapeLeft;
        else if (o == UIInterfaceOrientationPortraitUpsideDown) heading = CLDeviceOrientationPortraitUpsideDown;
        [self app].locationManager.headingOrientation = heading;
    }
}

- (cwtUITableViewController *)table { return (cwtUITableViewController *)list.childViewControllers.firstObject; }

- (void)reloadList { [[self table].tableView reloadData]; }

//the drawer list is rebuilt, with fresh distances, every time it opens; beside the compass
//it stays up, so refresh its distances as we move - but never under the user's finger.
//ponytail: whole-table reload at most every 10s; update just the distance labels in place
//if this ever shows as a flicker.
- (void)locationMoved {
    if (!list) return;
    static CFAbsoluteTime last;
    CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
    cwtUITableViewController *table = [self table];
    if (now - last < 10 || table.tableView.isDragging || table.tableView.isDecelerating
        || [table isDraggingCell] || table.currentlyActiveSlidingCell) return;
    last = now;
    [self reloadList];
}

//as a drawer the list is rebuilt every time it opens and the compass reloads when the
//drawer closes. side by side neither happens, so sync them here. deferred a turn: callers
//are mid-edit (row deletion/reordering) and finish their own table updates first.
- (void)locationsChanged {
    if (!list) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self->list) return;
        [[self app].viewController viewWillAppear:NO]; //clamps the current destination + reloads the pager
        [self reloadList];
    });
}

- (void)currentDestinationChanged {
    if (!list) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self reloadList];
        //follow the compass: bring its destination's row into view if it is off-screen
        cwtUITableViewController *table = [self table];
        NSInteger n = [[NSUserDefaults standardUserDefaults] integerForKey:@"currentDestinationN"];
        if (table && !table.isFiltered && n >= 0 && n < [table.tableView numberOfRowsInSection:0]) {
            [table.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:n inSection:0]
                                   atScrollPosition:UITableViewScrollPositionNone animated:YES];
        }
    });
}

@end

@implementation cwtAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{

    //[Crashlytics startWithAPIKey:@"1eb6d15737d50f2df4316cb5b8b073da76a42b67"];

    //[cwtIAP sharedInstance];

    
    [self loadmyLocations];

    // The window is created in -setUpWindowInScene: once the scene connects (cwtSceneDelegate, bottom of this file).

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
    
    

    // Defer Reachability setup off the critical launch path — runs after the first frame.
    // hasInternet defaults to NO (BOOL zero-init); callbacks fire async regardless, so
    // deferring preserves the same pre-callback default as before.
    dispatch_async(dispatch_get_main_queue(), ^{
        self.reachability = [Reachability reachabilityForInternetConnection];
        __weak __typeof(self) weakSelf = self;
        self.reachability.reachableBlock = ^(Reachability *r) {
#ifdef DEBUG
            NSLog(@"REACHABLE!");
#endif
            weakSelf.hasInternet = YES;
        };
        self.reachability.unreachableBlock = ^(Reachability *r) {
#ifdef DEBUG
            NSLog(@"UNREACHABLE!");
#endif
            weakSelf.hasInternet = NO;
        };
        [self.reachability startNotifier];
    });

    // Defer iCloud KVS observer + sync off the critical launch path.
    // loadmyLocations already ran synchronously above, so the KVS callback
    // can safely overwrite locationDictionaryArray whenever it fires.
    dispatch_async(dispatch_get_main_queue(), ^{
        NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(updateKeyValuePairs:)
                                                     name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification
                                                   object:store];
        [store synchronize];
    });
    
    [self activateASession];

    
    return YES;
}


- (void)setUpWindowInScene:(UIWindowScene *)scene {
    self.window = [[UIWindow alloc] initWithWindowScene:scene];
    self.viewController = [[cwtViewController3 alloc] init];
    self.navController = [[UINavigationController alloc] initWithRootViewController:self.viewController];
    [self.navController setNavigationBarHidden:YES animated:NO];

    self.rootController = [[cwtRootViewController alloc] init];
    self.window.rootViewController = self.rootController;
    [self.window makeKeyAndVisible];
}


-(void)activateASession{
    if ([WCSession isSupported]) {
        session = [WCSession defaultSession];
        session.delegate = self;
        [session activateSession];

        if([session activationState]!=WCSessionActivationStateActivated){
               //[session activateSession];
           }
        NSLog(@"Session on phone starting");
    }
    
}


- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {

    // Widget deep link: crowsflight://destination/<n> selects that destination.
    if ([[url scheme] isEqualToString:@"crowsflight"] && [[url host] isEqualToString:@"destination"]) {
        NSInteger n = [[[url path] lastPathComponent] integerValue];
        if (n >= 0 && n < self.nDestinations) {
            [[NSUserDefaults standardUserDefaults] setInteger:n forKey:@"currentDestinationN"];
            if (self.viewController) {
                [self.viewController flipToPage:n];
            }
        }
        return YES;
    }

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
    [self.rootController locationsChanged];


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


- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {

    CLLocation *newLocation = [locations lastObject];

    // test the age of the location measurement to determine if the measurement is cached
    // in most cases you will not want to rely on cached measurements
    NSTimeInterval locationAge = -[newLocation.timestamp timeIntervalSinceNow];
    if (locationAge > 5.0) return; //5 seconds

    [self ingestLocation:newLocation];
}

// Apply a fix to app-delegate state and refresh the per-page UI. Shared by the
// live location callback and applicationDidBecomeActive: (which re-delivers the
// manager's cached last fix so the arrow/distance render instantly on resume
// instead of showing the satellite-search state until a fresh callback arrives).
- (void)ingestLocation:(CLLocation *)newLocation {

    if (newLocation == nil) return;

    // test that the horizontal accuracy does not indicate an invalid measurement
    self.accuracy=newLocation.horizontalAccuracy;
    if (self.accuracy < 0) return;

    //simply get the speed provided by the phone from newLocation
    self.speed = newLocation.speed;

    // course over ground (direction of travel) — used to fake a heading in the widget
    self.course = newLocation.course;

    self.altitude= newLocation.altitude;
    self.altitudeAccuracy= newLocation.verticalAccuracy;

    // update the display with the new location data

    self.myLat=newLocation.coordinate.latitude;
    self.myLng=newLocation.coordinate.longitude;

    [self.viewController updateViewControllersWithLatLng: (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"currentDestinationN"]];

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

    [self.viewController updateViewControllersWithHeading:(int)[[NSUserDefaults standardUserDefaults] integerForKey:@"currentDestinationN"]];
    
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
    [self transferLocations];

}

#pragma mark - Share extension inbox

static NSString * const kAppGroupID = @"group.com.cwandt.crowsflight";
static NSString * const kPendingImportsKey = @"pendingImports";

-(NSInteger)indexOfDestinationMatchingLat:(double)lat lng:(double)lng{
    for (NSUInteger i = 0; i < [self.locationDictionaryArray count]; i++) {
        NSDictionary *d = [self.locationDictionaryArray objectAtIndex:i];
        double dlat = [[d objectForKey:@"lat"] doubleValue];
        double dlng = [[d objectForKey:@"lng"] doubleValue];
        if (fabs(dlat - lat) < 0.5e-4 && fabs(dlng - lng) < 0.5e-4) {
            return (NSInteger)i;
        }
    }
    return -1;
}

-(void)drainPendingImports{
    NSUserDefaults *shared = [[NSUserDefaults alloc] initWithSuiteName:kAppGroupID];
    NSArray *pending = [shared arrayForKey:kPendingImportsKey];
    if ([pending count] == 0) return;
    [shared removeObjectForKey:kPendingImportsKey];

    for (NSDictionary *item in pending) {
        if (![item isKindOfClass:[NSDictionary class]]) continue;
        NSString *name = [item objectForKey:@"searchedText"];
        double lat = [[item objectForKey:@"lat"] doubleValue];
        double lng = [[item objectForKey:@"lng"] doubleValue];

        if (![name isKindOfClass:[NSString class]] || [name length] == 0) continue;
        if (lat == 0.0 && lng == 0.0) continue;
        if (fabs(lat) > 90.0 || fabs(lng) > 180.0) continue;

        NSInteger existing = [self indexOfDestinationMatchingLat:lat lng:lng];
        if (existing >= 0) {
            [[NSUserDefaults standardUserDefaults] setInteger:existing forKey:@"currentDestinationN"];
            NSLog(@"Import: duplicate of %ld, selecting it", (long)existing);
        } else {
            [self addNewDestination:name newlat:lat newlng:lng];
            NSLog(@"Import: added %@", name);
        }
    }

    if (self.viewController) {
        [self.viewController flipToPage:[[NSUserDefaults standardUserDefaults] integerForKey:@"currentDestinationN"]];
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
    
    [self.viewController updateViewControllersWithLatLng: (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"currentDestinationN"]];
    [self.viewController updateViewControllersWithName];
    
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

    // Write a fresh snapshot for the CURRENT destination before backgrounding, so the
    // widget reflects whatever the user was just viewing (the per-update write only
    // fires on location ticks, which may not happen right after switching places).
    [self refreshWidgetSnapshot];
    [WidgetBridge reloadAll];
}

// Publish the current destination + last-known fix to the widget's app group.
- (void)refreshWidgetSnapshot {
    NSInteger n = [[NSUserDefaults standardUserDefaults] integerForKey:@"currentDestinationN"];
    if (n < 0 || n >= (NSInteger)[self.locationDictionaryArray count]) return;
    NSDictionary *d = [self.locationDictionaryArray objectAtIndex:n];
    NSString *name = [d objectForKey:@"searchedText"];
    if (![name isKindOfClass:[NSString class]]) name = @"";
    double dlat = [[d objectForKey:@"lat"] doubleValue];
    double dlng = [[d objectForKey:@"lng"] doubleValue];
    [WidgetBridge writeSnapshotWithName:name
                                destLat:dlat
                                destLng:dlng
                                  index:n
                                  count:self.nDestinations
                                userLat:self.myLat
                                userLng:self.myLng
                               accuracy:self.accuracy
                                  units:self.units
                                 course:self.course
                                heading:(self.headingAccuracy >= 0 ? self.heading : -1)];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    [self loadmyLocations];

}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [self drainPendingImports];

    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [UIApplication sharedApplication].idleTimerDisabled = YES;

    // NOTE: do NOT reset headingAccuracy here. On resume from background all of
    // myLat/myLng/accuracy/heading/headingAccuracy survived, so the stale-but-valid
    // values are the correct resume state. Forcing headingAccuracy=-2 on every
    // activation made the per-page UI fall back to the satellite-search state until
    // a fresh heading callback arrived. The -2 sentinel is set once at launch
    // (didFinishLaunching); the first fresh heading callback (sub-second once
    // updates restart below) corrects the accuracy either way.



    // Create the manager object once; re-use on subsequent activations.
    if (self.locationManager == nil) {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
            [self.locationManager requestWhenInUseAuthorization];
        }

        // This is the most important property to set for the manager. It ultimately determines how the manager will
        // attempt to acquire location and thus, the amount of power that will be consumed.
        self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;

        // Deliver location updates only when the user has moved at least 5 metres.
        self.locationManager.distanceFilter = 5;

        // Deliver heading updates only when the bearing changes by at least half a degree.
        self.locationManager.headingFilter = 0.5;

        // App is foreground-only for location (updates stopped on resign-active), so
        // auto-pause saves little but risks a stale distance display after the user
        // stands still (no pauseLocationUpdates/resumeLocationUpdates delegate handling exists).
        self.locationManager.activityType = CLActivityTypeFitness;
        self.locationManager.pausesLocationUpdatesAutomatically = NO;
    }

    // (Re-)start updates every activation; the manager is stopped in applicationWillResignActive:.
    [self.locationManager startUpdatingLocation];
    [self.locationManager startUpdatingHeading];

    // Instant-ready on resume: immediately re-deliver the manager's cached last fix
    // so the arrow/distance render without waiting for a fresh location callback
    // (which can take a few seconds on a real device). Guarded so it is a no-op on a
    // true cold start (manager.location == nil) and before the UI exists — in that
    // case the searching state shows exactly as before until the first fix.
    if (self.window.rootViewController != nil && self.locationManager.location != nil) {
        [self ingestLocation:self.locationManager.location];
    }

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

-(void)transferLocations{
    NSMutableArray<NSString *> *names = [NSMutableArray array];
    NSMutableArray<NSNumber *> *lats = [NSMutableArray array];
    NSMutableArray<NSNumber *> *lngs = [NSMutableArray array];
    for (NSDictionary *d in self.locationDictionaryArray) {
        NSString *name = [d objectForKey:@"searchedText"];
        [names addObject:[name isKindOfClass:[NSString class]] ? name : @""];
        [lats addObject:@([[d objectForKey:@"lat"] doubleValue])];
        [lngs addObject:@([[d objectForKey:@"lng"] doubleValue])];
    }
    [WatchSyncBridge pushDestinationsWithNames:names lats:lats lngs:lngs
                                         units:(self.units ?: @"m")];
}





- (void)session:(nonnull WCSession *)session activationDidCompleteWithState:(WCSessionActivationState)activationState error:(nullable NSError *)error { 
    NSLog(@"activation complete");

    [self transferLocations];

}

- (void)session:(nonnull WCSession *)session didFinishFileTransfer:(nonnull WCSessionFileTransfer *)fileTransfer error:(nullable NSError *)error {
    NSLog(@"file transfer complete");

}


- (void)sessionDidBecomeInactive:(nonnull WCSession *)session { 
    
}

- (void)sessionDidDeactivate:(nonnull WCSession *)session { 
    [self activateASession];

}





@end

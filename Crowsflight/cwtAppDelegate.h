//
//  cwtAppDelegate.h
//  Crowsflight
//
//  Created by Che-Wei Wang on 5/4/13.
//  Copyright (c) 2013 CW&T. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
//#import "MTStatusBarOverlay.h"
//#import "TestFlight.h"
#import <WatchConnectivity/WatchConnectivity.h>



//size of the app's window. use this instead of [UIScreen mainScreen].bounds: on an
//iPhone Duo the window is not necessarily the size of the main screen (cover vs inner
//display) and it changes when the phone folds/unfolds.
CGRect CFScreenBounds(void);

//width of the list drawer: the window minus the strip of compass left showing beside it.
//that strip is 40pt, or the right safe-area inset when that is wider - the iPhone Duo's
//cover screen keeps its camera and status items in an 84pt column down the right edge,
//so the strip widens to hold them and the list rows stay clear.
CGFloat CFListWidth(void);

@class cwtViewController3;

@interface cwtAppDelegate : UIResponder <UIApplicationDelegate>{
    //MTStatusBarOverlay *overlay;

}

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic) int nDestinations;
@property (strong, nonatomic) cwtViewController3 *viewController;
@property (nonatomic, strong) NSMutableArray *locationDictionaryArray;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) NSString *units;// "m" = imperial, "km" = metric, "nm" = nautical
@property (nonatomic) float myLat;
@property (nonatomic) float myLng;
@property (nonatomic) float heading;
@property (nonatomic) float headingAccuracy;
@property (nonatomic) float lastHeadingAccuracy;
@property (nonatomic) float speed;
@property (nonatomic) float course;// course over ground, degrees from north; <0 when invalid
@property (nonatomic) float altitude;
@property (nonatomic) float altitudeAccuracy;


@property (nonatomic) float accuracy;
@property (nonatomic,strong) UINavigationController *navController;

//@property (nonatomic,assign)    MTStatusBarOverlay *overlay;

-(void) loadmyLocations;
- (void) copyFile;

-(void)addNewDestination:(NSString *)name newlat:(double)_lat newlng:(double)_lng;
-(void)editDestination:(NSString *)name newlat:(double)_lat newlng:(double)_lng;
-(void)iCloudSync;
-(void)drainPendingImports;
-(void)transferLocations;


@property (nonatomic) BOOL hasInternet;


@end

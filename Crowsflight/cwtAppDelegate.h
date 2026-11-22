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

//width of the list. beside the compass (landscape split) it is the list pane; as a drawer
//it is the window minus the strip of compass left showing beside it.
//that strip is 40pt, or the right safe-area inset when that is wider - the iPhone Duo's
//cover screen keeps its camera and status items in an 84pt column down the right edge,
//so the strip widens to hold them and the list rows stay clear.
CGFloat CFListWidth(void);

@class cwtViewController3;

//root of the window. holds the compass (inside navController) and, when the window is
//landscape and roomy enough (an unfolded iPhone Duo), the destination list beside it
//instead of as a drawer.
@interface cwtRootViewController : UIViewController
@property (nonatomic, readonly) CGFloat listPaneWidth;  //0 while the list is a drawer
- (void)locationsChanged;           //the saved destinations were added to/removed/reordered
- (void)currentDestinationChanged;  //the compass settled on another destination
- (void)locationMoved;              //a new GPS fix arrived
@end

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
@property (nonatomic,strong) cwtRootViewController *rootController;

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

//
//  cwtViewController.h
//  Crowsflight
//
//  Created by Che-Wei Wang on 5/4/13.
//  Copyright (c) 2013 CW&T. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "cfLocationViewController2.h"
#import <MapKit/MapKit.h>
#import "cwtListViewController.h"
#import "UINavigationController+GZDrawer.h"
#import "cwtAppDelegate.h"
#import "SIAlertView.h"
#import "cwtToolBar.h"
#import <AudioToolbox/AudioToolbox.h>
//#import <W3wSDK/W3wSDK.h>
#import "cwtMapViewController.h"

@interface cwtViewController3 : UIViewController <UITextFieldDelegate>{
    
    
    SIAlertView *searchAlert;
    SIAlertView *addLocAlert;
   // UIAlertView *inappAlert;
    //SIAlertView* progressAlert;
    
    cwtAppDelegate* dele;
    UIButton *moreInfo;
    SystemSoundID audioCreate;
    NSMutableData *_responseData;


}
-(void)updateViewControllersWithName;
-(void)updateViewControllersWithLatLng: (int)_page;
-(void)updateViewControllersWithHeading: (int)_page;
-(void)showLocationEditAlert;
-(void) flipToPage:(NSInteger)x;


@property (nonatomic,strong) UIPageViewController *pageView;
@property (nonatomic,strong) cfLocationViewController2* locationViewController;
@property (nonatomic,strong) cwtListViewController * listViewController;
@property (nonatomic, strong) cwtMapViewController *mapViewController;

@property (nonatomic,strong)  cwtToolbar *toolBar;

-(IBAction) openListView:(id)sender;

-(void)addLocation:(CLLocationCoordinate2D)coordinate title:(NSString *)name;

-(IBAction) showSearch:(id)sender;
-(void)searchGeo:(UITextField*)searchField;

//@property(nonatomic, strong, readonly) UISearchBar *searchBar;

@property (nonatomic,strong) IBOutlet UIImageView *compassImage;
@property (nonatomic,strong) IBOutlet UIImageView *compassN;
@property (nonatomic,assign) BOOL showInfo;
@property (nonatomic,assign) BOOL showMapBool;
@property (nonatomic,assign) BOOL showListBool;

//-(void)checkPurchased;
//-(void)purchase;

@property (nonatomic, strong) NSArray *places;
@property (nonatomic, assign) MKCoordinateRegion boundingRegion;
@property (nonatomic, strong) MKLocalSearch *localSearch;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic) CLLocationCoordinate2D userLocation;

@property (nonatomic, strong) UIImageView  *instructions;
-(void)nextInstruction:(int)n;

//@property (nonatomic, strong) W3wSDK *w3wSDK;


@end


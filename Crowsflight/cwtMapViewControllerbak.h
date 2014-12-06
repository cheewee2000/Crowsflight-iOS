//
//  cwtUIMapViewController.h
//  Crowsflight
//
//  Created by Che-Wei Wang on 5/24/13.
//  Copyright (c) 2013 CW&T. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
//#import <MessageUI/MFMailComposeViewController.h>
#import "cwtAppDelegate.h"
#import <QuartzCore/QuartzCore.h>

@interface cwtMapViewController : UIViewController
<MKMapViewDelegate>
{
    
    MKMapView *mapView;

    float lat;
    float lng;
    NSString *name;
    @public BOOL wasSearchView;
    cwtAppDelegate* dele;
    UILongPressGestureRecognizer *lpgr;
    BOOL allowLongpress;
}


@property (strong, nonatomic)  UIButton *overlayButton;
@property (strong, nonatomic)  UIButton *mapButton;

@property (strong, nonatomic) IBOutlet MKMapView *mapView;
@property (nonatomic, readwrite, assign) CLLocationCoordinate2D coordinate;
@property (nonatomic, weak) CAShapeLayer *circleLayer;


- (void) zoomMapAndCenterAtLatitude:(double) latitude andLongitude:(double) longitude andName:(NSString*) title;
- (void) zoomLoadPoints;
- (void) zoomLoadSearchResults:(NSArray*)placemarks;

//- (IBAction)saveLocation:(id)sender;

//- (IBAction)actionButtonClicked:(UIBarButtonItem*)sender event:(UIEvent*)event;
//- (IBAction)mapTypeButtonClicked:(UISegmentedControl*)sender;

//- (IBAction)back:(id)sender;


@end
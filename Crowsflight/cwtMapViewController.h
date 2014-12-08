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
#import <AudioToolbox/AudioToolbox.h>
#import "cwtAnnotation.h"


@interface cwtMapViewController : UIViewController
<MKMapViewDelegate>
{
    
    MKMapView *mapView;
    
    NSString *name;
@public BOOL wasSearchView;
    cwtAppDelegate* dele;
    UILongPressGestureRecognizer *lpgr;
    BOOL allowLongpress;
    //SystemSoundID audioDrag;
    //SystemSoundID audioDrop;
    //SystemSoundID audioLongpress;
    SystemSoundID audioCreate;
    //SystemSoundID audioSelect3;

}


@property (strong, nonatomic)  UIButton *overlayButton;
@property (strong, nonatomic)  UIButton *mapButton;

@property (strong, nonatomic) IBOutlet MKMapView *mapView;
@property (nonatomic, readwrite, assign) CLLocationCoordinate2D coordinate;
@property (nonatomic, weak) CAShapeLayer *circleLayer;


//- (void) zoomMapAndCenterAtLatitude:(double) latitude andLongitude:(double) longitude andName:(NSString*) title;
//- (void) zoomLoadPoints;
//- (void) zoomLoadSearchResults:(NSArray*)mapItems setRegion:(MKCoordinateRegion)region;

//- (IBAction)saveLocation:(id)sender;

//- (IBAction)actionButtonClicked:(UIBarButtonItem*)sender event:(UIEvent*)event;
//- (IBAction)mapTypeButtonClicked:(UISegmentedControl*)sender;

//- (IBAction)back:(id)sender;


@property (nonatomic, strong) NSArray *mapItemList;
@property (nonatomic, assign) MKCoordinateRegion boundingRegion;
@property (nonatomic, strong) cwtAnnotation *annotation;


@property (nonatomic, strong) UIImageView  *instructions;
//-(void)nextInstruction;


@end
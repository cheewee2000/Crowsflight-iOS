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

    BOOL locationLoaded;
    // One-shot: on a cold first open the MKMapView may not have produced an
    // MKUserLocation yet when updateMap runs, so setUserTrackingMode can no-op.
    // Arm this in updateMap and engage FollowWithHeading once in didUpdateUserLocation.
    BOOL wantsFollowOnFirstFix;
    // Follow-engagement guard: MapKit can silently DROP an animated
    // setUserTrackingMode:FollowWithHeading requested DURING the drawer-push
    // transition. Cold-open trace: didChangeUserTrackingMode reports mode 2
    // IMMEDIATELY ON REQUEST (not on stick), then the real drop to 0 lands
    // ~115ms later — so success must be CONFIRMED after a delay, never on the
    // first mode-2 callback. Stay ARMED until a mode-2 observation survives a
    // ~0.7s confirm; on a None-revert while still armed, re-engage after ~0.3s,
    // bounded by followRetryCount (proven: engages ~300ms+ after the transition
    // always stick). followArmGeneration invalidates stale timers from a prior
    // open, and a 5s safety disarm scheduled at arming caps how long a user pan
    // inside the open window can ever be fought.
    BOOL followEngagePending;
    int  followRetryCount;
    int  followArmGeneration;
    // Pin-visible zoom clamp while following: engaging FollowWithHeading resets
    // the camera to its default ~5km altitude, discarding any region we set, so
    // far pins scroll off screen. We clamp the map's cameraZoomRange MIN
    // center-coordinate distance to K * (user->pin meters) so the follow camera
    // is forced UP to a pin-visible altitude (at any compass rotation) while
    // MapKit still owns centering + rotation; it tightens as the user
    // approaches. Records the user->pin distance the clamp was last computed
    // for (0 = no clamp active); re-clamped when it drifts >15%.
    double followClampUserPinDistance;
    // Current-destination pin, remembered so its callout can be re-selected
    // after the tracking-mode hand-off (which can drop the selection).
    cwtAnnotation *selectedAnnotation;
    CAShapeLayer *beam;
    CGPoint startPosition;
    MKCoordinateRegion region;

    
}
- (void)drawCone;
-(void) updateCone;
-(void)centerDeviceLocation;

@property (strong, nonatomic)  MKPolygon *cone;

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
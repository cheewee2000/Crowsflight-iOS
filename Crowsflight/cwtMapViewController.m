//
//  cwtUIMapViewController.m
//  Crowsflight
//
//  Created by Che-Wei Wang on 5/24/13.
//  Copyright (c) 2013 CW&T. All rights reserved.
//

#import "cwtMapViewController.h"
#import "cwtViewController3.h"
#import "SIAlertView.h"
#include <math.h>

#define DEGREES_TO_RADIANS(angle) (angle / 180.0 * M_PI)
#define RADIANS_TO_DEGREES(radians) ((radians) * (180.0 / M_PI))

#define MAP_PADDING 1.5

// --- Pin-visible zoom clamp while following (see followClampUserPinDistance in
// the header). minCameraDistance = FOLLOW_ZOOM_K * (user->pin meters), floored at
// FOLLOW_ZOOM_MIN_DISTANCE so nearby pins keep a sane close-in view.
// K sim-calibrated: visible ground span across the view's SHORT side measured at
// 0.2228 * centerCoordinateDistance (linear across 30/47/60 km probe points), so
// the inscribed-circle radius (pin visible at ANY compass rotation) is
// 0.1114 * distance -> K >= 9.0 just reaches the screen edge; 12.0 gives ~25% margin.
#define FOLLOW_ZOOM_K 12.0
#define FOLLOW_ZOOM_MIN_DISTANCE 800.0
#define FOLLOW_ZOOM_RECALC_FRACTION 0.15


@implementation cwtMapViewController

@synthesize mapView;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        locationLoaded=false;
    }
    
    return self;
}

// Arm the "until it sticks" follow-engagement guard (non-search open paths only).
// Bumps the generation so any timers scheduled by a previous open become stale,
// and schedules an absolute 5s safety disarm: if the engage never confirms (e.g.
// the user deliberately pans within the open window), the guard can never fight
// the user for more than a few seconds.
-(void)armFollowGuard{
    followEngagePending = YES;
    followRetryCount = 0;
    followArmGeneration++;
    int gen = followArmGeneration;
    __weak cwtMapViewController *weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        cwtMapViewController *strongSelf = weakSelf;
        if(strongSelf != nil && strongSelf->followArmGeneration == gen){
            strongSelf->followEngagePending = NO;
        }
    });
}

// Enforcement watchdog for a clamp raise. Sim-traced: a raised zoom-range min
// applied while the follow camera is mid-glide (e.g. still descending to a
// previously lowered min — glides run for many seconds) is silently SWALLOWED
// by MapKit: no tracking-mode event, camera settles below the min, pin off
// screen. Re-applying mid-glide is swallowed again (proved with 3x2s retries),
// but a raise on a SETTLED camera reliably enforces (with the 2->1->2 bounce
// the 0.6s auto-upgrade repairs). So: poll every 2s (up to 15 checks ~30s),
// and only re-apply once two consecutive camera readings match (settled).
// token = the user->pin distance this clamp was computed for, so any newer
// clamp supersedes pending verifies.
-(void)verifyFollowZoomClampMin:(double)minCam token:(double)token attempt:(int)attempt prevCam:(double)prevCam{
    if(followClampUserPinDistance != token) return;   // superseded by a newer clamp
    if(self.mapView.userTrackingMode == MKUserTrackingModeNone) return; // left follow
    double cam = self.mapView.camera.centerCoordinateDistance;
    if(cam >= minCam * 0.98) return;                  // enforced
    if(attempt >= 15) return;                         // give up; next drift re-clamps
    BOOL settled = (fabs(cam - prevCam) < MAX(1.0, cam * 0.005));
    if(settled){
        // NUDGE the value: MapKit only re-enforces the min against the current
        // camera when the zoom-range VALUE CHANGES — re-setting the identical
        // min is a no-op (sim-proved: 8 identical re-kicks ignored; a 0.2m
        // different value enforced immediately). +attempt+1 meters is
        // negligible vs the km-scale mins but always registers as a change.
        double nudgedMin = minCam + (double)(attempt + 1);
        NSLog(@"follow zoom clamp re-kick %d -> min %.0fm (settled cam %.0fm)", attempt + 1, nudgedMin, cam);
        MKMapCameraZoomRange *zr = [[MKMapCameraZoomRange alloc] initWithMinCenterCoordinateDistance:nudgedMin];
        [self.mapView setCameraZoomRange:zr animated:YES];
    }
    int gen = followArmGeneration;
    __weak cwtMapViewController *weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        cwtMapViewController *strongSelf = weakSelf;
        if(strongSelf != nil && strongSelf->followArmGeneration == gen){
            [strongSelf verifyFollowZoomClampMin:minCam token:token attempt:attempt + 1 prevCam:cam];
        }
    });
}

// Apply (or refresh) the pin-visible zoom clamp for the current destination pin.
// force==NO only re-clamps once the user->pin distance has drifted >15% since the
// last clamp (auto zoom-in as the user approaches, without thrashing the camera).
-(void)updateFollowZoomClampForFix:(CLLocation *)fix force:(BOOL)force{
    if(fix == nil || selectedAnnotation == nil) return;
    CLLocation *pinLoc = [[CLLocation alloc] initWithLatitude:selectedAnnotation.coordinate.latitude
                                                    longitude:selectedAnnotation.coordinate.longitude];
    double d = [fix distanceFromLocation:pinLoc];
    if(!force
       && followClampUserPinDistance > 0.0
       && fabs(d - followClampUserPinDistance) <= FOLLOW_ZOOM_RECALC_FRACTION * followClampUserPinDistance){
        return;
    }
    double minCam = FOLLOW_ZOOM_K * d;
    if(minCam < FOLLOW_ZOOM_MIN_DISTANCE) minCam = FOLLOW_ZOOM_MIN_DISTANCE;
    // Animation choice, sim-traced (device feedback on the old always-animated
    // order was rotate -> forced un-rotate -> rotate):
    // - OPEN path (not yet tracking): animated:NO — clamp lands silently BEFORE
    //   the follow engage, which then animates zoom+center+rotation as ONE
    //   motion. Traced: single "-> 2" transition, no mode-1.
    // - LOWERING the min while tracking (user approaching): animated:NO — the
    //   follow camera glides down to the new min with NO tracking-mode event
    //   (flash-free auto zoom-in, and enforcement is automatic).
    // - RAISING the min while tracking (user moving away): MapKit silently
    //   IGNORES an animated:NO raise (camera stays below min, pin lost), so it
    //   must be animated:YES — enforced, at the cost of one 2->1->2 bounce that
    //   the 0.6s auto-upgrade repairs (~0.6s north-up in this rare case).
    // The synchronous re-assert below is cheap insurance only; in traces the
    // 2->1 drop always arrives asynchronously via the delegate.
    BOOL wasFollowing = (self.mapView.userTrackingMode == MKUserTrackingModeFollowWithHeading);
    BOOL animatedClamp = (wasFollowing && minCam > self.mapView.camera.centerCoordinateDistance);
    MKMapCameraZoomRange *zr = [[MKMapCameraZoomRange alloc] initWithMinCenterCoordinateDistance:minCam];
    [self.mapView setCameraZoomRange:zr animated:animatedClamp];
    NSLog(@"follow zoom clamp -> min %.0fm (user->pin %.0fm)", minCam, d);
    if(wasFollowing && self.mapView.userTrackingMode != MKUserTrackingModeFollowWithHeading){
        [self.mapView setUserTrackingMode:MKUserTrackingModeFollowWithHeading animated:NO];
    }
    followClampUserPinDistance = d;

    // Raises while tracking can be swallowed if they race an in-flight camera
    // glide (sim-traced): schedule the settle-aware enforcement watchdog.
    if(animatedClamp){
        double camNow = self.mapView.camera.centerCoordinateDistance;
        int gen = followArmGeneration;
        __weak cwtMapViewController *weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            cwtMapViewController *strongSelf = weakSelf;
            if(strongSelf != nil && strongSelf->followArmGeneration == gen){
                [strongSelf verifyFollowZoomClampMin:minCam token:d attempt:0 prevCam:camNow];
            }
        });
    }
}

// Remove the clamp and restore MapKit's default (unrestricted) zoom range so
// free pinch/zoom is never restricted once the user has left follow mode.
-(void)clearFollowZoomClamp{
    followClampUserPinDistance = 0.0;
    self.mapView.cameraZoomRange = nil;   // null_resettable: nil restores the default range
}

-(void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation{

    if(locationLoaded==false){

        [self updateMap];
        locationLoaded=true;
    }

    // One-shot: guarantee compass-follow engages on the cold first open once the
    // map has produced a real MKUserLocation. setUserTrackingMode inside updateMap
    // can silently no-op if it ran before the map had a fix, which used to leave
    // the map stuck in the pin-fit fallback with tracking mode None.
    if(wantsFollowOnFirstFix
       && CLLocationCoordinate2DIsValid(userLocation.coordinate)
       && !(userLocation.coordinate.latitude == 0.0 && userLocation.coordinate.longitude == 0.0)){
        wantsFollowOnFirstFix = NO;
        if(self.mapView.userTrackingMode != MKUserTrackingModeFollowWithHeading){
            // Arm the "until it sticks" guard for the non-search open path (the
            // search branch manages its own tracking and must stay undisturbed).
            // ORDER MATTERS: apply the pin-visible zoom clamp BEFORE engaging
            // follow, so the engage animates zoom+center+rotation as ONE motion
            // (clamping after the engage forced a visible un-rotate/re-rotate).
            if(!wasSearchView){
                [self armFollowGuard];
                [self updateFollowZoomClampForFix:userLocation.location force:YES];
            }
            [self.mapView setUserTrackingMode:MKUserTrackingModeFollowWithHeading animated:YES];
        }
        [self.mapView selectAnnotation:selectedAnnotation animated:YES];
    }
    // Otherwise: keep the destination pin visible while following — re-clamp as
    // the user moves (>15% distance drift tightens/loosens the view).
    else if(!wasSearchView
       && self.mapView.userTrackingMode == MKUserTrackingModeFollowWithHeading
       && userLocation.location != nil
       && CLLocationCoordinate2DIsValid(userLocation.coordinate)
       && !(userLocation.coordinate.latitude == 0.0 && userLocation.coordinate.longitude == 0.0)){
        [self updateFollowZoomClampForFix:userLocation.location force:NO];
    }
}

-(void) viewWillAppear:(BOOL)animated{
    //resume the location consumer while the map drawer is visible
    self.mapView.showsUserLocation = YES;
    if(locationLoaded)[self updateMap];

    [super viewWillAppear:NO];


}

// "Armed until it sticks" resolver for the follow-mode engagement. See the
// followEngagePending / followRetryCount / followArmGeneration comments in the
// header. Key trace fact (cold open): MapKit reports mode 2 here IMMEDIATELY on
// request, then delivers the real drop to 0 ~115ms later — so a mode-2 callback
// is only a CANDIDATE success and must survive a delayed confirm before disarm.
// (No viewDidAppear re-assert: on the cold path viewDidAppear fires ~100ms BEFORE
// updateMap ever arms the guard, so it could never help there.)
-(void)mapView:(MKMapView *)aMapView didChangeUserTrackingMode:(MKUserTrackingMode)mode animated:(BOOL)animated{

    NSLog(@"map trackingMode -> %ld (animated=%d)", (long)mode, animated);

    // Sim-measured gotcha: applying/animating the zoom clamp can knock MapKit
    // from FollowWithHeading down to plain Follow (heading lost, still user-
    // centered). Nothing in this app ever selects plain Follow, and a user pan
    // produces None — never Follow — so while the pin-clamp is active it is safe
    // to upgrade back to FollowWithHeading once the clamp animation settles.
    // (Runs regardless of the engage guard: clamp refreshes as the user moves
    // happen long after the guard has disarmed.)
    if(mode == MKUserTrackingModeFollow && followClampUserPinDistance > 0.0){
        int clampGen = followArmGeneration;
        __weak cwtMapViewController *weakSelfClamp = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            cwtMapViewController *strongSelf = weakSelfClamp;
            if(strongSelf != nil
               && strongSelf->followArmGeneration == clampGen
               && strongSelf->followClampUserPinDistance > 0.0
               && strongSelf.mapView.userTrackingMode == MKUserTrackingModeFollow){
                [strongSelf.mapView setUserTrackingMode:MKUserTrackingModeFollowWithHeading animated:YES];
            }
        });
        return;
    }

    if(!followEngagePending){
        // Not guarding — honor whatever the map does. If follow just exited for
        // good (deliberate user pan), restore free pinch/zoom immediately.
        if(mode == MKUserTrackingModeNone) [self clearFollowZoomClamp];
        return;
    }

    __weak cwtMapViewController *weakSelf = self;
    int gen = followArmGeneration;

    if(mode == MKUserTrackingModeFollowWithHeading){
        // Candidate success. Confirm after 0.7s: if the mode is STILL
        // FollowWithHeading, it genuinely stuck — disarm so a later deliberate
        // user pan (mode -> None) is never fought. If it was dropped in the
        // meantime, stay armed; the None-revert path below handles the retry.
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.7 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            cwtMapViewController *strongSelf = weakSelf;
            if(strongSelf != nil
               && strongSelf->followArmGeneration == gen
               && strongSelf->followEngagePending
               && strongSelf.mapView.userTrackingMode == MKUserTrackingModeFollowWithHeading){
                strongSelf->followEngagePending = NO;
                strongSelf->followRetryCount = 0;
            }
        });
        return;
    }

    if(mode == MKUserTrackingModeNone){
        // MapKit dropped the engagement (the drawer-push transition window).
        // Re-engage after 0.3s — proven to stick once the transition is over —
        // bounded so a genuinely-failing engage can't loop forever.
        if(followRetryCount < 3){
            followRetryCount++;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)),
                           dispatch_get_main_queue(), ^{
                cwtMapViewController *strongSelf = weakSelf;
                if(strongSelf != nil
                   && strongSelf->followArmGeneration == gen
                   && strongSelf->followEngagePending){
                    [strongSelf.mapView setUserTrackingMode:MKUserTrackingModeFollowWithHeading animated:YES];
                }
            });
        }else{
            // Give up rather than fight the map indefinitely — and since we're
            // no longer following, don't restrict hand-navigation either.
            followEngagePending = NO;
            [self clearFollowZoomClamp];
        }
    }
}

-(void) updateMap{
    
    MKMapRect zoomRect = MKMapRectNull;
    
    //if(!wasSearchView)
    {
        
        lpgr = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
        lpgr.minimumPressDuration = 1.75f;
        
        [self.mapView addGestureRecognizer:lpgr];
    }
    
    
    
    
    // adjust the map to zoom/center to the annotations we want to show
    cwtAnnotation * currentAnnotation;
    
    
    if(wasSearchView)
    {
        
        if (self.mapItemList.count == 1)
        {
            
            MKMapItem *mapItem = [self.mapItemList objectAtIndex:0];
            
            self.title = mapItem.name;
            
            // add the single annotation to our map
            self.annotation = [[cwtAnnotation alloc] init];
            self.annotation.coordinate = mapItem.placemark.location.coordinate;
            self.annotation.title = [mapItem.name uppercaseString];
            self.annotation.subtitle=@"SAVE LOCATION";
            
            [self.mapView addAnnotation:self.annotation];
            
            currentAnnotation=self.annotation;
            
            
            MKMapPoint annotationPoint ;
            
            //current loc
            annotationPoint = MKMapPointForCoordinate(self.mapView.userLocation.coordinate);
            zoomRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 1, 1);
            
            //current annotation
            annotationPoint = MKMapPointForCoordinate(currentAnnotation.coordinate);
            MKMapRect pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 1, 1);
            zoomRect = MKMapRectUnion(zoomRect, pointRect);
            
        }
        else{
            
            // add all the found annotations to the map
            for (MKMapItem *item in self.mapItemList)
            {
                cwtAnnotation *a = [[cwtAnnotation alloc] init];
                a.coordinate = item.placemark.location.coordinate;
                a.title = [item.name uppercaseString];
                a.subtitle=@"SAVE LOCATION";
                [self.mapView addAnnotation:a];
            }
            
            
            currentAnnotation=[self.mapView.annotations objectAtIndex:0];
            
            MKMapPoint annotationPoint ;
            
            //current loc
            annotationPoint = MKMapPointForCoordinate(self.mapView.userLocation.coordinate);
            zoomRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 1, 1);
            
            //all search result annotation
            for (id <MKAnnotation> annotation in self.mapView.annotations)
            {
                MKMapPoint annotationPoint = MKMapPointForCoordinate(annotation.coordinate);
                MKMapRect pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 1, 1);
                zoomRect = MKMapRectUnion(zoomRect, pointRect);
            }
            
        }
    }
    
    //not search result
    else {
        
        
        //load all pins
        //for (NSMutableDictionary *dictionary in dele.locationDictionaryArray)
        for(int i=0; i<[dele.locationDictionaryArray count]; i++)
        {
            
            NSMutableDictionary *dictionary=[dele.locationDictionaryArray objectAtIndex:i];
            
            int currentDestinationN=(int)[[NSUserDefaults standardUserDefaults] integerForKey:@"currentDestinationN"];
            
            CLLocationCoordinate2D annotationCoord;
            
            annotationCoord.latitude = [[dictionary valueForKey:@"lat"] floatValue];;
            annotationCoord.longitude = [[dictionary valueForKey:@"lng"] floatValue];
            
            self.annotation = [[cwtAnnotation alloc] init];
            self.annotation.coordinate = annotationCoord;
            self.annotation.title = [[dictionary valueForKey:@"searchedText"] uppercaseString];
            //self.annotation.index=[dele.locationDictionaryArray indexOfObject:dictionary];
            self.annotation.index=i;
            
            //if(currentDestinationN == [dele.locationDictionaryArray indexOfObject:dictionary])
            if(currentDestinationN == i)
            {
                self.annotation.subtitle=@"drag pin to edit location";
                currentAnnotation=self.annotation;
            }
            else
            {
                self.annotation.subtitle=@"";
            }
            
            [self.mapView addAnnotation:self.annotation];
            
            
        }
        
        // NEW BEHAVIOR (non-search branch):
        // Open the map centered on the USER and oriented by the compass at
        // MapKit's default FollowWithHeading altitude, no matter how far the
        // destination is (far destinations behave EXACTLY like near ones).
        //
        // Source the fix from the app delegate's always-on location manager, NOT
        // from the map's own showsUserLocation plumbing: the map VC is lazy-created
        // on first open and showsUserLocation only turns on in viewWillAppear, so
        // mapView.userLocation.coordinate is still (0,0) on a cold first open. The
        // compass app has had a live fix long before the map ever opened.
        //
        // We only compute a modest initial region (so there's no pin-fit flash
        // before tracking engages); engaging FollowWithHeading immediately resets
        // the camera to its default follow altitude anyway, so no span math is
        // needed. The pin-fit fallback is kept ONLY for fix==nil (fresh install /
        // permissions pending), where FollowWithHeading engages later via the
        // one-shot in didUpdateUserLocation.

        CLLocation *fix = dele.locationManager.location;
        BOOL haveUserFix = (fix != nil
                            && CLLocationCoordinate2DIsValid(fix.coordinate)
                            && !(fix.coordinate.latitude == 0.0 && fix.coordinate.longitude == 0.0));

        if(haveUserFix){
            // Modest initial region centered on the user (~matches the follow
            // altitude, ~5km) so there is no pin-fit flash before tracking engages.
            MKCoordinateRegion userRegion = MKCoordinateRegionMakeWithDistance(fix.coordinate, 3000, 3000);
            [self.mapView setRegion:userRegion animated:NO];
        }
        else if(currentAnnotation != nil){
            // No usable fix yet: fit the pin (~9000 map points) rather than
            // centering on a bogus (0,0). FollowWithHeading recenters once a real
            // fix arrives (the one-shot in didUpdateUserLocation engages it).
            MKMapPoint pinPoint = MKMapPointForCoordinate(currentAnnotation.coordinate);
            double span = 9000.0;
            zoomRect = MKMapRectMake(pinPoint.x - span * 0.5,
                                     pinPoint.y - span * 0.5,
                                     span, span);
            [self.mapView setVisibleMapRect:zoomRect animated:NO];
        }

        // Remember the destination pin so its callout can be re-selected after the
        // tracking-mode hand-off (see the one-shot in didUpdateUserLocation).
        selectedAnnotation = currentAnnotation;

        // Callout pops for the current destination (nil = harmless no-op).
        [self.mapView selectAnnotation:currentAnnotation animated:YES];

        // ALWAYS orient by compass, at any distance. On a cold open the map may
        // not have an MKUserLocation yet, so arm the one-shot too. Also arm the
        // "until it sticks" guard so a FollowWithHeading engagement that MapKit
        // drops during the drawer-push transition gets re-asserted (this block
        // runs for search too, so gate the guard on the non-search path only).
        wantsFollowOnFirstFix = YES;
        if(!wasSearchView){
            [self armFollowGuard];
            // Pin-visible zoom: clamp BEFORE engaging follow (order matters —
            // engaging resets the camera to its default ~5km altitude, and
            // clamping afterwards forced a visible un-rotate/re-rotate bounce;
            // with the clamp already in place the engage animates
            // zoom+center+rotation as ONE motion). The no-fix fallback gets
            // clamped from didUpdateUserLocation when the first real fix lands.
            if(haveUserFix) [self updateFollowZoomClampForFix:fix force:YES];
            else followClampUserPinDistance = 0.0;
            [self.mapView setUserTrackingMode:MKUserTrackingModeFollowWithHeading animated:YES];
        }else{
            // Search opens keep classic free zoom — make sure no clamp lingers
            // from a previous destination open.
            [self clearFollowZoomClamp];
            [self.mapView setUserTrackingMode:MKUserTrackingModeFollowWithHeading animated:YES];
        }

    }
    
    
    
    
    // Search-results branch keeps its classic behavior: union rect + padding,
    // pin-only "tooBig" fallback for very-far results, and the <9000 heading gate.
    // (The non-search branch already set its own user-centered rect + FollowWithHeading above.)
    if(wasSearchView)
    {

    //add padding to map
    float xDiff=zoomRect.size.width*MAP_PADDING-zoomRect.size.width;
    float yDiff=zoomRect.size.height*MAP_PADDING-zoomRect.size.height;
    
    //shift origin of map
    zoomRect.origin.x-=xDiff*.5;
    zoomRect.origin.y-=yDiff*.5;
    
    //set map width height
    zoomRect.size.width=zoomRect.size.width+xDiff;
    zoomRect.size.height=zoomRect.size.height+yDiff;
    
    
    // NSLog(@"height: %f",zoomRect.size.height);
    //NSLog(@"width: %f",zoomRect.size.width);
    
    int tooBig=90000000;
    if(zoomRect.size.height>tooBig || zoomRect.size.width>tooBig){
        //reset rect to fit only pin
        MKMapPoint annotationPoint;
        annotationPoint = MKMapPointForCoordinate(currentAnnotation.coordinate);
        
        zoomRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 1,1);
        
        //add padding to map
        //        float xDiff=zoomRect.size.width*(tooBig*.5)-zoomRect.size.width;
        //        float yDiff=zoomRect.size.height*(tooBig*.5)-zoomRect.size.height;
        
        float xDiff=zoomRect.size.width*(tooBig*.0001)-zoomRect.size.width;
        float yDiff=zoomRect.size.height*(tooBig*.0001)-zoomRect.size.height;
        
        //shift origin of map
        zoomRect.origin.x-=xDiff*.5;
        zoomRect.origin.y-=yDiff*.5;
        
        //set map width height
        zoomRect.size.width=zoomRect.size.width+xDiff;
        zoomRect.size.height=zoomRect.size.height+yDiff;
        
    }

    
    [self.mapView setVisibleMapRect:zoomRect animated:NO];
    [self.mapView selectAnnotation:currentAnnotation animated:YES];
    if(zoomRect.size.height<9000 || zoomRect.size.width<9000){
//        /[self drawCone];
        [self.mapView setUserTrackingMode:MKUserTrackingModeFollowWithHeading animated:YES];
    }

    } // end if(wasSearchView)


    //[[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"mapInstructions"];
    
    //if no default, set default to true
    if( [[NSUserDefaults standardUserDefaults] objectForKey:@"enable_mapInstructions"]==0 )[[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:@"enable_mapInstructions"];
    
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"enable_mapInstructions"]==TRUE){
        
        int instructionN=(int)[[NSUserDefaults standardUserDefaults] integerForKey:@"mapInstructions"];
        
        //first launch
        if(instructionN==0){
            //instructionN=1;
            [[NSUserDefaults standardUserDefaults] setInteger:instructionN forKey:@"mapInstructions"];
        }
        
        NSLog(@"show map inst %i",instructionN);
        
        if((wasSearchView==TRUE && instructionN==0) || (wasSearchView==FALSE && instructionN==1)){
            [self.instructions setImage:[UIImage imageNamed:[NSString stringWithFormat:@"Crowsflight_mapInstructions_006-%02i",instructionN]]];
            [self.instructions setHidden:FALSE];
            
        }else{
            
            [self.instructions setHidden:TRUE];
            
        }
        
        
    }else{
        
        [self.instructions setHidden:TRUE];
        [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"mapInstructions"];
        
    }
    
    

}

-(void)centerDeviceLocation{
    //CGFloat currentZoom = self.mapView.camera.;
    region=self.mapView.region;

    //turn on user location it wasn't already
//    if(!self.mapView.showsUserLocation){
//        [self.mapView setShowsUserLocation:TRUE];
//    }
    [self.mapView setUserTrackingMode:MKUserTrackingModeFollowWithHeading];
//    
    //we may not have a device location... (ignore simulator values, their bogus!)
    if(self.mapView.userLocation){

                
                //center on location
               // CLLocationCoordinate2D tmpLocation;
               // tmpLocation.latitude = self.mapView.userLocation.coordinate.latitude;
               // tmpLocation.longitude = self.mapView.userLocation.coordinate.longitude;
               // [self.mapView setCenterCoordinate:tmpLocation animated:TRUE];
                
                //select the one and only annotation so the bubble shows
                //[self.mapView selectAnnotation:self.mapView.userLocation animated:TRUE];
                
                //zoom in 
                //[self setCenterCoordinate:tmpLocation zoomLevel:currentZoom animated:YES];

                // Make a region using our current zoom level
                //CLLocationDistance latitude = region.span.latitudeDelta*100.0;
                //CLLocationDistance longitude = region.span.longitudeDelta*100.0;
                //MKCoordinateRegion newRegion = MKCoordinateRegionMakeWithDistance(mapView.userLocation.coordinate, latitude, longitude);
                //[self.mapView setRegion:newRegion animated:YES];
                
                
        
        
    } 
    
}

- (void)setCenterCoordinate:(CLLocationCoordinate2D)coordinate
                  zoomLevel:(NSUInteger)zoom animated:(BOOL)animated
{
    MKCoordinateSpan span = MKCoordinateSpanMake(180 / pow(2, zoom) *
                                                 self.mapView.frame.size.height / 256, 0);
    [self.mapView setRegion:MKCoordinateRegionMake(coordinate, span) animated:animated];
}


- (void)drawCone {
    dele = (cwtAppDelegate*)[[UIApplication sharedApplication] delegate];

    //float bearing=dele.viewController.locationViewController.locBearing;
    //float heading=-DEGREES_TO_RADIANS(dele.heading)+M_PI*.5;
    float spread=DEGREES_TO_RADIANS(dele.viewController.locationViewController.spread);
 
    // create an array of coordinates from allPins
    CLLocationCoordinate2D coordinates[3];
    
//    coordinates[0] =self.mapView.userLocation.coordinate;
//    coordinates[1] =CLLocationCoordinate2DMake(self.mapView.userLocation.coordinate.latitude+30.0f*sin(heading+spread), self.mapView.userLocation.coordinate.longitude+cos(heading+spread)*30.0f);
//    coordinates[2] =CLLocationCoordinate2DMake(self.mapView.userLocation.coordinate.latitude+30.0f*sin(heading-spread), self.mapView.userLocation.coordinate.longitude+cos(heading-spread)*30.0f );
    float heading=180;
    coordinates[0] =self.mapView.userLocation.coordinate;
    coordinates[1] =CLLocationCoordinate2DMake(self.mapView.userLocation.coordinate.latitude+30.0f*sin(heading+spread), self.mapView.userLocation.coordinate.longitude+cos(heading+spread)*30.0f);
    coordinates[2] =CLLocationCoordinate2DMake(self.mapView.userLocation.coordinate.latitude+30.0f*sin(heading-spread), self.mapView.userLocation.coordinate.longitude+cos(heading-spread)*30.0f );
    
    
    
    MKPolygon *oldCone = self.cone;
    MKPolygon* newCone = [MKPolygon polygonWithCoordinates:coordinates count:3];
    
    [self.mapView addOverlay:newCone];
    
    // remove polyline if one exists
    self.cone=newCone;
    if(oldCone)[self.mapView removeOverlay:oldCone];

    
    
    
//    //caanimation
//    
//    int radius = 10;
//    beam = [CAShapeLayer layer];
//    
//    CGPoint myPos = [self.mapView convertCoordinate:self.mapView.userLocation.coordinate toPointToView:self.view];
//
//    beam.path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(myPos.x, myPos.y, 2.0*radius, 2.0*radius)
//                                             cornerRadius:radius].CGPath;
//    
//    
//    beam.fillColor = [UIColor clearColor].CGColor;
//    beam.strokeColor = [UIColor blackColor].CGColor;
//    beam.lineWidth = radius*2;
//    beam.opacity = 0.5;
//    
//    [self.mapView.layer addSublayer:beam];
//    
//    CABasicAnimation *drawAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
//    drawAnimation.duration            = 2.5; // "animate over 10 seconds or so.."
//    drawAnimation.repeatCount         = 1;  // Animate only once..
//    drawAnimation.removedOnCompletion = YES;   // Remain stroked after the animation..
//    
//    drawAnimation.fromValue = [NSNumber numberWithFloat:0.0f];
//    drawAnimation.toValue   = [NSNumber numberWithFloat:1.0f];
//    
//    [beam addAnimation:drawAnimation forKey:@"drawCircleAnimation"];
//    
    
}

-(void)updateCone{

    
    CGPoint lastPostion = [self.mapView convertCoordinate:self.mapView.userLocation.coordinate toPointToView:self.mapView];
    
    
    //beam.position=CGPointMake(myPos.x, myPos.y);
    
    //lastPostion=CGPointMake(lastPostion.x-self.mapView.frame.size.width, lastPostion.y-self.mapView.frame.size.height*.5);
    
    lastPostion=CGPointMake(lastPostion.x, lastPostion.y);

    
    CABasicAnimation *drawAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
    drawAnimation.duration          = .1;
    drawAnimation.fromValue         = [NSValue valueWithCGPoint:startPosition];
    drawAnimation.toValue = [NSValue valueWithCGPoint:lastPostion];
    [beam addAnimation:drawAnimation forKey:@"position"];
    beam.position=lastPostion;
    //beam.position = CGPointMake(CGRectGetMidX(self.view.frame)-10, CGRectGetMidY(self.view.frame)-10);

    startPosition=lastPostion;
    
    
    
    
    dele = (cwtAppDelegate*)[[UIApplication sharedApplication] delegate];
    
    //float bearing=dele.viewController.locationViewController.locBearing;
    float heading=-DEGREES_TO_RADIANS(dele.heading)+M_PI*.5;
    float spread=DEGREES_TO_RADIANS(dele.viewController.locationViewController.spread);
    
    // create an array of coordinates from allPins
    CLLocationCoordinate2D coordinates[3];
    
    coordinates[0] =self.mapView.userLocation.coordinate;
    coordinates[1] =CLLocationCoordinate2DMake(self.mapView.userLocation.coordinate.latitude+30.0f*sin(heading+spread), self.mapView.userLocation.coordinate.longitude+cos(heading+spread)*30.0f);
    coordinates[2] =CLLocationCoordinate2DMake(self.mapView.userLocation.coordinate.latitude+30.0f*sin(heading-spread), self.mapView.userLocation.coordinate.longitude+cos(heading-spread)*30.0f );
    
   // MKPolygon *oldCone = self.cone;
    MKPolygon* newCone = [MKPolygon polygonWithCoordinates:coordinates count:3];
    
    //[self.mapView addOverlay:newCone];
    
    // remove polyline if one exists
    //if(oldCone)[self.mapView removeOverlay:oldCone];
    
    [self.mapView exchangeOverlay:self.cone withOverlay:newCone];
    self.cone=newCone;

    
    
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id < MKOverlay >)overlay
{

    MKPolygonRenderer *renderer = [[MKPolygonRenderer alloc] initWithPolygon:(MKPolygon *)overlay];

    renderer.fillColor   = [[UIColor yellowColor] colorWithAlphaComponent:.4];
    renderer.strokeColor = [UIColor clearColor];
    renderer.lineWidth   = 1.0;
    
    return renderer;
    
    
}


-(void)nextInstruction:(int)n{
    

    if([[NSUserDefaults standardUserDefaults] boolForKey:@"enable_mapInstructions"]==FALSE)return;
    
    int instructionN=(int)[[NSUserDefaults standardUserDefaults] integerForKey:@"mapInstructions"];
    
    if(n-1==instructionN){

        if(instructionN<1){//last instruction
            NSLog(@"next instruction %i",n);

            instructionN++;
            [[NSUserDefaults standardUserDefaults] setInteger:instructionN forKey:@"mapInstructions"];
            [self.instructions setImage:[UIImage imageNamed:[NSString stringWithFormat:@"Crowsflight_mapInstructions_006-%02i",instructionN]]];
            [self.instructions setHidden:FALSE];
        }
        
        else{
            [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"mapInstructions"];
            [[NSUserDefaults standardUserDefaults] setBool:FALSE forKey:@"enable_mapInstructions"];
            [self.instructions setHidden:TRUE];
            
            NSLog(@"no more instructions");
            
        }
    }
}



- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    //stop feeding location to the hidden map so it doesn't keep a consumer alive
    self.mapView.showsUserLocation = NO;
    [self.mapView removeAnnotations:self.mapView.annotations];
    self.annotation = nil;
    // Drop the pin-visible zoom clamp between opens (re-applied on next open).
    [self clearFollowZoomClamp];


}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    mapView=[[MKMapView alloc] init];
    //mapView.frame=[[UIScreen mainScreen] bounds];
    CGRect screen = [[UIScreen mainScreen] bounds];
    mapView.frame=CGRectMake(40, 0, screen.size.width-40, screen.size.height);

    mapView.showsUserLocation = YES;
    mapView.delegate = self;
    mapView.mapType = [[NSUserDefaults standardUserDefaults] integerForKey:@"mapType"];
    [self.view addSubview:mapView];
    
    self.mapButton =[[UIButton alloc] initWithFrame:CGRectMake(self.view.bounds.size.width-60, self.view.bounds.size.height-60, 44, 44)];
    [self.mapButton addTarget:self action:@selector(mapTypeButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:self.mapButton];
    
    dele=(cwtAppDelegate*)[[UIApplication sharedApplication] delegate];
    
    

        
    if(mapView.mapType==MKMapTypeSatellite){
        [self.mapButton setImage:[UIImage imageNamed:@"EarthBLUE.png"] forState:UIControlStateNormal];
        
    }else if (mapView.mapType == MKMapTypeHybrid){
        [self.mapButton setImage:[UIImage imageNamed:@"EarthandLinesBLUE.png"] forState:UIControlStateNormal];
        
    }else{
        mapView.mapType = MKMapTypeStandard;
        [self.mapButton setImage:[UIImage imageNamed:@"LinesBLUE.png"] forState:UIControlStateNormal];
    }
    

    
    //sounds
    NSString * path = [[NSBundle mainBundle] pathForResource:@"Crowsflight_Create_001" ofType:@"wav"];
     NSURL *url = [NSURL fileURLWithPath:path];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)url, &audioCreate);


    //allowLongpress=TRUE;

    self.instructions=[[UIImageView alloc] init];
    [self.instructions setFrame:CGRectMake(22, -screen.size.width*.125, screen.size.width, screen.size.width)];
    [self.instructions setAlpha:.98];

    [self.view addSubview:self.instructions];
    

    
}
// was viewDidUnload (deprecated/never called on modern iOS); dispose sound on dealloc instead
-(void)dealloc{
    AudioServicesDisposeSystemSoundID(audioCreate);
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    
    NSLog(@"span latDelta %f",mapView.region.span.latitudeDelta);

    //if(!wasSearchView)
    {
        //NSLog(@"touch began");
        NSArray *touchesArray = [touches allObjects];
        
        UITouch *touch = (UITouch *)[touchesArray objectAtIndex:0];
        CGPoint point = [touch locationInView:self.mapView];
    
        // if there was a previous circle, get rid of it
        [self.circleLayer removeFromSuperlayer];
        
        // create new CAShapeLayer
        CAShapeLayer *shapeLayer = [CAShapeLayer layer];
        shapeLayer.path = [[self makeCircleAtLocation:point radius:80.0] CGPath];
        shapeLayer.fillColor = [[UIColor clearColor] CGColor];
        shapeLayer.strokeColor = [[UIColor colorWithRed:1.0f green:78.0/255.0f blue:36.0/255.0f alpha:1] CGColor];
        shapeLayer.opacity=.8f;
        shapeLayer.lineWidth = 28.0f;
        shapeLayer.strokeEnd=0.0f;
        
        // Save this shape layer in a class property for future reference,
        [self.mapView.layer addSublayer:shapeLayer];
        self.circleLayer = shapeLayer;
        
        
        //[self.audioLongpress playAtTime:self.audioLongpress.deviceCurrentTime+.5f];

        //animate arc
        CABasicAnimation *drawAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
        [drawAnimation setBeginTime:CACurrentMediaTime()+.5f];
        drawAnimation.duration            =2.5f;
        drawAnimation.repeatCount         = 1.0;  // Animate only once..
        drawAnimation.removedOnCompletion = NO;   // Remain stroked after the animation..
        drawAnimation.fillMode=kCAFillModeForwards;
    
        drawAnimation.fromValue = [NSNumber numberWithFloat:.0f];
        drawAnimation.toValue   = [NSNumber numberWithFloat:1.0f];
        drawAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
        [self.circleLayer addAnimation:drawAnimation forKey:@"drawCircleAnimation"];
        
    }
}



-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.circleLayer.opacity=0;

    [self.circleLayer removeFromSuperlayer];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.circleLayer.opacity=0;
    [self.circleLayer removeFromSuperlayer];

}

- (void)handleLongPress:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state != UIGestureRecognizerStateBegan) return;
    

    CGPoint touchPoint = [gestureRecognizer locationInView:self.mapView];
    CLLocationCoordinate2D touchMapCoordinate = [self.mapView convertPoint:touchPoint toCoordinateFromView:self.mapView];
    
    
    
    __block NSString *locTitle=[[NSString alloc] init];
    locTitle=@"";
    


    BOOL willshowUnlockAlert=FALSE;
    
	if([[NSUserDefaults standardUserDefaults] boolForKey:@"unlockcrowsflight"]==NO && [dele.locationDictionaryArray count]>=5){
        willshowUnlockAlert=TRUE;
    }
    
    
    if(dele.hasInternet==TRUE && willshowUnlockAlert==FALSE)
    {

        
        NSLog(@"hasInternet geolocating");
        
        [self dismissViewControllerAnimated:YES completion:nil];
        [self.navigationController popDrawerViewController:YES];
        
        //show progress
        SIAlertView * progressAlert = [ [SIAlertView alloc] initWithTitle: @"LOCATING..." andMessage:[NSString stringWithFormat:@"%f,%f\n\n\n\n",touchMapCoordinate.latitude,touchMapCoordinate.longitude]];
        
        progressAlert.showSpinner=TRUE;
        progressAlert.showTextField=FALSE;
        
        [progressAlert show];
        
        
        //reverse geocode
        CLGeocoder *geo=[[CLGeocoder alloc] init];
        CLLocation *loc=[[CLLocation alloc] initWithLatitude:touchMapCoordinate.latitude longitude:touchMapCoordinate.longitude];
    
        
        [geo reverseGeocodeLocation:loc completionHandler:^(NSArray *placemarks, NSError *error) {
            
            [progressAlert dismissAnimated:YES];

            if([placemarks count]>0){
                CLPlacemark  *placemark=[[CLPlacemark alloc] initWithPlacemark:[placemarks objectAtIndex:0]];
                
                //check zoom level to set name
                //NSLog(@"%f",mapView.region.span.latitudeDelta);
                
                if(self.mapView.region.span.latitudeDelta>1) locTitle=placemark.locality;
                else if(self.mapView.region.span.latitudeDelta>.05)locTitle=placemark.subLocality;
                else locTitle=placemark.name;

                locTitle=[locTitle uppercaseString];
            }
            

//            if(locTitle==NULL || [locTitle isEqual:@""]){
//                W3wPosition *position = [dele.viewController.w3wSDK convertPositionToW3W:kW3wLanguageEnglish lat:touchMapCoordinate.latitude lng:touchMapCoordinate.longitude];
//
//                locTitle=[NSString stringWithFormat:@"%@\n%f,%f",position.getW3w,touchMapCoordinate.latitude,touchMapCoordinate.longitude];
//            }

            //fall back to a default title if geocoding failed or returned nothing
            if(locTitle==NULL || [[locTitle stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length]==0){
                locTitle=@"Untitled";
            }

            NSLog(@"loc Title: %@",locTitle);
            

            [self->dele.viewController addLocation:touchMapCoordinate title:locTitle];
            AudioServicesPlaySystemSound(self->audioCreate);

        }];

      
    }
    
    else
    {
        
        NSLog(@"no internet?");
//        W3wPosition *position = [dele.viewController.w3wSDK convertPositionToW3W:kW3wLanguageEnglish lat:touchMapCoordinate.latitude lng:touchMapCoordinate.longitude];
//
//        locTitle=[NSString stringWithFormat:@"%@\n%f,%f",position.getW3w,touchMapCoordinate.latitude,touchMapCoordinate.longitude];
        locTitle=@"Untitled";
        [dele.viewController addLocation:touchMapCoordinate title:locTitle];
        AudioServicesPlaySystemSound(audioCreate);
        [self dismissViewControllerAnimated:YES completion:nil];
        [self.navigationController popDrawerViewController:YES];
    }
     

    [self nextInstruction:2];


    
    
    
    
    
    
}

- (UIBezierPath *)makeCircleAtLocation:(CGPoint)location radius:(CGFloat)radius
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path addArcWithCenter:location
                    radius:radius
                startAngle:M_PI * -.5
                  endAngle:M_PI * 2.5
                 clockwise:YES];
    
    return path;
}



-(void)setButtons{
    
    if([[NSUserDefaults standardUserDefaults] integerForKey:@"mapType"]==0){
        self.overlayButton.alpha=1;
        self.mapButton.alpha=.3;
    }
    else if([[NSUserDefaults standardUserDefaults] integerForKey:@"mapType"]==1){
        self.overlayButton.alpha=.3;
        self.mapButton.alpha=1;
    }
    else if([[NSUserDefaults standardUserDefaults] integerForKey:@"mapType"]==2){
        self.overlayButton.alpha=1;
        self.mapButton.alpha=1;
    }
}

-(void)mapPressed{
    
    if(mapView.mapType==MKMapTypeStandard){
        mapView.mapType = MKMapTypeHybrid;
        [[NSUserDefaults standardUserDefaults] setInteger:2 forKey:@"mapType"];
    }
    else if (mapView.mapType == MKMapTypeSatellite){
        mapView.mapType = MKMapTypeStandard;
        [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"mapType"];
    }
    else
    {
        mapView.mapType = MKMapTypeStandard;
        [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"mapType"];
    }
    [self setButtons];
}


-(void)viewWillDisappear:(BOOL)animated{    
    //set page location
    dele.viewController.locationViewController.page=[[NSUserDefaults standardUserDefaults] integerForKey:@"currentDestinationN"];

}



- (MKAnnotationView *) mapView: (MKMapView *) theMapView viewForAnnotation: (id) annotation
{
    MKPinAnnotationView *pin = [[MKPinAnnotationView alloc] initWithAnnotation: annotation reuseIdentifier:nil];
    
    //no annotation for user location. show blue dot
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        
        //pin.canShowCallout=NO;
        
        return nil;
        //pin.draggable = NO;
    }
    else if([[annotation subtitle] isEqualToString:@""])
    {
        pin.draggable = FALSE;
        pin.canShowCallout=TRUE;
        pin.animatesDrop=NO;
        pin.pinTintColor=[UIColor greenColor];
        UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        [rightButton setTitle:@"" forState:UIControlStateNormal];
        pin.rightCalloutAccessoryView = rightButton;
        
        
    }
    else if([[annotation subtitle] isEqualToString:@"SAVE LOCATION"])
    {
        pin.draggable = false;
        pin.canShowCallout=true;
        pin.animatesDrop=NO;
        pin.pinTintColor=[UIColor purpleColor];
        
        UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        [rightButton setTitle:@"" forState:UIControlStateNormal];
        pin.rightCalloutAccessoryView = rightButton;
    }
    else {
        pin.draggable = true;
        pin.canShowCallout=true;
        pin.animatesDrop=NO;
        pin.pinTintColor=[UIColor redColor];
    }
    
    
    return pin;
    
    
    
}

-(void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view{
    [self.circleLayer removeFromSuperlayer];
    //lpgr.enabled = NO;
    //allowLongpress=FALSE;
}

-(void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view{
    //lpgr.enabled = YES;
    //allowLongpress=TRUE;
}



- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {

    cwtAnnotation *annotation = (cwtAnnotation *)view.annotation;
    
    
    if([annotation.subtitle isEqual:@""] ){
        //AudioServicesPlaySystemSound(audioSelect3);

        NSLog(@"clicked annotation: %i",(int)annotation.index);
        [[NSUserDefaults standardUserDefaults] setInteger:annotation.index forKey:@"currentDestinationN"];

    }
    
    
    else if([annotation.subtitle isEqual:@"SAVE LOCATION"]){
        AudioServicesPlaySystemSound(audioCreate);
        [self nextInstruction:1];

        NSLog(@"saved annotation: %i",(int)annotation.index);
        [dele addNewDestination:annotation.title newlat:annotation.coordinate.latitude newlng:annotation.coordinate.longitude];
        
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.navigationController popDrawerViewController:YES];
    
}




- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)annotationView didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState
{

    
    if (newState == MKAnnotationViewDragStateEnding)
    {
        
        CLLocationCoordinate2D droppedAt = annotationView.annotation.coordinate;
        //NSLog(@"Pin dropped at %f,%f", droppedAt.latitude, droppedAt.longitude);
        

        
        MKPointAnnotation *pin = (MKPointAnnotation *)annotationView.annotation;
        
        pin.subtitle=[NSString stringWithFormat:@"SAVED: %f,%f",droppedAt.latitude,droppedAt.longitude];
        
        [dele editDestination:annotationView.annotation.title newlat:droppedAt.latitude newlng:droppedAt.longitude];

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, .4 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            //AudioServicesPlaySystemSound(audioDrop);
        });
        
    }
    
    else if (newState == MKAnnotationViewDragStateStarting)
    {
        //AudioServicesPlaySystemSound(audioDrag);
        NSLog(@"Beginning drag");
        [self.circleLayer removeFromSuperlayer];
        
    }
    
}




-(void)mapTypeButtonClicked {
    
    if(mapView.mapType==MKMapTypeStandard){
        mapView.mapType = MKMapTypeSatellite;
        [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"mapType"];
        [self.mapButton setImage:[UIImage imageNamed:@"EarthBLUE.png"] forState:UIControlStateNormal];
        
    }else if (mapView.mapType == MKMapTypeSatellite){
        mapView.mapType = MKMapTypeHybrid;
        [[NSUserDefaults standardUserDefaults] setInteger:2 forKey:@"mapType"];
        [self.mapButton setImage:[UIImage imageNamed:@"EarthandLinesBLUE.png"] forState:UIControlStateNormal];
        
    }else{
        mapView.mapType = MKMapTypeStandard;
        [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"mapType"];
        [self.mapButton setImage:[UIImage imageNamed:@"LinesBLUE.png"] forState:UIControlStateNormal];
        
    }
    
    
}



@end

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

#define DEGREES_TO_RADIANS(angle) (angle / 180.0 * M_PI)
#define RADIANS_TO_DEGREES(radians) ((radians) * (180.0 / M_PI))

#define MAP_PADDING 1.5


@implementation cwtMapViewController

@synthesize mapView;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    
    return self;
}


-(void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:NO];
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
                annotationPoint = MKMapPointForCoordinate(mapView.userLocation.coordinate);
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
                    self.annotation = [[cwtAnnotation alloc] init];
                    self.annotation.coordinate = item.placemark.location.coordinate;
                    self.annotation.title = [item.name uppercaseString];
                    self.annotation.subtitle=@"SAVE LOCATION";
                    [self.mapView addAnnotation:self.annotation];
                }
                currentAnnotation=[self.mapView.annotations objectAtIndex:0];
                
                MKMapPoint annotationPoint ;
                
                //current loc
                annotationPoint = MKMapPointForCoordinate(mapView.userLocation.coordinate);
                zoomRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 1, 1);
                
                //all search result annotation
                for (id <MKAnnotation> annotation in mapView.annotations)
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
                
               
                MKMapPoint annotationPoint;

                //current loc
                annotationPoint = MKMapPointForCoordinate(mapView.userLocation.coordinate);
                zoomRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 1, 1);
                
                //current annotation
                annotationPoint = MKMapPointForCoordinate(currentAnnotation.coordinate);
                MKMapRect pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 1, 1);
                zoomRect = MKMapRectUnion(zoomRect, pointRect);
                
            }

            
        }
    
    

    
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
        float xDiff=zoomRect.size.width*(tooBig*.5)-zoomRect.size.width;
        float yDiff=zoomRect.size.height*(tooBig*.5)-zoomRect.size.height;
        
        //shift origin of map
        zoomRect.origin.x-=xDiff*.5;
        zoomRect.origin.y-=yDiff*.5;
        
        //set map width height
        zoomRect.size.width=zoomRect.size.width+xDiff;
        zoomRect.size.height=zoomRect.size.height+yDiff;
        
    }


    
    [mapView setVisibleMapRect:zoomRect animated:NO];
    
    [self.mapView selectAnnotation:currentAnnotation animated:YES];
    
    
    //[self.mapView setUserTrackingMode:MKUserTrackingModeFollowWithHeading animated:YES];

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
    [self.mapView removeAnnotations:self.mapView.annotations];
    self.annotation = nil;
    

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
    
    self.mapButton =[[UIButton alloc] initWithFrame:CGRectMake(self.view.bounds.size.width-70, self.view.bounds.size.height*.07, 44, 44)];
    [self.mapButton addTarget:self action:@selector(mapTypeButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:self.mapButton];
    
    dele=[[UIApplication sharedApplication] delegate];
    
    

        
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
-(void)viewDidUnload{
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
                
                if(mapView.region.span.latitudeDelta>1) locTitle=placemark.locality;
                else if(mapView.region.span.latitudeDelta>.05)locTitle=placemark.subLocality;
                else locTitle=placemark.name;

                locTitle=[locTitle uppercaseString];
            }
            else{
                locTitle=@"";
            }
            
            NSLog(@"%@",locTitle);
            

            [dele.viewController addLocation:touchMapCoordinate title:locTitle];
            AudioServicesPlaySystemSound(audioCreate);

        }];
    
        
      
    }
    
    else
    {
        
        NSLog(@"no internet?");

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
        pin.pinColor=MKPinAnnotationColorGreen;
        UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        [rightButton setTitle:@"" forState:UIControlStateNormal];
        pin.rightCalloutAccessoryView = rightButton;
        
        
    }
    else if([[annotation subtitle] isEqualToString:@"SAVE LOCATION"])
    {
        pin.draggable = false;
        pin.canShowCallout=true;
        pin.animatesDrop=NO;
        pin.pinColor=MKPinAnnotationColorPurple;
        
        UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        [rightButton setTitle:@"" forState:UIControlStateNormal];
        pin.rightCalloutAccessoryView = rightButton;
    }
    else {
        pin.draggable = true;
        pin.canShowCallout=true;
        pin.animatesDrop=NO;
        pin.pinColor=MKPinAnnotationColorRed;
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
        

        
        MKPointAnnotation *pin = annotationView.annotation;
        
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
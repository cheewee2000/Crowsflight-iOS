//
//  cwtUIMapViewController.m
//  Crowsflight
//
//  Created by Che-Wei Wang on 5/24/13.
//  Copyright (c) 2013 CW&T. All rights reserved.
//

#import "cwtMapViewController.h"
#import "cwtViewController3.h"
#import "cwtAnnotation.h"

#define DEGREES_TO_RADIANS(angle) (angle / 180.0 * M_PI)
#define RADIANS_TO_DEGREES(radians) ((radians) * (180.0 / M_PI))


@implementation cwtMapViewController
@synthesize mapView;



- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    mapView.showsUserLocation = YES;
    mapView.delegate = self;

    mapView.mapType = [[NSUserDefaults standardUserDefaults] integerForKey:@"mapType"];
    
    self.mapButton =[[UIButton alloc] initWithFrame:CGRectMake(self.view.bounds.size.width-70, 20, 44, 44)];
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
    
    
    
    lpgr = [[UILongPressGestureRecognizer alloc]
                                          initWithTarget:self action:@selector(handleLongPress:)];
    lpgr.minimumPressDuration = 1.0;

    [self.mapView addGestureRecognizer:lpgr];
    
    
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    
    //if(allowLongpress)
    {
    //NSLog(@"touch began");
    NSArray *touchesArray = [touches allObjects];
    
    UITouch *touch = (UITouch *)[touchesArray objectAtIndex:0];
    CGPoint point = [touch locationInView:nil];

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

    
    //animate arc
    CABasicAnimation *drawAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    [drawAnimation setBeginTime:CACurrentMediaTime()+.5];
    drawAnimation.duration            = 2.0;
    drawAnimation.repeatCount         = 1.0;  // Animate only once..
    drawAnimation.removedOnCompletion = NO;   // Remain stroked after the animation..
    drawAnimation.fromValue = [NSNumber numberWithFloat:.0f];
    drawAnimation.toValue   = [NSNumber numberWithFloat:1.0f];
    drawAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    [self.circleLayer addAnimation:drawAnimation forKey:@"drawCircleAnimation"];
    }
    
}



-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.circleLayer removeFromSuperlayer]; 
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.circleLayer removeFromSuperlayer];
}

- (void)handleLongPress:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state != UIGestureRecognizerStateBegan) return;
    
    CGPoint touchPoint = [gestureRecognizer locationInView:self.mapView];
    CLLocationCoordinate2D touchMapCoordinate = [self.mapView convertPoint:touchPoint toCoordinateFromView:self.mapView];
    
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.navigationController popDrawerViewController:YES];
        
    [dele.viewController addLocation:touchMapCoordinate];

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

-(void)overlayPressed{
    
    if(mapView.mapType==MKMapTypeStandard){
        mapView.mapType = MKMapTypeSatellite;
        [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"mapType"];
        
    }
    else if (mapView.mapType == MKMapTypeSatellite){
        mapView.mapType = MKMapTypeHybrid;
        [[NSUserDefaults standardUserDefaults] setInteger:2 forKey:@"mapType"];
    }
    else
    {
        mapView.mapType = MKMapTypeSatellite;
        [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"mapType"];
    }
    
    
    [self setButtons];

}


-(void)viewWillDisappear:(BOOL)animated{
    
    //save location
    
   if(wasSearchView) [dele addNewDestination:name newlat:lat newlng:lng];
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
        //pin.image = [ UIImage imageNamed:@"light_pin.png" ];
        //pin.centerOffset=CGPointMake(-32.0/2.0, 0);

        UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        [rightButton setTitle:@"" forState:UIControlStateNormal];
        //[rightButton addTarget:self action:@selector(loadLocation:) forControlEvents:UIControlEventTouchUpInside];
        pin.rightCalloutAccessoryView = rightButton;


    }else{
        pin.draggable = true;
        pin.canShowCallout=true;
        pin.animatesDrop=NO;
        pin.pinColor=MKPinAnnotationColorRed;
        //pin.image = [ UIImage imageNamed:@"cyan_pin.png" ];
        //pin.centerOffset=CGPointMake(-32.0/2.0, 0);
        //[self setCalloutOffset:CGPointMake(-2, 3)];
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
    
    NSLog(@"clicked annotation: %i",annotation.index);
    [[NSUserDefaults standardUserDefaults] setInteger:annotation.index forKey:@"currentDestinationN"];
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.navigationController popDrawerViewController:YES];    
}

-(void)loadLocation:(NSInteger)index{
    //int currentDestinationN=[[NSUserDefaults standardUserDefaults] integerForKey:@"currentDestinationN"];
    

    
}


- (void)mapView:(MKMapView *)theMapView didAddAnnotationViews:(NSArray *)views
{
    
    //[mapView selectAnnotation:[[mapView annotations] objectAtIndex:0] animated:YES];
}



- (void) zoomMapAndCenterAtLatitude:(double)latitude andLongitude:(double)longitude andName:(NSString*)title
{
    
    lat = latitude;
    lng = longitude;
    
    CLLocationCoordinate2D annotationCoord;
    
    annotationCoord.latitude = lat;
    annotationCoord.longitude = lng;
    
    MKPointAnnotation *annotationPoint = [[MKPointAnnotation alloc] init];
    annotationPoint.coordinate = annotationCoord;

    name = title;
    annotationPoint.title = name;
    annotationPoint.subtitle=@"drag to edit position";
    [mapView addAnnotation:annotationPoint];
    

    //set zoom level and centerpoint

    CLLocationCoordinate2D SouthWest = CLLocationCoordinate2DMake(dele.myLat, dele.myLng);
    CLLocationCoordinate2D NorthEast = annotationPoint.coordinate;
    
    NorthEast.latitude = MAX(NorthEast.latitude, lat);
    NorthEast.longitude = MAX(NorthEast.longitude, lng);
    
    SouthWest.latitude = MIN(SouthWest.latitude, dele.myLat);
    SouthWest.longitude = MIN(SouthWest.longitude, dele.myLng);

    MKCoordinateRegion region;

    region.span.latitudeDelta = fabs(NorthEast.latitude - SouthWest.latitude) * 1.5;
    region.span.longitudeDelta = fabs(SouthWest.longitude - NorthEast.longitude) * 1.5;
    
    //check if too zoomed in
    if(region.span.latitudeDelta<=.001)region.span.latitudeDelta=.001;
    if(region.span.longitudeDelta<=.001)region.span.longitudeDelta=.001;
    
    region.center.latitude = NorthEast.latitude - (NorthEast.latitude - SouthWest.latitude) * 0.5;
    region.center.longitude = NorthEast.longitude + (SouthWest.longitude - NorthEast.longitude) * 0.5;
    
    
    [mapView setRegion:region animated:YES];
    
    //[mapView selectAnnotation:[[mapView annotations] objectAtIndex:0] animated:YES];
    [mapView selectAnnotation:annotationPoint animated:YES];
    
    
}



- (void) zoomLoadPoints
{
    
    //load all pins
    for (NSMutableDictionary *dictionary in dele.locationDictionaryArray) {
        
        //except current pin
        int currentDestinationN=[[NSUserDefaults standardUserDefaults] integerForKey:@"currentDestinationN"];
        
        if(currentDestinationN != [dele.locationDictionaryArray indexOfObject:dictionary]){
            CLLocationCoordinate2D annotationCoord;
            
            annotationCoord.latitude = [[dictionary valueForKey:@"lat"] floatValue];;
            annotationCoord.longitude = [[dictionary valueForKey:@"lng"] floatValue];
            
            cwtAnnotation *annotationPoint = [[cwtAnnotation alloc] init];
            annotationPoint.coordinate = annotationCoord;
            
            annotationPoint.title = [[dictionary valueForKey:@"searchedText"] uppercaseString];
            annotationPoint.subtitle=@"";
            
            annotationPoint.index=[dele.locationDictionaryArray indexOfObject:dictionary];
            
            
            [mapView addAnnotation:annotationPoint];
        }
    
    }
    
    
    //load destination name
    int currentDestinationN=[[NSUserDefaults standardUserDefaults] integerForKey:@"currentDestinationN"];
    
    //load dictionary
    NSMutableDictionary * dictionary = [dele.locationDictionaryArray objectAtIndex:currentDestinationN];
    
    lat=[[dictionary valueForKey:@"lat"] floatValue];
    lng=[[dictionary valueForKey:@"lng"] floatValue];
    
    if(lat==0 & lng==0){
        //ITP
        lat=40.691391;
        lng=-73.951385;
    }
    
    
    name= [dictionary valueForKey:@"searchedText"];
    
    
    CLLocationCoordinate2D annotationCoord;
    
    annotationCoord.latitude = lat;
    annotationCoord.longitude = lng;
    

    
    MKPointAnnotation *annotationPoint = [[MKPointAnnotation alloc] init];
    annotationPoint.coordinate = annotationCoord;
    
    annotationPoint.title = [[dictionary valueForKey:@"searchedText"] uppercaseString];
    annotationPoint.subtitle=@"drag to edit position";

    [mapView addAnnotation:annotationPoint];
    
    
    //set zoom level and centerpoint
    
    CLLocationCoordinate2D SouthWest = CLLocationCoordinate2DMake(dele.myLat, dele.myLng);
    CLLocationCoordinate2D NorthEast = annotationPoint.coordinate;
    
    NorthEast.latitude = MAX(NorthEast.latitude, lat);
    NorthEast.longitude = MAX(NorthEast.longitude, lng);
    
    SouthWest.latitude = MIN(SouthWest.latitude, dele.myLat);
    SouthWest.longitude = MIN(SouthWest.longitude, dele.myLng);
    
    MKCoordinateRegion region;
    
    region.span.latitudeDelta = fabs(NorthEast.latitude - SouthWest.latitude) * 1.5;
    region.span.longitudeDelta = fabs(SouthWest.longitude - NorthEast.longitude) * 1.5;
    
    //check if too zoomed in
    if(region.span.latitudeDelta<=.001)region.span.latitudeDelta=.001;
    if(region.span.longitudeDelta<=.001)region.span.longitudeDelta=.001;
    
    
    region.center.latitude = NorthEast.latitude - (NorthEast.latitude - SouthWest.latitude) * 0.5;
    region.center.longitude = NorthEast.longitude + (SouthWest.longitude - NorthEast.longitude) * 0.5;
    
    // check for sane center values
    if(region.center.latitude > 90.0f)    region.center.latitude=90.0f;
    if(region.center.latitude < -90.0f)   region.center.latitude = -90.0f;
    if(region.center.longitude > 360.0f)  region.center.longitude = 360.0f;
    if(region.center.longitude > 360.0f)  region.center.longitude = 360.0f ;
    if(region.center.longitude < -180.0f) region.center.longitude = -180.0f;

    
    
    [mapView setRegion:region animated:NO];
    [mapView selectAnnotation:annotationPoint animated:YES];
    
    
}



- (void) zoomLoadSearchResults:(NSArray*)placemarks
{
    

        
        //create view
        cwtMapViewController * mapViewController = [[cwtMapViewController alloc] init];
        CGRect frame = mapViewController.view.frame;
        frame.origin = CGPointMake(0, 0);
        
        mapViewController.view.frame = frame;
        
        NSString* lastSearch=[[NSUserDefaults standardUserDefaults] stringForKey:@"lastSearchText"];
        
        mapViewController->wasSearchView=true;
        [mapViewController zoomMapAndCenterAtLatitude:lat andLongitude:lng andName:lastSearch];
        
        [self.navigationController pushDrawerViewController:mapViewController  withStyle:DrawerLayoutStyleRightAnchored animated:YES];
        

        NSMutableArray* annotations=[[NSMutableArray alloc] initWithObjects: nil];
        
        
    //load all pins
    for (CLPlacemark *placemark in placemarks) {
        
        //except current pin

            CLLocationCoordinate2D annotationCoord;
            
            annotationCoord.latitude = placemark.region.center.latitude;
            annotationCoord.longitude = placemark.region.center.longitude;
            
            cwtAnnotation *annotationPoint = [[cwtAnnotation alloc] init];
            annotationPoint.coordinate = annotationCoord;
            
            annotationPoint.title = [placemark.name  uppercaseString];
            annotationPoint.subtitle=@"";
            
            //annotationPoint.index=[dele.locationDictionaryArray indexOfObject:dictionary];
            [annotations addObject:annotationPoint];
        
         
            [mapView addAnnotation:annotationPoint];
        
        NSLog(@"%@",placemark.name) ;
        }
        
        //int currentDestinationN=[[NSUserDefaults standardUserDefaults] integerForKey:@"currentDestinationN"];

        [self zoomToAnnotationsBounds:annotations];

    
    
    //load destination name
        
    //set zoom level and centerpoint
    
    

    //[mapView setRegion:region animated:YES];
    //[mapView selectAnnotation:annotationPoint animated:YES];
    
    
}



- (void) zoomToAnnotationsBounds:(NSMutableArray *)annotations {
    
    CLLocationDegrees minLatitude = DBL_MAX;
    CLLocationDegrees maxLatitude = -DBL_MAX;
    CLLocationDegrees minLongitude = DBL_MAX;
    CLLocationDegrees maxLongitude = -DBL_MAX;
    
    for (cwtAnnotation *annotation in annotations) {
        double annotationLat = annotation.coordinate.latitude;
        double annotationLong = annotation.coordinate.longitude;
        minLatitude = fmin(annotationLat, minLatitude);
        maxLatitude = fmax(annotationLat, maxLatitude);
        minLongitude = fmin(annotationLong, minLongitude);
        maxLongitude = fmax(annotationLong, maxLongitude);
    }
    
    // See function below
    [self setMapRegionForMinLat:minLatitude minLong:minLongitude maxLat:maxLatitude maxLong:maxLongitude];
    
    // If your markers were 40 in height and 20 in width, this would zoom the map to fit them perfectly. Note that there is a bug in mkmapview's set region which means it will snap the map to the nearest whole zoom level, so you will rarely get a perfect fit. But this will ensure a minimum padding.
    UIEdgeInsets mapPadding = UIEdgeInsetsMake(40.0, 10.0, 0.0, 10.0);
    CLLocationCoordinate2D relativeFromCoord = [self.mapView convertPoint:CGPointMake(0, 0) toCoordinateFromView:self.mapView];
    
    // Calculate the additional lat/long required at the current zoom level to add the padding
    CLLocationCoordinate2D topCoord = [self.mapView convertPoint:CGPointMake(0, mapPadding.top) toCoordinateFromView:self.mapView];
    CLLocationCoordinate2D rightCoord = [self.mapView convertPoint:CGPointMake(0, mapPadding.right) toCoordinateFromView:self.mapView];
    CLLocationCoordinate2D bottomCoord = [self.mapView convertPoint:CGPointMake(0, mapPadding.bottom) toCoordinateFromView:self.mapView];
    CLLocationCoordinate2D leftCoord = [self.mapView convertPoint:CGPointMake(0, mapPadding.left) toCoordinateFromView:self.mapView];
    
    double latitudeSpanToBeAddedToTop = relativeFromCoord.latitude - topCoord.latitude;
    double longitudeSpanToBeAddedToRight = relativeFromCoord.latitude - rightCoord.latitude;
    double latitudeSpanToBeAddedToBottom = relativeFromCoord.latitude - bottomCoord.latitude;
    double longitudeSpanToBeAddedToLeft = relativeFromCoord.latitude - leftCoord.latitude;
    
    maxLatitude = maxLatitude + latitudeSpanToBeAddedToTop;
    minLatitude = minLatitude - latitudeSpanToBeAddedToBottom;
    
    maxLongitude = maxLongitude + longitudeSpanToBeAddedToRight;
    minLongitude = minLongitude - longitudeSpanToBeAddedToLeft;
    
    [self setMapRegionForMinLat:minLatitude minLong:minLongitude maxLat:maxLatitude maxLong:maxLongitude];
}

-(void) setMapRegionForMinLat:(double)minLatitude minLong:(double)minLongitude maxLat:(double)maxLatitude maxLong:(double)maxLongitude {
    
    MKCoordinateRegion region;
    region.center.latitude = (minLatitude + maxLatitude) / 2;
    region.center.longitude = (minLongitude + maxLongitude) / 2;
    region.span.latitudeDelta = (maxLatitude - minLatitude);
    region.span.longitudeDelta = (maxLongitude - minLongitude);
    
    // MKMapView BUG: this snaps to the nearest whole zoom level, which is wrong- it doesn't respect the exact region you asked for. See http://stackoverflow.com/questions/1383296/why-mkmapview-region-is-different-than-requested
    [self.mapView setRegion:region animated:YES];
}



- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)annotationView didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState
{
    if (newState == MKAnnotationViewDragStateEnding)
    {
        CLLocationCoordinate2D droppedAt = annotationView.annotation.coordinate;
        //NSLog(@"Pin dropped at %f,%f", droppedAt.latitude, droppedAt.longitude);
        
        lat=droppedAt.latitude;
        lng=droppedAt.longitude;
        
        MKPointAnnotation *pin = annotationView.annotation;
        
        pin.subtitle=[NSString stringWithFormat:@"SAVED: %f,%f",lat,lng];
        
        [dele editDestination:name newlat:lat newlng:lng];
    }
    
    
    if (newState == MKAnnotationViewDragStateStarting)
    {
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
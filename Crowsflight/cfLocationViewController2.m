//
//  cfLocationViewController.m
//  Crowsflight
//
//  Created by Che-Wei Wang on 5/4/13.
//  Copyright (c) 2013 CW&T. All rights reserved.
//

#import "cfLocationViewController2.h"
#import "cwtAppDelegate.h"
#import "cwtViewController3.h"
#define EARTH_RAD_M 3956.0
#define EARTH_RAD_KM 6367.0
#define DEGREES_TO_RADIANS(angle) (angle / 180.0 * M_PI)
#define RADIANS_TO_DEGREES(radians) ((radians) * (180.0 / M_PI))
#define DISTANCE_TEXT_TAG 1

@interface cfLocationViewController2 ()

@end

@implementation cfLocationViewController2

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.progress=1;
    
    dele = [[UIApplication sharedApplication] delegate];
    CGRect screen = [[UIScreen mainScreen] bounds];
    
    //    self.arrowImage=[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"arrow-line.png"]];
    //    self.arrowImage.center=CGPointMake(screen.size.width*.5, screen.size.height*.5);
    //    [self.view addSubview:self.arrowImage];
    
    
    //main arrow
    self.arrow=[[cwtArrow alloc] initWithFrame:CGRectMake(0,0, screen.size.height*1.5,screen.size.height*1.5)];
    //[self.arrow setCenter:CGPointMake(screen.size.width*.5, screen.size.height*.5)];
    self.arrow.backgroundColor=[UIColor clearColor];
    [self.view addSubview:self.arrow];
    [self.arrow setHidden:TRUE];
    
    
    int moreYpos=30;
    
    //stats
    self.displayText=[[UILabel alloc] initWithFrame:CGRectMake(10, screen.size.height-moreYpos-44-35, 200, 60)];
    self.displayText.numberOfLines=6;
    self.displayText.backgroundColor=[UIColor clearColor];
    self.displayText.textColor=[UIColor colorWithWhite:.3 alpha:1];
    [self.displayText setFont:[UIFont fontWithName:@"Andale Mono" size:7.0]];
    [self.view addSubview:self.displayText];
    

    
    
    //page number
    self.pageNText=[[UILabel alloc] initWithFrame:CGRectMake(screen.size.width-160, screen.size.height-moreYpos-44, 150, 30)];
    self.pageNText.backgroundColor=[UIColor clearColor];
    self.pageNText.textColor=[UIColor colorWithWhite:.3 alpha:1];
    [self.pageNText setFont:[UIFont fontWithName:@"Andale Mono" size:8.0]];
    self.pageNText.textAlignment = NSTextAlignmentRight;
    [self.view addSubview:self.pageNText];
    [self.pageNText setText:[NSString stringWithFormat:@"%i/%i", (int)self.page+1, (int)dele.nDestinations]];
    
    
    //location name button
    self.destinationButton=[[UIButton alloc] initWithFrame:CGRectMake(10, 25, screen.size.width-20, 80)];
    [self.destinationButton.titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:18.0]];
    [self.destinationButton setTitleColor:[UIColor colorWithWhite:.2 alpha:1] forState:UIControlStateNormal];
    self.destinationButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.destinationButton.backgroundColor=[UIColor clearColor];
    self.destinationButton.titleLabel.textAlignment=NSTextAlignmentCenter;
    self.destinationButton.contentVerticalAlignment= UIControlContentVerticalAlignmentTop;
    [self.destinationButton addTarget:self action:@selector(editLocationName) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.destinationButton];
    
    //progress arc
    [self loadArc];
    
    //accuracyText
    self.accuracyText=[[UILabel alloc] initWithFrame:CGRectMake(0,0, 100, 10)];
    [self.accuracyText setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:9.0]];
    [self.accuracyText setCenter:CGPointMake(screen.size.width*.5, screen.size.height*.5-30)];
    self.accuracyText.backgroundColor=[UIColor clearColor];
    self.accuracyText.textAlignment=NSTextAlignmentCenter;
    [self.view addSubview:self.accuracyText];
    
    
    //unitText
    self.unitText=[[UILabel alloc] initWithFrame:CGRectMake(0,0, 100, 10)];
    [self.unitText setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:9.0]];
    [self.unitText setCenter:CGPointMake(screen.size.width*.5, screen.size.height*.5+30)];
    self.unitText.backgroundColor=[UIColor clearColor];
    self.unitText.textAlignment=NSTextAlignmentCenter;
    [self.view addSubview:self.unitText];
    
    //main dist
    self.distanceText=[[UILabel alloc] initWithFrame:CGRectMake(0,0, 140, 60)];
    [self.distanceText setCenter:CGPointMake(screen.size.width*.5, screen.size.height*.5)];
    self.distanceText.numberOfLines=1;
    self.distanceText.textAlignment=NSTextAlignmentCenter;
    [self.distanceText setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:25.0]];
    //self.distanceText.adjustsFontSizeToFitWidth = YES;
    self.distanceText.backgroundColor=[UIColor clearColor];
    [self.view addSubview:self.distanceText];
    
    //add satSearchImage
    self.satSearchImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    self.satSearchImage.center=CGPointMake(screen.size.width*.5, screen.size.height*.5-30);
    self.satSearchImage.animationImages = [NSArray arrayWithObjects:
                                           [UIImage imageNamed:@"satellite_0003.png"],
                                           [UIImage imageNamed:@"satellite_0002.png"],
                                           [UIImage imageNamed:@"satellite_0001.png"],
                                           [UIImage imageNamed:@"satellite_0000.png"], nil];
    self.satSearchImage.animationDuration = 2.0f;
    self.satSearchImage.animationRepeatCount = 0;
    [self.satSearchImage startAnimating];
    [self.view addSubview: self.satSearchImage];
    self.satSearchImage.hidden=TRUE;
    
    [self updateHeading];
    

}


-(void)viewWillDisappear:(BOOL)animated{
    [self.arrow setAlpha:0.0];
    [self.arrow setHidden:TRUE];
}


-(void)viewDidDisappear:(BOOL)animated{
    [self.arrow setAlpha:0.0];
    [self.arrow setHidden:TRUE];
}


-(void)viewWillAppear:(BOOL)animated{    
    //check if page is in bounds
//    if( [[NSUserDefaults standardUserDefaults] integerForKey:@"currentDestinationN"]>= dele.nDestinations ) {
//        [[NSUserDefaults standardUserDefaults] setInteger:dele.nDestinations-1 forKey:@"currentDestinationN"];
//        self.page=[[NSUserDefaults standardUserDefaults] integerForKey:@"currentDestinationN"];
//    }


    [self loadLocation];
    [self.arrow setAlpha:0.0];
    [self.arrow setHidden:FALSE];
    [self updateDestinationName];
    [self showHideInfo:0];

}

-(void)viewDidAppear:(BOOL)animated
{
    //NSLog(@"show page %i",[[NSUserDefaults standardUserDefaults] integerForKey:@"currentDestinationN"]);
    
    [[NSUserDefaults standardUserDefaults] setInteger:self.page forKey:@"currentDestinationN"];


    [UIView animateWithDuration:0.4f
                          delay:0.2f
                        options: UIViewAnimationOptionCurveLinear | UIViewAnimationOptionBeginFromCurrentState
                     animations: ^(void){
                         [self.arrow setAlpha:1.0f];

                     }
                     completion: ^(BOOL finished){
                         //[self.arrow setHidden:FALSE];
                     }];
    //[self spinArc];
    
}

-(void)viewDidLayoutSubviews{
    self.arrow.center=CGPointMake(self.distanceText.center.x, self.distanceText.center.y);
    self.arcProgressView.center=CGPointMake(self.distanceText.center.x, self.distanceText.center.y);
}

-(void)loadArc{
    CGRect myImageRect;
    myImageRect = CGRectMake(self.distanceText.center.x-230*.5, self.distanceText.center.y-230*.5, 230, 230);
    
    self.arcProgressView= [[cwtDrawArc alloc] initWithFrame:myImageRect];
	self.arcProgressView.backgroundColor = [UIColor clearColor];
	[self.view addSubview:self.arcProgressView];
    
    self.arcProgressView.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapGesture =
    [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pickUnits)];
    [self.arcProgressView addGestureRecognizer:tapGesture];
}

-(void)loadLocation{
    [self calculateMaxDist];
    [self updateDistanceWithLatLng:0];
    //[self getBearing];
}

-(void)updateDestinationName{
    
    NSMutableDictionary * dictionary = [dele.locationDictionaryArray objectAtIndex:self.page];
    
    [self.destinationButton setTitle:[[dictionary objectForKey:@"searchedText"] uppercaseString] forState: UIControlStateNormal];
    // NSString *theText=[[dictionary objectForKey:@"searchedText"] uppercaseString] ;
}

-(void)updateDistanceWithLatLng: (float)duration{
    
    CLLocation *locA = [[CLLocation alloc] initWithLatitude:dele.myLat longitude:dele.myLng];
    CLLocation *locB = [[CLLocation alloc] initWithLatitude:self.dlat longitude:self.dlng];
    //distance in meters
    self.distance = [locA distanceFromLocation:locB];
    self.locBearing=[self getBearing];
    [self getBearingAccuracy];
    
    

    
    
    //near destination
    if( self.distance<= 20.0 && self.distance>=0 && dele.accuracy>0){
        self.satSearchImage.hidden=TRUE;
        self.accuracyText.text=  @"ARRIVED" ;
        [self rotateArc:duration degrees:self.locBearing-dele.heading];
        self.spinning=FALSE;
    }
    
    //positioning
    else if( (self.distance<= dele.accuracy*.5 && dele.accuracy > 20.0) || dele.accuracy<=0 || dele.headingAccuracy<0){
        self.accuracyText.text=@"";
        self.satSearchImage.hidden=FALSE;
        if(self.spinning==FALSE) {
            [self spinArc];
            self.spinning=TRUE;
        }
    }
    
    //normal pointing state
    else{
        //arc max set to 10km
        //self.progress = self.distance / 10000.0  * [self.arcProgressView maxArc];
        self.satSearchImage.hidden=TRUE;
        [self rotateArc:duration degrees:self.locBearing-dele.heading];
        self.spinning=FALSE;
        
        
        if([dele.units isEqual:@"m"]){
            self.accuracyText.text=[NSString stringWithFormat:@"± %i'",(int)(dele.accuracy*3.2808399) ];
        }
        else {
            self.accuracyText.text=[NSString stringWithFormat:@"± %im",(int)dele.accuracy ];
        }
        
        //        if(dele.accuracy>=120){
        //            //self.accuracyText.text=[NSString stringWithFormat:@"%@ ⚠",self.accuracyText.text ];
        //            [self.accuracyText setTextColor:[UIColor colorWithRed:1 green:0 blue:0 alpha:1]];
        //        }else if(dele.accuracy>=65){
        //            [self.accuracyText setTextColor:[UIColor colorWithRed:1 green:0 blue:0 alpha:.8]];
        //        }
        //        else{
        //            [self.accuracyText setTextColor:[UIColor colorWithWhite:0 alpha:.8]];
        //        }
        
        //if(self.maxDistance>0)  self.progress = self.distance / self.maxDistance*270.0;
        //if(self.progress>=270) self.progress=270;
        
        
    }
    
    //set arc to log scale
    self.progress =((log(1+self.distance)/log(100))*.275-.2)*[self.arcProgressView maxArc];
    
    [self.arcProgressView updateProgress:self.progress];

    
    
    //always update distance
    if([dele.units isEqual:@"m"]){
        
        if(self.distance<402.336){ //.25 miles in meters
            self.distanceText.text= [NSString stringWithFormat:@"%i",(int)(self.distance*3.28084)];
            self.unitText.text=@"FEET";
            
        }else{
            self.distanceText.text= [NSString stringWithFormat:@"%.2f",self.distance*0.000621371];
            self.unitText.text=@"MILES";
        }
        
    }
    else {
        if(self.distance<1000){
            self.distanceText.text= [NSString stringWithFormat:@"%i",(int)self.distance];
            self.unitText.text=@"METERS";
            
            
        }else{
            self.distanceText.text= [NSString stringWithFormat:@"%.2f",self.distance/1000];
            self.unitText.text=@"KM";
            
        }
    }
    
    //if(self.maxDistance<0) [self calculateMaxDist];
    
    //NSLog(@"%.2f",RADIANS_TO_DEGREES([self getBearing]));
}




-(void)calculateMaxDist{
    if( self.page < [dele.locationDictionaryArray count] ) {
        NSMutableDictionary * dictionary = [dele.locationDictionaryArray objectAtIndex:self.page];
        //NSLog(@"%@", dictionary);
        self.dlat=[[dictionary valueForKey:@"lat"] floatValue];
        self.dlng=[[dictionary valueForKey:@"lng"] floatValue];
    }
    
    if(self.dlat!=0){
        //CLLocation *locA = [[CLLocation alloc] initWithLatitude:dele.myLat longitude:dele.myLng];
        // CLLocation *locB = [[CLLocation alloc] initWithLatitude:self.dlat longitude:self.dlng];
        //distance in meters
        //self.maxDistance= [locA distanceFromLocation:locB];
        self.maxDistance= 100;
    }else{
        
        self.maxDistance=-1;
    }
    
    
}


- (int) getBearing
{
    
    float _lat1 = dele.myLat;
    float _lng1 = dele.myLng;
    float _lat2 = self.dlat;
    float _lng2 = self.dlng;
    
    double lat1 = DEGREES_TO_RADIANS(_lat1);
    double lat2 = DEGREES_TO_RADIANS(_lat2);
    double dLon = DEGREES_TO_RADIANS(_lng2) - DEGREES_TO_RADIANS(_lng1);
	
    double y = sin(dLon) * cos(lat2);
    double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
	double brng = atan2(y, x);
    return (int)(RADIANS_TO_DEGREES(brng) + 360) % 360;
    
}



-(void) getBearingAccuracy{
    
    float bearing=self.locBearing;
    float offset=bearing+90;
    
    float xMeters=cosf(DEGREES_TO_RADIANS(offset))*dele.accuracy;
    float yMeters=sinf(DEGREES_TO_RADIANS(offset))*dele.accuracy;
    
    //111111 meters / degree (approximate) +- 10m
    float olat1 = dele.myLat+xMeters/111111.0;
    float olng1 = dele.myLng+yMeters/111111.0;
    
    
    float _lat1 = olat1;
    float _lng1 = olng1;
    float _lat2 = self.dlat;
    float _lng2 = self.dlng;
    
    double lat1 = DEGREES_TO_RADIANS(_lat1);
    double lat2 = DEGREES_TO_RADIANS(_lat2);
    double dLon = DEGREES_TO_RADIANS(_lng2) - DEGREES_TO_RADIANS(_lng1);
	
    double y = sin(dLon) * cos(lat2);
    double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
	double brng = atan2(y, x);
    
    int altBearing= (int)(RADIANS_TO_DEGREES(brng) + 360) % 360;
    
    float accuracy=bearing-altBearing;
    
    accuracy= (int)(accuracy + 360) % 360;
    
    bearingAccuracy= accuracy;
    
    //NSLog(@"%f,%i,=%f",bearing,altBearing,accuracy);
}



-(void)spinArc{
    
    CGAffineTransform transform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(self.spin));

    
    [UIView animateWithDuration:1.0f
                          delay:0.0f
                        options: UIViewAnimationOptionCurveLinear | UIViewAnimationOptionBeginFromCurrentState
                     animations: ^(void){
                         //[self rotateArc:0 degrees:self.spin];
                         self.arrow.transform = transform;

                     }
                     completion: ^(BOOL finished){
                         if(finished){
                             self.spin+=90.0f;
                             self.spin=(int)self.spin%360;
                             if(self.spinning==TRUE) [self spinArc];
                             //NSLog(@"spin");
                         }
                         
                     }];


}

- (void)rotateArc:(NSTimeInterval)duration  degrees:(CGFloat)degrees
{
	CGAffineTransform transformRing = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(degrees));
    [UIView animateWithDuration:duration
                          delay:0.0f
                        options: UIViewAnimationOptionCurveLinear | UIViewAnimationOptionBeginFromCurrentState
                     animations: ^(void){
                         // The transform matrix
                         self.arrow.transform = transformRing;
                     }
                     completion: ^(BOOL finished){
                     }
     ];
}

- (void)updateHeading{
    //rotate arc if arrow is showing
    if(self.spinning==FALSE) {
        self.angle=self.locBearing-dele.heading;
        
        if(self.lastAngle!=self.angle){
            [self rotateArc:0.3f degrees:self.angle];
            self.lastAngle=self.angle;
        }

    }

    self.spread=dele.headingAccuracy+bearingAccuracy;
    
    if(self.spread!=self.lastSpread){
        //NSLog(@"%i/%i",self.spread,self.lastSpread);
        
//        [UIView animateWithDuration:.3f
//                              delay:0.0f
//                            options:UIViewAnimationOptionCurveEaseInOut
//                         animations:^{
                             [self.arrow updateSpread:self.spread];

//                         }
//                         completion:nil];
        
        
        self.lastSpread=self.spread;
    }
    
    [self updateAccuracyText];
}


-(void)showHideInfo: (float)duration{
    BOOL info=[[NSUserDefaults standardUserDefaults] boolForKey:@"showInfo"];

    [UIView animateWithDuration:duration
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         if(!info) {
                             [self.displayText setAlpha: 0.0f];
                             [self.pageNText setAlpha: 0.0f];
                             [self.accuracyText setAlpha: 0.0f];
                             [self.arrow showExtras: FALSE];
                             [self.arcProgressView showExtras:FALSE];
                         }
                         else {
                             [self.displayText setAlpha: 1.0f];
                             [self.pageNText setAlpha: 1.0f];
                             [self.accuracyText setAlpha: 1.0f];
                             [self.arrow showExtras: TRUE];
                             [self.arcProgressView showExtras:TRUE];
                         }
                     }
                     completion:nil];
}

-(void)updateAccuracyText{
    NSString *statusString;
    float speed=dele.speed*3.6;
    if(speed<0)speed=0;
    float headingAccuracy=dele.headingAccuracy;
    
    NSString *speedString;
    NSString *altitudeString;
    NSString *currentString;

    if([dele.units isEqual:@"m"]){
        speedString=[NSString stringWithFormat:@"%.2fmph",speed*.621371f];
        altitudeString=[NSString stringWithFormat:@"%.2fft ±%.2f",dele.altitude*3.28084,dele.altitudeAccuracy*3.28084];
        currentString=[NSString stringWithFormat:@"%f,%f ±%.2fft",dele.myLat,dele.myLng, (int)dele.accuracy*3.28084];
        
    }else{
        
        speedString=[NSString stringWithFormat:@"%.2fkph",speed];
        altitudeString=[NSString stringWithFormat:@"%.2fm ±%.2f",dele.altitude,dele.altitudeAccuracy];
        currentString=[NSString stringWithFormat:@"%f,%f ±%im",dele.myLat,dele.myLng, (int)dele.accuracy];
    }

    
    if(headingAccuracy<0)headingAccuracy=0;
    statusString= [NSString stringWithFormat:@
                   "speed   : %@ \n"
                   "heading : %i° ±%i°\n"
                   "bearing : %i° ±%i°\n"
                   "altitude: %@\n"
                   "target  : %f,%f \n"
                   "current : %@"
                   ,
                   speedString,
                   (int)dele.heading,(int)headingAccuracy,
                   (int)self.locBearing,(int)bearingAccuracy,
                   altitudeString,
                   self.dlat , self.dlng,
                   currentString
                   ];
    
    self.displayText.text=statusString;
}

-(void)editLocationName{
    [dele.viewController showLocationEditAlert];
}

- (void) pickUnits{
    //NSLog(@"switch Units");
    if([dele.units isEqual:@"m"])dele.units=@"km";
    else dele.units=@"m";
    [[NSUserDefaults standardUserDefaults] setObject:dele.units forKey:@"units"];
    [self updateDistanceWithLatLng:0];
    
    [dele.viewController nextInstruction:6];

}

- (void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    //    cwtAppDelegate* dele=[[UIApplication sharedApplication] delegate];
    //
    //    //edit location name
    //	if(alertView.tag==5){
    //		if(buttonIndex==1){
    //            self.destinationButton.titleLabel.text=self.nameField.text;
    //
    //			[dele editDestination:self.nameField.text newlat:0 newlng:0];
    //
    //		}
    //	}
    
}

-(void) hideArrow:(BOOL) state
{
    self.arrow.hidden=state;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [super viewDidUnload];
}
@end

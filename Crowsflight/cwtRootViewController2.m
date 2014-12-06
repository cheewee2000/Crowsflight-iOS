
//
//  cwtViewController.m
//  Crowsflight
//
//  Created by Che-Wei Wang on 5/4/13.
//  Copyright (c) 2013 CW&T. All rights reserved.
//

#import "cwtRootViewController2.h"
#import "cfLocationViewController2.h"
#import "cwtMapViewController.h"
#import "cwtListViewController.h"

#import "cwtIAP.h"
#import <StoreKit/StoreKit.h>

#import "QuartzCore/CALayer.h"
#import "cwtToolbar.h"

#define DEGREES_TO_RADIANS(angle) (angle / 180.0 * M_PI)

@interface cwtRootViewController2 ()<UIPageViewControllerDataSource, UIPageViewControllerDelegate>

@end

@implementation cwtRootViewController2

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
    
    dele = [[UIApplication sharedApplication] delegate];
    
	// Do any additional setup after loading the view.
    self.view.backgroundColor=[UIColor colorWithWhite:.95 alpha:1];
    
    CGRect screen = [[UIScreen mainScreen] applicationFrame];
    
    
    
    self.view.layer.masksToBounds=NO;
    
    //add compass
    self.compassImage=[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"compass-background.png"]];
    self.compassImage.center=CGPointMake(screen.size.width*.5, screen.size.height*.5);
    [self.view addSubview:self.compassImage];

    self.compassN=[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"compass-n.png"]];
    self.compassN.center=CGPointMake(screen.size.width*.5, screen.size.height*.5);
    [self.view addSubview:self.compassN];
    
    
    
    self.pageView=[[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    self.pageView.dataSource = self;
    self.pageView.delegate = self;
    self.pageView.view.layer.masksToBounds=FALSE;
    [self.view addSubview:self.pageView.view];
        self.pageView.view.frame=CGRectMake(0, 0, CGRectGetWidth(self.view.bounds),  CGRectGetHeight(self.view.bounds));
    
    
    self.locationViewController=[[cfLocationViewController2 alloc] init];
    //make sure currentDestinationN is not out of bounds
    if( [[NSUserDefaults standardUserDefaults] integerForKey:@"currentDestinationN"]>= [dele.locationDictionaryArray count] ) {
        [[NSUserDefaults standardUserDefaults] setInteger:[dele.locationDictionaryArray count]-1 forKey:@"currentDestinationN"];
    }
    self.locationViewController.page=[[NSUserDefaults standardUserDefaults] integerForKey:@"currentDestinationN"];
    [self addChildViewController:self.pageView];
    
    [self.pageView setViewControllers:@[self.locationViewController] direction:UIPageViewControllerNavigationDirectionForward  animated:NO completion:^(BOOL finished) {
        //code
    }
     ];
    
    



    
    [[SIAlertView appearance] setMessageFont:[UIFont systemFontOfSize:13]];
    [[SIAlertView appearance] setCornerRadius:0];
    [[SIAlertView appearance] setShadowRadius:20];
    
    
    
    
    //custom toolbar
    UIView* buttonBar=[[UIView alloc ]initWithFrame:CGRectMake(0, screen.size.height-44, screen.size.width, 44)];
    
    buttonBar.layer.masksToBounds = NO;
    buttonBar.layer.shadowOffset = CGSizeMake(0, -1);
    buttonBar.layer.shadowRadius = 2;
    buttonBar.layer.shadowOpacity = 0.3;
    buttonBar.layer.shadowPath = [UIBezierPath bezierPathWithRect:buttonBar.bounds].CGPath;
    [self.view addSubview:buttonBar];
    buttonBar.backgroundColor=[UIColor colorWithWhite:1 alpha:.75];
    //  [buttonBar setAlpha:1];
    
    int iconWidth=44;
    
    UIButton *hamburger = [UIButton buttonWithType:UIButtonTypeCustom];
    [hamburger setBackgroundImage:[UIImage imageNamed:@"hamburger.png"] forState:UIControlStateNormal];
    hamburger.frame=CGRectMake(10.0, 0,iconWidth, iconWidth);
    [hamburger addTarget:self action:@selector(showList) forControlEvents:UIControlEventTouchUpInside];
    [buttonBar addSubview:hamburger];
    
    UIButton *pin = [UIButton buttonWithType:UIButtonTypeCustom];
    [pin setBackgroundImage:[UIImage imageNamed:@"pin.png"] forState:UIControlStateNormal];
    pin.frame=CGRectMake(screen.size.width*.5-iconWidth*.5, 0, iconWidth,iconWidth);
    [pin addTarget:self action:@selector(pinCurrentLocation) forControlEvents:UIControlEventTouchUpInside];
    [buttonBar addSubview:pin];
    
    UIButton *map = [UIButton buttonWithType:UIButtonTypeCustom];
    [map setBackgroundImage:[UIImage imageNamed:@"map.png"] forState:UIControlStateNormal];
    map.frame=CGRectMake(screen.size.width-iconWidth-10, 0, iconWidth,iconWidth);
    [map addTarget:self action:@selector(openMapView) forControlEvents:UIControlEventTouchUpInside];
    [buttonBar addSubview:map];
    
    
    //more info button
    iconWidth=50;
    moreInfo = [UIButton buttonWithType:UIButtonTypeCustom];
    //moreInfo.frame=CGRectMake(screen.size.width-iconWidth-10, 100.0, iconWidth,iconWidth);
    moreInfo.frame=CGRectMake(screen.size.width*.5-iconWidth*.5, screen.size.height-60.0-iconWidth, iconWidth,iconWidth);
    
    [moreInfo addTarget:self action:@selector(setShowInfo) forControlEvents:UIControlEventTouchUpInside];
    [moreInfo setImage:[UIImage imageNamed:@"more-info2.png"] forState:UIControlStateNormal];
    [moreInfo setImage:[UIImage imageNamed:@"less-info.png"] forState:UIControlStateSelected];
    
    [self.view addSubview:moreInfo];
    
    
    
    
    
    //check for inapp purchase
    //[self checkPurchased ];
    
}



-(void)viewWillAppear:(BOOL)animated{
    
    [self.pageView setViewControllers:@[self.locationViewController] direction:UIPageViewControllerNavigationDirectionForward  animated:NO completion:^(BOOL finished) {
        //code
        
        
    }
     ];
    
    if( [[NSUserDefaults standardUserDefaults] integerForKey:@"currentDestinationN"]>= [dele.locationDictionaryArray count] ) {
        [[NSUserDefaults standardUserDefaults] setInteger:[dele.locationDictionaryArray count]-1 forKey:@"currentDestinationN"];
    }
    
    self.locationViewController.page=[[NSUserDefaults standardUserDefaults] integerForKey:@"currentDestinationN"];
    
    
    //hide or unhide info
    self.showInfo=[[NSUserDefaults standardUserDefaults] boolForKey:@"showInfo"];
    NSLog(@"read show info %i",self.showInfo);

    [moreInfo setSelected:self.showInfo];

    if(self.showInfo==FALSE) {
        [self.compassImage setAlpha: 0.0f];
        [self.compassImage setHidden:YES];
    }
    else {
        [self.compassImage setAlpha: 1.0f];
        [self.compassImage setHidden:NO];

    }
    
    
    NSLog(@"locationViewController show %i",self.locationViewController.page);
    

}

-(void)viewDidAppear:(BOOL)animated
{
}


-(void)viewDidLayoutSubviews{
    //CGRect screen = [[UIScreen mainScreen] applicationFrame];
    //self.compassImage.center=CGPointMake(screen.size.width*.5, screen.size.height*.5+22);
    
}


-(void)updateViewControllersWithName{
    
    NSArray* viewC = [self.pageView viewControllers];
    [[viewC objectAtIndex:0] updateDestinationName];
}


-(void)updateViewControllersWithLatLng: (int)_page{
    NSArray* viewC = [self.pageView viewControllers];
    cfLocationViewController2 * vc=[viewC objectAtIndex:0];
    [vc updateDistanceWithLatLng:.3];
}


-(void)updateViewControllersWithHeading: (int)_page{
    NSArray* viewC = [self.pageView viewControllers];
    [[viewC objectAtIndex:0] updateHeading];
    [self rotateCompass:.1 degrees:-dele.heading];
    
}


- (void)rotateCompass:(NSTimeInterval)duration  degrees:(CGFloat)degrees
{

    CGAffineTransform transformCompass = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(degrees));

    [UIView animateWithDuration:0.3f
                          delay:0.0f
                        options: UIViewAnimationOptionCurveLinear | UIViewAnimationOptionBeginFromCurrentState
                     animations: ^(void){
                         // The transform matrix
                         self.compassImage.transform = transformCompass;
                         self.compassN.transform = transformCompass;
                     }
                     completion: ^(BOOL finished){
                         }
                     ];
    
}


-(IBAction)openListView:(id)sender{
    [self showList];
}

-(void)showList{
    //create view
    self.listViewController = [[cwtListViewController alloc] init];
    
    CGRect screen = [[UIScreen mainScreen] applicationFrame];
    CGRect frame=CGRectMake(0, 0, screen.size.width-40, screen.size.height);
    self.listViewController.view.frame = frame;
    [self.navigationController pushDrawerViewController:self.listViewController  withStyle:DrawerLayoutStyleLeftAnchored animated:YES];
    
    
}


-(void)setShowInfo{
    
    self.showInfo=!self.showInfo;
    [[NSUserDefaults standardUserDefaults] setBool:self.showInfo forKey:@"showInfo"];
    NSLog(@"set show info %i",self.showInfo);
    
    
    if(self.showInfo){
        [self.compassImage setHidden:FALSE];
        [self.compassImage setAlpha: 0.0f];
    }
    
    [moreInfo setSelected:self.showInfo];
    
    [UIView animateWithDuration:0.3f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         if(!self.showInfo)[self.compassImage setAlpha: 0.0f];
                         else [self.compassImage setAlpha:1.0f];
                     }
                     completion:^(BOOL finished){
                         [self.compassImage setHidden:!self.showInfo];
                     }];
    
    NSArray* viewC = [self.pageView viewControllers];
    [[viewC objectAtIndex:0] showHideInfo:.3f];
    
    //NSLog(@"switch showinfo");
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UIPageViewController Data Source

- (UIViewController*)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    NSInteger indx = [(cfLocationViewController2*)viewController page];
    indx++;
    
    if( indx>= [dele.locationDictionaryArray count] ) return nil;
    
    
    cfLocationViewController2* newLoc = [[cfLocationViewController2 alloc] init];
    newLoc.page = indx;
    return newLoc;
}

- (UIViewController*)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    NSInteger indx = [(cfLocationViewController2*)viewController page];
    indx--;
    
    if( indx<0 ) return nil;
    
    cfLocationViewController2* newLoc = [[cfLocationViewController2 alloc] init];
    newLoc.page = indx;
    return newLoc;
}


- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController
{
    NSArray* viewC = [self.pageView viewControllers];
    
    return   [viewC count];
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController
{
    return   self.locationViewController.page;
    
}


- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray *)pendingViewControllers{
    
}



#pragma mark - Add Location
-(IBAction)addLocation:(id)sender{
    
    //	if([[NSUserDefaults standardUserDefaults] boolForKey:@"unlockcrowsflight"]==NO && [dele.locationDictionaryArray count]>5){
    //		[self checkPurchased];
    //	}
    //    else
    //	{
    //		//get accuracy
    //		NSString *accuracy=[[NSString alloc] init];
    //		if([dele.units isEqual:@"m"]){
    //			accuracy=[NSString stringWithFormat:@"± %.1f\'",dele.accuracy*3.2808399 ] ;
    //			if(dele.accuracy*3.2808399<1000){
    //				accuracy=[NSString stringWithFormat:@"± %.1f\'",dele.accuracy*3.2808399 ] ;
    //			}
    //			else{
    //				accuracy=[NSString stringWithFormat:@"± %.1fmi",dele.accuracy*3.2808399/5280.0  ];
    //			}
    //		}
    //		else{
    //
    //			if(dele.accuracy<1000){
    //				accuracy=[NSString stringWithFormat:@"± %.1fm",dele.accuracy ];
    //			}
    //			else{
    //				accuracy=[NSString stringWithFormat:@"± %.1fm",dele.accuracy/1000.0 ];
    //			}
    //
    //		}
    //
    //		NSString *mess=[NSString stringWithFormat:@"Accuracy:%@\nLat:%f Lng:%f\n\n ",accuracy,dele.myLat,dele.myLng];
    //
    //
    //		addLocAlert = [[UIAlertView alloc] initWithTitle:@"Save Current Position" message:mess delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Done", nil];
    //		addLocAlert.tag = 3;
    //
    //		nameField = [[UITextField alloc] initWithFrame:CGRectMake(12, 100, 260, 27)];
    //		[nameField setBackgroundColor:[UIColor whiteColor]];
    //		[nameField setPlaceholder:@"Location Name"];
    //		nameField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    //
    //		// no auto correction support
    //		nameField.autocorrectionType = UITextAutocorrectionTypeNo;
    //		nameField.returnKeyType = UIReturnKeyDone;
    //		// has a clear 'x' button to the right
    //		nameField.clearButtonMode = UITextFieldViewModeWhileEditing;
    //		nameField.borderStyle = UITextBorderStyleRoundedRect;
    //		//nameField.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
    //		nameField.delegate=self;
    //		nameField.tag=3;
    //
    //		[addLocAlert addSubview:nameField];
    //
    //		[addLocAlert show];
    //		[nameField becomeFirstResponder];
    //	}
}

-(void)pinCurrentLocation{
    
	if([[NSUserDefaults standardUserDefaults] boolForKey:@"unlockcrowsflight"]==NO && [dele.locationDictionaryArray count]>=5){
		[self checkPurchased];
	}
    else
	{
        
        NSString *mess;
        
        if([dele.units isEqual:@"m"]){
            mess=[NSString stringWithFormat:@"± %i\'",(int)(dele.accuracy*3.2808399 )] ;
        }
        else {
            mess=[NSString stringWithFormat:@"± %im",(int)dele.accuracy ];
        }
        
        
        //NSString *mess=[NSString stringWithFormat:@"Accuracy:±%.2f%@",dele.accuracy];
        
		addLocAlert = [[SIAlertView alloc] initWithTitle:@"SAVE CURRENT POSITION" andMessage:mess];
        addLocAlert.showTextField=TRUE;
        addLocAlert.textFieldTag=4;
        addLocAlert.keyboardGo=@"ADD";
        [addLocAlert show];
        
        
        
        // [self addNewDestination:[NSString stringWithFormat:@"%f,%f",dele.myLat,dele.myLng] newlat:dele.myLat newlng:dele.myLng];
    }
}


-(void)addNewDestination:(NSString *)name newlat:(double)_lat newlng:(double)_lng{
    
	//clear last search text
	[[NSUserDefaults standardUserDefaults] setObject:@"" forKey:@"lastSearchText"];
    
    
	//save to locationList
	NSArray *keys = [NSArray arrayWithObjects:@"searchedText", @"address", @"lat", @"lng", nil];
	[dele.locationDictionaryArray addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects: name, @"123 address place holder", [NSNumber numberWithFloat:_lat], [NSNumber numberWithFloat:_lng], nil] forKeys:keys]];
	
	//set save path
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSString *path = [documentsDirectory stringByAppendingPathComponent:@"/locationList.plist"];
	
	//write to file
	bool didWrite=[dele.locationDictionaryArray writeToFile:path atomically:YES];
	
	if(didWrite){
        [[NSUserDefaults standardUserDefaults] setInteger:[dele.locationDictionaryArray count]-1 forKey:@"currentDestinationN"];
		NSLog(@"Saved destination. nDestinations: %i", [dele.locationDictionaryArray count]);
        
        [dele loadmyLocations];
        
        
        [self flipToPage:[[NSUserDefaults standardUserDefaults] integerForKey:@"currentDestinationN"]];
    }
    
}

-(void) flipToPage:(NSInteger)x {
    
    NSUInteger retreivedIndex =self.locationViewController.page;
    
    cfLocationViewController2 *neighborViewController = [self viewControllerAtIndex:x-1];
    cfLocationViewController2 *firstViewController = [self viewControllerAtIndex:x];
    cfLocationViewController2 *secondViewController = [self viewControllerAtIndex:x+1 ];
    
    
    NSArray *viewControllers = nil;
    
    
    if (retreivedIndex < x){
        viewControllers = [NSArray arrayWithObjects:neighborViewController, nil];
        [self.pageView setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:NULL];
        viewControllers = [NSArray arrayWithObjects:firstViewController, secondViewController, nil];
        [self.pageView setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:NULL];
    } else if (retreivedIndex > x ){
        viewControllers = [NSArray arrayWithObjects:neighborViewController, nil];
        [self.pageView setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionReverse animated:NO completion:NULL];
        viewControllers = [NSArray arrayWithObjects:firstViewController, secondViewController, nil];
        [self.pageView setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionReverse animated:YES completion:NULL];
    }
    
    
    
    
}

- (cfLocationViewController2 *)viewControllerAtIndex:(NSUInteger)index {
    if (([dele.locationDictionaryArray count] == 0) || (index >= [dele.locationDictionaryArray count])) {
        return nil;
    }
    cfLocationViewController2* newLoc = [[cfLocationViewController2 alloc] init];
    newLoc.page =  index;
    return newLoc;
}


#pragma mark - Search
- (IBAction)showSearch:(id)sender{
    [self showSearchBar];
    
}

-(void) showSearchBar{
    
	if([[NSUserDefaults standardUserDefaults] boolForKey:@"unlockcrowsflight"]==NO && [dele.locationDictionaryArray count]>=5){
		[self checkPurchased];
	}
	else
	{
        
        searchAlert= [[SIAlertView alloc] initWithTitle:@"SEARCH" andMessage:@"Enter an address, placename, or lat,lng \n(e.g. 40.729,-73.993)"];
        //        [searchAlert addButtonWithTitle:@"X"
        //                                   type:SIAlertViewButtonTypeCancel
        //                                handler:^(SIAlertView *alertView) {
        //                                    NSLog(@"x");
        //                                }];
        
        searchAlert.showTextField=TRUE;
        searchAlert.textFieldTag=0;
        searchAlert.keyboardGo=@"SEARCH";
        [searchAlert show];
        
	}
    
}



-(void)searchGeo:(UITextField*)searchField{
	//check if it's a lat lng
    
    //save search value
    //[[NSUserDefaults standardUserDefaults] setObject:searchField.text forKey:@"lastSearchText"];
    
    
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"unlockcrowsflight"]==NO && [dele.locationDictionaryArray count]>=5){
		[self checkPurchased];
	}
	else
    {
        BOOL isAddress=TRUE;
        NSMutableArray *slatlng = [[NSMutableArray alloc] init];
        
        [slatlng setArray:[searchField.text componentsSeparatedByString:@","]];
        
        if([slatlng count]==2){
            //NSLog(@"parsing lat lng");
            
            NSString* slat = [slatlng objectAtIndex: 0];
            NSString* slng = [slatlng objectAtIndex: 1];
            
            NSRegularExpression* regex = [[NSRegularExpression alloc] initWithPattern:@"-?\\d+\\.\\d+" options:NSRegularExpressionCaseInsensitive error:nil];
            
            NSArray* matches = [regex matchesInString:searchField.text options:0 range:NSMakeRange(0, [searchField.text length])];
            
            //NSLog(@"match=%@", matches );
            
            if([matches count]==2)
            {
                [self addNewDestination:searchField.text newlat:[slat doubleValue] newlng:[slng doubleValue] ];
                isAddress=FALSE;
            }
            
        }
        
        if(isAddress){
            
            //BOOL* internet=[self performSelectorInBackground:@selector(hasInternet) withObject:self.view];
            

            CLGeocoder *geocoder = [[CLGeocoder alloc] init];
            
            //show progress
            progressAlert = [ [SIAlertView alloc] initWithTitle: @"SEARCHING FOR..." andMessage:searchField.text ];
            
            progressAlert.showSpinner=TRUE;
            progressAlert.showTextField=FALSE;
            
            [progressAlert show];
            
            //[geocoder geocodeAddressString:searchField.text completionHandler:^(NSArray *placemarks, NSError *error) {
            
            [geocoder geocodeAddressString:searchField.text inRegion:nil completionHandler:^(NSArray *placemarks, NSError *error){
                
                
                //user forced cancel
                if(progressAlert.visible==NO)return;
                
                //Error checking
                [progressAlert dismissAnimated:YES];
                
                CLPlacemark *placemark = [placemarks objectAtIndex:0];
                
                float lat=placemark.region.center.latitude;
                float lng=placemark.region.center.longitude;
                
                if(lat!=0){
                    
                    //create view
                    cwtMapViewController * mapViewController = [[cwtMapViewController alloc] init];
                    CGRect frame = mapViewController.view.frame;
                    frame.origin = CGPointMake(0, 0);
                    
                    mapViewController.view.frame = frame;
                    
                    NSString* lastSearch=[[NSUserDefaults standardUserDefaults] stringForKey:@"lastSearchText"];
                    
                    mapViewController->wasSearchView=true;
                    [mapViewController zoomMapAndCenterAtLatitude:lat andLongitude:lng andName:lastSearch];
                    
                    [self.navigationController pushDrawerViewController:mapViewController  withStyle:DrawerLayoutStyleRightAnchored animated:YES];
                    
                    
                }
                else
                {
                    NSString* mess=@"";
                    
                    //if(error.code==-1009) mess=@"No Internet Connection";
                    //   else mess=error.description;
                    
                    SIAlertView* alert = [ [SIAlertView alloc] initWithTitle: @"NO RESULTS" andMessage:mess];
                    [alert addButtonWithTitle:@"OK"
                                         type:SIAlertViewButtonTypeDefault
                                      handler:^(SIAlertView *alertView) {
                                          
                                          [self showList];
                                          //give text view first responder
                                          
                                          
                                      }];
                    
                    alert.showTextField=FALSE;
                    [alert show];
                }
                
                
                
            }];
        }
    }
}



-(BOOL)hasInternet{
    NSURL *scriptUrl = [NSURL URLWithString:@"http://apple.com/"];
    NSData *data = [NSData dataWithContentsOfURL:scriptUrl];
    if (!data)
    {
        //        SIAlertView* alert = [ [SIAlertView alloc] initWithTitle: @"CANNOT REACH SERVER" andMessage:@""];
        //        [alert addButtonWithTitle:@"OK"
        //                             type:SIAlertViewButtonTypeDefault
        //                          handler:^(SIAlertView *alertView) {
        //
        //                              [progressAlert dismissAnimated:NO];
        //
        //
        //                          }];
        //        alert.transitionStyle = SIAlertViewTransitionStyleSlideFromTop;
        //        alert.backgroundStyle=SIAlertViewBackgroundStyleGradient;
        //        //CGRect screen = [[UIScreen mainScreen] applicationFrame];
        //        alert.containerHeight=130;
        //        //alert.topPosition=screen.size.height-216-[searchAlert containerHeight];//216 is keyboard height
        //        alert.topPosition=0;
        //        alert.showTextField=FALSE;
        //        [alert show];
        return FALSE;
    }else
        return TRUE;
    
}

-(void)showLocationEditAlert{
    bool expired=false;
    
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"unlockcrowsflight"]==NO ){
        //expired=[dele. checkDate];
    }
    if(expired==false)
    {
        //load destination number
        int currentDestinationN=[[NSUserDefaults standardUserDefaults] integerForKey:@"currentDestinationN"];
        
        //load dictionary
        NSMutableDictionary * dictionary = [dele.locationDictionaryArray objectAtIndex:currentDestinationN];
        NSString *st =[dictionary objectForKey:@"searchedText"];
        
        addLocAlert= [[SIAlertView alloc] initWithTitle:@"EDIT LOCATION NAME" andMessage:@""];
        
        addLocAlert.showTextField=TRUE;
        addLocAlert.textFieldTag=3;
        addLocAlert.keyboardGo=@"DONE";
        
        [addLocAlert show];
        
        [addLocAlert.textField setText:st ] ;
    }
}




// display a given NSError in an UIAlertView
- (void)displayError:(NSError*)error
{
    dispatch_async(dispatch_get_main_queue(),^ {
        
        NSString *message;
        switch ([error code])
        {
            case kCLErrorGeocodeFoundNoResult:
                message = @"kCLErrorGeocodeFoundNoResult";
                break;
            case kCLErrorGeocodeCanceled:
                message = @"kCLErrorGeocodeCanceled";
                break;
            case kCLErrorGeocodeFoundPartialResult:
                message = @"kCLErrorGeocodeFoundNoResult";
                break;
            default:
                message = [error description];
                break;
        }
        
        UIAlertView *alert =  [[UIAlertView alloc] initWithTitle:@"An error occurred."
                                                         message:message
                                                        delegate:nil
                                               cancelButtonTitle:@"OK"
                                               otherButtonTitles:nil];;
        [alert show];
    });
}


#pragma mark - map

-(void)openMapView{
    //create view
    
    cwtMapViewController * mapViewController = [[cwtMapViewController alloc] init];
    CGRect frame = mapViewController.view.frame;
    frame.origin = CGPointMake(0, 20);
    // To account for the status bar. Otherwise the gap is at the bottom during animation that adjusts after it completes.
    
    mapViewController.view.frame = frame;
    
    //load destination name
    //int currentDestinationN=[[NSUserDefaults standardUserDefaults] integerForKey:@"currentDestinationN"];
    
    //load dictionary
    //NSMutableDictionary * dictionary = [dele.locationDictionaryArray objectAtIndex:currentDestinationN];
    
    //NSString *st =[dictionary objectForKey:@"searchedText"];
    
    
	//float lat=[[dictionary valueForKey:@"lat"] floatValue];
	//float lng=[[dictionary valueForKey:@"lng"] floatValue];
    
    //[mapViewController zoomMapAndCenterAtLatitude:lat andLongitude:lng andName:st];
    [mapViewController zoomLoadPoints];
    
    mapViewController->wasSearchView=false;
    
    // subsequent views get pushed, pulled, prodded, etc.
    [self.navigationController pushDrawerViewController:mapViewController  withStyle:DrawerLayoutStyleRightAnchored animated:YES];
    
    //    NSLog(@"show map of %i",currentDestinationN);
    
}


#pragma mark - Textfield

//textfield
- (void)textFieldDidEndEditing:(UITextField *)textField{
	//cout<<"done editing";
}



- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    //close keyboard
    [textField setUserInteractionEnabled:YES];
    [textField resignFirstResponder];
    
    //hit search on keyboard
	if(textField.tag==0){
        if([textField.text length]>0)
        {
            [self searchGeo:textField];
            //[searchAlert dismissAnimated:YES];
        }
        
        
	}
    
    //hit done on keyboard after editing
    else if(textField.tag==3){
        
		[addLocAlert dismissAnimated:YES];
        [dele editDestination:textField.text newlat:0 newlng:0];
	}
    
    //hit done on keyboard after editing
    else if(textField.tag==4){
        [self addNewDestination:textField.text newlat:dele.myLat newlng:dele.myLng];
        [addLocAlert dismissAnimated:YES];
        
    }
    return YES;
}


#pragma mark - alertview

- (void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	//add new location
	if(alertView.tag==3){
		
		if(buttonIndex==1){
			//[self addNewDestination:nameField.text newlat:dele.myLat newlng:dele.myLng ];
		}
	}
    
    //iap
    if(alertView.tag==6){
		//[inappAlert dismissWithClickedButtonIndex:0 animated:YES];
		
		if(buttonIndex==1){
            
            [self purchase];
            
		}
		
	}
    
    
    
}



#pragma mark - inapp
-(void)purchase{
    [[cwtIAP sharedInstance] requestProductsWithCompletionHandler:^(BOOL success, NSArray *products) {
        if (success) {
            
            //NSLog(@"%i",products.count);
            if(products.count>0){
                SKProduct * product = (SKProduct *) products[0];
                NSLog(@"%@",product.localizedTitle);
                [[cwtIAP sharedInstance]  buyProduct:product];
                
            }
            
        }
    }];
    
}
-(void)checkPurchased{
	if([[NSUserDefaults standardUserDefaults] boolForKey:@"unlockcrowsflight"]==NO )
	{
        //purchased=true;
        inappAlert = [[UIAlertView alloc] initWithTitle:@"Unlock Crowsflight" message:@"You are currently limited to saving 5 locations. By unlocking the app, you'll be able to save unlimited locations and help us continue working on this app. If you've already paid for an unlock on any iOS device, unlocking again is free. <3 CW&T" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
        [inappAlert addButtonWithTitle:@"Unlock"];
        inappAlert.tag=6;
        [inappAlert show];
	}
}



@end

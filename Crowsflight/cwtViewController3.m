
//
//  cwtViewController.m
//  Crowsflight
//
//  Created by Che-Wei Wang on 5/4/13.
//  Copyright (c) 2013 CW&T. All rights reserved.
//

#import "cwtViewController3.h"
#import "cfLocationViewController2.h"

#import "cwtListViewController.h"

#import "cwtIAP.h"
#import <StoreKit/StoreKit.h>

#import "QuartzCore/CALayer.h"
#import "cwtToolbar.h"

#import "cwtMapViewController.h"



#define DEGREES_TO_RADIANS(angle) (angle / 180.0 * M_PI)





@interface cwtViewController3 ()<UIPageViewControllerDataSource, UIPageViewControllerDelegate>

@property (nonatomic, strong) cwtMapViewController *mapViewController;

@end

@implementation cwtViewController3

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
    
    //CGRect screen = [[UIScreen mainScreen] applicationFrame];
    CGRect screen = self.view.frame;

    
    
    self.view.layer.masksToBounds=NO;
    
    //add compass
    self.compassImage=[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"compass-background"]];
    self.compassImage.center=CGPointMake(screen.size.width*.5, screen.size.height*.5);
    [self.view addSubview:self.compassImage];
    
    self.compassN=[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"compass-n"]];
    self.compassN.center=CGPointMake(screen.size.width*.5, screen.size.height*.5);
    [self.view addSubview:self.compassN];
    
    
    
    self.pageView=[[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    self.pageView.dataSource = self;
    self.pageView.delegate = self;
    self.pageView.view.layer.masksToBounds=FALSE;
    [self.view addSubview:self.pageView.view];
    self.pageView.view.frame=CGRectMake(0, 0, CGRectGetWidth(self.view.bounds),  CGRectGetHeight(self.view.bounds));
    
    
    self.locationViewController=[[cfLocationViewController2 alloc] init];

    
    
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
    [hamburger setBackgroundImage:[UIImage imageNamed:@"hamburger"] forState:UIControlStateNormal];
    hamburger.frame=CGRectMake(screen.size.width*.07, 0,iconWidth, iconWidth);
    [hamburger addTarget:self action:@selector(showList) forControlEvents:UIControlEventTouchDown];
    [buttonBar addSubview:hamburger];
    
    UIButton *pin = [UIButton buttonWithType:UIButtonTypeCustom];
    [pin setBackgroundImage:[UIImage imageNamed:@"pin"] forState:UIControlStateNormal];
    pin.frame=CGRectMake(screen.size.width*.5-iconWidth*.5, 0, iconWidth,iconWidth);
    [pin addTarget:self action:@selector(pinCurrentLocation) forControlEvents:UIControlEventTouchDown];
    [buttonBar addSubview:pin];
    
    UIButton *map = [UIButton buttonWithType:UIButtonTypeCustom];
    [map setBackgroundImage:[UIImage imageNamed:@"map"] forState:UIControlStateNormal];
    map.frame=CGRectMake(screen.size.width-iconWidth-screen.size.width*.07, 0, iconWidth,iconWidth);
    [map addTarget:self action:@selector(openMapView) forControlEvents:UIControlEventTouchDown];
    [buttonBar addSubview:map];
    
    
    //map
    // create and reuse for later the mapViewController
    self.mapViewController = [[cwtMapViewController alloc] init];
                          CGRect frame = self.mapViewController.view.frame;
                            frame.origin = CGPointMake(0, 0);
                            self.mapViewController.view.frame = frame;
    

    
    
    //sounds
    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Crowsflight_Create_001" ofType:@"wav"]];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)url, &audioCreate);
    
    //more info button
    iconWidth=50;
    moreInfo = [UIButton buttonWithType:UIButtonTypeCustom];
    moreInfo.frame=CGRectMake(screen.size.width*.5-iconWidth*.5, screen.size.height-60.0-iconWidth, iconWidth,iconWidth);    
    [moreInfo addTarget:self action:@selector(setShowInfo) forControlEvents:UIControlEventTouchUpInside];
    [moreInfo setImage:[UIImage imageNamed:@"more-info2"] forState:UIControlStateNormal];
    [moreInfo setImage:[UIImage imageNamed:@"less-info"] forState:UIControlStateSelected];
    
    [self.view addSubview:moreInfo];

    

    self.instructions=[[UIImageView alloc] init];
    [self setInstructionPosition];
    [self.instructions setAlpha:.98];
    [self.view addSubview:self.instructions];
    
    [self initW3wSDK];

    
}


- (void)initW3wSDK
{
    // Get w3w files
    NSString *masterFilePath = [[NSBundle mainBundle] pathForResource:@"w3w_master" ofType:@"dat"];
    NSString *yBucketsFilePath = [[NSBundle mainBundle] pathForResource:@"w3w_ybuckets" ofType:@"dat"];
    NSString *englishFilePath = [[NSBundle mainBundle] pathForResource:@"w3w_en_words" ofType:nil];
    
    // Setup sdk
    W3wSDKFactory *factory = [[W3wSDKFactory alloc] initWithMasterFilePath:masterFilePath
                                                          yBucketsFilePath:yBucketsFilePath
                                                       englishWordListPath:englishFilePath];
    [factory addEnglish];
    
    self.w3wSDK = [factory build];
}



#pragma mark - Instructions

-(void)nextInstruction:(int)n{
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"enable_mainInstructions"]==FALSE)return;
    
    int instructionN=(int)[[NSUserDefaults standardUserDefaults] integerForKey:@"mainInstructions"];
    if(n-1==instructionN){
        if(instructionN<6){//last instruction
            instructionN++;
            [[NSUserDefaults standardUserDefaults] setInteger:instructionN forKey:@"mainInstructions"];
            [self.instructions setImage:[UIImage imageNamed:[NSString stringWithFormat:@"Crowsflight_Instructions_006-%02i",instructionN]]];
            [self setInstructionPosition];
            [self.instructions setHidden:FALSE];
        }
        
        else{
            [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"mainInstructions"];
            [[NSUserDefaults standardUserDefaults] setBool:FALSE forKey:@"enable_mainInstructions"];
            [self.instructions setHidden:TRUE];
            
            NSLog(@"no more instructions");
            
        }
    }
}




-(void)setInstructionPosition{
    int instructionN=(int)[[NSUserDefaults standardUserDefaults] integerForKey:@"mainInstructions"];
    CGRect screen = [[UIScreen mainScreen] bounds];

    NSLog(@"instn %i",instructionN);
    if(instructionN==0) [self.instructions setFrame:CGRectMake(0,screen.size.height*.5+60, screen.size.width, screen.size.width)];
    
    else if(instructionN==4) [self.instructions setFrame:CGRectMake(0,screen.size.height*.15, screen.size.width, screen.size.width)];
    else if(instructionN==5) [self.instructions setFrame:CGRectMake(0, screen.size.height*.5-screen.size.width-50, screen.size.width, screen.size.width)];
    else if(instructionN==6) [self.instructions setFrame:CGRectMake(0, screen.size.height-60-50-screen.size.width, screen.size.width, screen.size.width)];
    else [self.instructions setFrame:CGRectMake(0, screen.size.height-screen.size.width-44, screen.size.width, screen.size.width)];
    

}









-(void)viewDidUnload{
    AudioServicesDisposeSystemSoundID(audioCreate);
}


-(void)viewWillAppear:(BOOL)animated{
    
    if( [[NSUserDefaults standardUserDefaults] integerForKey:@"currentDestinationN"]>= [dele.locationDictionaryArray count] ) {
        [[NSUserDefaults standardUserDefaults] setInteger:[dele.locationDictionaryArray count]-1 forKey:@"currentDestinationN"];
    }
    
    self.locationViewController.page=[[NSUserDefaults standardUserDefaults] integerForKey:@"currentDestinationN"];
    
    
    [self.pageView setViewControllers:@[self.locationViewController] direction:UIPageViewControllerNavigationDirectionForward  animated:NO completion:^(BOOL finished) {
        //code
    }
     ];
    
    //hide or unhide info
    self.showInfo=[[NSUserDefaults standardUserDefaults] boolForKey:@"showInfo"];
    //NSLog(@"read show info %i",self.showInfo);
    
    [moreInfo setSelected:self.showInfo];
    
    if(self.showInfo==FALSE) {
        [self.compassImage setAlpha: 0.0f];
        [self.compassImage setHidden:YES];
    }
    else {
        [self.compassImage setAlpha: 1.0f];
        [self.compassImage setHidden:NO];
        
    }
    
    
    //NSLog(@"locationViewController show %i",[[NSUserDefaults standardUserDefaults] integerForKey:@"currentDestinationN"]);
    

    
}

-(void)viewDidAppear:(BOOL)animated
{
    
    self.showMapBool=TRUE;
    self.showListBool=TRUE;

    [self checkGPS];
    

    
    
    //load instructions
    
    //if no default, set default to true
    if( [[NSUserDefaults standardUserDefaults] objectForKey:@"enable_mainInstructions"]==0 )[[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:@"enable_mainInstructions"];
    
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"enable_mainInstructions"]==TRUE){
        
        int instructionN=(int)[[NSUserDefaults standardUserDefaults] integerForKey:@"mainInstructions"];
        
        NSLog(@"show main instructions");
  
        [self.instructions setImage:[UIImage imageNamed:[NSString stringWithFormat:@"Crowsflight_Instructions_006-%02i",instructionN]]];
        [self.instructions setHidden:FALSE];
        
        if(instructionN==0){
            
            SIAlertView * instructionAlert= [[SIAlertView alloc] initWithTitle:@"WELCOME TO CROWSFLIGHT" andMessage:@"CAN WE SHOW YOU SOME OF CROWSFLIGHT'S FEATURES?"];
            //instructionAlert.containerHeight=210;
            

            
            [instructionAlert addButtonWithTitle:@"SKIP"
            type:SIAlertViewButtonTypeDefault
            handler:^(SIAlertView *alertView) {
                [[NSUserDefaults standardUserDefaults] setBool:FALSE forKey:@"enable_mainInstructions"];
                [[NSUserDefaults standardUserDefaults] setBool:FALSE forKey:@"enable_listInstructions"];
                [[NSUserDefaults standardUserDefaults] setBool:FALSE forKey:@"enable_mapInstructions"];
                [self.instructions setHidden:TRUE];
                

            }];

            [instructionAlert addButtonWithTitle:@"OK"
                                            type:SIAlertViewButtonTypeDefault
                                         handler:^(SIAlertView *alertView) {
                                             [self nextInstruction:1];
                                             
                                         }];


            instructionAlert.hideBackground=TRUE;
            //NSLog(@"%d",instructionAlert.hideBackground);

            
            instructionAlert.showTextField=FALSE;
            [instructionAlert show];
            
        }
        
    }else{
        [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"mainInstructions"];
        [self.instructions setHidden:TRUE];
        NSLog(@"hide main instructions");
    }
    
    
    
}


-(void)checkGPS{
    NSString *causeStr = nil;

    // check whether location services are enabled on the device
    if ([CLLocationManager locationServicesEnabled] == NO)
    {
        causeStr = @"device";
    }
    // check the application’s explicit authorization status:
    else if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied)
    {
        causeStr = @"app";
    }
    
    if (causeStr != nil)
    {
        NSString *alertMessage = [NSString stringWithFormat:@"You currently have location services disabled for this %@. Please refer to \"Settings\" app to turn on Location Services.", causeStr];
        
        UIAlertView *servicesDisabledAlert = [[UIAlertView alloc] initWithTitle:@"Location Services Disabled"
                                                                        message:alertMessage
                                                                       delegate:nil
                                                              cancelButtonTitle:@"OK"
                                                              otherButtonTitles:nil];
        [servicesDisabledAlert show];
        
        
    }
    

}

-(void)viewDidLayoutSubviews{
    //CGRect screen = [[UIScreen mainScreen] applicationFrame];
    //self.compassImage.center=CGPointMake(screen.size.width*.5, screen.size.height*.5+22);
    
}


-(void)updateViewControllersWithName{
    
    NSArray* viewC = [self.pageView viewControllers];
    cfLocationViewController2 * vc=[viewC objectAtIndex:0];

    [vc updateDestinationName];
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
    

    
    if(self.showListBool==TRUE){
        [self showList];
    }
    self.showListBool=FALSE;
    self.showMapBool=FALSE;
    


    
}

-(void)showList{
    //[[NSUbiquitousKeyValueStore defaultStore] synchronize];

    //[self.audioSelect1 play];

    //AudioServicesPlaySystemSound(audioSelect1);

    //create view
    self.listViewController = [[cwtListViewController alloc] init];
    [self.navigationController pushDrawerViewController:self.listViewController  withStyle:DrawerLayoutStyleLeftAnchored animated:YES];
    [self nextInstruction:4];

}


-(void)setShowInfo{
    
    self.showInfo=!self.showInfo;
    [[NSUserDefaults standardUserDefaults] setBool:self.showInfo forKey:@"showInfo"];
    NSLog(@"set show info %i",self.showInfo);
    
    
    if(self.showInfo){
        //[self.audioMore play];
        [self.compassImage setHidden:FALSE];
        [self.compassImage setAlpha: 0.0f];
        
    }else{
        
        //[self.audioLess play];

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
    
    [self nextInstruction:7];

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


//-(void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed
//{
//    
//    
//    if(finished){
//        NSArray* viewC = [self.pageView viewControllers];
//        cfLocationViewController2 * vc=[viewC lastObject];
//
//        [[NSUserDefaults standardUserDefaults] setInteger:vc.page forKey:@"currentDestinationN"];
//    }
//    
//}

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



#pragma mark - Add Location'
//coming from longpress
-(void)addLocation:(CLLocationCoordinate2D)coordinate title:(NSString *)name{
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"unlockcrowsflight"]==NO && [dele.locationDictionaryArray count]>=5){
		[self checkPurchased];
	}
    else
	{
        
//        if([name isEqual:@""] || name==NULL){
//            
//            [self addNewDestination:[NSString stringWithFormat:@"%f,%f",coordinate.latitude,coordinate.longitude] newlat:coordinate.latitude newlng:coordinate.longitude];
//        
//        }
//        else
            [self addNewDestination:name newlat:coordinate.latitude newlng:coordinate.longitude];

        
        //[dele.viewController showLocationEditAlert];
    }

}

-(void)pinCurrentLocation{
    
    //[self.audioSelect1 play];
    //AudioServicesPlaySystemSound(audioSelect1);

    
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
		NSLog(@"Saved destination. nDestinations: %i", (int)[dele.locationDictionaryArray count]);
        
        [dele loadmyLocations];
        
        
        [self flipToPage:[[NSUserDefaults standardUserDefaults] integerForKey:@"currentDestinationN"]];
    }
    [dele iCloudSync];
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
    if (self.localSearch.searching)
    {
        [self.localSearch cancel];
    }
    
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"unlockcrowsflight"]==NO && [dele.locationDictionaryArray count]>=5){
		[self checkPurchased];
	}
	else
    {
        BOOL isAddress=TRUE;
        NSMutableArray *slatlng = [[NSMutableArray alloc] init];
        [slatlng setArray:[searchField.text componentsSeparatedByString:@","]];
        
        
        
        //            3 words:
        //            /^\p{L}+\.\p{L}+\.\p{L}+$/u
        //
        //            OneWord
        //            /^\*[\p{L}\-0-9]{6,31}$/u
        
        //NSLog(@"match=%@", matches );
        NSMutableArray *threeWords = [[NSMutableArray alloc] init];
        [threeWords setArray:[searchField.text componentsSeparatedByString:@"."]];


        NSRegularExpression* oneWordRegex = [[NSRegularExpression alloc] initWithPattern:@"^\\*[\\p{L}\\-0-9]{6,31}" options:NSRegularExpressionCaseInsensitive error:nil];
        
        NSArray* oneWordMatches = [oneWordRegex matchesInString:searchField.text options:0 range:NSMakeRange(0, [searchField.text length])];
        
        NSRegularExpression* regex = [[NSRegularExpression alloc] initWithPattern:@"-?\\d+\\.\\d+" options:NSRegularExpressionCaseInsensitive error:nil];
        NSArray* matches = [regex matchesInString:searchField.text options:0 range:NSMakeRange(0, [searchField.text length])];
        
        //if([slatlng count]==2){
            //NSLog(@"parsing lat lng");
        if([matches count]==2)
        {
        NSString* slat = [slatlng objectAtIndex: 0];
        NSString* slng = [slatlng objectAtIndex: 1];
        

        //NSLog(@"match=%@", matches );
        
        
            AudioServicesPlaySystemSound(audioCreate);
            [self addNewDestination:searchField.text newlat:[slat doubleValue] newlng:[slng doubleValue] ];
            isAddress=FALSE;
        }
        //}
        else if([threeWords count]==3 )
        {
            isAddress=FALSE;

            W3wPosition *position = [self.w3wSDK convertW3WToPosition:threeWords];
            
            AudioServicesPlaySystemSound(audioCreate);
            CLLocationCoordinate2D coord;
            coord = CLLocationCoordinate2DMake(position.lat, position.lng);
            [dele.viewController addLocation:coord title:searchField.text];
            
        }
            else if([oneWordMatches count]==1)
            {
            
                isAddress=FALSE;

                //show progress
                NSString* mess=[NSString stringWithFormat:@"%@\n\n\n\n",searchField.text];
                SIAlertView * progressAlert = [ [SIAlertView alloc] initWithTitle: @"LOOKING UP..." andMessage:mess];
                progressAlert.showSpinner=TRUE;
                progressAlert.showTextField=FALSE;
                [progressAlert show];
                
                [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
            

                NSString *postString = [NSString stringWithFormat:@"key=%@&string=%@&corners=%i",@"9TQ1TY3J",searchField.text,false];
                //NSString *urlString = @"http://api.what3words.com/w3w";

                // Create the request.
                NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString: @"http://api.what3words.com/w3w"] ];
                
                // Specify that it will be a POST request
                request.HTTPMethod = @"POST";

                // Convert your data and set your request's HTTPBody property
                NSData *requestBodyData = [postString dataUsingEncoding:NSUTF8StringEncoding];
                request.HTTPBody = requestBodyData;
                
                
                //NSString *requestString = @"your url here";
                [NSURLConnection sendAsynchronousRequest:request
                                                   queue:[NSOperationQueue mainQueue]
                                       completionHandler:
                 ^(NSURLResponse *response, NSData *data, NSError *error) {
                   //  NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                     
                     //user forced cancel
                     if(progressAlert.visible==NO)return;
                     [progressAlert dismissAnimated:YES];
     
                     
                     //if (!error && httpResponse.statusCode >= 200 && httpResponse.statusCode <300) {
                     if (!error) {

                         //Error checking
                         
                         NSError *derror;
                         NSMutableDictionary *returnedDict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&derror];
                         
                         float lat=[[[returnedDict objectForKey:@"position"] objectAtIndex:0] floatValue];
                         float lng=[[[returnedDict objectForKey:@"position"] objectAtIndex:1] floatValue];
                         
 
                         if (derror != nil || (lat==0 && lng==0))
                         {
                             
                             NSString *errorMessage=@"NO RESULTS";
                             if(dele.hasInternet==FALSE){
                                 errorMessage=@"NO INTERNET CONNECTION";
                             }
                             SIAlertView* alert = [ [SIAlertView alloc] initWithTitle:errorMessage andMessage:@""];
                             [alert addButtonWithTitle:@"OK"
                                                  type:SIAlertViewButtonTypeDefault
                                               handler:^(SIAlertView *alertView) {
                                                   [self showList];
                                               }];
                             
                             alert.showTextField=FALSE;
                             [alert show];
                             
                         }
                         else
                         {
                             AudioServicesPlaySystemSound(audioCreate);

                             CLLocationCoordinate2D coord;
                             coord = CLLocationCoordinate2DMake(lat, lng);
                             [dele.viewController addLocation:coord title:searchField.text];
                             //[self.navigationController pushDrawerViewController:self.mapViewController  withStyle:DrawerLayoutStyleRightAnchored animated:YES];

                         }
    
                         [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

                         
                         
                     }
                     
        


                 }];
                
            
                
            }

        
        if(isAddress){
 
            // confine the map search area to the user's current location
            MKCoordinateRegion newRegion;
            newRegion.center.latitude = self.userLocation.latitude;
            newRegion.center.longitude = self.userLocation.longitude;
            newRegion.span.latitudeDelta = 0.112872;
            newRegion.span.longitudeDelta = 0.109863;
            //newRegion.span.latitudeDelta = 1;
            //newRegion.span.longitudeDelta = 1;
            MKLocalSearchRequest *request = [[MKLocalSearchRequest alloc] init];
            
            request.naturalLanguageQuery = searchField.text;
            request.region = newRegion;
            
            
            
            if (self.localSearch != nil)
            {
                self.localSearch = nil;
            }
            
            //show progress
            NSString* mess=[NSString stringWithFormat:@"%@\n\n\n\n",searchField.text];
            
            //progressAlert = [ [SIAlertView alloc] initWithTitle: @"SEARCHING FOR..." andMessage:mess ];
            SIAlertView * progressAlert = [ [SIAlertView alloc] initWithTitle: @"SEARCHING for..." andMessage:mess];
            
            progressAlert.showSpinner=TRUE;
            progressAlert.showTextField=FALSE;
            
            
            [progressAlert show];
            
            
            
            self.localSearch = [[MKLocalSearch alloc] initWithRequest:request];
            
            
            [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
            
            

            MKLocalSearchCompletionHandler completionHandler = ^(MKLocalSearchResponse *response, NSError *error)
            {
                
                //user forced cancel
                if(progressAlert.visible==NO)return;
                
                //Error checking
                [progressAlert dismissAnimated:YES];
                
                if (error != nil)
                {
                    
                    NSString *errorMessage=@"NO RESULTS";
                    if(dele.hasInternet==FALSE){
                        errorMessage=@"NO INTERNET CONNECTION";
                        
                    }
                    SIAlertView* alert = [ [SIAlertView alloc] initWithTitle:errorMessage andMessage:@""];
                    [alert addButtonWithTitle:@"OK"
                                         type:SIAlertViewButtonTypeDefault
                                      handler:^(SIAlertView *alertView) {
                                          [self showList];
                                      }];
                    
                    alert.showTextField=FALSE;
                    [alert show];

                }
                else
                {
                    self.places = [response mapItems];
                    self.boundingRegion = response.boundingRegion;

                    self.mapViewController.boundingRegion = self.boundingRegion;
                    self.mapViewController.mapItemList = self.places;
                    self.mapViewController->wasSearchView=true;

                    
                    [self.navigationController pushDrawerViewController:self.mapViewController  withStyle:DrawerLayoutStyleRightAnchored animated:YES];
    
                }
                [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            };
            
            [self.localSearch startWithCompletionHandler:completionHandler];

            
            
        }
    }
}






-(void)showLocationEditAlert{
    bool expired=false;
    
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"unlockcrowsflight"]==NO ){
        //expired=[dele. checkDate];
    }
    if(expired==false)
    {
        //load destination number
        int currentDestinationN=(int)[[NSUserDefaults standardUserDefaults] integerForKey:@"currentDestinationN"];
        
        //load dictionary
        NSMutableDictionary * dictionary = [dele.locationDictionaryArray objectAtIndex:currentDestinationN];
        NSString *st =[dictionary objectForKey:@"searchedText"];
        
        addLocAlert= [[SIAlertView alloc] initWithTitle:@"LOCATION NAME" andMessage:@"\n"];
        
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
    
    //[self.audioSelect1 play];
    //AudioServicesPlaySystemSound(audioSelect1);

    
    if(self.showMapBool==TRUE){

        
        self.mapViewController->wasSearchView=false;

        [self.navigationController pushDrawerViewController:self.mapViewController  withStyle:DrawerLayoutStyleRightAnchored animated:YES];
        [self nextInstruction:3];

    
    
    }
    
    
    //avoid doubleclick
    self.showMapBool=FALSE;
    self.showListBool=FALSE;

}




#pragma mark - Textfield

//textfield
- (void)textFieldDidEndEditing:(UITextField *)textField{
	NSLog(@"done editing");
    if(textField.tag==4) [addLocAlert cancelGeo];

}

-(void)textFieldDidBeginEditing:(UITextField *)textField{
    

}
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    NSLog(@"editing");

    if(textField.tag==4 && string.length>0) [addLocAlert cancelGeo];

    return TRUE;
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
        
        [self nextInstruction:5];

	}
    
    //hit done on keyboard after pin current location
    else if(textField.tag==4){
        AudioServicesPlaySystemSound(audioCreate);

        [self addNewDestination:textField.text newlat:dele.myLat newlng:dele.myLng];
        [addLocAlert dismissAnimated:YES];
        [self nextInstruction:2];

        
    }
    
    //hit done on keyboard
    else if(textField.tag==5){
        AudioServicesPlaySystemSound(audioCreate);

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

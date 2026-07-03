
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

//#import "cwtIAP.h"
#import <StoreKit/StoreKit.h>

#import "QuartzCore/CALayer.h"
#import "cwtToolbar.h"

#import "cwtMapViewController.h"

   

#define DEGREES_TO_RADIANS(angle) (angle / 180.0 * M_PI)





@interface cwtViewController3 ()<UIScrollViewDelegate, WCSessionDelegate>{
    //destination pager state: loaded page VCs by index, pages mid appearance-transition,
    //and the index the pager last snapped to (-1 before the first settle)
    NSMutableDictionary *loadedPages;
    NSMutableSet *appearingPages;
    NSInteger settledPage;
}

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
    
    dele = (cwtAppDelegate*)[[UIApplication sharedApplication] delegate];
    
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
    
    
    
    //destination pager: a plain paging scroll view, so pages track the finger and snap.
    //(replaced UIPageViewController: its private queuing scroll view swallows touches that
    //land on non-UIControl page content - the full-screen arrow, the arc, labels - so
    //neither its own native scroll nor any external recogniser could ever cover the whole
    //screen. a vanilla scroll view has standard touch routing: dragging works over any
    //page content and the in-page buttons receive their taps natively.)
    loadedPages = [NSMutableDictionary dictionary];
    appearingPages = [NSMutableSet set];
    settledPage = -1;
    self.pagerScroll = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    //paging is done manually (fast deceleration + snap in scrollViewWillEndDragging:)
    //rather than pagingEnabled=YES: modern UIKit gates a paging scroll view's pan behind
    //a private swipe recogniser, which adds a swipe-vs-drag mode split; manual snapping
    //gives the classic one-page-at-a-time feel and tracks the finger the whole way.
    self.pagerScroll.pagingEnabled = NO;
    self.pagerScroll.decelerationRate = UIScrollViewDecelerationRateFast;
    self.pagerScroll.showsHorizontalScrollIndicator = NO;
    self.pagerScroll.showsVerticalScrollIndicator = NO;
    self.pagerScroll.alwaysBounceHorizontal = YES;
    self.pagerScroll.alwaysBounceVertical = NO;
    self.pagerScroll.directionalLockEnabled = YES;
    self.pagerScroll.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    self.pagerScroll.delegate = self;
    [self.view addSubview:self.pagerScroll];


    
    [[SIAlertView appearance] setMessageFont:[UIFont systemFontOfSize:13]];
    [[SIAlertView appearance] setCornerRadius:0];
    [[SIAlertView appearance] setShadowRadius:20];
    
    
    
    
    //custom toolbar. final position/height is set in viewDidLayoutSubviews once the
    //safe-area insets are known, so it clears the home indicator on every notched phone
    //(the old code only special-cased the original iPhone X by its exact pixel height).
    UIView* buttonBar=[[UIView alloc ]initWithFrame:CGRectMake(0, screen.size.height-55, screen.size.width, 55)];
    cfButtonBar = buttonBar;


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
    moreInfo.frame=CGRectMake(screen.size.width*.5-iconWidth*.5, screen.size.height-80.0-iconWidth, iconWidth,iconWidth);    
    [moreInfo addTarget:self action:@selector(setShowInfo) forControlEvents:UIControlEventTouchUpInside];
    [moreInfo setImage:[UIImage imageNamed:@"more-info2"] forState:UIControlStateNormal];
    [moreInfo setImage:[UIImage imageNamed:@"less-info"] forState:UIControlStateSelected];
    
    [self.view addSubview:moreInfo];

    

    self.instructions=[[UIImageView alloc] init];
    [self setInstructionPosition];
    [self.instructions setAlpha:.98];
    [self.view addSubview:self.instructions];
    
    //[self initW3wSDK];
    
    if ([WCSession isSupported]) {
    WCSession *session = [WCSession defaultSession];
    session.delegate = self;

    [session activateSession];
    }


}


//- (void)initW3wSDK
//{
//    // Get w3w files
//    NSString *masterFilePath = [[NSBundle mainBundle] pathForResource:@"w3w_master" ofType:@"dat"];
//    NSString *yBucketsFilePath = [[NSBundle mainBundle] pathForResource:@"w3w_ybuckets" ofType:@"dat"];
//    NSString *englishFilePath = [[NSBundle mainBundle] pathForResource:@"w3w_en_words" ofType:nil];
//
//    // Setup sdk
//    W3wSDKFactory *factory = [[W3wSDKFactory alloc] initWithMasterFilePath:masterFilePath
//                                                          yBucketsFilePath:yBucketsFilePath
//                                                       englishWordListPath:englishFilePath];
//    [factory addEnglish];
//
//    self.w3wSDK = [factory build];
//}



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






-(void)transferSettings{

    //long n = [[NSUserDefaults standardUserDefaults] integerForKey:@"currentDestinationN"];
    
    NSMutableDictionary *settings = [NSMutableDictionary dictionary];
    //[settings setObject: n  forKey: @"targetIndex"];

    
    [[WCSession defaultSession] transferUserInfo:settings];
}

//WCSessionDelegate required methods
- (void)session:(WCSession *)session activationDidCompleteWithState:(WCSessionActivationState)activationState error:(NSError *)error{
}
- (void)sessionDidBecomeInactive:(WCSession *)session{
}
- (void)sessionDidDeactivate:(WCSession *)session{
}


// was viewDidUnload (deprecated/never called on modern iOS); dispose sound on dealloc instead
-(void)dealloc{
    AudioServicesDisposeSystemSoundID(audioCreate);
}


-(void)viewWillAppear:(BOOL)animated{

    if( [[NSUserDefaults standardUserDefaults] integerForKey:@"currentDestinationN"]>= [dele.locationDictionaryArray count] ) {

        [[NSUserDefaults standardUserDefaults] setInteger:[dele.locationDictionaryArray count]-1 forKey:@"currentDestinationN"];
    }

    //rebuild the pager on every appearance: destinations may have been added, removed,
    //renamed or reordered in the list/map drawers while this view was covered
    [self reloadPagerShowingPage:[[NSUserDefaults standardUserDefaults] integerForKey:@"currentDestinationN"]];

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
    else if ([[[CLLocationManager alloc] init] authorizationStatus] == kCLAuthorizationStatusDenied)
    {
        causeStr = @"app";
    }
    
    if (causeStr != nil)
    {
        NSString *alertMessage = [NSString stringWithFormat:@"You currently have location services disabled for this %@. Please refer to \"Settings\" app to turn on Location Services.", causeStr];
        

        UIAlertController* servicesDisabledAlert = [UIAlertController
                                alertControllerWithTitle:@"No Location"
                                message:alertMessage
                                preferredStyle:UIAlertControllerStyleAlert];

//        UIAlertAction* yesButton = [UIAlertAction
//                                    actionWithTitle:@"Yes, please"
//                                    style:UIAlertActionStyleDefault
//                                    handler:^(UIAlertAction * action) {
//                                        //Handle your yes please button action here
//                                    }];
        
        UIAlertAction* noButton = [UIAlertAction
                                   actionWithTitle:@"OK"
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction * action) {
            //Handle no, thanks button
//            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
//
            NSURL *URL =[NSURL URLWithString:UIApplicationOpenSettingsURLString];
            
            [[UIApplication sharedApplication] openURL:URL options:@{} completionHandler:^(BOOL success) {
                if (success) {
                    NSLog(@"Opened url");
                }
            }];
            
        }];
        //[servicesDisabledAlert addAction:yesButton];
        [servicesDisabledAlert addAction:noButton];
        
        
        [self presentViewController:servicesDisabledAlert animated:YES completion:nil];

        
        
    }
    

}

-(void)viewDidLayoutSubviews{
    //CGRect screen = [[UIScreen mainScreen] applicationFrame];
    //self.compassImage.center=CGPointMake(screen.size.width*.5, screen.size.height*.5+22);

    //keep the toolbar and more-info button clear of the home indicator on notched phones.
    //the buttons sit at the top of the bar, so lifting the bar by the bottom safe-area inset
    //moves them above the indicator while the bar's background still fills to the screen edge.
    CGFloat safeBottom = self.view.safeAreaInsets.bottom;
    CGFloat w = self.view.bounds.size.width;
    CGFloat h = self.view.bounds.size.height;

    CGFloat barH = 55 + safeBottom;
    cfButtonBar.frame = CGRectMake(0, h - barH, w, barH);
    cfButtonBar.layer.shadowPath = [UIBezierPath bezierPathWithRect:cfButtonBar.bounds].CGPath;

    CGRect mi = moreInfo.frame;
    moreInfo.frame = CGRectMake(mi.origin.x, h - 80.0 - mi.size.height - safeBottom, mi.size.width, mi.size.height);

    //keep the pager and its loaded pages in step with the root view's size
    if (!CGRectEqualToRect(self.pagerScroll.frame, self.view.bounds)) {
        self.pagerScroll.frame = self.view.bounds;
        [self updatePagerContentSize];
        for (NSNumber *key in loadedPages) {
            [self loadPage:key.integerValue]; //re-applies the page frame
        }
        if (settledPage >= 0) {
            self.pagerScroll.contentOffset = CGPointMake(settledPage * self.pagerScroll.bounds.size.width, 0);
        }
    }
}


//live location/heading ticks from the app delegate: feed every loaded page (current +
//preloaded neighbours, three at most) so a half-dragged page is never stale
-(void)updateViewControllersWithName{
    for (cfLocationViewController2 *vc in [loadedPages allValues]) {
        [vc updateDestinationName];
    }
}


-(void)updateViewControllersWithLatLng: (int)_page{
    for (cfLocationViewController2 *vc in [loadedPages allValues]) {
        [vc updateDistanceWithLatLng:.3];
    }
}


-(void)updateViewControllersWithHeading: (int)_page{
    for (cfLocationViewController2 *vc in [loadedPages allValues]) {
        [vc updateHeading];
    }
    [self rotateCompass:.1 degrees:-dele.heading];
    //NSLog(@"dele.heading: %f", dele.heading);

}


- (void)rotateCompass:(NSTimeInterval)duration  degrees:(CGFloat)degrees
{
    
    CGAffineTransform transformCompass = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(degrees));
    
    [UIView animateWithDuration:0.0f
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
    
    for (cfLocationViewController2 *vc in [loadedPages allValues]) {
        [vc showHideInfo:.3f];
    }

    [self nextInstruction:7];

    //NSLog(@"switch showinfo");
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Destination pager

//child page appearance (viewWillAppear -> loadLocation/arrow unhide, viewDidAppear ->
//persist currentDestinationN) is driven manually below, tied to drags and snaps
- (BOOL)shouldAutomaticallyForwardAppearanceMethods {
    return NO;
}

//create (or retrieve) the page for a destination index and place it in the scroll view
- (cfLocationViewController2 *)loadPage:(NSInteger)index {
    if (index < 0 || index >= (NSInteger)[dele.locationDictionaryArray count]) return nil;

    cfLocationViewController2 *vc = loadedPages[@(index)];
    CGFloat w = self.pagerScroll.bounds.size.width;
    CGFloat h = self.pagerScroll.bounds.size.height;
    if (vc == nil) {
        vc = [[cfLocationViewController2 alloc] init];
        vc.page = index;
        [self addChildViewController:vc];
        vc.view.frame = CGRectMake(index * w, 0, w, h);
        //clip each page so the oversized arrow doesn't bleed across neighbours mid-drag
        //(page bounds == screen, so a settled page looks exactly as before)
        vc.view.clipsToBounds = YES;
        [self.pagerScroll addSubview:vc.view];
        [vc didMoveToParentViewController:self];
        loadedPages[@(index)] = vc;
    } else {
        vc.view.frame = CGRectMake(index * w, 0, w, h);
    }
    return vc;
}

- (void)updatePagerContentSize {
    CGFloat w = self.pagerScroll.bounds.size.width;
    CGFloat h = self.pagerScroll.bounds.size.height;
    NSInteger n = (NSInteger)[dele.locationDictionaryArray count];
    self.pagerScroll.contentSize = CGSizeMake(w * MAX(n, 1), h);
}

- (void)removeAllPages {
    for (cfLocationViewController2 *vc in [loadedPages allValues]) {
        [vc willMoveToParentViewController:nil];
        [vc.view removeFromSuperview];
        [vc removeFromParentViewController];
    }
    [loadedPages removeAllObjects];
    [appearingPages removeAllObjects];
}

//drop pages more than one step from the settled one; three stay loaded at most
- (void)unloadDistantPages {
    for (NSNumber *key in [loadedPages allKeys]) {
        if (labs(key.integerValue - settledPage) > 1) {
            cfLocationViewController2 *vc = loadedPages[key];
            [vc willMoveToParentViewController:nil];
            [vc.view removeFromSuperview];
            [vc removeFromParentViewController];
            [loadedPages removeObjectForKey:key];
        }
    }
}

//the pager came to rest on a page: finish its appearance (persists currentDestinationN,
//fades the arrow in), retire the previous page, cancel any page that was dragged
//partway in but abandoned
- (void)settleOnPage:(NSInteger)index {
    NSInteger n = (NSInteger)[dele.locationDictionaryArray count];
    if (n <= 0) return;
    if (index < 0) index = 0;
    if (index >= n) index = n - 1;

    cfLocationViewController2 *old = (settledPage >= 0) ? loadedPages[@(settledPage)] : nil;
    cfLocationViewController2 *incoming = [self loadPage:index];
    if (incoming == nil) return;

    if ([appearingPages containsObject:incoming]) {
        [incoming endAppearanceTransition];
        [appearingPages removeObject:incoming];
    } else if (incoming != old) {
        [incoming beginAppearanceTransition:YES animated:NO];
        [incoming endAppearanceTransition];
    }

    if (old != nil && old != incoming) {
        [old beginAppearanceTransition:NO animated:NO];
        [old endAppearanceTransition];
    }

    for (cfLocationViewController2 *vc in [appearingPages copy]) {
        if (vc == incoming) continue;
        [vc beginAppearanceTransition:NO animated:NO];
        [vc endAppearanceTransition];
        [appearingPages removeObject:vc];
    }

    settledPage = index;
    self.locationViewController = incoming;
    [self unloadDistantPages];
}

//tear down and rebuild at the given page without animation (data may have changed)
- (void)reloadPagerShowingPage:(NSInteger)index {
    [self removeAllPages];
    settledPage = -1;
    [self updatePagerContentSize];

    NSInteger n = (NSInteger)[dele.locationDictionaryArray count];
    if (n <= 0) {
        self.locationViewController = nil;
        return;
    }
    if (index < 0) index = 0;
    if (index >= n) index = n - 1;

    self.pagerScroll.contentOffset = CGPointMake(index * self.pagerScroll.bounds.size.width, 0);
    [self settleOnPage:index];
}

#pragma mark - Pager scroll delegate

//while dragging (or during a snap animation), make sure both visible pages exist and
//have begun appearing, so the incoming page shows live data mid-drag
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView != self.pagerScroll) return;
    CGFloat w = scrollView.bounds.size.width;
    if (w <= 0) return;

    NSInteger n = (NSInteger)[dele.locationDictionaryArray count];
    NSInteger first = (NSInteger)floor(scrollView.contentOffset.x / w);
    cfLocationViewController2 *settled = (settledPage >= 0) ? loadedPages[@(settledPage)] : nil;

    for (NSInteger index = first; index <= first + 1; index++) {
        if (index < 0 || index >= n) continue;
        cfLocationViewController2 *vc = [self loadPage:index];
        if (vc != nil && vc != settled && ![appearingPages containsObject:vc]) {
            [vc beginAppearanceTransition:YES animated:YES];
            [appearingPages addObject:vc];
        }
    }
}

//snap the release point to a page boundary, one page at a time like a native pager
- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    if (scrollView != self.pagerScroll) return;
    CGFloat w = scrollView.bounds.size.width;
    if (w <= 0) return;
    NSInteger n = (NSInteger)[dele.locationDictionaryArray count];

    NSInteger target;
    if (velocity.x > 0.3) {
        target = (NSInteger)floor(scrollView.contentOffset.x / w) + 1;   //flick left -> next
    } else if (velocity.x < -0.3) {
        target = (NSInteger)ceil(scrollView.contentOffset.x / w) - 1;    //flick right -> previous
    } else {
        target = (NSInteger)round(targetContentOffset->x / w);           //slow release -> nearest
    }
    //never skip pages in one gesture, and stay in range
    if (settledPage >= 0) {
        if (target > settledPage + 1) target = settledPage + 1;
        if (target < settledPage - 1) target = settledPage - 1;
    }
    if (target < 0) target = 0;
    if (target >= n) target = n - 1;
    targetContentOffset->x = target * w;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (scrollView == self.pagerScroll) [self settleOnCurrentPage];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    if (scrollView == self.pagerScroll) [self settleOnCurrentPage];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (scrollView == self.pagerScroll && !decelerate) [self settleOnCurrentPage];
}

- (void)settleOnCurrentPage {
    CGFloat w = self.pagerScroll.bounds.size.width;
    if (w <= 0) return;
    [self settleOnPage:(NSInteger)round(self.pagerScroll.contentOffset.x / w)];
}



#pragma mark - Add Location'
//coming from longpress
-(void)addLocation:(CLLocationCoordinate2D)coordinate title:(NSString *)name{
//    if([[NSUserDefaults standardUserDefaults] boolForKey:@"unlockcrowsflight"]==NO && [dele.locationDictionaryArray count]>=5){
//        [self checkPurchased];
//    }
//    else
//    {
    
//        if([name isEqual:@""] || name==NULL){
//            
//            [self addNewDestination:[NSString stringWithFormat:@"%f,%f",coordinate.latitude,coordinate.longitude] newlat:coordinate.latitude newlng:coordinate.longitude];
//        
//        }
//        else
            [self addNewDestination:name newlat:coordinate.latitude newlng:coordinate.longitude];

        
        //[dele.viewController showLocationEditAlert];
 //   }

}

-(void)pinCurrentLocation{
    
    //[self.audioSelect1 play];
    //AudioServicesPlaySystemSound(audioSelect1);

    
//    if([[NSUserDefaults standardUserDefaults] boolForKey:@"unlockcrowsflight"]==NO && [dele.locationDictionaryArray count]>=5){
//        [self checkPurchased];
//    }
//    else
//    {
//
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
  //  }
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


//programmatic flip (destination list, post-save, iCloud sync). the destination count
//may have changed since the pager was last built, so the content size is refreshed and
//a distant target starts its slide from the neighbouring index, reading as one page flip
-(void) flipToPage:(NSInteger)x {

    NSInteger n = (NSInteger)[dele.locationDictionaryArray count];
    [self updatePagerContentSize];
    if (n <= 0) {
        [self removeAllPages];
        settledPage = -1;
        self.locationViewController = nil;
        return;
    }
    if (x < 0) x = 0;
    if (x >= n) x = n - 1;

    CGFloat w = self.pagerScroll.bounds.size.width;

    //already there: rebuild in place, the data behind the index may have changed
    if (settledPage == x) {
        [self reloadPagerShowingPage:x];
        return;
    }

    //jumping further than a neighbour: hop next to the target without animation first
    if (settledPage < 0 || labs(x - settledPage) > 1) {
        NSInteger hop = (settledPage >= 0 && x < settledPage) ? x + 1 : x - 1;
        if (hop < 0 || hop >= n) {
            [self reloadPagerShowingPage:x];
            return;
        }
        [self removeAllPages];
        settledPage = -1;
        [self loadPage:hop];
        self.pagerScroll.contentOffset = CGPointMake(hop * w, 0);
    }

    [self loadPage:x];
    [self.pagerScroll setContentOffset:CGPointMake(x * w, 0) animated:YES];
    //settleOnPage: fires from scrollViewDidEndScrollingAnimation
}


#pragma mark - Search
- (IBAction)showSearch:(id)sender{
    [self showSearchBar];
    
}

-(void) showSearchBar{
    
//    if([[NSUserDefaults standardUserDefaults] boolForKey:@"unlockcrowsflight"]==NO && [dele.locationDictionaryArray count]>=5){
//        [self checkPurchased];
//    }
//    else
//    {
//
        searchAlert= [[SIAlertView alloc] initWithTitle:@"SEARCH" andMessage:@"Enter an address, placename, or lat,lng \n(e.g. 40.729,-73.993)"];
        //        [searchAlert addButtonWithTitle:@"X"
        //                                   type:SIAlertViewButtonTypeCancel
        //                                handler:^(SIAlertView *alertView) {
        //                                    NSLog(@"x");
        //                                }];

        searchAlert.showTextField=TRUE;
        searchAlert.textFieldTag=0;
        searchAlert.keyboardGo=@"SEARCH";
    
    //searchAlert.titleColor=UIColor.blackColor;
    searchAlert.textField.textColor=  [UIColor colorWithWhite:.1 alpha:1];

    
        [searchAlert show];
        
//	}
    
}



-(void)searchGeo:(UITextField*)searchField{
	//check if it's a lat lng
    
    //save search value
    //[[NSUserDefaults standardUserDefaults] setObject:searchField.text forKey:@"lastSearchText"];
    if (self.localSearch.searching)
    {
        [self.localSearch cancel];
    }
    
//    if([[NSUserDefaults standardUserDefaults] boolForKey:@"unlockcrowsflight"]==NO && [dele.locationDictionaryArray count]>=5){
//        [self checkPurchased];
//    }
//    else
//    {
        BOOL isAddress=TRUE;
        NSMutableArray *slatlng = [[NSMutableArray alloc] init];
        [slatlng setArray:[searchField.text componentsSeparatedByString:@","]];
        
        
        
        //            3 words:
        //            /^\p{L}+\.\p{L}+\.\p{L}+$/u
        //
        //            OneWord
        //            /^\*[\p{L}\-0-9]{6,31}$/u
        
        //NSLog(@"match=%@", matches );
//        NSMutableArray *threeWords = [[NSMutableArray alloc] init];
//        [threeWords setArray:[[searchField.text lowercaseString] componentsSeparatedByString:@"."]];


//        NSRegularExpression* oneWordRegex = [[NSRegularExpression alloc] initWithPattern:@"^\\*[\\p{L}\\-0-9]{6,31}" options:NSRegularExpressionCaseInsensitive error:nil];
//        
//        NSArray* oneWordMatches = [oneWordRegex matchesInString:searchField.text options:0 range:NSMakeRange(0, [searchField.text length])];
//        
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
//        else if([threeWords count]==3 )
//        {
//            isAddress=FALSE;
//
//            //W3wPosition *position = [self.w3wSDK convertW3WToPosition:threeWords];
//
////            if (position==nil)
////            {
////
////                NSString *errorMessage=@"NO RESULTS";
////                SIAlertView* alert = [ [SIAlertView alloc] initWithTitle:errorMessage andMessage:@""];
////                [alert addButtonWithTitle:@"OK"
////                                     type:SIAlertViewButtonTypeDefault
////                                  handler:^(SIAlertView *alertView) {
////                                      [self showList];
////                                  }];
////
////                alert.showTextField=FALSE;
////                [alert show];
////
////            }else{
//            
//                AudioServicesPlaySystemSound(audioCreate);
//                CLLocationCoordinate2D coord;
//                coord = CLLocationCoordinate2DMake(position.lat, position.lng);
//                [dele.viewController addLocation:coord title:searchField.text];
//                
//            //}
//            
//            
//            
//            
//        }
       //     else if([oneWordMatches count]==1)
//            {
//
//                isAddress=FALSE;
//
//                //show progress
//                NSString* mess=[NSString stringWithFormat:@"%@\n\n\n\n",searchField.text];
//                SIAlertView * progressAlert = [ [SIAlertView alloc] initWithTitle: @"LOOKING UP..." andMessage:mess];
//                progressAlert.showSpinner=TRUE;
//                progressAlert.showTextField=FALSE;
//                [progressAlert show];
//
//                [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
//
//
//                NSString *postString = [NSString stringWithFormat:@"key=%@&string=%@&corners=%i",@"9TQ1TY3J",searchField.text,false];
//                //NSString *urlString = @"http://api.what3words.com/w3w";
//
//                // Create the request.
//                NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString: @"http://api.what3words.com/w3w"] ];
//
//                // Specify that it will be a POST request
//                request.HTTPMethod = @"POST";
//
//                // Convert your data and set your request's HTTPBody property
//                NSData *requestBodyData = [postString dataUsingEncoding:NSUTF8StringEncoding];
//                request.HTTPBody = requestBodyData;
//
//
//                //NSString *requestString = @"your url here";
//
//                NSURLSession *session = [NSURLSession sharedSession];
//                [[session dataTaskWithURL:[NSURL URLWithString:londonWeatherUrl]
//                        completionHandler:^(NSData *data,
//                                            NSURLResponse *response,
//                                            NSError *error) {
//                            // handle response
//
//                        }] resume];
//
//
//
//
//
//                [NSURLConnection sendAsynchronousRequest:request
//                                                   queue:[NSOperationQueue mainQueue]
//                                       completionHandler:
//                 ^(NSURLResponse *response, NSData *data, NSError *error) {
//                   //  NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
//
//                     //user forced cancel
//                     if(progressAlert.visible==NO)return;
//                     [progressAlert dismissAnimated:YES];
//
//
//                     //if (!error && httpResponse.statusCode >= 200 && httpResponse.statusCode <300) {
//                     if (!error) {
//
//                         //Error checking
//
//                         NSError *derror;
//                         NSMutableDictionary *returnedDict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&derror];
//
//                         float lat=[[[returnedDict objectForKey:@"position"] objectAtIndex:0] floatValue];
//                         float lng=[[[returnedDict objectForKey:@"position"] objectAtIndex:1] floatValue];
//
//
//                         if (derror != nil || (lat==0 && lng==0))
//                         {
//
//                             NSString *errorMessage=@"NO RESULTS";
//                             if(dele.hasInternet==FALSE){
//                                 errorMessage=@"NO INTERNET CONNECTION";
//                             }
//                             SIAlertView* alert = [ [SIAlertView alloc] initWithTitle:errorMessage andMessage:@""];
//                             [alert addButtonWithTitle:@"OK"
//                                                  type:SIAlertViewButtonTypeDefault
//                                               handler:^(SIAlertView *alertView) {
//                                                   [self showList];
//                                               }];
//
//                             alert.showTextField=FALSE;
//                             [alert show];
//
//                         }
//                         else
//                         {
//                             AudioServicesPlaySystemSound(audioCreate);
//
//                             CLLocationCoordinate2D coord;
//                             coord = CLLocationCoordinate2DMake(lat, lng);
//                             [dele.viewController addLocation:coord title:searchField.text];
//                             //[self.navigationController pushDrawerViewController:self.mapViewController  withStyle:DrawerLayoutStyleRightAnchored animated:YES];
//
//                         }
//
//                         [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
//
//
//
//                     }
//
//
//
//
//                 }];
//
//
//
//            }

        
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



            MKLocalSearchCompletionHandler completionHandler = ^(MKLocalSearchResponse *response, NSError *error)
            {
                
                //user forced cancel
                if(progressAlert.visible==NO)return;
                
                //Error checking
                [progressAlert dismissAnimated:YES];
                
                if (error != nil)
                {
                    
                    NSString *errorMessage=@"NO RESULTS";
                    if(self->dele.hasInternet==FALSE){
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
            };
            
            [self.localSearch startWithCompletionHandler:completionHandler];

            
            
        }
    //}
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
        
        //addLocAlert.textField.textColor=UIColor.blackColor;
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
        
//        UIAlertView *alert =  [[UIAlertView alloc] initWithTitle:@"An error occurred."
//                                                         message:message
//                                                        delegate:nil
//                                               cancelButtonTitle:@"OK"
//                                               otherButtonTitles:nil];;
//        [alert show];
        
        

        
        
        UIAlertController* alert = [UIAlertController
                                                    alertControllerWithTitle:@"Error"
                                                    message:@"An error occured"
                                                    preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* noButton = [UIAlertAction
                                   actionWithTitle:@"OK"
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction * action) {
                                       //Handle no, thanks button
                                   }];
        [alert addAction:noButton];
        
        [self presentViewController:alert animated:YES completion:nil];
        
        
        
        
        
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







#pragma mark - inapp
//-(void)purchase{
//    [[cwtIAP sharedInstance] requestProductsWithCompletionHandler:^(BOOL success, NSArray *products) {
//        if (success) {
//            
//            //NSLog(@"%i",products.count);
//            if(products.count>0){
//                SKProduct * product = (SKProduct *) products[0];
//                NSLog(@"%@",product.localizedTitle);
//                [[cwtIAP sharedInstance]  buyProduct:product];
//                
//            }
//            
//        }
//    }];
//    
//}
//-(void)checkPurchased{
//    if([[NSUserDefaults standardUserDefaults] boolForKey:@"unlockcrowsflight"]==NO )
//    {
//        //purchased=true;
//        inappAlert = [[UIAlertView alloc] initWithTitle:@"Unlock Crowsflight" message:@"You are currently limited to saving 5 locations. By unlocking the app, you'll be able to save unlimited locations and help us continue working on this app. If you've already paid for an unlock on any iOS device, unlocking again is free. <3 CW&T" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
//        [inappAlert addButtonWithTitle:@"Unlock"];
//        inappAlert.tag=6;
//        [inappAlert show];
//    }
//}

@end

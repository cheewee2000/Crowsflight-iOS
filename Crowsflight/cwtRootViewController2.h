//
//  cwtViewController.h
//  Crowsflight
//
//  Created by Che-Wei Wang on 5/4/13.
//  Copyright (c) 2013 CW&T. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "cfLocationViewController2.h"
#import <MapKit/MapKit.h>
#import "cwtListViewController.h"
#import "UINavigationController+GZDrawer.h"
#import "cwtAppDelegate.h"
#import "SIAlertView.h"
#import "cwtToolBar.h"


@interface cwtRootViewController2 : UIViewController <UITextFieldDelegate>{
    
    
    SIAlertView *searchAlert;
    SIAlertView *addLocAlert;
    UIAlertView *inappAlert;
    SIAlertView* progressAlert;
    
    cwtAppDelegate* dele;
    UIButton *moreInfo;
}
-(void)updateViewControllersWithName;
-(void)updateViewControllersWithLatLng: (int)_page;
-(void)updateViewControllersWithHeading: (int)_page;
-(void)showLocationEditAlert;
-(void) flipToPage:(NSInteger)x;


@property (nonatomic,strong) UIPageViewController *pageView;
@property (nonatomic,strong) cfLocationViewController2* locationViewController;
@property (nonatomic,strong) cwtListViewController * listViewController;

@property (nonatomic,strong)  cwtToolbar *toolBar;

-(IBAction) openListView:(id)sender;
-(IBAction) addLocation:(id)sender;
-(IBAction) showSearch:(id)sender;
-(void)searchGeo:(UITextField*)searchField;

//@property(nonatomic, strong, readonly) UISearchBar *searchBar;

@property (nonatomic,strong) IBOutlet UIImageView *compassImage;
@property (nonatomic,strong) IBOutlet UIImageView *compassN;
@property (nonatomic,assign) BOOL showInfo;

-(void)checkPurchased;
-(void)purchase;


@end


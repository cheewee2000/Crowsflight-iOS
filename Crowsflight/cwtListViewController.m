//
//  cwtListViewController.m
//  Crowsflight
//
//  Created by Che-Wei Wang on 5/26/13.
//  Copyright (c) 2013 CW&T. All rights reserved.
//

#import "cwtAppDelegate.h"
#import "cwtListViewController.h"
#import "cwtUITableViewController.h"

@interface cwtListViewController ()

@end

@implementation cwtListViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

        self.view.frame=CFScreenBounds();

    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    // Custom initialization
    cwtUITableViewController * tableViewController = [[cwtUITableViewController alloc] initWithStyle:UITableViewStylePlain];
    
    [self addChildViewController:tableViewController];
    //sized explicitly in viewDidLayoutSubviews; autoresizing would squash it first whenever
    //this view is loaded at a stale size and then corrected
    tableViewController.view.autoresizingMask = UIViewAutoresizingNone;
    [self.view addSubview:tableViewController.view];

}


//- (IBAction)back:(UIButton *)sender {
//    cwtAppDelegate* dele = [[UIApplication sharedApplication] delegate];
//    int currentDestinationN=[[NSUserDefaults standardUserDefaults] integerForKey:@"currentDestinationN"];
//
//    dele.viewController.locationViewController.page=currentDestinationN;
//    //dele.viewController.locationViewController.page=currentDestinationN;
//
//    [self dismissModalViewControllerAnimated:YES];
//    [self.navigationController popToRootViewControllerAnimated:YES];
//}

//the table is the drawer minus the strip of compass left showing. size it from the
//live view rather than trusting the size it was created at (the window resizes when an
//iPhone Duo folds/unfolds, and the screen it reports can lag behind)
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.childViewControllers.firstObject.view.frame = CGRectMake(0, 0, CFListWidth(), self.view.bounds.size.height);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

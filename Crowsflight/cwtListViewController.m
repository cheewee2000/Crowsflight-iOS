//
//  cwtListViewController.m
//  Crowsflight
//
//  Created by Che-Wei Wang on 5/26/13.
//  Copyright (c) 2013 CW&T. All rights reserved.
//

#import "cwtListViewController.h"
#import "cwtUITableViewController.h"

@interface cwtListViewController ()

@end

@implementation cwtListViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

        self.view.frame=[[UIScreen mainScreen] bounds];

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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

//
//  cwtUITableViewController.h
//  Crowsflight
//
//  Created by Che-Wei Wang on 5/5/13.
//  Copyright (c) 2013 CW&T. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "cwtTableViewCell.h"
#import "cwtAppDelegate.h"
#import "LRSlidingTableViewCell.h"

#import "ATSDragToReorderTableViewController.h"
//#import <AudioToolbox/AudioToolbox.h>


@interface cwtUITableViewController : ATSDragToReorderTableViewController<UITextFieldDelegate>
{
    cwtAppDelegate* dele ;
    //NSInteger nCells;
    //NSMutableArray *arrayOfItems;
    BOOL _searchBarMayResign;
    //SystemSoundID audioSelect3;
    UIImageView* walkAnimView;
    UIImageView*  doorAnimView;
    UIImageView* doorBackground;
    
}



@property (nonatomic, retain) IBOutlet UITableViewCell *cell;
//@property (nonatomic, retain) IBOutlet cwtTableViewCell *cell;

@property (nonatomic, retain) LRSlidingTableViewCell *currentlyActiveSlidingCell;
@property (nonatomic, retain) IBOutlet UISegmentedControl *swipeDirectionSegmentedControl;
@property (nonatomic, assign) LRSlidingTableViewCellSwipeDirection swipeDirection;

//- (IBAction)handleSegmentedControlSelection:(id)sender;



//search
@property (strong, nonatomic) UITextField * filterBar;
@property (strong, nonatomic) NSMutableArray* filteredTableData;
@property (strong, nonatomic) NSMutableArray* unfilteredCellRow;

@property (nonatomic, assign) BOOL isFiltered;
-(void)doFilter;

@property (nonatomic, strong) UIImageView  *instructions;
-(void)nextInstruction:(int)n;


@end

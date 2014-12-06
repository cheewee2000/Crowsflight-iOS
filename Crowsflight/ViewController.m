//
//  ViewController.m
//  JTGestureBasedTableViewDemo
//
//  Created by James Tang on 2/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"
#import "JTTableViewGestureRecognizer.h"

@interface ViewController () <JTTableViewGestureMoveRowDelegate>
@property (nonatomic, strong) NSMutableArray *rows;
@property (nonatomic, strong) JTTableViewGestureRecognizer *tableViewRecognizer;
@property (nonatomic, strong) id grabbedObject;

@end

@implementation ViewController
@synthesize rows;
@synthesize tableViewRecognizer;
@synthesize grabbedObject;

#define ADDING_CELL @"Continue..."
#define DONE_CELL @"Done"
#define DUMMY_CELL @"Dummy"
#define COMMITING_CREATE_CELL_HEIGHT 60
#define NORMAL_CELL_FINISHING_HEIGHT 60

#pragma mark - View lifecycle


- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        
        CGRect screen = [[UIScreen mainScreen] applicationFrame];
        
        self.tableView  = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, screen.size.width-40, screen.size.height) style:UITableViewStylePlain];
        
        [self.tableView setSeparatorStyle:(UITableViewCellSeparatorStyleSingleLine)];
        [self.tableView setBackgroundColor:[UIColor grayColor]];
        
        dele = [[UIApplication sharedApplication] delegate];
        
        
    }
    
    return self;
}



- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    // In this example, we setup self.rows as datasource
    self.rows = [NSMutableArray arrayWithObjects:
                 @"Swipe to the right to complete",
                 @"Swipe to left to delete",
                 @"Drag down to create a new cell",
                 @"Pinch two rows apart to create cell",
                 @"Long hold to start reorder cell",
                 nil];


    // Setup your tableView.delegate and tableView.datasource,
    // then enable gesture recognition in one line.
    self.tableViewRecognizer = [self.tableView enableGestureTableViewWithDelegate:self];
    
}



#pragma mark UITableViewDatasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.rows count];
    
//    NSLog(@"check numberofRowsinSection");
//    if(section==1) return 1;
//    //else return dele.nDestinations;
//    else return  [dele.locationDictionaryArray count];
//    //else return nCells;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    NSObject *object = [self.rows objectAtIndex:indexPath.row];
        static NSString *cellIdentifier = @"MyCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
            cell.textLabel.adjustsFontSizeToFitWidth = YES;
            cell.textLabel.backgroundColor = [UIColor clearColor];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }

        cell.textLabel.text = @"hello";
        if ([object isEqual:DONE_CELL]) {
            cell.textLabel.textColor = [UIColor grayColor];
            cell.contentView.backgroundColor = [UIColor darkGrayColor];
        } else if ([object isEqual:DUMMY_CELL]) {
            cell.textLabel.text = @"";
            cell.contentView.backgroundColor = [UIColor clearColor];
        } else {
            cell.textLabel.textColor = [UIColor whiteColor];
            //cell.contentView.backgroundColor = backgroundColor;
        }
        cell.textLabel.shadowOffset = CGSizeMake(0, 1);
        cell.textLabel.shadowColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.6];
        
        return cell;
    
}


#pragma mark JTTableViewGestureMoveRowDelegate

- (BOOL)gestureRecognizer:(JTTableViewGestureRecognizer *)gestureRecognizer canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)gestureRecognizer:(JTTableViewGestureRecognizer *)gestureRecognizer needsCreatePlaceholderForRowAtIndexPath:(NSIndexPath *)indexPath {
    self.grabbedObject = [self.rows objectAtIndex:indexPath.row];
    [self.rows replaceObjectAtIndex:indexPath.row withObject:DUMMY_CELL];
}

- (void)gestureRecognizer:(JTTableViewGestureRecognizer *)gestureRecognizer needsMoveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    id object = [self.rows objectAtIndex:sourceIndexPath.row];
    [self.rows removeObjectAtIndex:sourceIndexPath.row];
    [self.rows insertObject:object atIndex:destinationIndexPath.row];
}

- (void)gestureRecognizer:(JTTableViewGestureRecognizer *)gestureRecognizer needsReplacePlaceholderForRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.rows replaceObjectAtIndex:indexPath.row withObject:self.grabbedObject];
    self.grabbedObject = nil;
}

@end

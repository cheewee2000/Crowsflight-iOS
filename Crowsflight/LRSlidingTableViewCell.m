//
//  SlidingTableCell.m
//  SlidingTableCell
//
//  Created by Luke Redpath on 26/05/2011.
//  Copyright 2011 LJR Software Limited. All rights reserved.
//

#import "LRSlidingTableViewCell.h"
#import <MapKit/MapKit.h>
#import "cwtUITableViewController.h"


@interface LRSlidingTableViewCell ()
- (void)addSwipeGestureRecognizer:(UISwipeGestureRecognizerDirection)direction;
@end

@implementation LRSlidingTableViewCell

@synthesize swipeDirection;
@synthesize lastGestureRecognized;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
  if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
    
    self.swipeDirection = LRSlidingTableViewCellSwipeDirectionRight;

    UIView *defaultBackgroundView = [[UIView alloc] initWithFrame:self.contentView.frame];
    defaultBackgroundView.backgroundColor = [UIColor colorWithRed:1 green:1 blue:0 alpha:1];
    self.backgroundView = defaultBackgroundView;
      
      float cellWidth=[UIScreen mainScreen].bounds.size.width-40;

      float imgH=35;
      
      UIButton *mbutton = [UIButton buttonWithType:UIButtonTypeCustom];
      [mbutton addTarget:self
                  action:@selector(mapItemClicked)
        forControlEvents:UIControlEventTouchDown];
      [mbutton setImage:[UIImage imageNamed:@"folded-map.png"] forState:UIControlStateNormal];
      mbutton.frame = CGRectMake(cellWidth*.25-imgH*.5, 30-imgH/2, imgH, imgH);
      [defaultBackgroundView addSubview:mbutton];
      
      
      UIButton *ebutton = [UIButton buttonWithType:UIButtonTypeCustom];
      [ebutton addTarget:self
                  action:@selector(emailItemClicked)
        forControlEvents:UIControlEventTouchDown];
      [ebutton setImage:[UIImage imageNamed:@"email.png"] forState:UIControlStateNormal];
      ebutton.frame = CGRectMake(cellWidth*.5-imgH*.5, 30-imgH/2, imgH, imgH);
      [defaultBackgroundView addSubview:ebutton];
      
      UIButton *xbutton = [UIButton buttonWithType:UIButtonTypeCustom];
      [xbutton addTarget:self
                 action:@selector(deleteRow)
       forControlEvents:UIControlEventTouchDown];
      [xbutton setImage:[UIImage imageNamed:@"x.png"] forState:UIControlStateNormal];
      xbutton.frame = CGRectMake(cellWidth*.75-imgH*.5, 30-imgH/2, imgH, imgH);
      [defaultBackgroundView addSubview:xbutton];
      
      dele=[[UIApplication sharedApplication] delegate];
  }
  
  return self;
}


-(void)deleteRow{
    
    
    //remove by index
    if([dele.locationDictionaryArray count]>1){
        
        /*
        UIView *view;
        while (view != nil && ![view isKindOfClass:[cwtUITableViewController class]]) {
            view = [view superview];
        }
        UITableView *tableView = (UITableView *)view;
        
        
        //UITableView* tableView = (UITableView *)self.superview;
        NSIndexPath* pathOfTheCell = [tableView indexPathForCell:self];
        NSInteger row = pathOfTheCell.row;
        
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:pathOfTheCell];
        
        cwtUITableViewController *vc = (cwtUITableViewController *) tableView.dataSource;
*/
        
        UITableView *tableView = (UITableView *)[self findSuperViewWithClass:[UITableView class]];
        NSIndexPath* pathOfTheCell = [tableView indexPathForCell:self];
        NSInteger row = pathOfTheCell.row;

        UITableViewCell *cell = [tableView cellForRowAtIndexPath:pathOfTheCell];

        cwtUITableViewController *vc = (cwtUITableViewController *) tableView.dataSource;

        //delete marked rows
        //if(vc.isFiltered)
        [dele.locationDictionaryArray  removeObjectAtIndex:cell.tag];
        //else [dele.locationDictionaryArray  removeObjectAtIndex:row];
        //save nsmutablearray
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *path = [documentsDirectory stringByAppendingPathComponent:@"/locationList.plist"];
        [dele.locationDictionaryArray writeToFile:path atomically:YES];
        [dele loadmyLocations];

        [dele iCloudSync];
        
        if(vc.isFiltered){
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
            [vc.filteredTableData removeObjectAtIndex:row];
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:NO];
        }
        else{
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:NO];
        }
        
        //reload filter and cell tags
        [tableView reloadData];
        
        if(vc.filterBar.text.length > 0) [vc doFilter];

        NSLog(@"finished deleting");
        
        [vc nextInstruction:3];
        
    }

}




- (UIView *)findSuperViewWithClass:(Class)superViewClass {
    
    UIView *superView = self.superview;
    UIView *foundSuperView = nil;
    
    while (nil != superView && nil == foundSuperView) {
        if ([superView isKindOfClass:superViewClass]) {
            foundSuperView = superView;
        } else {
            superView = superView.superview;
        }
    }
    return foundSuperView;
}

- (void) emailItemClicked{
    
    NSLog(@"email");

//    UITableView* tableView = (UITableView *)self.superview;
//    NSIndexPath* pathOfTheCell = [tableView indexPathForCell:self];
//    //NSInteger row = pathOfTheCell.row;
//    UITableViewCell *cell = [tableView cellForRowAtIndexPath:pathOfTheCell];

    
    NSMutableDictionary * dictionary = [dele.locationDictionaryArray objectAtIndex:self.tag];
    
    NSString * name=[[dictionary objectForKey:@"searchedText"] uppercaseString];
    
    float lat=[[dictionary valueForKey:@"lat"] floatValue];
    float lng=[[dictionary valueForKey:@"lng"] floatValue];
    
    
    MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
    controller.mailComposeDelegate = self;
    
    NSString *subject = [NSString stringWithFormat:@"CROWSFLIGHT:%@", name];
    [controller setSubject:subject];
    
    NSString *cfurl = [NSString stringWithFormat:@"<h3><a href='crowsflight://&ll=%f,%f&q=%@'>%@</a></h3>", lat,lng, name, name];
    NSString *gurl = [NSString stringWithFormat:@"<small><a href='crowsflight://&ll=%f,%f&q=%@'>crowsflight://&ll=%f,%f&q=%@</a></small></br></br>Open the above link on your iPhone to add %@ to Crowsflight.", lat,lng,name,lat,lng,name,name];
    NSString *gurl2 = [NSString stringWithFormat:@"</br></br><small><a href='http://maps.google.com/?ll=%f,%f&near=%@'>[map]</a></small>", lat,lng,name];
    NSString *seprator = @"</br></br>--</br>";
    NSString *footer = @"<small>via <a href='http://cwandt.com/#crows-flight-iphone' >Crowsflight</a></small>";
    NSString *body = [NSString stringWithFormat:@"%@%@%@%@%@", cfurl, gurl,gurl2,seprator,footer];
    [controller setMessageBody:body isHTML:YES];
        
    if (controller) [dele.navController presentViewController:controller animated:YES completion:nil];
    
}

- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error;
{
    if (result == MFMailComposeResultSent) {
        NSLog(@"sent");
    }
    [dele.navController dismissViewControllerAnimated:YES completion:nil];
}


- (void) mapItemClicked{
    Class mapItemClass = [MKMapItem class];
    
    
    //UITableView* tableView = (UITableView *)self.superview;
    //NSIndexPath* pathOfTheCell = [tableView indexPathForCell:self];
    //NSIndexPath *pathOfTheCell = [tableView indexPathForRowAtPoint:self.center];
    //UITableViewCell *cell = [tableView cellForRowAtIndexPath:pathOfTheCell];
    

    
    NSMutableDictionary * dictionary = [dele.locationDictionaryArray objectAtIndex:self.tag];
    
    float lat=[[dictionary valueForKey:@"lat"] floatValue];
    float lng=[[dictionary valueForKey:@"lng"] floatValue];
    
        //check for google maps
        if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"comgooglemaps://"]]){
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"comgooglemaps://?saddr=&daddr=%f,%f&zoom=19",lat, lng]]];            
        }

        // Check for iOS 6
        else if (mapItemClass && [mapItemClass respondsToSelector:@selector(openMapsWithItems:launchOptions:)])
        {
            // Create an MKMapItem to pass to the Maps app
            CLLocationCoordinate2D coordinate =  CLLocationCoordinate2DMake(lat, lng);
            MKPlacemark *placemark = [[MKPlacemark alloc] initWithCoordinate:coordinate addressDictionary:nil] ;
            MKMapItem *mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];

            NSString *st =[dictionary objectForKey:@"searchedText"];

            [mapItem setName:st];
            // Pass the map item to the Maps app
            [mapItem openInMapsWithLaunchOptions:nil];
        }
        else{
            //if there is no ios6
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat: @"http://maps.google.com/maps?ll=%f,%f&z=19", lat, lng]]];
        }


}



- (void)handleSwipe:(UISwipeGestureRecognizer *)gesture
{
    [self setLastGestureRecognized:gesture];
    [self slideOutContentView];
    [self.LRViewControllerDelegate cellDidReceiveSwipe:self];
}

- (void)setSwipeDirection:(LRSlidingTableViewCellSwipeDirection)direction
{
    swipeDirection = direction;
    
    NSArray *existingGestures = [self gestureRecognizers];
    for (UIGestureRecognizer *gesture in existingGestures) {
        [self removeGestureRecognizer:gesture];
    }
    
    switch (swipeDirection) {
        case LRSlidingTableViewCellSwipeDirectionLeft:
            [self addSwipeGestureRecognizer:UISwipeGestureRecognizerDirectionLeft];
            break;
        case LRSlidingTableViewCellSwipeDirectionRight:
            [self addSwipeGestureRecognizer:UISwipeGestureRecognizerDirectionRight];
            break;
        case LRSlidingTableViewCellSwipeDirectionBoth:
            [self addSwipeGestureRecognizer:UISwipeGestureRecognizerDirectionLeft];
            [self addSwipeGestureRecognizer:UISwipeGestureRecognizerDirectionRight];
        default:
            break;
    }
}

- (void)addSwipeGestureRecognizer:(UISwipeGestureRecognizerDirection)direction;
{
  UISwipeGestureRecognizer *swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
  swipeGesture.direction = direction;
  [self addGestureRecognizer:swipeGesture];
}


#pragma mark Sliding content view

#define kBOUNCE_DISTANCE 20.0

void LR_offsetView(UIView *view, CGFloat offsetX, CGFloat offsetY)
{
  view.frame = CGRectOffset(view.frame, offsetX, offsetY);
}

- (void)slideOutContentView;
{
  CGFloat offsetX;
  
  switch (self.lastGestureRecognized.direction) {
    case UISwipeGestureRecognizerDirectionLeft:
      offsetX = -self.contentView.frame.size.width;
      break;
    case UISwipeGestureRecognizerDirectionRight:
      offsetX = self.contentView.frame.size.width;
      break;
    default:
      @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Unhandled gesture direction" userInfo:[NSDictionary dictionaryWithObject:self.lastGestureRecognized forKey:@"lastGestureRecognized"]];
      break;
  }

  [UIView animateWithDuration:0.2 
                        delay:0 
                      options:UIViewAnimationOptionCurveEaseOut 
                   animations:^{ LR_offsetView(self.contentView, offsetX, 0); } 
                   completion:NULL];
}

- (void)slideInContentView;
{
    CGFloat offsetX, bounceDistance;
    
    switch (self.lastGestureRecognized.direction) {
        case UISwipeGestureRecognizerDirectionLeft:
            offsetX = self.contentView.frame.size.width;
            bounceDistance = -kBOUNCE_DISTANCE;
            break;
        case UISwipeGestureRecognizerDirectionRight:
            offsetX = -self.contentView.frame.size.width;
            bounceDistance = kBOUNCE_DISTANCE;
            break;
        default:
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Unhandled gesture direction" userInfo:[NSDictionary dictionaryWithObject:self.lastGestureRecognized forKey:@"lastGestureRecognized"]];
            break;
    }
    
    [UIView animateWithDuration:0.1
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionAllowUserInteraction
                     animations:^{ LR_offsetView(self.contentView, offsetX, 0); }
                     completion:^(BOOL f) {
                         
                         [UIView animateWithDuration:0.1 delay:0
                                             options:UIViewAnimationOptionCurveLinear
                                          animations:^{ LR_offsetView(self.contentView, bounceDistance, 0); }
                                          completion:^(BOOL f) {
                                              
                                              [UIView animateWithDuration:0.1 delay:0
                                                                  options:UIViewAnimationOptionCurveLinear
                                                               animations:^{ LR_offsetView(self.contentView, -bounceDistance, 0); } 
                                                               completion:NULL];
                                          }
                          ];   
                     }];
}

@end

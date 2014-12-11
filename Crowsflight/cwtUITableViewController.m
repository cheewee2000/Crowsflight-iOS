//
//  cwtUITableViewController.m
//  Crowsflight
//
//  Created by Che-Wei Wang on 5/5/13.
//  Copyright (c) 2013 CW&T. All rights reserved.
//

#import "cwtUITableViewController.h"
#import "cwtViewController3.h"
@implementation cwtUITableViewController

@synthesize currentlyActiveSlidingCell;
@synthesize swipeDirectionSegmentedControl;
@synthesize swipeDirection;


- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {

        //CGRect screen = [[UIScreen mainScreen] applicationFrame];
        //CGRect screenBounds = [[UIScreen mainScreen] applicationFrame];
        CGRect screenBounds = [[UIScreen mainScreen] bounds];
        
        self.tableView.frame=CGRectMake(0, 0, screenBounds.size.width-40, screenBounds.size.height);
        
        [self.tableView setSeparatorStyle:(UITableViewCellSeparatorStyleNone)];
        [self.tableView setBackgroundColor:[UIColor colorWithRed:1.0 green:78/255.0f blue:36/255.0f alpha:1]];
        
        dele = [[UIApplication sharedApplication] delegate];
        
        self.filterBar = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, screenBounds.size.width-40, 44)];
        self.filterBar.delegate=self;

        
        UIImageView *searchImage = [[UIImageView alloc] initWithFrame:CGRectMake(00, 5, 30, 30)];
        searchImage.image = [UIImage imageNamed:@"search.png"];
        [self.filterBar  setLeftView:searchImage];
        [self.filterBar  setLeftViewMode:UITextFieldViewModeAlways];

        self.filterBar.autocapitalizationType=UITextAutocapitalizationTypeAllCharacters;
        self.filterBar.placeholder=@"FILTER OR SEARCH";
        self.filterBar.layer.masksToBounds = NO;
        self.filterBar.layer.shadowOffset = CGSizeMake(0, 1);
        self.filterBar.layer.shadowRadius = 2;
        self.filterBar.layer.shadowOpacity = 0.3;
        [self.filterBar  setBackgroundColor:[UIColor colorWithWhite:.95 alpha:1]];
        self.filterBar .clearButtonMode = UITextFieldViewModeAlways;	// has a clear 'x' button to the right
        self.filterBar.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.filterBar.bounds].CGPath;


        [self.filterBar setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:18.0f]];
        self.filterBar.borderStyle = UITextBorderStyleNone;
        self.filterBar.returnKeyType=UIReturnKeySearch;

        UIView * statusBackground=[[UIView alloc] initWithFrame:CGRectMake(0, -20, [[UIScreen mainScreen] bounds].size.width, 20)];
        [statusBackground setBackgroundColor:[UIColor whiteColor]];
        [self.filterBar addSubview:statusBackground];
    
        
        _searchBarMayResign = YES;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange) name:UITextFieldTextDidChangeNotification object:nil];
        

    }

    return self;    
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    //self.clearsSelectionOnViewWillAppear = NO;
 

    
    //sounds
//    NSString *path = [[NSBundle mainBundle] pathForResource:@"Crowsflight_SelectClick_003" ofType:@"wav"];
//    NSURL *url = [NSURL fileURLWithPath:path];
//    AudioServicesCreateSystemSoundID((__bridge CFURLRef)url, &audioSelect3);
//    

    //[[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"listInstructions"];
    
    self.instructions=[[UIImageView alloc] init];
    [self.instructions setAlpha:.98];
    [self.view addSubview:self.instructions];
    

    

}



-(void)viewDidUnload{
    //AudioServicesDisposeSystemSoundID(audioSelect3);
    
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    

}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[dele window] makeKeyWindow];
    
    [self.filterBar  setText:[[NSUserDefaults standardUserDefaults] stringForKey:@"lastSearchText"]];
    
    if(self.filterBar.text.length == 0)
    {
        self.isFiltered = FALSE;
        int currentDestinationN=(int)[[NSUserDefaults standardUserDefaults] integerForKey:@"currentDestinationN"];
        
        if(currentDestinationN>=[dele.locationDictionaryArray count])currentDestinationN=(int)[dele.locationDictionaryArray count]-1;
        
        
        NSIndexPath * ndxPath= [NSIndexPath indexPathForRow:currentDestinationN inSection:0];
        [self.tableView  scrollToRowAtIndexPath:ndxPath atScrollPosition:UITableViewScrollPositionMiddle  animated:NO];
        
    }
    else
    {
        self.isFiltered = TRUE;
        [self doFilter];
        [self.filterBar becomeFirstResponder];
        
    }
    
    [self.tableView reloadData];
    
    
    
    //if no default, set default to true
    if( [[NSUserDefaults standardUserDefaults] objectForKey:@"enable_listInstructions"]==0 )[[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:@"enable_listInstructions"];
    
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"enable_listInstructions"]==TRUE){
        
        int instructionN=(int)[[NSUserDefaults standardUserDefaults] integerForKey:@"listInstructions"];
        
        NSLog(@"show list instructions");
        
        //first launch
        if(instructionN==0){
            //instructionN=1;
            [[NSUserDefaults standardUserDefaults] setInteger:instructionN forKey:@"listInstructions"];
        }
        
        if( instructionN>=0 && self.isFiltered==FALSE){
            [self.instructions setImage:[UIImage imageNamed:[NSString stringWithFormat:@"Crowsflight_listInstructions_006-%02i.png",instructionN]]];
            [self.instructions setHidden:FALSE];
            [self setInstructionPosition];

        }
        
    }else{
        [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"listInstructions"];
        [self.instructions setHidden:TRUE];
    }
    
    
    
}


-(void)viewWillDisappear:(BOOL)animated{
    //dele.viewController.locationViewController.page=[[NSUserDefaults standardUserDefaults] integerForKey:@"currentDestinationN"];
    //NSLog(@"disappearing list view show row %i",dele.viewController.locationViewController.page);
    //[filterBar resignFirstResponder];
}
-(void)viewDidDisappear:(BOOL)animated{
    [self.filterBar resignFirstResponder];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Instructions

-(void)nextInstruction:(int)n{
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"enable_listInstructions"]==FALSE)return;
    
    int instructionN=(int)[[NSUserDefaults standardUserDefaults] integerForKey:@"listInstructions"];
    if(n-1==instructionN){
        if(instructionN<3){
            instructionN++;
            [[NSUserDefaults standardUserDefaults] setInteger:instructionN forKey:@"listInstructions"];
            [self.instructions setImage:[UIImage imageNamed:[NSString stringWithFormat:@"Crowsflight_listInstructions_006-%02i.png",instructionN]]];
            
            [self setInstructionPosition];
            
        }
        
        else{
            [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"listInstructions"];
            [[NSUserDefaults standardUserDefaults] setBool:FALSE forKey:@"enable_listInstructions"];
            [self.instructions setHidden:TRUE];
            
            NSLog(@"no more instructions");
            
        }
    }
}


-(void)setInstructionPosition{
    int instructionN=(int)[[NSUserDefaults standardUserDefaults] integerForKey:@"listInstructions"];
    CGRect screen = [[UIScreen mainScreen] bounds];
    
    NSLog(@"instn %i",instructionN);
    
    if(instructionN==2){
        [self.instructions setFrame:CGRectMake(-22,40, screen.size.width, screen.size.width)];

        
        
        //reset scroll to 0
        CGPoint contentOffset = self.tableView.contentOffset;
        contentOffset.y = -20;
        [self.tableView setContentOffset:contentOffset animated:NO];
    }
    
    //swipe and delete instructions
    else
    {
        //[self.instructions setFrame:CGRectMake(0, dele.nDestinations*self.cell.frame.size.height-20, 320, 320)];
        [self.instructions setFrame:CGRectMake(-22, (dele.nDestinations-1)*60+100, screen.size.width, screen.size.width)];

    }
    
    
}



#pragma mark - Table view data source
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    
    if(section==0){
        // UIView *view = [[UIView alloc] initWithFrame:[self.filterBar frame]];
        // [view addSubview:self.filterBar];
        //return view;

        return self.filterBar;

    }
    else return nil;
    
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if(section==0) return 44;
    else return 0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 3;
}


- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0;
}


- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return @"";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{

    int rowCount;
    if(section==1) {
        if([[NSUserDefaults standardUserDefaults] boolForKey:@"unlockcrowsflight"]==NO ) return 5;
        else return 4;
    }
    else if(section==2) {
        if (self.isFiltered)return 0;
        else return 1;
    }
    else{
        
        if(self.isFiltered) {
            rowCount = (int)self.filteredTableData.count;
            [self setReorderingEnabled:FALSE];
        }
        else{
            [self setReorderingEnabled:( [dele.locationDictionaryArray count] > 1 )];
            rowCount=(int)[dele.locationDictionaryArray count];
        }
    }
    //return 0;
    return rowCount;
    
    

}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"";
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section==1 && indexPath.row==4) return 150;
    else if(indexPath.section==1 && indexPath.row==2) return 80;
    else if(indexPath.section==1 && indexPath.row==3) return 80;

    else if(indexPath.section==2) return 40;

    else  return 60;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{

    int screenWidth=[UIScreen mainScreen].bounds.size.width;

    if(!self.isFiltered){
    float yPos=0;
    
    float h= scrollView.contentSize.height;
    float y= scrollView.contentOffset.y;

    int animationStart=250;
    int animationBottomPos=60;
    int animationFrame=[[UIScreen mainScreen] bounds].size.height-(h-y)-yPos-animationStart;
    
    //NSLog(@"animation Frame %i",animationFrame);
    
    int maxWalkFrames=93;

    int walkAnimFrame=animationFrame;
    if(walkAnimFrame>=maxWalkFrames)walkAnimFrame=maxWalkFrames;
    else if(walkAnimFrame<=0)walkAnimFrame=0;
    
    
    NSString *strImgeName = [NSString stringWithFormat:@"walk-%i.png", walkAnimFrame];
    [walkAnimView setImage:[UIImage imageNamed:strImgeName]];
    [walkAnimView setFrame:CGRectMake(0, [[UIScreen mainScreen] bounds].size.height-(h-y)-animationBottomPos, screenWidth, screenWidth*.25)];
    
    
    int doorAnimFrame=animationFrame;
    if(doorAnimFrame>=6)doorAnimFrame=6;
    else if(doorAnimFrame<=0)doorAnimFrame=0;
    
    strImgeName = [NSString stringWithFormat:@"walk-d%i.png", doorAnimFrame];
    [doorAnimView setImage:[UIImage imageNamed:strImgeName]];
    [doorAnimView setFrame:CGRectMake(0, [[UIScreen mainScreen] bounds].size.height-(h-y)-animationBottomPos, screenWidth, screenWidth*.25)];
    [doorBackground setFrame:CGRectMake(0, [[UIScreen mainScreen] bounds].size.height-(h-y)-animationBottomPos, 41 ,screenWidth*.25)];

    
    if(animationFrame>=maxWalkFrames){
        
        doorAnimFrame=(maxWalkFrames+6)-animationFrame;
        
        //NSLog(@"door Frame %i",animationFrame);

        if(doorAnimFrame>=6)doorAnimFrame=6;
        else if(doorAnimFrame<=0)doorAnimFrame=0;
        
        strImgeName = [NSString stringWithFormat:@"walk-d%i.png", doorAnimFrame];
        [doorAnimView setImage:[UIImage imageNamed:strImgeName]];
        [doorAnimView setFrame:CGRectMake(0, [[UIScreen mainScreen] bounds].size.height-(h-y)-animationBottomPos, screenWidth,screenWidth*.25)];
           
    }
    if(h>10 && animationFrame>=maxWalkFrames+6){
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://shop.cwandt.com"]];
    }
    
    }
    

    
    
}


/** Store a reference to the cell that has been swiped.
 *
 *  This allows us to slide the cell's content back in again if the user
 *  starts dragging the table view or swipes a different cell.
 */
- (void)cellDidReceiveSwipe:(LRSlidingTableViewCell *)cell
{
    [self.filterBar resignFirstResponder];
    self.currentlyActiveSlidingCell = cell;
    
    [self nextInstruction:1];
    
}

/** Any swiped cell should be reset when we start to scroll. */
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self.filterBar resignFirstResponder];
    self.currentlyActiveSlidingCell = nil;
    
}

/** Whenever the current active sliding cell changes (or is set to nil)
 * the existing one should be reset by calling it's slideInContentView method. */
- (void)setCurrentlyActiveSlidingCell:(LRSlidingTableViewCell *)cell
{
        [self.currentlyActiveSlidingCell slideInContentView];
        currentlyActiveSlidingCell = cell;
    
}


#pragma mark - Table view delegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    float lineWidth=[UIScreen mainScreen].bounds.size.width-40;
    float screenWidth=[UIScreen mainScreen].bounds.size.width;

    if(indexPath.section==0){

        if(indexPath.row<[dele.locationDictionaryArray count]){
            
            NSMutableDictionary * dictionary;
            if(self.isFiltered) dictionary = [self.filteredTableData objectAtIndex:indexPath.row];
            else dictionary = [dele.locationDictionaryArray objectAtIndex:indexPath.row];
            
            BOOL isCurrent=FALSE;
            int currentDestinationN=(int)[[NSUserDefaults standardUserDefaults] integerForKey:@"currentDestinationN"];
            if(indexPath.row==currentDestinationN)isCurrent=TRUE;
            
            BOOL isLastRow=FALSE;
            int count=0;
            if(self.isFiltered) count = (int)[self.filteredTableData count];
            else count = (int)[dele.locationDictionaryArray count];
            if(indexPath.row==count-1) isLastRow=TRUE;
            
            
    
            NSString *identifier = [NSString stringWithFormat: @"cell-%@%i-%i-%i-%i", [[dictionary objectForKey:@"searchedText"] uppercaseString], (int)indexPath.row,isCurrent,isLastRow,self.isFiltered];
           
            LRSlidingTableViewCell *cell = (LRSlidingTableViewCell *)[tableView dequeueReusableCellWithIdentifier:identifier];
        
        if (cell == nil) {
            cell = [[LRSlidingTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
            cell.LRViewControllerDelegate=(id)self;
            cell.swipeDirection = LRSlidingTableViewCellSwipeDirectionRight;
  
            if(self.isFiltered) {
                NSNumber* num=[self.unfilteredCellRow objectAtIndex:indexPath.row];
                cell.tag=[num integerValue];
            }
            else cell.tag=indexPath.row;
            
            CLLocation *locA = [[CLLocation alloc] initWithLatitude:dele.myLat longitude:dele.myLng];
            CLLocation *locB = [[CLLocation alloc] initWithLatitude:[[dictionary valueForKey:@"lat"] floatValue] longitude:[[dictionary valueForKey:@"lng"] floatValue]];
            
            //distance in meters
            float dist= [locA distanceFromLocation:locB];
            float lotDist=(log(1+dist)/log(100))*.275;


            
            UIView *progressBar = [[UIView alloc] init];
            [cell.contentView addSubview:progressBar];
            progressBar.frame=CGRectMake(0,0, lineWidth*lotDist, 60-1);
                
            UILabel * mainLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 10.0, lineWidth-50, 20)];
            mainLabel.font = [UIFont systemFontOfSize:16.0];
            mainLabel.textAlignment = NSTextAlignmentLeft;
            mainLabel.textColor = [UIColor whiteColor];
            mainLabel.backgroundColor = [UIColor clearColor];
            mainLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight;
            mainLabel.text = [[dictionary objectForKey:@"searchedText"] uppercaseString];

            [progressBar addSubview:mainLabel];

            
            NSString * distanceString;
            if([dele.units isEqual:@"m"]){
                if(dist<402.336) //.25 miles in meters
                    distanceString= [NSString stringWithFormat:@"%.1f\'",dist*3.28084];
                else  distanceString= [NSString stringWithFormat:@"%.2fmi",dist*0.000621371];
                
            }
            else {
                if(dist<1000) distanceString= [NSString stringWithFormat:@"%.1fm",dist];
                else distanceString= [NSString stringWithFormat:@"%.2fkm",dist/1000.0];
            }

            UILabel * secondLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 25, lineWidth-50, 25.0)];
            secondLabel.font = [UIFont systemFontOfSize:10.0];
            secondLabel.textAlignment = NSTextAlignmentLeft;
            secondLabel.textColor = [UIColor whiteColor];
            secondLabel.backgroundColor = [UIColor clearColor];
            secondLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight;
            secondLabel.text = [distanceString uppercaseString];
            [progressBar addSubview:secondLabel];


            UIImageView *photo = [[UIImageView alloc] initWithFrame:CGRectMake(lineWidth-40, 30-12.5, 25.0, 25.0)];
            photo.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight;
            [progressBar addSubview:photo];

            if(dist<1500)photo.image =[UIImage imageNamed:@"walk.png"];
            else if( dist<10000)photo.image =[UIImage imageNamed:@"bike.png"];
            else if( dist<150000)photo.image =[UIImage imageNamed:@"drive.png"];
            else photo.image =[UIImage imageNamed:@"fly.png"];

            
            if(indexPath.row==currentDestinationN || (self.isFiltered && cell.tag==currentDestinationN) ){
                cell.contentView.backgroundColor = [UIColor colorWithRed:111/255.0 green:227/255.0 blue:1 alpha:1];
                progressBar.backgroundColor = [UIColor colorWithRed:0 green:.73 blue:1 alpha:1];
            }
            else{
                progressBar.backgroundColor = [UIColor colorWithWhite:.57 alpha:1];
                cell.contentView.backgroundColor = [UIColor colorWithWhite:.7 alpha:1];
            }
            
            //separation bar
            UIView * bar=[[UIView alloc] initWithFrame:CGRectMake(0,  60-1, lineWidth, 1)];
            bar.backgroundColor=[UIColor colorWithWhite:1 alpha:1];
            [cell addSubview:bar];
            
            if(self.isFiltered){
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
            }
            else{
                cell.selectionStyle = UITableViewCellSelectionStyleGray;
            }
            
            if(isLastRow){
                //last location
                bar.backgroundColor=[UIColor clearColor];
                cell.contentView.layer.shadowOffset = CGSizeMake(0, 2);
                cell.contentView.layer.shadowRadius = 2;
                cell.contentView.layer.shadowOpacity = 0.5;
            }

        }
        return cell;
       }

    }
    
    //show search button if filter==0
    else if(indexPath.section==1 && [self.filteredTableData count]==0 && self.isFiltered && indexPath.row==0){
        

        
        NSString *identifier = @"searchHelp";
        
        UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:identifier];
        
        if (cell == nil){
            
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
            
            UILabel *label2 = [[UILabel alloc] initWithFrame:CGRectMake(15, -10, lineWidth, 80)];
            [label2 setTextColor:[UIColor colorWithWhite:.2 alpha:1]];
            [label2 setBackgroundColor:[UIColor clearColor]];
            [label2 setFont:[UIFont fontWithName: @"Helvetica" size: 10.0f]];
            //[label2 setText:[@"Search for a new address, placename \n\nor enter lat,lng directly \n(e.g. 40.729,-73.993)" uppercaseString]];
            [label2 setText:@"SEARCH\nADDRESS, PLACENAME, LAT/LNG OR what3words" ];

            label2.numberOfLines=4;
            [cell addSubview:label2];
            
            
            UILabel *label3 = [[UILabel alloc] initWithFrame:CGRectMake(15, 35, lineWidth, 80)];
            [label3 setTextColor:[UIColor colorWithWhite:.2 alpha:1]];
            [label3 setBackgroundColor:[UIColor clearColor]];
            [label3 setFont:[UIFont fontWithName: @"Helvetica" size: 10.0f]];
            //[label3 setText:@"USE what3words TOO!\n(E.G. AFTER.BLANK.REJECT)" ];

            [label3 setText:@"PLACENAME (e.g. UNION SQUARE)\nLAT,LNG (e.g. 40.729,-73.993)\nwhat3words (e.g. recent.pints.giving)" ];
            label3.numberOfLines=4;
            [cell addSubview:label3];
            
            //cell.contentView.backgroundColor = [UIColor colorWithRed:111/255.0 green:227/255.0 blue:1 alpha:1];
            cell.contentView.backgroundColor = [UIColor colorWithWhite:.95 alpha:1];

            cell.selectionStyle=UITableViewCellSelectionStyleNone;
            }
        return cell;
        
        
        
    }
    
    else if(indexPath.section==1 && [self.filteredTableData count]==0 && self.isFiltered && indexPath.row==1){
        
        NSString *identifier = [NSString stringWithFormat:@"filter%@",self.filterBar.text];
        
        UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:identifier];
        
        if (cell == nil){
            
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
            
            
            UIView * searchButton =[[UIView alloc] initWithFrame:CGRectMake(lineWidth-80, 5, 60, 40)];
            //[searchButton setBackgroundColor:[UIColor colorWithWhite:.9 alpha:1]];
            searchButton.backgroundColor = [UIColor colorWithRed:0 green:.73 blue:1 alpha:1];

            
            
            UILabel *swipeLabel = [[UILabel alloc] initWithFrame:CGRectMake(14, 5, 60, 30)];
            [swipeLabel setTextColor:[UIColor colorWithWhite:.95 alpha:1]];
            [swipeLabel setFont:[UIFont fontWithName: @"Helvetica" size: 20.0f]];
            [swipeLabel setBackgroundColor:[UIColor clearColor]];
            [swipeLabel setText:@"GO"];


            //cell.contentView.backgroundColor = [UIColor colorWithRed:111/255.0 green:227/255.0 blue:1 alpha:1];
            cell.contentView.backgroundColor = [UIColor colorWithWhite:.95 alpha:1];

            swipeLabel.numberOfLines=1;
            [searchButton addSubview:swipeLabel];
            [cell addSubview:searchButton];
        
            cell.selectionStyle=UITableViewCellSelectionStyleNone;
    }
        return cell;
        
    }

    
    
    //swipe label
    else if (indexPath.section==1)
    {
        
        if(indexPath.row==0){
            NSString *identifier = @"instructions";
            UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:identifier];
        
            
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
                [cell.contentView setBackgroundColor:[UIColor colorWithRed:1.0 green:78/255.0f blue:36/255.0f alpha:1]];

                UIImageView *swipeImage = [[UIImageView alloc] initWithFrame:CGRectMake(lineWidth-130, 0, 120 , 60)];
                swipeImage.image =[UIImage imageNamed:@"swipe3.png"];
                [cell addSubview:swipeImage];


                UILabel *swipeLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 20, lineWidth, 20)];
                [swipeLabel setBackgroundColor:[UIColor clearColor]];

                NSString *text=@"SWIPE TO GET DIRECTIONS EMAIL DELETE";

                UIFont *regularFont = [UIFont fontWithName: @"AndaleMono" size: 9.0f];

                [swipeLabel setFont:regularFont];
                [swipeLabel setText:text];
                swipeLabel.textColor=[UIColor colorWithWhite:1 alpha:1];

                [cell addSubview:swipeLabel];
                cell.selectionStyle=UITableViewCellSelectionStyleNone;


            }

            return cell;
        }
        
        
        
        //long press label
        else if(indexPath.row==1){
            
            NSString *identifier =  [NSString stringWithFormat:@"instructions2%i",self.isFiltered];
            
            UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:identifier];
            
            if (cell == nil){
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
                UIImageView *holdImage = [[UIImageView alloc] initWithFrame:CGRectMake(lineWidth-130, 0, 120 , 60)];
                holdImage.image =[UIImage imageNamed:@"longpress3.png"];
                [cell addSubview:holdImage];
                
                UILabel *holdLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 20, lineWidth-20, 20)];
                [holdLabel setBackgroundColor:[UIColor clearColor]];
                [cell.contentView setBackgroundColor:[UIColor colorWithRed:1.0 green:78/255.0f blue:36/255.0f alpha:1]];

                NSString * text=@"LONG PRESS ROW TO REARRANGE THE LIST";
                        
                UIFont *regularFont = [UIFont fontWithName: @"AndaleMono" size: 9.0f];
                [holdLabel setFont:regularFont];
                [holdLabel setText:text];
                [cell addSubview:holdLabel];
                
                cell.selectionStyle=UITableViewCellSelectionStyleNone;
                
                //top border
                UIView *bar=[[UIView alloc] initWithFrame:CGRectMake(0,  0, lineWidth, 1)];
                bar.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"dotted-line.png"]];
                [cell addSubview:bar];
            
            
                if(self.isFiltered){
                    holdLabel.textColor=[UIColor colorWithWhite:1 alpha:.25];
                    holdImage.alpha=.25;
                    
                }else{
                    holdLabel.textColor=[UIColor colorWithWhite:1 alpha:1];
                    holdImage.alpha=1;
                }
            
            }

            return cell;
        }
        
        
        
        else if(indexPath.row==2){
            NSString *identifier = @"info";
            UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:identifier];
            
            
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];

                UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 15, lineWidth-20, 50)];
                [label setBackgroundColor:[UIColor clearColor]];
                [cell.contentView setBackgroundColor:[UIColor colorWithRed:1.0 green:78/255.0f blue:36/255.0f alpha:1]];

                NSString * text=@"CROWSFLIGHT is lovingly designed and built by CW&T.";

                NSMutableAttributedString* attrString = [[NSMutableAttributedString alloc] initWithString: text];
                [attrString addAttribute:NSUnderlineStyleAttributeName value: [NSNumber numberWithInt:NSUnderlineStyleSingle] range:NSMakeRange(46, 4)];
                
                
                UIFont *regularFont = [UIFont fontWithName: @"AndaleMono" size: 11.0f];
                [label setFont:regularFont];
                label.textColor=[UIColor colorWithWhite:1 alpha:1];
                label.numberOfLines=4;
                //[label setText:text];
                label.attributedText = attrString;
            
                [cell addSubview:label];
                
                //top border
                UIView *bar=[[UIView alloc] initWithFrame:CGRectMake(0,  0, lineWidth, 1)];
                bar.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"dotted-line.png"]];
                [cell addSubview:bar];


                cell.selectionStyle=UITableViewCellSelectionStyleNone;
            }
            return cell;
            
        }
        else if(indexPath.row==3){
            NSString *identifier = @"appstore";
            UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:identifier];
            
            
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
                //UIImageView* pin=[[UIImageView alloc] initWithFrame:CGRectMake(cell.frame.size.width*.5-30, 95, 64/3, 78/3)];
                //[pin setImage:[UIImage imageNamed:@"white_pin.png"]];
                //[cell addSubview:pin];
                
                UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 15, lineWidth-20, 50)];
                [label setBackgroundColor:[UIColor clearColor]];
                [cell.contentView setBackgroundColor:[UIColor colorWithRed:1.0 green:78/255.0f blue:36/255.0f alpha:1]];
                
                NSString * text=@"If you like it, please rate it or better yet, write a review for it in the App Store. Thank you!";
                
                NSMutableAttributedString* attrString = [[NSMutableAttributedString alloc] initWithString: text];
                [attrString addAttribute:NSUnderlineStyleAttributeName value: [NSNumber numberWithInt:NSUnderlineStyleSingle] range:NSMakeRange(75, 9)];
                
                
                UIFont *regularFont = [UIFont fontWithName: @"AndaleMono" size: 11.0f];
                [label setFont:regularFont];
                label.textColor=[UIColor colorWithWhite:1 alpha:1];
                label.numberOfLines=4;
                //[label setText:text];
                label.attributedText = attrString;
                
                [cell addSubview:label];
                
                //top border
                UIView *bar=[[UIView alloc] initWithFrame:CGRectMake(0,  0, lineWidth, 1)];
                bar.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"dotted-line.png"]];
                [cell addSubview:bar];
                
                
                cell.selectionStyle=UITableViewCellSelectionStyleNone;
            }
            return cell;
            
        }
        
        else if(indexPath.row==4){
            NSString *identifier = @"inapp";
            UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:identifier];
            
            
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
                UIImageView* pin=[[UIImageView alloc] initWithFrame:CGRectMake(lineWidth*.5-15, 110, 30, 30)];
                [pin setImage:[UIImage imageNamed:@"unlock.png"]];
                [cell addSubview:pin];
                
                cell.selectionStyle=UITableViewCellSelectionStyleNone;
            
                
                UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 15, lineWidth-20, 80)];
                [label setBackgroundColor:[UIColor clearColor]];
                [cell.contentView setBackgroundColor:[UIColor colorWithRed:1.0 green:78/255.0f blue:36/255.0f alpha:1]];

                NSString * text=@"You're currently limited to saving 5 locations. UNLOCK CROWSFLIGHT to save as many locations as you want. If you've already purchased Crowsflight on any iOS device, re-unlocking is free.";
                
                UIFont *regularFont = [UIFont fontWithName: @"AndaleMono" size: 11.0f];
                [label setFont:regularFont];
                label.textColor=[UIColor colorWithWhite:1 alpha:1];
                label.numberOfLines=6;
                [label setText:text];
                [cell addSubview:label];
                
                //top border
                UIView *bar=[[UIView alloc] initWithFrame:CGRectMake(0,  0, lineWidth, 1)];
                bar.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"dotted-line.png"]];
                [cell addSubview:bar];
                
//                //bottom separation bar
//                UIView *bar=[[UIView alloc] initWithFrame:CGRectMake(0,  150-1, cell.bounds.size.width, 1)];
//                bar.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"dotted-line.png"]];
//                [cell addSubview:bar];
            }
            
            return cell;
            
        }

    }//end section 1
    
    
    //walk animation View
    else if (indexPath.section==2){
        //NSLog(@"frame height %f",tableView.contentSize.height);
        float yPos=0;
        
        
        NSString *identifier = [NSString stringWithFormat:@"easter-%f",yPos];
        
        UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:identifier];

        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];           
            UIImageView* yOffset=[[UIImageView alloc] initWithFrame:CGRectMake(lineWidth*.5-175/2.0, 40+yPos, 150, 175)];
            [yOffset setImage:[UIImage imageNamed:@"teeth-02.png"]];
            [cell addSubview:yOffset];
            [cell setBackgroundColor:[UIColor colorWithRed:1.0 green:78/255.0f blue:36/255.0f alpha:1]];

            cell.selectionStyle=UITableViewCellSelectionStyleNone;
        }
        
        walkAnimView=[[UIImageView alloc] init];
        [cell addSubview:walkAnimView];

        doorBackground=[[UIImageView alloc] init];
        [doorBackground setFrame:CGRectMake(0, [[UIScreen mainScreen] bounds].size.height, screenWidth ,80)];
        [doorBackground setBackgroundColor:[UIColor colorWithRed:1.0 green:78/255.0f blue:36/255.0f alpha:1]];
        [cell addSubview:doorBackground];

        
        
         doorAnimView=[[UIImageView alloc] init];
        [doorAnimView setFrame:CGRectMake(0, [[UIScreen mainScreen] bounds].size.height, screenWidth,80)];
        [doorAnimView setImage:[UIImage imageNamed:@"walk-walk.png"]];
        [cell addSubview:doorAnimView];
        
        
        
        return cell;

        
    }

    return nil;
    
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if(indexPath.section==1){
        
        if(indexPath.row==2){
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"http://cwandt.com/"]];

            return;            
        }
        else if(indexPath.row==3){
            
            //[[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"http://appstore.com/crowsflight"]];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"itms-apps://itunes.apple.com/app/id444185307"]];

            //[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://itunes.apple.com/ru/app/id444185307"]];

            return;
        }
        else if(indexPath.row==4){
            [dele.viewController purchase];
            return;
        }

         if(self.isFiltered==FALSE)return;
        
         else if( self.isFiltered && [self.filteredTableData count]==0)
         {
            [dele.viewController searchGeo:(UITextField*)self.filterBar];
            [self.filterBar resignFirstResponder];
            [super dismissViewControllerAnimated:NO completion:nil];
            [super.navigationController popToRootViewControllerAnimated:NO];
            return;
        }
    }
    else if(indexPath.section==0){

        //AudioServicesPlaySystemSound(audioSelect3);

        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];

        [[NSUserDefaults standardUserDefaults] setInteger:cell.tag forKey:@"currentDestinationN"];
        dele.viewController.locationViewController.page=cell.tag;
        [self dismissViewControllerAnimated:YES completion:nil];
        [self.navigationController popDrawerViewController:YES];
        [self.filterBar resignFirstResponder];

        
        
        NSLog(@"selected row %i",(int)dele.viewController.locationViewController.page);
    }

}


- (UITableViewCell *)cellIdenticalToCellAtIndexPath:(NSIndexPath *)indexPath forDragTableViewController:(ATSDragToReorderTableViewController *)dragTableViewController {
	
    if(indexPath.section==0){
        
        if(indexPath.row<[dele.locationDictionaryArray count]){
            NSString *identifier = [NSString stringWithFormat: @"cell%ihighlighted", (int)indexPath.row];
            
            //LRSlidingTableViewCell *cell = (LRSlidingTableViewCell *)[dragTableViewController dequeueReusableCellWithIdentifier:identifier];
            LRSlidingTableViewCell *cell = [[LRSlidingTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];

            if (cell == nil) {
                cell = [[LRSlidingTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
            }
            
            cell.selectionStyle = UITableViewCellSelectionStyleGray;

            NSMutableDictionary * dictionary;
            if(self.isFiltered)
                dictionary = [self.filteredTableData objectAtIndex:indexPath.row];
            else
                dictionary = [dele.locationDictionaryArray objectAtIndex:indexPath.row];
 
            
            //NSMutableDictionary * dictionary = [dele.locationDictionaryArray objectAtIndex:indexPath.row];
            
            CLLocation *locA = [[CLLocation alloc] initWithLatitude:dele.myLat longitude:dele.myLng];
            CLLocation *locB = [[CLLocation alloc] initWithLatitude:[[dictionary valueForKey:@"lat"] floatValue] longitude:[[dictionary valueForKey:@"lng"] floatValue]];
            
            //distance in meters
            float dist= [locA distanceFromLocation:locB];

            float lotDist=(log(1+dist)/log(100))*.275-.2;

            float lineWidth=[UIScreen mainScreen].bounds.size.width-40;
            
            UIView *progressBar = [[UIView alloc] initWithFrame:CGRectMake(0,0, lineWidth*lotDist, 60-1)];
            [cell.contentView addSubview:progressBar];
            
            UILabel * mainLabel = [[UILabel alloc] initWithFrame:CGRectMake(5.0, 10.0, lineWidth-50, 20)];
            mainLabel.font = [UIFont systemFontOfSize:16.0];
            mainLabel.textAlignment = NSTextAlignmentLeft;
            mainLabel.textColor = [UIColor whiteColor];
            mainLabel.backgroundColor = [UIColor clearColor];
            //mainLabel.backgroundColor=[UIColor colorWithRed:1.0 green:78/255.0f blue:36/255.0f alpha:1];

            mainLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight;
            [progressBar addSubview:mainLabel];
            mainLabel.text = [[dictionary objectForKey:@"searchedText"] uppercaseString];
            
            NSString * distanceString;
            if([dele.units isEqual:@"m"]){
                if(dist<402.336) //.25 miles in meters
                    distanceString= [NSString stringWithFormat:@"%.1f\'",dist*3.28084];
                else  distanceString= [NSString stringWithFormat:@"%.2fmi",dist*0.000621371];
                
            }
            else {
                if(dist<1000) distanceString= [NSString stringWithFormat:@"%.1fm",dist];
                else distanceString= [NSString stringWithFormat:@"%.2fkm",dist/1000.0];
            }
            
            UILabel * secondLabel = [[UILabel alloc] initWithFrame:CGRectMake(5.0, 25, lineWidth-50, 25.0)];
            secondLabel.font = [UIFont systemFontOfSize:10.0];
            secondLabel.textAlignment = NSTextAlignmentLeft;
            
            secondLabel.textColor = [UIColor whiteColor];
            secondLabel.backgroundColor = [UIColor clearColor];
            secondLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight;
            secondLabel.text = [distanceString uppercaseString];
            [progressBar addSubview:secondLabel];
            
            UIImageView *photo = [[UIImageView alloc] initWithFrame:CGRectMake(lineWidth-40, 30-12.5, 25.0, 25.0)];
            photo.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight;
            [progressBar addSubview:photo];
            
            if(dist<1500)photo.image =[UIImage imageNamed:@"walk.png"];
            else if( dist<10000)photo.image =[UIImage imageNamed:@"bike.png"];
            else if( dist<150000)photo.image =[UIImage imageNamed:@"drive.png"];
            else photo.image =[UIImage imageNamed:@"fly.png"];
            

        
        
            return cell;
        }
        
    }
	return nil;
}


#pragma mark - Search
//-(void)searchBar:(UISearchBar*)filterBar textDidChange:(NSString*)text
//- (BOOL) textField: (UITextField *) textField shouldChangeCharactersInRange: (NSRange) range replacementString: (NSString *) text;
-(void)textDidChange{
    //NSLog(@"filtering");

    if(self.filterBar.text.length == 0)
    {
        self.isFiltered = FALSE;
        [[NSUserDefaults standardUserDefaults] setValue:self.filterBar.text forKey:@"lastSearchText"];
        
        

        
    }
    else
    {
        self.isFiltered = TRUE;
        [[NSUserDefaults standardUserDefaults] setValue:self.filterBar.text forKey:@"lastSearchText"];
        [self doFilter];
        //reset scroll to 0 if there are results
        if(self.filteredTableData.count>0)
        {
            CGPoint contentOffset = self.tableView.contentOffset;
            contentOffset.y = -20;
            [self.tableView setContentOffset:contentOffset animated:NO];
        }
    }

    _searchBarMayResign = NO;
    [self.tableView reloadData];
    _searchBarMayResign = YES;
    
    
    
    //check filter again after reloadData
    
    if(self.filterBar.text.length == 0)
    {
        int currentDestinationN=(int)[[NSUserDefaults standardUserDefaults] integerForKey:@"currentDestinationN"];
        if(currentDestinationN>=[dele.locationDictionaryArray count])currentDestinationN=(int)[dele.locationDictionaryArray count]-1;

        NSIndexPath * ndxPath= [NSIndexPath indexPathForRow:currentDestinationN inSection:0];
        [self.tableView  scrollToRowAtIndexPath:ndxPath atScrollPosition:UITableViewScrollPositionMiddle  animated:NO];
        
    }
}






-(BOOL)textFieldShouldEndEditing:(UITextField *)textField{

    return _searchBarMayResign;
}



-(void)doFilter{
    
    //NSLog(@"do filter");

    self.filteredTableData = [[NSMutableArray alloc] init];
    self.unfilteredCellRow = [[NSMutableArray alloc] init];
    int cellRow=0;
    for (NSMutableDictionary * dictionary in dele.locationDictionaryArray)
    {
        //mainLabel.text = [[dictionary objectForKey:@"searchedText"] uppercaseString];
        NSRange nameRange = [[dictionary objectForKey:@"searchedText"]rangeOfString:self.filterBar.text options:NSCaseInsensitiveSearch];
        
        //NSLog([NSString stringWithFormat:@"%@", self.filterBar.text]);
        if(nameRange.location != NSNotFound)
        {
            [self.filteredTableData addObject:dictionary];
            [self.unfilteredCellRow addObject:[NSNumber numberWithInt:cellRow]];
        }
        cellRow++;
    }

}




- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if(self.filterBar.text.length>0)
    {
        //AudioServicesPlaySystemSound(audioSelect3);
        
        [self.filterBar resignFirstResponder];
        
        [super dismissViewControllerAnimated:NO completion:nil];
        [super.navigationController popToRootViewControllerAnimated:NO];
        
        //[self performSelectorInBackground:@selector(search) withObject:self.view];
        [dele.viewController searchGeo:(UITextField*)self.filterBar];
        
        [self nextInstruction:3];
        return YES;
    }
    return NO;
}



/*
 Required for drag tableview controller
 */
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
		
    if(toIndexPath.section==0 && toIndexPath.row<[dele.locationDictionaryArray count]){
        NSMutableDictionary * rowDictionary = [dele.locationDictionaryArray objectAtIndex:fromIndexPath.row];
        //delete
        [dele.locationDictionaryArray  removeObjectAtIndex:fromIndexPath.row];

        //insert into array
        [dele.locationDictionaryArray insertObject:rowDictionary atIndex:toIndexPath.row];

        //save nsmutablearray
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *path = [documentsDirectory stringByAppendingPathComponent:@"/locationList.plist"];
        [dele.locationDictionaryArray writeToFile:path atomically:YES];
        [dele loadmyLocations];
        
                
        [[NSUserDefaults standardUserDefaults] setInteger:toIndexPath.row forKey:@"currentDestinationN"];
        dele.viewController.locationViewController.page=toIndexPath.row;
        
        [self.tableView reloadData];

        
        NSLog(@"finished moving");
    }

}





@end

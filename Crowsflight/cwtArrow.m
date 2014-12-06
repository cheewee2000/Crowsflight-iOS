//
//  cwtArrow.m
//  Crowsflight
//
//  Created by Che-Wei Wang on 6/16/13.
//  Copyright (c) 2013 CW&T. All rights reserved.
//

#import "cwtArrow.h"

#import "cwtAppDelegate.h"

#define DEGREES_TO_RADIANS(angle) (angle / 180.0 * M_PI)

@implementation cwtArrow

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.spread=60.0;
        //self.showExtras=TRUE;
        //self.showExtras=[[NSUserDefaults standardUserDefaults] boolForKey:@"showInfo"];
         
    }
    return self;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    //int thickness=210;
    //int r=100+10+thickness*.5;

    int thickness=255;
    int r=60+thickness*.5;

    //CGRect screen = [[UIScreen mainScreen] applicationFrame];

	int x=325;
	int y=325;
	
    //float angle=15;
    if(self.spread<=1)self.spread=88.0;
    else if(self.spread>180)self.spread=180;

    _start=-90.0-self.spread;
    _end=-90+self.spread;
    
    _start=DEGREES_TO_RADIANS(_start);
    _end=DEGREES_TO_RADIANS(_end);

    
    CGContextRef context = UIGraphicsGetCurrentContext();

	//arrow
	CGContextSetLineWidth(context,thickness);
    CGContextSetStrokeColorWithColor(context, [UIColor colorWithRed:1 green:1 blue:0 alpha:.7].CGColor);
    CGContextAddArc(context, x, y, r,_start,_end,0);
	CGContextStrokePath(context);
    
    
    
    if(_showExtras){
        r=320*.5-40;
        
        //dimension arc
        CGContextSetLineWidth(context,.5);
        CGContextSetStrokeColorWithColor(context, [UIColor colorWithWhite:.7 alpha:1].CGColor);
        CGContextAddArc(context, x, y, r, _start,_end,0);
        CGContextStrokePath(context);
        
        
        int tickWidth=2;
        
        //ticks
        CGContextMoveToPoint(context, x+cosf(_start)*(r+tickWidth), y+sinf(_start)*(r+tickWidth));
        CGContextAddLineToPoint(context,x+cosf(_start)*(r-tickWidth), y+sinf(_start)*(r-tickWidth) );
        CGContextStrokePath(context);
     
        CGContextMoveToPoint(context, x+cosf(_end)*(r+tickWidth), y+sinf(_end)*(r+tickWidth));
        CGContextAddLineToPoint(context,x+cosf(_end)*(r-tickWidth), y+sinf(_end)*(r-tickWidth) );
        CGContextStrokePath(context);
    

        //callout
        //cwtAppDelegate* dele = [[UIApplication sharedApplication] delegate];
        NSString *string = [NSString stringWithFormat:@"±%i°",(int)self.spread];
        [[UIColor colorWithWhite:.7 alpha:1] set];
        
        UIFont*font=[UIFont fontWithName:@"HelveticaNeue-Light" size:8.0];
        
        CGSize stringSize = [string sizeWithFont:font];
        [string drawAtPoint:CGPointMake( x-stringSize.width*.5, y-(r-tickWidth) ) withFont:font];    
        
    }

    

}


-(void) updateSpread:(CGFloat)newSpread
{
    self.spread = newSpread;
    [self setNeedsDisplay];
}


-(void) showExtras:(BOOL)show
{
    _showExtras=show;
    [self setNeedsDisplay];
}


@end

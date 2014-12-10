//
//  cwtDrawArc.m
//  Crowsflight
//
//  Created by Che-Wei Wang on 5/5/13.
//  Copyright (c) 2013 CW&T. All rights reserved.
//

#import "cwtDrawArc.h"

// Our conversion definition
#define DEGREES_TO_RADIANS(angle) (angle / 180.0 * M_PI)

@implementation cwtDrawArc

- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
    // Initialization code.
        _progress=359;
        self.maxArc=359;
        //self.showExtras=TRUE;
        //self.showExtras=[[NSUserDefaults standardUserDefaults] boolForKey:@"showInfo"];

        

    }
    return self;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    //CGRect screen = [[UIScreen mainScreen] applicationFrame];
    //based on 320;
	int r=95;
    float t=20.0;
    
	// Drawing code.
	int x=115;
	int y=115;

    float start=-90.0;
    float end=start+1;
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, t);

    //background arc
//    CGContextSetStrokeColorWithColor(context, [UIColor colorWithWhite:.97 alpha:1].CGColor);
//    CGContextAddArc(context, x, y, r, 0, 2 * M_PI, 1);
//	CGContextStrokePath(context);

    //midline
    CGContextSetStrokeColorWithColor(context, [UIColor colorWithRed:0 green:.73f blue:1 alpha:1].CGColor);
    CGContextSetLineWidth(context, 1.0);
    CGContextAddArc(context, x, y, r, 0, 2 * M_PI, 1);
	CGContextStrokePath(context);

    
	//progress arc
	CGContextSetLineWidth(context, t);
    CGContextSetStrokeColorWithColor(context, [UIColor colorWithRed:0 green:.73f blue:1 alpha:1.0f].CGColor);
    if(_progress>=self.maxArc) _progress=self.maxArc;
    if(_progress<=5 ) _progress=5;

    end=start+360-_progress;
    CGContextAddArc(context, x, y, r, DEGREES_TO_RADIANS(start),DEGREES_TO_RADIANS(end),1);
	CGContextStrokePath(context);
    
    
    float underlayRadius=60;

    
    if(_showExtras){
        CGContextSetLineWidth(context,1);
        
        //zero line
        CGContextMoveToPoint(context, x, y-r-t*.5);
        CGContextAddLineToPoint(context, x, y-r+t*.5+5);
        CGContextStrokePath(context);
        
        NSString *string = @"0";
        [[UIColor colorWithRed:0 green:.73f blue:1 alpha:1] set];
        //[string drawAtPoint:CGPointMake(x-2, y-r+t*.5+5) withFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:8.0]];
        
        
        UIFont *font = [UIFont fontWithName:@"HelveticaNeue-Light" size:8.0];
        NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        
        NSDictionary *attributes = @{ NSFontAttributeName: font,
                                      NSParagraphStyleAttributeName: paragraphStyle };
        
        [string drawAtPoint:CGPointMake(x-2, y-r+t*.5+5) withAttributes:attributes];
        
        [[UIColor colorWithRed:0 green:.73f blue:1 alpha:1] set];

        //distance tracking line
        float lx=x+cosf(DEGREES_TO_RADIANS(end))*(r+t*.5);
        float ly=y+sinf(DEGREES_TO_RADIANS(end))*(r+t*.5);
        CGContextMoveToPoint(context, lx, ly);
        lx=x+cosf(DEGREES_TO_RADIANS(end))*(underlayRadius);
        ly=y+sinf(DEGREES_TO_RADIANS(end))*(underlayRadius);
        CGContextAddLineToPoint(context, lx, ly);
        
        CGContextStrokePath(context);
    
    }
    
    
    //distance text underlay
    CGContextSetFillColorWithColor( context, [UIColor colorWithWhite:.975 alpha:1].CGColor );
    CGContextFillEllipseInRect(context, CGRectMake(x-underlayRadius, y-underlayRadius, underlayRadius*2.0, underlayRadius*2.0));

    
}


// set the component's value
-(void) updateProgress:(CGFloat)newProgress
{

    _progress = newProgress;    
    [self setNeedsDisplay];
}


// returns the component's value.
-(CGFloat) progress {
	return _progress;
}

-(void) showExtras:(BOOL)show
{
    _showExtras=show;
    [self setNeedsDisplay];
}



@end


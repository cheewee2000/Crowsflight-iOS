//
//  cwtToolbar.m
//  Crowsflight
//
//  Created by Che-Wei Wang on 6/13/13.
//  Copyright (c) 2013 CW&T. All rights reserved.
//

#import "cwtToolbar.h"
#import "QuartzCore/CALayer.h"

@implementation cwtToolbar


-(void)drawRect:(CGRect)rect {

    [super drawRect: rect];
    
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx {
    CALayer *imgLayer = [[CALayer alloc] init];
    [imgLayer setContents:(id)[[UIImage imageNamed: @"toolbarbackground.png"] CGImage]];
    [imgLayer setBounds:CGRectMake(0.0f, 0.0f, self.frame.size.width, self.frame.size.height)];
    [imgLayer setPosition:CGPointMake(self.bounds.size.width/2,self.bounds.size.height/2)];
    [layer insertSublayer:imgLayer atIndex:0];
    
    layer.masksToBounds = NO;
    layer.shadowOffset = CGSizeMake(0, 5);
    layer.shadowRadius = 5;
    layer.shadowOpacity = 0.5;
    
}


@end

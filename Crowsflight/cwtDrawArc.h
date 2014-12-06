//
//  cwtDrawArc.h
//  Crowsflight
//
//  Created by Che-Wei Wang on 5/5/13.
//  Copyright (c) 2013 CW&T. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface cwtDrawArc : UIView {
	CGFloat _progress;
}

-(void) updateProgress:(CGFloat)newProgress;
-(CGFloat) progress; // returns the component's value.
@property (nonatomic,assign)float maxArc;
@property (nonatomic,assign) BOOL showExtras;

-(void) showExtras:(BOOL)show;


@end
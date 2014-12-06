//
//  cwtAnnotation.h
//  Crowsflight
//
//  Created by Che-Wei Wang on 6/26/13.
//  Copyright (c) 2013 CW&T. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>



@interface cwtAnnotation : NSObject <MKAnnotation>
@property (nonatomic) CLLocationCoordinate2D coordinate;
@property (nonatomic) NSInteger index;

@property (nonatomic, copy) NSString *title, *subtitle;
@end

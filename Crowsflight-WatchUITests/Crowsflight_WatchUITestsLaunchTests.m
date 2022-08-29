//
//  Crowsflight_WatchUITestsLaunchTests.m
//  Crowsflight-WatchUITests
//
//  Created by Che-Wei Wang on 8/29/22.
//  Copyright © 2022 CWandT. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface Crowsflight_WatchUITestsLaunchTests : XCTestCase

@end

@implementation Crowsflight_WatchUITestsLaunchTests

+ (BOOL)runsForEachTargetApplicationUIConfiguration {
    return YES;
}

- (void)setUp {
    self.continueAfterFailure = NO;
}

- (void)testLaunch {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];

    // Insert steps here to perform after app launch but before taking a screenshot,
    // such as logging into a test account or navigating somewhere in the app

    XCTAttachment *attachment = [XCTAttachment attachmentWithScreenshot:XCUIScreen.mainScreen.screenshot];
    attachment.name = @"Launch Screen";
    attachment.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:attachment];
}

@end

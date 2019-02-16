//
//  HBHelperTest.m
//
//  Created by Sven A. Schmidt on 10/06/2018.
//

#import <XCTest/XCTest.h>
#import "HBHelper.h"

@interface HBHelperTest : XCTestCase

@end


@implementation HBHelperTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testCompareMasks {
    int widerMask = kCGEventFlagMaskShift | kCGEventFlagMaskCommand;
    int smallerMask = kCGEventFlagMaskCommand;
    int disjointMask = kCGEventFlagMaskControl | kCGEventFlagMaskSecondaryFn;
    XCTAssertEqual(compareMasks(widerMask, smallerMask), wider);
    XCTAssertEqual(compareMasks(smallerMask, widerMask), smaller);
    XCTAssertEqual(compareMasks(widerMask, widerMask), equal);
    XCTAssertEqual(compareMasks(widerMask, disjointMask), disjoint);
}

@end

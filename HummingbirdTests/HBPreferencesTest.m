#import <XCTest/XCTest.h>
#import "HBPreferences.h"
#import "HummingbirdTests-Swift.h"

@interface HBPreferencesTest : XCTestCase

@end

@implementation HBPreferencesTest {
    NSString *testDefaultsName;
    HBPreferences *preferences;
}

- (void)setUp {
    [super setUp];
    NSString *uuid = [[NSUUID UUID] UUIDString];
    testDefaultsName = [@"co.finestructure.Hummingbird." stringByAppendingString:uuid];
    NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:testDefaultsName];
    preferences = [[HBPreferences alloc] initWithUserDefaults:userDefaults];
}

- (void)tearDown {
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:testDefaultsName];
    [super tearDown];
}

- (void)testResetPreferences {
    [preferences setToDefaults];

    {
        NSSet *flagStringSet = [preferences getFlagStringSetForFlagSet:hoverResizeFlags];
        NSSet *expectedSet = [NSSet setWithArray:@[@"CTRL", @"ALT", @"CMD"]];
        XCTAssertEqualObjects(flagStringSet, expectedSet, "Should contain the expected defaults");
    }

    {
        NSSet *flagStringSet = [preferences getFlagStringSetForFlagSet:hoverMoveFlags];
        NSSet *expectedSet = [NSSet setWithArray:@[@"CTRL", @"ALT"]];
        XCTAssertEqualObjects(flagStringSet, expectedSet, "Should contain the expected defaults");

        [preferences setModifierKey:@"CTRL" enabled:NO flagSet:hoverMoveFlags];
        flagStringSet = [preferences getFlagStringSetForFlagSet:hoverMoveFlags];
        expectedSet = [NSSet setWithArray:@[@"ALT"]];
        XCTAssertEqualObjects(flagStringSet, expectedSet, "Should contain the modified defaults");

        [preferences setToDefaults];
        flagStringSet = [preferences getFlagStringSetForFlagSet:hoverMoveFlags];
        expectedSet = [NSSet setWithArray:@[@"ALT", @"CTRL"]];
        XCTAssertEqualObjects(flagStringSet, expectedSet, "Should contain the restored defaults");
    }
}

- (void)testHSBDefaults {
    [preferences setToDefaults];
    NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:testDefaultsName];
    HBSDefaults* defaults = [[HBSDefaults alloc] initWithDefaults: userDefaults];
//    XCTAssertEqual([defaults move, )
}

@end

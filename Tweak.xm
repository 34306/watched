#import <Foundation/Foundation.h>

@interface watched : NSObject
@end

@implementation watched

- (void)addNewItemsToPlistWithPath:(NSString *)plistPath key:(NSString *)key value:(id)value {
    NSMutableDictionary *plistDictionary = [NSMutableDictionary dictionaryWithContentsOfFile:plistPath];

    if (plistDictionary == nil) {
        NSLog(@"Failed to load plist file at path: %@", plistPath);
        return;
    }

    [plistDictionary setObject:value forKey:key];

    if (![plistDictionary writeToFile:plistPath atomically:YES]) {
        NSLog(@"Failed to write plist file at path: %@", plistPath);
    } else {
        NSLog(@"Successfully added items to plist file: %@", plistPath);
    }
}

@end

%ctor {
    //require respring to apply the tweak working.
    watched *tweak = [[watched alloc] init];

    //first file
    NSString *firstPlistPath = @"/var/mobile/Library/Preferences/com.apple.NanoRegistry.plist";
    [tweak addNewItemsToPlistWithPath:firstPlistPath key:@"minPairingCompatibilityVersion" value:@(1)];
    //if apple update more watchOS, set maxPairingCompatibilityVersion to higher number (example: 9.5.1 around 27 then +2 for each big version, now lastest is 10.3.1 then it's 35~37)
    [tweak addNewItemsToPlistWithPath:firstPlistPath key:@"maxPairingCompatibilityVersion" value:@(37)];
    [tweak addNewItemsToPlistWithPath:firstPlistPath key:@"IOS_PAIRING_EOL_MIN_PAIRING_COMPATIBILITY_VERSION_CHIPIDS" value:@""];
    [tweak addNewItemsToPlistWithPath:firstPlistPath key:@"minPairingCompatibilityVersionWithChipID" value:@(1)];

    //second file
    NSString *secondPlistPath = @"/var/mobile/Library/Preferences/com.apple.pairedsync.plist";
    //maybe the same as the 37
    [tweak addNewItemsToPlistWithPath:secondPlistPath key:@"activityTimeout" value:@(35)];
}

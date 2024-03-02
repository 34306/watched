#import <Foundation/Foundation.h>

@interface MyTweak : NSObject
@end

@implementation MyTweak

- (void)addNewItemsToPlist {
    //plist path
    NSString *plistPath = @"/var/mobile/Library/Preferences/com.apple.NanoRegistry.plist";

    //load
    NSMutableDictionary *plistDictionary = [NSMutableDictionary dictionaryWithContentsOfFile:plistPath];

    if (plistDictionary == nil) {
        NSLog(@"Failed to load plist file at path: %@", plistPath);
        return;
    }

    //some items that help paired
    [plistDictionary setObject:@(1) forKey:@"minPairingCompatibilityVersion"];
    [plistDictionary setObject:@(37) forKey:@"maxPairingCompatibilityVersion"];
    //if apple update more watchOS, set maxPairingCompatibilityVersion to higher number (example: 9.5.1 around 27 then +2 for each big version, now lastest is 10.3.1 then it's 35~37)
    [plistDictionary setObject:@"" forKey:@"IOS_PAIRING_EOL_MIN_PAIRING_COMPATIBILITY_VERSION_CHIPIDS"];
    [plistDictionary setObject:@(1) forKey:@"minPairingCompatibilityVersionWithChipID"];

    //write to the plist
    if (![plistDictionary writeToFile:plistPath atomically:YES]) {
        NSLog(@"Failed to write plist file at path: %@", plistPath);
    } else {
        NSLog(@"Successfully added items to plist file.");
    }
}

@end

%ctor {
    //require respring to apply the tweak working.
    MyTweak *tweak = [[MyTweak alloc] init];
    [tweak addNewItemsToPlist];
}

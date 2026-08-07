#import <Foundation/Foundation.h>
#import <dlfcn.h>
#import <unistd.h>

static const NSInteger kAlignedMajorVersion = 26;
static const NSInteger kWatchOSToIOSOffset = 7;

static const long long kMaxPairingVersion = 999;
static const long long kMinPairingVersion = 1;

static NSString *const kNanoRegistryDomain = @"com.apple.NanoRegistry";
static NSString *const kPairedSyncDomain = @"com.apple.pairedsync";

#pragma mark - Preference method

static BOOL WritePreference(NSString *domain, NSString *key, id value) {
	CFStringRef cfDomain = (__bridge CFStringRef)domain;
	CFStringRef cfKey = (__bridge CFStringRef)key;

	CFPropertyListRef current = CFPreferencesCopyValue(cfKey, cfDomain, CFSTR("mobile"), kCFPreferencesAnyHost);
	BOOL unchanged = current && CFEqual(current, (__bridge CFTypeRef)value);
	if (current) CFRelease(current);
	if (unchanged) return NO;

	CFPreferencesSetValue(cfKey, (__bridge CFPropertyListRef)value, cfDomain, CFSTR("mobile"), kCFPreferencesAnyHost);
	return YES;
}

static void FlushPreferenceCache(NSString *domain) {
	static void (*flush)(CFStringRef, CFStringRef);
	static dispatch_once_t once;
	dispatch_once(&once, ^{
		flush = (void (*)(CFStringRef, CFStringRef))dlsym(RTLD_DEFAULT, "_CFPreferencesFlushCachesForIdentifier");
	});
	if (flush) flush((__bridge CFStringRef)domain, CFSTR("mobile"));
}

static void ApplyPairingPreferences(void) {
	if (geteuid() != 501) return;

	BOOL changed = NO;
	changed |= WritePreference(kNanoRegistryDomain, @"minPairingCompatibilityVersion", @(kMinPairingVersion));
	changed |= WritePreference(kNanoRegistryDomain, @"maxPairingCompatibilityVersion", @(kMaxPairingVersion));
	changed |= WritePreference(kNanoRegistryDomain, @"minPairingCompatibilityVersionWithChipID", @(kMinPairingVersion));
	changed |= WritePreference(kNanoRegistryDomain, @"minQuickSwitchCompatibilityVersion", @(kMinPairingVersion));
	changed |= WritePreference(kNanoRegistryDomain, @"IOS_PAIRING_EOL_MIN_PAIRING_COMPATIBILITY_VERSION_CHIPIDS", @"");

	if (changed) {
		CFPreferencesSynchronize((__bridge CFStringRef)kNanoRegistryDomain, CFSTR("mobile"), kCFPreferencesAnyHost);
		FlushPreferenceCache(kNanoRegistryDomain);
	}

	if (WritePreference(kPairedSyncDomain, @"activityTimeout", @30)) {
		CFPreferencesSynchronize((__bridge CFStringRef)kPairedSyncDomain, CFSTR("mobile"), kCFPreferencesAnyHost);
		FlushPreferenceCache(kPairedSyncDomain);
	}
}

#pragma mark - Runtime method

@interface NRPairingCompatibilityVersionInfo : NSObject
@end

@interface NRDevice : NSObject
- (id)valueForProperty:(id)property;
@end

@interface NRMutableDevice : NRDevice
@end

@interface ACXRemoteApplication : NSObject
@end

static NSString *NanoRegistryPropertyKey(const char *symbol) {
	void *address = dlsym(RTLD_DEFAULT, symbol);
	return address ? *(NSString *__unsafe_unretained *)address : nil;
}

//pair photo stuff
static BOOL DeviceRunsNewerOSThanHost(NRDevice *device) {
	static NSString *marketingKey, *systemKey;
	static dispatch_once_t once;
	dispatch_once(&once, ^{
		marketingKey = NanoRegistryPropertyKey("NRDevicePropertyMarketingVersion");
		systemKey = NanoRegistryPropertyKey("NRDevicePropertySystemVersion");
	});

	id version = marketingKey ? [device valueForProperty:marketingKey] : nil;
	if (![version isKindOfClass:NSString.class] && systemKey) {
		version = [device valueForProperty:systemKey];
	}
	if (![version isKindOfClass:NSString.class]) return NO;

	NSInteger major = [(NSString *)version integerValue];
	if (major <= 0) return NO;
	if (major < kAlignedMajorVersion) major += kWatchOSToIOSOffset;

	return major > NSProcessInfo.processInfo.operatingSystemVersion.majorVersion;
}

%group DeviceCapabilities
%hook NRDevice
- (BOOL)supportsCapability:(id)capability {
	return %orig ?: DeviceRunsNewerOSThanHost(self);
}
%end

%hook NRMutableDevice
- (BOOL)supportsCapability:(id)capability {
	return %orig ?: DeviceRunsNewerOSThanHost(self);
}
%end
%end

%group AppInstall
%hook ACXRemoteApplication
//sync
- (BOOL)isRuntimeCompatibleWithOSVersion:(id)version {
	return YES;
}
%end
%end

%group PairingGate
%hook NRPairingCompatibilityVersionInfo
//fix pair ig
- (long long)maxPairingCompatibilityVersion {
	return kMaxPairingVersion;
}

- (long long)minPairingCompatibilityVersion {
	return kMinPairingVersion;
}

- (long long)minPairingCompatibilityVersionWithChipID {
	return kMinPairingVersion;
}

- (long long)minQuickSwitchCompatibilityVersion {
	return kMinPairingVersion;
}

- (long long)minPairingCompatibilityVersionForChipID:(id)chipID {
	return kMinPairingVersion;
}

- (long long)minPairingCompatibilityVersionForChipID:(id)chipID name:(id)name defaultVersion:(long long)version {
	return kMinPairingVersion;
}

- (long long)minQuickSwitchPairingCompatibilityVersionForChipID:(id)chipID {
	return kMinPairingVersion;
}

- (long long)minPairingCompatibilityVersionForWatchProductType:(id)productType {
	return kMinPairingVersion;
}

- (long long)maxPairingCompatibilityVersionForPhoneProductType:(id)productType {
	return kMaxPairingVersion;
}

- (unsigned long long)pairingCompatibilitySupportStateForAdvertisingWatchVersion:(long long)version {
	return 1;
}
%end
%end

%ctor {
	@autoreleasepool {
		if (NSClassFromString(@"NRPairingCompatibilityVersionInfo")) {
			%init(PairingGate);
		}
		if (NSClassFromString(@"NRDevice")) {
			%init(DeviceCapabilities);
		}
		if (NSClassFromString(@"ACXRemoteApplication")) {
			%init(AppInstall);
		}
		ApplyPairingPreferences();
	}
}

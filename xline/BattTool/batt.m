/*
 File:			GetPrimaryMACAddress.c
 
 Description:	This sample application demonstrates how to do retrieve the Ethernet MAC
 address of the built-in Ethernet interface from the I/O Registry on Mac OS X.
 Techniques shown include finding the primary (built-in) Ethernet interface,
 finding the parent Ethernet controller, and retrieving properties from the
 controller's I/O Registry entry.
 
 
 Change History (most recent first):
 
 <3>	 	09/15/05	Updated to produce a universal binary. Use kIOMasterPortDefault
 instead of older IOMasterPort function. Print the MAC address
 to stdout in response to <rdar://problem/4021220>.
 <2>		04/30/02	Fix bug in creating the matching dictionary that caused the
 kIOPrimaryInterface property to be ignored. Clean up comments and add
 additional comments about how IOServiceGetMatchingServices operates.
 <1>	 	06/07/01	New sample.
 
 */
#import "batt.h"
#import <IOKit/IOKitLib.h>
#import <IOKit/ps/IOPowerSources.h>
#import <IOKit/ps/IOPSKeys.h>
#import <IOKit/pwr_mgt/IOPM.h>
#import <IOKit/pwr_mgt/IOPMLib.h>
//#include <stdlib.h>
//#include <stdio.h>
//#include <sys/types.h>
//#include <sys/sysctl.h>

@implementation batKit
/*
- (NSString*)batName {
	return [_batName copy];
}

- (NSString*)batType {
	return [_batType copy];
}

- (NSString*)batPSState {
	return [_batPSState copy];
}

- (NSString*)batHealth {
	return [_batHealth copy];
}

- (NSString*)batHConfidence {
	return [_batHConfidence copy];
}

- (NSString*)batHCondition {
	return [_batHCondition copy];
}

- (NSArray*)batFailureModes {
	return [_batFailureModes copy];
}

- (NSArray*)batCapacity {
	return [_batCapacity copy];
}

- (NSArray*)batMCapacity {
	return [_batMCapacity copy];
}

- (BOOL)batIsCharging {
	return [_batIsCharging copy];
}

- (BOOL)batIsPresent {
	return [_batIsPresent copy];
}

- (BOOL)batIsACConnected {
	return [_batIsACConnected copy];
}

- (BOOL)requestValues {
    CFTypeRef powerInfo = IOPSCopyPowerSourcesInfo();
    if(!powerInfo) return FALSE;
    
    CFArrayRef sources = IOPSCopyPowerSourcesList(powerInfo);
    if(!sources) {
        CFRelease(powerInfo);
        CFRelease(sources);
        return FALSE;
    }
    
    // Should only get one source. But in practice, check for > 0 sources
    if (CFArrayGetCount(sources))
    {
        CFDictionaryRef pSource = IOPSGetPowerSourceDescription(powerInfo, CFArrayGetValueAtIndex(sources, 0));
        
        CFRelease(powerInfo);
        CFRelease(sources);
        
        const void *psValue;
        const void *bVal;
        const void *state;
        
        if (CFDictionaryGetValueIfPresent(pSource, CFSTR(kIOPSNameKey), &psValue)) {
            _batName = (__bridge NSString *)psValue;
        }
        else {
            _batName = @"-";
        }
        
        if (CFDictionaryGetValueIfPresent(pSource, CFSTR(kIOPSTypeKey), &psValue)) {
            _batType = (__bridge NSString *)psValue;
        }
        else {
            _batType = @"-";
        }
        if (CFDictionaryGetValueIfPresent(pSource, CFSTR(kIOPSPowerSourceStateKey), &psValue)) {
            _batPSState = (__bridge NSString *)(psValue);
            state = (__bridge const void *)((__bridge NSString *)psValue);
        }
        else {
            _batPSState = @"-";
        }
        
        if (CFDictionaryGetValueIfPresent(pSource, CFSTR(kIOPSHardwareSerialNumberKey), &psValue)) {
            _batHSNumber = (__bridge NSString *)psValue;
        }
        else {
            _batHSNumber = @"-";
        }
        
        if (CFDictionaryGetValueIfPresent(pSource, CFSTR(kIOPSBatteryHealthKey), &psValue)) {
            _batHealth = (__bridge NSString *)psValue;
        }
        else {
            _batHealth = @"-";
        }
        
        if (CFDictionaryGetValueIfPresent(pSource, CFSTR(kIOPSHealthConfidenceKey), &psValue)) {
            _batHConfidence = (__bridge NSString *)psValue;
        }
        else {
            _batHConfidence = @"-";
        }
        
        if (CFDictionaryGetValueIfPresent(pSource, CFSTR(kIOPSBatteryHealthConditionKey), &psValue)) {
            _batHCondition = (__bridge NSString *)psValue;
        }
        else {
            _batHCondition = @"-";
        }
        
        if (CFDictionaryGetValueIfPresent(pSource, CFSTR(kIOPSBatteryFailureModesKey), &psValue)) {
            _batFailureModes = (__bridge NSArray *)psValue;
        }
        else {
            _batFailureModes = [NSMutableArray array];
        }
        
        if (CFDictionaryGetValueIfPresent(pSource, CFSTR(kIOPSVoltageKey), &psValue)) {
            _batVoltage = (__bridge NSNumber *)psValue;
        }
        else {
            _batVoltage = 0;
        }
        
        if (CFDictionaryGetValueIfPresent(pSource, CFSTR(kIOPSCurrentCapacityKey), &psValue)) {
            CFNumberGetValue((CFNumberRef)psValue, kCFNumberSInt32Type, &_batCapacity);
        }
        
        if (CFDictionaryGetValueIfPresent(pSource, CFSTR(kIOPSMaxCapacityKey), &psValue)) {
            CFNumberGetValue((CFNumberRef)psValue, kCFNumberSInt32Type, &_batMCapacity);
        }
        
        if ((CFDictionaryGetValueIfPresent(pSource, CFSTR(kIOPSIsChargingKey), &bVal)) && (bVal == kCFBooleanTrue)) {
            _batIsCharging = TRUE;
        }
        else {
            _batIsCharging = FALSE;
        }
        
        if (STRMATCH(state, CFSTR(kIOPSACPowerValue))) {
            _batIsACConnected = TRUE;
        }
        else {
            _batIsACConnected = FALSE;
        }
 
        return TRUE;
    }
    
    CFRelease(powerInfo);
    CFRelease(sources);
    return FALSE;
    
}

-(NSString *) machineModel
{
    size_t len = 0;
    sysctlbyname("hw.model", NULL, &len, NULL, 0);
    
    if (len)
    {
        char *model = malloc(len*sizeof(char));
        sysctlbyname("hw.model", model, &len, NULL, 0);
        NSString *model_ns = [NSString stringWithUTF8String:model];
        free(model);
        return model_ns;
    }
    
    return @"Just an Apple Computer"; //incase model name can't be read
}
*/
- (NSNumber *) batVoltage
{
    NSDictionary *advancedBatteryInfo = [self getAdvancedBatteryInfo];
    //NSDictionary *moreAdvancedBatteryInfo = [self getMoreAdvancedBatteryInfo];
    //NSNumber *Voltage =
    _batVoltage = [advancedBatteryInfo objectForKey:@"Voltage"]; //units mV
    return _batVoltage;
}

- (NSNumber *) batCurrentAmperage
{
    NSDictionary *advancedBatteryInfo = [self getAdvancedBatteryInfo];
    //NSDictionary *moreAdvancedBatteryInfo = [self getMoreAdvancedBatteryInfo];
    //NSNumber *Voltage =
    _batCurrentAmperage = [advancedBatteryInfo objectForKey:@"Current"]; //units mAh
    return _batCurrentAmperage;
}

- (NSNumber *) batMaxCapacity
{
    NSDictionary *advancedBatteryInfo = [self getAdvancedBatteryInfo];
    //NSDictionary *moreAdvancedBatteryInfo = [self getMoreAdvancedBatteryInfo];
    //NSNumber *Voltage =
    _batMaxCapacity = [advancedBatteryInfo objectForKey:@"Capacity"]; //units mAh
    return _batMaxCapacity;
}

- (NSNumber *) batDesignCapacity
{
    NSDictionary *advancedBatteryInfo = [self getAdvancedBatteryInfo];
    //NSDictionary *moreAdvancedBatteryInfo = [self getMoreAdvancedBatteryInfo];
    //NSNumber *Voltage =
    _batDesignCapacity = [advancedBatteryInfo objectForKey:@"DesignCapacity"]; //units mAh
    return _batDesignCapacity;
}

- (NSNumber *) batCycleCount
{
    NSDictionary *moreAdvancedBatteryInfo = [self getMoreAdvancedBatteryInfo];
    //NSDictionary *moreAdvancedBatteryInfo = [self getMoreAdvancedBatteryInfo];
    //NSNumber *Voltage =
    _batCycleCount = [moreAdvancedBatteryInfo objectForKey:@"CycleCount"];
    return _batCycleCount;
}

- (NSNumber *) batDesignCycleCount
{
    NSDictionary *moreAdvancedBatteryInfo = [self getMoreAdvancedBatteryInfo];
    //NSDictionary *moreAdvancedBatteryInfo = [self getMoreAdvancedBatteryInfo];
    //NSNumber *Voltage =
    _batDesignCycleCount = [moreAdvancedBatteryInfo objectForKey:@"DesignCycleCount9C"];
    return _batDesignCycleCount;
}

- (NSNumber *) batWatts
{
    NSDictionary *advancedBatteryInfo = [self getAdvancedBatteryInfo];
    //NSNumber *Voltage =
    _batWatts = [NSNumber numberWithDouble:[[advancedBatteryInfo objectForKey:@"Amperage"] doubleValue] / 1000 * [_batVoltage doubleValue] / 1000]; //units Wh
    return _batWatts;
}

- (NSNumber *) batTemperature
{
    NSDictionary *moreAdvancedBatteryInfo = [self getMoreAdvancedBatteryInfo];
    //NSDictionary *moreAdvancedBatteryInfo = [self getMoreAdvancedBatteryInfo];
    //NSNumber *Voltage =
    _batTemperature = [NSNumber numberWithDouble:[[moreAdvancedBatteryInfo objectForKey:@"Temperature"] doubleValue] / 100]; //unit Celsiuses
    return _batTemperature;
}

- (NSString *) batHSNumber
{
    NSDictionary *moreAdvancedBatteryInfo = [self getMoreAdvancedBatteryInfo];
    //NSDictionary *moreAdvancedBatteryInfo = [self getMoreAdvancedBatteryInfo];
    //NSNumber *Voltage =
    _batHSNumber = [moreAdvancedBatteryInfo objectForKey:@"BatterySerialNumber"];
    return _batHSNumber;
}

- (NSString *) batName
{
    NSDictionary *moreAdvancedBatteryInfo = [self getMoreAdvancedBatteryInfo];
    //NSDictionary *moreAdvancedBatteryInfo = [self getMoreAdvancedBatteryInfo];
    //NSNumber *Voltage =
    _batName = [moreAdvancedBatteryInfo objectForKey:@"DeviceName"];
    return _batName;
}

- (NSString *) batManufacturer
{
    NSDictionary *moreAdvancedBatteryInfo = [self getMoreAdvancedBatteryInfo];
    //NSDictionary *moreAdvancedBatteryInfo = [self getMoreAdvancedBatteryInfo];
    //NSNumber *Voltage =
    _batManufacturer = [moreAdvancedBatteryInfo objectForKey:@"Manufacturer"];
    return _batManufacturer;
}

- (NSDate *) batManufactureDate
{
    NSDictionary *moreAdvancedBatteryInfo = [self getMoreAdvancedBatteryInfo];
    unsigned int state = [[moreAdvancedBatteryInfo objectForKey:@"ManufactureDate"] intValue];
    
    NSDateComponents* manufactureDateComponents = [[NSDateComponents alloc]init];
    manufactureDateComponents.year = (state >> 9) + 1980;
    manufactureDateComponents.month = (state >> 5) & 0xF;
    manufactureDateComponents.day = state & 0x1F;
    _batManufactureDate = [[NSCalendar currentCalendar] dateFromComponents:manufactureDateComponents];
    return _batManufactureDate;
}

- (NSNumber *) batTimeRemaining
{
    NSDictionary *moreAdvancedBatteryInfo = [self getMoreAdvancedBatteryInfo];
    _batTimeRemaining = [moreAdvancedBatteryInfo objectForKey:@"AvgTimeToEmpty"];
    return _batTimeRemaining;
}


- (NSNumber *) batIsPresent
{
    NSDictionary *moreAdvancedBatteryInfo = [self getMoreAdvancedBatteryInfo];
    _batIsPresent = [moreAdvancedBatteryInfo objectForKey:@"BatteryInstalled"];
    return _batIsPresent;
}

- (NSNumber *) batIsFull
{
    NSDictionary *moreAdvancedBatteryInfo = [self getMoreAdvancedBatteryInfo];
    _batIsFull = [moreAdvancedBatteryInfo objectForKey:@"FullyCharged"];
    return _batIsFull;
}

- (NSNumber *) batIsCharging
{
    NSDictionary *moreAdvancedBatteryInfo = [self getMoreAdvancedBatteryInfo];
    _batIsCharging = [moreAdvancedBatteryInfo objectForKey:@"IsCharging"];
    return _batIsCharging;
}

- (NSNumber *) batIsACConnected
{
    NSDictionary *moreAdvancedBatteryInfo = [self getMoreAdvancedBatteryInfo];
    _batIsACConnected = [moreAdvancedBatteryInfo objectForKey:@"ExternalConnected"];
    return _batIsACConnected;
}

- (NSDictionary *)getAdvancedBatteryInfo
{
    mach_port_t masterPort;
    CFArrayRef batteryInfo;
    
    if (kIOReturnSuccess == IOMasterPort(MACH_PORT_NULL, &masterPort) &&
        kIOReturnSuccess == IOPMCopyBatteryInfo(masterPort, &batteryInfo))
    {
        return [(__bridge NSArray*)batteryInfo objectAtIndex:0];
    }
    return nil;
}

- (NSDictionary *)getMoreAdvancedBatteryInfo
{
    CFMutableDictionaryRef matching, properties = NULL;
    io_registry_entry_t entry = 0;
    // same as matching = IOServiceMatching("IOPMPowerSource");
    matching = IOServiceNameMatching("AppleSmartBattery");
    entry = IOServiceGetMatchingService(kIOMasterPortDefault, matching);
    IORegistryEntryCreateCFProperties(entry, &properties, NULL, 0);
    return (__bridge NSDictionary *)properties;
    //IOObjectRelease(entry);
}

@end
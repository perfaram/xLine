//
//  main.m
//  xLine
//
//  Created by Perceval FARAMAZ on 03.10.14.
//  Copyright (c) 2014 Perceval <perfaram> Faramaz. All rights reserved.
//

#import <Foundation/Foundation.h>

// main.m
#import "BRLOptionParser.h"
#import "smc.h"
//#import "batkit/batkit/batkit.h"
#import <sys/sysctl.h>

void IFPrint (NSString *format, ...) {
    va_list args;
    va_start(args, format);
    
    fputs([[[NSString alloc] initWithFormat:format arguments:args] UTF8String], stdout);
    
    va_end(args);
}

NSString* machineModel() {
    size_t len = 0;
    sysctlbyname("hw.model", NULL, &len, NULL, 0);
    if (len) {
        char *model = malloc(len*sizeof(char));
        sysctlbyname("hw.model", model, &len, NULL, 0);
        NSString *model_ns = [NSString stringWithUTF8String:model];
        free(model);
        return model_ns;
    }
    return nil; //incase model name can't be read
}

NSDictionary* getSMCInfo() {
    CFMutableDictionaryRef matching, properties = NULL;
    io_registry_entry_t entry = 0;
    matching = IOServiceNameMatching("AppleSMC");
    entry = IOServiceGetMatchingService(kIOMasterPortDefault, matching);
    IORegistryEntryCreateCFProperties(entry, &properties, NULL, 0);
    return (__bridge NSDictionary *)properties;
    //IOObjectRelease(entry);
}

NSString* getSMCVer() {
    CFMutableDictionaryRef matching, properties = NULL;
    io_registry_entry_t entry = 0;
    matching = IOServiceNameMatching("AppleSMC");
    entry = IOServiceGetMatchingService(kIOMasterPortDefault, matching);
    IORegistryEntryCreateCFProperties(entry, &properties, NULL, 0);
    NSDictionary *smcProps = (__bridge NSDictionary *)properties;
    IOObjectRelease(entry);
    //NSDictionary *moreAdvancedBatteryInfo = [self getMoreAdvancedBatteryInfo];
    //NSNumber *Voltage =
    //NSString *SMCVer = [smcProps objectForKey:@"smc-version"];
    return [smcProps objectForKey:@"smc-version"];
}

int main(int argc, const char * argv[])
{
    @autoreleasepool {
        NSString *name = @"world";
        NSString *probe = @"";
        NSString *batterySelector= @"";
        NSString *smc= @"";
        //NSString *smcW= @"";
        NSString *fan= @"";
        NSString *sil= @"";
        NSString *platform= @"";
        NSString *dump= @"";
        BOOL raw = NO;
        BOOL convert = NO;
        BOOL type = NO;
        BOOL fandata = NO;
        BOOL verbose = NO;
        
        BRLOptionParser *options = [BRLOptionParser new];
        [options addSeparator:@"==Options=="];
        [options addOption:"temp" flag:'t' description:@"Prints the specified component's temperature. Use [-t help] to know which info you can request." argument:&probe];
        [options addOption:"battery" flag:'b' description:@"Prints the specified battery info. Use [-b help] to know which info you can request." argument:&batterySelector];
        [options addOption:"smcRead" flag:'r' description:@"Useful to make raw SMC requests. For example : xline -s X (X = SMC key) will return raw SMC data (in hex) and its type. See SWITCHES section to get all this formatted." argument:&smc];
        //[options addOption:"smcWrite" flag:'w' description:@"Used to write data to SMC. Be careful, it could disturb it (you'll have to reinitialise it) - or even worse... For example : xline -S X Y (X = SMC key, Y = Value) " argument:&smcW];
        [options addOption:"platform" flag:'p' description:@"Getting computer info, such as device (eg MacBookPro8,1). To get more info, [-p help]." argument:&platform];
        [options addOption:"SIL" flag:'S' description:@"Setting SIL (the led that sits on your MacBook's front) state. [-S 1] is on, [-S 0] is off, [-S breathe] makes it breathe like when the MacBook is sleeping." argument:&sil];
        [options addOption:"fan" flag:'f' description:@"Prints the specified fan's data. Use [-f help] to get examples." argument:&fan];
        //[options addOption:"dump" flag:'d' description:@"Dumps everything to a ZIP archive, containing different files. See [-d help] to know more." argument:&dump];
        [options addSeparator:@"Switches"];
        [options addOption:"raw" flag:'R' description:@"Combine with -s. Shows raw data (hex)" value:&raw];
        [options addOption:"type" flag:'T' description:@"Combine with -s. Shows only the requested key's type (eg SP78)" value:&type];
        [options addOption:"convert" flag:'C' description:@"Combine with -s. Shows converted data (bytes 41e0 [SP78] => ~65.625 [°C]) without any text" value:&convert];
        [options addOption:"fandata" flag:'D' description:@"Combine with -f. Shows fan parameters in a comma-separated list style. Use [-f help] to get examples." value:&fandata];
        [options addOption:"verbose" flag:'v' description:nil value:&verbose];
        __weak typeof(options) weakOptions = options;
        [options addOption:"help" flag:'h' description:@"Show this message" block:^{
            printf("%s", [[weakOptions description] UTF8String]);
            exit(EXIT_SUCCESS);
        }];
        
        NSError *error = nil;
        if (![options parseArgc:argc argv:argv error:&error]) {
            const char * message = [[error localizedDescription] UTF8String];
            fprintf(stderr, "%s: %s\n", argv[0], message);
            exit(EXIT_FAILURE);
        }
        
        if (![probe isEqualToString:@""]) {
            char *probeKey;
            if ([probe caseInsensitiveCompare:@"CPU"]== NSOrderedSame )
                probeKey = "TC0P";
            else if ([probe caseInsensitiveCompare:@"CPUD"]== NSOrderedSame )
                probeKey = "TC0D";
            else if ([probe caseInsensitiveCompare:@"CPUH"]== NSOrderedSame )
                probeKey = "TC0H";
            else if ([probe caseInsensitiveCompare:@"GPU"]== NSOrderedSame )
                probeKey = "TG0P";
            else if ([probe caseInsensitiveCompare:@"GPUD"]== NSOrderedSame )
                probeKey = "TG0D";
            else if ([probe caseInsensitiveCompare:@"GPUH"]== NSOrderedSame )
                probeKey = "TG0H";
            else if ([probe caseInsensitiveCompare:@"PALM"]== NSOrderedSame )
                probeKey = "Ts0P";
            else if ([probe caseInsensitiveCompare:@"POWER"]== NSOrderedSame )//battery charger prox (FUCK HERE, Tm0P/Tp0P/Tp0C)
                probeKey = "Ts0S";
            else if ([probe caseInsensitiveCompare:@"BAT3"]== NSOrderedSame ) // battery pos 3
                probeKey = "TB2T";
            else if ([probe caseInsensitiveCompare:@"BAT2"]== NSOrderedSame ) // battery pos 2
                probeKey = "TB1T";
            else if ([probe caseInsensitiveCompare:@"BAT1"]== NSOrderedSame ) // battery pos 1
                probeKey = "TB0T";
            else if ([probe caseInsensitiveCompare:@"WHATSTHAT"]== NSOrderedSame ) //BPIT, TC0F, BRIT, TPCD
                probeKey = "WHAT";
            else if ([probe caseInsensitiveCompare:@"PCHD"]== NSOrderedSame )
                probeKey = "TPCD";
            else if ([probe caseInsensitiveCompare:@"PCH"]== NSOrderedSame )
                probeKey = "TP0P";
            else if ([probe caseInsensitiveCompare:@"MEM1"]== NSOrderedSame )
                probeKey = "TM0S";
            else if ([probe caseInsensitiveCompare:@"MEM2"]== NSOrderedSame ) // ACTUALLY MEM PROX
                probeKey = "TM0P";
            else if ([probe caseInsensitiveCompare:@"LCD"]== NSOrderedSame )
                probeKey = "TL0P";
            else if ([probe caseInsensitiveCompare:@"AIR"]== NSOrderedSame )
                probeKey = "TW0P";
            else if ([probe caseInsensitiveCompare:@"help"]== NSOrderedSame ) {
                printf("Here's what you can request with -t : \n- CPU \n- CPUH : CPU Heatsink\n- CPUD : CPU Die\n- GPU\n- GPUH : GPU Heatsink\n- GPUD : GPU Die\n- PALM : Left palm rest\n- POWER : Battery charger proximity\n- BAT3 : Battery, position 3\n- BAT2 : Battery, position 2\n- BAT1 : Battery, position 1\n- PCHD : Platform Controller Hub\n- PCH : Power Supply Proximity\n- MEM1 : RAM\n- MEM2 : RAM proximity\n- LCD : Screen\n- AIR : Airport\nIf something returns 0, don't worry, as it just means that there is no such part within your computer !\n");
                exit(EXIT_FAILURE);
            } else {
                printf("E02 Unknown component\n");
                exit(EXIT_FAILURE);
            }
            double temp;
            kern_return_t result;
            result= SMCGetTemperature(probeKey, &temp);
            //IFPrint(@"%f", temp);
            printf("%f °C\n", temp);//[probe UTF8String]);
            exit(EXIT_SUCCESS);
        };
        
        if (![platform isEqualToString:@""]) {
            //char *plKey;
            if ([platform caseInsensitiveCompare:@"deviceID"]== NSOrderedSame ) {
                IFPrint(machineModel());
                printf("\n");
                exit(EXIT_SUCCESS);
            } else if ([platform caseInsensitiveCompare:@"platform"]== NSOrderedSame ) {
                kern_return_t result;
                SMCVal_t val;
                SMCOpen();
                result= SMCReadKey("RPlt", &val);
                if (result != kIOReturnSuccess) {
                    printf("E10 SMC transaction failed with error %08x\n", result);
                    SMCClose();
                    exit(EXIT_FAILURE);
                } else {
                    printConvVal(val);
                    printf("\n");
                    SMCClose();
                    exit(EXIT_SUCCESS);
                }
            } else if ([platform caseInsensitiveCompare:@"smcver"]== NSOrderedSame) {
                IFPrint(getSMCVer());
                exit(EXIT_SUCCESS);
            } else if ([probe caseInsensitiveCompare:@"help"]== NSOrderedSame ) {
                printf("You can request : \n- device : Device ID (eg MacBookPro8,1)\n- platform : Platform string (eg k90i)\n- SMCver : SMC version.");
                exit(EXIT_FAILURE);
            } else {
                printf("E02 Unknown key\n");
                exit(EXIT_FAILURE);
            }
        }
        
        if (![fan isEqualToString:@""]) {
            if ([fan caseInsensitiveCompare:@"help"]== NSOrderedSame) {
                printf("Example : \n[xline -f all] to get all fans infos\n[xline -f 0] to get fan O infos\n[xline -f 0 -D] to get a comma-separated list of fan 0 infos (e.g=A,B,C,D,E,F with A=Current fan RPM, B=minimum RPM, C=maximum RPM, D=Safe speed, E=Target speed, F=Fan mode. If you do not provide a fan ID but ask for a comma-sep. list, you'll get #X,A,B,C,D,E,F with #X=fan ID)\n");
                exit(EXIT_FAILURE);
            } else if ([fan caseInsensitiveCompare:@"all"]== NSOrderedSame) {
                
            }
            
            kern_return_t result;
            int fanNum = 0;
            
            NSNumberFormatter *fanNm = [[NSNumberFormatter alloc] init];
            [fanNm setNumberStyle:NSNumberFormatterDecimalStyle];
            NSNumber *fanIDn = [fanNm numberFromString:fan];
            
            if (fanIDn != nil) {
                fanNum=[fanIDn intValue];
            } else if (fanIDn == nil) {
                fanNum=-1;
            } else {
                printf("E01 Incorrect parameter");
                exit(EXIT_FAILURE);
            }
            
            if (fandata) {
                result = SMCPrintFansAsCSL(fanNum);
            } else {
                result = SMCPrintFans(fanNum);
            }
            if (result != kIOReturnSuccess) {
                printf("E10 SMC transaction failed with error %08x\n", result);
                exit(EXIT_FAILURE);
            } else {
                exit(EXIT_SUCCESS);
            }
        }
        
        if (![smc isEqualToString:@""]) {
            char *smcKey = (char*)[smc UTF8String];
            SMCOpen();
            kern_return_t result;
            SMCVal_t val;
            result = SMCReadKey(smcKey, &val);
            if (result != kIOReturnSuccess) {
                printf("E10 SMC transaction failed with error %08x\n", result);
                exit(EXIT_FAILURE);
            } else {
                if (raw) {
                    printRawVal(val);
                    printf("\n");
                }
                else if (convert) {
                    printConvVal(val);
                }
                else if (type) {
                    printValType(val);
                }
                else {
                    printVal(val);
                };
            };
            SMCClose();
            exit(EXIT_SUCCESS);
        }
        
        
        printf("%s", [[weakOptions description] UTF8String]);
    }
    
    return EXIT_SUCCESS;
}

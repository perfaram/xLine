//
//  main.m
//  xLine
//
//  Created by Perceval FARAMAZ on 03.10.14.
//  Copyright (c) 2014 perfaram. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BRLOptionParser/BRLOptionParser.h"
#import "SMCTool/smc.h"
//#import "BattTool/batt.h"
#import "batkit/batkit/batkit.h"
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
        
        BRLOptionParser *options = [BRLOptionParser new];
        //[options setBanner:@"usage: %s [-t <probe>] [-b <key>]", argv[0]];
        [options addSeparator:@"Options"];
        [options addOption:"temp" flag:'t' description:@"Prints the specified component's temperature. Use [-t help] to know which info you can request." argument:&probe];
        [options addOption:"battery" flag:'b' description:@"Prints the specified battery info. Use [-b help] to know which info you can request." argument:&batterySelector];
        [options addOption:"smcRead" flag:'r' description:@"Useful to make raw SMC requests. For example : xline -s X (X = SMC key) will return raw SMC data (in hex) and its type. See SWITCHES section to get all this formatted." argument:&smc];
        //[options addOption:"smcWrite" flag:'w' description:@"Used to write data to SMC. Be careful, it could disturb it (you'll have to reinitialise it) - or even worse... For example : xline -S X Y (X = SMC key, Y = Value) " argument:&smcW];
        [options addOption:"platform" flag:'p' description:@"Getting computer info, such as device (eg MacBookPro8,1). To get more info, [-p help]." argument:&platform];
        [options addOption:"SIL" flag:'S' description:@"Setting SIL (the led that sits on your MacBook's front) state. [-S 1] is on, [-S 0] is off, [-S breathe] makes it breathe like when the MacBook is sleeping." argument:&sil];
        [options addOption:"fan" flag:'f' description:@"Prints the specified fan's data. Use [-f help] to get examples." argument:&fan];
        [options addOption:"dump" flag:'d' description:@"Dumps everything to a ZIP archive, containing different files. See [-d help] to know more." argument:&dump];
        [options addSeparator:@"Switches"];
        [options addOption:"raw" flag:'R' description:@"Combine with -s. Shows raw data (hex)" value:&raw];
        [options addOption:"type" flag:'T' description:@"Combine with -s. Shows only the requested key's type (eg SP78)" value:&type];
        [options addOption:"convert" flag:'C' description:@"Combine with -s. Shows converted data (bytes 41e0 [SP78] => ~65.625 [°C]) without any text" value:&convert];
        [options addOption:"fandata" flag:'D' description:@"Combine with -f. Shows fan parameters in a comma-separated list style. Use [-f help] to get examples." value:&fandata];
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
        
        if ((raw && (convert || type) || (convert && type))) { //for sure there's a more efficient way of doing this
            printf("E03 Printed data cannot be raw AND converted ! Use --help to get rescued.\n");
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
                    exit(EXIT_SUCCESS);
            } else {
                printf("E02 Unknown component\n");
                exit(EXIT_FAILURE);
            }
            double temp;
            kern_return_t result;
            result= SMCGetTemperature(probeKey, &temp);
            //IFPrint(@"%f", temp);
            printf("%f\n", temp);//[probe UTF8String]);
            exit(EXIT_SUCCESS);
        }
        
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
                exit(EXIT_SUCCESS);
            } else {
                printf("E02 Unknown key\n");
                exit(EXIT_FAILURE);
            }
        }
        
        if (![fan isEqualToString:@""]) {
            if ([fan caseInsensitiveCompare:@"help"]== NSOrderedSame) {
                printf("Example : \n[xline -f] to get all fans infos\n[xline -f 0] to get fan O infos\n[xline -f 0 -D] to get a comma-separated list of fan 0 infos (e.g=A,B,C,D,E,F with A=Current fan RPM, B=minimum RPM, C=maximum RPM, D=Safe speed, E=Target speed, F=Fan mode. If you do not provide a fan ID but ask for a comma-sep. list, you'll get #X,A,B,C,D,E,F with #X=fan ID)\n");
                exit(EXIT_SUCCESS);
            }
            
            kern_return_t result;
            int fanNum;
            
            NSNumberFormatter *fanNm = [[NSNumberFormatter alloc] init];
            [fanNm setNumberStyle:NSNumberFormatterDecimalStyle];
            NSNumber *fanIDn = [fanNm numberFromString:fan];
            
            if (fanIDn != nil) {
                fanNum=[fanIDn intValue];
            } else if (fanIDn == nil) {
                fanNum=-1;
            } else {
                printf("E01 Incorrect parameter");
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
        
        if (![sil isEqualToString:@""]) {
            SMCOpen();
            char *state;
            char *silKey;
            if ([sil isEqual:@"1"]) {
                state = "01";
                silKey = "LSOO";
            } else if ([sil isEqual:@"0"]){
                state = "";
                silKey = "LSOO";
            } else if ([sil isEqual:@"breathe"]){
                state = "020101";
                silKey = "LSSB";
                printf("Good choice. Seeing your SIL breathing is always a relaxing experience.\n");
            /*} else if ([sil isEqual:@"blink"]){
                printf("Tic-toc-tic-toc-tic-toc-BOOOM. I hope this won't happen to your Macintosh.\n");
                SMCBlink();
                SMCClose();
                exit(EXIT_SUCCESS);*/
            } else {
                printf("GRATS ! You broke it. Get rescued calling xline -h");
                SMCClose();
                exit(EXIT_FAILURE);
            }
            SMCVal_t      val;
            kern_return_t result;
            UInt32Char_t  key = "\0";
            snprintf(key, 5, "%s", silKey);
            {
                int i, j, k1, k2;
                char c;
				char* p = state; j=0; i=0;
				while (i < strlen(state))
                {
					c = *p++; k1=k2=0; i++;
					/*if (c=' ') {
                     c = *p++; i++;
                     }*/
					if ((c >= '0') && (c<='9')) {
						k1=c-'0';
					} else if ((c >='a') && (c<='f')) {
						k1=c-'a'+10;
					}
					c = *p++; i++;
					/*if (c=' ') {
                     c = *p++; i++;
                     }*/
					if ((c >= '0') && (c<='9')) {
						k2=c-'0';
					} else if ((c >= 'a') && (c<='f')) {
						k2=c-'a'+10;
					}
					
                    //snprintf(c, 2, "%c%c", optarg[i * 2], optarg[(i * 2) + 1]);
                    val.bytes[j++] = (int)(((k1&0xf)<<4) + (k2&0xf));
                }
                val.dataSize = j;
                /*if ((val.dataSize * 2) != strlen(optarg)) {
                 printf("Error: value is not valid\n");
                 return 1;
                 }*/
            }
            //val.dataType = SMCGetValType("LSOO");
            if (strlen(key) > 0) {
                snprintf(val.key, 5, "%s", key);
                result = SMCWriteKey(val);
                if (result != kIOReturnSuccess)
                    printf("E10 SMC transaction failed with error %08x\n", result);
            }
            //printVal(val);
            //SMCBlink();
            SMCClose();
            exit(EXIT_SUCCESS);
        }
        
        if (![dump isEqualToString:@""]) {
            if ([dump caseInsensitiveCompare:@"help"]== NSOrderedSame ) {
                printf("Here's what will be in your dump : \n- Dumps IOReg to Apple's proprietary format\n- Kexts list to kxlist (just a plist, really)\n- SMC keys to smcdump (plist again!)\n- Hardware data to SPX (plist...)\nNote that dumping can take some time.");
                exit(EXIT_SUCCESS);
            } else if ([dump caseInsensitiveCompare:@"quick"]== NSOrderedSame ){
            IFPrint(@"Now dumping\n");
            exit(EXIT_SUCCESS);
            } else {
            IFPrint(@"Now dumping\n");
            //DoProgress("Dumping", 37, 100);
            exit(EXIT_FAILURE);
            }
        }
    
        if (![batterySelector isEqualToString:@""]) {
            id batteryKit = [batKit alloc];
            if ([batterySelector caseInsensitiveCompare:@"voltage"]== NSOrderedSame )
                IFPrint(@"%@\n", [batteryKit batVoltage]);
            else if ([batterySelector caseInsensitiveCompare:@"cyclecount"]== NSOrderedSame )
                IFPrint(@"%@\n", [batteryKit batCycleCount]);
            else if ([batterySelector caseInsensitiveCompare:@"designcyclecount"]== NSOrderedSame )
                IFPrint(@"%@\n", [batteryKit batDesignCycleCount]);
            else if ([batterySelector caseInsensitiveCompare:@"serialnumber"]== NSOrderedSame )
                IFPrint(@"%@\n", [batteryKit batHSNumber]);
            else if ([batterySelector caseInsensitiveCompare:@"ispresent"]== NSOrderedSame )
                IFPrint(@"%@\n", [batteryKit batIsPresent]);
            else if ([batterySelector caseInsensitiveCompare:@"isfull"]== NSOrderedSame )
                IFPrint(@"%@\n", [batteryKit batIsFull]);
            else if ([batterySelector caseInsensitiveCompare:@"ischarging"]== NSOrderedSame )
                IFPrint(@"%@\n", [batteryKit batIsCharging]);
            else if ([batterySelector caseInsensitiveCompare:@"manufacturer"]== NSOrderedSame )
                IFPrint(@"%@\n", [batteryKit batManufacturer]);
            else if ([batterySelector caseInsensitiveCompare:@"manufacturedate"]== NSOrderedSame )
                IFPrint(@"%@\n", [batteryKit batManufactureDate]);
            else if ([batterySelector caseInsensitiveCompare:@"timeremaining"]== NSOrderedSame )
                IFPrint(@"%@\n", [batteryKit batTimeRemaining]);
            else if ([batterySelector caseInsensitiveCompare:@"isAC"]== NSOrderedSame )
                IFPrint(@"%@\n", [batteryKit batIsACConnected]);
            else if ([batterySelector caseInsensitiveCompare:@"power"]== NSOrderedSame )
                IFPrint(@"%@\n", [batteryKit batWatts]);
            else if ([batterySelector caseInsensitiveCompare:@"amperage"]== NSOrderedSame )
                IFPrint(@"%@\n", [batteryKit batCurrentAmperage]);
            else if ([batterySelector caseInsensitiveCompare:@"maxcapacity"]== NSOrderedSame )
                IFPrint(@"%@\n", [batteryKit batMaxCapacity]);
            else if ([batterySelector caseInsensitiveCompare:@"designcapacity"]== NSOrderedSame )
                IFPrint(@"%@\n", [batteryKit batDesignCapacity]);
            else if ([batterySelector caseInsensitiveCompare:@"temperature"]== NSOrderedSame )
                IFPrint(@"%@\n", [batteryKit batTemperature]);
            else if ([batterySelector caseInsensitiveCompare:@"help"]== NSOrderedSame ) {
                printf("Here's what you can request with -b : \n- Voltage : Prints battery's current voltage \n- CycleCount : Battery's current count of charge/discharge cycle\n- DesignCycleCount : Battery's designed (planned) cycle count \n- SerialNumber : Self-explanatory, hmmm? \n- Power : Battery's current power in Wh \n- Temperature : Battery's temperature in °Celsius \n- Amperage : Battery's current amperage in mA \n- MaxCapacity : Battery's maximum capacity in mA \n- DesignCapacity : Battery's designed (planned) capacity in mA \n- Manufacturer : Self-explanatory... \n- ManufactureDate : U silly, bro? \n- TimeRemaining : The number of minutes before you run out of juice \n- isAC : Is your computer currently connected to an external power source ? \n- isFull : Is your battery currently full ? \n- isCharging : Is your battery currently being recharged ? \n- IsPresent : Is there a battery connected to this computer (if not, all other requests will return empty values, except isAC)\n");
                exit(EXIT_SUCCESS);
            } else {
                IFPrint(@"E02 Unknown component\n");
                exit(EXIT_FAILURE);
            }
            exit(EXIT_SUCCESS);
        }
}
}

/*
 //SMCOpen();
 double temp = SMCGetTemperature(SMC_KEY_CPU_TEMP);
 //SMCClose();
 IFPrint(@"Hello, World!");
 IFPrint(@"%f", temp);
 
 printf("%d", getDesignCycleCount());
 */
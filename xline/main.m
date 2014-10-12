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
#import "BattTool/batt.h"

void IFPrint (NSString *format, ...) {
    va_list args;
    va_start(args, format);
    
    fputs([[[NSString alloc] initWithFormat:format arguments:args] UTF8String], stdout);
    
    va_end(args);
}

int main(int argc, const char * argv[])
{
    @autoreleasepool {
        NSString *probe = @"";
        NSString *batterySelector= @"";
        NSString *smc= @"";
        //NSString *smcW= @"";
        NSString *fan= @"0";
        NSString *sil= @"";
        BOOL raw = NO;
        BOOL convert = NO;
        BOOL type = NO;
        BOOL fandata = NO;
        
        BRLOptionParser *options = [BRLOptionParser new];
        [options setBanner:@"usage: %s [-t <probe>] [-b <key>]", argv[0]];
        [options addSeparator:@"Options"];
        [options addOption:"temp" flag:'t' description:@"Prints the specified component's temperature. Use [-t help] to know which info you can request." argument:&probe];
        [options addOption:"battery" flag:'b' description:@"Prints the specified battery info. Use [-b help] to know which info you can request." argument:&batterySelector];
        [options addOption:"smcRead" flag:'r' description:@"Useful to make raw SMC requests. For example : xline -s X (X = SMC key) will return raw SMC data (in hex) and its type. See SWITCHES section to get all this formatted." argument:&smc];
        //[options addOption:"smcWrite" flag:'w' description:@"Used to write data to SMC. Be careful, it could disturb it (you'll have to reinitialise it) - or even worse... For example : xline -S X Y (X = SMC key, Y = Value) " argument:&smcW];
        [options addOption:"SIL" flag:'S' description:@"Setting SIL led (the led that sits on your MacBook's front) state. [-S 1] is on, [-S 0] is off, [-S breathe] makes it breathe like when the MacBook is sleeping." argument:&sil];
        [options addOption:"fan" flag:'f' description:@"Prints the specified fan's data. Use [-f help] to get examples." argument:&fan];
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
            printf("Printed data cannot be raw AND converted ! Use --help to get rescued.\n");
            exit(EXIT_FAILURE);
        }
        
        if (![probe isEqualToString:@""]) {
            char *probeKey;
            if ([probe isEqualToString:@"CPU"])
                probeKey = "TC0P";
            else if ([probe isEqualToString:@"CPUD"])
                probeKey = "TC0D";
            else if ([probe isEqualToString:@"CPUH"])
                probeKey = "TC0H";
            else if ([probe isEqualToString:@"GPU"])
                probeKey = "TG0P";
            else if ([probe isEqualToString:@"GPUD"])
                probeKey = "TG0D";
            else if ([probe isEqualToString:@"GPUH"])
                probeKey = "TG0H";
            else if ([probe isEqualToString:@"PALM"])
                probeKey = "Ts0P";
            else if ([probe isEqualToString:@"POWER"])//battery charger prox (FUCK HERE, Tm0P/Tp0P/Tp0C)
                probeKey = "Ts0S";
            else if ([probe isEqualToString:@"BAT3"]) // battery pos 3
                probeKey = "TB2T";
            else if ([probe isEqualToString:@"BAT2"]) // battery pos 2
                probeKey = "TB1T";
            else if ([probe isEqualToString:@"BAT1"]) // battery pos 1
                probeKey = "TB0T";
            else if ([probe isEqualToString:@"WHATSTHAT"]) //BPIT, TC0F, BRIT, TPCD
                probeKey = "WHAT";
            else if ([probe isEqualToString:@"PCHD"])
                probeKey = "TPCD";
            else if ([probe isEqualToString:@"PCH"])
                probeKey = "TP0P";
            else if ([probe isEqualToString:@"MEM1"])
                probeKey = "TM0S";
            else if ([probe isEqualToString:@"MEM2"]) // ACTUALLY MEM PROX
                probeKey = "TM0P";
            else if ([probe isEqualToString:@"LCD"])
                probeKey = "TL0P";
            else if ([probe isEqualToString:@"help"]) {
                printf("Here's what you can request with -t : \n- CPU \n- CPUH : CPU Heatsink\n- CPUD : CPU Die\n- GPU\n- GPUH : GPU Heatsink\n- GPUD : GPU Die\n- PALM : Left palm rest\n- POWER : Battery charger proximity\n- BAT3 : Battery, position 3\n- BAT2 : Battery, position 2\n- BAT1 : Battery, position 1\n- PCHD : Platform Controller Hub\n- PCH : Power Supply Proximity\n- MEM1 : RAM\n- MEM2 : RAM proximity\n- LCD : Screen\nIf something returns 0, don't worry, as it just means that there is no such part within your computer !\n");
                    exit(EXIT_SUCCESS);
            } else {
                printf("Unknown component\n");
                exit(EXIT_FAILURE);
            }
            double temp = SMCGetTemperature(probeKey);
            //IFPrint(@"%f", temp);
            printf("%f\n", temp);//[probe UTF8String]);
            exit(EXIT_SUCCESS);
        }
        
        if (![fan isEqualToString:@""]) {
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
                printf("Example : \n[xline -f] to get all fans infos\n[xline -f 0] to get fan O infos\n[xline -f 0 -D] to get a comma-separated list of fan 0 infos (e.g=A,B,C,D,E,F with A=Current fan RPM, B=minimum RPM, C=maximum RPM, D=Safe speed, E=Target speed, F=Fan mode. If you do not provide a fan ID but ask for a comma-sep. list, you'll get #X,A,B,C,D,E,F with #X=fan ID)");
                exit(EXIT_SUCCESS);
            }
            
            if (fandata) {
                result = SMCPrintFansAsCSL(fanNum);
            } else {
                result = SMCPrintFans(fanNum);
            }
            if (result != kIOReturnSuccess) {
                printf("Error: SMCPrintFans() = %08x\n", result);
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
                    printf("Error: SMCReadKey() = %08x\n", result);
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
                    printf("Error: SMCWriteKey() = %08x\n", result);
            }
            //printVal(val);
            //SMCBlink();
            SMCClose();
            exit(EXIT_SUCCESS);
        }
        
        if (![batterySelector isEqualToString:@""]) {
            id batteryKit = [batKit alloc];
            if ([batterySelector isEqualToString:@"voltage"])
                IFPrint(@"%@\n", [batteryKit batVoltage]);
            else if ([batterySelector isEqualToString:@"cyclecount"])
                IFPrint(@"%@\n", [batteryKit batCycleCount]);
            else if ([batterySelector isEqualToString:@"designcyclecount"])
                IFPrint(@"%@\n", [batteryKit batDesignCycleCount]);
            else if ([batterySelector isEqualToString:@"serialnumber"])
                IFPrint(@"%@\n", [batteryKit batHSNumber]);
            else if ([batterySelector isEqualToString:@"ispresent"])
                IFPrint(@"%@\n", [batteryKit batIsPresent]);
            else if ([batterySelector isEqualToString:@"isfull"])
                IFPrint(@"%@\n", [batteryKit batIsFull]);
            else if ([batterySelector isEqualToString:@"ischarging"])
                IFPrint(@"%@\n", [batteryKit batIsCharging]);
            else if ([batterySelector isEqualToString:@"manufacturer"])
                IFPrint(@"%@\n", [batteryKit batManufacturer]);
            else if ([batterySelector isEqualToString:@"manufacturedate"])
                IFPrint(@"%@\n", [batteryKit batManufactureDate]);
            else if ([batterySelector isEqualToString:@"timeremaining"])
                IFPrint(@"%@\n", [batteryKit batTimeRemaining]);
            else if ([batterySelector isEqualToString:@"isAC"])
                IFPrint(@"%@\n", [batteryKit batIsACConnected]);
            else if ([batterySelector isEqualToString:@"power"])
                IFPrint(@"%@\n", [batteryKit batWatts]);
            else if ([batterySelector isEqualToString:@"amperage"])
                IFPrint(@"%@\n", [batteryKit batCurrentAmperage]);
            else if ([batterySelector isEqualToString:@"maxcapacity"])
                IFPrint(@"%@\n", [batteryKit batMaxCapacity]);
            else if ([batterySelector isEqualToString:@"designcapacity"])
                IFPrint(@"%@\n", [batteryKit batDesignCapacity]);
            else if ([batterySelector isEqualToString:@"temperature"])
                IFPrint(@"%@\n", [batteryKit batTemperature]);
            else if ([batterySelector isEqualToString:@"help"]) {
                printf("Here's what you can request with -b : \n- Voltage : Prints battery's current voltage \n- CycleCount : Battery's current count of charge/discharge cycle\n- DesignCycleCount : Battery's designed (planned) cycle count \n- SerialNumber : Self-explanatory, hmmm? \n- Power : Battery's current power in Wh \n- Temperature : Battery's temperature in °Celsius \n- Amperage : Battery's current amperage in mA \n- MaxCapacity : Battery's maximum capacity in mA \n- DesignCapacity : Battery's designed (planned) capacity in mA \n- Manufacturer : Self-explanatory... \n- ManufactureDate : U silly, bro? \n- TimeRemaining : The number of minutes before you run out of juice \n- isAC : Is your computer currently connected to an external power source ? \n- isFull : Is your battery currently full ? \n- isCharging : Is your battery currently being recharged ? \n- IsPresent : Is there a battery connected to this computer (if not, all other requests will return empty values, except isAC)\n");
                exit(EXIT_FAILURE);
            } else {
                IFPrint(@"Unknown component\n");
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
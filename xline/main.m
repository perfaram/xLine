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
        
        BRLOptionParser *options = [BRLOptionParser new];
        //TODO : add options to get raw SMC data, translated data, formatted data, beautiful text
        [options setBanner:@"usage: %s [-t <probe>] [-b <key>]", argv[0]];
        [options addOption:"temp" flag:'t' description:@"Prints the specified component's temperature. Use [-t help] to know which info you can request." argument:&probe];
        [options addSeparator];
        [options addOption:"battery" flag:'b' description:@"Prints the specified battery info. Use [-b help] to know which info you can request." argument:&batterySelector];
        [options addSeparator];
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
            else if ([batterySelector isEqualToString:@"help"])
                printf("Here's what you can request with -t : \n- CPU \n- CPUH : CPU Heatsink\n- CPUD : CPU Die\n- GPU\n- GPUH : GPU Heatsink\n- GPUD : GPU Die\n- PALM : Left palm rest\n- POWER : Battery charger proximity\n- BAT3 : Battery, position 3\n- BAT2 : Battery, position 2\n- BAT1 : Battery, position 1\n- PCHD : Platform Controller Hub\n- PCH : Power Supply Proximity\n- MEM1 : RAM\n- MEM2 : RAM proximity\n- LCD : Screen\n If something returns 0.00, doesn't matter : it just means that there is no such component in your computer !");
            else {
                printf("Unknown component\n");
                exit(EXIT_FAILURE);
            }
            double temp = SMCGetTemperature(probeKey);
            //IFPrint(@"%f", temp);
            printf("%f\n", temp);//[probe UTF8String]);
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
            else if ([batterySelector isEqualToString:@"help"])
                printf("Here's what you can request with -b : \n- Voltage : Prints battery's current voltage \n- CycleCount : Battery's current count of charge/discharge cycle\n- DesignCycleCount : Battery's designed (planned) cycle count \n- SerialNumber : Self-explanatory, hmmm? \n- Power : Battery's current power in Wh \n- Temperature : Battery's temperature in °Celsius \n- Amperage : Battery's current amperage in mA \n- MaxCapacity : Battery's maximum capacity in mA \n- DesignCapacity : Battery's designed (planned) capacity in mA \n- Manufacturer : Self-explanatory... \n- ManufactureDate : U silly, bro? \n- TimeRemaining : The number of minutes before you run out of juice \n- isAC : Is your computer currently connected to an external power source ? \n- isFull : Is your battery currently full ? \n- isCharging : Is your battery currently being recharged ? \n- IsPresent : Is there a battery connected to this computer (if not, all other requests will return empty values, except isAC)\n");
            else {
                IFPrint(@"Unknown component");
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
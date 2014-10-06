/*
 * Apple System Management Control (SMC) Tool
 * Copyright (C) 2006 devnull
 * Portions Copyright (C) 2012 Alex Leigh
 * Portions Copyright (C) 2013 Michael Wilber
 * Portions Copyright (C) 2014 Perceval Faramaz
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.

 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

@interface batKit : NSObject

@property (assign, nonatomic) NSString *batType;                //battery type
@property (assign, nonatomic) NSString *batPSState;             //power source state

@property (assign, nonatomic) NSString *batHealth;              //health
@property (assign, nonatomic) NSString *batHConfidence;         //health confidence
@property (assign, nonatomic) NSString *batHCondition;          //health condition
@property (assign, nonatomic) NSArray *batFailureModes;         //battery failure modes




@property (assign, nonatomic) NSString *batName;
@property (assign, nonatomic) NSNumber *batVoltage;
@property (assign, nonatomic) NSNumber *batAmperage;
@property (assign, nonatomic) NSNumber *batCurrentAmperage;
@property (assign, nonatomic) NSNumber *batMaxCapacity;
@property (assign, nonatomic) NSNumber *batDesignCapacity;
@property (assign, nonatomic) NSNumber *batCycleCount;
@property (assign, nonatomic) NSNumber *batDesignCycleCount;
@property (assign, nonatomic) NSNumber *batWatts;
@property (assign, nonatomic) NSNumber *batTemperature;
@property (assign, nonatomic) NSString *batHSNumber;
@property (assign, nonatomic) NSString *batManufacturer;
@property (assign, nonatomic) NSDate *batManufactureDate;
@property (assign, nonatomic) NSNumber *batTimeRemaining;
@property (assign, nonatomic) NSNumber *batIsPresent;
@property (assign, nonatomic) NSNumber *batIsFull;
@property (assign, nonatomic) NSNumber *batIsCharging;
@property (assign, nonatomic) NSNumber *batIsACConnected;

- (NSString *)      batName;                  //battery's name
- (NSNumber *)      batVoltage;               //current voltage
- (NSNumber *)      batCurrentAmperage;       //current amperage mAh
- (NSNumber *)      batMaxCapacity;           //maximum amperage mAh
- (NSNumber *)      batDesignCapacity;        //designed amperage mAh
- (NSNumber *)      batCycleCount;            //battery's cycle count
- (NSNumber *)      batDesignCycleCount;      //battery's designed cycle count
- (NSNumber *)      batTemperature;           //battery's current temperature - °C
- (NSNumber *)      batWatts;                 //current power - Wh
- (NSString *)      batHSNumber;              //battery's Serial Number
- (NSString *)      batManufacturer;          //battery's manufacturer
- (NSDate *)        batManufactureDate;       //YYYY-MM-DD
- (NSNumber *)batTimeRemaining;         //
- (NSNumber *)      batIsPresent;             //--
- (NSNumber *)      batIsFull;                //--
- (NSNumber *)      batIsACConnected;         //--
- (NSNumber *)      batIsCharging;            //--

@end
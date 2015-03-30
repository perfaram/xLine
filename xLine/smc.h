/*
 * Apple System Management Control (SMC) Tool
 * Copyright (C) 2006 devnull
 * Portions Copyright (C) 2012 Alex Leigh
 * Portions Copyright (C) 2013 Michael Wilber
 * Portions Copyright (C) 2013 Jedda Wignall
 * Portions Copyright (C) 2014 Perceval Faramaz
 * Portions Copyright (C) 2014 Naoya Sato
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
/* TODO : CREATE CLASSES */
/*
#ifndef __SMC_H__
#define __SMC_H__
#endif

#define SMCLIBVERSION               "1.7" //Added sooo much thing that 1.7 seems good :D. And I like 7. (V2 will be at the time SMCUtil becomes a class.)

#define KERNEL_INDEX_SMC      2

#define SMC_CMD_READ_BYTES    5
#define SMC_CMD_WRITE_BYTES   6
#define SMC_CMD_READ_INDEX    8
#define SMC_CMD_READ_KEYINFO  9
#define SMC_CMD_READ_PLIMIT   11
#define SMC_CMD_READ_VERS     12

#define DATATYPE_FP1F         "fp1f"
#define DATATYPE_FP4C         "fp4c"
#define DATATYPE_FP5B         "fp5b"
#define DATATYPE_FP6A         "fp6a"
#define DATATYPE_FP79         "fp79"
#define DATATYPE_FP88         "fp88"
#define DATATYPE_FPA6         "fpa6"
#define DATATYPE_FPC4         "fpc4"
#define DATATYPE_FPE2         "fpe2"

#define DATATYPE_SP1E         "sp1e"
#define DATATYPE_SP3C         "sp3c"
#define DATATYPE_SP4B         "sp4b"
#define DATATYPE_SP5A         "sp5a"
#define DATATYPE_SP69         "sp69"
#define DATATYPE_SP78         "sp78"
#define DATATYPE_SP87         "sp87"
#define DATATYPE_SP96         "sp96"
#define DATATYPE_SPB4         "spb4"
#define DATATYPE_SPF0         "spf0"

#define DATATYPE_UINT8        "ui8 "
#define DATATYPE_UINT16       "ui16"
#define DATATYPE_UINT32       "ui32"

#define DATATYPE_SI8          "si8 "
#define DATATYPE_SI16         "si16"

#define DATATYPE_FLAG         "flag"
#define DATATYPE_PWM          "{pwm"
#define DATATYPE_LSO          "{lso"
#define DATATYPE_CHARSTAR     "ch8*"

// key values
#define SMC_KEY_CPU_TEMP      "TC0P"
#define SMC_KEY_FAN_SPEED     "F%dAc"
#define SMC_KEY_FAN_NUM       "FNum"
#define SMC_KEY_BATTERY_TEMP  "TB0T"


typedef struct {
    char                  major;
    char                  minor;
    char                  build;
    char                  reserved[1];
    UInt16                release;
} SMCKeyData_vers_t;

typedef struct {
    UInt16                version;
    UInt16                length;
    UInt32                cpuPLimit;
    UInt32                gpuPLimit;
    UInt32                memPLimit;
} SMCKeyData_pLimitData_t;

typedef struct {
    UInt32                dataSize;
    UInt32                dataType;
    char                  dataAttributes;
} SMCKeyData_keyInfo_t;

typedef char              SMCBytes_t[32];

typedef struct {
    UInt32                  key;
    SMCKeyData_vers_t       vers;
    SMCKeyData_pLimitData_t pLimitData;
    SMCKeyData_keyInfo_t    keyInfo;
    char                    result;
    char                    status;
    char                    data8;
    UInt32                  data32;
    SMCBytes_t              bytes;
} SMCKeyData_t;

typedef char              UInt32Char_t[5];

typedef char              Flag[1];
typedef UInt8   flag;


typedef UInt16 PWMValue;

typedef struct {
    UInt32Char_t            key;
    UInt32                  dataSize;
    UInt32Char_t            dataType;
    SMCBytes_t              bytes;
} SMCVal_t;

enum LmsSelect { kLmsOff,              // SIL off
    kLmsOn,               // SIL on,        autoscale OK
    kLmsBreathe,          // SIL breathing, autoscale OK
    kLmsBrightNoScale     // SIL on bright, no autoscale
    //   (for power switch override)
};

struct LmsDwell {
    UInt16 ui16MidToStartRatio; // Mid-step size / start-step  size
    UInt16 ui16MidToEndRatio;   // Mid-step size / end-step    size
    UInt16 ui16StartTicks;      // # of ticks using start-step size
    UInt16 ui16EndTicks;        // # of ticks using end-step   size
};

struct LmsFlare {
    PWMValue modvFlareCeiling;  // Flare algorithm is active below this value.
    PWMValue modvMinChange;     // Minimum rate of change while flaring.
    UInt16   ui16FlareAdjust;   // Smaller value causes stronger flare as
};

struct LmsOverrideBehavior {
    enum LmsSelect lmssTargetBehavior;  // Enumerated SIL behavior
    flag fRamp;                    // Set to 1 (LMS_RAMP) for a slew-rate
    //   controlled transition.  Set to 0
    //   (LMS_NO_RAMP) for a step change.
};
*/
// prototypes
kern_return_t SMCOpen(void);
kern_return_t SMCClose(void);
kern_return_t SMCPrintFans(int fanNum);
kern_return_t SMCPrintFansAsCSL(int fanNum);
char SMCGetValType(char *valKey);
SMCVal_t createSMCVal(char *valKey, char *valDataType, SMCBytes_t valBytes);
kern_return_t SMCWriteKey(SMCVal_t writeVal);
float SMCGetFanSpeed(int fanNum);
int SMCGetFanRPM(char *key);
int SMCGetFanNumber(char *key);
kern_return_t SMCReadKey(UInt32Char_t key, SMCVal_t *val);
void printVal(SMCVal_t val);
//void SMCBlink();
void printRawVal(SMCVal_t val);
void printValType(SMCVal_t val);
void printConvVal(SMCVal_t val);
kern_return_t SMCGetTemperature(char *key, double *comTemp);
const char* getBatteryHealth();
int getDesignCycleCount();
int getBatteryCharge();
CFTypeRef IOPSCopyPowerSourcesInfo(void);
CFArrayRef IOPSCopyPowerSourcesList(CFTypeRef blob);
CFDictionaryRef IOPSGetPowerSourceDescription(CFTypeRef blob, CFTypeRef ps);

// Ruby modules
/*void Init_osx_stats();
VALUE method_get_cpu_temp(VALUE self);
VALUE method_get_fan_speed(VALUE self, VALUE num);
VALUE method_get_fan_number(VALUE self);
VALUE method_has_battery(VALUE self);
VALUE method_get_battery_health(VALUE self);
VALUE method_get_battery_design_cycle_count(VALUE self);
VALUE method_get_battery_temp(VALUE self);
VALUE method_get_battery_time_remaining(VALUE self);
VALUE method_get_battery_charge(VALUE self);
*/
/*
 * Apple System Management Control (SMC) Tool
 * Copyright (C) 2006 devnull
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

#include <stdio.h>
#include <string.h>
//#include <ruby.h>
#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/IOKitLib.h>
#include <IOKit/ps/IOPSKeys.h>
#include <IOKit/ps/IOPowerSources.h>

#include "smc.h"
#define KEY_INFO_CACHE_SIZE 100
static io_connect_t conn;
io_connect_t g_conn = 0;
struct {
    UInt32 key;
    SMCKeyData_keyInfo_t keyInfo;
} g_keyInfoCache[KEY_INFO_CACHE_SIZE];

int g_keyInfoCacheCount = 0;
OSSpinLock g_keyInfoSpinLock = 0;

UInt32 _strtoul(char *str, int size, int base)
{
    UInt32 total = 0;
    int i;

    for (i = 0; i < size; i++)
    {
        if (base == 16)
            total += str[i] << (size - 1 - i) * 8;
        else
           total += (unsigned char) (str[i] << (size - 1 - i) * 8);
    }
    
    return total;
}

float _strtof(unsigned char *str, int size, int e)
{
    float total = 0;
    int i;

    for (i = 0; i < size; i++)
    {
        if (i == (size - 1))
            total += (str[i] & 0xff) >> e;
        else
            total += str[i] << (size - 1 - i) * (8 - e);
    }

	total += (str[size-1] & 0x03) * 0.25;

    return total;
}

void _ultostr(char *str, UInt32 val)
{
    str[0] = '\0';
    sprintf(str, "%c%c%c%c",
            (unsigned int) val >> 24,
            (unsigned int) val >> 16,
            (unsigned int) val >> 8,
            (unsigned int) val);
}

void printFP1F(SMCVal_t val)
{
    printf("%.5f ", ntohs(*(UInt16*)val.bytes) / 32768.0);
}

void printFP4C(SMCVal_t val)
{
    printf("%.5f ", ntohs(*(UInt16*)val.bytes) / 4096.0);
}

void printFP5B(SMCVal_t val)
{
    printf("%.5f ", ntohs(*(UInt16*)val.bytes) / 2048.0);
}

void printFP6A(SMCVal_t val)
{
    printf("%.4f ", ntohs(*(UInt16*)val.bytes) / 1024.0);
}

void printFP79(SMCVal_t val)
{
    printf("%.4f ", ntohs(*(UInt16*)val.bytes) / 512.0);
}

void printFP88(SMCVal_t val)
{
    printf("%.3f ", ntohs(*(UInt16*)val.bytes) / 256.0);
}

void printFPA6(SMCVal_t val)
{
    printf("%.2f ", ntohs(*(UInt16*)val.bytes) / 64.0);
}

void printFPC4(SMCVal_t val)
{
    printf("%.2f ", ntohs(*(UInt16*)val.bytes) / 16.0);
}

void printFPE2(SMCVal_t val)
{
    printf("%.2f ", ntohs(*(UInt16*)val.bytes) / 4.0);
}

void printUInt(SMCVal_t val)
{
    printf("%u ", (unsigned int) _strtoul((char *)val.bytes, val.dataSize, 10));
}

void printSP1E(SMCVal_t val)
{
    printf("%.5f ", ((SInt16)ntohs(*(UInt16*)val.bytes)) / 16384.0);
}

void printSP3C(SMCVal_t val)
{
    printf("%.5f ", ((SInt16)ntohs(*(UInt16*)val.bytes)) / 4096.0);
}

void printSP4B(SMCVal_t val)
{
    printf("%.4f ", ((SInt16)ntohs(*(UInt16*)val.bytes)) / 2048.0);
}

void printSP5A(SMCVal_t val)
{
    printf("%.4f ", ((SInt16)ntohs(*(UInt16*)val.bytes)) / 1024.0);
}

void printSP69(SMCVal_t val)
{
    printf("%.3f ", ((SInt16)ntohs(*(UInt16*)val.bytes)) / 512.0);
}

void printSP78(SMCVal_t val)
{
    printf("%.3f ", ((SInt16)ntohs(*(UInt16*)val.bytes)) / 256.0);
}

void printSP87(SMCVal_t val)
{
    printf("%.3f ", ((SInt16)ntohs(*(UInt16*)val.bytes)) / 128.0);
}

void printSP96(SMCVal_t val)
{
    printf("%.2f ", ((SInt16)ntohs(*(UInt16*)val.bytes)) / 64.0);
}

void printSPB4(SMCVal_t val)
{
    printf("%.2f ", ((SInt16)ntohs(*(UInt16*)val.bytes)) / 16.0);
}

void printSPF0(SMCVal_t val)
{
    printf("%.0f ", (float)ntohs(*(UInt16*)val.bytes));
}

void printSI8(SMCVal_t val)
{
    printf("%d ", (signed char)*val.bytes);
}

void printSI16(SMCVal_t val)
{
    printf("%d ", ntohs(*(SInt16*)val.bytes));
}

void printPWM(SMCVal_t val)
{
    printf("%.1f%% ", ntohs(*(UInt16*)val.bytes) * 100 / 65536.0);
}


void printString(SMCVal_t val) {
    printf("%s ", val.bytes);
}

void printBytesHex(SMCVal_t val) {
    int i;
    
    printf("(bytes");
    for (i = 0; i < val.dataSize; i++) {
        printf(" %02x", (unsigned char) val.bytes[i]);
    }
    printf(")");
}

kern_return_t SMCOpen(void)
{
    kern_return_t result;
    mach_port_t   masterPort;
    io_iterator_t iterator;
    io_object_t   device;

    result = IOMasterPort(MACH_PORT_NULL, &masterPort);

    CFMutableDictionaryRef matchingDictionary = IOServiceMatching("AppleSMC");
    result = IOServiceGetMatchingServices(masterPort, matchingDictionary, &iterator);
    if (result != kIOReturnSuccess)
    {
        printf("Error: IOServiceGetMatchingServices() = %08x\n", result);
        return 1;
    }

    device = IOIteratorNext(iterator);
    IOObjectRelease(iterator);
    if (device == 0)
    {
        printf("Error: no SMC found\n");
        return 1;
    }

    result = IOServiceOpen(device, mach_task_self(), 0, &conn);
    IOObjectRelease(device);
    if (result != kIOReturnSuccess)
    {
        printf("Error: IOServiceOpen() = %08x\n", result);
        return 1;
    }

    return kIOReturnSuccess;
}

kern_return_t SMCClose()
{
    return IOServiceClose(conn);
}

kern_return_t SMCCall2(int index, SMCKeyData_t *inputStructure, SMCKeyData_t *outputStructure,io_connect_t conn)
{
    size_t   structureInputSize;
    size_t   structureOutputSize;
    structureInputSize = sizeof(SMCKeyData_t);
    structureOutputSize = sizeof(SMCKeyData_t);
    
    return IOConnectCallStructMethod(conn, index, inputStructure, structureInputSize, outputStructure, &structureOutputSize);
}

// Provides key info, using a cache to dramatically improve the energy impact of smcFanControl
kern_return_t SMCGetKeyInfo(UInt32 key, SMCKeyData_keyInfo_t* keyInfo, io_connect_t conn)
{
    SMCKeyData_t inputStructure;
    SMCKeyData_t outputStructure;
    kern_return_t result = kIOReturnSuccess;
    int i = 0;
    
    OSSpinLockLock(&g_keyInfoSpinLock);
    
    for (; i < g_keyInfoCacheCount; ++i)
    {
        if (key == g_keyInfoCache[i].key)
        {
            *keyInfo = g_keyInfoCache[i].keyInfo;
            break;
        }
    }
    
    if (i == g_keyInfoCacheCount)
    {
        // Not in cache, must look it up.
        memset(&inputStructure, 0, sizeof(inputStructure));
        memset(&outputStructure, 0, sizeof(outputStructure));
        
        inputStructure.key = key;
        inputStructure.data8 = SMC_CMD_READ_KEYINFO;
        
        result = SMCCall2(KERNEL_INDEX_SMC, &inputStructure, &outputStructure, conn);
        if (result == kIOReturnSuccess)
        {
            *keyInfo = outputStructure.keyInfo;
            if (g_keyInfoCacheCount < KEY_INFO_CACHE_SIZE)
            {
                g_keyInfoCache[g_keyInfoCacheCount].key = key;
                g_keyInfoCache[g_keyInfoCacheCount].keyInfo = outputStructure.keyInfo;
                ++g_keyInfoCacheCount;
            }
        }
    }
    
    OSSpinLockUnlock(&g_keyInfoSpinLock);
    
    return result;
}

kern_return_t SMCReadKey2(UInt32Char_t key, SMCVal_t *val,io_connect_t conn)
{
    kern_return_t result;
    SMCKeyData_t  inputStructure;
    SMCKeyData_t  outputStructure;
    
    memset(&inputStructure, 0, sizeof(SMCKeyData_t));
    memset(&outputStructure, 0, sizeof(SMCKeyData_t));
    memset(val, 0, sizeof(SMCVal_t));
    
    inputStructure.key = _strtoul(key, 4, 16);
    sprintf(val->key, "%s", key);
    
    result = SMCGetKeyInfo(inputStructure.key, &outputStructure.keyInfo, conn);
    if (result != kIOReturnSuccess)
    {
        return result;
    }
    
    val->dataSize = outputStructure.keyInfo.dataSize;
    _ultostr(val->dataType, outputStructure.keyInfo.dataType);
    inputStructure.keyInfo.dataSize = val->dataSize;
    inputStructure.data8 = SMC_CMD_READ_BYTES;
    
    result = SMCCall2(KERNEL_INDEX_SMC, &inputStructure, &outputStructure,conn);
    if (result != kIOReturnSuccess)
    {
        return result;
    }
    
    memcpy(val->bytes, outputStructure.bytes, sizeof(outputStructure.bytes));
    
    return kIOReturnSuccess;
}

kern_return_t SMCWriteKey2(SMCVal_t writeVal, io_connect_t conn)
{
    kern_return_t result;
    SMCKeyData_t  inputStructure;
    SMCKeyData_t  outputStructure;
    
    SMCVal_t      readVal;
    
    result = SMCReadKey2(writeVal.key, &readVal,conn);
    if (result != kIOReturnSuccess)
        return result;
    
    if (readVal.dataSize != writeVal.dataSize)
        return kIOReturnError;
    
    memset(&inputStructure, 0, sizeof(SMCKeyData_t));
    memset(&outputStructure, 0, sizeof(SMCKeyData_t));
    
    inputStructure.key = _strtoul(writeVal.key, 4, 16);
    inputStructure.data8 = SMC_CMD_WRITE_BYTES;
    inputStructure.keyInfo.dataSize = writeVal.dataSize;
    memcpy(inputStructure.bytes, writeVal.bytes, sizeof(writeVal.bytes));
    result = SMCCall2(KERNEL_INDEX_SMC, &inputStructure, &outputStructure,conn);
    
    if (result != kIOReturnSuccess)
        return result;
    return kIOReturnSuccess;
}

kern_return_t SMCCall(int index, SMCKeyData_t *inputStructure, SMCKeyData_t *outputStructure)
{
    size_t   structureInputSize;
    size_t   structureOutputSize;
    
    structureInputSize = sizeof(SMCKeyData_t);
    structureOutputSize = sizeof(SMCKeyData_t);
    
#if MAC_OS_X_VERSION_10_5
    return IOConnectCallStructMethod( conn, index,
                                     // inputStructure
                                     inputStructure, structureInputSize,
                                     // ouputStructure
                                     outputStructure, &structureOutputSize );
#else
    return IOConnectMethodStructureIStructureO( conn, index,
                                               structureInputSize, /* structureInputSize */
                                               &structureOutputSize,   /* structureOutputSize */
                                               inputStructure,        /* inputStructure */
                                               outputStructure);       /* ouputStructure */
#endif
    
}

kern_return_t SMCWriteKey(SMCVal_t writeVal)
{
    //return SMCWriteKey2(writeVal, g_conn);
    kern_return_t result;
    SMCKeyData_t  inputStructure;
    SMCKeyData_t  outputStructure;
    
    SMCVal_t      readVal;
    
    result = SMCReadKey(writeVal.key, &readVal);
    if (result != kIOReturnSuccess)
        return result;
    
    if (readVal.dataSize != writeVal.dataSize) {
		//return kIOReturnError;
		writeVal.dataSize = readVal.dataSize;
    }
    
    memset(&inputStructure, 0, sizeof(SMCKeyData_t));
    memset(&outputStructure, 0, sizeof(SMCKeyData_t));
    
    inputStructure.key = _strtoul(writeVal.key, 4, 16);
    inputStructure.data8 = SMC_CMD_WRITE_BYTES;
    inputStructure.keyInfo.dataSize = writeVal.dataSize;
    memcpy(inputStructure.bytes, writeVal.bytes, sizeof(writeVal.bytes));
    
    result = SMCCall(KERNEL_INDEX_SMC, &inputStructure, &outputStructure);
    if (result != kIOReturnSuccess)
        return result;
    
    return kIOReturnSuccess;
}

kern_return_t SMCReadKey(UInt32Char_t key, SMCVal_t *val)
{
    //return SMCReadKey2(key, val, g_conn);
    
    kern_return_t result;
    SMCKeyData_t  inputStructure;
    SMCKeyData_t  outputStructure;

    memset(&inputStructure, 0, sizeof(SMCKeyData_t));
    memset(&outputStructure, 0, sizeof(SMCKeyData_t));
    memset(val, 0, sizeof(SMCVal_t));

    inputStructure.key = _strtoul(key, 4, 16);
    inputStructure.data8 = SMC_CMD_READ_KEYINFO;

    result = SMCCall(KERNEL_INDEX_SMC, &inputStructure, &outputStructure);
    if (result != kIOReturnSuccess)
        return result;

    val->dataSize = outputStructure.keyInfo.dataSize;
    _ultostr(val->dataType, outputStructure.keyInfo.dataType);
    inputStructure.keyInfo.dataSize = val->dataSize;
    inputStructure.data8 = SMC_CMD_READ_BYTES;

    result = SMCCall(KERNEL_INDEX_SMC, &inputStructure, &outputStructure);
    if (result != kIOReturnSuccess)
        return result;

    memcpy(val->bytes, outputStructure.bytes, sizeof(outputStructure.bytes));

    return kIOReturnSuccess;
}

SMCVal_t createSMCVal(char *valKey, char *valDataType, SMCBytes_t valBytes)
{
    kern_return_t result;
    SMCVal_t val;
    result = SMCReadKey(valKey, &val);
    if (result == kIOReturnSuccess) {
        printVal(val);
        memcpy(val.bytes, valBytes, strlen(valBytes)+1);
        return val;
    }
    return val;
}

void SMCSILBreathe() { //SMC Key LSSB
    enum LmsSelect breathe = kLmsBreathe;
    struct LmsOverrideBehavior silBehavior;
    silBehavior.lmssTargetBehavior = breathe;
    silBehavior.fRamp = true;
    
    SMCVal_t      val;
    kern_return_t result;
    UInt32Char_t  key = "\0";
    snprintf(key, 5, "%s", "LSOO");
    snprintf(val.key, 5, "%s", key);
    
    result = SMCWriteKey(val);
    if (result != kIOReturnSuccess)
        printf("Error: SMCSILBreathe() = %08x\n", result);
}

char SMCGetValType(char *valKey)
{
    kern_return_t result;
    SMCVal_t val;
    result = SMCReadKey(valKey, &val);
    if (result == kIOReturnSuccess) {
        return sprintf("%-4s\n", val.dataType);;
    }
    return nil;
}

double SMCGetTemperature(char *key)
{
    SMCOpen();
    SMCVal_t val;
    kern_return_t result;

    result = SMCReadKey(key, &val);
    if (result == kIOReturnSuccess) {
        // read succeeded - check returned value
        if (val.dataSize > 0) {
            if (strcmp(val.dataType, DATATYPE_SP78) == 0) {
                // convert fp78 value to temperature
                int intValue = (val.bytes[0] * 256 + val.bytes[1]) >> 2;
                return intValue / 64.0;
                SMCClose();
            }
        }
    }
    // read failed
    SMCClose();
    return 0.0;
}

float SMCGetFanSpeed(int fanNum)
{
    SMCVal_t val;
    kern_return_t result;

    UInt32Char_t  key;
    sprintf(key, SMC_KEY_FAN_SPEED, fanNum);
    result = SMCReadKey(key, &val);
    return _strtof(val.bytes, val.dataSize, 2);
}

int SMCGetFanRPM(char *key) {
    SMCOpen();
    SMCVal_t val;
    kern_return_t result;
    
    result = SMCReadKey(key, &val);
    if (result == kIOReturnSuccess) {
        // read succeeded - check returned value
        if (val.dataSize > 0) {
            if (strcmp(val.dataType, DATATYPE_FPE2) == 0) {
                // convert FPE2 value to int value
                return (int)_strtof(val.bytes, val.dataSize, 2);
                SMCClose();
            }
        }
    }
    // read failed
    SMCClose();
    return 0.0;
}

kern_return_t SMCPrintFans(int fanNum) {
    SMCOpen();
    kern_return_t resultt;
    SMCVal_t      val;
    UInt32Char_t  key;
    char *fnum = "FNum";
    
    resultt = SMCReadKey(fnum, &val);
    if (resultt != kIOReturnSuccess)
        return kIOReturnError;
    
    if (fanNum!=-1) {
        snprintf(key, 5, "F%dAc", fanNum);
        SMCReadKey(key, &val);
        printf("    Actual speed : %.0f Key[%s]\n", _strtof(val.bytes, val.dataSize, 2), key);
        snprintf(key, 5, "F%dMn", fanNum);
        SMCReadKey(key, &val);
        printf("    Minimum speed: %.0f\n", _strtof(val.bytes, val.dataSize, 2));
        snprintf(key, 5, "F%dMx", fanNum);
        SMCReadKey(key, &val);
        printf("    Maximum speed: %.0f\n", _strtof(val.bytes, val.dataSize, 2));
        snprintf(key, 5, "F%dSf", fanNum);
        SMCReadKey(key, &val);
        printf("    Safe speed   : %.0f\n", _strtof(val.bytes, val.dataSize, 2));
        sprintf(key, "F%dTg", fanNum);
        SMCReadKey(key, &val);
        printf("    Target speed : %.0f\n", _strtof(val.bytes, val.dataSize, 2));
        SMCReadKey("FS! ", &val);
        if ((_strtoul(val.bytes, 2, 16) & (1 << fanNum)) == 0)
            printf("    Mode         : auto\n");
        else
            printf("    Mode         : forced\n");
    } else if (fanNum==-1) {
        int           totalFans, i;
        
        totalFans = _strtoul(val.bytes, val.dataSize, 10);
        printf("Total fans in system: %d\n", totalFans);
        
        for (i = 0; i < totalFans; i++) {
            printf("\nFan #%d:\n", i);
            snprintf(key, 5, "F%dAc", i);
            SMCReadKey(key, &val);
            printf("    Actual speed : %.0f Key[%s]\n", _strtof(val.bytes, val.dataSize, 2), key);
            snprintf(key, 5, "F%dMn", i);
            SMCReadKey(key, &val);
            printf("    Minimum speed: %.0f\n", _strtof(val.bytes, val.dataSize, 2));
            snprintf(key, 5, "F%dMx", i);
            SMCReadKey(key, &val);
            printf("    Maximum speed: %.0f\n", _strtof(val.bytes, val.dataSize, 2));
            snprintf(key, 5, "F%dSf", i);
            SMCReadKey(key, &val);
            printf("    Safe speed   : %.0f\n", _strtof(val.bytes, val.dataSize, 2));
            sprintf(key, "F%dTg", i);
            SMCReadKey(key, &val);
            printf("    Target speed : %.0f\n", _strtof(val.bytes, val.dataSize, 2));
            SMCReadKey("FS! ", &val);
            if ((_strtoul(val.bytes, 2, 16) & (1 << i)) == 0)
                printf("    Mode         : auto\n");
            else
                printf("    Mode         : forced\n");
        }
    } else {
        //return kIOReturnError;
    }
    SMCClose();
    return kIOReturnSuccess;
}

kern_return_t SMCPrintFansAsCSL(int fanNum) {
    SMCOpen();
    kern_return_t resultt;
    SMCVal_t      val;
    UInt32Char_t  key;
    char *fnum = "FNum";
    
    resultt = SMCReadKey(fnum, &val);
    if (resultt != kIOReturnSuccess)
        return kIOReturnError;
    
    if (fanNum!=-1) {
        
        snprintf(key, 5, "F%dAc", fanNum);
        SMCReadKey(key, &val);
        printf("%.0f,", _strtof(val.bytes, val.dataSize, 2), key);
        snprintf(key, 5, "F%dMn", fanNum);
        SMCReadKey(key, &val);
        printf("%.0f,", _strtof(val.bytes, val.dataSize, 2));
        snprintf(key, 5, "F%dMx", fanNum);
        SMCReadKey(key, &val);
        printf("%.0f,", _strtof(val.bytes, val.dataSize, 2));
        snprintf(key, 5, "F%dSf", fanNum);
        SMCReadKey(key, &val);
        printf("%.0f,", _strtof(val.bytes, val.dataSize, 2));
        sprintf(key, "F%dTg", fanNum);
        SMCReadKey(key, &val);
        printf("%.0f,", _strtof(val.bytes, val.dataSize, 2));
        SMCReadKey("FS! ", &val);
        if ((_strtoul(val.bytes, 2, 16) & (1 << fanNum)) == 0)
            printf("auto\n");
        else
            printf("forced\n");
    } else if (fanNum==-1) {
        int           totalFans, i;
        
        totalFans = _strtoul(val.bytes, val.dataSize, 10);
        
        for (i = 0; i < totalFans; i++) {
            printf("#%d,", i);
            snprintf(key, 5, "F%dAc", i);
            SMCReadKey(key, &val);
            printf("%.0f,", _strtof(val.bytes, val.dataSize, 2), key);
            snprintf(key, 5, "F%dMn", i);
            SMCReadKey(key, &val);
            printf("%.0f,", _strtof(val.bytes, val.dataSize, 2));
            snprintf(key, 5, "F%dMx", i);
            SMCReadKey(key, &val);
            printf("%.0f,", _strtof(val.bytes, val.dataSize, 2));
            snprintf(key, 5, "F%dSf", i);
            SMCReadKey(key, &val);
            printf("%.0f,", _strtof(val.bytes, val.dataSize, 2));
            sprintf(key, "F%dTg", i);
            SMCReadKey(key, &val);
            printf("%.0f,", _strtof(val.bytes, val.dataSize, 2));
            SMCReadKey("FS! ", &val);
            if ((_strtoul(val.bytes, 2, 16) & (1 << i)) == 0)
                printf("auto\n");
            else
                printf("forced\n");
        }
    } else {
        //return kIOReturnError;
    }
    SMCClose();
    return kIOReturnSuccess;
}

int SMCGetFanNumber(char *key)
{
    SMCVal_t val;
    kern_return_t result;

    result = SMCReadKey(key, &val);
    return _strtoul((char *)val.bytes, val.dataSize, 10);
}

void printVal(SMCVal_t val) {
    printf(" key [type]  (raw) {formatted}\n");
    printf(" %s  [%-4s]  ", val.key, val.dataType);
    
    if (val.dataSize > 0) {
        printBytesHex(val);
        printf("  ");
        
        printf("{");
        if ((strcmp(val.dataType, DATATYPE_UINT8) == 0) ||
            (strcmp(val.dataType, DATATYPE_UINT16) == 0) ||
            (strcmp(val.dataType, DATATYPE_UINT32) == 0))
            printUInt(val);
        else if (strcmp(val.dataType, DATATYPE_FP1F) == 0 && val.dataSize == 2)
            printFP1F(val);
        else if (strcmp(val.dataType, DATATYPE_FP4C) == 0 && val.dataSize == 2)
            printFP4C(val);
        else if (strcmp(val.dataType, DATATYPE_FP5B) == 0 && val.dataSize == 2)
            printFP5B(val);
        else if (strcmp(val.dataType, DATATYPE_FP6A) == 0 && val.dataSize == 2)
            printFP6A(val);
        else if (strcmp(val.dataType, DATATYPE_FP79) == 0 && val.dataSize == 2)
            printFP79(val);
        else if (strcmp(val.dataType, DATATYPE_FP88) == 0 && val.dataSize == 2)
            printFP88(val);
        else if (strcmp(val.dataType, DATATYPE_FPA6) == 0 && val.dataSize == 2)
            printFPA6(val);
        else if (strcmp(val.dataType, DATATYPE_FPC4) == 0 && val.dataSize == 2)
            printFPC4(val);
        else if (strcmp(val.dataType, DATATYPE_FPE2) == 0 && val.dataSize == 2)
            printFPE2(val);
		else if (strcmp(val.dataType, DATATYPE_SP1E) == 0 && val.dataSize == 2)
			printSP1E(val);
		else if (strcmp(val.dataType, DATATYPE_SP3C) == 0 && val.dataSize == 2)
			printSP3C(val);
		else if (strcmp(val.dataType, DATATYPE_SP4B) == 0 && val.dataSize == 2)
			printSP4B(val);
		else if (strcmp(val.dataType, DATATYPE_SP5A) == 0 && val.dataSize == 2)
			printSP5A(val);
		else if (strcmp(val.dataType, DATATYPE_SP69) == 0 && val.dataSize == 2)
			printSP69(val);
		else if (strcmp(val.dataType, DATATYPE_SP78) == 0 && val.dataSize == 2)
			printSP78(val);
		else if (strcmp(val.dataType, DATATYPE_SP87) == 0 && val.dataSize == 2)
			printSP87(val);
		else if (strcmp(val.dataType, DATATYPE_SP96) == 0 && val.dataSize == 2)
			printSP96(val);
		else if (strcmp(val.dataType, DATATYPE_SPB4) == 0 && val.dataSize == 2)
			printSPB4(val);
		else if (strcmp(val.dataType, DATATYPE_SPF0) == 0 && val.dataSize == 2)
			printSPF0(val);
		else if (strcmp(val.dataType, DATATYPE_SI8) == 0 && val.dataSize == 1)
			printSI8(val);
		else if (strcmp(val.dataType, DATATYPE_SI16) == 0 && val.dataSize == 2)
			printSI16(val);
		else if (strcmp(val.dataType, DATATYPE_PWM) == 0 && val.dataSize == 2)
			printPWM(val);
        else if (strcmp(val.dataType, DATATYPE_FPE2) == 0)
            printFPE2(val);
        else if (strcmp(val.dataType, DATATYPE_CHARSTAR) == 0)
            printString(val);
        else if (strcmp(val.dataType, DATATYPE_FLAG) == 0)
            printf(val.bytes[0] ? "TRUE" : "FALSE");
        printf("}\n");
    }
    
    else {
        printf("E11 - SMC returned no data\n");
    }
}

void printRawVal(SMCVal_t val) {
    if (val.dataSize > 0) {
        printBytesHex(val);
    } else {
        printf("E11 - SMC returned no data\n");
    }
}

void printValType(SMCVal_t val) {
    if (val.dataSize > 0) {
        printf("%-4s\n", val.dataType);
    } else {
        printf("E11 - SMC returned no data\n");
    }
}

void printConvVal(SMCVal_t val) {
    if (val.dataSize > 0) {
        if ((strcmp(val.dataType, DATATYPE_UINT8) == 0) ||
            (strcmp(val.dataType, DATATYPE_UINT16) == 0) ||
            (strcmp(val.dataType, DATATYPE_UINT32) == 0))
            printUInt(val);
        else if (strcmp(val.dataType, DATATYPE_FP1F) == 0 && val.dataSize == 2)
            printFP1F(val);
        else if (strcmp(val.dataType, DATATYPE_FP4C) == 0 && val.dataSize == 2)
            printFP4C(val);
        else if (strcmp(val.dataType, DATATYPE_FP5B) == 0 && val.dataSize == 2)
            printFP5B(val);
        else if (strcmp(val.dataType, DATATYPE_FP6A) == 0 && val.dataSize == 2)
            printFP6A(val);
        else if (strcmp(val.dataType, DATATYPE_FP79) == 0 && val.dataSize == 2)
            printFP79(val);
        else if (strcmp(val.dataType, DATATYPE_FP88) == 0 && val.dataSize == 2)
            printFP88(val);
        else if (strcmp(val.dataType, DATATYPE_FPA6) == 0 && val.dataSize == 2)
            printFPA6(val);
        else if (strcmp(val.dataType, DATATYPE_FPC4) == 0 && val.dataSize == 2)
            printFPC4(val);
        else if (strcmp(val.dataType, DATATYPE_FPE2) == 0 && val.dataSize == 2)
            printFPE2(val);
		else if (strcmp(val.dataType, DATATYPE_SP1E) == 0 && val.dataSize == 2)
			printSP1E(val);
		else if (strcmp(val.dataType, DATATYPE_SP3C) == 0 && val.dataSize == 2)
			printSP3C(val);
		else if (strcmp(val.dataType, DATATYPE_SP4B) == 0 && val.dataSize == 2)
			printSP4B(val);
		else if (strcmp(val.dataType, DATATYPE_SP5A) == 0 && val.dataSize == 2)
			printSP5A(val);
		else if (strcmp(val.dataType, DATATYPE_SP69) == 0 && val.dataSize == 2)
			printSP69(val);
		else if (strcmp(val.dataType, DATATYPE_SP78) == 0 && val.dataSize == 2)
			printSP78(val);
		else if (strcmp(val.dataType, DATATYPE_SP87) == 0 && val.dataSize == 2)
			printSP87(val);
		else if (strcmp(val.dataType, DATATYPE_SP96) == 0 && val.dataSize == 2)
			printSP96(val);
		else if (strcmp(val.dataType, DATATYPE_SPB4) == 0 && val.dataSize == 2)
			printSPB4(val);
		else if (strcmp(val.dataType, DATATYPE_SPF0) == 0 && val.dataSize == 2)
			printSPF0(val);
		else if (strcmp(val.dataType, DATATYPE_SI8) == 0 && val.dataSize == 1)
			printSI8(val);
		else if (strcmp(val.dataType, DATATYPE_SI16) == 0 && val.dataSize == 2)
			printSI16(val);
		else if (strcmp(val.dataType, DATATYPE_PWM) == 0 && val.dataSize == 2)
			printPWM(val);
        else if (strcmp(val.dataType, DATATYPE_FPE2) == 0)
            printFPE2(val);
        else if (strcmp(val.dataType, DATATYPE_CHARSTAR) == 0)
            printString(val);
        else if (strcmp(val.dataType, DATATYPE_FLAG) == 0)
            printf(val.bytes[0] ? "TRUE" : "FALSE");
    } else {
        printf("E11 - SMC returned no data\n");
    }
}

/***************************************GARBAGE CODE AREA - NO TRESPASSING BEYOND THIS LINE*********************************************/
/* Battery info
 * Ref: http://www.newosxbook.com/src.jl?tree=listings&file=bat.c
 *      https://developer.apple.com/library/mac/documentation/IOKit/Reference/IOPowerSources_header_reference/Reference/reference.html
 */
/*
void dumpDict (CFDictionaryRef Dict)
{
    // Helper function to just dump a CFDictionary as XML
    CFDataRef xml = CFPropertyListCreateXMLData(kCFAllocatorDefault, (CFPropertyListRef)Dict);
    if (xml) { write(1, CFDataGetBytePtr(xml), CFDataGetLength(xml)); CFRelease(xml); }
}

CFDictionaryRef powerSourceInfo(int Debug)
{
    CFTypeRef       powerInfo;
    CFArrayRef      powerSourcesList;
    CFDictionaryRef powerSourceInformation;

    powerInfo = IOPSCopyPowerSourcesInfo();

    if(! powerInfo) return NULL;

    powerSourcesList = IOPSCopyPowerSourcesList(powerInfo);
    if(!powerSourcesList) {
        CFRelease(powerInfo);
        return NULL;
    }

    // Should only get one source. But in practice, check for > 0 sources
    if (CFArrayGetCount(powerSourcesList))
    {
        powerSourceInformation = IOPSGetPowerSourceDescription(powerInfo, CFArrayGetValueAtIndex(powerSourcesList, 0));

        if (Debug) dumpDict (powerSourceInformation);

        //CFRelease(powerInfo);
        //CFRelease(powerSourcesList);
        return powerSourceInformation;
    }

    CFRelease(powerInfo);
    CFRelease(powerSourcesList);
    return NULL;
}

int getDesignCycleCount() {
    CFDictionaryRef powerSourceInformation = powerSourceInfo(0);

    if(powerSourceInformation == NULL)
        return 0;

    CFNumberRef designCycleCountRef = (CFNumberRef)  CFDictionaryGetValue(powerSourceInformation, CFSTR("DesignCycleCount"));
    uint32_t    designCycleCount;
    if ( ! CFNumberGetValue(designCycleCountRef,  // CFNumberRef number,
                            kCFNumberSInt32Type,  // CFNumberType theType,
                            &designCycleCount))   // void *valuePtr);
        return 0;
    else
        return designCycleCount;
}

const char* getBatteryHealth() {
    CFDictionaryRef powerSourceInformation = powerSourceInfo(0);

    if(powerSourceInformation == NULL)
        return "Unknown";

    CFStringRef batteryHealthRef = (CFStringRef) CFDictionaryGetValue(powerSourceInformation, CFSTR("BatteryHealth"));

    const char *batteryHealth = CFStringGetCStringPtr(batteryHealthRef, // CFStringRef theString,
                                                kCFStringEncodingMacRoman); //CFStringEncoding encoding);
    if(batteryHealth == NULL)
        return "unknown";

    return batteryHealth;
}

const int hasBattery() {
  CFDictionaryRef powerSourceInformation = powerSourceInfo(0);
  return !(powerSourceInformation == NULL);
}

int getBatteryCharge() {
    CFNumberRef currentCapacity;
    CFNumberRef maximumCapacity;

    int iCurrentCapacity;
    int iMaximumCapacity;
    int charge;

    CFDictionaryRef powerSourceInformation;

    powerSourceInformation = powerSourceInfo(0);
    if (powerSourceInformation == NULL)
        return 0;

    currentCapacity = CFDictionaryGetValue(powerSourceInformation, CFSTR(kIOPSCurrentCapacityKey));
    maximumCapacity = CFDictionaryGetValue(powerSourceInformation, CFSTR(kIOPSMaxCapacityKey));

    CFNumberGetValue(currentCapacity, kCFNumberIntType, &iCurrentCapacity);
    CFNumberGetValue(maximumCapacity, kCFNumberIntType, &iMaximumCapacity);

    charge = (float)iCurrentCapacity / iMaximumCapacity * 100;

    return charge;
}
*/
/*
void SMCBlink() { //just to try some things
    SMCVal_t      valOn;
    SMCVal_t      valOff;
    kern_return_t result;
    UInt32Char_t  key = "\0";
    snprintf(key, 5, "%s", "LSOO");
    int i, j, k1, k2;
    char c;
    char* p = "01"; j=0; i=0;
    while (i < strlen("01"))
    {
        c = *p++; k1=k2=0; i++;
        if ((c >= '0') && (c<='9')) {
            k1=c-'0';
        } else if ((c >='a') && (c<='f')) {
            k1=c-'a'+10;
        }
        c = *p++; i++;
        if ((c >= '0') && (c<='9')) {
            k2=c-'0';
        } else if ((c >= 'a') && (c<='f')) {
            k2=c-'a'+10;
        }
        
        //snprintf(c, 2, "%c%c", optarg[i * 2], optarg[(i * 2) + 1]);
        valOn.bytes[j++] = (int)(((k1&0xf)<<4) + (k2&0xf));
    }
    valOn.dataSize = j;
    i=0, j=0, k1=0, k2=0;
    char d;
    char* o = "01"; j=0; i=0;
    while (i < strlen(""))
    {
        d = *o++; k1=k2=0; i++;
        if ((d >= '0') && (d<='9')) {
            k1=d-'0';
        } else if ((d >='a') && (d<='f')) {
            k1=d-'a'+10;
        }
        d = *o++; i++;
        if ((d >= '0') && (d<='9')) {
            k2=d-'0';
        } else if ((d >= 'a') && (d<='f')) {
            k2=d-'a'+10;
        }
        
        //snprintf(d, 2, "%d%d", optarg[i * 2], optarg[(i * 2) + 1]);
        valOff.bytes[j++] = (int)(((k1&0xf)<<4) + (k2&0xf));
    }
    valOff.dataSize = j;
    //val.dataType = SMCGetValType("LSOO");
    snprintf(valOn.key, 5, "%s", key);
    snprintf(valOff.key, 5, "%s", key);
    result = SMCWriteKey(valOn);
    if (result != kIOReturnSuccess)
        printf("Error: SMCWriteKey() = %08x\n", result);
    result = SMCWriteKey(valOff);
    sleep(1);
    result = SMCWriteKey(valOn);
    sleep(1);
    result = SMCWriteKey(valOff);
    sleep(1);
    result = SMCWriteKey(valOn);
    sleep(1);
    result = SMCWriteKey(valOff);
    sleep(1);
    result = SMCWriteKey(valOn);
    sleep(1);
    result = SMCWriteKey(valOff);
    sleep(1);
    result = SMCWriteKey(valOn);
    sleep(1);
    result = SMCWriteKey(valOff);
    sleep(1);
    result = SMCWriteKey(valOn);
    sleep(1);
    result = SMCWriteKey(valOff);
    sleep(1);
    result = SMCWriteKey(valOn);
    sleep(1);
    result = SMCWriteKey(valOff);
    sleep(1);
    result = SMCWriteKey(valOn);
    sleep(1);
    result = SMCWriteKey(valOff);
    sleep(1);
    result = SMCWriteKey(valOn);
    sleep(1);
    result = SMCWriteKey(valOff);
    sleep(1);
    result = SMCWriteKey(valOn);
    sleep(1);
    result = SMCWriteKey(valOff);
    sleep(1);
    result = SMCWriteKey(valOn);
    sleep(1);
    result = SMCWriteKey(valOff);
}
*/
/*
 RUBY MODULES
*/
/*
VALUE CPU_STATS = Qnil;
VALUE FAN_STATS = Qnil;
VALUE BATTERY_STATS = Qnil;
 * Define Ruby modules and associated methods
 * We never call this, Ruby does.
*/
/*
void Init_osx_stats() {
    CPU_STATS = rb_define_module("CPU_STATS");
    rb_define_method(CPU_STATS, "get_cpu_temp", method_get_cpu_temp, 0);

    FAN_STATS = rb_define_module("FAN_STATS");
    rb_define_method(FAN_STATS, "get_fan_number", method_get_fan_number, 0);
    rb_define_method(FAN_STATS, "get_fan_speed", method_get_fan_speed, 1);

    BATTERY_STATS = rb_define_module("BATTERY_STATS");
    rb_define_method(BATTERY_STATS, "has_battery?", method_has_battery, 0);
    rb_define_method(BATTERY_STATS, "get_battery_health", method_get_battery_health, 0);
    rb_define_method(BATTERY_STATS, "get_battery_design_cycle_count", method_get_battery_design_cycle_count, 0);
    rb_define_method(BATTERY_STATS, "get_battery_temp", method_get_battery_temp, 0);
    rb_define_method(BATTERY_STATS, "get_battery_time_remaining", method_get_battery_time_remaining, 0);
    rb_define_method(BATTERY_STATS, "get_battery_charge", method_get_battery_charge, 0);
}

VALUE method_get_cpu_temp(VALUE self) {
    SMCOpen();
    double temp = SMCGetTemperature(SMC_KEY_CPU_TEMP);
    SMCClose();

    return rb_float_new(temp);
}

VALUE method_get_fan_number(VALUE self) {
    SMCOpen();
    int num = SMCGetFanNumber(SMC_KEY_FAN_NUM);
    SMCClose();

    return INT2NUM(num);
}

VALUE method_get_fan_speed(VALUE self, VALUE num) {
    uint fanNum = NUM2UINT(num);
    SMCOpen();
    float speed = SMCGetFanSpeed(fanNum);
    SMCClose();

    return rb_float_new(speed);
}

VALUE method_has_battery(VALUE self) {
    return hasBattery() ? Qtrue : Qfalse;
}

VALUE method_get_battery_health(VALUE self) {
    const char* health = getBatteryHealth();
    return rb_str_new2(health);
}

VALUE method_get_battery_design_cycle_count(VALUE self) {
    int cc = getDesignCycleCount();
    return INT2NUM(cc);
}

VALUE method_get_battery_temp(VALUE self) {
    SMCOpen();
    double temp = SMCGetTemperature(SMC_KEY_BATTERY_TEMP);
    SMCClose();

    return rb_float_new(temp);
}

VALUE method_get_battery_time_remaining(VALUE self) {
    CFTimeInterval time_remaining;

    time_remaining = IOPSGetTimeRemainingEstimate();

    if (time_remaining == kIOPSTimeRemainingUnknown) {
        return rb_str_new2("Calculating");
    } else if (time_remaining == kIOPSTimeRemainingUnlimited) {
        return rb_str_new2("Unlimited");
    } else {
        return INT2NUM(time_remaining);
    }
}

VALUE method_get_battery_charge(VALUE self) {
    int charge = getBatteryCharge();

    if (charge == 0) {
        return Qnil;
    } else {
        return INT2NUM(charge);
    }
}
*/
/* Main method used for test */
// int main(int argc, char *argv[])
// {
//     //SMCOpen();
//     //printf("%0.1f°C\n", SMCGetTemperature(SMC_KEY_CPU_TEMP));
//     //printf("%0.1f\n", SMCGetFanSpeed(0));
//     //printf("%0.1f\n", SMCGetFanSpeed(3));
//     //printf("%i\n", SMCGetFanNumber(SMC_KEY_FAN_NUM));
//     //SMCClose();
//
//     int designCycleCount = getDesignCycleCount();
//     const char* batteryHealth = getBatteryHealth();
//
//   	if (designCycleCount) printf ("%i\n", designCycleCount);
//     if (batteryHealth) printf ("%s\n", batteryHealth);
//
//     return 0;
// }

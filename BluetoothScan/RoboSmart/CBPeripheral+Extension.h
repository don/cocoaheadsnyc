//
//  CBPeripheral+Extensions.h
//  BluetoothScan
//
//  Created by Don Coleman on 6/7/16.
//  Copyright © 2016 Chariot Solutions. All rights reserved.
//

#ifndef CBPeripheral_Extension_h
#define CBPeripheral_Extension_h

#import <objc/runtime.h>
#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface CBPeripheral(com_chariotsolutions_ble_extension)
@property (nonatomic, retain) NSNumber *advertisementRSSI;
@end

#endif /* CBPeripheral_Extension_h */

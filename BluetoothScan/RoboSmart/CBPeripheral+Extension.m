//
//  CBPeripheral+Extensions.m
//  BluetoothScan
//
//  Created by Don Coleman on 6/7/16.
//  Copyright © 2016 Chariot Solutions. All rights reserved.
//

#import "CBPeripheral+Extension.h"

static char ADVERTISEMENT_RSSI_IDENTIFER;

@implementation CBPeripheral(com_chariotsolutions_ble_extension)

- (void)setAdvertisementRSSI:(NSNumber *)newAdvertisementRSSIValue {
    objc_setAssociatedObject(self, &ADVERTISEMENT_RSSI_IDENTIFER, newAdvertisementRSSIValue, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(NSString*)advertisementRSSI{
    return objc_getAssociatedObject(self, &ADVERTISEMENT_RSSI_IDENTIFER);
}

@end
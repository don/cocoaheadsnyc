//
//  DeviceDetailViewController.h
//  BluetoothScan
//
//  Created by Mike Bell on 6/2/16.
//  Copyright © 2016 Chariot Solutions. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface DeviceDetailViewController : UIViewController <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (strong, nonatomic) CBCentralManager *centralManager;

@property (strong, nonatomic) CBPeripheral *peripheral;
@property (strong, nonatomic) CBCharacteristic *switchCharacteristic;
@property (strong, nonatomic) CBCharacteristic *dimmerCharacteristic;

@property (strong, nonatomic) IBOutlet UISwitch *powerSwitch;
@property (strong, nonatomic) IBOutlet UISlider *dimmerSlider;
- (void) on;
- (void) off;
- (void) brightness: (UInt8)level;

@end

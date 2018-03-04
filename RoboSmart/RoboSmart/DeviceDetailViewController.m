//
//  DeviceDetailViewController.m
//  BluetoothScan
//
//  Created by Mike Bell on 6/2/16.
//  Copyright © 2016 Chariot Solutions. All rights reserved.
//

#import "DeviceDetailViewController.h"

@interface DeviceDetailViewController ()

@end

@implementation DeviceDetailViewController

static CBUUID* serviceUUID;
static CBUUID* switchUUID;
static CBUUID* dimmerUUID;

static double INTERVAL = 0.05; // 50 milliseconds
double lastTime = 0;

- (void)viewDidLoad {
    [super viewDidLoad];
    serviceUUID =[CBUUID UUIDWithString:@"FF10"];
    switchUUID =[CBUUID UUIDWithString:@"FF11"];
    dimmerUUID =[CBUUID UUIDWithString:@"FF12"];
    
    [_dimmerSlider setMinimumValue:0];
    [_dimmerSlider setMaximumValue:0xFF];
    [_dimmerSlider addTarget:self action:@selector(onDimmerChanged:) forControlEvents:UIControlEventValueChanged];
    [_dimmerSlider setEnabled:NO];
    
    [_powerSwitch addTarget:self action:@selector(onPowerSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    [_powerSwitch setEnabled:NO];
    
    [_centralManager setDelegate:self];
    [_centralManager connectPeripheral:_peripheral options:nil];
    
    [self setTitle:self.peripheral.name];
}

-(void)viewWillDisappear:(BOOL)animated {
    [_centralManager cancelPeripheralConnection:_peripheral];
}

#pragma mark - CBCentralManagerDelegate

-(void)centralManagerDidUpdateState:(CBCentralManager *)central {
    NSLog(@"----- detail: centralManagerDidUpdateState");
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"Connected to %@", peripheral);
    peripheral.delegate = self;
    [peripheral discoverServices:@[serviceUUID]];
}

- (void) centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"Failed to connect to %@", peripheral);
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"Disconnected from %@", peripheral);
}

#pragma mark - CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    
    for (CBService *service in peripheral.services) {
        NSLog(@"Discovered service %@", service);
        NSArray* characteristics = @[switchUUID, dimmerUUID];
        [peripheral discoverCharacteristics:characteristics forService:service];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    
    for (CBCharacteristic *characteristic in service.characteristics) {
        NSLog(@"Discovered characteristic %@", characteristic);
        
        if ([characteristic.UUID isEqual: switchUUID]) {
            _switchCharacteristic = characteristic;
        } else if ([characteristic.UUID isEqual: dimmerUUID]) {
            _dimmerCharacteristic = characteristic;
        }
    }
    
    NSLog(@"switchCharacteristic %@", _switchCharacteristic);
    NSLog(@"dimmerCharacteristic %@", _dimmerCharacteristic);
    
    // ask for the values, will get the results in didUpdateValueForCharacteristic
    [peripheral readValueForCharacteristic:_switchCharacteristic];
    if (_dimmerCharacteristic) {
        [peripheral readValueForCharacteristic:_dimmerCharacteristic];
    }
    
    // enable the UI
    [_powerSwitch setEnabled:YES];
    [_dimmerSlider setEnabled:YES];
    
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    //if ([characteristic.UUID isEqual: switchUUID]) {
    if ([characteristic isEqual: _switchCharacteristic]) {
        
        // get bytes out of the NSData
        NSData *data = characteristic.value;
        UInt8 bytes[1];
        [data getBytes:&bytes length:sizeof(bytes)];
        
        if (bytes[0] == 1) {
            NSLog(@"Light is on");
            [_powerSwitch setOn:YES animated:YES];
        } else {
            NSLog(@"Light is off");
            [_powerSwitch setOn:NO animated:YES];
        }
        
        //} else if ([characteristic.UUID isEqual: dimmerUUID]) {
    } else if ([characteristic isEqual: _dimmerCharacteristic]) {
        
        NSData *data = characteristic.value;
        UInt8 bytes[1];
        [data getBytes:&bytes length:sizeof(bytes)];
        UInt8 brightness = bytes[0];
        NSLog(@"Brightness is %hhu", brightness);
        
        [_dimmerSlider setValue:brightness animated:YES];
    }
    
}

-(void) peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSLog(@"Wrote value for %@", [characteristic UUID]);
}

#pragma mark - Switch Events

- (void) onPowerSwitchChanged:(id)sender {
    // we get the value of the switch before it changes
    if ([sender isOn]) {
        [self off];
    } else {
        [self on];
    }
}

- (void) onDimmerChanged:(id)sender {
    if (!_dimmerCharacteristic) {
        NSLog(@"This device does not have a dimmer");
        return;
    }
    
    // throttle so we don't send too much data too fast
    double currentTime = [NSDate timeIntervalSinceReferenceDate];
    if (currentTime - lastTime > INTERVAL) {
        lastTime = currentTime;
        [self brightness:[_dimmerSlider value]];
        if (![_powerSwitch isOn]) {
            [_powerSwitch setOn:TRUE];
        }
    }
}

#pragma mark - Light Controls

- (void) on {
    NSLog(@"Turning light on");
    UInt8 bytes[1] = { 0x00 };
    NSData *data = [NSData dataWithBytes:&bytes length:1];
    
    [_peripheral writeValue:data forCharacteristic:_switchCharacteristic type:CBCharacteristicWriteWithResponse];
}

- (void) off {
    NSLog(@"Turning light off");
    UInt8 bytes[1] = { 0x01 };
    NSData *data = [NSData dataWithBytes:&bytes length:1];
    
    [_peripheral writeValue:data forCharacteristic:_switchCharacteristic type:CBCharacteristicWriteWithResponse];
}

- (void) brightness: (UInt8)level {
    NSLog(@"Setting brightness to %hhu", level);
    UInt8 bytes[1];
    bytes[0] = level;
    NSData *data = [NSData dataWithBytes:&bytes length:1];
    
    [_peripheral writeValue:data forCharacteristic:_dimmerCharacteristic type:CBCharacteristicWriteWithResponse];
    
}

@end

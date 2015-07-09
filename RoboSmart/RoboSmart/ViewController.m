//
//  ViewController.m
//  RoboSmart
//
//  Created by Don Coleman on 7/2/15.
//  Copyright (c) 2015 Don Coleman. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
    @property (strong, nonatomic) CBCentralManager *centralManager;
    @property (strong, nonatomic) CBPeripheral *peripheral;
    @property (strong, nonatomic) CBCharacteristic *switchCharacteristic;
    @property (strong, nonatomic) CBCharacteristic *dimmerCharacteristic;

@end

@implementation ViewController

static CBUUID* serviceUUID;
static CBUUID* switchUUID;
static CBUUID* dimmerUUID;

// for throttling dimmer updates
static double INTERVAL = 0.05; // 50 milliseconds
double lastTime = 0;


- (void)viewDidLoad {
    [super viewDidLoad];
    
    _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:nil];
    
    serviceUUID =[CBUUID UUIDWithString:@"FF10"];
    switchUUID =[CBUUID UUIDWithString:@"FF11"];
    dimmerUUID =[CBUUID UUIDWithString:@"FF12"];
    
    [_dimmerSlider setMinimumValue:0];
    [_dimmerSlider setMaximumValue:0xFF];
    
    [_powerSwitch addTarget:self
                 action:@selector(onPowerSwitchChanged:)
       forControlEvents:UIControlEventValueChanged];

    [_dimmerSlider addTarget:self
                     action:@selector(onDimmerChanged:)
           forControlEvents:UIControlEventValueChanged];
    
    [_powerSwitch setEnabled:NO];
    [_dimmerSlider setEnabled:NO];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    
    if ([central state] == CBCentralManagerStatePoweredOn) {
        // begin scanning
        [_centralManager scanForPeripheralsWithServices:@[serviceUUID] options:nil];
        
        // stop the scan
        float scanTimeout = 5;
        [NSTimer scheduledTimerWithTimeInterval:scanTimeout target:self selector:@selector(scanTimer:) userInfo:nil repeats:NO];

    }
    
    // real code should handle other states
}


- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    
    NSLog(@"Discovered %@", peripheral.name);
    
    // we restricted the scan, so this is the device we want to connect to
    [central stopScan];
    
    // can't connect and scan, normally this works out OK when the user is selecting a device
    _peripheral = peripheral;
    float connectTimeout = 0.1;
    [NSTimer scheduledTimerWithTimeInterval:connectTimeout target:self selector:@selector(connectTimer:) userInfo:nil repeats:NO];

}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"Connected to %@", peripheral);
    peripheral.delegate = self;
    [peripheral discoverServices:@[serviceUUID]];
}

- (void) centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"Failed to connect to %@", peripheral);
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:error.localizedDescription
                                                    message:error.localizedRecoverySuggestion
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"Disconnected from %@", peripheral);
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:error.localizedDescription
                                                    message:error.localizedRecoverySuggestion
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
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
    [peripheral readValueForCharacteristic:_dimmerCharacteristic];

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

#pragma mark - Timers

- (void) scanTimer:(NSTimer *)timer
{
    [_centralManager stopScan];
    
    if (!_peripheral) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No lightbulb"
                                                        message:@"Could not find a RoboSmart lightbulb."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
}

- (void) connectTimer:(NSTimer *)timer
{
    NSLog(@"Requesting connection to %@", _peripheral);
    [_centralManager connectPeripheral:_peripheral options:nil];
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

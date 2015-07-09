//
//  ViewController.m
//  Thermometer
//
//  Created by Don Coleman on 7/2/15.
//  Copyright (c) 2015 Don Coleman. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
    @property (strong, nonatomic) CBCentralManager *centralManager;
    @property (strong, nonatomic) CBPeripheral *peripheral;

@end

@implementation ViewController

static CBUUID* thermometerServiceUUID;
static CBUUID* temperatureUUID;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:nil];
    
    thermometerServiceUUID =[CBUUID UUIDWithString:@"BBB0"];
    temperatureUUID =[CBUUID UUIDWithString:@"BBB1"];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    
    if ([central state] == CBCentralManagerStatePoweredOn) {
        // begin scanning
        [_centralManager scanForPeripheralsWithServices:@[thermometerServiceUUID] options:nil];
        
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
    [peripheral discoverServices:@[thermometerServiceUUID]];
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
        NSArray* characteristics = @[temperatureUUID];
        [peripheral discoverCharacteristics:characteristics forService:service];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    
    for (CBCharacteristic *characteristic in service.characteristics) {
        NSLog(@"Discovered characteristic %@", characteristic);
        
        if ([characteristic.UUID isEqual: temperatureUUID]) {
            
            // subscribe for notifications
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            
            // read the current value, so we can update the UI
            [peripheral readValueForCharacteristic: characteristic];
            
        }
    }
    
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    if ([characteristic.UUID isEqual: temperatureUUID]) {
        
        NSData *data = characteristic.value;
        NSLog(@"%@", data);
        // http://stackoverflow.com/questions/18437535/get-float-value-from-nsdata-objective-c-ios
        uint32_t hostData = CFSwapInt32LittleToHost(*(const uint32_t *)[data bytes]);
        float value = *(float *)(&hostData);
        NSLog(@"celcius %f", value);
        float fahrenheit = 1.8 * value + 32;
        // degree symbol is shift + option + 8
        NSString* message = [NSString stringWithFormat:@"%0.1f°F", fahrenheit];
        [_temperatureLabel setText:message];
        
    }
    
}

#pragma mark - Timers

- (void) scanTimer:(NSTimer *)timer
{
    [_centralManager stopScan];
    
    if (!_peripheral) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Thermometer"
                                                        message:@"Could not find a thermometer."
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


@end

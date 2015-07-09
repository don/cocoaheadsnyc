//
//  ViewController.m
//  iBeacon
//
//  Created by Don Coleman on 7/3/15.
//  Copyright (c) 2015 Don Coleman. All rights reserved.
//

#import "ViewController.h"
#import <CoreLocation/CoreLocation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface ViewController () <CBPeripheralManagerDelegate>

@property (strong, nonatomic) CBPeripheralManager *peripheralManager;
@property (strong, nonatomic) CLBeaconRegion *region;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    _peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
    
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:@"12345678-AAAA-BBBB-CCCC-123456789ABC"];
    
    _region = [[CLBeaconRegion alloc] initWithProximityUUID:uuid
                                                      major:1
                                                      minor:1
                                                 identifier:@"com.example.beacon"];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Peripheral Methods

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    // Ignore anything but powered on
    if (peripheral.state != CBPeripheralManagerStatePoweredOn) {
        return;
    }
    
    NSLog(@"self.peripheralManager powered on.");
    
    NSDictionary *peripheralData = [_region peripheralDataWithMeasuredPower:nil];
    
    [_peripheralManager startAdvertising:peripheralData];
    
}

- (void) peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error {
    NSLog(@"Started advertising");
    if (error) {
        NSLog(@"There was an error advertising");
        NSLog(@"%@", error);
    }
    
}


@end

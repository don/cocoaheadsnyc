//
//  DevicesViewController.m
//  BluetoothScan
//
//  Created by Mike Bell on 6/2/16.
//  Copyright © 2016 Chariot Solutions. All rights reserved.
//

#import "DevicesViewController.h"

@interface DevicesViewController () {
    
    NSMutableArray *devices;
}
@property (strong, nonatomic) CBCentralManager *centralManager;
@property (strong, nonatomic) CBPeripheral *peripheral;

@end

@implementation DevicesViewController

static CBUUID* serviceUUID;

static double INTERVAL = 0.05; // 50 milliseconds
double lastTime = 0;

- (void)viewDidLoad {
    [super viewDidLoad];
//    devices = [NSMutableArray arrayWithObjects:@"BT Device1", @"BT Device2", @"BT Device3", nil];
    devices = [NSMutableArray array];
    
    _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:nil];

    serviceUUID =[CBUUID UUIDWithString:@"FF10"];
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
}


- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    
    NSLog(@"Discovered %@", peripheral.name);
    [devices addObject:peripheral.name];
    [[self tableView] reloadData];
    // we restricted the scan, so this is the device we want to connect to
//    [central stopScan];
    
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
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:error.localizedDescription
                                          message:error.localizedRecoverySuggestion
                                          preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *dismiss = [UIAlertAction actionWithTitle:@"OK"
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction *action) {
                                                    }];
    [alertController addAction:dismiss];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"Disconnected from %@", peripheral);
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:error.localizedDescription
                                          message:error.localizedRecoverySuggestion
                                          preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *dismiss = [UIAlertAction actionWithTitle:@"OK"
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction *action) {
                                                    }];
    [alertController addAction:dismiss];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - Timers

- (void) scanTimer:(NSTimer *)timer {
    [_centralManager stopScan];
    
    if (!_peripheral) {
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:@"No lightblub"
                                              message:@"Could not find a lightbulb"
                                              preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *dismiss = [UIAlertAction actionWithTitle:@"OK"
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction *action) {
                                  }];
        [alertController addAction:dismiss];
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

- (void) connectTimer:(NSTimer *)timer
{
    NSLog(@"Requesting connection to %@", _peripheral);
    [_centralManager connectPeripheral:_peripheral options:nil];
}

#pragma mark - tableView methods

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [devices count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    static NSString *CellIdentifier = @"deviceCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    cell.textLabel.text = [devices objectAtIndex:[indexPath row]];
    return cell;
}

@end

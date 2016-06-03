//
//  DevicesViewController.m
//  BluetoothScan
//
//  Created by Mike Bell on 6/2/16.
//  Copyright © 2016 Chariot Solutions. All rights reserved.
//

#import "DevicesViewController.h"
#import "DeviceTableViewCell.h"
#import "DeviceDetailViewController.h"

@interface DevicesViewController () {
    
    NSMutableArray *devices;
}
@property (strong, nonatomic) CBCentralManager *centralManager;
@property (strong, nonatomic) CBPeripheral *peripheral;
@property(nonatomic, strong) UIRefreshControl *refreshControl;

@end

@implementation DevicesViewController

static CBUUID* serviceUUID;

- (void)viewDidLoad {
    [super viewDidLoad];
    devices = [NSMutableArray array];
    
    _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:nil];

    serviceUUID =[CBUUID UUIDWithString:@"FF10"];
    
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.backgroundColor = [UIColor clearColor];
    self.refreshControl.tintColor = [UIColor lightGrayColor];
    self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to Refresh"];
    [self.refreshControl addTarget:self action:@selector(scanForDevices) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];

}

- (void)scanForDevices {
    NSLog(@"----- scanForDevices");
    [devices removeAllObjects];
    if ([_centralManager state] == CBCentralManagerStatePoweredOn) {
        NSLog(@"----- Starting Scan");
        [_centralManager scanForPeripheralsWithServices:@[serviceUUID] options:nil];
        // stop the scan
        float scanTimeout = 5;
        [NSTimer scheduledTimerWithTimeInterval:scanTimeout target:self selector:@selector(scanTimer:) userInfo:nil repeats:NO];
    }
}

#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    [self scanForDevices];
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    
    NSLog(@"Discovered %@", peripheral.name);
    if (peripheral.name) {
        [devices addObject:peripheral];
        [[self tableView] reloadData];
    }
}

#pragma mark - Timers

- (void) scanTimer:(NSTimer *)timer {
    NSLog(@"----- Stopping Scan");
    [_centralManager stopScan];
    [self.refreshControl endRefreshing];
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
    
    DeviceTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[DeviceTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    CBPeripheral *peripheral = [devices objectAtIndex:[indexPath row]];
    cell.lblDeviceName.text = peripheral.name;
    cell.lblUUID.text = [peripheral.identifier UUIDString];
//    cell.lblRSSI.text = [NSString stringWithFormat:@"%@",peripheral.RSSI];
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    _peripheral = [devices objectAtIndex:[indexPath row]];
    [self performSegueWithIdentifier:@"detailSegue" sender:nil];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    DeviceDetailViewController *detailController = segue.destinationViewController;
    [detailController setCentralManager:_centralManager];
    [detailController setPeripheral:_peripheral];
}

@end

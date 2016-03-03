//
//  FirstViewController.m
//  OverplayDemo
//
//  Created by Mitchell Kahn on 1/29/16.
//  Copyright © 2016 AppDelegates. All rights reserved.
//
#import <arpa/inet.h>

#import "FirstViewController.h"
#import "SecondViewController.h"
#import "Overplayer.h"
#import "AFNetworking.h"
#import "NetUtils.h"

@interface FirstViewController ()
@property (strong, nonatomic) IBOutlet UILabel *mainStatusLabel;
@property (strong, nonatomic) IBOutlet UITableView *foundUnitsTable;

@property (strong, nonatomic) NSMutableArray *availableOverplayers;
@property (strong, nonatomic) NSArray *sortedOverplayers;
@property (strong, nonatomic) NSString *iphoneIPAddress;

@property (strong, nonatomic) UIRefreshControl *refreshControl;
@property (nonatomic, assign) BOOL findingOverplayers;

@end

@implementation FirstViewController


-(void)sortByIpAndReload {
    // Call this instead of [self.foundUnitsTable reloadData].
    
    /*NSMutableArray *arrayToSort = [[NSMutableArray alloc] initWithArray:self.availableOverplayers copyItems:NO];
    arrayToSort = (NSMutableArray *)[arrayToSort sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        NSString *ipA = [(Overplayer *)a ipAddress];
        NSString *ipB = [(Overplayer *)b ipAddress];
        
        return [ipA compare:ipB options:NSNumericSearch];
    }];*/
    
    self.sortedOverplayers = [self.availableOverplayers sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        NSString *ipA = [(Overplayer *)a ipAddress];
        NSString *ipB = [(Overplayer *)b ipAddress];
        
        return [ipA compare:ipB options:NSNumericSearch];
    }];
    
    
    [self.foundUnitsTable reloadData];
}


-(void)findOverplayers {
    // only shows refreshing animation until it finds the first overplayer
    
    [self.refreshControl beginRefreshing];
    
    if (self.findingOverplayers == YES) {
        [self.refreshControl endRefreshing];
        return;
    } else {
        self.findingOverplayers = YES;
    }
    
    NSString *ipaddr = [NetUtils getIPAddress];
    
    if ([ipaddr hasPrefix:@"error"]){
        [self.refreshControl endRefreshing];
        self.mainStatusLabel.text = @"Not on a WiFi Net, Dumbass!";
        return;
        
    } else {
        self.iphoneIPAddress = [NetUtils getIPAddress];
        self.mainStatusLabel.text = [NSString stringWithFormat:@"My IP: %@", self.iphoneIPAddress];
    }
    
    [self.availableOverplayers removeAllObjects];
    
    AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] init];
    
    dispatch_group_t group = dispatch_group_create();
    
    NSArray *ipParts = [self.iphoneIPAddress componentsSeparatedByString:@"."];
    
    for (int lowIp = 2; lowIp <= 254; lowIp++) {
        NSString *toPing = [NSString stringWithFormat:@"http://%@.%@.%@.%d/api/v1/overplayos/index.php?command=identify", ipParts[0], ipParts[1], ipParts[2], lowIp];
        Overplayer *toAdd = [Overplayer new];
        toAdd.ipAddress = [NSString stringWithFormat:@"%@.%@.%@.%d", ipParts[0], ipParts[1], ipParts[2], lowIp];
        
        NSLog(@"Pinging: %@", toAdd.ipAddress);
        
        dispatch_group_enter(group);
        
        [manager GET:toPing
          parameters:nil
             success:^(AFHTTPRequestOperation *operation, id responseObject) {
                 NSLog(@"Found: %@", toAdd.ipAddress);
                 toAdd.systemName = [responseObject objectForKey:@"name"];
                 toAdd.location = [responseObject objectForKey:@"location"];
                 [self.availableOverplayers addObject:toAdd];
                 
                 dispatch_async(dispatch_get_main_queue(), ^{
                     [self.refreshControl endRefreshing];
                     [self sortByIpAndReload];
                 });
                 
                 dispatch_group_leave(group);
             }
             failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                 NSLog(@"Not found: %@", toAdd.ipAddress);
                 dispatch_group_leave(group);
             }];
    }
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        self.findingOverplayers = NO;
        [self.refreshControl endRefreshing];
        [self sortByIpAndReload];
    });
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.findingOverplayers = NO;
    
    self.foundUnitsTable.dataSource = self;
    self.foundUnitsTable.delegate = self;
    
    self.availableOverplayers = [NSMutableArray new];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(findOverplayers) forControlEvents:UIControlEventValueChanged];
    [self.foundUnitsTable addSubview:self.refreshControl];
    
    [self findOverplayers];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma - markup TableView Delegate Methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.sortedOverplayers count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *simpleTableIdentifier = @"SimpleTableItem";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@ at %@",
                           [[self.sortedOverplayers objectAtIndex:indexPath.row] systemName],
                           [[self.sortedOverplayers objectAtIndex:indexPath.row] ipAddress]];
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    //cell.imageView.image = [UIImage imageNamed:@"geekPic.jpg"];
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self performSegueWithIdentifier:@"toOPControl" sender:nil];
}


- (IBAction)refresh:(id)sender {
    [self findOverplayers];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"toOPControl"]) {
        [self.refreshControl endRefreshing];
        NSIndexPath *indexPath = [self.foundUnitsTable indexPathForSelectedRow];
        Overplayer *op = [self.sortedOverplayers objectAtIndex:indexPath.row];
        SecondViewController *svc = (SecondViewController *)[segue destinationViewController];
        [svc setOp:op];
    }
}

@end

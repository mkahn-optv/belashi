//
//  FirstViewController.m
//  OverplayDemo
//
//  Created by Mitchell Kahn on 1/29/16.
//  Copyright © 2016 AppDelegates. All rights reserved.
//

#import "FirstViewController.h"
#import "SecondViewController.h"
#import "Overplayer.h"
#import "AFNetworking.h"
#import "NetUtils.h"

@interface FirstViewController ()
@property (strong, nonatomic) IBOutlet UILabel *mainStatusLabel;
@property (strong, nonatomic) IBOutlet UITableView *foundUnitsTable;

@property (strong, nonatomic) NSMutableArray *availableOverplayers;
@property (strong, nonatomic) NSString *iphoneIPAddress;

@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

@end

@implementation FirstViewController


-(void)findOverplayers {
    
    [self.spinner startAnimating];
    NSString *ipaddr = [NetUtils getIPAddress];
    if ([ipaddr hasPrefix:@"error"]){
        [self.spinner stopAnimating];

        self.mainStatusLabel.text = @"Not on a WiFi Net, Dumbass!";
        return;
        
    } else {
        [self.spinner stopAnimating];

        self.iphoneIPAddress = [NetUtils getIPAddress];
        self.mainStatusLabel.text = [NSString stringWithFormat:@"My IP: %@", self.iphoneIPAddress];
    }
    
    
    [self.availableOverplayers removeAllObjects];
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    NSArray *ipParts = [self.iphoneIPAddress componentsSeparatedByString:@"."];
    
    for (int lowIp=2; lowIp<35; lowIp++) {
        NSString *toPing = [NSString stringWithFormat:@"http://%@.%@.%@.%d/api/v1/overplayos/index.php?command=identify", ipParts[0], ipParts[1], ipParts[2], lowIp];
        //NSLog(@"Pinging: %@", toPing);
        
        Overplayer *toAdd = [Overplayer new];
        toAdd.ipAddress = [NSString stringWithFormat:@"%@.%@.%@.%d", ipParts[0], ipParts[1], ipParts[2], lowIp];
        
        [manager GET:toPing
          parameters:nil
             success:^(AFHTTPRequestOperation *operation, id responseObject) {
                 NSLog(@"Found: %@", toAdd.ipAddress);
                 toAdd.systemName = [responseObject objectForKey:@"name"];
                 toAdd.location = [responseObject objectForKey:@"location"];
                 [self.availableOverplayers addObject:toAdd];
                 dispatch_async(dispatch_get_main_queue(), ^{
                     [self.foundUnitsTable reloadData];
                 });
                 
             } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                 NSLog(@"Not found: %@", toAdd.ipAddress);
             }];

        
    }
    
 }

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    /*
    Overplayer *op1 = [Overplayer new];
    op1.systemName = @"System One";
    
    Overplayer *op2 = [Overplayer new];
    op2.systemName = @"System Dos";

    Overplayer *op3 = [Overplayer new];
    op3.systemName = @"System Trois";

    
     */
    
    self.foundUnitsTable.dataSource = self;
    self.foundUnitsTable.delegate = self;
    
    //self.availableOverplayers = [NSMutableArray arrayWithObjects:op1, op2, op3, nil];
    self.availableOverplayers = [NSMutableArray new];
    

    
    [self findOverplayers];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma - markup TableView Delegate Methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section

{
    
    return [self.availableOverplayers count];
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath

{
    
    static NSString *simpleTableIdentifier = @"SimpleTableItem";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    
    if (cell == nil) {
        
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
        
    }
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@ at %@",
                           [[self.availableOverplayers objectAtIndex:indexPath.row] systemName],
                           [[self.availableOverplayers objectAtIndex:indexPath.row] ipAddress]];
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    
    //cell.imageView.image = [UIImage imageNamed:@"geekPic.jpg"];
    
    return cell;
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath

{
    NSLog(@"Yeah fucker, picked %ld", (long)indexPath.row);
    [self performSegueWithIdentifier:@"toOPControl" sender:nil];
    
}
- (IBAction)refresh:(id)sender {
    [self findOverplayers];

}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"toOPControl"])
    {
        NSIndexPath *indexPath = [self.foundUnitsTable indexPathForSelectedRow];
        Overplayer *op = [self.availableOverplayers objectAtIndex:indexPath.row];
        SecondViewController *svc = (SecondViewController *)[segue destinationViewController];
        [svc setOp:op];
    }
}
@end

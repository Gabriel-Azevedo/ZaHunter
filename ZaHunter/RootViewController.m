//
//  ViewController.m
//  ZaHunter
//
//  Created by Gabriel Borri de Azevedo on 1/21/15.
//  Copyright (c) 2015 Gabriel Enterprises. All rights reserved.
//

#import "RootViewController.h"
#import "Pizzeria.h"
#import "MapViewController.h"
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

@interface RootViewController () <UITableViewDataSource, UITableViewDelegate, CLLocationManagerDelegate>

@property NSMutableArray *pizzeriasArray;
@property CLLocationManager *locationManager;
@property CLLocation *currentLocation;
@property Pizzeria *pizzeria;
@property NSMutableArray *minutesArray;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UITextView *textView;

@end

@implementation RootViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.locationManager = [CLLocationManager new];
    self.locationManager.delegate = self;
    self.pizzeriasArray = [NSMutableArray new];
    self.minutesArray = [NSMutableArray new];
    [self updateCurrentLocation];
}

-(void)updateCurrentLocation
{
    [self.locationManager requestAlwaysAuthorization];
    [self.locationManager startUpdatingLocation];
}

#pragma mark - CLLocation Delegate Methods
-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"%@",error);
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    self.currentLocation = locations.firstObject;

    NSLog(@"vertical = %f, horizontal = %f",self.currentLocation.verticalAccuracy, self.currentLocation.horizontalAccuracy);
    if (self.currentLocation.verticalAccuracy < 9 && self.currentLocation.horizontalAccuracy < 500)
    {
        [self findPizzaPlacesNear:self.currentLocation];
        [self.locationManager stopUpdatingLocation];
    }

}

#pragma mark - Custom Methods
-(void)findPizzaPlacesNear:(CLLocation *)location
{
    MKLocalSearchRequest *request = [MKLocalSearchRequest new];
    request.naturalLanguageQuery = @"pizza";
    request.region = MKCoordinateRegionMake(location.coordinate, MKCoordinateSpanMake(0.005, 0.005));

    MKLocalSearch *search = [[MKLocalSearch alloc] initWithRequest:request];
    [search startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error) {

        NSArray *mapItems = response.mapItems;

        NSMutableArray *temporaryArray = [NSMutableArray new];

        for (MKMapItem *mapItem in mapItems)
        {

            CLLocationDistance metersAway = [mapItem.placemark.location distanceFromLocation:location];
            Pizzeria *pizzeria = [Pizzeria new];
            pizzeria.mapItem = mapItem;
            pizzeria.metersAway = metersAway;
            pizzeria.coordinate = mapItem.placemark.location.coordinate;

            [temporaryArray addObject:pizzeria];
        }
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"metersAway" ascending:true];
        NSArray *sortedArray = [temporaryArray sortedArrayUsingDescriptors:@[sortDescriptor]];
        self.pizzeriasArray = [NSMutableArray arrayWithArray:sortedArray];
        [self.tableView reloadData];
        [self createSourceAndDestination];

    }];
}

-(void)createSourceAndDestination
{
    [self.tableView reloadData];
    CLLocationCoordinate2D sourceCLL;
    CLLocationCoordinate2D destinationCLL;
    for (int i = 0; i < 5; i++)
    {
        Pizzeria *pizzaria = [self.pizzeriasArray objectAtIndex:i];
        Pizzeria *pizzaria2;

        if (i == 0)
        {
            sourceCLL = CLLocationCoordinate2DMake(self.currentLocation.coordinate.latitude, self.currentLocation.coordinate.longitude);
            pizzaria2 = [self.pizzeriasArray objectAtIndex:i+1];
            destinationCLL = pizzaria2.coordinate;
        }
        else if (i == 5)
        {
            sourceCLL = pizzaria.coordinate;
            destinationCLL = CLLocationCoordinate2DMake(self.currentLocation.coordinate.latitude, self.currentLocation.coordinate.longitude);
        }
        else
        {
            sourceCLL = pizzaria.coordinate;
            pizzaria2 = [self.pizzeriasArray objectAtIndex:i+1];
            destinationCLL = pizzaria2.coordinate;
        }

        [self getPathDirection:sourceCLL andDestination:destinationCLL];
    }
}

-(void)getPathDirection:(CLLocationCoordinate2D)source andDestination:(CLLocationCoordinate2D)destination
{
    MKPlacemark *sourcePlacemark = [[MKPlacemark alloc] initWithCoordinate:source addressDictionary:nil];
    MKMapItem *sourceMapItem = [[MKMapItem alloc] initWithPlacemark:sourcePlacemark];

    MKPlacemark *destinationPlacemark = [[MKPlacemark alloc] initWithCoordinate:destination addressDictionary:nil];
    MKMapItem *destinationMapItem = [[MKMapItem alloc] initWithPlacemark:destinationPlacemark];

    MKDirectionsRequest *request = [[MKDirectionsRequest alloc] init];
    [request setSource:sourceMapItem];
    [request setDestination:destinationMapItem];
    [request setTransportType:MKDirectionsTransportTypeWalking];
    request.requestsAlternateRoutes = NO;

    MKDirections *directions = [[MKDirections alloc] initWithRequest:request];

    [directions calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
        MKRoute *route = response.routes.lastObject;

        NSString *time = [NSString stringWithFormat:@"%.2f", (route.expectedTravelTime)/60];
        //NSLog(@"%@",time);
        [self.minutesArray addObject:time];
        [self displayTime];
    }];

}

-(void)displayTime
{
    double count = 200;
    NSString *text = @"Leaving your current location,";
    for (int i = 0; i < self.minutesArray.count-1; i++)
    {
        text = [text stringByAppendingString:@"you will arrive at "];
        text = [text stringByAppendingString:[[[self.pizzeriasArray objectAtIndex:i] mapItem] name]];
        text = [text stringByAppendingString:@" within "];
        text = [text stringByAppendingString:[self.minutesArray objectAtIndex:i]];
        text = [text stringByAppendingString:@" minutes.\nAfter that, "];
        count += [[self.minutesArray objectAtIndex:i] doubleValue];
    }
    text = [text stringByAppendingString:@"you will arrive at your starting point"];
    text = [text stringByAppendingString:@" within "];
    text = [text stringByAppendingString:[self.minutesArray lastObject]];
    text = [text stringByAppendingString:@" minutes."];
    text = [text stringByAppendingString:[NSString stringWithFormat:@"\nTotal Time: %.2f min",count]];

    self.textView.text = text;
}



#pragma mark - UITableView Delegate Methods
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    Pizzeria *pizzaria = [self.pizzeriasArray objectAtIndex:indexPath.row];
    cell.textLabel.text = [[pizzaria mapItem] name];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%.2f km", pizzaria.metersAway/1000];
    return cell;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.pizzeriasArray.count >= 4)
    {
        return 4;
    }
    else
    {
        return 0;
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    MapViewController *mapVC = [segue destinationViewController];
    mapVC.pizzeriasArray = self.pizzeriasArray;
}


@end

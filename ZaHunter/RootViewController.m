//
//  ViewController.m
//  ZaHunter
//
//  Created by Gabriel Borri de Azevedo on 1/21/15.
//  Copyright (c) 2015 Gabriel Enterprises. All rights reserved.
//

#import "RootViewController.h"
#import "Pizzeria.h"
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

@interface RootViewController () <UITableViewDataSource, UITableViewDelegate, CLLocationManagerDelegate>

@property NSArray *pizzeriasArray;
@property CLLocationManager *locationManager;
@property CLLocation *currentLocation;
@property Pizzeria *pizzeria;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UITextView *textView;

@end

@implementation RootViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.locationManager = [CLLocationManager new];
    self.locationManager.delegate = self;
    self.pizzeriasArray = [NSArray new];
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
    [self.locationManager stopUpdatingLocation];
    if (self.currentLocation.verticalAccuracy < 10000 && self.currentLocation.horizontalAccuracy < 10000)
    {
        [self findPizzaPlacesNear:self.currentLocation];
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
            NSLog(@"%@, %.3f",[[pizzeria mapItem] name], metersAway/1000);

            [temporaryArray addObject:pizzeria];
        }
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"metersAway" ascending:true];
        NSArray *sortedArray = [temporaryArray sortedArrayUsingDescriptors:@[sortDescriptor]];
        self.pizzeriasArray = [NSArray arrayWithArray:sortedArray];
        [self.tableView reloadData];
    }];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Pizzeria *pizzaria = [self.pizzeriasArray objectAtIndex:indexPath.row];
    Pizzeria *pizzaria2 = [self.pizzeriasArray objectAtIndex:indexPath.row+1];
    CLLocationCoordinate2D sourceCLL = pizzaria.coordinate;
    CLLocationCoordinate2D destinationCLL = pizzaria2.coordinate;

    [self getPathDirection:sourceCLL andDestination:destinationCLL];

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

//        NSString *allSteps = [NSString new];
//
//        for (int i = 0; i < route.steps.count; i++)
//        {
//            MKRouteStep *step = [route.steps objectAtIndex:i];
//            NSString *newStepString = step.instructions;
//            allSteps = [allSteps stringByAppendingString:newStepString];
//            allSteps = [allSteps stringByAppendingString:@"\n\n"];
//        }
        NSLog(@"%.2f meters",route.distance);

        self.textView.text = allSteps;
        
    }];
    
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



@end

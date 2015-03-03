//
//  HeatMapViewController.m
//  HeatMapExample
//
//  Created by Ryan Olson on 12-03-04.
//  Copyright (c) 2012 Ryan Olson. 
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is furnished
// to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "HeatMapViewController.h"
#import "parseCSV.h"

enum segmentedControlIndicies {
    kSegmentStandard = 0,
    kSegmentSatellite = 1,
    kSegmentHybrid = 2,
    kSegmentTerrain = 3
};

@interface HeatMapViewController(){
    HeatMapView * heatMapView;
}

- (NSDictionary *)heatMapData;
@property (weak, nonatomic) IBOutlet UILabel *valueLabel;
@property (weak, nonatomic) IBOutlet UILabel *valueLabel2;

@end

@implementation HeatMapViewController
@synthesize mapView = _mapView;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
    self.mapView.delegate = self;
    
    HeatMap *hm = [[HeatMap alloc] initWithData:[self heatMapData]];
    [self.mapView addOverlay:hm];
    [self.mapView setVisibleMapRect:[hm boundingMapRect] animated:YES];
}

- (IBAction)mapTypeChanged:(UISegmentedControl *)sender {
    switch (sender.selectedSegmentIndex) {
        case kSegmentStandard:
            self.mapView.mapType = MKMapTypeStandard;
            break;
            
        case kSegmentSatellite:
            self.mapView.mapType = MKMapTypeSatellite;
            break;
        
        case kSegmentHybrid:
            self.mapView.mapType = MKMapTypeHybrid;
            break;
            
        case kSegmentTerrain:
            self.mapView.mapType = 3;
            break;
    }
}

- (NSDictionary *)heatMapData
{
    CSVParser *parser = [CSVParser new];
    NSString *csvFilePath = [[NSBundle mainBundle] pathForResource:@"Breweries_clean" ofType:@"csv"];
    [parser openFile:csvFilePath];
    NSArray *csvContent = [parser parseFile];
    
    NSMutableDictionary *toRet = [[NSMutableDictionary alloc] initWithCapacity:[csvContent count]];
    
    for (NSArray *line in csvContent) {
        
        MKMapPoint point = MKMapPointForCoordinate(
            CLLocationCoordinate2DMake([[line objectAtIndex:1] doubleValue], 
                                       [[line objectAtIndex:0] doubleValue]));
        
        NSValue *pointValue = [NSValue value:&point withObjCType:@encode(MKMapPoint)];
        [toRet setObject:[NSNumber numberWithInt:2] forKey:pointValue];
    }
    
    return toRet;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    [self setMapView:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark -
#pragma mark MKMapViewDelegate

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay
{
    heatMapView = [[HeatMapView alloc] initWithOverlay:overlay];
    return heatMapView;
}


// This sets the spread of the heat from each map point (in screen pts.)
//static const NSInteger kSBHeatRadiusInPoints = 48;

// These affect the transparency of the heatmap
// Colder areas will be more transparent
// Currently the alpha is a two piece linear function of the value
// Play with the pivot point and max alpha to affect the look of the heatmap

// This number should be between 0 and 1
static const CGFloat kSBAlphaPivotX = 0.333;

// This number should be between 0 and MAX_ALPHA
static const CGFloat kSBAlphaPivotY = 0.5;

// This number should be between 0 and 1
static const CGFloat kSBMaxAlpha = 0.85;

- (void)colorForValue:(double)value red:(CGFloat *)red green:(CGFloat *)green blue:(CGFloat *)blue alpha:(CGFloat *)alpha
{
    if (value > 1) value = 1;
    value = sqrt(value);
    
    if (value < kSBAlphaPivotY) {
        *alpha = value * kSBAlphaPivotY / kSBAlphaPivotX;
    } else {
        *alpha = kSBAlphaPivotY + ((kSBMaxAlpha - kSBAlphaPivotY) / (1 - kSBAlphaPivotX)) * (value - kSBAlphaPivotX);
    }
    
    //formula converts a number from 0 to 1.0 to an rgb color.
    //uses MATLAB/Octave colorbar code
    if(value <= 0) {
        *red = *green = *blue = *alpha = 0;
    } else if(value < 0.125) {
        *red = *green = 0;
        *blue = 4 * (value + 0.125);
    } else if(value < 0.375) {
        *red = 0;
        *green = 4 * (value - 0.125);
        *blue = 1;
    } else if(value < 0.625) {
        *red = 4 * (value - 0.375);
        *green = 1;
        *blue = 1 - 4 * (value - 0.375);
    } else if(value < 0.875) {
        *red = 1;
        *green = 1 - 4 * (value - 0.625);
        *blue = 0;
    } else {
        *red = MAX(1 - 4 * (value - 0.875), 0.5);
        *green = *blue = 0;
    }
}

- (IBAction)testSlider:(UISlider *)sender {
    CGFloat red, green, blue, alpha;
    
    [self colorForValue:sender.value red:&red green:&green blue:&blue alpha:&alpha];
//    CGContextSetRGBFillColor(context, red, green, blue, alpha);
    [self.valueLabel setBackgroundColor:[UIColor colorWithRed:red green:green blue:blue alpha:alpha]];
    [self.valueLabel setText:[NSString stringWithFormat:@"%f",sender.value]];
}
- (IBAction)testSlider2:(UISlider *)sender {
    int value = sender.value;
    [heatMapView setHeatRadiusInPoints:value];
    [self.valueLabel2 setText:[NSString stringWithFormat:@"%d",value]];
}

@end

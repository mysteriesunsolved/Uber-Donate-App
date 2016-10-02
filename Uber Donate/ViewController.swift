//
//  ViewController.swift
//  Uber Donate
//
//  Created by Sanaya Sanghvi on 01/10/16.
//  Copyright © 2016 0110_0010_0000. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import UberRides
import AFNetworking
import Social
//hiiiiiii
protocol HandleMapSearch {
    func dropPinZoomIn(placemark:MKPlacemark)
}

class ViewController: UIViewController, RideRequestButtonDelegate {

    @IBOutlet weak var uberMap: MKMapView!
    
    @IBOutlet weak var requestButton: UIButton!
    
    @IBOutlet weak var facebookButton: UIButton!
    
    @IBOutlet weak var donateLabel: UILabel!
    
    let server_token = "kUp-kJfdmCUYrFCOFwbvW-xLxGVeKCCC7DPsecq-"
    
   
    var longitude = 0.0
    var latitude = 0.0
    var dropOffLongitude = 0.0
    var dropOffLatitude = 0.0
    let ridesClient = RidesClient()
    let button = RideRequestButton()
    
    let locationManager = CLLocationManager()
    
    var resultSearchController:UISearchController? = nil
    
    var selectedPin:MKPlacemark? = nil
    
    
    //drop off location search
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        facebookButton.layer.cornerRadius = facebookButton.frame.width/2
        uberMap.addSubview(facebookButton)
        
        //search table
        let locationSearchTable = storyboard!.instantiateViewControllerWithIdentifier("LocationSearchController") as! LocationSearchController
        resultSearchController = UISearchController(searchResultsController: locationSearchTable)
        resultSearchController?.searchResultsUpdater = locationSearchTable
        
        
        let searchBar = resultSearchController!.searchBar
        searchBar.sizeToFit()
        searchBar.backgroundColor = UIColor.blackColor()
        searchBar.barTintColor = UIColor.blackColor()
        searchBar.tintColor = UIColor.redColor()
        searchBar.placeholder = "Search for places"
        navigationItem.titleView = resultSearchController?.searchBar
        
        
        resultSearchController?.hidesNavigationBarDuringPresentation = false
        resultSearchController?.dimsBackgroundDuringPresentation = true
        definesPresentationContext = true
        
        
        
        locationSearchTable.mapView = uberMap
        
        locationSearchTable.handleMapSearchDelegate = self

        //location stuff
    
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()

        //uber stuff
        requestButton.hidden = true
        
        
        button.delegate = self
        
        let dropoffLocation = CLLocation(latitude: dropOffLatitude, longitude: dropOffLongitude)
        let pickupLocation = CLLocation(latitude: latitude, longitude: longitude)
        let builder = RideParametersBuilder()
            .setPickupLocation(pickupLocation)
            // nickname or address is required to properly display destination on the Uber App
            .setDropoffLocation(dropoffLocation)
        
        
            ridesClient.fetchCheapestProduct(pickupLocation: pickupLocation, completion: {
            product, response in
            if let productID = product?.productID { //check if the productID exists
                builder.setProductID(productID)
                self.button.rideParameters = builder.build()
                
                // show estimate in the button
                self.button.loadRideInformation()
            }
        })

      
        uberMap.addSubview(button)
        button.center = uberMap.center
        button.frame.origin.y = requestButton.frame.origin.y
        
        uberMap.addSubview(donateLabel)
        donateLabel.hidden = true
       
                // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func rideRequestButtonDidLoadRideInformation(button: RideRequestButton) {
        button.sizeToFit()
        button.center = view.center
        button.frame.origin.y = requestButton.frame.origin.y
    }
    
    func rideRequestButton(button: RideRequestButton, didReceiveError error: RidesError) {
        // error handling
        print("failed")
    }

    @IBAction func facebookButtonPushed(sender: AnyObject) {
        
       
            if SLComposeViewController.isAvailableForServiceType(SLServiceTypeFacebook){
                let facebookSheet:SLComposeViewController = SLComposeViewController(forServiceType: SLServiceTypeFacebook)
                facebookSheet.setInitialText("I donated a ride to Uber today! You should too!")
                self.presentViewController(facebookSheet, animated: true, completion: nil)
            } else {
                let alert = UIAlertController(title: "Accounts", message: "Please login to a Facebook account to share.", preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
            }
        }
    

}

extension ViewController: CLLocationManagerDelegate {
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .AuthorizedWhenInUse {
            locationManager.requestLocation()
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            let span = MKCoordinateSpanMake(0.05, 0.05)
            let region = MKCoordinateRegion(center: location.coordinate, span: span)
            uberMap.setRegion(region, animated: true)
            let locationArray = locations as NSArray
            let locationObj = locationArray.lastObject as! CLLocation
            let coord = locationObj.coordinate
            longitude = coord.longitude
            latitude = coord.latitude

        }
        
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("error:: (error)")
    }
    
    
}



extension ViewController: HandleMapSearch {
    func dropPinZoomIn(placemark:MKPlacemark){
        // cache the pin
        selectedPin = placemark
        // clear existing pins
        uberMap.removeAnnotations(uberMap.annotations)
        let annotation = MKPointAnnotation()
        annotation.coordinate = placemark.coordinate
        annotation.title = placemark.name
        if let city = placemark.locality,
            let state = placemark.administrativeArea {
            annotation.subtitle = "(city) (state)"
        }
        uberMap.addAnnotation(annotation)
        let span = MKCoordinateSpanMake(0.05, 0.05)
        let region = MKCoordinateRegionMake(placemark.coordinate, span)
        uberMap.setRegion(region, animated: true)
        
        let dropOffCoord = placemark.coordinate
        dropOffLatitude = dropOffCoord.latitude
        dropOffLongitude = dropOffCoord.longitude
        
        button.delegate = self
        
        let dropoffLocation = CLLocation(latitude: dropOffLatitude, longitude: dropOffLongitude)
        let pickupLocation = CLLocation(latitude: latitude, longitude: longitude)
        let builder = RideParametersBuilder()
            .setPickupLocation(pickupLocation)
            // nickname or address is required to properly display destination on the Uber App
            .setDropoffLocation(dropoffLocation)
        
        
        ridesClient.fetchCheapestProduct(pickupLocation: pickupLocation, completion: {
            product, response in
            if let productID = product?.productID { //check if the productID exists
                builder.setProductID(productID)
                self.button.rideParameters = builder.build()
                
                // show estimate in the button
                self.button.loadRideInformation()
                
                let url = NSURL(string: "https://api.uber.com/v1/estimates/price?start_latitude=" + String(self.latitude) + "&start_longitude=" + String(self.longitude) + "&end_latitude=" + String(self.dropOffLatitude) + "&end_longitude=" + String(self.dropOffLongitude))
                let request = NSMutableURLRequest(URL: url!)
                request.HTTPMethod = "GET"
                request.setValue("Token kWHSMejyzdpLL7-OoNpSPQSbHgzFF1TuFxmEOrtO", forHTTPHeaderField: "Authorization")
                let session1 = NSURLSession.sharedSession()
                session1.dataTaskWithRequest(request, completionHandler: { (returnData, response, error) -> Void in
                    do {
                        let response = try! NSJSONSerialization.JSONObjectWithData(returnData!, options: NSJSONReadingOptions())
                        print(response)
                        let uberCars = response["prices"] as! NSArray
                        
    
                        for uberCar in uberCars {
                            let carName = uberCar["display_name"] as! String
                            if carName == "uberX" {
                                dispatch_async(dispatch_get_main_queue(), {
                                   
                                    let highEstimate = uberCar["high_estimate"] as! Float
                                    let lowEstimate = uberCar["low_estimate"] as! Float
                                    
                                    print(highEstimate)
                                    print(lowEstimate)
                                    let averagePrice = (highEstimate+lowEstimate)/2
                                    print(averagePrice)
                                    
                                    let simulatedPrice = averagePrice + 0.37
                                    
                                    print(simulatedPrice)
                                    
                                    let roundUp = floor(simulatedPrice + 1)
                                    print (roundUp)
                                    let donate = roundUp - simulatedPrice
                                    print(donate)
                                    
                                    self.donateLabel.text = "Price = $\(simulatedPrice)\nPay $\(roundUp) and donate a ride worth $\(donate)?"
                                  
                                  
                                    
                                    self.donateLabel.frame = CGRectMake(self.button.frame.origin.x, self.button.frame.origin.y + 50, self.button.frame.width + 5, self.button.frame.height)
                                    self.donateLabel.adjustsFontSizeToFitWidth = true
                                    self.donateLabel.layer.cornerRadius = self.button.layer.cornerRadius
                                    self.donateLabel.hidden = false

                                    
                                })
                                
                                
                            }
                        }
                    } catch {
                        print(error)
                    }
                }).resume()

                
            }
        })

    }
}

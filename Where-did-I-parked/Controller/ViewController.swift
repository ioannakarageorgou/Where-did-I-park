//
//  ViewController.swift
//  Where-did-I-parked
//
//  Created by Ioanna Karageorgou on 28/11/22.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController {

    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var locationLabel: UIButton!
    @IBOutlet weak var justParkedButton: UIButton!
    @IBOutlet weak var findCarButton: UIButton!
    
    let locationManager = CLLocationManager()
    var parkingModeEnabled: Bool = true
    
    let userDefaults = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationLabel.isHidden = true
        justParkedButton.addBlurEffect(style: .regular, cornerRadius: 10, padding: 0)
        findCarButton.addBlurEffect(style: .regular, cornerRadius: 10, padding: 0)
        
        map.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
//        locationManager.startUpdatingLocation()
//        map.showsUserLocation = true
        
        if let currentLocation = loadUserLocation(), let currentAddress = loadUserAddress() {
            print("LOADED: currentLocation = \(currentLocation), currentAddress = \(currentAddress)")
            removeOldAnnotations()
            addPinToCurrentLocation(currentLocation)
            updateCurrentAddressButton(with: currentAddress)
        }
        
        self.overrideUserInterfaceStyle = .dark
    }

    @IBAction func justParkedPressed(_ sender: Any) {
        parkingModeEnabled = true
        startUpdatingLocation()
    }
    
    @IBAction func findMyCarPressed(_ sender: Any) {
        parkingModeEnabled = false
        startUpdatingLocation()
    }
    
    func startUpdatingLocation() {
        locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
        }
    }
    
    func saveUserLocation(_ location: CLLocation) {
        if let encodedLocation = try? NSKeyedArchiver.archivedData(withRootObject: location, requiringSecureCoding: false) {
            userDefaults.set(encodedLocation, forKey: "savedLocation")
        }
    }
    
    func loadUserLocation() -> CLLocation? {
        if let loadedLocation = userDefaults.data(forKey: "savedLocation"),
           let decodedLocation = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(loadedLocation) as? CLLocation {
            return decodedLocation
        }
        return nil
    }
    
    func saveUserAddress(_ address: String) {
        userDefaults.set(address, forKey: "savedAddress")
    }
    
    func loadUserAddress() -> String? {
        if let loadedAddress = userDefaults.string(forKey: "savedAddress") {
            return loadedAddress
        }
        return nil
    }
    
    func addPinToCurrentLocation(_ location: CLLocation) {
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        let coordinates = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        let region = MKCoordinateRegion(center: coordinates, span: MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003))
        map.setRegion(region, animated: true)
        
        let mkAnnotation: MKPointAnnotation = MKPointAnnotation()
        mkAnnotation.coordinate = CLLocationCoordinate2DMake(lat, lon)
        map.addAnnotation(mkAnnotation)
    }
    
    func createRoute(_ location: CLLocation) {
        let currentLocation = CLLocationCoordinate2D.init(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        if let parkingLocation = loadUserLocation() {
            let destination = CLLocationCoordinate2D.init(latitude: parkingLocation.coordinate.latitude, longitude: parkingLocation.coordinate.longitude)
            showRouteOnMap(pickupCoordinate: currentLocation, destinationCoordinate: destination)
        }
    }
    
    func updateCurrentAddressButton(with title: String) {
        DispatchQueue.main.async {
            if !title.isEmpty {
                self.locationLabel.isHidden = false
                self.locationLabel.addBlurEffect(style: .regular, cornerRadius: 20, padding: 0)
                self.locationLabel.setTitle(title, for: .normal)
            }
        }
    }
    
    func showRouteOnMap(pickupCoordinate: CLLocationCoordinate2D, destinationCoordinate: CLLocationCoordinate2D) {

            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: pickupCoordinate, addressDictionary: nil))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destinationCoordinate, addressDictionary: nil))
            request.requestsAlternateRoutes = true
            request.transportType = .automobile

            let directions = MKDirections(request: request)

            directions.calculate { [unowned self] response, error in
                guard let unwrappedResponse = response else { return }
                
                //for getting just one route
                if let route = unwrappedResponse.routes.first {
                    //show on map
                    self.map.addOverlay(route.polyline)
                    //set the map area to show the route
                    self.map.setVisibleMapRect(route.polyline.boundingMapRect, edgePadding: UIEdgeInsets.init(top: 80.0, left: 20.0, bottom: 100.0, right: 20.0), animated: true)
                }

                //if you want to show multiple routes then you can get all routes in a loop in the following statement
                //for route in unwrappedResponse.routes {}
            }
        }
}

//MARK: - CLLocation Manager Delegate Methods

extension ViewController : CLLocationManagerDelegate {
    
////    This method can cause UI unresponsiveness if invoked on the main thread. Instead, consider waiting for the `-locationManagerDidChangeAuthorization:` callback and checking `authorizationStatus` first.
////
//    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
//        if manager.authorizationStatus == CLAuthorizationStatus.denied {
//            // The user denied authorization
//        } else if manager.authorizationStatus == CLAuthorizationStatus.authorizedAlways {
//            // The user accepted authorization
//        }
//    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("locationManager.didFailWithError \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if let location = locations.last {
            locationManager.stopUpdatingLocation()
            
            if parkingModeEnabled {
                // add pin to current location and save it as a parking spot
                removeOldAnnotations()
                addPinToCurrentLocation(location)
                
                saveUserLocation(location)
                let currentAddress = getUserAddress(location)
                saveUserAddress(currentAddress)
            } else {
               createRoute(location)
            }
        }
    }
    
    func getUserAddress(_ location: CLLocation) -> String {
        var currentAddress: String = ""
        let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location) { (placemarksArray, error) in
                print(placemarksArray!)
                if (error) == nil {
                    if placemarksArray!.count > 0 {
                        let placemark = placemarksArray?[0]
                        let address = "\(placemark?.thoroughfare ?? "") \(placemark?.subThoroughfare ?? "") \(placemark?.locality ?? "") \(placemark?.postalCode ?? "") \(placemark?.country ?? "")"
                        print("getUserAddress:: current address: \(address)")
                        currentAddress = address
                        self.saveUserAddress(currentAddress)
                        self.updateCurrentAddressButton(with: address)
                    }
                }

            }
        return currentAddress
    }
    
    func removeOldAnnotations() {
        let annotations = self.map.annotations
        print("Removing old annotations (\(annotations.count)")
        for annotation in annotations {
            self.map.removeAnnotation(annotation)
        }
    }
}

//MARK: - MKMap View Delegate Methods

extension ViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
//        if parkingModeEnabled {
            let annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "MyMarker")
            annotationView.markerTintColor = UIColor(rgb: 0x4543A4)
            annotationView.glyphImage = UIImage(named: "car.rear")
            return annotationView
//        } else {
//            return nil
//        }
    }
    
    //this delegate function is for displaying the route overlay and styling it
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
         let renderer = MKPolylineRenderer(overlay: overlay)
         renderer.strokeColor = UIColor.red
         renderer.lineWidth = 5.0
         return renderer
    }
}

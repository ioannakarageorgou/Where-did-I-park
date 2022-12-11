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
        
        if let currentLocation = loadUserLocation(), let currentAddress = loadUserAddress() {
            print("LOADED: currentLocation = \(currentLocation), currentAddress = \(currentAddress)")
            removeOldAnnotations()
            addPinToCurrentLocation(currentLocation)
            updateCurrentAddressButton(with: currentAddress)
        }
        
//        self.overrideUserInterfaceStyle = .dark
    }

    @IBAction func justParkedPressed(_ sender: Any) {
        locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
        }
    }
    
    @IBAction func findMyCarPressed(_ sender: Any) {
        if let parkingLocation = loadUserLocation() {
            openGoogleMap(to: parkingLocation)
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
    
    func updateCurrentAddressButton(with title: String) {
        DispatchQueue.main.async {
            if !title.isEmpty {
                self.locationLabel.isHidden = false
                self.locationLabel.addBlurEffect(style: .regular, cornerRadius: 20, padding: 0)
                self.locationLabel.setTitle(title, for: .normal)
            }
        }
    }
    
    func openGoogleMap(to location: CLLocation) {
        if let parkingLocation = loadUserLocation() {
            let destLat = parkingLocation.coordinate.latitude
            let destLon = parkingLocation.coordinate.longitude
            
            if (UIApplication.shared.canOpenURL(URL(string:"comgooglemaps://")!)) {
                //if phone has an app(
                if let url = URL(string: "comgooglemaps-x-callback://?saddr=&daddr=\(Double(destLat)),\(Double(destLon))&directionsmode=walking") {
                    UIApplication.shared.open(url, options: [:])
                 }
            } else {
                //Open in browser
                if let urlDestination = URL.init(string: "https://www.google.co.in/maps/dir/?saddr=&daddr=\(Double(destLat)),\(Double(destLon))&directionsmode=walking") {
                    UIApplication.shared.open(urlDestination)
                }
            }
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
            
            // add pin to current location and save it as a parking spot
            removeOldAnnotations()
            addPinToCurrentLocation(location)
            
            saveUserLocation(location)
            let currentAddress = getUserAddress(location)
            saveUserAddress(currentAddress)
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
        let annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "MyMarker")
        annotationView.markerTintColor = UIColor(rgb: 0x4543A4)
        annotationView.glyphImage = UIImage(named: "car.rear")
        return annotationView
    }
    
    //this delegate function is for displaying the route overlay and styling it
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
         let renderer = MKPolylineRenderer(overlay: overlay)
         renderer.strokeColor = UIColor.red
         renderer.lineWidth = 5.0
         return renderer
    }
}

//
//  ViewController.swift
//  Where-did-I-parked
//
//  Created by Ioanna Karageorgou on 28/11/22.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var locationLabel: UIButton!
    @IBOutlet weak var justParkedButton: UIButton!
    @IBOutlet weak var findCarButton: UIButton!
    
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        justParkedButton.addBlurEffect(style: .regular, cornerRadius: 10, padding: 0)
        findCarButton.addBlurEffect(style: .regular, cornerRadius: 10, padding: 0)
        
        map.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
//        self.overrideUserInterfaceStyle = .dark
//        let darkLayer = CALayer()
//        darkLayer.frame = self.view.bounds
//        darkLayer.compositingFilter = "darkMode"
//        darkLayer.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.4).cgColor
//        self.map.layer.addSublayer(darkLayer)

    }

    @IBAction func justParkedPressed(_ sender: Any) {
        locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
//            locationManager.requestLocation()
        }
    }
}

//MARK: - CLLocation Manager Delegate Methods

extension ViewController : CLLocationManagerDelegate {
    
//    This method can cause UI unresponsiveness if invoked on the main thread. Instead, consider waiting for the `-locationManagerDidChangeAuthorization:` callback and checking `authorizationStatus` first.
//
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == CLAuthorizationStatus.denied {
            // The user denied authorization
        } else if manager.authorizationStatus == CLAuthorizationStatus.authorizedAlways {
            // The user accepted authorization
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("locationManager.didFailWithError \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if let location = locations.last {
            locationManager.stopUpdatingLocation()
            let lat = location.coordinate.latitude
            let lon = location.coordinate.longitude
            let coordinates = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            let region = MKCoordinateRegion(center: coordinates, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))

            map.setRegion(region, animated: true)
            
            let mkAnnotation: MKPointAnnotation = MKPointAnnotation()
            mkAnnotation.coordinate = CLLocationCoordinate2DMake(lat, lon)
//            mkAnnotation.title = self.setUsersClosestLocation(location)
            setUsersClosestLocation(location)
            map.addAnnotation(mkAnnotation)
        }
    }
    
    func setUsersClosestLocation(_ location: CLLocation) {
        let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location) { (placemarksArray, error) in
                print(placemarksArray!)
                if (error) == nil {
                    if placemarksArray!.count > 0 {
                        let placemark = placemarksArray?[0]
                        let address = "\(placemark?.thoroughfare ?? "") \(placemark?.subThoroughfare ?? "") \(placemark?.locality ?? "") \(placemark?.postalCode ?? "") \(placemark?.country ?? "")"
                        print("current address: \(address)")
                        DispatchQueue.main.async {
                            self.locationLabel.addBlurEffect(style: .regular, cornerRadius: 20, padding: 0)
                            self.locationLabel.setTitle(address, for: .normal)
                        }
                    }
                }

            }
    }
}


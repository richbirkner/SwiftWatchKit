//
//  MapViewController.swift
//  WorldTrotter
//
//  Created by Richard Birkner on 18.03.19.
//  Copyright © 2019 Richard Birkner. All rights reserved.
//
import Foundation
import UIKit
import MapKit

protocol HandleMapSearch: class {
    func dropPinZoomIn(placemark:MKPlacemark)
}

final class MapAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    
    init(coordinate: CLLocationCoordinate2D, title: String?, subtitle: String?) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        super.init()
    }
    
    var region: MKCoordinateRegion {
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        return MKCoordinateRegion(center: coordinate, span: span)
    }
}

class MapViewController: UIViewController, UISearchBarDelegate{
    
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var goButton: UIBarButtonItem!
    var selectedPin:MKPlacemark! = nil
    //var listAnnotation = [MapAnnotation]()

    //var mapView: MKMapView!
    let locationManager = CLLocationManager()
    var resultSearchController:UISearchController? = nil
    var directionsArray: [MKDirections] = []

    override func loadView() {
        mapView = MKMapView()
        view = mapView
    
        
        let standardString = NSLocalizedString("Standard", comment: "Standard map view")
        let satelliteString = NSLocalizedString("Satellite", comment: "Satellite map view")
        let hybridString = NSLocalizedString("Hybrid", comment: "Hybrid map view")
        let segmentedControl = UISegmentedControl(items: [standardString, satelliteString, hybridString])
        segmentedControl.backgroundColor = UIColor.white.withAlphaComponent(0.5)
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(MapViewController.mapTypeChanged(_:)), for: .valueChanged)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(segmentedControl)

        let topConstraint = segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8)
        let margins = view.layoutMarginsGuide
        let leadingConstraint = segmentedControl.leadingAnchor.constraint(equalTo: margins.leadingAnchor)
        let trailingCostraint = segmentedControl.trailingAnchor.constraint(equalTo: margins.trailingAnchor)
        topConstraint.isActive = true
        leadingConstraint.isActive = true
        trailingCostraint.isActive = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkLocationServices()
        let locationSearchTable = storyboard!.instantiateViewController(withIdentifier: "LocationSearchTable") as! LocationSearchTable
        resultSearchController = UISearchController(searchResultsController: locationSearchTable)
        resultSearchController?.searchResultsUpdater = locationSearchTable
        let searchBar = resultSearchController!.searchBar
        searchBar.sizeToFit()
        searchBar.placeholder = "Search for places"
        navigationItem.titleView = resultSearchController?.searchBar
        resultSearchController?.hidesNavigationBarDuringPresentation = false
        resultSearchController?.dimsBackgroundDuringPresentation = true
        definesPresentationContext = true
        locationSearchTable.mapView = mapView
        locationSearchTable.handleMapSearchDelegate = self as? HandleMapSearch
        mapView.delegate = self
        print("MapViewController loaded its view")

    }

    
    override func viewDidAppear(_ animated: Bool) {
        checkLocationServices()
    }
    
    
    @objc func mapTypeChanged(_ segControl: UISegmentedControl){
        switch segControl.selectedSegmentIndex {
        case 0:
            mapView.mapType = .standard
        case 1:
            mapView.mapType = .hybrid
        case 2:
            mapView.mapType = .satellite
        default:
            break
        }
    }
    
    func checkLocationServices(){
        if CLLocationManager.locationServicesEnabled(){
            checkLocationAuthoritation()
        } else {
            // Show Allert
            locationManager.requestWhenInUseAuthorization()
            checkLocationAuthoritation()
        }
    }
    
    func checkLocationAuthoritation() {
        
        switch CLLocationManager.authorizationStatus(){
        case .authorizedWhenInUse:
            //Creating the Location Button
            let buttonItem = MKUserTrackingButton(mapView: mapView)
            let screenSize = UIScreen.main.bounds
            buttonItem.frame = CGRect(origin: CGPoint(x: Int(screenSize.width - 50), y: 100), size: CGSize(width: 35, height: 35))
            view.addSubview(buttonItem)
            break
        case .denied:
            //Request the location
            locationManager.requestWhenInUseAuthorization()
            checkLocationAuthoritation()
            break
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            //checkLocationAuthoritation()
            break
        case .restricted:
            // Show an alert letting them know what's up
            break
        case .authorizedAlways:
            break
        }
    }
    
    @objc func getDirections(){
        guard let location = locationManager.location?.coordinate else {
            //TODO: Inform user we do not have their current location
            return
        }
        let request = createDirectionsRequest(from: location)
        let directions = MKDirections(request: request)
       //resetMapView(withNew: directions)
        
        directions.calculate { [unowned self] (responde, error) in
            //TODO: Handle error if needed
            guard let responde = responde else { return }
            
            for route in responde.routes {
                print(route.distance)
                self.mapView.addOverlay(route.polyline)
                self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
            }
        }
    }
    
    func getPinLocation(for selectedPin: MKPlacemark) -> CLLocation {
        let latitude = selectedPin.coordinate.latitude
        let longitude = selectedPin.coordinate.longitude
        
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    
    func createDirectionsRequest(from coordinate: CLLocationCoordinate2D) -> MKDirections.Request {
        
        //let destinationCoordinate = listAnnotation[0].coordinate
        let destinationCoordinate = getPinLocation(for: selectedPin).coordinate
        let startingLocation = MKPlacemark(coordinate: coordinate)
        let destination = MKPlacemark(coordinate: destinationCoordinate)
        let request = MKDirections.Request()
        
        request.source = MKMapItem(placemark: startingLocation)
        request.transportType = .automobile
        request.destination = MKMapItem(placemark: destination)
        request.requestsAlternateRoutes = true
        
        return request
        
    }
    
//    func resetMapView(withNew directions: MKDirections) {
//        mapView.removeOverlay(mapView?.overlays as! MKOverlay)
//        directionsArray.append(directions)
//        directionsArray.map { $0.cancel()}
//    }
    
    @IBAction func goButtonTapped(_ sender: UIBarButtonItem) {
        getDirections()
    }
}

extension MapViewController : MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let rendered = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        rendered.strokeColor = UIColor.red
        return rendered
    }
}


extension MapViewController: HandleMapSearch {

    func dropPinZoomIn(placemark:MKPlacemark){
        // cache the pin
        selectedPin = placemark
        // clear existing pins
        mapView.removeAnnotations(mapView.annotations)
//        let annotation = MKAnnotation()
//        if let city = placemark.locality,
//            let state = placemark.administrativeArea {
//            annotation.subtitle = "\(city) \(state)"
//        }

        let annotation = MapAnnotation(coordinate: placemark.coordinate, title: placemark.name, subtitle: placemark.locality)
        if let city = placemark.locality,
            let state = placemark.administrativeArea {
            annotation.subtitle = "\(city) \(state)"
        }
        let finalAnnotation = MapAnnotation(coordinate: annotation.coordinate, title: annotation.title, subtitle: annotation.subtitle)
        mapView.addAnnotation(finalAnnotation)
        
        //listAnnotation.append(finalAnnotation)
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: placemark.coordinate, span: span)
        mapView.setRegion(region, animated: true)
    }
}


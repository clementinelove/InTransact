//
//  LocationPicker.swift
//  InAndOut
//
//  Created by Yuhao Zhang on 2023-05-12.
//

import SwiftUI
import MapKit

class LocationPickerViewModel: ObservableObject {
  @Published var locationSearchText: String = ""
  
  init() {
    let searchRequest = MKLocalSearch.Request()
    searchRequest.naturalLanguageQuery = "coffee"
    
    // Set the region to an associated map view's region.
//    searchRequest.region
    let search = MKLocalSearch(request: searchRequest)
    search.start { (response, error) in
      guard let response = response else {
        // TODO: Handle the error.
        return
      }
      
      for item in response.mapItems {
        if let name = item.name,
           let location = item.placemark.location {
          print("\(name): \(location.coordinate.latitude),\(location.coordinate.longitude)")
        }
      }
    }
  }
}

struct LocationPicker: View {
  
    @StateObject var viewModel = LocationPickerViewModel()
  
    var body: some View {
      Form {
        TextField("Search Location...", text: $viewModel.locationSearchText)
      }
    }
}

struct LocationPicker_Previews: PreviewProvider {
    static var previews: some View {
        LocationPicker()
    }
}

//
//  WelcomeView.swift
//  InTransact
//
//  Created by Yuhao Zhang on 2023-06-01.
//

import SwiftUI

struct WelcomeView: View {
  
  @Environment(\.dismiss) private var dismiss
  
    var body: some View {
      ScrollView {

        VStack(alignment: .leading, spacing: 20) {
          // MARK: App Icon, Title and Subtitle
          VStack(alignment: .leading) {
            Image("AppImage")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: 100)
              .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            
            Text("Welcome to InTransact")
              .font(.largeTitle.bold())
              .multilineTextAlignment(.leading)
            
            Text("Track Transactions/Item Counts/Keeper Names/Counterparties/Prices and Taxes")
              .multilineTextAlignment(.leading)
              .foregroundStyle(.secondary)
          }
          
          // MARK: Key Features
          VStack(alignment: .leading, spacing: 10) {
            
            VStack(alignment: .leading) {
              VStack(alignment: .leading) {
                Text("Document Based")
                  .font(.headline)
                Text("Easily backup, restore, and share your transactions data.")
              }

              

            }
            
            VStack(alignment: .leading) {

              VStack(alignment: .leading) {
                Text("Record Anywhere")
                  .font(.headline)
                Text("Record transactions data and track current stock level of different items.")
              }

            }
            
            VStack(alignment: .leading) {
              
              VStack(alignment: .leading) {
                Text("Export to CSV")
                  .font(.headline)
                Text("Export the data to spreadsheet format so you can continue.")
              }
            }
          }
          
          // MARK: Made with...
          VStack(alignment: .leading) {
            Text("Designed with Heart and Soul")
            Text("© 2023 Yuhao Zhang")
          }
          .font(.footnote)
          .foregroundStyle(.primary.opacity(0.8))
          
        }
        .padding(32)
      }
      .safeAreaInset(edge: .bottom, spacing: 0) {
        VStack(spacing: 10) {
          Button {
            dismiss()
          } label: {
            Text("Continue", comment: "Button to dismiss the welcome landing page")
              .padding(.vertical, 10)
              .font(.title3)
              .fontWeight(.semibold)
              .frame(maxWidth: .infinity)
          }
          .buttonStyle(.borderedProminent)
        }
        .padding(.vertical)
        .padding(.horizontal, 32)
        #if os(iOS)
        .background(.background)
        #endif
      }
      
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
      
      WelcomeView()
      
      Rectangle()
        .sheet(isPresented: .constant(true)) {
          WelcomeView()
            .presentationContentInteraction(.resizes)
            .dynamicTypeSize(.xxxLarge)
        }
    }
}

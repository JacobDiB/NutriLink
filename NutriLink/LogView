//
//  SearchView.swift
//  NutriLink
//
//  Created by Jack Micklus on 11/15/25.
//

// SearchView.swift
import SwiftUI

struct LogView: View {
    @State private var query: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {

                // MARK: Search Bar
                TextField("Search foods...", text: $query)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                    .onSubmit {
                        print(query)
                        // TODO: Implement search via API
                    }

                // MARK: Image & Barcode Options
                HStack(spacing: 40) {
                    VStack {
                        Button {
                            // TODO: Implement photo capture
                        } label: {
                            Image(systemName: "camera")
                                .font(.system(size: 40))
                                .padding()
                                .background(.thinMaterial)
                                .clipShape(Circle())
                        }
                        Text("Photo")
                            .font(.subheadline)
                    }

                    VStack {
                        Button {
                            // TODO: Implement barcode scan
                        } label: {
                            Image(systemName: "barcode.viewfinder")
                                .font(.system(size: 40))
                                .padding()
                                .background(.thinMaterial)
                                .clipShape(Circle())
                        }
                        Text("Scan")
                            .font(.subheadline)
                    }
                }

                Spacer()
            }
            .navigationTitle("Search")
        }
    }
}

#Preview {
    NavigationStack {
        LogView()
    }
}

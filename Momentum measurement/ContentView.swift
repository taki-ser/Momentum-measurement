//
//  ContentView.swift
//  Momentum measurement
//
//  Created by 滝瀬隆斗 on 2023/03/29.
//


import SwiftUI
import CoreMotion

struct ContentView: View {
    var body: some View {
        TabView {
            GraphView()
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("Graph")
                }
            RecordView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Records")
                }
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

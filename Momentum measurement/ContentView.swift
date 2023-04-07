//
//  ContentView.swift
//  Momentum measurement
//
//  Created by 滝瀬隆斗 on 2023/03/29.
//


import SwiftUI
import CoreMotion
//struct data {
//     @State var listOfPath: URL
//     @State var
//}
struct ContentView: View {
    @State var listOfPathOriginal: [URL] = []
    var body: some View {
        TabView {
            GraphView(sensorDataManager: SensorDataManager(listOfPath1: listOfPathOriginal), listOfPath: $listOfPathOriginal)
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("Graph")
                }
            RecordView(listOfPath: $listOfPathOriginal)
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Records")
                }
        }
        .onAppear(perform: {
            listOfPathOriginal = getFolder(url: URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]))
               })
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
  

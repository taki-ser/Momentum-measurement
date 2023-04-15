//
//  ContentView.swift
//  Momentum measurement
//
//  Created by 滝瀬隆斗 on 2023/03/29.
//


import SwiftUI
import CoreMotion

struct ContentView: View {
    @StateObject var timeCounter = TimeCounter()
    @State var listOfPathOriginal: [URL] = []
    var body: some View {
        TabView {
            GraphView(sensorDataManager: SensorDataManager(listOfPath1: listOfPathOriginal, timeCounter: timeCounter))
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

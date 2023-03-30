//
//  RecordView.swift
//  Momentum measurement
//
//  Created by 滝瀬隆斗 on 2023/03/29.
//

import SwiftUI

struct Record: Identifiable {
    let id = UUID()
    let date: Date
    let filename: String
    }

struct RecordView: View {
    @State private var records: [Record] = []
    var body: some View {
        NavigationView {
            List(records) { record in
                Text("\(record.date): \(record.filename)")
            }
            .navigationTitle("Records")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        saveRecord()
                    }, label: {
                        Image(systemName: "plus")
                    })
                }
            }
        }
    }
    func saveRecord() {
        let date = Date()
        let filename = "record_\(date.timeIntervalSince1970).csv"
        guard let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let fileURL = directory.appendingPathComponent(filename)
        do {
            try "".write(to: fileURL, atomically: true, encoding: .utf8)
            records.append(Record(date: date, filename: filename))
        } catch {
            print(error.localizedDescription)
        }
    }
}

struct RecordView_Previews: PreviewProvider {
    static var previews: some View {
        RecordView()
    }
}

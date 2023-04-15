//
//  testGraphView.swift
//  Momentum measurement
//
//  Created by 滝瀬隆斗 on 2023/04/14.
//
import SwiftUI
struct MailListView: View {
    @State private var mails = [
        "mail1@example.com",
        "mail2@example.com",
        "mail3@example.com",
        "mail4@example.com",
        "mail5@example.com",
        "mail6@example.com",
        "mail7@example.com",
        "mail8@example.com",
        "mail9@example.com",
        "mail10@example.com"
    ]

    @State private var selection = Set<Int>()
    @State private var isEditing = false

    var body: some View {
        NavigationView {
            List(selection: $selection) {
                ForEach(mails.indices, id: \.self) { index in
                    Text(mails[index])
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "Done" : "Edit") {
                        isEditing.toggle()
                    }
                }
            }
            .environment(\.editMode, isEditing ? .constant(.active) : .constant(.inactive))
        }
    }
}
struct MailListView_Previews: PreviewProvider {
    static var previews: some View {
        MailListView()
    }
}
//struct ConteaatView: PreviewProvider {
//    @State var listOfPath: [URL] = []
//    static var previews: some View {
//       ContetView()
//    }
//}

//
//  RecordView.swift
//  Momentum measurement
//
//  Created by 滝瀬隆斗 on 2023/03/29.
//

import SwiftUI

struct RecordView: View {
    @State private var newItem = ""
    @Binding var listOfPath: [URL]
    @State private var deleteCandidate: URL?
    @FocusState private var isEditing: Bool
    var body: some View {
        NavigationView {
            List{
                ForEach(listOfPath, id: \.self) { url in
                    ItemCell(url: url)
                }
                .onDelete { (indexSet) in
                    if let index = indexSet.first {
                        deleteCandidate = listOfPath[index]
                    }
                    if let candidate = deleteCandidate {
                        removeItem(atPath: candidate)
                        listOfPath = getFolder(url: URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]))
                        deleteCandidate = nil
                    }
                }
                HStack{
                    Image(systemName: "folder")
                    TextField("New Item", text: $newItem, onCommit: {
                        isEditing = false
                        if newItem != "" {
                            createDirectory()
                        }
                        DispatchQueue.main.async {
                            newItem = "" // テキストフィールドを空にする
                        }
                    })
                    .focused($isEditing)
                    .keyboardType(.default)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding(.horizontal)
                    .onTapGesture {
                        //                    isEditing = true
                        isEditing = !isEditing
                    }
                    .animation(.default, value: isEditing)

                }
                .navigationTitle("Activity")
            }
//            .selectionMode(.multiple)
        }

    }
    func createDirectory() {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        let directoryURL = documentsDirectory.appendingPathComponent(newItem, isDirectory: true)

        do {
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
            listOfPath.append(directoryURL)
        } catch {
            print(error.localizedDescription)
        }
        newItem = ""
    }
}
struct ItemCell: View {
    let url: URL
    @Environment(\.dismiss) var dismissKeyboard
    @FocusState private var isEditing: Bool
    @State private var showContextMenu = false
    @State private var rename = ""
    var body: some View {
        HStack {
            if url.hasDirectoryPath {
                /// フォルダ
                NavigationLink(destination: SubFolder(url: url)) {
                    Image(systemName: "folder")
                    Text(url.lastPathComponent)
                        .contextMenu(menuItems: {
                            Button("Copy", action: {
                                UIPasteboard.general.string = url.lastPathComponent
                            })
//                            Button("Rename", action:{
//                                TextField("New Item", text: $rename, onCommit: {
//                                    isEditing = false
//                                    if rename != "" {
//
//                                    }
//                                    DispatchQueue.main.async {
//                                        rename = "" // テキストフィールドを空にする
//                                    }
//                                })
//                            })
                        })
                        .onLongPressGesture {
                            showContextMenu = true
                        }

                }
            } else {
                /// ファイル
                Image(systemName: "doc.text")
                Text(url.lastPathComponent)
                    .contextMenu(menuItems: {
                        Button("Copy", action: {
                            UIPasteboard.general.string = url.lastPathComponent
                        })
                    })
                    .onLongPressGesture {
                        showContextMenu = true
                    }
            }
        }
    }

}
//struct ItemCell: View {
//    let url: URL
//    @Environment(\.dismiss) var dismissKeyboard
//    @FocusState private var isEditing: Bool
//    @State private var showContextMenu = false
//    @State private var rename = ""
//    @State private var showRenameAlert = false
//
//    var body: some View {
//        HStack {
//            if url.hasDirectoryPath {
//                /// フォルダ
//                NavigationLink(destination: SubFolder(url: url)) {
//                    Image(systemName: "folder")
//                    Text(url.lastPathComponent)
//                        .contextMenu(menuItems: {
//                            Button("Copy", action: {
//                                UIPasteboard.general.string = url.lastPathComponent
//                            })
//                            Button("Rename", action:{
//                                isEditing = true
//                            })
//                        })
//                        .onLongPressGesture {
//                            showContextMenu = true
//                        }
//                        .alert(isPresented: $showRenameAlert) {
//                            Alert(title: Text("Rename Folder"), message: Text("Please enter the new name of the folder"), primaryButton: .cancel(), secondaryButton: .default(Text("OK")) {
//                                isEditing = false
//                                if rename != "" {
//                                    let newURL = url.deletingLastPathComponent().appendingPathComponent(rename, isDirectory: true)
//                                    do {
//                                        try FileManager.default.moveItem(at: url, to: newURL)
//                                    } catch let error {
//                                        print("Error renaming folder: \(error.localizedDescription)")
//                                    }
//                                }
//                                DispatchQueue.main.async {
//                                    rename = "" // テキストフィールドを空にする
//                                }
//                            })
//                        }
//                }
//                .padding(.trailing, isEditing ? 80 : 0)
//                .animation(.default)
//                .overlay(
//                    Group {
//                        if isEditing {
//                            TextField("", text: $rename, onCommit: {
//                                showRenameAlert = true
//                            })
//                            .frame(width: 100, height: 30)
//                            .foregroundColor(.primary)
//                            .background(Color(.secondarySystemBackground))
//                            .cornerRadius(5)
//                            .padding(.leading, 8)
//                            .padding(.trailing, 8)
//                            .onAppear {
//                                DispatchQueue.main.async {
//                                    rename = url.lastPathComponent
//                                }
//                            }
//                            .onDisappear {
//                                DispatchQueue.main.async {
//                                    rename = ""
//                                }
//                            }
//                        }
//                    }
//                )
//            } else {
//                /// ファイル
//                Image(systemName: "doc.text")
//                Text(url.lastPathComponent)
//                    .contextMenu(menuItems: {
//                        Button("Copy", action: {
//                            UIPasteboard.general.string = url.lastPathComponent
//                        })
//                    })
//                    .onLongPressGesture {
//                        showContextMenu = true
//                    }
//            }
//        }
//    }
//}

struct SubFolder: View {
    @State private var showingDeleteAlert = false
    @State var listOfPath: [URL] = []
    @State private var showingDeleteAlertSub = false
    @State private var deleteCandidate: URL?
    let url: URL
    var body: some View {
        List {
            ForEach(getFolder(url: url), id: \.self) { url in
                ItemCell(url:url)
            }
            .onDelete { (indexSet) in
                if let index = indexSet.first {
                    deleteCandidate = getFolder(url: url)[index]
                }
                if let candidate = deleteCandidate {
                    removeItem(atPath: candidate)
                    listOfPath = getFolder(url: URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]))
                    deleteCandidate = nil
                }
            }
        }
        .navigationBarTitle(url.lastPathComponent, displayMode: .inline)
        .onAppear() {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}


func getFolder(url: URL) -> [URL] {
    do {
        /// フォルダのURLからふくまれるURLを取得
        let fileAndFolderURLs = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
        return fileAndFolderURLs
    } catch {
        print(error)
        return []
    }
}


func removeItem(atPath path: URL) {
    let fileManager = FileManager.default
    do {
        try fileManager.removeItem(at: path)
    } catch {
        fatalError("Failed to remove item at path \(path). Error: \(error.localizedDescription)")
    }
}



struct RecordView_Previews: PreviewProvider {
    @State var listOfPath: [URL] = []
    static var previews: some View {
        RecordView(listOfPath: ContentView().$listOfPathOriginal)
    }
}
import SwiftUI

//struct ContetView: View {
//    @State private var text: String = ""
//    @State private var showContextMenu = false
//
//    var body: some View {
//        VStack {
//            Text(text)
//                .contextMenu(menuItems: {
//                    Button("Copy", action: {
//                        UIPasteboard.general.string = text
//                    })
//                    Button("Cut", action: {
//                        UIPasteboard.general.string = text
//                        text = ""
//                    })
//                    Button("Paste", action: {
//                        if let copiedText = UIPasteboard.general.string {
//                            text += copiedText
//                        }
//                    })
//                })
//                .onLongPressGesture {
//                    showContextMenu = true
//                }
//                .alert(isPresented: $showContextMenu) {
//                    Alert(
//                        title: Text("Select Action"),
//                        message: nil,
//                        dismissButton: .cancel()
//                    )
//                }
//            TextField("Enter text", text: $text)
//                .padding()
//        }
//    }
//}
//struct ConteaatView: PreviewProvider {
//    @State var listOfPath: [URL] = []
//    static var previews: some View {
//       ContetView()
//    }
//}

//
//  ContentView.swift
//  RespringCC
//
//  Created by mini on 2023/02/04.
//

import SwiftUI

struct ContentView: View {
    @State var isURLSchemeOpened = false
    @State var Show = 0
    @State private var flag = true
    var body: some View {
        VStack {
            if Show == 1{
                BounceAnimationView(text: "Respring Now...", startTime: 0.0)
                ActivityIndicator()
                    .onAppear {
                        CC()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            if UserDefaults.standard.bool(forKey: "Respring_Mode") {
                                respringFrontboard()
                            }else{
                                respringBackboard()
                            }
                        }
                    }
            }else if Show == 2{
                NavigationView {
                    List {
                        VStack {
                            Text("Respring Mode")
                            Toggle(flag ? "Frontboard" : "Backboard", isOn: $flag)
                                .onChange(of: flag) { newValue in
                                    UserDefaults.standard.set(flag, forKey: "Respring_Mode")
                                }
                        }
                    }
                }
            }
        }.onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if isURLSchemeOpened {
                    Show = 2
                }else{
                    Show = 1
                }
            }
        }
        .onOpenURL { url in
            isURLSchemeOpened = true
        }
    }
}

func CC() {
    let Module_BasePath = "/System/Library/ControlCenter/Bundles/MagnifierModule.bundle"
    var Default_URL_STR = "\(Module_BasePath)/Info.plist"
    guard var Import_URL = Bundle.main.url(forResource: "Default", withExtension: "plist") else { return }
    guard var Import_Data = try? Data(contentsOf: Import_URL) else { return }
    guard var Import_Data = PlistPadding(Plist_Data: Import_Data, Target_URL: Default_URL_STR) else { return }
    print(OverwriteData(TargetFilePath: Default_URL_STR, OverwriteFileData: Import_Data))
    
    Default_URL_STR = "\(Module_BasePath)/Assets.car"
    guard var Import_URL = Bundle.main.url(forResource: "Default", withExtension: "car") else { return }
    guard var Import_Data = try? Data(contentsOf: Import_URL) else { return }
    print(OverwriteData(TargetFilePath: Default_URL_STR, OverwriteFileData: Import_Data))
    
    do {
        let files = try FileManager.default.contentsOfDirectory(atPath: Module_BasePath)
        files.forEach { file in
            if file.contains("lproj") {
                let lproj = "\(Module_BasePath)/\(file)/InfoPlist.strings"
                print(OverwriteData_XXX(TargetFilePath: lproj, OverwriteData: "xxx"))
            }
        }
    } catch {
        print(error.localizedDescription)
    }
}

func PlistPadding(Plist_Data: Data, Target_URL: String) -> Data? {
    guard let Target_Data = try? Data(contentsOf: URL(fileURLWithPath: Target_URL)) else { return nil }
    if Plist_Data.count == Target_Data.count { return Plist_Data }
    guard var Plist = try? PropertyListSerialization.propertyList(from: Plist_Data, format: nil) as? [String:Any] else { return nil }
    var EditedDict = Plist as! [String: Any]
    EditedDict.updateValue(Bundle.main.bundleIdentifier, forKey: "CCLaunchApplicationIdentifier")
    guard var newData = try? PropertyListSerialization.data(fromPropertyList: EditedDict, format: .binary, options: 0) else { return nil }
    var count = 0
    print("DefaultData - "+String(Target_Data.count))
    while true {
        newData = try! PropertyListSerialization.data(fromPropertyList: EditedDict, format: .binary, options: 0)
        if newData.count >= Target_Data.count { break }
        count += 1
        EditedDict.updateValue(String(repeating:"0", count:count), forKey: "0")
    }
    print("ImportData - "+String(newData.count))
    return newData
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


struct ActivityIndicator: UIViewRepresentable {
func makeUIView(context: UIViewRepresentableContext<ActivityIndicator>) -> UIActivityIndicatorView {
return UIActivityIndicatorView(style: .large)
    }
func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<ActivityIndicator>) {
        uiView.startAnimating()
    }
}

struct BounceAnimationView: View {
    let characters: Array<String.Element>

    @State var offsetYForBounce: CGFloat = -50
    @State var opacity: CGFloat = 0
    @State var baseTime: Double

    init(text: String, startTime: Double){
        self.characters = Array(text)
        self.baseTime = startTime
    }

    var body: some View {
        HStack(spacing:0){
            ForEach(0..<characters.count) { num in
                Text(String(self.characters[num]))
                    .font(.system(size: 24, weight: .bold, design: .default))
                    .offset(x: 0, y: offsetYForBounce)
                    .opacity(opacity)
                    .animation(.spring(response: 0.2, dampingFraction: 0.5, blendDuration: 0.1).delay( Double(num) * 0.01 ), value: offsetYForBounce)
            }
            .onTapGesture {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.0) {
                    opacity = 0
                    offsetYForBounce = -50
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    opacity = 1
                    offsetYForBounce = 0
                }
            }
            .onAppear{
                DispatchQueue.main.asyncAfter(deadline: .now() + (0.5 + baseTime)) {
                    opacity = 1
                    offsetYForBounce = 0
                }
            }
        }
    }
}

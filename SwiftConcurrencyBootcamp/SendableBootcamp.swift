//
//  SendableBootcamp.swift
//  SwiftConcurrencyBootcamp
//
//  Created by 진준호 on 1/19/25.
//

import SwiftUI

actor CurrentUserManager {
    func updateDatabase(userInfo: MyUserInfo) {
        
    }
}

// 기본적으로 Struct는 쓰레드로부터 안전하기 때문에 굳이 Sendable을 표기할 필요는 없다.
struct MyUserInfo: Sendable {
    var name: String
}

// @unchecked라는 것은 컴파일러에게 직접 체크할테니 체크하지 말라고 하는것이지, Sendable을 만족하는 것은 아니다. 그러므로 근본적인 해결이 될 수 없다.
// @unchecked를 사용할 경우 수동적으로 쓰레드로부터 안전하게 만들어줘야 한다.
// 해결법 중 하나는 내부에서 메서드를 통해 값을 바꿀 수 있도록 하고, 값을 바꾸는 과정을 하나의 내부 큐에서 처리하도록 하는 것이다.
// 다만 이 또한 가장 좋은 방법은 아니고, 가장 최선의 방법은 Sendable을 만족하도록 하는것이다.
final class MyClassUserInfo: @unchecked Sendable {
    // 만약 let이라면 해당 클래스에는 바꿀 수 있는 프로퍼티가 없으므로 쓰레드로 부터 안전하기 때문에 Sendable을 채택하더라도 에러가 발생하지 않는다.
    // 만약 var라면 해당 클래스에서 바꿀 수 있는 프로퍼티가 있다는 뜻이고, 여러 쓰레드에서 접근해서 바꾸게 될 수 있기 때문에 쓰레드로 부터 안전하지 않다고 판단하기 때문에 Sendable을 채택하면 에러가 발생한다.
    // 다만 class의 장점 중 하나는 여러쓰레드에서 접근해서 프로퍼티를 바꿀 수 있다는 것인데 모든 프로퍼티를 let으로 만들어서 Sendable을 만족한다는 것은 class를 굳이 사용할 필요가 없기 때문에 다른 방법으로 에러를 해결하는 것이 좋다.
    private var name: String
    let queue = DispatchQueue(label: "com.MyApp.MyClassUserInfo")
    
    init(name: String) {
        self.name = name
    }
    
    func updateName(name: String) {
        queue.async {
            self.name = name
        }
    }
}

class SendableBootcampViewModel: ObservableObject {
    let manager = CurrentUserManager()
    
    func updateCurrentUserInfo() async {
        let info = MyUserInfo(name: "info")
        await manager.updateDatabase(userInfo: info)
    }
}

struct SendableBootcamp: View {
    @StateObject private var viewModel = SendableBootcampViewModel()
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    SendableBootcamp()
}

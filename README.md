# AsyncAwaitStudy
- [링크](https://www.youtube.com/playlist?list=PLwvDm4Vfkdphr2Dl4sY4rS9PLzPdyi8PM)를 참고해서 AsyncAwait에 대해 학습하고 회사코드에 적용해보기 위한 Study를 목적으로 작성됨

## 1. DoCatchTryThrows
- 1강에서는 기본적으로 Do Catch 구문, Try 및 Throws를 통해 Error Throw를 하는 기본적인 내용을 담고 있다.
- 기본적인 내용이기 때문에 설명은 남기지 않음

## 2. DownloadImageAsync
- 2강에서는 URLSession의 기본적은 메서드를 활용해 @escaping, Combine, async throws 각 방법별로 비동기처리를 하고 에러핸들링을 하는 내용을 담고 있다.
- 비동기 처리를 한 후 UI 관련 업데이트 시에는 꼭 MainThread에서 실행해야되기 때문에 await MainActor.run 혹인 @MainActor 키워드를 사용해 UI 업데이트를 진행해야함
<details>
<summary>코드 정리</summary>
<div markdown="1">

```swift
// 기본적인 Async 활용 방법

// 구현
class DownloadImageAsyncImageLoader {
    let url = URL(string: "https://picsum.photos/200")!
    
    func handleResponse(data: Data?, response: URLResponse?) -> UIImage? {
        guard
            let data = data,
            let image = UIImage(data: data),
            let response = response as? HTTPURLResponse,
            response.statusCode >= 200 && response.statusCode < 300
        else {
            return nil
        }
        return image
    }

    func downloadWithAsync() async throws -> UIImage? {
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            return handleResponse(data: data, response: response)
        } catch {
            throw error
        }
    }
}

// 사용
class DownloadImageAsyncViewModel: ObservableObject {
    @Published var image: UIImage? = nil
    let loader = DownloadImageAsyncImageLoader()

    func fetchImage() async {
        let image = try? await loader.downloadWithAsync()
        await MainActor.run {
            self.image = image
        }
    }
}

struct DownloadImageAsync: View {
    @StateObject private var viewModel = DownloadImageAsyncViewModel()
    
    var body: some View {
        ZStack {
            if let image = viewModel.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250, height: 250)
            }
        }
        .onAppear {
            Task {
                await viewModel.fetchImage()
            }
        }
    }
}
```

</div>
</details>

## 3. AsyncAwait
- 3강에서는 print를 통해 Async Await, Multi Thread 환경에서 코드의 동작이 어떠한 방식으로 이루어지는지에 대해 다루고 있다.
- 실질적으로 사용하는 코드 보다는 원리에 대한 이해가 필요한 강의이기 때문에 코드정리는 따로 진행하지 않음

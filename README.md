# GITGET <img src="https://github.com/fimuxd/GITGET/blob/develop/GITGET/Resource/Assets.xcassets/AppIcon.appiconset/mac_app_icon_1024.png?raw=true" width="50" align="right">

> **My First Personal Project / 첫 번째 개인 프로젝트**

[<img src="https://devimages-cdn.apple.com/app-store/marketing/guidelines/images/badge-download-on-the-app-store.svg">](https://itunes.apple.com/us/app/gitget/id1317170245?mt=8) [<img src="https://developer.apple.com/app-store/marketing/guidelines/images/badge-download-on-the-mac-app-store.svg">](https://apps.apple.com/us/app/gitget/id1317170245)

## Contents / 목차
* [About GITGET](https://github.com/fimuxd/GITGET#about-gitget) / [GITGET 소개](https://github.com/fimuxd/GITGET#about-gitget)
* [Concept](https://github.com/fimuxd/GITGET#concept) / [개념](https://github.com/fimuxd/GITGET#concept)
* [Updates](https://github.com/fimuxd/GITGET#updates) / [업데이트](https://github.com/fimuxd/GITGET#updates)
* [Contributors (Special Thanks)](https://github.com/fimuxd/GITGET#contributors-special-thanks) / [기여자 (특별 감사)](https://github.com/fimuxd/GITGET#contributors-special-thanks)
* [Contact Me](https://github.com/fimuxd/GITGET#contact-me) / [연락처](https://github.com/fimuxd/GITGET#contact-me)

## About GITGET / GITGET 소개

<img src="https://github.com/fimuxd/GITGET/blob/master/screenshots/devices.png?raw=true">

> - **GitHub + Widget**
> - No more than three meals a day, aim for three commits a day!
> - Say goodbye to gray fields on GitHub
> - Stay connected via the widget; coding never stops until you achieve a **fully green field**
> 
> **GITGET - Making our GitHub greener and greener!**
> 
> **GITGET - 우리 GitHub, 푸르게 푸르게!**

## Concept / 개념

- GITGET (or `깃젯`) is my first app, completed solo after I began coding in Swift in May 2017.
- The app displays contributions from a GitHub profile directly on an iPhone widget.
- Through developing `깃젯`, I was able to study the following:
  
    i. **Firebase**: Utilized Realtime Database to replace backend services with Firebase.  
    ii. **GitHub API**: Implemented API communication and integrated `OAuth 2.0` with `Firebase Auth`.  
    iii. **Today Extension**: Enabled communication between the widget and the host app.  
    iv. **Realm**: Employed Realm as a local storage solution.  
    v. **SwiftUI + Combine**: Applied WidgetKit for modern UI components.  

- `깃젯`은 2017년 5월, `Swift`로 코딩을 처음 접한 뒤 혼자서 완성한 첫 번째 앱입니다.  
- GitHub 프로필 페이지의 `contributions`를 `iPhone`의 `widget`상에 띄워서 볼 수 있게 하였습니다.  
- `깃젯`을 통해 다음과 같은 내용을 스터디할 수 있었습니다:  

    i. **Firebase**: Realtime Database를 이용하여 백엔드 단을 Firebase로 대체하였습니다.  
    ii. **GitHub API**: API 통신 및 `OAuth 2.0` + `Firebase Auth` 연동.  
    iii. **Today Extension**: Widget과 Host App 간의 연동.  
    iv. **Realm**: 로컬 저장소로써의 Realm 활용.  
    v. **SwiftUI + Combine**: WidgetKit 적용.  

## Updates / 업데이트
### Version 2
- **22.38.0**: Added lock screen widget for iOS 16 / Fixed invalid user bug  
- **21.4.0**: Updated Korean localization  
- **21.3.0**: Added support for macOS  
- **21.2.0**: Launched GITGET VERSION 2, reduced in-app features, applied WidgetKit for iOS 14. Utilized RxSwift for the app and SwiftUI + Combine for the widget.  

### Version 1
- **3.3**: Team management via Realm, added nickname features.  
- **3.2**: Enhanced version control and team management UX using Firebase.  
- **3.1.0**: Added team creation feature.  
- **3.0.0**: Introduced widget color theme options.  
- **2.0.0**: Major UI and data communication revisions; added `UITabBarController` and `UINavigationController`.  
- **1.1.0**: Added widget refresh on single tap and app launch on double tap; enabled direct communication from the widget.  
- **1.0.1**: Initial App Store release (November 28, 2017).  

### 버전 2
- **22.38.0**: iOS 16 용 잠금화면 위젯 추가 / invalid user 버그 수정  
- **21.4.0**: 한글 현지화 업데이트  
- **21.3.0**: MacOS 지원  
- **21.2.0**: GITGET VERSION2 배포. 입앱 기능 축소 및 iOS14 target WidgetKit 적용. 앱은 RxSwift, 위젯은 SwiftUI + Combine 활용.  

### 버전 1
- **3.3**: Realm을 이용한 Team 관리, 별명 추가/수정 기능  
- **3.2**: Firebase를 이용한 버전관리 및 Team 관리 UX 개선  
- **3.1.0**: Team 추가 기능  
- **3.0.0**: 위젯 색상 테마 기능  
- **2.0.0**: 대대적 UI 및 데이터 통신 수정. `UITabBarController`, `UINavigationController` 추가  
- **1.1.0**: 위젯을 한번 탭하면 새로고침, 두 번 탭하면 앱이 열리는 기능 추가. 위젯이 직접 통신  
- **1.0.1**: 1차 App Store release (2017.11.28)  

## Contributors (Special Thanks) / 기여자 (특별 감사)
> I would like to extend my heartfelt thanks to those who have contributed to making GITGET better. This includes everyone who submitted pull requests, offered invaluable guidance to a Swift rookie like me, and shared innovative ideas for improvement. I truly appreciate your support! :)  
> GITGET(깃젯)이 더욱 나을 수 있도록 기여를 해주신 분들께 진심으로 감사드립니다. PR을 보내주신 분들, 저에게 많은 가르침을 주신 분들, 개선 아이디어를 공유해주신 분들께 감사드립니다! :)

- [blackturtle2](https://github.com/blackturtle2) | [**Blog**](http://blackturtle2.net)  
- [isjang98](https://github.com/isjang98) | [**Blog**](https://medium.com/@zida.papa)  
- [joeseonmi](https://github.com/joeseonmi)  
- [unnnyong](https://github.com/unnnyong)  
- [woollim](https://github.com/woollim)  

## Contact Me / 연락처
- 📱 +82 10.3316.1609  
- 📧 me@boyoung.dev  
- <img src="https://assets.brandfolder.com/osogig-6gybeo-1fxfn9/original/Slack%20App%20Icon.png" width="20"> [gitget.slack.com](https://gitget.slack.com/messages)  

***
***Love is all or nothing? / 사랑은 전부 아니면 아무것도 아닙니다?***

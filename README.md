# 🐻 FlashKids - 우리 아이 첫 번째 학습 친구

<p align="center">
  <img width="1024" height="500" alt="image" src="https://github.com/user-attachments/assets/b10f94ff-118f-4f87-ae31-00d8921f8ca3" />
</p>

<p align="center">
  <strong>이미지와 단어로 배우는 스마트 플래시카드 앱</strong><br/>
  한글과 영어를 동시에! 아이와 함께하는 즐거운 학습 🎯
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.41.7-02569B?style=flat-square&logo=flutter"/>
  <img src="https://img.shields.io/badge/Dart-3.11.5-0175C2?style=flat-square&logo=dart"/>
  <img src="https://img.shields.io/badge/Platform-Android-3DDC84?style=flat-square&logo=android"/>
  <img src="https://img.shields.io/badge/License-MIT-yellow?style=flat-square"/>
</p>

---

## 📱 스크린샷
<img width="1080" height="1997" alt="KakaoTalk_20260429_111756094_05" src="https://github.com/user-attachments/assets/19f0cdfc-3b13-49b8-9ef7-63d91ca83ebb" />
<img width="1080" height="2068" alt="KakaoTalk_20260429_111756094_03" src="https://github.com/user-attachments/assets/76a2583a-4e6d-4101-8d93-637b82104863" />
<img width="1080" height="2034" alt="KakaoTalk_20260429_111756094_04" src="https://github.com/user-attachments/assets/e5aaf88f-9298-470d-bd72-3f59c14ecac4" />
<img width="1080" height="2090" alt="KakaoTalk_20260429_111756094_01" src="https://github.com/user-attachments/assets/83017c35-9760-44f1-b0b8-e056f28b9520" />
<img width="1080" height="2076" alt="KakaoTalk_20260429_111756094" src="https://github.com/user-attachments/assets/7a9bd795-5eff-46af-b6a3-cf008b292828" />

---

## ✨ 주요 기능

### 📚 플래시카드
- 생생한 이미지와 함께 단어를 자연스럽게 익혀요
- 자동 재생 모드로 손 안 대고 학습 가능
- 속도 조절 슬라이더로 아이 수준에 맞게 설정
- 전체화면 모드로 이미지 크게 보기
- 스와이프 또는 탭으로 카드 넘기기

### 🎯 퀴즈 게임
- 카테고리 및 문제 수 선택 후 도전
- 정답률에 따라 곰돌이 캐릭터가 반응
- 5단계 결과 화면으로 성취감 제공

### 🌍 한글 / 영어 전환
- 버튼 하나로 즉시 전환
- 이중 언어 학습으로 언어 감각 키우기

### 🔊 TTS 발음
- 원어민 발음으로 정확한 발음 학습
- 한국어 / 영어 모두 지원

### 📂 카테고리 다중 선택
| 카테고리 | | 카테고리 | |
|---|---|---|---|
| 🦕 공룡 | 🍎 과일 | 🚗 교통수단 | 🌍 국가 |
| 🌸 꽃 | ⛅ 날씨 | 🐻 동물 | 🎨 색깔 |
| 🔢 숫자 | 🎸 악기 | 🔤 알파벳 | 👷 직업 |
| 🥦 채소 | | | |

---

## 🏗️ 기술 스택

| 분류 | 기술 |
|---|---|
| Framework | Flutter 3.41.7 |
| Language | Dart 3.11.5 |
| 상태관리 | Flutter Riverpod |
| 라우팅 | Go Router |
| 이미지 캐싱 | Cached Network Image |
| TTS | Flutter TTS |
| 로컬 저장소 | Shared Preferences |
| 데이터 | GitHub Pages (JSON) |

---

## 📁 프로젝트 구조

```
lib/
├── main.dart                  # 앱 진입점
├── models/
│   └── flashcard_model.dart   # 데이터 모델
├── providers/
│   └── flashcard_provider.dart # 상태 관리
├── screens/
│   ├── splash_screen.dart     # 스플래시
│   ├── home_screen.dart       # 홈
│   ├── flashcard_screen.dart  # 플래시카드
│   ├── quiz_screen.dart       # 퀴즈
│   ├── card_detail_screen.dart# 카드 목록
│   └── about_screen.dart      # 소개
└── services/
    ├── flashcard_service.dart  # API 서비스
    └── tts_service.dart        # TTS 서비스
```

---

## 🚀 시작하기

### 요구사항
- Flutter 3.x 이상
- Dart 3.x 이상
- Android SDK 21 이상

### 설치 및 실행

```bash
# 저장소 클론
git clone https://github.com/sb2chun/flashkids_flutter.git
cd flashkids_flutter

# 패키지 설치
flutter pub get

# 앱 실행
flutter run
```

### 빌드

```bash
# Android AAB 빌드
flutter build appbundle --release

# Android APK 빌드
flutter build apk --release
```

---

## 📊 플래시카드 데이터

플래시카드 데이터는 별도 저장소에서 GitHub Pages로 제공됩니다.

- API URL: `https://sb2chun.github.io/baby-flashcard/flashcards.json`
- 현재 카드 수: **350개 이상**

---

## 📱 다운로드

Android App 배포 中

---

## 🔒 개인정보처리방침

본 앱은 어떠한 개인정보도 수집하지 않습니다.

- [개인정보처리방침 보기](https://sb2chun.github.io/privacy-policy)

---

## 📄 라이선스

```
MIT License

Copyright (c) 2026 sb2chun

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction.
```

---

<p align="center">
  Made with ❤️ by <a href="https://github.com/sb2chun">sb2chun</a>
</p>

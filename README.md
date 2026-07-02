# ChatAI 📱🤖

An AI-powered iOS chat application built with **SwiftUI** that combines conversational AI, secure authentication, cloud synchronization, subscriptions, speech features, and document management into a modern, production-ready experience.

---

## ✨ Features

- 💬 AI-powered chat interface
- 🔐 Secure Authentication (Email OTP & Supabase Auth)
- ☁️ Cloud synchronization with Supabase
- 🎙️ Speech-to-Text support
- 🔊 Text-to-Speech responses
- 👤 User profile management
- 💎 Premium subscription management
- 📚 Chat history and recent conversations
- 📂 Cloud Library for saved chats
- 📧 Email support integration
- ⚡ Fast and responsive SwiftUI interface

---

# Screenshots

> Add screenshots here.

| Home | Chat | Settings |
|------|------|----------|
| ![](Docs/home.png) | ![](Docs/chat.png) | ![](Docs/settings.png) |

---

# Tech Stack

## iOS

- Swift
- SwiftUI
- MVVM Architecture
- Combine
- Swift Concurrency (async/await)
- URLSession
- Codable
- UserDefaults
- NotificationCenter

---

## Backend

- Supabase
- PostgreSQL
- REST APIs
- Edge Functions

---

## Authentication

- Supabase Authentication
- Email OTP Verification

---

## AI Integration

- AI Chat API
- Prompt Engineering
- Streaming Responses

---

## Cloud Storage

- Supabase Database
- Supabase Storage

---

## Subscription

- RevenueCat Ready Architecture
- Premium Feature Gating

---

## Additional Services

- Speech Recognition
- Text-to-Speech
- SwiftSMTP
- Email Services

---

## Project Structure

```
ChatAI
│
├── UI
│   ├── Home
│   ├── Chat
│   ├── Settings
│   ├── Authentication
│   └── Components
│
├── Models
│
├── Services
│   ├── AI
│   ├── SpeechRecognizer
│   ├── TTSService
│   ├── EmailService
│   ├── SubscriptionManager
│   └── OTPManager
│
├── Supabase
│   ├── Auth
│   ├── Database
│   └── Services
│
├── Utilities
│
└── Assets
```

---

# Architecture

The project follows the **MVVM (Model-View-ViewModel)** architecture.

```
View
   │
ViewModel
   │
Services
   │
Supabase / AI APIs
```

This separation improves maintainability, scalability, and testability.

---

# Getting Started

## Clone the repository

```bash
git clone https://github.com/yourusername/ChatAI.git
```

## Open Project

```bash
open ChatAI.xcodeproj
```

---

## Configure Secrets

Copy

```
Secrets.sample.xcconfig
```

to

```
Secrets.xcconfig
```

Add your credentials:

```
SUPABASE_URL=
SUPABASE_ANON_KEY=
OPENAI_API_KEY=
SMTP_USERNAME=
SMTP_PASSWORD=
```

---

## Install Dependencies

Open the project in Xcode and resolve Swift Package dependencies.

---

## Run

Build and run using Xcode 16+.

---

# Technologies Used

- Swift
- SwiftUI
- Combine
- MVVM
- Supabase
- PostgreSQL
- REST APIs
- SwiftSMTP
- Speech Framework
- AVFoundation
- UserDefaults
- URLSession
- Codable
- Async/Await
- Git
- GitHub
- Xcode

---

# Folder Highlights

## UI

Contains all screens including:

- Home
- Chat
- Settings
- Authentication
- Library

---

## Services

Business logic including

- AI communication
- Email service
- Speech Recognition
- Text-to-Speech
- Subscription handling
- OTP verification

---

## Supabase

Contains

- Authentication
- Database communication
- User management
- Cloud synchronization

---

# Future Improvements

- Image generation
- Voice conversations
- Multiple AI models
- Chat export
- Markdown rendering
- Offline mode
- Apple Sign In
- Push Notifications

---

# Requirements

- macOS
- Xcode 16+
- iOS 17+
- Swift 5.10+

---

# Author

**Ravi Kumar Tiwari**

- LinkedIn: https://www.linkedin.com/in/ravi-tiwari-b047652b4/
- GitHub: https://github.com/RaviTwari03

---

# License

This project is intended for educational and portfolio purposes.

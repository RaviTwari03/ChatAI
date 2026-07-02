<div align="center">

# 🤖 ChatAI

### *An Intelligent AI-Powered iOS Chat Application*

<img src="https://img.shields.io/badge/Platform-iOS-blue?style=for-the-badge&logo=apple" />
<img src="https://img.shields.io/badge/Swift-5.10-orange?style=for-the-badge&logo=swift" />
<img src="https://img.shields.io/badge/SwiftUI-MVVM-green?style=for-the-badge" />
<img src="https://img.shields.io/badge/Supabase-Backend-3ECF8E?style=for-the-badge&logo=supabase" />
<img src="https://img.shields.io/badge/OpenAI-AI-black?style=for-the-badge&logo=openai" />
<img src="https://img.shields.io/badge/License-MIT-blue?style=for-the-badge" />

A modern **AI-powered iOS application** built using **SwiftUI** that delivers intelligent conversations, secure authentication, cloud synchronization, premium subscriptions, speech capabilities, and document management within a clean and responsive user experience.

</div>

---

# ✨ Features

<table>
<tr>
<td width="50%">

### 🤖 AI Experience

- 💬 Intelligent AI Conversations
- ⚡ Real-time Streaming Responses
- 🧠 Prompt Engineering
- 📚 Chat History
- 📂 Cloud Library
- 📄 Document Management

</td>

<td width="50%">

### 📱 User Experience

- 🔐 Secure Authentication
- ☁️ Cloud Sync
- 💎 Premium Subscription
- 🎙️ Speech-to-Text
- 🔊 Text-to-Speech
- 👤 User Profiles

</td>
</tr>
</table>

---

# 📸 Screenshots

<p align="center">

| Home | AI Chat | Profile |
|------|---------|----------|
| <img src="Screenshots/home.png" width="230"/> | <img src="Screenshots/chat.png" width="230"/> | <img src="Screenshots/profile.png" width="230"/> |

</p>

> **Replace the above screenshots with your own images.**

---

# 🏗 Architecture

```text
                   SwiftUI Views
                         │
                         ▼
                  ViewModels (MVVM)
                         │
                         ▼
                    Business Logic
                         │
     ┌───────────────────┼──────────────────┐
     ▼                   ▼                  ▼
 OpenAI API         Supabase API      Local Services
     │                   │                  │
     └────────────── Cloud Backend ─────────┘
```

The application follows the **MVVM (Model-View-ViewModel)** architecture, ensuring scalability, modularity, and maintainability.

---

# 🛠 Tech Stack

## 📱 iOS Development

| Technology | Usage |
|------------|-------|
| Swift | Core Language |
| SwiftUI | UI Development |
| MVVM | Architecture |
| Combine | Reactive Programming |
| Async/Await | Concurrency |
| URLSession | Networking |
| Codable | JSON Parsing |
| UserDefaults | Local Storage |
| NotificationCenter | Event Handling |

---

## ☁️ Backend

| Technology | Usage |
|------------|-------|
| Supabase | Backend as a Service |
| PostgreSQL | Database |
| REST APIs | Communication |
| Edge Functions | Server-side Logic |

---

## 🤖 AI

- OpenAI API
- Prompt Engineering
- Streaming Responses
- AI Chat Services

---

## 🔐 Authentication

- Email OTP Verification
- Supabase Authentication
- Secure Session Management

---

## 💎 Subscription

- RevenueCat Integration
- Premium Feature Management
- Subscription Validation

---

## 📂 Cloud Services

- Supabase Storage
- Cloud Database
- User Data Synchronization

---

## 🎙 Additional Services

- Speech Recognition
- Text-to-Speech
- SwiftSMTP
- Email Support

---

# 📂 Project Structure

```text
ChatAI
│
├── App
│
├── Views
│   ├── Home
│   ├── Chat
│   ├── Profile
│   ├── Settings
│   ├── Authentication
│   └── Components
│
├── ViewModels
│
├── Models
│
├── Services
│   ├── AI
│   ├── Speech
│   ├── TextToSpeech
│   ├── Email
│   ├── Authentication
│   ├── Subscription
│   └── Networking
│
├── Supabase
│
├── Utilities
│
├── Assets
│
└── Resources
```

---

# 🚀 Getting Started

## 1️⃣ Clone the Repository

```bash
git clone https://github.com/RaviTwari03/ChatAI.git
```

---

## 2️⃣ Open the Project

```bash
open ChatAI.xcodeproj
```

---

## 3️⃣ Configure Environment Variables

Create

```
Secrets.xcconfig
```

Add

```text
SUPABASE_URL=

SUPABASE_ANON_KEY=

OPENAI_API_KEY=

SMTP_USERNAME=

SMTP_PASSWORD=
```

---

## 4️⃣ Install Dependencies

Resolve all Swift Package Manager dependencies directly from **Xcode**.

---

## 5️⃣ Run the App

Build and run using

- Xcode 16+
- iOS 17+
- Swift 5.10+

---

# ⚙ Technologies Used

<div align="center">

| iOS | Backend | AI | Tools |
|------|---------|------|-------|
| Swift | Supabase | OpenAI API | Git |
| SwiftUI | PostgreSQL | Prompt Engineering | GitHub |
| Combine | REST APIs | Streaming AI | Xcode |
| MVVM | Edge Functions | LLM Integration | Postman |
| Async/Await | Cloud Storage | AI Services | Cursor |

</div>

---

# 📌 Highlights

✅ Modern SwiftUI Interface

✅ MVVM Architecture

✅ Secure Authentication

✅ Cloud Synchronization

✅ AI-powered Conversations

✅ Voice Support

✅ Premium Subscription System

✅ Scalable Backend

---

# 🚧 Future Roadmap

- 🖼 AI Image Generation
- 🎤 Voice-to-Voice Conversations
- 🌐 Multiple AI Providers
- 📤 Chat Export
- 📝 Markdown Rendering
- 📱 Offline Mode
- 🍎 Sign in with Apple
- 🔔 Push Notifications
- 🎨 Theme Customization

---

# 👨‍💻 Author

<div align="center">

## Ravi Kumar Tiwari

**iOS Developer • AI/ML Enthusiast • Swift Developer**

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Ravi%20Kumar%20Tiwari-blue?style=for-the-badge&logo=linkedin)](https://www.linkedin.com/in/ravi-tiwari-b047652b4/)

[![GitHub](https://img.shields.io/badge/GitHub-RaviTwari03-black?style=for-the-badge&logo=github)](https://github.com/RaviTwari03)

</div>

---

<div align="center">

### ⭐ If you like this project, consider giving it a star!

Made with ❤️ using **SwiftUI**, **Supabase**, and **OpenAI**

</div>

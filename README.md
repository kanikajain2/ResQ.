# ResQ — Crisis Coordination & Emergency Intelligence 🛡️🚀

ResQ is a production-grade, offline-first emergency coordination platform designed for high-stakes hospitality and event environments. It transforms chaotic crisis moments into synchronized, data-driven responses using real-time tracking, AI-powered intelligence, and a resilient P2P mesh network.

![Theme](https://img.shields.io/badge/Theme-Soft_Coral_%26_Pristine_White-FF4D67)
![AI](https://img.shields.io/badge/AI-Gemini_Pro-00D97E)
![Performance](https://img.shields.io/badge/Triage_Speed-1.2s-blue)

## 🌟 Core Capabilities

### 🛡️ For Guests (Crisis Intelligence)
- **Instant SOS**: One-tap emergency alerts with automatic room identification and spatial context.
- **AI Triage Speed Badge**: Real-time transparency showing exactly how fast Gemini analyzed the situation (e.g., *"AI triaged in 1.2s"*).
- **Crisis AI Chat**: Intelligent triage and safety guidance powered by Google Gemini, offering immediate reassurance.
- **Live Status Tracking**: A modern, shadow-free visual stepper tracking the response team from "Received" to "Resolved."
- **Emergency Hub**: Direct tap-to-call access to local emergency services for maximum redundancy.

### ⚖️ For Staff (Command & Control)
- **Soft Coral Command Dashboard**: A high-fidelity "God's Eye" view of active incidents on a high-precision, interactive map.
- **Real-time Staff Status Management**: Automatic availability tracking (Available/En Route/On Scene) ensuring optimized resource allocation.
- **Resolution Checklist**: Mandatory 3-step safety verification (Guest Safe, Area Clear, Services Notified) before an incident can be closed.
- **Automated Gemini Reporting**: Instant generation of professional post-incident summaries for insurance and legal compliance.
- **Live Video Bridge**: Instant encrypted video coordination between the command center and responders on the scene.

### 🔗 For Infrastructure (Crisis Hardening)
- **Offline P2P Mesh**: Communication remains active via Google Nearby Connections even if the hotel's Wi-Fi or cellular network fails.
- **Multi-Database Resilience**: Enterprise-grade Firestore architecture using dedicated database instances (`sos1-1information`).
- **Response Timeline**: Automated, second-by-second auditing of every action, creating an indisputable "Black Box" record of the crisis.

## 🎨 Visual Identity & Aesthetics

ResQ uses a curated **Soft Coral (#FF4D67)** and **Pristine White** design system. This palette balances the urgency of an emergency with the premium, calming atmosphere of a high-end hotel. Success states utilize a high-visibility **Neon Emerald (#00D97E)** for maximum clarity in high-stress moments.

## 🛠️ Technical Stack

- **Framework**: Flutter (Dart) — High-performance cross-platform UI.
- **Backend**: Firebase (Firestore Enterprise, Auth, Storage).
- **AI Engine**: Google Gemini (Flash & Pro models) for triage and reporting.
- **Connectivity**: WebRTC (Video) & Google Nearby Connections (P2P Mesh).
- **Animations**: Flutter Animate (Fluid, premium micro-interactions).

## 📜 Role Permissions Matrix

| Feature | Responder | Manager | Admin |
| :--- | :---: | :---: | :---: |
| View Dashboard | ✅ | ✅ | ✅ |
| Update Status (En Route/On Scene) | ✅ | ✅ | ✅ |
| Reassign Responders | ❌ | ✅ | ✅ |
| Mark Resolved (Safety Checklist) | ❌ | ✅ | ✅ |
| View Analytics & Audit Logs | ❌ | ✅ | ✅ |
| Manage Staff & Database Config | ❌ | ❌ | ✅ |

## 🛡️ Security & Integrity

ResQ implements **Production-Grade Firestore Security Rules** to ensure data integrity:
- **Role-Based Access (RBAC)**: Security rules verify staff roles before allowing state changes.
- **Atomic Availability**: Staff status is automatically reset to `available` upon incident resolution or reassignment.
- **Server-Side Timeline**: Every critical event uses `FieldValue.serverTimestamp()` to maintain a tamper-proof audit trail.
- **Data Hardening**: Critical incident fields (Room Number, Guest ID) are immutable after creation.

---
**ResQ** — *Because every second counts.* 🛡️✨🏥🚨

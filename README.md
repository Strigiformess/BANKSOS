````md
# BANKSOS

BANKSOS (Bank Soal Kolaboratif) adalah aplikasi mobile berbasis Flutter dengan pendekatan **offline-first** yang dirancang untuk membantu mahasiswa mengakses, mengerjakan, dan berkontribusi soal latihan akademik secara fleksibel, bahkan tanpa koneksi internet.

Aplikasi ini terinspirasi dari platform latihan seperti picoCTF dan redlimit.hack.id, namun difokuskan untuk kebutuhan akademik mahasiswa Teknik Informatika dan Teknik Komputer.

---

# ✨ Fitur Utama

## 👨‍🎓 Mahasiswa
- Registrasi & login
- Browse bank soal berdasarkan mata kuliah
- Filter tingkat kesulitan
- Kerjakan soal online & offline
- Sistem jawaban short-answer (case-insensitive)
- Placeholder jawaban seperti THM (`____ ____`)
- Bookmark soal
- Riwayat pengerjaan
- Submit soal baru
- Download soal untuk offline

## 🛡 Reviewer
- Review soal mahasiswa
- Approve / reject / revisi soal
- Atur kategori & tingkat kesulitan
- Kelola koleksi soal

## ⚙ Admin
- Kelola user
- Kelola status soal
- Arsipkan / nonaktifkan soal
- Kontrol sistem penuh

---

# 🧠 Konsep Utama

## Offline-First Architecture

BANKSOS menggunakan pendekatan hybrid:

- **Hive (Local Storage)** → penyimpanan offline
- **MongoDB (Cloud Database)** → sinkronisasi & kolaborasi

Pengguna tetap dapat:
- membuka soal
- mengerjakan soal
- melihat progress

meskipun tidak memiliki koneksi internet.

---

# 🏗 Tech Stack

## Frontend
- Flutter

## Local Storage
- Hive

## Backend
- REST API

## Database
- MongoDB

## State Management
- Provider / Riverpod

---

# 📁 Struktur Project

```plaintext
lib/
│
├── core/                    
│   ├── config/            
│   ├── constants/          
│   ├── guard/              
│   ├── services/            
│   ├── theme/              
│   └── utils/             
│
├── data/                  
│   ├── local/
│   │   ├── boxes/          
│   │   └── hive/           
│   ├── models/                                 
│   └── remote/
│       ├── mongodb/        
│       ├── auth_remote.dart
│       ├── question_remote.dart
│       ├── review_remote.dart
│       ├── bookmark_remote.dart
│       ├── progress_remote.dart
│       └── category_remote.dart
│
├── features/             
│   ├── admin/                                   
│   ├── auth/                               
│   ├── bookmarks/        
│   ├── collection/         
│   ├── dashboard/                          
│   ├── kontribusi/                       
│   ├── profile/             
│   ├── question/          
│   ├── review/            
│   ├── reviewer/         
│   ├── riwayat/            
│   └── statistics/         
│
├── routes/                 
├── shared/
│   ├── layouts/            
│   └── widgets/             
│                            
│                           
└── main.dart                


# 🗂 Database Entities

## Users

```json
{
  "_id": "ObjectId",
  "nama_lengkap": "string",
  "nim": "string",
  "email": "string",
  "password_hash": "string",
  "role": "mahasiswa | reviewer | admin",
  "status": "active | inactive"
}
```

## Questions

```json
{
  "_id": "ObjectId",
  "pertanyaan": "string",
  "jawaban": "string",
  "kategori_id": "ObjectId",
  "tingkat_kesulitan": "easy | medium | hard",
  "status": "pending | published | rejected | archived",
  "hints": [],
  "submitted_by": "ObjectId"
}
```

---

# 🔐 Role System

| Role      | Akses                                |
| --------- | ------------------------------------ |
| Mahasiswa | Kerjakan soal, bookmark, submit soal |
| Reviewer  | Review & moderasi soal               |
| Admin     | Kelola sistem & user                 |

---

# 🧩 Sistem Jawaban

BANKSOS menggunakan sistem jawaban short-answer:

* tidak case-sensitive
* whitespace trimming
* placeholder jawaban otomatis

Contoh:

```txt
Jawaban asli:
basis data

Ditampilkan:
_____ _____
```

---

# 🔄 Sinkronisasi Offline

Saat offline:

* progress disimpan ke Hive
* data masuk ke SyncQueue

Saat online kembali:

* SyncManager otomatis sinkronisasi ke server

---

# 🌙 UI/UX Principles

* Modern minimalis
* Dominan warna biru
* Dark mode support
* Mobile-first design
* Feedback interaktif

---

# 🌿 Git Workflow

## Branch Strategy

```plaintext
main
develop
feature/*
fix/*
```

## Commit Convention

```plaintext
feat: add offline sync manager
fix: correct answer validation
docs: update readme
```

---

# 🚀 Setup Project

## 1. Clone Repository

```bash
git clone <repository-url>
```

---

## 2. Masuk ke folder project

```bash
cd BANKSOS
```

---

## 3. Install dependency

```bash
flutter pub get
```

---

## 4. Run project

```bash
flutter run
```

---

# 📌 MVP Scope

* Android only
* Offline-first
* Short answer system
* Review moderation
* Bookmark system
* Progress tracking
* Sync manager

---

# 📅 Sprint Planning

| Sprint   | Fokus               |
| -------- | ------------------- |
| Sprint 0 | Setup & arsitektur  |
| Sprint 1 | Auth & role         |
| Sprint 2 | Bank soal & offline |
| Sprint 3 | Hint & bookmark     |
| Sprint 4 | Submit & review     |
| Sprint 5 | Sync & admin        |
| Sprint 6 | Testing & polish    |

---

# 👥 Tim Pengembang

| Nama                    | Role                          |
| ----------------------- | ----------------------------- |
| Seruni Libertina Islami | Flutter Dev                   |
| Mohammad Jibril Fathi   | Flutter Dev / Offline-First   |
| Revaldi Prasetyo        | Feature Dev                   |
| Adjie Ali Nurfizal      | Backend Dev                   |

---

# 📄 License

Internal Academic Project — POLBAN

```
```

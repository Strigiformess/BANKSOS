# banksos

lib/
│
├── core/
│   ├── constants/
│   ├── theme/
│   ├── utils/
│   ├── errors/
│   ├── services/
│   └── config/
│
├── data/
│   ├── local/
│   │   ├── hive/
│   │   └── boxes/
│   │
│   ├── remote/
│   │   └── mongodb/
│   │
│   ├── models/
│   └── repositories/
│
├── features/
│   ├── auth/
│   │   ├── screens/
│   │   ├── widgets/
│   │   ├── controllers/
│   │   └── services/
│   │
│   ├── questions/
│   ├── bookmarks/
│   ├── review/
│   ├── sync/
│   ├── admin/
│   └── dashboard/
│
├── shared/
│   ├── widgets/
│   ├── components/
│   └── layouts/
│
├── routes/
│
├── providers/
│
└── main.dart

core/

Berisi hal global aplikasi.

constants/

Semua konstanta.

Contoh:

warna
nama hive box
role user
status soal
theme/

Konfigurasi tema.

utils/

Helper functions.

services/

Service global.

Contoh:

connectivity service
session service
data/

Semua data handling.

local/

Semua akses Hive.

remote/

Semua akses MongoDB.

models/

Semua model aplikasi.

repositories/

Layer penghubung antara UI dan database.

features/

Semua fitur dipisah per domain.

















A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

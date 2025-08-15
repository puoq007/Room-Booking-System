## 🏢 Room Booking System

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)
[![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://www.android.com/)
[![iOS](https://img.shields.io/badge/iOS-000000?style=for-the-badge&logo=ios&logoColor=white)](https://www.apple.com/ios/)

---

### ภาพรวมโปรเจกต์ (Project Overview)

**Room Booking System** คือแอปพลิเคชันมือถือที่พัฒนาขึ้นด้วย **Flutter** เพื่อมอบประสบการณ์การจัดการและจองห้องพักที่ทันสมัยและสะดวกสบายแก่ผู้ใช้งาน ไม่ว่าจะเป็นห้องประชุม ห้องเรียน หรือพื้นที่อื่น ๆ ภายในองค์กรหรือสถาบัน แอปพลิเคชันนี้จะช่วยแก้ปัญหาความยุ่งยากในการจองได้อย่างมีประสิทธิภาพ

ด้วยอินเทอร์เฟซที่ใช้งานง่าย แอปพลิเคชันนี้จะแสดงสถานะห้องว่างแบบ **เรียลไทม์** ช่วยให้ผู้ใช้สามารถดูข้อมูลห้อง จอง และจัดการการจองได้อย่างรวดเร็ว

---

### คุณสมบัติหลัก (Key Features)

* **ดูห้องว่าง:** แสดงรายละเอียดของห้องแต่ละห้องอย่างครบถ้วน รวมถึงความจุ, สิ่งอำนวยความสะดวก และรูปภาพ
* **จองห้อง:** เลือกวันที่และเวลาที่ต้องการได้อย่างง่ายดายผ่านปฏิทินและตัวเลือกเวลาที่ชัดเจน
* **จัดการการจอง:** ตรวจสอบ แก้ไข หรือยกเลิกการจองที่มีอยู่ได้ตลอดเวลา
* **ระบบแจ้งเตือน:** มีระบบแจ้งเตือนอัตโนมัติสำหรับการจองที่กำลังจะมาถึง เพื่อให้ไม่พลาดนัดหมายสำคัญ
* **รองรับหลายแพลตฟอร์ม:** แอปพลิเคชันสามารถใช้งานได้ทั้งบนระบบปฏิบัติการ **Android** และ **iOS**

---

### 🚀 วิธีเริ่มต้นใช้งาน (Getting Started)

ทำตามขั้นตอนด้านล่างเพื่อตั้งค่าและรันโปรเจกต์นี้บนเครื่องของคุณสำหรับการพัฒนาหรือทดสอบ:

#### ข้อกำหนดเบื้องต้น (Prerequisites)

ตรวจสอบให้แน่ใจว่าได้ติดตั้งซอฟต์แวร์ต่อไปนี้เรียบร้อยแล้ว:
* **Flutter SDK**
* **Dart**
* **Android Studio** หรือ **VS Code** (พร้อมส่วนขยาย Flutter & Dart)
* **Emulator** หรืออุปกรณ์จริงสำหรับทดสอบ

### 1. **โคลน Repository:**

    git clone https://github.com/puoq007/Room-Booking-System.git
    cd Room-Booking-System

### 2. การติดตั้ง Dependencies

ก่อนรันโปรเจกต์ คุณต้องติดตั้ง Dependencies ทั้งหมดที่ระบุในไฟล์ pubspec.yaml ด้วยคำสั่ง:

    flutter pub get

### 3. การตั้งค่า Firebase (ถ้ามี)

หากโปรเจกต์มีการใช้งาน Firebase คุณจะต้องตั้งค่า Firebase สำหรับโปรเจกต์ของคุณ:

สร้างโปรเจกต์ใหม่ใน Firebase Console

ทำตามขั้นตอนเพื่อเพิ่มแอปพลิเคชัน Android และ iOS

ดาวน์โหลดไฟล์ google-services.json สำหรับ Android และ GoogleService-Info.plist สำหรับ iOS แล้วนำไปวางในโฟลเดอร์ที่เหมาะสมตามที่เอกสารของ Firebase ระบุ

### 4. การรันแอปพลิเคชัน

หลังจากติดตั้ง Dependencies และตั้งค่าต่างๆ เรียบร้อยแล้ว คุณสามารถรันแอปพลิเคชันได้บนอุปกรณ์จำลอง (Emulator) หรืออุปกรณ์จริง (Physical Device) ด้วยคำสั่ง:

    flutter run

หากต้องการรันบนอุปกรณ์ที่เฉพาะเจาะจง ให้ใช้คำสั่ง:

    flutter run -d <device_id>

คุณสามารถดูรายการอุปกรณ์ทั้งหมดได้ด้วยคำสั่ง flutter devices

การสร้าง Build สำหรับ Production

หากต้องการสร้างไฟล์ติดตั้ง (APK หรือ App Bundle) สำหรับ Android หรือไฟล์ .ipa สำหรับ iOS ให้ใช้คำสั่ง:

    flutter build apk
#### หรือ
    flutter build appbundle
#### หรือ
    flutter build ipa

### โครงสร้างไฟล์
    Project/
    ├── API/                        # ไฟล์สำหรับจัดการ Endpoints และ Logic ของ API
    │   ├── roomPicture             # รูปห้องประชุม
    │   ├── app.js                  # API
    │   ├── db.js                   # Data Base
    ├── lib/                        # โค้ดหลักของ Flutter
    │   ├── main.dart               # จุดเริ่มต้นของแอปพลิเคชัน
    │   ├── Logo.dart               # Logo
    │   ├── Login.dart              # Login
    │   ├── dashboard.dart          # dashboard หลัก
    │   ├── Register.dart           # Register
    │   ├── approver/               # โฟลเดอร์ Approver
    │   │   ├── apphome.dart        # Home Approver
    │   │   ├── appnavbar.dart      # Navbar Approver
    │   │   ├── appprofile.dart     # Profile Approver
    │   │   ├── appprequest.dart    # Request Approver
    │   ├── staff/                  # โฟลเดอร์ Staff
    │   │   ├── staffhome.dart      # Home Staff
    │   │   ├── appnav.dart         # Navbar Staff
    │   │   ├── appprofile.dart     # Profile Staff
    │   ├── stu/                    # โฟลเดอร์ Student
    │   │   ├── stuHome.dart        # Home Student
    │   │   ├── stunavbar.dart      # Navbar Student
    │   │   ├── stuProfile.dart     # Profile Student
    │   │   ├── stuRequest.dart     # Request Student
    ├── android/                    # โฟลเดอร์สำหรับ Android
    ├── ios/                        # โฟลเดอร์สำหรับ iOS
    ├── assets/                     # ไฟล์สื่อ เช่น รูปภาพ, ไอคอน
    ├── build/                      # โฟลเดอร์ที่สร้างโดย Flutter (ไม่ควรนำขึ้น Git)
    ├── pubspec.yaml                # รายการ dependencies และการตั้งค่าโปรเจกต์
    ├── .gitignore                  # ไฟล์ที่บอก Git ว่าจะไม่ติดตามไฟล์ใด
    └── README.md                   # เอกสารโปรเจกต์
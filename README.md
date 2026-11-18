# Kerio Control macOS Standalone Client

[English](#english) | [فارسی](#persian)

---

<a name="english"></a>
## English

A native, standalone macOS client wrapper for **Kerio Control VPN**, designed to run on modern macOS versions (**macOS 13 Ventura, macOS 14 Sonoma, macOS 15 Sequoia, and newer**).

### Why doesn't the official Kerio client work on modern macOS?

1. **Preference Panes Removed by Apple:** Kerio never provided a standalone configuration app for macOS; instead, it relied on a legacy System Preferences pane (`KVpnClient.prefPane`). Apple completely discontinued third-party Preference Panes in macOS Ventura and newer.
2. **Crash on Launch Bug:** Kerio's legacy client code invokes an invalid memory release (`CFRelease(NULL)`) when checking Login Items, causing it to crash immediately and silently on modern macOS.
3. **Background Daemon Management:** The background service (`com.kerio.kvpncsvc`) often fails to load automatically without elevated privileges on newer macOS security architectures.

This project wraps the official configuration view inside a clean, modern Cocoa application and applies a lightweight safety hook to eliminate the crash—restoring full functionality on all modern Macs.

### Features

* **Universal 2 Binary:** Native support for both **Apple Silicon (M1/M2/M3/M4)** and **Intel (x86_64)** processors.
* **Complete GUI:** Full connection configuration, server settings, credentials, saved passwords, and SSL certificate trust dialogs.
* **Service Monitor & Helper:** Real-time indicator for the background Kerio service status (`🟢 Active` / `⚠️ Inactive`) with a one-click root starter.
* **Full Keyboard & Clipboard Support:** Standard macOS Edit menu enabling `Cmd+C`, `Cmd+V`, `Cmd+A` for easy pasting of credentials.
* **Native Integration:** Runs in the Dock, Launchpad, and Application switcher with the official Kerio icon.

### Prerequisites

You must have the official Kerio Control VPN Client package installed once on your Mac, as it supplies the required kernel/system network extensions (`KerioVpnNetExt`) and background daemon.

### Installation

1. Download **`Kerio Control-macOS-Universal.dmg`** from the [Releases](https://github.com/) section.
2. Open the DMG file and drag **Kerio Control** to your **Applications** folder.
3. Launch **Kerio Control** from Applications or Spotlight.
4. If the top service banner shows inactive, click **Start Service** and enter your administrator password.
5. Enter your VPN server, username, and password, then click **Connect**.

### Building from Source

Requirements: Xcode Command Line Tools (`xcode-select --install`).

```bash
# Clone the repository
git clone https://github.com/your-username/kerio-control-mac.git
cd kerio-control-mac

# Build the Universal .app bundle
./build.sh

# Build DMG and ZIP release packages (placed in ./dist)
./build.sh release
```

### Troubleshooting

* **Connected, but IP has not changed:**
  * **Conflicting Proxy/TUN:** If tools like `v2rayN`, `sing-box`, `Clash`, or `Hiddify` are running with **TUN Mode enabled**, they intercept all system routes. Turn off TUN mode or disconnect them before connecting Kerio.
  * **Split Tunneling:** By default, Kerio Control VPN operates in split-tunnel mode (only routing private office subnets). For full-tunnel internet traffic, the administrator must enable *"All traffic goes through the firewall"* on the Kerio Control server.

---

<a name="persian"></a>
## فارسی

یک کلاینت بومی و مستقل برای **Kerio Control VPN** روی مک، سازگار با نسخه‌های مدرن سیستم‌عامل مک (**macOS 13 Ventura، macOS 14 Sonoma، macOS 15 Sequoia و نسخه‌های جدیدتر**).

### چرا نسخه رسمی کریو روی مک‌های جدید باز نمی‌شود؟

1. **حذف Preference Panes توسط اپل:** شرکت Kerio نرم‌افزار مستقلی برای باز شدن در داک یا لانچ‌پد نداشت و صرفاً به پنل تنظیمات System Preferences قدیمی (`KVpnClient.prefPane`) متکی بود. اپل از macOS 13 به بعد پشتیبانی از این پنل‌ها را کاملاً حذف کرد.
2. **باگ کرش لحظه‌ای:** کدهای قدیمی کریو هنگام بررسی Login Items یک اشاره‌گر خالی را آزاد می‌کردند (`CFRelease(NULL)`) که در مک‌های جدید منجر به کرش نامرئی برنامه می‌شد.
3. **عدم اجرای خودکار سرویس:** سرویس پس‌زمینه کریو (`com.kerio.kvpncsvc`) به دلیل تغییرات امنیتی مک جدید بدون تایید اولیه ادمین لود نمی‌شد.

این پروژه رابط کاربری رسمی کریو را داخل یک پنجره استاندارد مک اجرا کرده و با یک هوک امنیتی کوچک، باگ کرش را خنثی می‌کند.

### امکانات و ویژگی‌ها

* **باینری یونیورسال (Universal 2):** سازگار با تمام مک‌های **Apple Silicon (M1/M2/M3/M4)** و پردازنده‌های **Intel**.
* **رابط کاربری کامل:** دسترسی به تمام فیلدهای سرور، پورت، نام کاربری، رمز عبور، ذخیره پسورد و تایید گواهی SSL.
* **نوار وضعیت هوشمند سرویس:** نمایش زنده وضعیت سرویس کریو (`🟢 فعال` / `⚠️ متوقف`) با کلید راه‌اندازی سریع با دسترسی ادمین.
* **پشتیبانی از کپی/پیست:** منوی استاندارد ادیت برای کارکرد صحیح کلیدهای `Cmd+C` ،`Cmd+V` و `Cmd+A` هنگام وارد کردن اطلاعات.
* **آیکون رسمی:** نمایش استاندارد در Dock، Launchpad و منوی برنامه‌ها.

### پیش‌نیاز

پکیج رسمی کریو کنترل (`Kerio Control VPN Client`) باید از قبل روی سیستم نصب شده باشد تا درایورهای شبکه و افزونه سیستمی در مک وجود داشته باشند.

### راهنمای نصب و استفاده

1. از بخش **Releases** فایل **`Kerio Control-macOS-Universal.dmg`** را دانلود کنید.
2. فایل DMG را باز کرده و برنامه **Kerio Control** را به پوشه **Applications** بکشید.
3. برنامه را از Applications یا با جستجو در Spotlight اجرا کنید.
4. در صورت مشاهده وضعیت قرمز سرویس، کلید **Start Service** را زده و رمز عبور مک خود را وارد نمایید.
5. مشخصات سرور و اکانت خود را وارد کرده و روی **Connect** کلیک کنید.

### بیلد از سورس‌کد (برای توسعه‌دهندگان)

```bash
# بیلد برنامه به صورت یونیورسال
./build.sh

# ساخت پکیج‌های DMG و ZIP در پوشه dist
./build.sh release
```

### نکات عیب‌یابی

* **اتصال برقرار است اما آی‌پی تغییر نکرده:**
  * **تداخل با سایر فیلترشکن‌ها:** اگر برنامه‌هایی مثل `v2rayN`، `sing-box` یا `Hiddify` با قابلیت **TUN Mode** روشن باشند، کل ترافیک شبکه را مصادره می‌کنند. قبل از اتصال کریو، حالت TUN آن‌ها را خاموش کنید.
  * **طراحی Split-Tunnel در کریو:** کریو کنترل به طور پیش‌فرض فقط ترافیک شبکه داخلی سرور مقصد را عبور می‌دهد. برای عبور کل ترافیک اینترنت از کریو، مدیر سرور باید گزینه *"All traffic goes through the firewall"* را در تنظیمات فایروال کریو فعال کرده باشد.

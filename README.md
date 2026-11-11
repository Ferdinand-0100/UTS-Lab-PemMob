# Quiz Master

**a. Identitas Mahasiswa**

| | |
|---|---|
| Nama | Ferdinand |
| NIM | 241401080 |
| Lab. | PM 4 |

---

## b. Informasi Aplikasi

**i. Nama Aplikasi:** Quiz Master

**ii. Deskripsi Singkat:**
Quiz Master adalah aplikasi mobile kuis berbasis Flutter yang menggabungkan pengalaman bermain kuis pilihan berganda dengan elemen sosial. User dapat mengerjakan kuis yang dibuat oleh admin, melihat hasilnya secara langsung, dan memantau progress teman-teman mereka. Tampilan aplikasi menggunakan tema konsol game retro (CRT / Game Boy), dengan layar phosphor hijau, efek scanline, tombol arcade, dan boot sequence saat berpindah halaman.

---

**iii. Fitur-Fitur yang Tersedia**

### 1. Autentikasi (Sign Up / Sign In)
- User dapat mendaftar akun baru dengan nama tampil, email, dan password.
- User yang sudah terdaftar dapat masuk menggunakan email dan password.
- Terdapat dua peran: **User** (pemain) dan **Admin** (pembuat kuis). Peran Admin memerlukan kode rahasia saat registrasi.
- Validasi form dilakukan di sisi klien sebelum dikirim ke server.
- Sesi login dipertahankan secara otomatis oleh Supabase Auth.

### 2. Halaman Utama (Home)
- Menampilkan daftar semua kuis yang tersedia dalam bentuk kartu.
- Setiap kartu kuis menampilkan:
  - Judul dan deskripsi kuis
  - Jumlah pertanyaan
  - Batas nilai kelulusan (passing score)
  - **Label tingkat kesulitan** (EASY / MED / HARD) berdasarkan passing score:
    - Hijau (EASY): passing score < 60%
    - Biru (MED): passing score 60–79%
    - Magenta (HARD): passing score ≥ 80%
  - **Badge `✓ PASSED`** berwarna phosphor hijau jika user sudah pernah lulus kuis tersebut minimal sekali
- Navigasi antar halaman menggunakan animasi CRT loading screen (900ms minimum) untuk menjaga konsistensi feel konsol retro.

### 3. Bermain Kuis (Quiz Play)
- Kuis berbentuk pilihan berganda (MCQ) dengan 4 pilihan jawaban per pertanyaan.
- Setiap pertanyaan memiliki **timer countdown** yang terlihat secara visual:
  - Hijau (> 10 detik): normal
  - Kuning (6–10 detik): hampir habis
  - Merah (≤ 5 detik): kritis
- Jika waktu habis sebelum menjawab, pertanyaan otomatis dilewati (dihitung sebagai tidak dijawab).
- Setiap pilihan jawaban memiliki warna aksen berbeda (A=hijau, B=biru, C=magenta, D=kuning).
- Saat user mengetuk jawaban:
  - Timer **dijeda** secara otomatis
  - Tombol jawaban **berkilau selama 2 detik** dengan warna penuhnya sebagai konfirmasi visual
  - Efek suara `buttonAnswer.mp3` diputar
  - Setelah 2 detik, lanjut ke pertanyaan berikutnya
- Terdapat konfirmasi dialog jika user menekan tombol kembali di tengah kuis (progres akan hilang).
- Bar progress di bagian atas menunjukkan posisi pertanyaan saat ini dari total pertanyaan.

### 4. Hasil Kuis (Quiz Result)
- Menampilkan persentase nilai dengan **animasi penghitung** yang naik dari 0% ke nilai aktual selama 1,2 detik.
- Stamp PASSED atau FAILED ditampilkan dengan warna hijau (lulus) atau merah (gagal).
- Tabel tally menunjukkan jumlah jawaban benar, salah, dan pertanyaan yang dilewati.
- Bagian **Breakdown** menampilkan setiap pertanyaan beserta:
  - Jawaban yang dipilih user
  - Jawaban yang benar (jika user salah)
  - Warna kartu berbeda: hijau (benar), merah (salah), kuning (dilewati)
- Nilai kuis otomatis disimpan ke database Supabase setelah selesai.

### 5. Friendlist (Daftar Teman)
- User dapat **menambah teman** dengan memasukkan alamat email teman.
- Permintaan pertemanan bersifat dua arah: penerima harus menerima terlebih dahulu sebelum keduanya terhubung.
- Status pertemanan ditampilkan dengan LED indicator:
  - Kuning berkedip: masih pending
  - Hijau: sudah terhubung
- Setiap kartu teman yang sudah terhubung menampilkan **Quiz Pass Bar**:
  - Segmen blok per kuis yang pernah dicoba
  - Blok terisi = pernah lulus kuis tersebut minimal sekali
  - Warna hijau jika semua kuis lulus, kuning jika sebagian
  - Penghitung `x/y` di sebelah kanan (contoh: `2/3`)
- User dapat membatalkan permintaan yang dikirim atau menghapus teman yang sudah terhubung.

### 6. Admin — Membuat Kuis
- Hanya akun dengan peran Admin yang dapat mengakses fitur ini.
- Form pembuatan kuis mencakup:
  - Judul dan deskripsi kuis
  - Passing score (0–100%)
  - Daftar pertanyaan yang dapat ditambah/dihapus secara dinamis
- Setiap pertanyaan memiliki:
  - Teks pertanyaan
  - 4 pilihan jawaban (semua wajib diisi)
  - Selector jawaban benar (ketuk lingkaran di sebelah pilihan)
  - Penjelasan opsional (explanation) yang ditampilkan di halaman hasil
- Kuis yang baru dibuat langsung muncul di halaman utama untuk semua user.

### 7. Admin — Mengedit Kuis
- Admin dapat mengedit kuis yang sudah ada dengan mengetuk kartu kuis di halaman utama.
- Form edit identik dengan form buat, dan data lama dimuat otomatis dari database.
- Penyimpanan menggunakan strategi delete-then-reinsert untuk pertanyaan, memastikan tidak ada data duplikat.
- Cache kuis di-invalidate setelah penyimpanan sehingga halaman utama selalu menampilkan data terbaru.

---

## C. Dokumentasi Teknis

**Stack:**
- Flutter (Dart) — framework utama
- Supabase — backend (Auth + PostgreSQL)
- Riverpod — state management
- GoRouter — navigasi
- Google Fonts — Silkscreen & Space Mono
- audioplayers — efek suara

**Arsitektur:** Clean Architecture (domain / data / presentation)

**Fonts:**
- Silkscreen (pixel display font) — https://fonts.google.com/specimen/Silkscreen
- Space Mono (password fields) — https://fonts.google.com/specimen/Space+Mono

**Sound Effects:**
- `buttonAnswer.mp3` — "Jvanko_2600" via Pixabay
- `buttonClick.mp3` — "Official Profile" via Pixabay

**Screenshot dan Link Prototype:**
https://drive.google.com/drive/folders/1ngZ1ILzKev_vRC7mL5yz11pKjOpds2jW?usp=sharing

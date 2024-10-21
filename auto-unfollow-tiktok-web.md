# Auto Unfollow Tiktok Web
## V.1.0.0
```
// Fungsi untuk mengklik tombol
function clickFollowButton() {
    // Mencari tombol berdasarkan kelas yang diberikan
    const button = document.querySelector(".e1bph0nm2.css-s6a072-Button-StyledFollowButtonV2.ehk74z00");
    
    // Jika tombol ditemukan, klik tombol tersebut
    if (button) {
        button.click();
        console.log("Tombol diklik!");
    } else {
        console.log("Tombol tidak ditemukan.");
    }
}

// Fungsi untuk scroll ke bawah
function scrollPage() {
    window.scrollBy(0, window.innerHeight); // Scroll ke bawah sejauh tinggi jendela
}

// Fungsi untuk memulai perulangan
function startClicking() {
    // Set interval untuk scroll dan klik tombol setiap 1000 ms
    setInterval(() => {
        scrollPage(); // Scroll halaman
        clickFollowButton(); // Klik tombol
    }, 1000);
}

// Memulai perulangan
startClicking();
```
## V.2.0.0
```
// Fungsi untuk mengklik tombol
function clickFollowButton() {
    // Mencari tombol berdasarkan kelas yang diberikan
    const button = document.querySelector(".e1bph0nm2.css-s6a072-Button-StyledFollowButtonV2.ehk74z00");
    
    // Jika tombol ditemukan, klik tombol tersebut
    if (button) {
        button.click();
        console.log("Tombol diklik!");
        
        // Scroll setelah tombol diklik
        scrollPage();
    } else {
        console.log("Tombol tidak ditemukan.");
    }
}

// Fungsi untuk scroll sedikit
function scrollPage() {
    window.scrollBy(0, 100); // Scroll ke bawah sejauh 100 piksel
}

// Fungsi untuk memulai perulangan
function startClicking() {
    // Set interval untuk klik tombol setiap 1000 ms
    setInterval(clickFollowButton, 1000);
}

// Memulai perulangan
startClicking();
```

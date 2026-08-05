# Panduan Pengembangan Layanan TIK - Backend Terpadu

## Implementasi Fitur Chatbot AI (F-BOT)
Saat mengimplementasikan `ChatbotController` atau logika chatbot lainnya di masa depan, AI agent **WAJIB** mengikuti 4 standar berikut agar jawaban chatbot relevan dan tidak berhalusinasi (halu):

1. **System Prompt Spesifik (Persona):**
   - Sisipkan instruksi sistem ketat di balik layar sebelum pesan user dikirim ke LLM.
   - Contoh: *"Anda adalah asisten virtual resmi untuk Layanan TIK Dinas Provinsi. Jawab HANYA pertanyaan terkait layanan TIK, peminjaman alat, pengajuan email, dan masalah jaringan. Jika di luar topik, tolak menjawab secara halus."*

2. **RAG (Retrieval-Augmented Generation):**
   - JANGAN biarkan AI menebak kebijakan atau ketersediaan barang.
   - Ambil data terlebih dahulu dari database (misal tabel `faq`, `master_item`, `master_topik`) yang relevan dengan pertanyaan user, lalu injeksikan/tambahkan data tersebut sebagai konteks ke dalam prompt ke LLM.

3. **Limitasi Temperature:**
   - Gunakan `temperature` rendah (sekitar `0.1` hingga `0.2`) pada payload request ke API Gemini atau Groq. Ini memaksa AI menjawab secara faktual, deterministik, dan kaku (tidak mengarang bebas).

4. **Batasan Konteks History:**
   - Saat menyertakan riwayat percakapan dari `chatbot_messages` untuk sesi yang sama, ambil maksimal 5 hingga 10 pesan terakhir saja agar LLM tidak kehilangan fokus atau context window berlebih.

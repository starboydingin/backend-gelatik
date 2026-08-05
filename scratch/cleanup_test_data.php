<?php
$pdo = new PDO("mysql:host=127.0.0.1;dbname=db_layanantik;charset=utf8mb4", "root", "", [
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION
]);

$cleanup = [
    "DELETE FROM `users` WHERE username LIKE 'user_test_%' OR username LIKE 'auto_%' OR email LIKE 'test_auto_%'",
    "DELETE FROM `roles` WHERE name LIKE 'role_test_%' OR name LIKE 'test_role_%' OR name LIKE 'auto_role_%'",
    "DELETE FROM `tr_permintaan_pinjam` WHERE nama_pic LIKE 'PIC%' OR nama_pic LIKE 'Test PIC%'",
    "DELETE FROM `pinjam_item` WHERE id >= 78",
    "DELETE FROM `tr_konsultasi` WHERE judul LIKE '%Test%' OR judul LIKE '%Auto%'",
    "DELETE FROM `tr_konsultasi_response` WHERE pesan LIKE '%tes%' OR pesan LIKE '%Tes%'",
    "DELETE FROM `usulan_email` WHERE email_pribadi LIKE 'test_%' OR email_pribadi LIKE 'pribadi_test_%'",
    "DELETE FROM `kritik_sarans` WHERE kritik LIKE '%tes%' OR kritik LIKE 'Kritik%'",
    "DELETE FROM `pengumumans` WHERE judul LIKE '%Test%' OR judul LIKE '%Auto%'",
    "DELETE FROM `ratings` WHERE user_id IN (2, 250)",
    "DELETE FROM `master_item` WHERE nama LIKE '%AutoTest%' OR nama LIKE 'Nama Item%'",
    "DELETE FROM `master_topik` WHERE topik LIKE '%AutoTest%' OR topik LIKE 'Topik Test%'",
    "DELETE FROM `faq` WHERE judul LIKE '%AutoTest%' OR judul LIKE 'Judul FAQ%'",
    "DELETE FROM `sliders` WHERE judul LIKE '%AutoTest%' OR judul LIKE 'Slider%'"
];

foreach ($cleanup as $sql) {
    try {
        $pdo->exec($sql);
    } catch (\Throwable $e) {
        // ignore
    }
}
echo "CLEANUP COMPLETED\n";

<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PegawaiBelumPunyaEmail extends Model
{
    // FR-B06, FR-B07 dari SRS §3
    // Nama tabel PERSIS seperti ini (case-sensitive)
    protected $table = 'PegawaiBelumPunyaEMail';

    // PK berupa varchar, bukan auto-increment
    protected $primaryKey = 'ID_Peg';
    public $incrementing  = false;
    protected $keyType    = 'string';

    // Tidak ada kolom timestamps
    public $timestamps = false;

    // FR-B07: sembunyikan ID_Peg dari response API
    protected $hidden = ['ID_Peg'];

    protected $fillable = [
        'ID_Peg',
        'NIP_Baru',
        'Nama',
        'Unit_Kerja',
        'NJab',
        'NUnKer',
        'EmailUsulan',
        'EmailPribadi',
    ];

    public function usulanEmails()
    {
        return $this->hasMany(UsulanEmail::class, 'id_peg', 'ID_Peg');
    }
}

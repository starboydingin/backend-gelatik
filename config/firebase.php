<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Firebase Credentials
    |--------------------------------------------------------------------------
    |
    | Path ke file service-account.json Firebase Admin SDK.
    | Secara default merujuk ke storage/app/firebase/service-account.json
    |
    */

    'credentials' => [
        'file' => base_path(env('FIREBASE_CREDENTIALS', 'storage/app/firebase/service-account.json')),
    ],

];

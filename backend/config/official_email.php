<?php

$domains = array_values(array_filter(array_map(
    'trim',
    explode(',', (string) env('OFFICIAL_EMAIL_ALLOWED_DOMAINS', '')),
)));

return [
    // Intentionally empty by default: the repository has no authoritative
    // government directory/API or confirmed domain contract. Deployment must
    // supply the officially approved domains; never guess them in source.
    'allowed_domains' => $domains,
];

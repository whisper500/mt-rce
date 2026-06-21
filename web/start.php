<?php
$filename = $_GET['file'] ?? '';
$filepath = '/data/targets/' . basename($filename);
if (!file_exists($filepath)) die("File not found.");

// Buat job
$job_id = uniqid();
$job = [
    'id' => $job_id,
    'status' => 'pending',
    'mode' => 'mass',     // bisa diganti dengan pilihan user
    'target_file' => $filepath,
    'threads' => 5,
    'created_at' => date('c')
];
file_put_contents("/data/jobs/{$job_id}.json", json_encode($job));
header("Location: index.php");
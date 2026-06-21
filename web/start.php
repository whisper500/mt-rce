<?php
$token = getenv('ACCESS_TOKEN') ?: 'rahasia123';
if (!isset($_GET['token']) || $_GET['token'] !== $token) {
    die('Unauthorized');
}
$filename = $_GET['file'] ?? '';
$filepath = '/data/targets/' . basename($filename);
if (!file_exists($filepath)) die("File not found.");

$job_id = uniqid();
$job = [
    'id' => $job_id,
    'status' => 'pending',
    'mode' => 'mass',
    'target_file' => $filepath,
    'threads' => 5,
    'created_at' => date('c')
];
file_put_contents("/data/jobs/{$job_id}.json", json_encode($job));
header("Location: index.php?token=" . urlencode($token));
<?php
header('Content-Type: application/json');
$token = getenv('ACCESS_TOKEN') ?: 'rahasia123';
if (!isset($_GET['token']) || $_GET['token'] !== $token) {
    echo json_encode(['error' => 'Unauthorized']);
    exit;
}
if (!isset($_GET['job_id'])) {
    echo json_encode(['error' => 'job_id required']);
    exit;
}

$job_id = basename($_GET['job_id']);
$job_file = "/data/jobs/{$job_id}.json";
if (!file_exists($job_file)) {
    echo json_encode(['error' => 'Job not found']);
    exit;
}

$job = json_decode(file_get_contents($job_file), true);
$output_dir = "/data/outputs/{$job_id}";

$response = [
    'job_id' => $job_id,
    'status' => $job['status'] ?? 'unknown',
    'progress' => null,
    'total' => null,
    'log_tail' => '',
];

if (is_dir($output_dir)) {
    $progress_file = "$output_dir/sampai-mana.txt";
    if (file_exists($progress_file)) {
        $response['progress'] = (int)file_get_contents($progress_file);
    }
    $targets_file = "$output_dir/targets_clean.txt";
    if (file_exists($targets_file)) {
        $response['total'] = (int)trim(shell_exec("wc -l < " . escapeshellarg($targets_file)));
    } elseif (file_exists("$output_dir/targets.txt")) {
        $response['total'] = (int)trim(shell_exec("wc -l < " . escapeshellarg("$output_dir/targets.txt")));
    }
    $log_file = "$output_dir/log.txt";
    if (file_exists($log_file)) {
        $response['log_tail'] = shell_exec("tail -n 20 " . escapeshellarg($log_file));
    }
}
echo json_encode($response);
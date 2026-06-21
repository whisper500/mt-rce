<?php
$job_id = $_GET['job'] ?? '';
$output_dir = "/data/outputs/" . basename($job_id);
if (!is_dir($output_dir)) die("Output not found.");

echo "<h1>Output for Job $job_id</h1>";

// Tampilkan log
$log_file = "$output_dir/log.txt";
if (file_exists($log_file)) {
    echo "<h2>Log</h2><pre>" . htmlspecialchars(file_get_contents($log_file)) . "</pre>";
}

// Tampilkan CSV
$csv_file = "$output_dir/results.csv";
if (file_exists($csv_file)) {
    echo "<h2>Results CSV</h2><pre>" . htmlspecialchars(file_get_contents($csv_file)) . "</pre>";
}

// Daftar file vulnerable
$vuln_dir = "$output_dir/vulnerable";
if (is_dir($vuln_dir)) {
    echo "<h2>Vulnerable Targets</h2><ul>";
    foreach (glob("$vuln_dir/*.txt") as $file) {
        $name = basename($file);
        echo "<li><a href='view.php?job=$job_id&file=$name'>$name</a></li>";
    }
    echo "</ul>";
}
?>
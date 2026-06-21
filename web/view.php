<?php
$job_id = $_GET['job'] ?? '';
$file = $_GET['file'] ?? '';
$filepath = "/data/outputs/" . basename($job_id) . "/vulnerable/" . basename($file);
if (!file_exists($filepath)) die("File not found.");
echo "<pre>" . htmlspecialchars(file_get_contents($filepath)) . "</pre>";
<?php
$jobId = $_GET['job'] ?? '';
if (!$jobId) die('No job specified');
$outputDir = "/data/outputs/$jobId";
$logFile = "$outputDir/log.txt";
$csvFile = "$outputDir/results.csv";
$vulnDir = "$outputDir/vulnerable";
?>
<!DOCTYPE html>
<html>
<head><title>Output <?= htmlspecialchars($jobId) ?></title></head>
<body>
    <h1>Output for Job <?= htmlspecialchars($jobId) ?></h1>
    <h2>Log</h2>
    <pre><?php if (file_exists($logFile)) echo htmlspecialchars(file_get_contents($logFile)); else echo 'No log yet.'; ?></pre>
    <h2>Results CSV</h2>
    <pre><?php if (file_exists($csvFile)) echo htmlspecialchars(file_get_contents($csvFile)); ?></pre>
    <h2>Vulnerable Details</h2>
    <?php
    if (is_dir($vulnDir)) {
        $files = scandir($vulnDir);
        echo "<ul>";
        foreach ($files as $f) {
            if ($f != '.' && $f != '..') {
                echo "<li><a href='?job=$jobId&file=" . urlencode($f) . "'>$f</a></li>";
            }
        }
        echo "</ul>";
        if (isset($_GET['file'])) {
            $file = basename($_GET['file']);
            $path = "$vulnDir/$file";
            if (file_exists($path)) {
                echo "<pre>" . htmlspecialchars(file_get_contents($path)) . "</pre>";
            }
        }
    }
    ?>
</body>
</html>
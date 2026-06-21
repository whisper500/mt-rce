<?php
// Token keamanan sederhana (ganti dengan env variable)
$token = getenv('ACCESS_TOKEN') ?: 'rahasia123';
if (!isset($_GET['token']) || $_GET['token'] !== $token) {
    die('Unauthorized');
}

$jobs = glob('/data/jobs/*.json') ?: [];
?>
<!DOCTYPE html>
<html>
<head><title>MT-RCE Scanner</title></head>
<body>
<h1>MT-RCE Scanner Jobs</h1>
<?php if (empty($jobs)): ?>
    <p>No jobs yet. <a href="upload.php?token=<?= urlencode($token) ?>">Upload target & start scan</a></p>
<?php else: ?>
    <table border="1">
    <tr><th>Job ID</th><th>Status</th><th>Mode</th><th>Target</th><th>Progress</th><th>Action</th></tr>
    <?php foreach ($jobs as $jobfile): 
        $job = json_decode(file_get_contents($jobfile), true); ?>
    <tr>
        <td><?= htmlspecialchars($job['id']) ?></td>
        <td><?= htmlspecialchars($job['status']) ?></td>
        <td><?= htmlspecialchars($job['mode']) ?></td>
        <td><?= htmlspecialchars(basename($job['target_file'])) ?></td>
        <td>
            <?php
            $progress_file = "/data/outputs/{$job['id']}/sampai-mana.txt";
            $targets_file = "/data/outputs/{$job['id']}/targets_clean.txt";
            if (file_exists($progress_file)) {
                $progress = (int)file_get_contents($progress_file);
                $total = file_exists($targets_file) ? (int)trim(shell_exec("wc -l < ".escapeshellarg($targets_file))) : '?';
                echo "$progress / $total";
            } else { echo '-'; }
            ?>
        </td>
        <td><a href="output.php?job=<?= urlencode($job['id']) ?>&token=<?= urlencode($token) ?>">View Output</a></td>
    </tr>
    <?php endforeach; ?>
    </table>
    <a href="upload.php?token=<?= urlencode($token) ?>">Upload New Target</a>
<?php endif; ?>
</body>
</html>
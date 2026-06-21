<?php
$jobs = glob('/data/jobs/*.json');
?>
<!DOCTYPE html>
<html>
<head><title>MT-RCE Scanner</title></head>
<body>
<h1>MT-RCE Scanner Jobs</h1>
<table border="1">
<tr><th>Job ID</th><th>Status</th><th>Mode</th><th>Target</th><th>Progress</th><th>Action</th></tr>
<?php foreach ($jobs as $jobfile): $job = json_decode(file_get_contents($jobfile), true); ?>
<tr>
    <td><?= $job['id'] ?></td>
    <td><?= $job['status'] ?></td>
    <td><?= $job['mode'] ?></td>
    <td><?= basename($job['target_file']) ?></td>
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
    <td><a href="output.php?job=<?= $job['id'] ?>">View Output</a></td>
</tr>
<?php endforeach; ?>
</table>
<a href="upload.php">Upload New Target & Start Scan</a>
</body>
</html>
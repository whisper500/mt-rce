<?php
$jobs = [];
foreach (glob('/data/jobs/*.json') as $file) {
    $job = json_decode(file_get_contents($file), true);
    $jobs[] = $job;
}
?>
<!DOCTYPE html>
<html>
<head>
    <title>MT-RCE Scanner</title>
    <style>
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        .vuln { color: green; }
        .running { color: orange; }
    </style>
</head>
<body>
    <h1>MT-RCE Mass Scanner</h1>
    <a href="upload.php">Upload Target File</a> | 
    <a href="start.php">New Scan</a>
    <h2>Jobs</h2>
    <table>
        <tr>
            <th>ID</th>
            <th>Status</th>
            <th>Mode</th>
            <th>Target</th>
            <th>Progress</th>
            <th>Action</th>
        </tr>
        <?php foreach ($jobs as $job): ?>
        <tr>
            <td><?= htmlspecialchars($job['id']) ?></td>
            <td class="<?= $job['status'] ?>"><?= htmlspecialchars($job['status']) ?></td>
            <td><?= htmlspecialchars($job['mode']) ?></td>
            <td><?= htmlspecialchars(basename($job['target_file'])) ?></td>
            <td>
                <?php 
                $progressFile = "/data/outputs/{$job['id']}/sampai-mana.txt";
                if (file_exists($progressFile)) {
                    echo file_get_contents($progressFile);
                } else {
                    echo '0';
                }
                ?>
            </td>
            <td>
                <a href="output.php?job=<?= $job['id'] ?>">View Output</a>
            </td>
        </tr>
        <?php endforeach; ?>
    </table>
</body>
</html>
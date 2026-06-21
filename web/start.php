<?php
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $mode = $_POST['mode'];
    $targetFile = '/data/targets/' . basename($_POST['target_file']);
    $threads = intval($_POST['threads'] ?? 5);
    $jobId = uniqid();
    $job = [
        'id' => $jobId,
        'status' => 'pending',
        'mode' => $mode,
        'target_file' => $targetFile,
        'threads' => $threads,
        'created_at' => date('c')
    ];
    $jobsDir = '/data/jobs/';
    if (!is_dir($jobsDir)) mkdir($jobsDir, 0777, true);
    file_put_contents("$jobsDir/$jobId.json", json_encode($job));
    header('Location: index.php');
    exit;
}
$targets = glob('/data/targets/*.txt');
?>
<!DOCTYPE html>
<html>
<head><title>Start Scan</title></head>
<body>
    <h1>Start New Scan</h1>
    <form method="post">
        <label>Target File:</label>
        <select name="target_file" required>
            <?php foreach ($targets as $t): ?>
                <option value="<?= basename($t) ?>"><?= basename($t) ?></option>
            <?php endforeach; ?>
        </select><br>
        <label>Mode:</label>
        <select name="mode">
            <option value="mass">Mass Scan (single file)</option>
            <option value="batch">Batch Scan (folder domains)</option>
        </select><br>
        <label>Threads:</label>
        <input type="number" name="threads" value="5" min="1" max="20"><br>
        <button type="submit">Start Scan</button>
    </form>
</body>
</html>
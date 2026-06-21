<?php
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_FILES['target_file'])) {
    $targetDir = '/data/targets/';
    if (!is_dir($targetDir)) mkdir($targetDir, 0777, true);
    $filename = basename($_FILES['target_file']['name']);
    $dest = $targetDir . $filename;
    move_uploaded_file($_FILES['target_file']['tmp_name'], $dest);
    header('Location: index.php');
    exit;
}
?>
<!DOCTYPE html>
<html>
<head><title>Upload Target</title></head>
<body>
    <h1>Upload Target File</h1>
    <form method="post" enctype="multipart/form-data">
        <input type="file" name="target_file" required>
        <button type="submit">Upload</button>
    </form>
</body>
</html>
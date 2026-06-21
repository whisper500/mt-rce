<?php
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_FILES['target_file'])) {
    $target_dir = '/data/targets/';
    if (!is_dir($target_dir)) mkdir($target_dir, 0777, true);
    $filename = basename($_FILES['target_file']['name']);
    move_uploaded_file($_FILES['target_file']['tmp_name'], $target_dir . $filename);
    header('Location: start.php?file=' . urlencode($filename));
    exit;
}
?>
<h1>Upload Target File</h1>
<form method="post" enctype="multipart/form-data">
    <input type="file" name="target_file" accept=".txt"><br><br>
    <button type="submit">Upload</button>
</form>
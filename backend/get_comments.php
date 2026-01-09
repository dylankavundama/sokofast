<?php
require_once 'db_connection.php';
$product_id = $_GET['product_id'];
$result = $conn->query("SELECT * FROM comments WHERE product_id = $product_id ORDER BY created_at DESC");
$comments = [];
while ($row = $result->fetch_assoc()) {
    $comments[] = $row;
}
echo json_encode($comments);
?>

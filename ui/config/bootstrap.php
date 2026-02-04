<?php
// ui/config/bootstrap.php
// Shared DB bootstrap for all pages. Provides:
//  - $pdo  (PDO connection)
//  - h()   (HTML escaping helper)

$config = require __DIR__ . "/db.php";

$dsn = sprintf(
  "mysql:host=%s;port=%d;dbname=%s;charset=%s",
  $config["db_host"],
  (int)$config["db_port"],
  $config["db_name"],
  $config["charset"]
);

try {
  $pdo = new PDO($dsn, $config["db_user"], $config["db_pass"], [
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
  ]);
} catch (Throwable $e) {
  http_response_code(500);
  echo "<h2>DB connection failed</h2>";
  echo "<pre>" . htmlspecialchars($e->getMessage()) . "</pre>";
  exit;
}
$pdo->exec("SET NAMES utf8mb4 COLLATE utf8mb4_0900_ai_ci");

function h($s): string {
  return htmlspecialchars((string)$s, ENT_QUOTES | ENT_SUBSTITUTE, "UTF-8");
}

/**
 * Display helper: show "NA" for empty/null/"." values, otherwise HTML-escape.
 */
function na($v, string $fallback = "NA"): string {
  $v = trim((string)($v ?? ""));
  if ($v === "" || $v === "." || strtoupper($v) === "NA") {
    return $fallback;
  }
  return h($v);
}

require_once __DIR__ . "/../download_helpers.php";

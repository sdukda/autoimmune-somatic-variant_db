<?php
// ui/config/download_helpers.php

/**
 * Stream an array of associative arrays as CSV and exit.
 *
 * @param array  $rows      Array of associative arrays (PDO::FETCH_ASSOC).
 * @param array  $cols      Column keys to export (order matters).
 * @param string $filename  Filename without extension (".csv" added).
 */
function download_csv_and_exit(array $rows, array $cols, string $filename = "export"): void
{
  // IMPORTANT: nothing should have been output before this function is called.
  if (headers_sent()) {
    // Fail safely: don't output broken CSV into an HTML page
    http_response_code(500);
    echo "Error: headers already sent; download must run before HTML output.";
    exit;
  }

  $safe = preg_replace('/[^A-Za-z0-9._-]+/', '_', $filename);
  if ($safe === "" || $safe === "_") $safe = "export";

  header("Content-Type: text/csv; charset=utf-8");
  header('Content-Disposition: attachment; filename="' . $safe . '.csv"');

  $out = fopen("php://output", "w");

  // PHP 8.4+ warning prevention: always pass escape param explicitly
  $escape = "\\";

  // Header row
  fputcsv($out, $cols, ",", '"', $escape);

  foreach ($rows as $r) {
    $line = [];
    foreach ($cols as $c) {
      $line[] = (string)($r[$c] ?? "");
    }
    fputcsv($out, $line, ",", '"', $escape);
  }

  fclose($out);
  exit;
}

/**
 * True if request asks for CSV download.
 */
function wants_csv_download(): bool
{
  return strtolower(trim((string)($_GET["download"] ?? ""))) === "csv";
}

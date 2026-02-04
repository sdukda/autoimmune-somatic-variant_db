<?php
// ui/public/partials/header.php
// Expects: $pageTitle (string)
?>
<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title><?= h($pageTitle ?? "Autoimmune Somatic Variants Portal") ?></title>
  <link rel="stylesheet" href="/assets/style.css">
</head>
<body>
<header class="site-header">
  <div class="container header-row">
    <div class="brand">
      <img src="/assets/images/ctbmb_logo_col.jpg" alt="" class="brand-logo">
      <div>
        <div class="brand-title">Autoimmune Somatic Variants Portal</div>
        <div class="brand-subtitle">Literature-derived driver variants &amp; evidence</div>
      </div>
    </div>

  <nav class="nav">
  <a href="/">Home</a>
  <a href="/gene_v2.php">Gene</a>
  <a href="/disease_v2.php">Disease</a>
  <a href="/study_v2.php">Study</a>
  <a href="/variants_v2.php">Variants</a>
</nav>
  </div>
</header>
  <main class="container">

<?php
require __DIR__ . "/../config/bootstrap.php";

$pageTitle = "Autoimmune_DB UI";
require __DIR__ . "/partials/header.php";

// quick stats
$stats = [
  "studies"  => 0,
  "variants" => 0,
  "genes"    => 0,
  "diseases" => 0,
];

try {
  $stats["studies"]  = (int)($pdo->query("SELECT COUNT(*) c FROM study")->fetch()["c"] ?? 0);
  $stats["variants"] = (int)($pdo->query("SELECT COUNT(*) c FROM literature_driver_variants")->fetch()["c"] ?? 0);
  $stats["genes"]    = (int)($pdo->query("SELECT COUNT(DISTINCT gene_symbol) c FROM literature_driver_variants")->fetch()["c"] ?? 0);
  $stats["diseases"] = (int)($pdo->query("SELECT COUNT(*) c FROM disease")->fetch()["c"] ?? 0);
} catch (Throwable $e) {
  // keep zeros; page still renders
}
?>

<div class="card">
  <h2>Welcome</h2>
  <p class="small">
    This interface is for quickly browsing literature-derived variants by <b>gene</b>, <b>disease</b>, and <b>study</b>.
  </p>

  <div class="grid">
    <div class="col-6">
      <div class="card">
        <h3>Quick stats</h3>
        
    <table class="quick-stats-table">
 <tr>
    <th><a href="/study_v2.php">Studies</a></th>
    <td><a href="/study_v2.php"><?=(int)$stats["studies"] ?></a></td>
  </tr>
  <tr>
    <th><a href="/variants_v2.php">Variants</a></th>
    <td><a href="/variants_v2.php"><?= (int)$stats["variants"] ?></a></td>
  </tr>
  <tr>
    <th><a href="/gene_v2.php">Genes</a></th>
    <td><a href="/gene_v2.php"><?= (int)$stats["genes"] ?></a></td>
  </tr>
  <tr>
    <th><a href="/disease_v2.php">Diseases</a></th>
    <td><a href="/disease_v2.php"><?= (int)$stats["diseases"] ?></a></td>
  </tr>
</table>

      </div>
    </div>

    <div class="col-6">
      <div class="card start-here-card">
        <h3>Start here</h3>

        <form class="start-here-form" method="get" action="/gene_v2.php">
  <label><b>Search Gene</b></label><br>
  <span class="small">e.g. DNMT3A, TET2, STAT3</span>
  <br><br>
  <input type="text" name="q" placeholder="Enter gene symbol…" />
  <br><br>
  <button type="submit">Search</button>
</form>

<form class="start-here-form" method="get" action="/disease_v2.php" style="margin-top:10px;">
  <label><b>Search Disease</b></label><br>
  <span class="small">e.g. Ulcerative colitis, DOID:0050146</span>
  <br><br>
  <input type="text" name="q" placeholder="Enter disease name or DOID…" />
  <br><br>
  <button type="submit">Search</button>
</form>

<form class="start-here-form" method="get" action="/study_v2.php" style="margin-top:10px;">
  <label><b>Search Study</b></label><br>
  <span class="small">e.g. PMID, author, year</span>
  <br><br>
  <input type="text" name="q" placeholder="Enter PMID or keyword…" />
  <br><br>
  <button type="submit">Search</button>
</form>

<form class="start-here-form" method="get" action="/variants_v2.php" style="margin-top:10px;">
  <label><b>Search Variant</b></label><br>
  <span class="small">e.g. chr17:7675236 C&gt;G, STAT3 p.Y640F</span>
  <br><br>
  <input type="text" name="q" placeholder="Enter variant / gene / HGVS…" />
  <br><br>
  <button type="submit">Search</button>
</form>


        <div class="small">
          Tip: browse <a href="/gene_v2.php">all genes</a>, <a href="/disease_v2.php">all diseases</a>, <a href="/study_v2.php">all studies</a>, or <a href="/variants_v2.php">all variants</a>.
        </div>
      </div>
    </div>
  </div>
</div>

<?php require __DIR__ . "/partials/footer.php"; ?>

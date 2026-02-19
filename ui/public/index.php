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

<div class="home-hero">
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

<form id="smartSearchForm" class="ncbi-search" method="get">
  <select id="smartSearchType" class="ncbi-search__select">
    <option value="all" selected>All</option>
    <option value="gene">Gene</option>
    <option value="disease">Disease</option>
    <option value="study">Study</option>
    <option value="variant">Variant</option>
  </select>

  <input id="smartSearchInput"
         name="q"
         class="ncbi-search__input"
         type="text"
         >

  <button class="ncbi-search__btn" type="submit">Search</button>
</form>
  <div class="small muted" style="margin-top:8px;">
    Examples: gene (DNMT3A), disease (Ulcerative colitis), study (PMID), variant (chr17:44245096 T>A)
  </div>
</div>

        
          
        
      </div>
    </div>
  </div>
</div>

<script>
(function(){
  const form  = document.getElementById('smartSearchForm');
  const type  = document.getElementById('smartSearchType');
  const input = document.getElementById('smartSearchInput');

  if (!form || !type || !input) return;

  const routes = {
    all: "/variants_v2.php",   // global search target
    gene: "/gene_v2.php",
    disease: "/disease_v2.php",
    study: "/study_v2.php",
    variant: "/variants_v2.php"
  };

  const placeholders = {
    all: "",
    gene: "Search gene (e.g. DNMT3A, TET2, STAT3)",
    disease: "Search disease (e.g. Ulcerative colitis, DOID:0050146)",
    study: "Search study (e.g. PMID, author, year)",
    variant: "Search variant (e.g. chr17:7675236 C>G, STAT3 p.Y640F)"
  };

  // Update placeholder when dropdown changes
  function updatePlaceholder(){
    input.placeholder = placeholders[type.value] || "";
  }
  type.addEventListener('change', updatePlaceholder);
  updatePlaceholder();

  // Route to the right page on submit
  form.addEventListener('submit', function(e){
    const t = type.value;
    form.action = routes[t] || "/";

    // Optional: stop empty searches
    if (!input.value.trim()) {
      e.preventDefault();
      input.focus();
    }
  });
})();
</script>
<?php require __DIR__ . "/partials/footer.php"; ?>

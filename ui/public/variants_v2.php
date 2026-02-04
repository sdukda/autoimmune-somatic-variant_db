<?php
// ui/public/variants_v2.php

require __DIR__ . "/../config/bootstrap.php";      // provides $pdo + h()
require_once __DIR__ . "/../download_helpers.php"; // wants_csv_download(), download_csv_and_exit()

// UCSC URL from a genomic_variant string like:
//  - chr12:8857315 C>T
//  - chr11:103362219_117295916
//  - chr11:103362219-117295916
if (!function_exists('ucsc_url_from_genomic_variant')) {
  function ucsc_url_from_genomic_variant(string $refGenome, string $genomicVariant): ?string
  {
    $gv = trim((string)$genomicVariant);
    if ($gv === '') return null;

    // Parse chr:start[_-]end (underscore OR dash). Allow extra trailing text.
    if (!preg_match('/\b(chr[0-9XYM]+)\s*:\s*([0-9]+)(?:\s*[_-]\s*([0-9]+))?/i', $gv, $m)) {
      return null;
    }

    $chrom = $m[1];
    $start = (int)$m[2];
    $end   = (isset($m[3]) && $m[3] !== '') ? (int)$m[3] : $start;

    // Swap if reversed
    if ($end < $start) { $tmp = $start; $start = $end; $end = $tmp; }

    // Map your ref genome -> UCSC db
    $rg = strtoupper(trim($refGenome));
    $rg = str_replace([' ', "\t"], '', $rg);

    $db = null;
    if ($rg === 'GRCH38' || $rg === 'HG38') $db = 'hg38';
    if ($rg === 'GRCH37' || $rg === 'HG19') $db = 'hg19';
    if (!$db) return null;

    // UCSC expects start-end
    $pos = $chrom . ':' . $start . '-' . $end;

    return 'https://genome.ucsc.edu/cgi-bin/hgTracks?db=' . rawurlencode($db)
         . '&position=' . rawurlencode($pos);
  }
}


// Optional: uncomment during debugging
// error_reporting(E_ALL);
// ini_set('display_errors', '1');

if (!function_exists("na")) {
  function na($v, string $fallback = "NA"): string {
    $v = trim((string)($v ?? ""));
    if ($v === "" || $v === "." || strtoupper($v) === "NA") return $fallback;
    return h($v);
  }
}

/**
 * Build UCSC URL from a genomic variant string + ref genome.
 * Supports: chr12:49022121 G>T, chr2:25275709-25275721 ..., chr1:1387310 G>A
 */
function ucsc_url_from_genomic_variant(string $refGenome, string $genomicVariant): ?string
{
  $gv = trim($genomicVariant);
  if ($gv === '') return null;

  // parse "chrX:START" or "chrX:START-END"
  if (!preg_match('/^(chr[0-9XYM]+):([0-9]+)(?:-([0-9]+))?/i', $gv, $m)) {
    return null;
  }

  $chrom = $m[1];
  $start = $m[2];
  $end   = $m[3] ?? $start;

  $rg = strtoupper(trim($refGenome));
  $db = null;
  if ($rg === 'GRCH38' || $rg === 'HG38') $db = 'hg38';
  if ($rg === 'GRCH37' || $rg === 'HG19') $db = 'hg19';
  if (!$db) return null;

  $pos = $chrom . ':' . $start . '-' . $end;

  return 'https://genome.ucsc.edu/cgi-bin/hgTracks?db=' . rawurlencode($db)
       . '&position=' . rawurlencode($pos);
}

// --------------------
// Inputs
// --------------------
$q = trim((string)($_GET["q"] ?? ""));
$consequenceFilter = trim((string)($_GET["consequence"] ?? ""));

// ----------------------------
// Sorting
// ----------------------------
$allowedSorts = ['gene_symbol','ref_genome','genomic_variant','consequence','n_reports','n_studies'];
$sort = (string)($_GET['sort'] ?? 'gene_symbol');
$dir  = strtolower((string)($_GET['dir'] ?? 'asc'));
if (!in_array($sort, $allowedSorts, true)) $sort = 'gene_symbol';
$dirSql = ($dir === 'desc') ? 'DESC' : 'ASC';

$sortSqlMap = [
  'gene_symbol'     => 's.gene_symbol',
  'ref_genome'      => 's.ref_genome',
  'genomic_variant' => 's.genomic_variant',
  'consequence'     => 'COALESCE(s.consequence, \'Unknown\')',
  'n_reports'       => 's.n_reports',
  'n_studies'       => 's.n_studies'
];

$orderBy = $sortSqlMap[$sort] . " " . $dirSql . ", s.gene_symbol ASC, s.genomic_variant ASC";

function variants_sort_link($label, $key, $q, $consequence, $sort, $dir) {
  $currentDir = strtolower($dir);
  $nextDir = 'asc';
  if ($sort === $key && $currentDir === 'asc') $nextDir = 'desc';

  $href = 'variants_v2.php?' . http_build_query([
    'q' => $q,
    'consequence' => $consequence,
    'sort' => $key,
    'dir' => $nextDir
  ]);

 // Always show ▲▼, highlight active direction
  if ($sort === $key) {
    $arrow = ($currentDir === 'asc')
      ? ' <span class="sort-arrow active">&#9650;</span><span class="sort-arrow inactive">&#9660;</span>'
      : ' <span class="sort-arrow inactive">&#9650;</span><span class="sort-arrow active">&#9660;</span>';
  } else {
    $arrow = ' <span class="sort-arrow inactive">&#9650;</span><span class="sort-arrow inactive">&#9660;</span>';
  }

  return '<a href="' . h($href) . '">' . h($label) . $arrow . '</a>';
}

// --------------------
// Consequence dropdown options
// --------------------
$consequenceOptions = [];
try {
  $consequenceOptions = $pdo->query("
    SELECT DISTINCT COALESCE(consequence, 'Unknown') AS consequence
    FROM v_literature_variants_flat
    ORDER BY consequence
  ")->fetchAll();
} catch (Throwable $e) {
  $consequenceOptions = [];
}

// --------------------
// Main query (simple + stable)
// --------------------
$rows = [];
$sqlError = "";

try {
  $stmt = $pdo->prepare("
    SELECT
      s.gene_symbol,
      s.ref_genome,
      s.genomic_variant,
      COALESCE(s.consequence, 'Unknown') AS consequence,
      s.n_reports,
      s.n_studies,
      s.studies
    FROM v_literature_summary_by_variant_coords s
    WHERE 1=1
      AND (:consequence = '' OR COALESCE(s.consequence, 'Unknown') = :consequence)
      AND (
        :q = ''
        OR s.gene_symbol LIKE :q_like
        OR s.genomic_variant LIKE :q_like
        OR s.studies LIKE :q_like
      )
    ORDER BY $orderBy
    LIMIT 2000
  ");

  $stmt->execute([
    ":q" => $q,
    ":q_like" => "%" . $q . "%",
    ":consequence" => $consequenceFilter,
  ]);

  $rows = $stmt->fetchAll();

} catch (Throwable $e) {
  $rows = [];
  $sqlError = $e->getMessage();
}

// -----------------------------
// Download CSV (before HTML)
// -----------------------------
if (wants_csv_download()) {
  $cols = ["gene_symbol","ref_genome","genomic_variant","consequence","n_reports","n_studies","studies"];
  download_csv_and_exit($rows, $cols, "variants_" . date("Ymd_His"));
}

// --------------------
// Output HTML
// --------------------
$pageTitle = "Variants";
require __DIR__ . "/partials/header.php";
?>

<div class="card">
  <h2>Variants</h2>

  <div class="card">
    <h3>Search &amp; filter</h3>

    <form method="get" action="/variants_v2.php" class="form-row">
      <label for="q"><b>Search</b></label><br>
      <input id="q" name="q" type="text" value="<?= h($q) ?>"
        laceholder="gene / disease / study / HGVS / chr:pos..." style="min-width:340px;" />
      &nbsp;&nbsp;

      <label for="consequence"><b>Consequence</b></label><br>
      <select id="consequence" name="consequence">
        <option value="" <?= ($consequenceFilter === "" ? "selected" : "") ?>>All</option>
        <?php foreach ($consequenceOptions as $opt): ?>
          <?php $c = (string)($opt["consequence"] ?? "Unknown"); ?>
          <option value="<?= h($c) ?>" <?= ($consequenceFilter === $c ? "selected" : "") ?>>
            <?= h($c) ?>
          </option>
        <?php endforeach; ?>
      </select>

      &nbsp;&nbsp;
<br><br>
      <button type="submit">Search</button>
      <button type="submit" name="download" value="csv">Download</button>
<a class="btn" href="/variants_v2.php">Clear</a>
      <p class="small">
        Tip: Click the genomic variant to open the detail page and then click to open UCSC at that coordinate.
      </p>
    </form>


    <?php if ($sqlError): ?>
      <div class="small" style="color:#b00020;">
        SQL error: <?= h($sqlError) ?>
      </div>
    <?php endif; ?>
  </div>
</div>
  <div class="card">
    <h3>Browse all variants</h3>
    <div class="small">Showing <?= count($rows) ?> rows (limit 2000).</div>

    <?php if (!$rows): ?>
      <p class="small">No variants found.</p>
    <?php else: ?>
      <table class="browse-variants-table">
        <tr>
          <th class="col-gene"><?= variants_sort_link('Gene','gene_symbol',$q,$consequenceFilter,$sort,$dir) ?></th>
          <th><?= variants_sort_link('Reference genome','ref_genome',$q,$consequenceFilter,$sort,$dir) ?></th>
          <th title="Click variant opens detail page; 🔗 opens UCSC">
            <?= variants_sort_link('Genomic variant','genomic_variant',$q,$consequenceFilter,$sort,$dir) ?>
          </th>
          <th><?= variants_sort_link('Consequence','consequence',$q,$consequenceFilter,$sort,$dir) ?></th>
          <th><?= variants_sort_link('Reports','n_reports',$q,$consequenceFilter,$sort,$dir) ?></th>
          <th><?= variants_sort_link('Studies','n_studies',$q,$consequenceFilter,$sort,$dir) ?></th>
          <th>Studies</th>
        </tr>

        <?php foreach ($rows as $r): ?>
          <?php
            $gv   = (string)($r["genomic_variant"] ?? "");
            $ucsc = ucsc_url_from_genomic_variant((string)($r["ref_genome"] ?? ""), $gv);
          ?>
          <tr>
            <td class="col-gene">
              <a href="/gene_v2.php?q=<?= urlencode((string)($r["gene_symbol"] ?? "")) ?>">
                <?= na($r["gene_symbol"] ?? null) ?>
              </a>
            </td>

            <td><?= na($r["ref_genome"] ?? null) ?></td>

<td class="small">
  <?php if ($gv !== ""): ?>
    <a href="/variant_v2.php?variant=<?= urlencode($gv) ?>">
      <?= h($gv) ?>
    </a>
  <?php else: ?>
    NA
  <?php endif; ?>
</td>
            <td><?= na($r["consequence"] ?? null, "Unknown") ?></td>
            <td><?= (int)($r["n_reports"] ?? 0) ?></td>
            <td><?= (int)($r["n_studies"] ?? 0) ?></td>
            <td class="small"><?= na($r["studies"] ?? null) ?></td>
          </tr>
        <?php endforeach; ?>
      </table>
    <?php endif; ?>
  </div>
</div>

<?php require __DIR__ . "/partials/footer.php"; ?>

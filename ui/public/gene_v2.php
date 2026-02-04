<?php
// ui/public/gene_v2.php
require __DIR__ . "/../config/bootstrap.php"; // provides $pdo, h(), na(), wants_csv_download(), download_csv_and_exit()
require_once __DIR__ . "/../download_helpers.php"; // wants_csv_download(), download_csv_and_exit()

// $pageTitle = "Gene";
// require __DIR__ . "/partials/header.php";
// --------------------
// Inputs
// --------------------
$q    = trim((string)($_GET["q"] ?? ""));
// ----------------------------
// Sorting (for browse table)
// ----------------------------
$allowedSorts = [
  'gene_symbol',
  'n_unique_variants',
  'n_studies',
  'n_diseases'
];

$sort = $_GET['sort'] ?? 'gene_symbol';
$dir  = strtolower($_GET['dir'] ?? 'asc');

if (!in_array($sort, $allowedSorts, true)) {
  $sort = 'gene_symbol';
}

$dir = ($dir === 'desc') ? 'DESC' : 'ASC';
$gene = strtoupper($q);

// Helper to build clickable header links (with optional tooltip)
// Helper to build clickable header links
function gene_sort_link($label, $key, $q, $sort, $dir) {
  $currentDir = (strtolower($dir) === 'desc') ? 'desc' : 'asc';
  $nextDir    = 'asc';

  if ($sort === $key && $currentDir === 'asc') {
    $nextDir = 'desc';
  }

  $href = 'gene_v2.php?' . http_build_query([
    'q'    => $q,
    'sort' => $key,
    'dir'  => $nextDir
  ]);

  // Always show both arrows
  if ($sort === $key) {
    $arrow = ($currentDir === 'asc')
      ? '<span class="sort-active">▲</span><span class="sort-inactive">▼</span>'
      : '<span class="sort-inactive">▲</span><span class="sort-active">▼</span>';
  } else {
    $arrow = '<span class="sort-inactive">▲</span><span class="sort-inactive">▼</span>';
  }

  return '<a class="sort-link" href="' . h($href) . '"><span class="sort-label">' . h($label) . '</span> ' . $arrow . '</a>';
}
// --------------------
// Data
// --------------------

// If no query, show list of genes (from summary view)
$geneList = [];
$rows = [];

if ($gene === "") {
    $geneList = $pdo->query("
      SELECT gene_symbol, n_unique_variants, n_studies, n_diseases
      FROM v_literature_summary_by_gene
      ORDER BY $sort $dir, gene_symbol ASC
      LIMIT 500
    ")->fetchAll();
} else {
  try {
    $stmt = $pdo->prepare("
      SELECT
        literature_variant_id,
        study_id, study_name, study_name_short,
        gene_symbol,
        cDNA_HGVS, protein_change,
        variant_type,
        consequence,
        consequence_detail,

        CONCAT_WS('',
          COALESCE(lifted_chrom, paper_chrom), ':',
          COALESCE(lifted_pos,   paper_pos),  ' ',
          COALESCE(lifted_ref,   paper_ref),  '>',
          COALESCE(lifted_alt,   paper_alt)
        ) AS genomic_variant,

        is_driver,
        disease_id, disease_name, disease_category, disease_ontology_id,
        cell_type_name, cell_type_ontology_id,
        evidence_type,
        paper_ref_genome, paper_chrom, paper_pos, paper_ref, paper_alt,
        lifted_ref_genome, lifted_chrom, lifted_pos, lifted_ref, lifted_alt
      FROM v_literature_variants_flat
      WHERE gene_symbol = :gene
      ORDER BY disease_name, study_id, literature_variant_id
      LIMIT 2000
    ");
    $stmt->execute([":gene" => $gene]);
    $rows = $stmt->fetchAll();
  } catch (Throwable $e) {
    $rows = [];
  }
}

// --------------------
// Download (CSV) - MUST happen before any HTML output
// --------------------
if ($gene !== "" && wants_csv_download()) {
  $cols = [
    "literature_variant_id",
    "gene_symbol",
    "cDNA_HGVS",
    "protein_change",
    "variant_type",
    "consequence",
    "consequence_detail",
    "genomic_variant",
    "is_driver",
    "disease_name",
    "disease_category",
    "disease_ontology_id",
    "cell_type_name",
    "cell_type_ontology_id",
    "study_name_short",
    "study_name",
    "evidence_type",
    "paper_ref_genome", "paper_chrom", "paper_pos", "paper_ref", "paper_alt",
    "lifted_ref_genome", "lifted_chrom", "lifted_pos", "lifted_ref", "lifted_alt"
  ];

  download_csv_and_exit($rows, $cols, "gene_" . $gene . "_" . date("Ymd_His"));
}

// --------------------
// Render page
// --------------------
$pageTitle = "Gene";
require __DIR__ . "/partials/header.php";
?>

<div class="card gene-page-card">
  <h2>Gene</h2>

<form method="get" action="/gene_v2.php" class="form-row">

  <label for="q"><b>Gene symbol</b> (e.g., DNMT3A, TET2, STAT3)</label><br>

  <input id="q" name="q" type="text" value="<?= h($q) ?>" placeholder="Enter gene symbol..." />
<br><br>
  <button type="submit">Search</button>

  <!-- Download: only works when a gene is searched -->
  <button type="submit" name="download" value="csv" <?= ($gene === "" ? "disabled" : "") ?>>Download</button>

  <a href="/gene_v2.php" class="btn">Clear</a>
</form>

  <p class="small">
    Tip: search by <b>gene symbol</b> (e.g., DNMT3A, TET2, STAT3). Click a gene to view its variants.
  </p>
</div>

<?php if ($gene === ""): ?>

  <div class="card gene-page-section">
    <h3>Browse all genes</h3>

    <?php if (!$geneList): ?>
      <div class="small">No genes found in v_literature_summary_by_gene.</div>
    <?php else: ?>
      <table class="browse-genes-table">
        <tr>
        <th><?= gene_sort_link('Gene', 'gene_symbol', $q, $sort, $dir) ?></th>
        <th><?= gene_sort_link('Variants', 'n_unique_variants', $q, $sort, $dir) ?></th>
        <th><?= gene_sort_link('Studies', 'n_studies', $q, $sort, $dir) ?></th>
        <th><?= gene_sort_link('Diseases', 'n_diseases', $q, $sort, $dir) ?></th>
        </tr>

        <?php foreach ($geneList as $g): ?>
          <tr>
            <td>
              <a href="/gene_v2.php?q=<?= urlencode($g["gene_symbol"]) ?>">
                <?= h($g["gene_symbol"]) ?>
              </a>
            </td>
            <td><?= (int)$g["n_unique_variants"] ?></td>
            <td><?= (int)$g["n_studies"] ?></td>
            <td><?= (int)$g["n_diseases"] ?></td>
          </tr>
        <?php endforeach; ?>
      </table>
    <?php endif; ?>
  </div>

<?php else: ?>

  <div class="card">
    <h3>Results for gene: <?= h($gene) ?></h3>

    <?php if (!$rows): ?>
      <p>No variants found for this gene.</p>
    <?php else: ?>
      <div class="small">
        Showing <?= count($rows) ?> rows (limit 2000).
      </div>
<div class="table-wrap">
      <table>
        <tr>
          <th>cDNA (HGVS)</th>
          <th>Protein</th>
          <th>Variant</th>
          <th title="Mutation class based on REF/ALT length (SNV / Insertion / Deletion / Indel)">
            Variant type
          </th>
          <th title="Functional/biological category (Missense / Nonsense / Frameshift / Splice / Intron / etc.)">
            Consequence
          </th>
          <th>Disease</th>
          <th>Category</th>
          <th>DOID</th>
          <th>Cell type</th>
          <th>CL ID</th>
          <th>Study</th>
        </tr>

        <?php foreach ($rows as $r): ?>
          <tr>
            <!-- cDNA (HGVS): show NA if missing; only link if variant_id exists AND HGVS not missing -->
            <td class="small">
              <?php
                $hgvs_raw = trim((string)($r["cDNA_HGVS"] ?? ""));
                $hgvs_missing = ($hgvs_raw === "" || $hgvs_raw === ".");
              ?>
              <?php if (!empty($r["literature_variant_id"]) && !$hgvs_missing): ?>
                <a href="/variant_v2.php?id=<?= (int)$r["literature_variant_id"] ?>">
                  <?= na($r["cDNA_HGVS"] ?? null) ?>
                </a>
              <?php else: ?>
                <?= na($r["cDNA_HGVS"] ?? null) ?>
              <?php endif; ?>
            </td>

            <td class="small"><?= na($r["protein_change"] ?? null) ?></td>

            <!-- Variant (genomic) -->
            <td class="small">
              <?php if (!empty($r["genomic_variant"])): ?>
                <a href="/variant_v2.php?variant=<?= urlencode($r["genomic_variant"]) ?>">
                  <?= h($r["genomic_variant"]) ?>
                </a>
              <?php else: ?>
                NA
              <?php endif; ?>
            </td>

            <!-- Variant type -->
            <td><?= na($r["variant_type"] ?? null) ?></td>

            <td><?= na($r["consequence"] ?? null) ?></td>

            <td>
              <?php if (!empty($r["disease_id"])): ?>
                <a href="/disease_v2.php?id=<?= (int)$r["disease_id"] ?>">
                  <?= h($r["disease_name"] ?? "") ?>
                </a>
              <?php else: ?>
                <?= na($r["disease_name"] ?? null) ?>
              <?php endif; ?>
            </td>

            <td><?= na($r["disease_category"] ?? null) ?></td>

            <!-- DOID clickable -->
            <td class="small">
              <?php $doid = trim((string)($r["disease_ontology_id"] ?? "")); ?>
              <?php if ($doid === "" || $doid === "."): ?>
                NA
              <?php else: ?>
                <a target="_blank" rel="noopener"
                   href="https://disease-ontology.org/?id=<?= urlencode($doid) ?>">
                  <?= h($doid) ?>
                </a>
              <?php endif; ?>
            </td>

            <td><?= na($r["cell_type_name"] ?? null) ?></td>

            <!-- CL ID clickable -->
            <td class="small">
              <?php $clid = trim((string)($r["cell_type_ontology_id"] ?? "")); ?>
              <?php if ($clid === "" || $clid === "."): ?>
                NA
              <?php else: ?>
                <a target="_blank" rel="noopener"
                   href="https://www.ebi.ac.uk/ols/ontologies/cl/terms?obo_id=<?= urlencode($clid) ?>">
                  <?= h($clid) ?>
                </a>
              <?php endif; ?>
            </td>

            <td>
              <?php if (!empty($r["study_id"])): ?>
                <a href="/study_v2.php?id=<?= (int)$r["study_id"] ?>">
                  <?= h($r["study_name_short"] ?? $r["study_name"] ?? ("Study " . (int)$r["study_id"])) ?>
                </a>
              <?php else: ?>
                <?= na($r["study_name_short"] ?? $r["study_name"] ?? null) ?>
              <?php endif; ?>
            </td>
          </tr>
        <?php endforeach; ?>
      </table>
      </div>
    <?php endif; ?>
  </div>

<?php endif; ?>

<?php require __DIR__ . "/partials/footer.php"; ?>

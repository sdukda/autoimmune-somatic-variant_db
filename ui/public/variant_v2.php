<?php
// ui/public/variant_v2.php
require __DIR__ . "/../config/bootstrap.php";
// Helper function
function ucsc_url_from_genomic_variant(string $refGenome, string $genomicVariant): ?string
{
  $gv = trim($genomicVariant);
  if ($gv === '') return null;

  // Accept:
  // chr12:8857315 C>T
  // chr11:103362219-117295916
  // chr11:103362219_117295916
  if (!preg_match('/^(chr[0-9XYM]+):\s*([0-9]+)(?:[-_ ]([0-9]+))?/i', $gv, $m)) {
    return null;
  }

  $chrom = $m[1];
  $start = $m[2];
  $end   = $m[3] ?? $start;

  $rg = strtoupper(trim($refGenome));
  if ($rg === 'GRCH37' || $rg === 'HG19') {
    $db = 'hg19';
  } elseif ($rg === 'GRCH38' || $rg === 'HG38') {
    $db = 'hg38';
  } else {
    return null;
  }

  $position = $chrom . ':' . $start . '-' . $end;

  return 'https://genome.ucsc.edu/cgi-bin/hgTracks?db=' . rawurlencode($db)
       . '&position=' . rawurlencode($position);
}
$pageTitle = "Variant";
require __DIR__ . "/partials/header.php";

/*
  Modes:
   1) Detail by internal id:  /variant_v2.php?id=123
   2) Search:                /variant_v2.php?q=DNMT3A
   3) Coordinate click:      /variant_v2.php?variant=chr2:25243931%20G%3EA
*/

// Tiny display helper (only define if not already defined in bootstrap.php)
if (!function_exists("na")) {
  function na($v, string $fallback = "NA"): string {
    $v = trim((string)($v ?? ""));
    if ($v === "" || $v === "." || strtoupper($v) === "NA") return $fallback;
    return h($v);
  }
}
if (!function_exists('genomic_variant_string')) {
function genomic_variant_string(array $row): ?string {
  // Prefer paper-reported coords; fall back to lifted coords
$candidates = [
  ['paper_chrom','paper_pos','paper_ref','paper_alt'],
    ['lifted_chrom','lifted_pos','lifted_ref','lifted_alt'],
];
  foreach ($candidates as [$chrK,$posK,$refK,$altK]) {
    $chr = $row[$chrK] ?? null;
    $pos = $row[$posK] ?? null;
    $ref = $row[$refK] ?? null;
    $alt = $row[$altK] ?? null;

    if ($chr && $pos && $ref && $alt) {
      return "{$chr}:{$pos} {$ref}>{$alt}";
    }
  }
  return null;
}
}

$id      = (int)($_GET["id"] ?? 0);
$q       = trim((string)($_GET["q"] ?? ""));
$variant = trim((string)($_GET["variant"] ?? ""));  // coordinate string like "chr2:25243931 G>A"

$detail = null;          // detail row (id mode)
$rows   = [];            // search rows (q mode)
$vsum   = null;          // variant summary row (variant mode)
$evRows = [];            // evidence rows (variant mode)

// -------------------------
// 1) DETAIL MODE: ?id=123
// -------------------------
if ($id > 0) {
  try {
    $stmt = $pdo->prepare("
      SELECT *
      FROM v_literature_variants_flat
      WHERE literature_variant_id = :id
    ");
    $stmt->execute([":id" => $id]);
    $detail = $stmt->fetch() ?: null;
  } catch (Throwable $e) {
    $detail = null;
  }
}

// ------------------------------------
// 2) COORDINATE MODE: ?variant=...
// ------------------------------------
if ($id === 0 && $variant !== "") {
  try {
    // Summary: report counts + study list
    $stmt = $pdo->prepare("
      SELECT
        gene_symbol,
        ref_genome,
        genomic_variant,
        example_literature_variant_id,
        protein_change,
        n_reports,
        n_studies,
        studies
      FROM v_literature_summary_by_variant_coords
      WHERE genomic_variant = :v
      LIMIT 1
    ");
    $stmt->execute([":v" => $variant]);
    $vsum = $stmt->fetch() ?: null;

    // Evidence rows: pull all matching records from the flat view
    $stmt = $pdo->prepare("
      SELECT
        literature_variant_id,
        study_id, study_name, study_name_short,
        gene_symbol,
        cDNA_HGVS, protein_change,
        variant_type,
        consequence,
        consequence_detail,
        is_driver,
        disease_id, disease_name, disease_category, disease_ontology_id,
        cell_type_name, cell_type_ontology_id,
        evidence_type,

        paper_ref_genome, paper_chrom, paper_pos, paper_ref, paper_alt,
        lifted_ref_genome, lifted_chrom, lifted_pos, lifted_ref, lifted_alt
      FROM v_literature_variants_flat
      WHERE (
        CONCAT(paper_chrom,  ':', paper_pos,  ' ', paper_ref,  '>', paper_alt)  = :v
        OR
        CONCAT(lifted_chrom, ':', lifted_pos, ' ', lifted_ref, '>', lifted_alt) = :v
      )
      ORDER BY disease_name, study_id, literature_variant_id
      LIMIT 2000
    ");
    $stmt->execute([":v" => $variant]);
    $evRows = $stmt->fetchAll();

    // FIX: derive Gene + Reference genome from evidence rows,
    // choosing paper vs lifted based on what the user clicked (the :v string).
    $coordGene = $vsum["gene_symbol"] ?? null;
    $coordRefGenome = $vsum["ref_genome"] ?? null;

    if (!empty($evRows)) {
      $first = $evRows[0];

      $paperStr =
        ($first["paper_chrom"] ?? "") . ":" .
        ($first["paper_pos"]  ?? "") . " " .
        ($first["paper_ref"]  ?? "") . ">" .
        ($first["paper_alt"]  ?? "");

      $liftedStr =
        ($first["lifted_chrom"] ?? "") . ":" .
        ($first["lifted_pos"]  ?? "") . " " .
        ($first["lifted_ref"]  ?? "") . ">" .
        ($first["lifted_alt"]  ?? "");

      if ($variant === $paperStr) {
        $coordGene = $first["gene_symbol"] ?? $coordGene;
        $coordRefGenome = $first["paper_ref_genome"] ?? $coordRefGenome;
      } elseif ($variant === $liftedStr) {
        $coordGene = $first["gene_symbol"] ?? $coordGene;
        $coordRefGenome = $first["lifted_ref_genome"] ?? $coordRefGenome;
      } else {
        // Fallback: prefer paper ref genome if paper coords exist, else lifted
        $hasPaper =
          !empty($first["paper_chrom"]) && !empty($first["paper_pos"]) &&
          !empty($first["paper_ref"])  && !empty($first["paper_alt"]);

        $coordGene = $first["gene_symbol"] ?? $coordGene;
        $coordRefGenome = $hasPaper
          ? ($first["paper_ref_genome"] ?? $coordRefGenome)
          : ($first["lifted_ref_genome"] ?? $coordRefGenome);
      }

      // Make summary align with what we're displaying
      if ($vsum) {
        $vsum["gene_symbol"] = $coordGene;
        $vsum["ref_genome"]  = $coordRefGenome ?? ($vsum["ref_genome"] ?? null);
      }
    }

  } catch (Throwable $e) {
    $vsum = null;
    $evRows = [];
  }
}

//-----------------------
// 3) SEARCH MODE: ?q=...
// ---------------------------

if ($id === 0 && $variant === "" && $q !== "") {
  try {
    $stmt = $pdo->prepare("
      SELECT
        literature_variant_id,
        study_id, study_name_short,
        gene_symbol,
        cDNA_HGVS,
        protein_change,
        variant_type,
        consequence,
        is_driver,
        disease_id, disease_name,
        cell_type_name,
        lifted_ref_genome, lifted_chrom, lifted_pos, lifted_ref, lifted_alt,
        paper_ref_genome, paper_chrom, paper_pos, paper_ref, paper_alt
      FROM v_literature_variants_flat
      WHERE gene_symbol LIKE :q
         OR disease_name LIKE :q
         OR study_name_short LIKE :q
         OR cDNA_HGVS LIKE :q
         OR protein_change LIKE :q
         OR CONCAT(lifted_chrom, ':', lifted_pos) LIKE :q
         OR CONCAT(paper_chrom, ':', paper_pos) LIKE :q
      ORDER BY gene_symbol, literature_variant_id
      LIMIT 200
    ");
    $stmt->execute([":q" => "%" . $q . "%"]);
    $rows = $stmt->fetchAll();
  } catch (Throwable $e) {
    $rows = [];
  }
}
?>

<div class="card">
  <h2>Variant</h2>

  <p class="small">
    Researchers can arrive here in three ways:
    by clicking a variant from Gene/Disease/Study (ID mode),
    searching below (search mode),
    or clicking a genomic coordinate from the Variants page (coordinate mode).
  </p>

  <div class="card">
    <h3>Search</h3>
    <form method="get" action="/variant_v2.php">
      <input type="text" name="q" value="<?= h($q) ?>" placeholder="Search gene/disease/study/HGVS/chr:pos..." />
      <br><br>
      <button type="submit">Search</button>
      <a class="btn btn-link" href="/variant_v2.php">Clear</a>
    </form>

    <p class="small">
      Tip: you can also open a coordinate directly:
      <code>e.g.chr2:25243931 G&gt;A</code>
    </p>
  </div>

  <!-- ===================== -->
  <!-- COORDINATE MODE VIEW  -->
  <!-- ===================== -->
  <?php if ($id === 0 && $variant !== ""): ?>
    <div class="card">
      <h3>Variant (by genomic coordinates)</h3>

      <?php if (!$vsum): ?>
        <p class="small"><b>Variant not found in summary view.</b></p>
        <?php if (!$evRows): ?>
          <p class="small">No evidence rows matched this coordinate string.</p>
        <?php endif; ?>
      <?php else: ?>

        <?php
          // Derive a single "Consequence" display value from evidence rows (most frequent bucket + most frequent detail)
          $coord_consequence = null;
          $coord_detail      = null;

          if ($evRows) {
            $bucketCounts = [];
            $detailCounts = [];

            foreach ($evRows as $r) {
              $b = trim((string)($r["consequence"] ?? ""));
              $d = trim((string)($r["consequence_detail"] ?? ""));

              

              if ($b !== "" && strtoupper($b) !== "NA") $bucketCounts[$b] = ($bucketCounts[$b] ?? 0) + 1;
              if ($d !== "" && strtoupper($d) !== "NA") $detailCounts[$d] = ($detailCounts[$d] ?? 0) + 1;
            }

            if ($bucketCounts) { arsort($bucketCounts); $coord_consequence = array_key_first($bucketCounts); }
            if ($detailCounts) { arsort($detailCounts); $coord_detail      = array_key_first($detailCounts); }
          }
        ?>

        <table>
          <tr>
            <th>Gene</th>
            <td>
              <a href="/gene_v2.php?q=<?= urlencode((string)($coordGene ?? $vsum["gene_symbol"] ?? "")) ?>">
                <?= h($coordGene ?? $vsum["gene_symbol"] ?? "") ?>
              </a>
            </td>
          </tr>
          <tr><th>Reference genome</th><td><?= na($coordRefGenome ?? ($vsum["ref_genome"] ?? null)) ?></td></tr>

<tr>
  <th>Genomic variant</th>
          <td class="small">
  <?php
    $gv   = (string)($vsum["genomic_variant"] ?? "");
    $ucsc = ucsc_url_from_genomic_variant(
      (string)($coordRefGenome ?? ($vsum["ref_genome"] ?? "")),
      $gv
    );
  ?>

  <?php if ($gv !== "" && $ucsc): ?>
    <a href="<?= h($ucsc) ?>"
       target="_blank"
       rel="noopener noreferrer"
       title="Open this coordinate in UCSC Genome Browser">
      <?= h($gv) ?>
    </a>
  <?php else: ?>
    <?= h($gv) ?: "NA" ?>
  <?php endif; ?>
</td>

          <tr>
            <th>Consequence</th>
            <td title="Detail: <?= h($coord_detail ?? "NA") ?>"><?= na($coord_consequence ?? null) ?></td>
          </tr>

          <tr><th># Reports</th><td><?= (int)($vsum["n_reports"] ?? 0) ?></td></tr>
          <tr><th># Studies</th><td><?= (int)($vsum["n_studies"] ?? 0) ?></td></tr>
          <tr><th>Studies</th><td><?= na($vsum["studies"] ?? null) ?></td></tr>
        </table>
      <?php endif; ?>

      <div class="card">
        <h4>Evidence rows</h4>

        <?php if (!$evRows): ?>
          <p class="small">No evidence rows for this coordinate.</p>
        <?php else: ?>
          <div class="small">Showing <?= count($evRows) ?> rows (limit 2000).</div>

          <table>
            <tr>
              <th>cDNA (HGVS)</th>
              <th>Protein</th>
              <th title="Mutation class derived from REF/ALT length (SNV / Insertion / Deletion / Indel)">
  Variant type
</th>

<th title="Functional/biological category (Missense, Nonsense, Frameshift, Splice, Intron, etc.)">
  Consequence
</th>
              <th>Disease</th>
              <th>Cell type</th>
              <th>Study</th>
            </tr>

            <?php foreach ($evRows as $r): ?>
              <tr>
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

            <td class="small"><?= na(genomic_variant_string($r) ?? ($r["protein_change"] ?? null)) ?></td>
                <td><?= na($r["variant_type"] ?? null) ?></td>

                <td title="Detail: <?= h($r["consequence_detail"] ?? "NA") ?>">
                  <?= na($r["consequence"] ?? null) ?>
                </td>


                <td>
                  <?php if (!empty($r["disease_id"])): ?>
                    <a href="/disease_v2.php?id=<?= (int)$r["disease_id"] ?>">
                      <?= h($r["disease_name"] ?? "") ?>
                    </a>
                  <?php else: ?>
                    <?= na($r["disease_name"] ?? null) ?>
                  <?php endif; ?>
                </td>

                <td><?= na($r["cell_type_name"] ?? null) ?></td>

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
        <?php endif; ?>
      </div>
    </div>
  <?php endif; ?>

  <!-- ============ -->
  <!-- ID MODE VIEW -->
  <!-- ============ -->
  <?php if ($id > 0): ?>
    <div class="card">
      <h3>Variant details (internal ID)</h3>

      <?php if (!$detail): ?>
        <p class="small"><b>Variant not found.</b> Try searching above.</p>
      <?php else: ?>
        <table>
          <tr><th>Variant ID</th><td><?= (int)$detail["literature_variant_id"] ?></td></tr>

          <tr>
            <th>Gene</th>
            <td>
              <a href="/gene_v2.php?q=<?= urlencode((string)$detail["gene_symbol"]) ?>">
                <?= na($detail["gene_symbol"] ?? null) ?>
              </a>
            </td>
          </tr>

          <tr><th>Genomic variant</th><td><?= na(genomic_variant_string($detail) ?? ($detail["protein_change"] ?? null)) ?></td></tr>
          <tr><th>cDNA</th><td><?= na($detail["cDNA_HGVS"] ?? null) ?></td></tr>

          <tr><th>Variant type</th><td><?= na($detail["variant_type"] ?? null) ?></td></tr>

          <tr>
            <th>Consequence</th>
            <td title="Detail: <?= h($detail["consequence_detail"] ?? "NA") ?>">
              <?= na($detail["consequence"] ?? null) ?>
            </td>
          </tr>

          <tr><th>Driver label</th><td><?= na($detail["is_driver"] ?? null) ?></td></tr>

          <tr>
            <th>Disease</th>
            <td>
              <?php if (!empty($detail["disease_id"])): ?>
                <a href="/disease_v2.php?id=<?= (int)$detail["disease_id"] ?>">
                  <?= na($detail["disease_name"] ?? null) ?>
                </a>
              <?php else: ?>
                <?= na($detail["disease_name"] ?? null) ?>
              <?php endif; ?>
            </td>
          </tr>

          <tr><th>Cell type</th><td><?= na($detail["cell_type_name"] ?? null) ?></td></tr>

          <tr>
        
  <th>Study</th>
  <td>
    <?php if (!empty($detail["study_id"])): ?>
      <a href="/study_v2.php?id=<?= (int)$detail["study_id"] ?>">
        <?= na($detail["study_name"] ?? null) ?>
      </a>
    <?php else: ?>
      <?= na($detail["study_name"] ?? null) ?>
    <?php endif; ?>
  </td>
</tr>
        </table>

        <div class="grid" style="margin-top:16px;">
          <div class="col-6">
            <div class="card">
              <h4>Paper-reported coordinate</h4>
              <table>
                <tr><th>Ref genome</th><td><?= na($detail["paper_ref_genome"] ?? null) ?></td></tr>
                <tr><th>Chrom</th><td><?= na($detail["paper_chrom"] ?? null) ?></td></tr>
                <tr><th>Pos</th><td><?= na($detail["paper_pos"] ?? null) ?></td></tr>
                <tr><th>Ref</th><td><?= na($detail["paper_ref"] ?? null) ?></td></tr>
                <tr><th>Alt</th><td><?= na($detail["paper_alt"] ?? null) ?></td></tr>
              </table>
            </div>
          </div>

          <div class="col-6">
            <div class="card">
              <h4>Lifted coordinate</h4>
              <table>
                <tr><th>Ref genome</th><td><?= na($detail["lifted_ref_genome"] ?? null) ?></td></tr>
                <tr><th>Chrom</th><td><?= na($detail["lifted_chrom"] ?? null) ?></td></tr>
                <tr><th>Pos</th><td><?= na($detail["lifted_pos"] ?? null) ?></td></tr>
                <tr><th>Ref</th><td><?= na($detail["lifted_ref"] ?? null) ?></td></tr>
                <tr><th>Alt</th><td><?= na($detail["lifted_alt"] ?? null) ?></td></tr>
              </table>
            </div>
          </div>
        </div>

        <div class="card">
          <h4>Notes / remarks</h4>
          <p><b>Evidence:</b> <?= na($detail["evidence_type"] ?? null) ?></p>
          <p><b>Notes:</b> <?= nl2br(h((string)($detail["notes"] ?? ""))) ?></p>
          <p><b>Remarks:</b> <?= nl2br(h((string)($detail["Remarks"] ?? ""))) ?></p>
        </div>
      <?php endif; ?>
    </div>
  <?php endif; ?>

  <!-- ================= -->
  <!-- SEARCH MODE VIEW  -->
  <!-- ================= -->
<?php if ($id === 0 && $variant === ""): ?>
  <div class="card">
    <h3>Results</h3>

    <?php if ($q === ""): ?>
      <p class="small">Enter a search term to find variants (this page does not list all variants by default).</p>

    <?php else: ?>

      <?php if (count($rows) === 0): ?>
        <p class="small">No results found.</p>

      <?php else: ?>
        <table>
          <tr>
            <th>Variant ID</th>
            <th>Gene</th>
            <th>Genomic variant</th>
            <th>cDNA</th>
            <th>Disease</th>
            <th>Study</th>
            <th title="Variant type = mutation class (SNV / Insertion / Deletion / Indel / MNV)">Variant type</th>
            <th title="Consequence = functional effect on protein (Missense / Nonsense / Frameshift / etc.)">Consequence</th>
            <th>Driver</th>
          </tr>

          <?php foreach ($rows as $r): ?>
            <tr>
              <td>
                <a href="/variant_v2.php?id=<?= (int)$r["literature_variant_id"] ?>">
                  <?= (int)$r["literature_variant_id"] ?>
                </a>
              </td>

              <td>
                <a href="/gene_v2.php?q=<?= urlencode((string)$r["gene_symbol"]) ?>">
                  <?= na($r["gene_symbol"] ?? null) ?>
                </a>
              </td>

              <td><?= na(genomic_variant_string($r) ?? ($r["protein_change"] ?? null)) ?></td>
              <td><?= na($r["cDNA_HGVS"] ?? null) ?></td>

              <td>
                <?php if (!empty($r["disease_id"])): ?>
                  <a href="/disease_v2.php?id=<?= (int)$r["disease_id"] ?>">
                    <?= na($r["disease_name"] ?? null) ?>
                  </a>
                <?php else: ?>
                  <?= na($r["disease_name"] ?? null) ?>
                <?php endif; ?>
              </td>

              <td>
                <?php if (!empty($r["study_id"])): ?>
                  <a href="/study_v2.php?id=<?= (int)$r["study_id"] ?>">
                    <?= na($r["study_name_short"] ?? null) ?>
                  </a>
                <?php else: ?>
                  <?= na($r["study_name_short"] ?? null) ?>
                <?php endif; ?>
              </td>

              <td><?= na($r["variant_type"] ?? null) ?></td>
              <td><?= na($r["consequence"] ?? null) ?></td>
              <td><?= na($r["is_driver"] ?? null) ?></td>
            </tr>
          <?php endforeach; ?>
        </table>
      <?php endif; ?>

    <?php endif; ?>
  </div>
<?php endif; ?>
<?php require __DIR__ . "/partials/footer.php"; ?>

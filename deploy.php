<?php
// Script de deploy — protegido por token secreto
// Recibe un ZIP con el contenido de build/web/ y lo extrae en public_html/

$token = getenv('DEPLOY_TOKEN') ?: 'pgh_deploy_2026';

$provided = $_SERVER['HTTP_X_DEPLOY_TOKEN'] ?? '';
if ($provided !== $token) {
    http_response_code(403);
    die(json_encode(['error' => 'Forbidden']));
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    die(json_encode(['error' => 'Method not allowed']));
}

$zip_path = sys_get_temp_dir() . '/deploy_' . time() . '.zip';
$raw = file_get_contents('php://input');

if (!$raw || strlen($raw) < 100) {
    http_response_code(400);
    die(json_encode(['error' => 'Empty body']));
}

file_put_contents($zip_path, $raw);

$zip = new ZipArchive();
if ($zip->open($zip_path) !== true) {
    unlink($zip_path);
    http_response_code(500);
    die(json_encode(['error' => 'No se pudo abrir el ZIP']));
}

$target = __DIR__ . '/';
$zip->extractTo($target);
$zip->close();
unlink($zip_path);

// Borrar el propio script del resultado extraído si se sobreescribió
// (el zip no debe incluirlo, pero por si acaso)

echo json_encode(['ok' => true, 'files' => 'deployed', 'time' => date('c')]);

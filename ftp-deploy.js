const ftp = require('basic-ftp');
const fs  = require('fs');
const path = require('path');

async function deploy() {
  const client = new ftp.Client();
  client.ftp.verbose = false;

  try {
    await client.access({
      host:     '145.79.20.170',
      port:     21,
      user:     'u745645411.agenda.appgh.net',
      password: 'Delicias44##',
      secure:   false,
    });

    console.log('Conectado. Limpiando public_html/...');
    await client.clearWorkingDir();

    console.log('Subiendo build/web/...');
    await client.uploadFromDir('build/web');

    console.log('Deploy completado.');
  } catch (err) {
    console.error('Error:', err);
    process.exit(1);
  } finally {
    client.close();
  }
}

deploy();
